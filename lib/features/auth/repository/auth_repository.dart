import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../core/config/env_config.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/csrf_service.dart';
import '../../../core/utils/html_parser_util.dart';
import '../models/user_model.dart';
import '../widgets/recaptcha_invisible_view.dart';

/// Handles all authentication operations against the SoftStore backend.
///
/// SoftStore uses:
/// - Session cookies (`SOFTSTORE_SESSID`) — persisted by Dio's [PersistCookieJar]
/// - CSRF tokens — extracted from each page before POSTing
/// - Form-encoded bodies for login/register (not JSON)
/// - JSON bodies only for /auth/google/callback and /store/checkout/send-code|verify-code
class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();
  factory AuthRepository() => instance;

  final DioClient _client = DioClient();
  final CsrfService _csrf = CsrfService.instance;

  // ─── Login ────────────────────────────────────────────────────────────────

  /// Authenticates the user with email and password.
  ///
  /// Flow:
  ///  1. GET /login → extract CSRF token
  ///  2. POST /login with form-encoded body
  ///  3. Server sets `SOFTSTORE_SESSID` cookie on success
  ///  4. Parse user from GET /store/account/profile
  ///
  /// Throws [AuthFailure] on credential error.
  /// Throws [NetworkFailure] on connectivity issues.
  Future<User> login({
    required String email,
    required String password,
    required String recaptchaToken,
  }) async {
    try {
      final cleanEmail = email.trim();
      final cleanPassword = password;
      String token = recaptchaToken;

      if (token.isEmpty) {
        token = await RecaptchaController.instance.getFreshToken();
      }

      developer.log('[Auth] Login attempt — email: $cleanEmail', name: 'auth');

      // Clear any old session cookies that may conflict with new login
      try {
        final cookieJar = _client.cookieJar;
        final uri = Uri.parse(EnvConfig.baseUrl);
        await cookieJar.delete(uri);
        developer.log('[Auth] Cleared old cookies for ${uri.host}', name: 'auth');
      } catch (e) {
        developer.log('[Auth] Cookie clear note: $e', name: 'auth');
      }

      // ── Strategy 1: Standard Web Form Login (/login) ────────────────────────
      _csrf.clearAll();
      final csrfToken = await _csrf.fetchToken(ApiEndpoints.loginPage);
      developer.log('[Auth] CSRF token fetched: ${csrfToken != null}', name: 'auth');

      if (csrfToken != null) {
        // Send as Map — Dio encodes for application/x-www-form-urlencoded correctly
        final formData = <String, String>{
          '_csrf_token': csrfToken,
          'email': cleanEmail,
          'password': cleanPassword,
        };

        developer.log('[Auth] Strategy 1: POST /login — fields: ${formData.keys.toList()}', name: 'auth');

        final response = await _client.post<dynamic>(
          ApiEndpoints.loginPage,
          data: formData,
          options: Options(
            contentType: 'application/x-www-form-urlencoded',
            responseType: ResponseType.plain,
            validateStatus: (s) => s != null && s < 500,
            followRedirects: false,
            headers: {
              'Referer': '${EnvConfig.baseUrl}/login',
              'X-CSRF-TOKEN': csrfToken,
              'Accept': 'text/html,application/xhtml+xml,*/*;q=0.9',
            },
          ),
        );

        final status = response.statusCode ?? 0;
        final location = response.headers.value('location') ?? '';
        final rawData = response.data?.toString() ?? '';
        developer.log('[Auth] Form login: status=$status, location=$location', name: 'auth');

        // Case A: 302 redirect away from /login (success)
        if (status == 302 && !location.contains('/login')) {
          developer.log('[Auth] Form login SUCCESS — redirected to: $location', name: 'auth');
          _csrf.clearAll();
          final user = await restoreSession();
          if (user != null) return user;
          return User(
            firstName: cleanEmail.split('@').first,
            lastName: '',
            email: cleanEmail,
          );
        }

        // Case B: Check if session was established (some servers use 200 + JS redirect)
        final userAfterLogin = await restoreSession();
        if (userAfterLogin != null && userAfterLogin.email.isNotEmpty) {
          developer.log('[Auth] Session established after form login', name: 'auth');
          _csrf.clearAll();
          return userAfterLogin;
        }

        // Case C: Surface server form error from HTML
        if (rawData.isNotEmpty) {
          final error = HtmlParserUtil.extractFormError(rawData);
          if (error != null) {
            developer.log('[Auth] Server error: $error', name: 'auth');
            throw AuthFailure(error);
          }
          developer.log('[Auth] No form error extracted. Body (500 chars): ${rawData.substring(0, rawData.length > 500 ? 500 : rawData.length)}', name: 'auth');
        }
      }

      // ── Strategy 2: Direct JSON API Login (/api/auth/login) ───────────────
      try {
        developer.log('[Auth] Strategy 2: POST /api/auth/login', name: 'auth');
        final apiResponse = await _client.post<dynamic>(
          ApiEndpoints.apiAuthLogin,
          data: {
            'email': cleanEmail,
            'password': cleanPassword,
          },
          options: Options(
            contentType: 'application/json',
            validateStatus: (s) => s != null && s < 500,
          ),
        );

        final apiStatus = apiResponse.statusCode ?? 0;
        final data = apiResponse.data;
        developer.log('[Auth] API login: status=$apiStatus', name: 'auth');

        if (apiStatus == 200 && data is Map<String, dynamic>) {
          if (data['success'] == true) {
            developer.log('[Auth] API login SUCCESS for: $cleanEmail', name: 'auth');
            _csrf.clearAll();

            if (data['user'] is Map<String, dynamic>) {
              try {
                return User.fromJson(data['user'] as Map<String, dynamic>);
              } catch (_) {}
            }

            final user = await restoreSession();
            if (user != null) return user;

            return User(
              firstName: cleanEmail.split('@').first,
              lastName: '',
              email: cleanEmail,
            );
          }
        }

        if (apiStatus == 401 || (data is Map<String, dynamic> && data['success'] == false)) {
          final errorMsg = (data is Map<String, dynamic>)
              ? (data['message'] ?? data['error'] ?? 'Those credentials do not match our records.')
              : 'Invalid email or password. Please verify your credentials.';
          developer.log('[Auth] API login REJECTED: $errorMsg', name: 'auth');
          throw AuthFailure(errorMsg.toString());
        }
      } on AuthFailure {
        rethrow;
      } catch (e) {
        developer.log('[Auth] API fallback error: $e', name: 'auth');
      }

      throw const AuthFailure('Invalid email or password. Please try again.');
    } on AuthFailure {
      rethrow;
    } on DioException catch (e) {
      _handleDioError(e);
    }
    throw const AuthFailure('Login failed. Please try again.');
  }

  // ─── Register ─────────────────────────────────────────────────────────────

  /// Creates a new SoftStore buyer account.
  ///
  /// After successful registration, the server auto-signs in the user.
  Future<User> register({
    required String firstName,
    required String email,
    required String password,
    String? lastName,
    String? phone,
    required String recaptchaToken,
  }) async {
    try {
      _csrf.clearAll();
      final csrfToken = await _csrf.fetchToken(ApiEndpoints.registerPage);
      if (csrfToken == null) {
        throw const AuthFailure('Unable to connect to registration server. Please try again.');
      }

      final fullName = '$firstName ${lastName ?? ''}'.trim();
      final formData = <String, String>{
        '_csrf_token': csrfToken,
        'full_name': fullName,
        'first_name': firstName.trim(),
        'name': fullName,
        if (lastName != null && lastName.isNotEmpty) 'last_name': lastName.trim(),
        'email': email.trim(),
        'password': password,
        'password_confirmation': password,
        if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
        if (recaptchaToken.isNotEmpty) 'g-recaptcha-response': recaptchaToken,
      };

      final formBody = Uri(queryParameters: formData).query;

      final response = await _client.post<dynamic>(
        ApiEndpoints.registerPage,
        data: formBody,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          responseType: ResponseType.plain,
          validateStatus: (s) => s != null && s < 500,
          followRedirects: false,
          headers: {
            'User-Agent': 'SoftStoreBuyer/1.0 iOS',
            'Referer': '${EnvConfig.baseUrl}/register',
            'X-CSRF-TOKEN': csrfToken,
            'Accept': 'text/html,application/xhtml+xml,*/*;q=0.9',
          },
        ),
      );

      final status = response.statusCode ?? 0;
      final location = response.headers.value('location') ?? '';
      final rawData = response.data;

      if (status == 302 && !location.contains('/login') && !location.contains('/register')) {
        _csrf.clearAll();
        final user = await restoreSession();
        if (user != null) return user;
        return User(
          firstName: firstName.trim(),
          lastName: lastName?.trim() ?? '',
          email: email.trim(),
          phone: phone?.trim(),
        );
      }

      final userAfterReg = await restoreSession();
      if (userAfterReg != null && userAfterReg.email.isNotEmpty) {
        _csrf.clearAll();
        return userAfterReg;
      }

      if (rawData is String && rawData.isNotEmpty) {
        final error = HtmlParserUtil.extractFormError(rawData);
        throw AuthFailure(error ?? 'Registration failed. Please check the entered information.');
      }

      throw const AuthFailure('Registration failed. Please try again.');
    } on AuthFailure {
      rethrow;
    } on DioException catch (e) {
      _handleDioError(e);
    }
    throw const AuthFailure('Registration failed. Please try again.');
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  /// Clears the server session and invalidates the `SOFTSTORE_SESSID` cookie.
  Future<void> logout() async {
    try {
      final csrfToken = await _csrf.fetchToken(ApiEndpoints.profilePage);

      await _client.post<String>(
        ApiEndpoints.logout,
        data: {
          if (csrfToken != null) ...{
            '_csrf_token': csrfToken,
            'csrf_token': csrfToken,
          },
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          responseType: ResponseType.plain,
          validateStatus: (s) => s != null && s < 500,
          followRedirects: false,
        ),
      );
    } catch (e) {
      // Log but do not throw — client-side cleanup still happens
      developer.log('[Auth] Logout request failed: $e', name: 'auth');
    } finally {
      _csrf.clearAll();
    }
  }

  // ─── Session Restoration ──────────────────────────────────────────────────

  /// Checks if the persisted session cookie is still valid and returns the
  /// authenticated [User] if so.
  ///
  /// Returns null if:
  ///  - No cookie exists
  ///  - Server redirects to /login (session expired)
  Future<User?> restoreSession() async {
    try {
      // Follow redirects like iOS URLSession does — if we end up at /login the session is expired
      final response = await _client.get<String>(
        ApiEndpoints.profilePage,
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (s) => s != null && s < 500,
          followRedirects: true,
          maxRedirects: 5,
          headers: {
            'User-Agent': 'SoftStoreBuyer/1.0 iOS',
            'Accept': 'text/html,application/xhtml+xml,*/*;q=0.9',
          },
        ),
      );

      final status = response.statusCode ?? 0;
      final finalUrl = response.realUri.toString();

      // If we ended up at login page, session is expired
      if (finalUrl.contains('/login')) {
        developer.log('[Auth] Session expired — redirected to login', name: 'auth');
        return null;
      }

      if (status == 200) {
        final html = response.data as String? ?? '';
        developer.log('[Auth] Profile fetched OK, parsing user…', name: 'auth');
        return _parseUserFromProfileHtml(html);
      }

      return null;
    } catch (e) {
      developer.log('[Auth] restoreSession error: $e', name: 'auth');
      return null;
    }
  }

  // ─── Email Verification (Checkout) ───────────────────────────────────────

  /// Sends a 6-digit OTP to [email] for checkout verification.
  Future<void> sendVerificationCode(String email) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.sendVerificationCode,
        data: {'email': email.trim()},
        options: Options(contentType: 'application/json'),
      );

      final body = response.data;
      if (body != null && body['success'] == false) {
        throw AuthFailure(
          body['message']?.toString() ?? 'Failed to send verification code.',
        );
      }
    } on AuthFailure {
      rethrow;
    } on DioException catch (e) {
      _handleDioError(e);
    }
  }

  /// Verifies the OTP entered by the user.
  ///
  /// Returns true if verification is successful.
  Future<bool> verifyCode(String code) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.verifyCode,
        data: {'code': code.trim()},
        options: Options(contentType: 'application/json'),
      );

      final body = response.data;
      return body != null && body['success'] == true;
    } on DioException catch (e) {
      _handleDioError(e);
    }
    return false;
  }

  // ─── Parsing ──────────────────────────────────────────────────────────────

  /// Extracts [User] data from the profile page HTML.
  ///
  /// The profile page has a form with named inputs for each field.
  User _parseUserFromProfileHtml(String html) {
    final doc = HtmlParserUtil.parse(html);

    String? inputVal(String name) {
      try {
        return doc.querySelector('input[name="$name"]')?.attributes['value']?.trim();
      } catch (e) {
        developer.log('[Auth] Selector failed for $name: $e', name: 'auth');
        return null;
      }
    }

    final firstName = inputVal('first_name') ?? '';
    final lastName = inputVal('last_name') ?? '';
    final email = inputVal('email') ?? '';
    final phone = inputVal('phone');

    return User(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone?.isEmpty == true ? null : phone,
    );
  }

  // ─── Error Handling ───────────────────────────────────────────────────────

  Never _handleDioError(DioException e) {
    developer.log('[Auth] DioException: ${e.message}', name: 'auth');

    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      throw const NetworkFailure('Connection timed out. Check your internet.');
    }

    if (e.type == DioExceptionType.connectionError) {
      throw const NetworkFailure('No internet connection.');
    }

    if (e.error is AuthFailure) throw e.error as AuthFailure;

    throw AuthFailure(e.message ?? 'An unexpected error occurred.');
  }
}
