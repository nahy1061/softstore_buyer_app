import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio_cookie_manager/dio_cookie_manager.dart';
import '../constants/app_constants.dart';
import 'api_error.dart';

// SSL.com TLS RSA Root CA 2022 — bundled so the app trusts softstore.pk's
// certificate chain even on devices whose system store hasn't received this
// CA via a Play-Services or OTA update yet.
const _kSslComRootCA2022 = '''-----BEGIN CERTIFICATE-----
MIIFiTCCA3GgAwIBAgIQb77arXO9CEDii02+1PdbkTANBgkqhkiG9w0BAQsFADBO
MQswCQYDVQQGEwJVUzEYMBYGA1UECgwPU1NMIENvcnBvcmF0aW9uMSUwIwYDVQQD
DBxTU0wuY29tIFRMUyBSU0EgUm9vdCBDQSAyMDIyMB4XDTIyMDgyNTE2MzQyMloX
DTQ2MDgxOTE2MzQyMVowTjELMAkGA1UEBhMCVVMxGDAWBgNVBAoMD1NTTCBDb3Jw
b3JhdGlvbjElMCMGA1UEAwwcU1NMLmNvbSBUTFMgUlNBIFJvb3QgQ0EgMjAyMjCC
AiIwDQYJKoZIhvcNAQEBBQADggIPADCCAgoCggIBANCkCXJPQIgSYT41I57u9nTP
L3tYPc48DRAokC+X94xI2KDYJbFMsBFMF3NQ0CJKY7uB0ylu1bUJPiYYf7ISf5OY
t6/wNr/y7hienDtSxUcZXXTzZGbVXcdotL8bHAajvI9AI7YexoS9UcQbOcGV0ins
S657Lb85/bRi3pZ7QcacoOAGcvvwB5cJOYF0r/c0WRFXCsJbwST0MXMwgsadugL3
PnxEX4MN8/HdIGkWCVDi1FW24IBydm5MR7d1VVm0U3TZlMZBrViKMWYPHqIbKUBO
L9975hYsLfy/7PO0+r4Y9ptJ1O4Fbtk085zx7AGL0SDGD6C1vBdOSHtRwvzpXGk3
R2azaPgVKPC506QVzFpPulJwoxJF3ca6TvvC0PeoUidtbnm1jPx7jMEWTO6Af77w
dr5BUxIzrlo4QqvXDz5BjXYHMtWrifZOZ9mxQnUjbvPNQrL8VfVThxc7wDNY8VLS
+YCk8OjwO4s4zKTGkH8PnP2L0aPP2oOnaclQNtVcBdIKQXTbYxE3waWglksejBYS
d66UNHsef8JmAOSqg+qKkK3ONkRN0VHpvB/zagX9wHQfJRlAUW7qglFA35u5CCoG
AtUjHBPW6dvbxrB6y3snm/vg1UYk7RBLY0ulBY+6uB0rpvqR4pJSvezrZ5dtmi2f
gTIFZzL7SAg/2SW4BCUvAgMBAAGjYzBhMA8GA1UdEwEB/wQFMAMBAf8wHwYDVR0j
BBgwFoAU+y437uOEeicuzRk1sTN8/9REQrkwHQYDVR0OBBYEFPsuN+7jhHonLs0Z
NbEzfP/UREK5MA4GA1UdDwEB/wQEAwIBhjANBgkqhkiG9w0BAQsFAAOCAgEAjYlt
hEUY8U+zoO9opMAdrDC8Z2awms22qyIZZtM7QbUQnRC6cm4pJCAcAZli05bg4vsM
QtfhWsSWTVTNj8pDU/0quOr4ZcoBwq1gaAafORpR2eCNJvkLTqVTJXojpBzOCBvf
R4iyrT7gJ4eLSYwfqUdYe5byiB0YrrPRpgqU+tvT5TgKa3kSM/tKWTcWQA673vWJ
DPFs0/dRa1419dvAJuoSc06pkZCmF8NsLzjUo3KUQyxi4U5cMj29TH0ZR6LDSeeW
P4+a0zvkEdiLA9z2tmBVGKaBUfPhqBVq6+AL8BQx1rmMRTqoENjwuSfr98t67wVy
lrXEj5ZzxOhWc5y8aVFjvO9nHEMaX3cZHxj4HCUp+UmZKbaSPaKDN7EgkaibMOlq
bLQjk2UEqxHzDh1TJElTHaE/nUiSEeJ9DU/1172iWD54nR4fK/4huxoTtrEoZP2w
AgDHbICivRZQIA9ygV/MlP+7mea6kMvq+cYMwq7FGc4zoWtcu358NFcXrfA/rs3q
r5nsLFR+jM4uElZI7xc7P0peYNLcdDa8pUNjyw9bowJWCZ4kLOGGgYz+qxcs+sji
Mho6/4UIyYOf8kpIEFR3N+2ivEC+5BB09+Rbu7nzifmPQdjH5FCQNYA+HLhNkNPU
98OwoX6EyneSMSy4kLGCenROmxMmtNVQZlR4rmA=
-----END CERTIFICATE-----''';

