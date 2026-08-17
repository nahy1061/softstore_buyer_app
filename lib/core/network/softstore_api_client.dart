import 'dart:async';
import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter/foundation.dart';

/// Dedicated HTTP client for the SoftStore PHP backend.
///
/// This backend uses session cookies (SOFTSTORE_SESSID) for auth instead of
/// Bearer tokens, and requires CSRF tokens for POST requests to /store/* routes.
///
/// ## CORS strategy (Flutter Web)
///
/// On web, Dio uses `XMLHttpRequest` which the browser subjects to CORS.
/// A *preflight* (OPTIONS) is triggered whenever:
/// - `Content-Type` is NOT one of `application/x-www-form-urlencoded`,
///   `multipart/form-data`, or `text/plain`
/// - Any custom header is sent (e.g. `X-Requested-With`, `X-CSRF-TOKEN`)
///
/// The softstore.pk backend may not handle OPTIONS preflight yet, so this
/// client deliberately avoids triggering one:
/// - All requests use `Content-Type: text/plain` (CORS-safelisted) with a
///   JSON string body.  PHP reads the raw body via `php://input` and
///   `json_decode()` regardless of Content-Type.
/// - No custom headers are sent.  The CSRF token is passed in the body
///   (`_csrf_token` / `csrf_token` fields) instead of an `X-CSRF-TOKEN`
///   header.
/// - Cookies are managed by the browser natively on web.
///
/// The server **must** still return `Access-Control-Allow-Origin` and
/// `Access-Control-Allow-Credentials` on every response so the browser lets
/// JS read the body.  See the CORS setup instructions in the project docs.
class SoftstoreApiClient {
  static final SoftstoreApiClient _instance = SoftstoreApiClient._();
  factory SoftstoreApiClient() => _instance;

  final Dio _dio;

  CookieJar? _cookieJar;
  bool _cookieJarReady = false;
  final Completer<void> _cookieJarCompleter = Completer<void>();

  static const String _defaultBaseUrl = 'https://softstore.pk';

  static String get _baseUrl {
    const envUrl = String.fromEnvironment('BASE_URL');
    return envUrl.isNotEmpty ? envUrl : _defaultBaseUrl;
  }

  /// CORS-safe content type.  `text/plain` is a CORS-safelisted value, so
  /// the browser will NOT send an OPTIONS preflight.  PHP still reads the
  /// JSON body from `php://input` regardless of the Content-Type header.
  static const String _jsonOverTextPlain = 'text/plain';

  SoftstoreApiClient._()
      : _dio = Dio(BaseOptions(
          baseUrl: _baseUrl,
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        )) {
    _initCookieJar();
  }

  Future<void> _initCookieJar() async {
    try {
      if (kIsWeb) {
        // PersistCookieJar requires dart:io (FileStorage).  On web the browser
        // manages cookies natively, so a plain in-memory CookieJar is enough
        // for the CookieManager interceptor to process Set-Cookie headers.
        _cookieJar = CookieJar();
      } else {
        final dir = await getApplicationDocumentsDirectory();
        _cookieJar = PersistCookieJar(
          storage: FileStorage('${dir.path}/.softstore_cookies/'),
        );
      }

      // On web, the browser natively manages and sends cookies for the
      // domain — we do NOT add CookieManager because it explicitly sets a
      // Cookie header via xhr.setRequestHeader(), which is NOT a
      // CORS-safelisted header and triggers a preflight OPTIONS request.
      if (!kIsWeb) {
        _dio.interceptors.add(CookieManager(_cookieJar!));
      }
      _dio.interceptors.add(LogInterceptor(
        request: kDebugMode,
        requestHeader: kDebugMode,
        requestBody: kDebugMode,
        responseHeader: kDebugMode,
        responseBody: kDebugMode,
        error: true,
      ));

      _cookieJarReady = true;
      _cookieJarCompleter.complete();
    } catch (e) {
      _cookieJarReady = true;
      if (!_cookieJarCompleter.isCompleted) {
        _cookieJarCompleter.complete();
      }
    }
  }

  Future<void> _ensureReady() async {
    if (_cookieJarReady) return;
    return _cookieJarCompleter.future;
  }

  Future<void> init() => _ensureReady();

  Dio get dio => _dio;

  // ── CSRF ──────────────────────────────────────────────────────────────────

