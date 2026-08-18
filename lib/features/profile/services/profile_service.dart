import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../models/user_model.dart';
import '../models/dashboard_stats_model.dart';

class ProfileService {
  final DioClient _dio = DioClient();

  /// Get CSRF token from a page (API Mapping critical note)
  Future<String> _getCsrfToken(String pagePath) async {
    try {
      final response = await _dio.get(pagePath);
      if (response.data is String) {
        return extractCsrfToken(response.data as String);
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  /// Get current user profile (API Mapping #22)
  /// GET /store/account/profile
  Future<User> getProfile() async {
    try {
      final response = await _dio.get(ApiEndpoints.getProfile);
      if (response.data is String) {
        return User.fromHtml(response.data as String);
      }
      return User.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  /// Update user profile (API Mapping #23)
  /// POST /store/account/profile
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      // Step 1: GET the profile page to extract CSRF token
      final csrfToken = await _getCsrfToken(ApiEndpoints.getProfile);

      // Step 2: POST with CSRF token
      await _dio.post(
        ApiEndpoints.updateProfile,
        data: {
          if (csrfToken.isNotEmpty) ...{
            '_csrf_token': csrfToken,
            'csrf_token': csrfToken,
          },
          'first_name': firstName,
          'last_name': lastName,
          'phone': phone,
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
    } on DioException {
      rethrow;
    }
  }

  /// Change password (API Mapping #24)
  /// POST /store/account/password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      // Step 1: GET a page to extract CSRF token
      final csrfToken = await _getCsrfToken(ApiEndpoints.getProfile);

      // Step 2: POST with CSRF token
      await _dio.post(
        ApiEndpoints.changePassword,
        data: {
          if (csrfToken.isNotEmpty) ...{
            '_csrf_token': csrfToken,
            'csrf_token': csrfToken,
          },
          'current_password': currentPassword,
          'new_password': newPassword,
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );
    } on DioException {
      rethrow;
    }
  }

  /// Get dashboard stats (API Mapping #25)
  /// GET /store/account/dashboard
  Future<DashboardStats> getDashboard() async {
    try {
      final response = await _dio.get(ApiEndpoints.getDashboard);
      if (response.data is String) {
        return DashboardStats.fromHtml(response.data as String);
      }
      return DashboardStats.fromJson(response.data as Map<String, dynamic>);
    } on DioException {
      rethrow;
    }
  }

  /// Extract CSRF token from HTML page
  /// Checks 3 patterns: name-before-value, value-before-name, JS variable
  String extractCsrfToken(String html) {
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