class WebSessionClient {
  static final WebSessionClient shared = WebSessionClient._();

  late final Dio _dio;
  final CookieJar _cookieJar = CookieJar();

  WebSessionClient._() {
    _dio = Dio(BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: const Duration(seconds: AppConstants.requestTimeout),
      receiveTimeout: const Duration(seconds: AppConstants.requestTimeout),
      headers: {
        'User-Agent': AppConstants.userAgent,
      },
      followRedirects: true,
      maxRedirects: 5,
      validateStatus: (status) => status != null && status < 600,
    ));

    // On mobile/desktop (not web), configure a custom HttpClient that
    // explicitly trusts the SSL.com 2022 root CA that softstore.pk uses,
    // in case the device's system store hasn't been updated to include it.
    if (!kIsWeb) {
      _dio.httpClientAdapter = IOHttpClientAdapter(
        createHttpClient: () {
          final ctx = SecurityContext(withTrustedRoots: true);
          try {
            ctx.setTrustedCertificatesBytes(utf8.encode(_kSslComRootCA2022));
          } catch (_) {
            // Ignore if already present or unsupported on this platform.
          }
          return HttpClient(context: ctx)
            ..connectionTimeout = const Duration(seconds: AppConstants.requestTimeout);
        },
      );
    }

    _dio.interceptors.add(CookieManager(_cookieJar));
  }

  bool get isSignedIn => false; // checked asynchronously via checkSignedIn()

  Future<bool> checkSignedIn() async {
    final cookies = await _cookieJar.loadForRequest(Uri.parse(AppConstants.baseUrl));
    return cookies.any((c) => c.name == AppConstants.sessionCookieName);
  }

  Future<void> clearSession() async {
    await _cookieJar.deleteAll();
  }

  // MARK: - CSRF
  Future<String> fetchCsrf(String path) async {
    final html = await fetchHtml(path);
    final token = scrapeCSRF(html);
    if (token == null) throw ApiError('Could not read security token. Please try again.');
    return token;
  }

  String? scrapeCSRF(String html) {
    // name before value
    var m = RegExp(r'name="_csrf_token"[^>]{0,120}value="([^"]+)"').firstMatch(html);
    if (m != null) return m.group(1);
    // value before name
    m = RegExp(r'value="([^"]+)"[^>]{0,120}name="_csrf_token"').firstMatch(html);
    if (m != null) return m.group(1);
    // JS variable
    m = RegExp(r"csrfToken\s*=\s*'([^']{20,})'").firstMatch(html);
    if (m != null) return m.group(1);
    return null;
  }

  // MARK: - HTML fetch
  Future<String> fetchHtml(String path) async {
    try {
      final response = await _dio.get(
        path,
        options: Options(headers: {
          'Accept': 'text/html,application/xhtml+xml',
          'User-Agent': AppConstants.userAgent,
        }),
      );
      _validateHttp(response);
      return response.data?.toString() ?? '';
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Future<({String html, String finalUrl})> fetchHtmlWithFinalUrl(String path) async {
    try {
      final response = await _dio.get(
        path,
        options: Options(headers: {
          'Accept': 'text/html,application/xhtml+xml',
          'User-Agent': AppConstants.userAgent,
        }),
      );
      _validateHttp(response);
      final finalUrl = response.realUri.toString();
      return (html: response.data?.toString() ?? '', finalUrl: finalUrl);
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // MARK: - Form POST (returns HTML)
  Future<({String html, String finalUrl})> postForm(
    String path,
    Map<String, String> fields, {
    String? referer,
  }) async {
    final ref = referer != null
        ? '${AppConstants.baseUrl}$referer'
        : '${AppConstants.baseUrl}$path';

    Future<Response> buildAndSend(Map<String, String> f) async {
      final headers = <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'text/html,application/xhtml+xml,*/*;q=0.9',
        'User-Agent': AppConstants.userAgent,
        'Referer': ref,
      };
      final fCsrf = f['_csrf_token'];
      if (fCsrf != null) headers['X-CSRF-TOKEN'] = fCsrf;
      return _dio.post(
        path,
        data: _urlEncode(f),
        options: Options(headers: headers, validateStatus: (s) => s != null && s < 600),
      );
    }

    try {
      var response = await buildAndSend(fields);
      if (response.statusCode == 419) {
        final freshHtml = await fetchHtml(path);
        final freshToken = scrapeCSRF(freshHtml);
        if (freshToken == null) throw ApiError('Your session security token expired. Please try again.');
        final updated = {...fields, '_csrf_token': freshToken};
        response = await buildAndSend(updated);
        if (response.statusCode == 419) throw ApiError('Your session security token expired. Please try again.');
      }
      _validateHttp(response);
      return (html: response.data?.toString() ?? '', finalUrl: response.realUri.toString());
    } on ApiError {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // MARK: - Form POST → JSON
  Future<T> postFormJson<T>(
    String path,
    Map<String, String> fields,
    String csrfToken,
    T Function(Map<String, dynamic>) fromJson,
  ) async {
    Future<Response> buildAndSend(Map<String, String> f, String csrf) async {
      return _dio.post(
        path,
        data: _urlEncode(f),
        options: Options(headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'Referer': AppConstants.baseUrl,
          'X-CSRF-TOKEN': csrf,
          'User-Agent': AppConstants.userAgent,
        }, validateStatus: (s) => s != null && s < 600),
      );
    }

    try {
      var response = await buildAndSend(fields, csrfToken);
      if (response.statusCode == 419) {
        final freshHtml = await fetchHtml(path);
        final freshToken = scrapeCSRF(freshHtml) ?? csrfToken;
        final updated = {...fields, '_csrf_token': freshToken};
        response = await buildAndSend(updated, freshToken);
      }
      _validateJson(response);
      return fromJson(_decodeJson(response));
    } on ApiError {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // MARK: - JSON POST → JSON
  Future<T> postJson<T>(
    String path,
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJson, {
    String? csrfToken,
  }) async {
    Future<Response> buildAndSend(Map<String, dynamic> j, String? csrf) async {
      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-Requested-With': 'XMLHttpRequest',
        'Referer': AppConstants.baseUrl,
        'User-Agent': AppConstants.userAgent,
      };
      if (csrf != null) headers['X-CSRF-TOKEN'] = csrf;
      return _dio.post(
        path,
        data: jsonEncode(j),
        options: Options(headers: headers, validateStatus: (s) => s != null && s < 600),
      );
    }

    try {
      var response = await buildAndSend(json, csrfToken);
      if (response.statusCode == 419) {
        final freshHtml = await fetchHtml(path);
        final freshToken = scrapeCSRF(freshHtml);
        var updated = Map<String, dynamic>.from(json);
        if (updated.containsKey('_csrf_token') && freshToken != null) updated['_csrf_token'] = freshToken;
        if (updated.containsKey('csrf_token') && freshToken != null) updated['csrf_token'] = freshToken;
        response = await buildAndSend(updated, freshToken ?? csrfToken);
      }
      _validateJson(response);
      return fromJson(_decodeJson(response));
    } on ApiError {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // MARK: - JSON GET
  Future<T> fetchJson<T>(
    String path,
    T Function(dynamic) fromJson, {
    Map<String, String> query = const {},
  }) async {
    try {
      final response = await _dio.get(
        path,
        queryParameters: query.isEmpty ? null : query,
        options: Options(headers: {
          'Accept': 'application/json',
          'User-Agent': AppConstants.userAgent,
        }, validateStatus: (s) => s != null && s < 600),
      );
      _validateJson(response);
      return fromJson(response.data);
    } on ApiError {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // MARK: - Multipart POST
  Future<({String html, String finalUrl})> postMultipart(
    String path,
    Map<String, String> fields,
    String fileFieldName,
    List<({String filename, String mimeType, List<int> data})> files, {
    String? referer,
  }) async {
    final ref = referer != null
        ? '${AppConstants.baseUrl}$referer'
        : '${AppConstants.baseUrl}$path';

    final formData = FormData();
    for (final entry in fields.entries) {
      formData.fields.add(MapEntry(entry.key, entry.value));
    }
    for (final file in files) {
      formData.files.add(MapEntry(
        '$fileFieldName[]',
        MultipartFile.fromBytes(file.data,
            filename: file.filename,
            contentType: DioMediaType.parse(file.mimeType)),
      ));
    }

    try {
      final csrf = fields['_csrf_token'];
      final headers = <String, String>{
        'Accept': 'text/html,*/*',
        'Referer': ref,
        'User-Agent': AppConstants.userAgent,
      };
      if (csrf != null) headers['X-CSRF-TOKEN'] = csrf;

      final response = await _dio.post(
        path,
        data: formData,
        options: Options(headers: headers, validateStatus: (s) => s != null && s < 600),
      );
      _validateHttp(response);
      return (html: response.data?.toString() ?? '', finalUrl: response.realUri.toString());
    } on ApiError {
      rethrow;
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  // MARK: - Helpers
  void _validateHttp(Response response) {
    final status = response.statusCode ?? 0;
    if (status == 404) throw ApiError.server(404, 'Page not found.');
    if (status >= 500) throw ApiError.server(status, 'Server error. Please try again.');
  }

  void _validateJson(Response response) {
    final status = response.statusCode ?? 0;
    if (status >= 400) {
      final data = response.data;
      String msg = 'Something went wrong.';
      String? code;
      if (data is Map) {
        msg = data['message'] as String? ?? data['error'] as String? ?? msg;
        code = data['code'] as String?;
      }
      if (status == 401) throw ApiError.unauthorized(msg);
      throw ApiError.server(status, msg, code: code);
    }
  }

  Map<String, dynamic> _decodeJson(Response response) {
    final data = response.data;
    if (data is Map<String, dynamic>) return data;
    if (data is String) {
      try {
        return jsonDecode(data) as Map<String, dynamic>;
      } catch (_) {
        throw ApiError.decoding();
      }
    }
    throw ApiError.decoding();
  }

  String _urlEncode(Map<String, String> fields) {
    return fields.entries
        .map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}')
        .join('&');
  }

  ApiError _mapDioError(DioException e) {
    debugPrint('[WebSessionClient] DioException type=${e.type} msg=${e.message} inner=${e.error}');
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return ApiError.timeout();
      case DioExceptionType.connectionError:
        // Include underlying error details so we can diagnose SSL vs network issues.
        final inner = e.error;
        final detail = inner?.toString() ?? e.message ?? 'unknown';
        if (detail.toLowerCase().contains('handshake') || detail.toLowerCase().contains('certificate')) {
          return ApiError('SSL error – certificate not trusted. ($detail)');
        }
        if (kDebugMode) {
          return ApiError('Connection failed: $detail');
        }
        return ApiError.offline();
      default:
        return ApiError(e.message ?? 'Unknown network error');
    }
  }
}
