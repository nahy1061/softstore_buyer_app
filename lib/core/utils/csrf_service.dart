import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../network/dio_client.dart';
import 'html_parser_util.dart';

/// Service for fetching and caching CSRF tokens from SoftStore pages.
///
/// SoftStore requires a `_csrf_token` (and sometimes also `csrf_token`) field
/// in the body of every mutating (POST/PUT/DELETE) form request.
///
/// This service:
///  1. GETs the relevant page to extract the CSRF token
///  2. Caches the token so sequential requests within one flow can reuse it
///  3. Automatically re-fetches on 419 (token expiry)
class CsrfService {
  CsrfService._();
  static final CsrfService instance = CsrfService._();

  final DioClient _dioClient = DioClient();

  /// In-memory cache: path → token
  final Map<String, String> _cache = {};

  /// Fetches and returns the CSRF token from [path].
  ///
  /// Returns null if the page does not contain a CSRF token (public pages).
  Future<String?> fetchToken(String path) async {
    try {
      final response = await _dioClient.get<String>(
        path,
        options: Options(responseType: ResponseType.plain),
      );
      final html = response.data as String? ?? '';
      final token = HtmlParserUtil.extractCsrfToken(html);
      if (token != null) {
        _cache[path] = token;
        developer.log('[CSRF] Fetched token for $path', name: 'csrf');
      }
      return token;
    } catch (e) {
      developer.log('[CSRF] Failed to fetch token for $path: $e', name: 'csrf');
      return null;
    }
  }

  /// Returns a cached CSRF token for [path], or fetches a fresh one.
  Future<String?> getToken(String path) async {
    return _cache[path] ?? await fetchToken(path);
  }

  /// Invalidates any cached token for [path] and fetches a new one.
  /// Call this on 419 responses before retrying the failed request.
  Future<String?> refreshToken(String path) async {
    _cache.remove(path);
    return fetchToken(path);
  }

  /// Clears all cached CSRF tokens (e.g. on logout).
  void clearAll() => _cache.clear();
}
