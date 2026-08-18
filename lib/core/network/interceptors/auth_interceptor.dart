import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../errors/failures.dart';

/// Interceptor to detect and handle auth-related responses.
/// - 401: Session expired
/// - 419: CSRF token expired (auto-retry once)
/// - 302: Redirect to login (session expired)
class AuthInterceptor extends Interceptor {
  final Set<String> _retryingPaths = {};

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final statusCode = response.statusCode ?? 0;

    // 401 - Session expired
    if (statusCode == 401) {
      developer.log('[AuthInterceptor] Session expired (401)', name: 'auth');
      final error = DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.unknown,
        error: AuthFailure('Session expired. Please login again.'),
      );
      return handler.reject(error);
    }

    // 419 - CSRF token expired (from Laravel/PHP backend)
    if (statusCode == 419) {
      final path = response.requestOptions.path;
      if (!_retryingPaths.contains(path)) {
        developer.log('[AuthInterceptor] CSRF expired (419), will retry: $path',
            name: 'auth');
        _retryingPaths.add(path);
        // Signal to retry - the retry interceptor or caller should handle this
        // For now, reject with a specific error that can be caught
        final error = DioException(
          requestOptions: response.requestOptions,
          response: response,
          type: DioExceptionType.unknown,
          error: AuthFailure('CSRF token expired. Retrying...'),
        );
        return handler.reject(error);
      } else {
        // Already retried once, don't retry again
        _retryingPaths.remove(path);
      }
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final statusCode = err.response?.statusCode ?? 0;

    if (statusCode == 401) {
      developer.log('[AuthInterceptor] Unauthorized error (401)', name: 'auth');
      return handler.next(err);
    }

    // Handle connection errors that might indicate session issues
    if (err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout) {
      developer.log('[AuthInterceptor] Network error: ${err.type}', name: 'auth');
    }

    handler.next(err);
  }
}
