import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../errors/failures.dart';

/// Interceptor to detect and handle 401 (Unauthorized) responses.
/// Triggers session expired event when token is invalid.
class AuthInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    if (response.statusCode == 401) {
      developer.log('[AuthInterceptor] Session expired (401)', name: 'auth');

      final error = DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.unknown,
        error: AuthFailure('Session expired. Please login again.'),
      );

      return handler.reject(error);
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      developer.log('[AuthInterceptor] Unauthorized error (401)', name: 'auth');
      return handler.reject(err);
    }

    handler.next(err);
  }
}
