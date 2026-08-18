import 'package:dio/dio.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/constants/api_endpoints.dart';
import '../models/address_model.dart';

class AddressService {
  final DioClient _dio = DioClient();

  /// Get CSRF token from a page
  Future<String> _getCsrfToken(String pagePath) async {
    try {
      final response = await _dio.get(pagePath);
      if (response.data is String) {
        return extractCsrfToken(response.data as String);
      }
      return '';
    } catch (_) {
      return '';
    }
  }

  /// Get all saved addresses (API Mapping #26)
  /// GET /store/account/addresses
  Future<List<Address>> getAddresses() async {
    try {
      final response = await _dio.get(ApiEndpoints.getAddresses);
      if (response.data is String) {
        return _parseAddressesFromHtml(response.data as String);
      }
      final list = response.data as List<dynamic>;
      return list
          .map((e) => Address.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException {
      rethrow;
    }
  }

  /// Add a new address (API Mapping #27)
  /// POST /store/account/addresses
  Future<void> addAddress({required Address address}) async {
    try {
      // Step 1: GET the addresses page to extract CSRF token
      final csrfToken = await _getCsrfToken(ApiEndpoints.getAddresses);

      // Step 2: POST with CSRF token
      await _dio.post(
        ApiEndpoints.addAddress,
        data: {
          if (csrfToken.isNotEmpty) '_csrf_token': csrfToken,
          ...address.toJson(),
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          followRedirects: false,
          validateStatus: (status) => status != null && status < 400,
        ),
      );
    } on DioException {
      rethrow;
    }
  }

  /// Delete an address (API Mapping #28)
  /// POST /store/account/addresses/{id}/delete
  Future<void> deleteAddress(int addressId) async {
    try {
      // Step 1: GET a page to extract CSRF token
      final csrfToken = await _getCsrfToken(ApiEndpoints.getAddresses);

      // Step 2: POST delete with CSRF token
      final path = ApiEndpoints.deleteAddress
          .replaceAll(':id', addressId.toString());
      await _dio.post(
        path,
        data: {
          if (csrfToken.isNotEmpty) '_csrf_token': csrfToken,
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          followRedirects: false,
          validateStatus: (status) => status != null && status < 400,
        ),
      );
    } on DioException {
      rethrow;
    }
  }

  /// Parse addresses from HTML response
  List<Address> _parseAddressesFromHtml(String html) {
    final addresses = <Address>[];
    final cardRegex = RegExp(
      '<div[^>]*class="[^"]*address[^"]*"[^>]*>(.*?)</div>\\s*</div>',
      dotAll: true,
    );
    final matches = cardRegex.allMatches(html);
    int idCounter = 0;
    for (final match in matches) {
      final cardHtml = match.group(0) ?? '';
      idCounter++;
      addresses.add(Address(
        id: idCounter,
        label: _extractText(cardHtml, 'label'),
        name: _extractText(cardHtml, 'name'),
        phone: _extractText(cardHtml, 'phone'),
        address: _extractText(cardHtml, 'address'),
      ));
    }
    return addresses;
  }

  String _extractText(String html, String className) {
    final pattern = RegExp(
      'class="[^"]*$className[^"]*"[^>]*>([^<]*)<',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(html);
    return match?.group(1)?.trim() ?? '';
  }

  /// Extract CSRF token from HTML page
  String extractCsrfToken(String html) {
    final pattern = RegExp(
      '<input[^>]*name=["\']_csrf_token["\'][^>]*value=["\']([^"\']*)["\']',
      caseSensitive: false,
    );
    final match = pattern.firstMatch(html);
    if (match != null) return match.group(1) ?? '';

    final reversePattern = RegExp(
      '<input[^>]*value=["\']([^"\']*)["\'][^>]*name=["\']_csrf_token["\']',
      caseSensitive: false,
    );
    final reverseMatch = reversePattern.firstMatch(html);
    if (reverseMatch != null) return reverseMatch.group(1) ?? '';

    return '';
  }
}
