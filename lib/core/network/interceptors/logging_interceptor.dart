import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../config/feature_flags.dart';

/// Interceptor to log HTTP requests and responses for debugging.
/// Respects feature flag enableNetworkLogging.
/// Never logs sensitive data (auth tokens, passwords).
class LoggingInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (FeatureFlags.enableNetworkLogging || FeatureFlags.enableDetailedLogs) {
      developer.log('[HTTP Request] ${options.method.toUpperCase()} ${options.path}', name: 'network');
      if (options.queryParameters.isNotEmpty) {
        developer.log('[Query Params] ${options.queryParameters}', name: 'network');
      }
      if (options.data != null) {
        developer.log('[Request Body] ${_sanitizeData(options.data)}', name: 'network');
      }
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (FeatureFlags.enableNetworkLogging || FeatureFlags.enableDetailedLogs) {
      developer.log('[HTTP Response] ${response.statusCode} ${response.requestOptions.path}', name: 'network');
      if (response.data != null) {
        developer.log('[Response Body] ${_sanitizeData(response.data)}', name: 'network');
      }
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (FeatureFlags.enableNetworkLogging || FeatureFlags.enableDetailedLogs) {
      developer.log('[HTTP Error] ${err.type} - ${err.message}', name: 'network');
      developer.log('[Error Path] ${err.requestOptions.path}', name: 'network');
      if (err.response != null) {
        developer.log('[Error Status] ${err.response?.statusCode}', name: 'network');
      }
    }
    handler.next(err);
  }

  /// Sanitize data to remove sensitive information
  dynamic _sanitizeData(dynamic data) {
    if (data is String) {
      return data;
    }
    if (data is Map) {
      final sanitized = Map<String, dynamic>.from(data);
      // Remove sensitive keys
      sanitized.remove('password');
      sanitized.remove('token');
      sanitized.remove('refreshToken');
      sanitized.remove('authToken');
      sanitized.remove('accessToken');
      sanitized.remove('fcmToken');
      sanitized.remove('otp');
      return sanitized;
    }
    return data;
  }
}
