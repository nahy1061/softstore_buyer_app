import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../core/config/env_config.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/csrf_service.dart';
import '../../../core/utils/html_parser_util.dart';
import '../../cart/repository/cart_repository.dart';
import '../models/user_model.dart';

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
        final formData = <String, String>{
          '_csrf_token': csrfToken,
          'csrf_token': csrfToken,
          '_token': csrfToken,
          'email': cleanEmail,
          'username': cleanEmail,
          'login': cleanEmail,
          'user_login': cleanEmail,
          'password': cleanPassword,
          '_password': cleanPassword,
        };

        if (recaptchaToken.isNotEmpty && recaptchaToken != 'app-token') {
          formData['recaptcha_token'] = recaptchaToken;
          formData['g-recaptcha-response'] = recaptchaToken;
        }

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
              'Origin': EnvConfig.baseUrl,
              'X-CSRF-TOKEN': csrfToken,
              'X-CSRF-Token': csrfToken,
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
            responseType: ResponseType.json,
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

      // Final fallback: check if any session was established
      final userAfterLogin = await restoreSession();
      if (userAfterLogin != null) {
        _csrf.clearAll();
        if (userAfterLogin.email.isEmpty) {
          return userAfterLogin.copyWith(email: cleanEmail);
        }
        return userAfterLogin;
      }

      throw const AuthFailure('Invalid email or password. Please verify your credentials.');
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
      final csrfToken = await _csrf.fetchToken(ApiEndpoints.registerPage);
      if (csrfToken == null) {
        throw const AuthFailure('Unable to connect to registration server. Please try again.');
      }

      final formData = <String, dynamic>{
        '_csrf_token': csrfToken,
        'csrf_token': csrfToken,
        '_token': csrfToken,
        'first_name': firstName.trim(),
        'name': '$firstName ${lastName ?? ''}'.trim(),
        if (lastName != null && lastName.trim().isNotEmpty) 'last_name': lastName.trim(),
        'email': email.trim(),
        'username': email.trim(),
        'password': password,
        'password_confirmation': password,
        if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
      };

      if (recaptchaToken.isNotEmpty && recaptchaToken != 'app-token') {
        formData['recaptcha_token'] = recaptchaToken;
        formData['g-recaptcha-response'] = recaptchaToken;
      }

      final response = await _client.post<dynamic>(
        ApiEndpoints.registerPage,
        data: formData,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          responseType: ResponseType.plain,
          headers: {
            'Referer': '${EnvConfig.apiBaseUrl}${ApiEndpoints.registerPage}',
            'Origin': EnvConfig.apiBaseUrl,
            if (csrfToken.isNotEmpty) 'X-CSRF-TOKEN': csrfToken,
            if (csrfToken.isNotEmpty) 'X-CSRF-Token': csrfToken,
          },
          validateStatus: (s) => s != null && s < 500,
          followRedirects: false,
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

      final html = rawData is String ? rawData : (rawData?.toString() ?? '');
      final regError = HtmlParserUtil.extractFormError(html);
      if (regError != null && regError.isNotEmpty) {
        throw AuthFailure(regError);
      }

      throw const AuthFailure('Registration failed. Please check the entered information.');
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
      try {
        await _client.cookieJar.deleteAll();
      } catch (_) {}
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
      final response = await _client.get<String>(
        ApiEndpoints.profilePage,
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (s) => s != null && s < 500,
          followRedirects: false,
        ),
      );

      final status = response.statusCode ?? 0;
      final location = response.headers.value('location') ?? '';

      // Session expired
      if (status == 302 && HtmlParserUtil.isLoginRedirect(location)) {
        developer.log('[Auth] Session expired', name: 'auth');
        return null;
      }

      if (status == 200) {
        final html = response.data as String? ?? '';
        final user = _parseUserFromProfileHtml(html);
        if (user.email.isNotEmpty) {
          final isVerifiedLocally =
              await CartRepository.instance.isEmailVerified(user.email);
          if (isVerifiedLocally && !user.isEmailVerified) {
            return user.copyWith(isEmailVerified: true);
          }
        }
        return user;
      }

      return null;
    } catch (e) {
      developer.log('[Auth] restoreSession error: $e', name: 'auth');
      return null;
    }
  }

  // ─── Email Verification ───────────────────────────────────────────────────

  /// Sends a 6-digit OTP to [email] using the existing Send OTP endpoint.
  /// When [isResend] is true, refreshes the CSRF token to ensure a fresh request.
  Future<void> sendVerificationCode(
    String email, {
    String? name,
    String? phone,
    bool isResend = false,
  }) async {
    final targetEmail = email.trim();
    if (targetEmail.isEmpty) {
      throw const AuthFailure(
          'Email address is required to receive verification code.');
    }

    try {
      final csrfToken = isResend
          ? await _csrf
              .refreshToken(ApiEndpoints.checkoutPage)
              .timeout(const Duration(seconds: 4), onTimeout: () => null)
          : await _csrf
              .fetchToken(ApiEndpoints.checkoutPage)
              .timeout(const Duration(seconds: 4), onTimeout: () => null);

      final response = await _client.post<dynamic>(
        ApiEndpoints.sendVerificationCode,
        data: {
          'email': targetEmail,
          if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
          if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
          if (csrfToken != null && csrfToken.isNotEmpty) '_csrf_token': csrfToken,
          if (csrfToken != null && csrfToken.isNotEmpty) 'csrf_token': csrfToken,
        },
        options: Options(
          contentType: 'application/json',
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {
            if (csrfToken != null) 'X-CSRF-TOKEN': csrfToken,
            if (csrfToken != null) 'X-CSRF-Token': csrfToken,
            'Accept': 'application/json',
          },
        ),
      );

      final dynamic data = response.data;
      final Map? body = data is Map ? data : null;
      if (body != null &&
          (body['success'] == false || body['error'] != null)) {
        final msg = body['message']?.toString() ??
            body['error']?.toString() ??
            'Failed to send verification code.';
        final lowerMsg = msg.toLowerCase();

        // If rate limited on initial send, an active OTP was already generated for this email.
        // Proceed smoothly to the OTP verification screen so user can enter the active code.
        if (!isResend &&
            (lowerMsg.contains('too many requests') ||
                lowerMsg.contains('already sent') ||
                lowerMsg.contains('wait a few minutes') ||
                lowerMsg.contains('please wait'))) {
          developer.log(
            '[Auth] Rate limited on initial send ($msg), active OTP code is already in inbox.',
            name: 'auth',
          );
          return;
        }

        throw AuthFailure(msg);
      }
    } on AuthFailure {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 419) {
        // Token expired or invalid on resend — refresh token and retry
        final freshCsrf =
            await _csrf.refreshToken(ApiEndpoints.checkoutPage);
        if (freshCsrf != null) {
          final retryResponse = await _client.post<dynamic>(
            ApiEndpoints.sendVerificationCode,
            data: {
              'email': targetEmail,
              if (name != null && name.trim().isNotEmpty) 'name': name.trim(),
              if (phone != null && phone.trim().isNotEmpty) 'phone': phone.trim(),
              '_csrf_token': freshCsrf,
              'csrf_token': freshCsrf,
            },
            options: Options(
              contentType: 'application/json',
              sendTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
              headers: {
                'X-CSRF-TOKEN': freshCsrf,
                'X-CSRF-Token': freshCsrf,
                'Accept': 'application/json',
              },
            ),
          );
          final dynamic retryData = retryResponse.data;
          final Map? retryBody = retryData is Map ? retryData : null;
          if (retryBody != null &&
              (retryBody['success'] == false || retryBody['error'] != null)) {
            final msg = retryBody['message']?.toString() ??
                retryBody['error']?.toString() ??
                'Failed to send verification code.';
            final lowerMsg = msg.toLowerCase();
            if (!isResend &&
                (lowerMsg.contains('too many requests') ||
                    lowerMsg.contains('already sent') ||
                    lowerMsg.contains('wait a few minutes') ||
                    lowerMsg.contains('please wait'))) {
              developer.log(
                '[Auth] Rate limited on retry ($msg), proceeding with active code.',
                name: 'auth',
              );
              return;
            }
            throw AuthFailure(msg);
          }
          return;
        }
      }

      if (e.response?.statusCode == 429) {
        if (!isResend) {
          developer.log(
            '[Auth] 429 Too Many Requests on initial send, active OTP already present.',
            name: 'auth',
          );
          return;
        }
        throw const AuthFailure(
            'Too many requests. Please wait a minute before requesting another OTP.');
      }

      if (e.response?.data is Map) {
        final err = (e.response!.data['message'] ??
                e.response!.data['error'])
            ?.toString();
        if (err != null && err.isNotEmpty) {
          final lowerErr = err.toLowerCase();
          if (!isResend &&
              (lowerErr.contains('too many requests') ||
                  lowerErr.contains('already sent') ||
                  lowerErr.contains('wait a few minutes') ||
                  lowerErr.contains('please wait'))) {
            developer.log(
              '[Auth] Rate limited ($err), proceeding to OTP input with active code.',
              name: 'auth',
            );
            return;
          }
          throw AuthFailure(err);
        }
      }
      _handleDioError(e);
    }
  }

  /// Verifies the OTP entered by the user using the existing Verify OTP endpoint.
  ///
  /// Returns true if verification is successful.
  Future<bool> verifyCode(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      throw const AuthFailure(
          'Please enter the 6-digit code received on your email.');
    }

    try {
      final csrfToken = await _csrf
          .fetchToken(ApiEndpoints.checkoutPage)
          .timeout(const Duration(seconds: 3), onTimeout: () => null);

      final response = await _client.post<dynamic>(
        ApiEndpoints.verifyCode,
        data: {'code': trimmed},
        options: Options(
          contentType: 'application/json',
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {
            if (csrfToken != null) 'X-CSRF-TOKEN': csrfToken,
            'Accept': 'application/json',
          },
        ),
      );

      final dynamic data = response.data;
      final Map? body = data is Map ? data : null;
      if (body != null) {
        final bool isSuccess =
            body['success'] == true || body['verified'] == true;
        if (isSuccess) return true;

        final msg =
            (body['message'] ?? body['error'] ?? '').toString();
        if (msg.toLowerCase().contains('expire')) {
          throw const AuthFailure(
              'OTP has expired. Please request a new OTP.');
        }
        throw const AuthFailure(
            'Invalid OTP. Please enter the correct OTP.');
      }

      return response.statusCode == 200;
    } on AuthFailure {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.data is Map) {
        final err = (e.response!.data['message'] ??
                e.response!.data['error'] ??
                '')
            .toString();
        if (err.toLowerCase().contains('expire')) {
          throw const AuthFailure(
              'OTP has expired. Please request a new OTP.');
        }
        throw const AuthFailure(
            'Invalid OTP. Please enter the correct OTP.');
      }
      _handleDioError(e);
    }
    return false;
  }

  // ─── Parsing ──────────────────────────────────────────────────────────────

  /// Extracts [User] data from the profile page HTML.
  ///
  /// The profile page has a form with named inputs for each field.
  /// Also attempts to detect email verification status from the HTML.
  User _parseUserFromProfileHtml(String html) {
    final doc = HtmlParserUtil.parse(html);

    String? inputVal(String name) {
      try {
        return doc.querySelector('input[name="$name"]')?.attributes['value']?.trim() ??
            doc.querySelector('input[id="$name"]')?.attributes['value']?.trim();
      } catch (e) {
        developer.log('[Auth] Selector failed for $name: $e', name: 'auth');
        return null;
      }
    }

    final firstName = inputVal('first_name') ?? inputVal('name') ?? '';
    final lastName = inputVal('last_name') ?? '';
    final email = inputVal('email') ??
        inputVal('user_email') ??
        doc.querySelector('input[type="email"]')?.attributes['value']?.trim() ??
        '';
    final phone = inputVal('phone');

    // Detect email verification status from the profile HTML.
    // Looks for common patterns: hidden inputs, checkboxes, text indicators.
    final isEmailVerified = _detectEmailVerified(doc, html);

    return User(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone?.isEmpty == true ? null : phone,
      isEmailVerified: isEmailVerified,
    );
  }

  /// Attempts to detect whether the user's email is verified from the
  /// profile page HTML document or raw HTML string.
  bool _detectEmailVerified(dynamic doc, String html) {
    // 1. Check hidden/visible input fields with verification-related names
    for (final name in [
      'email_verified',
      'is_email_verified',
      'verified',
      'email_verification_status',
    ]) {
      final input = doc.querySelector('input[name="$name"]');
      if (input != null) {
        final val = input.attributes['value']?.toLowerCase() ?? '';
        if (val == '1' || val == 'true' || val == 'yes') return true;
        if (val == '0' || val == 'false' || val == 'no') return false;
      }
    }

    // 2. Check for a checked checkbox
    for (final name in ['email_verified', 'is_email_verified', 'verified']) {
      final checkbox = doc.querySelector(
        'input[name="$name"][type="checkbox"]',
      );
      if (checkbox != null && checkbox.attributes.containsKey('checked')) {
        return true;
      }
    }

    // 3. Look for text indicators in the raw HTML
    final lowerHtml = html.toLowerCase();
    if (lowerHtml.contains('email verified') ||
        lowerHtml.contains('email_verified') ||
        lowerHtml.contains('is-verified') ||
        lowerHtml.contains('verification-badge')) {
      return true;
    }
    if (lowerHtml.contains('email not verified') ||
        lowerHtml.contains('email unverified') ||
        lowerHtml.contains('verify your email') ||
        lowerHtml.contains('pending verification')) {
      return false;
    }

    // Cannot determine from HTML — default to unverified so the
    // checkout flow will proactively send an OTP.
    return false;
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
