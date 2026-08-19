import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../errors/failures.dart';

/// Interceptor to detect and handle session expiry and CSRF errors.
///
/// SoftStore uses session cookies (not JWT). Session expiry manifests as:
///   - 302 redirect to /login
///
/// CSRF expiry manifests as:
///   - 419 status code
///
/// Both are surfaced as [AuthFailure] so callers can clear session and
/// redirect the user to the login screen.
class AuthInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final status = response.statusCode;
    final location = response.headers.value('location') ?? '';
    final path = response.requestOptions.path;

    // Do NOT treat 302 on login or register as session expired
    if (path.contains('/login') || path.contains('/register')) {
      return handler.next(response);
    }

    // 302 → /login means the session cookie has expired
    if (status == 302 && location.contains('/login')) {
      developer.log(
        '[AuthInterceptor] Session expired — redirect to /login',
        name: 'auth',
      );
      final error = DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.unknown,
        error: const AuthFailure('Session expired. Please login again.'),
      );
      return handler.reject(error);
    }

    // 419 = CSRF token expired (server-side)
    if (status == 419) {
      developer.log('[AuthInterceptor] CSRF token expired (419)', name: 'auth');
      final error = DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.unknown,
        error: const AuthFailure(
          'csrf_expired',
        ),
      );
      return handler.reject(error);
    }

    // Legacy: treat 401 as session expired as well
    if (status == 401) {
      developer.log('[AuthInterceptor] Unauthorized (401)', name: 'auth');
      final error = DioException(
        requestOptions: response.requestOptions,
        response: response,
        type: DioExceptionType.unknown,
        error: const AuthFailure('Session expired. Please login again.'),
      );
      return handler.reject(error);
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final status = err.response?.statusCode;
    if (status == 401 || status == 419) {
      developer.log(
        '[AuthInterceptor] Auth error ($status)',
        name: 'auth',
      );
    }
    handler.next(err);
  }
}

