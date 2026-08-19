import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
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

      // ── Strategy 1: Standard Web Form Login (/login) ────────────────────────
      // Replicates the native iOS WebSessionClient login flow
      _csrf.clearAll();
      final csrfToken = await _csrf.fetchToken(ApiEndpoints.loginPage);
      if (csrfToken != null) {
        final formData = <String, String>{
          '_csrf_token': csrfToken,
          'email': cleanEmail,
          'password': cleanPassword,
          if (token.isNotEmpty) 'g-recaptcha-response': token,
        };

        final formBody = Uri(queryParameters: formData).query;

        final response = await _client.post<dynamic>(
          ApiEndpoints.loginPage,
          data: formBody,
          options: Options(
            contentType: 'application/x-www-form-urlencoded',
            responseType: ResponseType.plain,
            validateStatus: (s) => s != null && s < 500,
            followRedirects: false,
            headers: {
              'User-Agent': 'SoftStoreBuyer/1.0 iOS',
              'Referer': '${EnvConfig.baseUrl}/login',
              'X-CSRF-TOKEN': csrfToken,
              'Accept': 'text/html,application/xhtml+xml,*/*;q=0.9',
            },
          ),
        );

        final status = response.statusCode ?? 0;
        final location = response.headers.value('location') ?? '';
        final rawData = response.data;

        // Case A: 302 redirect away from /login (standard PHP success redirect)
        if (status == 302 && !location.contains('/login')) {
          developer.log('[Auth] Form login successful, redirected to: $location', name: 'auth');
          _csrf.clearAll();
          final user = await restoreSession();
          if (user != null) return user;
          return User(
            firstName: cleanEmail.split('@').first,
            lastName: '',
            email: cleanEmail,
          );
        }

        // Case B: 302 back to /login = validation error (wrong creds, captcha, etc.)
        if (status == 302 && location.contains('/login')) {
          final errorPage = await _fetchRedirectPage(location);
          if (errorPage != null) {
            final error = HtmlParserUtil.extractFormError(errorPage);
            throw AuthFailure(error ?? 'Invalid email or password. Please verify your credentials.');
          }
          throw const AuthFailure('Invalid email or password. Please verify your credentials.');
        }

        // Case C: Check if session was successfully established
        final userAfterLogin = await restoreSession();
        if (userAfterLogin != null && userAfterLogin.email.isNotEmpty) {
          _csrf.clearAll();
          return userAfterLogin;
        }

        // Case D: Surface server form error from HTML response
        if (rawData is String && rawData.isNotEmpty) {
          final error = HtmlParserUtil.extractFormError(rawData);
          if (error != null && !error.toLowerCase().contains('captcha')) {
            throw AuthFailure(error);
          }
        }
      }

      // ── Strategy 2: Direct JSON API Login (/api/auth/login) ───────────────
      // Mobile-friendly API endpoint fallback
      try {
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

        if (apiStatus == 200 && data is Map<String, dynamic>) {
          if (data['success'] == true) {
            developer.log('[Auth] API login successful for: $cleanEmail', name: 'auth');
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

      debugPrint('[Auth] Register response: status=$status, location=$location');
      if (rawData is String) {
        debugPrint('[Auth] Register response body (first 500 chars): ${rawData.substring(0, rawData.length > 500 ? 500 : rawData.length)}');
      }

      // 302 to success (not /login or /register) = registration succeeded
      if (status == 302 && !location.contains('/login') && !location.contains('/register')) {
        debugPrint('[Auth] Register SUCCESS - redirected to: $location');
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

      // 302 back to /register = validation error (captcha, duplicate email, etc.)
      if (status == 302 && location.contains('/register')) {
        debugPrint('[Auth] Register FAILED - redirected back to /register');
        final errorPage = await _fetchRedirectPage(location);
        if (errorPage != null) {
          debugPrint('[Auth] Error page (first 500 chars): ${errorPage.substring(0, errorPage.length > 500 ? 500 : errorPage.length)}');
          final error = HtmlParserUtil.extractFormError(errorPage);
          debugPrint('[Auth] Extracted error: $error');
          throw AuthFailure(error ?? 'Registration failed. Please check your information and try again.');
        }
        throw const AuthFailure('Registration failed. Please check your information and try again.');
      }

      // Check if session was established (some servers 200 with auto-login)
      final userAfterReg = await restoreSession();
      if (userAfterReg != null && userAfterReg.email.isNotEmpty) {
        _csrf.clearAll();
        return userAfterReg;
      }

      // Try to extract error from response body
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
      debugPrint('[Auth] Logout request failed: $e');
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
      debugPrint('[Auth] restoreSession error: $e');
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

  /// Follows a redirect URL and returns the HTML body.
  ///
  /// Used to extract error messages from flash-message pages
  /// (e.g., 302 back to /register with validation errors).
  Future<String?> _fetchRedirectPage(String location) async {
    try {
      final redirectUrl = location.startsWith('http')
          ? location
          : '${_client.dio.options.baseUrl}$location';
      final response = await _client.get<String>(
        redirectUrl,
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      return response.data;
    } catch (e) {
      debugPrint('[Auth] Failed to fetch redirect page: $e');
      return null;
    }
  }

  /// Extracts [User] data from the profile page HTML.
  ///
  /// The profile page has a form with named inputs for each field.
  User _parseUserFromProfileHtml(String html) {
    final doc = HtmlParserUtil.parse(html);

    String? inputVal(String name) =>
        doc.querySelector('input[name="$name"]')?.attributes['value']?.trim();

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
    debugPrint('[Auth] DioException: ${e.message}');

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