  /// Fetches [pageUrl] and extracts the CSRF token from:
  /// 1. `<input name="_csrf_token" value="...">`
  /// 2. `<meta name="csrf-token" content="...">`
  /// 3. JS variable `csrfToken = '...'`
  Future<String> fetchCsrfToken(String pageUrl) async {
    await _ensureReady();
    final response = await _dio.get(
      pageUrl,
      options: Options(responseType: ResponseType.plain),
    );
    final html = response.data.toString();

    // Pattern 1a: name before value
    final inputPattern = RegExp(
      r"""<input[^>]+name=["']_csrf_token["'][^>]+value=["']([^"']+)["']""",
      caseSensitive: false,
    );
    final inputMatch = inputPattern.firstMatch(html);
    if (inputMatch != null) return inputMatch.group(1)!;

    // Pattern 1b: value before name
    final inputPattern2 = RegExp(
      r"""<input[^>]+value=["']([^"']+)["'][^>]+name=["']_csrf_token["']""",
      caseSensitive: false,
    );
    final inputMatch2 = inputPattern2.firstMatch(html);
    if (inputMatch2 != null) return inputMatch2.group(1)!;

    // Pattern 2a: meta name="csrf-token"
    final metaPattern = RegExp(
      r"""<meta[^>]+name=["']csrf-token["'][^>]+content=["']([^"']+)["']""",
      caseSensitive: false,
    );
    final metaMatch = metaPattern.firstMatch(html);
    if (metaMatch != null) return metaMatch.group(1)!;

    // Pattern 2b: content before name
    final metaPattern2 = RegExp(
      r"""<meta[^>]+content=["']([^"']+)["'][^>]+name=["']csrf-token["']""",
      caseSensitive: false,
    );
    final metaMatch2 = metaPattern2.firstMatch(html);
    if (metaMatch2 != null) return metaMatch2.group(1)!;

    // Pattern 3: JS variable
    final jsPattern = RegExp(
      r"""csrfToken\s*=\s*['"]([^'"]+)['"]""",
      caseSensitive: false,
    );
    final jsMatch = jsPattern.firstMatch(html);
    if (jsMatch != null) return jsMatch.group(1)!;

    throw Exception('CSRF token not found in page: $pageUrl');
  }

  /// Performs a CSRF-protected POST request.
  ///
  /// 1. Fetches a fresh CSRF token from [pageUrl]
  /// 2. POSTs to [endpoint] with JSON body encoded as `text/plain` and the
  ///    CSRF token included in the body fields (`_csrf_token` / `csrf_token`).
  ///    No custom headers are sent, so the browser does NOT trigger an
  ///    OPTIONS preflight.
  /// 3. Automatically retries once if 419 is returned (CSRF expiry)
  Future<Response> csrfProtectedRequest({
    required String pageUrl,
    required String endpoint,
    required Map<String, dynamic> Function(String csrfToken) buildBody,
  }) async {
    return _csrfPost(
      pageUrl,
      endpoint,
      buildBody,
      isRetry: false,
    );
  }

  Future<Response> _csrfPost(
    String pageUrl,
    String endpoint,
    Map<String, dynamic> Function(String csrfToken) buildBody, {
    required bool isRetry,
  }) async {
    await _ensureReady();
    final csrfToken = await fetchCsrfToken(pageUrl);
    final body = buildBody(csrfToken);

    try {
      final response = await _dio.post(
        endpoint,
        data: jsonEncode(body),
        options: Options(
          contentType: _jsonOverTextPlain,
          responseType: ResponseType.json,
        ),
      );
      return response;
    } on DioException catch (e) {
      if (e.response?.statusCode == 419 && !isRetry) {
        return _csrfPost(
          pageUrl,
          endpoint,
          buildBody,
          isRetry: true,
        );
      }
      rethrow;
    }
  }

  // ── Plain requests (for /api/* and /store/checkout/* endpoints) ─────────

  /// Makes a POST request with a JSON body encoded as `text/plain`.
  ///
  /// `text/plain` is a CORS-safelisted Content-Type so the browser will NOT
  /// send an OPTIONS preflight.  The server reads the JSON body from
  /// `php://input` regardless of the Content-Type header.
  Future<Response> postJson(
    String endpoint, {
    dynamic data,
  }) async {
    await _ensureReady();
    return _dio.post(
      endpoint,
      data: data is String ? data : jsonEncode(data),
      options: Options(
        contentType: _jsonOverTextPlain,
        responseType: ResponseType.json,
      ),
    );
  }

  // ── User-friendly error messages ─────────────────────────────────────────

  /// Returns a human-readable message for [DioException] errors.
  static String humanReadableError(Object error) {
    if (error is DioException) {
      switch (error.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.connectionTimeout:
          return 'Can\'t reach the server. Please check your internet connection and try again.';

        case DioExceptionType.sendTimeout:
          return 'The request took too long to send. Please check your connection.';

        case DioExceptionType.receiveTimeout:
          return 'The server took too long to respond. Please try again.';

        case DioExceptionType.badResponse:
          final status = error.response?.statusCode;
          if (status == 419) return 'Your session expired. Please try again.';
          if (status == 404) return 'Page not found.';
          if (status == 500) {
            return 'Something went wrong on our end. Please try again later.';
          }
          if (status != null && status >= 400 && status < 500) {
            return 'Request failed ($status). Please check your input and try again.';
          }
          if (status != null && status >= 500) {
            return 'Server error ($status). Please try again later.';
          }
          return 'Unexpected server response. Please try again.';

        case DioExceptionType.cancel:
          return 'Request was cancelled.';

        case DioExceptionType.badCertificate:
          return 'Security certificate error. Please try again later.';

        case DioExceptionType.transformTimeout:
        case DioExceptionType.unknown:
          final msg = error.message ?? '';
          if (msg.contains('XMLHttpRequest') || msg.contains('CORS')) {
            return 'Can\'t connect to the server. This may be a temporary issue — please try again in a moment.';
          }
          return 'A network error occurred. Please check your connection and try again.';
      }
    }

    final msg = error.toString();
    if (msg.contains('SocketException') || msg.contains('HandshakeException')) {
      return 'Can\'t reach the server. Please check your internet connection.';
    }

    return 'An unexpected error occurred. Please try again.';
  }
}
