import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/csrf_service.dart';
import '../../../core/utils/html_parser_util.dart';
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
      // Step 1: Fetch CSRF token from login page
      final csrfToken = await _csrf.fetchToken(ApiEndpoints.loginPage);
      if (csrfToken == null) {
        throw const AuthFailure('Unable to connect to login server. Please check your internet connection.');
      }

      // Step 2: Build compatibility form-encoded payload
      final formData = <String, dynamic>{
        '_csrf_token': csrfToken,
        'csrf_token': csrfToken,
        '_token': csrfToken,
        'email': email.trim(),
        'username': email.trim(),
        'login': email.trim(),
        'user_login': email.trim(),
        'password': password,
        '_password': password,
      };

      if (recaptchaToken.isNotEmpty && recaptchaToken != 'app-token') {
        formData['recaptcha_token'] = recaptchaToken;
        formData['g-recaptcha-response'] = recaptchaToken;
      }

      // Step 3: POST login form
      final response = await _client.post<dynamic>(
        ApiEndpoints.loginPage,
        data: formData,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          responseType: ResponseType.plain,
          validateStatus: (s) => s != null && s < 500,
          followRedirects: false,
        ),
      );

      final status = response.statusCode ?? 0;
      final location = response.headers.value('location') ?? '';
      final rawData = response.data;

      // Case A: 302 redirect away from /login (standard PHP success redirect)
      if (status == 302 && !location.contains('/login')) {
        developer.log('[Auth] Login successful, redirected to: $location', name: 'auth');
        _csrf.clearAll();
        final user = await restoreSession();
        if (user != null && user.email.isNotEmpty) return user;
        return User(
          firstName: email.split('@').first,
          lastName: '',
          email: email.trim(),
        );
      }

      // Case B: Check if session was successfully established
      final userAfterLogin = await restoreSession();
      if (userAfterLogin != null) {
        _csrf.clearAll();
        if (userAfterLogin.email.isEmpty) {
          return userAfterLogin.copyWith(email: email.trim());
        }
        return userAfterLogin;
      }

      // Case C: Check for JSON API response
      if (rawData is String && rawData.trim().startsWith('{')) {
        final error = HtmlParserUtil.extractFormError(rawData);
        if (error != null) throw AuthFailure(error);
      }

      // Case D: HTML page response (status 200 or 302 back)
      if (rawData is String && rawData.isNotEmpty) {
        final error = HtmlParserUtil.extractFormError(rawData);
        throw AuthFailure(error ?? 'Invalid email or password. Please verify your credentials.');
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
        if (lastName != null) 'last_name': lastName.trim(),
        'email': email.trim(),
        'username': email.trim(),
        'password': password,
        'password_confirmation': password,
        if (phone != null) 'phone': phone.trim(),
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
      final csrfToken = await _csrf
          .fetchToken(ApiEndpoints.checkoutPage)
          .timeout(const Duration(seconds: 3), onTimeout: () => null);

      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.sendVerificationCode,
        data: {'email': email.trim()},
        options: Options(
          contentType: 'application/json',
          headers: {
            if (csrfToken != null) 'X-CSRF-TOKEN': csrfToken,
            'Accept': 'application/json',
          },
        ),
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
      final csrfToken = await _csrf
          .fetchToken(ApiEndpoints.checkoutPage)
          .timeout(const Duration(seconds: 3), onTimeout: () => null);

      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.verifyCode,
        data: {'code': code.trim()},
        options: Options(
          contentType: 'application/json',
          headers: {
            if (csrfToken != null) 'X-CSRF-TOKEN': csrfToken,
            'Accept': 'application/json',
          },
        ),
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
  /// Also attempts to detect email verification status from the HTML.
  User _parseUserFromProfileHtml(String html) {
    final doc = HtmlParserUtil.parse(html);

    String? inputVal(String name) =>
        doc.querySelector('input[name="$name"]')?.attributes['value']?.trim() ??
        doc.querySelector('input[id="$name"]')?.attributes['value']?.trim();

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
