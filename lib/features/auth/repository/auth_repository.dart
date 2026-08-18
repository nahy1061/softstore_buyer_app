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
        throw const AuthFailure('Unable to load login page. Please try again.');
      }

      // Step 2: POST login form
      final response = await _client.post<String>(
        ApiEndpoints.loginPage,
        data: {
          '_csrf_token': csrfToken,
          'email': email.trim(),
          'password': password,
          'recaptcha_token': recaptchaToken,
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          responseType: ResponseType.plain,
          // Allow 200 and 302; 302 handled below
          validateStatus: (s) => s != null && s < 500,
          followRedirects: false,
        ),
      );

      final status = response.statusCode ?? 0;
      final location = response.headers.value('location') ?? '';

      // 302 without /login in location = success redirect (e.g. to /store)
      if (status == 302 && !location.contains('/login')) {
        developer.log('[Auth] Login successful, redirected to: $location', name: 'auth');
        // Invalidate cached CSRF for login page
        _csrf.clearAll();
        final user = await restoreSession();
        if (user == null) throw const AuthFailure('Unable to load user profile.');
        return user;
      }

      // Check for form errors in HTML body
      if (status == 200) {
        final html = response.data as String? ?? '';
        final error = HtmlParserUtil.extractFormError(html);
        throw AuthFailure(error ?? 'Invalid email or password.');
      }

      throw const AuthFailure('Login failed. Please try again.');
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
        throw const AuthFailure('Unable to load registration page.');
      }

      final response = await _client.post<String>(
        ApiEndpoints.registerPage,
        data: {
          '_csrf_token': csrfToken,
          'first_name': firstName.trim(),
          if (lastName != null) 'last_name': lastName.trim(),
          'email': email.trim(),
          'password': password,
          if (phone != null) 'phone': phone.trim(),
          'recaptcha_token': recaptchaToken,
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          responseType: ResponseType.plain,
          validateStatus: (s) => s != null && s < 500,
          followRedirects: false,
        ),
      );

      final status = response.statusCode ?? 0;
      final location = response.headers.value('location') ?? '';

      if (status == 302 && !location.contains('/login')) {
        _csrf.clearAll();
        final user = await restoreSession();
        if (user == null) throw const AuthFailure('Unable to load user profile.');
        return user;
      }

      if (status == 200) {
        final html = response.data as String? ?? '';
        final error = HtmlParserUtil.extractFormError(html);
        throw AuthFailure(error ?? 'Registration failed. Please try again.');
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
          if (csrfToken != null) '_csrf_token': csrfToken,
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
