import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../core/config/env_config.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/storage/local_storage.dart';
import '../../../core/utils/csrf_service.dart';
import '../../../core/utils/html_parser_util.dart';
import '../models/dashboard_stats_model.dart';
import '../models/notification_settings_model.dart';
import '../models/user_model.dart';

class ProfileService {
  final DioClient _dio = DioClient();
  final CsrfService _csrf = CsrfService.instance;
  final LocalStorageService _localStorage = LocalStorageService.instance;

  /// Get current user profile (API Mapping #22)
  /// GET /store/account/profile
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
  /// POST /store/account/profile
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
      if (e.error is AuthFailure) {
        throw Exception((e.error as AuthFailure).message);
      }
      if (e.error is Failure) {
        throw Exception((e.error as Failure).message);
      }
      if (e.response?.data is String && (e.response!.data as String).isNotEmpty) {
        final error = HtmlParserUtil.extractFormError(e.response!.data as String);
        if (error != null) throw Exception(error);
      }
      throw Exception(e.message ?? 'Failed to update profile.');
    }
  }

  /// Change password (API Mapping #24)
  /// POST /store/account/password
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    User? user,
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
        'existing_password': currentPassword,
        'password_current': currentPassword,
        'new_password': newPassword,
        'password': newPassword,
        'new_password_confirmation': newPassword,
        'password_confirmation': newPassword,
        'confirm_password': newPassword,
        'confirm_new_password': newPassword,
        'password_confirm': newPassword,
        'action': 'change_password',
        'update_type': 'password',
        'type': 'password',
        if (user != null) ...{
          if (user.firstName.isNotEmpty) 'first_name': user.firstName,
          if (user.lastName.isNotEmpty) 'last_name': user.lastName,
          if (user.phone.isNotEmpty) 'phone': user.phone,
          if (user.email.isNotEmpty) 'email': user.email,
        },
      };

      final response = await _dio.post<dynamic>(
        ApiEndpoints.changePassword,
        data: formData,
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
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

      // 302 redirect is the standard PHP success response upon updating DB
      if (status == 302) {
        final location = response.headers.value('location') ?? '';
        if (location.contains('/login')) {
          throw Exception('Session expired. Please log in again.');
        }
        return;
      }

      if (rawData is String && rawData.isNotEmpty) {
        final lower = rawData.toLowerCase();
        if (lower.contains('password updated') ||
            lower.contains('password changed') ||
            lower.contains('alert-success')) {
          return;
        }

        final error = HtmlParserUtil.extractFormError(rawData);
        if (error != null) {
          throw Exception(error);
        }

        // If returned 200 without positive confirmation or redirect, DB was not updated
        throw Exception('Current password incorrect or server could not update password. Please try again.');
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('No internet connection. Please try again.');
      }
      if (e.error is AuthFailure) {
        throw Exception((e.error as AuthFailure).message);
      }
      if (e.error is Failure) {
        throw Exception((e.error as Failure).message);
      }
      if (e.response?.data is String && (e.response!.data as String).isNotEmpty) {
        final error = HtmlParserUtil.extractFormError(e.response!.data as String);
        if (error != null) throw Exception(error);
      }
      throw Exception(e.message ?? 'Failed to change password. Please check your credentials and try again.');
    }
  }

  /// Get dashboard stats (API Mapping #25)
  /// GET /store/account/dashboard
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

  /// Get notification preferences
  Future<NotificationSettings> getNotificationSettings() async {
    final localOrder = _localStorage.getBool(StorageKeys.notifOrderUpdates) ?? true;
    final localPromos = _localStorage.getBool(StorageKeys.notifPromotions) ?? false;
    final localEmail = _localStorage.getBool(StorageKeys.notifEmail) ?? true;

    var currentSettings = NotificationSettings(
      orderUpdates: localOrder,
      promotions: localPromos,
      emailNotifications: localEmail,
    );

    try {
      final response = await _dio.get<dynamic>(
        ApiEndpoints.notificationSettings,
        options: Options(
          validateStatus: (s) => s != null && s < 500,
          headers: {'Accept': 'application/json'},
        ),
      );

      if (response.statusCode == 200 && response.data is Map<String, dynamic>) {
        final serverSettings = NotificationSettings.fromJson(
          response.data as Map<String, dynamic>,
        );
        currentSettings = serverSettings;
        await _localStorage.setBool(StorageKeys.notifOrderUpdates, serverSettings.orderUpdates);
        await _localStorage.setBool(StorageKeys.notifPromotions, serverSettings.promotions);
        await _localStorage.setBool(StorageKeys.notifEmail, serverSettings.emailNotifications);
      }
    } catch (e) {
      developer.log('[ProfileService] getNotificationSettings fallback to cache: $e', name: 'profile');
    }

    return currentSettings;
  }

  /// Update notification preferences (API & Local Storage & OneSignal)
  Future<void> updateNotificationSettings(NotificationSettings settings) async {
    // 1. Immediately cache locally
    await _localStorage.setBool(StorageKeys.notifOrderUpdates, settings.orderUpdates);
    await _localStorage.setBool(StorageKeys.notifPromotions, settings.promotions);
    await _localStorage.setBool(StorageKeys.notifEmail, settings.emailNotifications);

    // 2. Update OneSignal push tags
    await NotificationService.instance.updateNotificationPreferences(
      orderUpdates: settings.orderUpdates,
      promotions: settings.promotions,
      emailNotifications: settings.emailNotifications,
    );

    // 3. Send to backend endpoints
    try {
      final pushToken = NotificationService.instance.pushToken;
      final csrfToken = await _csrf.fetchToken(ApiEndpoints.profilePage) ?? '';

      final payload = {
        ...settings.toJson(),
        ...settings.toFormData(),
        if (pushToken != null && pushToken.isNotEmpty) 'push_token': pushToken,
        if (csrfToken.isNotEmpty) ...{
          '_csrf_token': csrfToken,
          'csrf_token': csrfToken,
        },
      };

      await _dio.post<dynamic>(
        ApiEndpoints.notificationSettings,
        data: payload,
        options: Options(
          contentType: 'application/json',
          validateStatus: (s) => s != null && s < 500,
        ),
      );
    } catch (e) {
      developer.log('[ProfileService] updateNotificationSettings sync warning: $e', name: 'profile');
    }
  }
}
