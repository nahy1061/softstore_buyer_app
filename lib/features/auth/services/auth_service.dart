import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/storage_keys.dart';

class AuthService {
  final DioClient _dio = DioClient();

  /// Login with email + password (API Mapping #2)
  /// POST /auth/login
  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      // Step 1: GET login page to extract CSRF token
      final pageResponse = await _dio.get(ApiEndpoints.login);
      final csrfToken = _extractCsrfToken(pageResponse.data is String
          ? pageResponse.data as String
          : '');

      // Step 2: POST login with CSRF token
      await _dio.post(
        ApiEndpoints.login,
        data: {
          if (csrfToken.isNotEmpty) '_csrf_token': csrfToken,
          'email': email,
          'password': password,
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          followRedirects: false,
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      // Step 3: Save session info
      await _saveSession(email);
    } on DioException {
      rethrow;
    }
  }

  /// Register new account (API Mapping #1)
  /// POST /auth/register
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    try {
      // Step 1: GET register page to extract CSRF token
      final pageResponse = await _dio.get(ApiEndpoints.register);
      final csrfToken = _extractCsrfToken(pageResponse.data is String
          ? pageResponse.data as String
          : '');

      // Step 2: POST register with CSRF token
      await _dio.post(
        ApiEndpoints.register,
        data: {
          if (csrfToken.isNotEmpty) '_csrf_token': csrfToken,
          'first_name': firstName,
          'last_name': lastName,
          'email': email,
          'password': password,
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          followRedirects: false,
          validateStatus: (status) => status != null && status < 400,
        ),
      );

      // Step 3: Save session info
      await _saveSession(email);
    } on DioException {
      rethrow;
    }
  }

  /// Logout (API Mapping #3)
  /// POST /auth/logout
  Future<void> logout() async {
    try {
      // Step 1: GET a page to extract CSRF token
      final pageResponse = await _dio.get(ApiEndpoints.getProfile);
      final csrfToken = _extractCsrfToken(pageResponse.data is String
          ? pageResponse.data as String
          : '');

      // Step 2: POST logout with CSRF token
      await _dio.post(
        ApiEndpoints.logout,
        data: {
          if (csrfToken.isNotEmpty) '_csrf_token': csrfToken,
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          followRedirects: false,
          validateStatus: (status) => status != null && status < 400,
        ),
      );
    } on DioException {
      // Ignore errors on logout - clear local state regardless
    } finally {
      await _clearSession();
    }
  }

  /// Check if user has stored session locally (no network call).
  /// The backend returns 200 HTML even for anonymous users,
  /// so network-based session checks are unreliable.
  Future<bool> hasStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(StorageKeys.userEmail);
    return email != null && email.isNotEmpty;
  }

  /// Get stored user email
  Future<String?> getStoredEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(StorageKeys.userEmail);
  }

  Future<void> _saveSession(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.userEmail, email);
  }

  Future<void> _clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.userEmail);
    await prefs.remove(StorageKeys.userId);
    await prefs.remove(StorageKeys.userName);
    await prefs.remove(StorageKeys.userPhone);
  }

  /// Extract CSRF token from HTML page
  String _extractCsrfToken(String html) {
    // Pattern 1: <input name="_csrf_token" value="TOKEN">
    final p1 = RegExp(
      '<input[^>]*name=["\']_csrf_token["\'][^>]*value=["\']([^"\']*)["\']',
      caseSensitive: false,
    );
    final m1 = p1.firstMatch(html);
    if (m1 != null) return m1.group(1) ?? '';

    // Pattern 2: <input value="TOKEN" name="_csrf_token">
    final p2 = RegExp(
      '<input[^>]*value=["\']([^"\']*)["\'][^>]*name=["\']_csrf_token["\']',
      caseSensitive: false,
    );
    final m2 = p2.firstMatch(html);
    if (m2 != null) return m2.group(1) ?? '';

    // Pattern 3: var csrfToken = 'TOKEN'
    final p3 = RegExp("var\\s+csrfToken\\s*=\\s*'([^']*)'");
    final m3 = p3.firstMatch(html);
    if (m3 != null) return m3.group(1) ?? '';

    return '';
  }
}
