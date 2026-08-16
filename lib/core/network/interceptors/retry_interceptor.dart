import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../constants/app_config.dart';

/// Interceptor to retry failed requests with exponential backoff.
/// Retries on timeout (408) and server errors (5xx).
/// Skips retries on client errors (4xx except 408) and auth errors.
class RetryInterceptor extends Interceptor {
  static const String _retryCountKey = 'retry_count';

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    final requestOptions = err.requestOptions;

    // Get current retry count (stored in request extra)
    int retryCount = (requestOptions.extra[_retryCountKey] ?? 0) as int;

    // Check if we should retry
    if (_shouldRetry(err) && retryCount < AppConfig.maxRetries) {
      retryCount++;
      requestOptions.extra[_retryCountKey] = retryCount;

      // Calculate exponential backoff delay
      final delaySeconds = _calculateBackoffSeconds(retryCount);
      developer.log('[RetryInterceptor] Retrying request (attempt $retryCount/$maxRetries) after ${delaySeconds}s: ${requestOptions.path}', name: 'network');

      // Wait before retrying
      await Future.delayed(Duration(seconds: delaySeconds));

      try {
        final response = await _retry(requestOptions);
        handler.resolve(response);
        return;
      } catch (e) {
        handler.next(DioException(
          requestOptions: requestOptions,
          response: e is DioException ? e.response : null,
          type: e is DioException ? e.type : DioExceptionType.unknown,
          error: e,
        ));
        return;
      }
    }

    // No retry or max retries exceeded
    handler.next(err);
  }

  /// Check if error should be retried
  bool _shouldRetry(DioException err) {
    // Retry on timeout
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout) {
      return true;
    }

    // Retry on 408 (Request Timeout)
    if (err.response?.statusCode == 408) {
      return true;
    }

    // Retry on 5xx (Server errors)
    final statusCode = err.response?.statusCode;
    if (statusCode != null && statusCode >= 500 && statusCode < 600) {
      return true;
    }

    return false;
  }

  /// Calculate exponential backoff delay in seconds
  int _calculateBackoffSeconds(int retryCount) {
    // 1st retry: 1s, 2nd retry: 2s, etc.
    return retryCount;
  }

  /// Retry the request using Dio instance
  Future<Response> _retry(RequestOptions requestOptions) async {
    final dio = Dio(BaseOptions(
      method: requestOptions.method,
      baseUrl: requestOptions.baseUrl,
      headers: requestOptions.headers,
      contentType: requestOptions.contentType,
    ));

    return dio.request(
      requestOptions.path,
      data: requestOptions.data,
      queryParameters: requestOptions.queryParameters,
      options: Options(method: requestOptions.method),
    );
  }
}

const int maxRetries = 2;
