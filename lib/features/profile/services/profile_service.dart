import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../core/config/env_config.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/csrf_service.dart';
import '../../../core/utils/html_parser_util.dart';
import '../models/dashboard_stats_model.dart';
import '../models/user_model.dart';

class ProfileService {
  final DioClient _dio = DioClient();
  final CsrfService _csrf = CsrfService.instance;

  /// Get current user profile (API Mapping #22)
  /// GET /marketplace/account/profile
  Future<User> getProfile() async {
    try {
      final response = await _dio.get<String>(
        ApiEndpoints.profilePage,
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (status) => status != null && status < 500,
          headers: {
            'User-Agent': 'SoftStoreBuyer/1.0 iOS',
            'Accept': 'text/html,application/xhtml+xml,*/*;q=0.9',
          },
        ),
      );
      final html = response.data ?? '';
      return User.fromHtml(html);
    } on DioException catch (e) {
      developer.log('[ProfileService] getProfile DioException: ${e.message}', name: 'profile');
      rethrow;
    } catch (e) {
      developer.log('[ProfileService] getProfile error: $e', name: 'profile');
      rethrow;
    }
  }

  /// Update user profile (API Mapping #23)
  /// POST /marketplace/account/profile
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
  }) async {
    try {
      final csrfToken = await _csrf.fetchToken(ApiEndpoints.profilePage) ?? '';

      final formData = <String, String>{
        if (csrfToken.isNotEmpty) ...{
          '_csrf_token': csrfToken,
          'csrf_token': csrfToken,
          '_token': csrfToken,
        },
        'first_name': firstName.trim(),
        'last_name': lastName.trim(),
        'name': '$firstName $lastName'.trim(),
        'full_name': '$firstName $lastName'.trim(),
        'phone': phone.trim(),
        'phone_number': phone.trim(),
        'action': 'update_profile',
      };

      final formBody = Uri(queryParameters: formData).query;

      final response = await _dio.post<dynamic>(
        ApiEndpoints.updateProfile,
        data: formBody,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          responseType: ResponseType.plain,
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
          headers: {
            'User-Agent': 'SoftStoreBuyer/1.0 iOS',
            'Referer': '${EnvConfig.baseUrl}/marketplace/account/profile',
            'Origin': EnvConfig.baseUrl,
            if (csrfToken.isNotEmpty) 'X-CSRF-TOKEN': csrfToken,
            'Accept': 'text/html,application/xhtml+xml,*/*;q=0.9',
          },
        ),
      );

      final status = response.statusCode ?? 0;
      final rawData = response.data;

      // 302 redirect is standard success in SoftStore PHP backend
      if (status == 302) {
        final location = response.headers.value('location') ?? '';
        if (location.contains('/login')) {
          throw Exception('Session expired. Please log in again.');
        }
        return;
      }

      if (rawData is String && rawData.isNotEmpty) {
        final error = HtmlParserUtil.extractFormError(rawData);
        if (error != null) {
          throw Exception(error);
        }
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('No internet connection. Please try again.');
      }
      throw Exception(e.message ?? 'Failed to update profile.');
    }
  }

  /// Change password (API Mapping #24)
  /// POST /marketplace/account/profile
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final csrfToken = await _csrf.fetchToken(ApiEndpoints.profilePage) ?? '';

      final formData = <String, String>{
        if (csrfToken.isNotEmpty) ...{
          '_csrf_token': csrfToken,
          'csrf_token': csrfToken,
          '_token': csrfToken,
        },
        'current_password': currentPassword,
        'old_password': currentPassword,
        'new_password': newPassword,
        'password': newPassword,
        'new_password_confirmation': newPassword,
        'password_confirmation': newPassword,
        'confirm_password': newPassword,
        'action': 'change_password',
      };

      final formBody = Uri(queryParameters: formData).query;

      final response = await _dio.post<dynamic>(
        ApiEndpoints.changePassword,
        data: formBody,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          responseType: ResponseType.plain,
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
          headers: {
            'User-Agent': 'SoftStoreBuyer/1.0 iOS',
            'Referer': '${EnvConfig.baseUrl}/marketplace/account/profile',
            'Origin': EnvConfig.baseUrl,
            if (csrfToken.isNotEmpty) 'X-CSRF-TOKEN': csrfToken,
            'Accept': 'text/html,application/xhtml+xml,*/*;q=0.9',
          },
        ),
      );

      final status = response.statusCode ?? 0;
      final rawData = response.data;

      if (status == 302) {
        final location = response.headers.value('location') ?? '';
        if (location.contains('/login')) {
          throw Exception('Session expired. Please log in again.');
        }
        return;
      }

      if (rawData is String && rawData.isNotEmpty) {
        final error = HtmlParserUtil.extractFormError(rawData);
        if (error != null) {
          throw Exception(error);
        }
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('No internet connection. Please try again.');
      }
      throw Exception(e.message ?? 'Failed to change password.');
    }
  }

  /// Get dashboard stats (API Mapping #25)
  /// GET /marketplace/account
  Future<DashboardStats> getDashboard() async {
    try {
      final response = await _dio.get<String>(
        ApiEndpoints.getDashboard,
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (s) => s != null && s < 500,
          headers: {
            'User-Agent': 'SoftStoreBuyer/1.0 iOS',
            'Accept': 'text/html,application/xhtml+xml,*/*;q=0.9',
          },
        ),
      );
      if (response.data is String && (response.data as String).isNotEmpty) {
        return DashboardStats.fromHtml(response.data as String);
      }
      return const DashboardStats();
    } catch (_) {
      return const DashboardStats();
    }
  }
}
