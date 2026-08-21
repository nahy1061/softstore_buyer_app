import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../core/config/env_config.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/csrf_service.dart';
import '../../../core/utils/html_parser_util.dart';
import '../models/address_model.dart';

class AddressService {
  final DioClient _dio = DioClient();
  final CsrfService _csrf = CsrfService.instance;

  /// Get all saved addresses (API Mapping #26)
  /// GET /store/account/addresses
  Future<List<Address>> getAddresses() async {
    try {
      final response = await _dio.get<String>(
        ApiEndpoints.getAddresses,
        options: Options(
          responseType: ResponseType.plain,
          headers: {
            'User-Agent': 'SoftStoreBuyer/1.0 iOS',
            'Accept': 'text/html,application/xhtml+xml,*/*;q=0.9',
          },
        ),
      );
      if (response.data is String) {
        return _parseAddressesFromHtml(response.data as String);
      }
      return [];
    } on DioException catch (e) {
      developer.log('[AddressService] getAddresses DioException: ${e.message}', name: 'address');
      rethrow;
    } catch (e) {
      developer.log('[AddressService] getAddresses error: $e', name: 'address');
      rethrow;
    }
  }

  /// Add a new address (API Mapping #27)
  /// POST /store/account/addresses
  Future<void> addAddress({required Address address}) async {
    try {
      final csrfToken = await _csrf.fetchToken(ApiEndpoints.addresses) ?? '';

      final formData = <String, String>{
        if (csrfToken.isNotEmpty) ...{
          '_csrf_token': csrfToken,
          'csrf_token': csrfToken,
        },
        'label': address.label.trim(),
        'name': address.name.trim(),
        'recipient_name': address.name.trim(),
        'phone': address.phone.trim(),
        'address': address.address.trim(),
        'address_line1': address.address.trim(),
        if (address.city.isNotEmpty) 'city': address.city.trim(),
        if (address.isDefault) ...{
          'is_default': '1',
          'set_default': 'true',
        },
      };

      final formBody = Uri(queryParameters: formData).query;

      final response = await _dio.post<dynamic>(
        ApiEndpoints.addAddress,
        data: formBody,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          responseType: ResponseType.plain,
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
          headers: {
            'User-Agent': 'SoftStoreBuyer/1.0 iOS',
            'Referer': '${EnvConfig.baseUrl}/store/account/addresses',
            if (csrfToken.isNotEmpty) 'X-CSRF-TOKEN': csrfToken,
            'Accept': 'text/html,application/xhtml+xml,*/*;q=0.9',
          },
        ),
      );

      final status = response.statusCode ?? 0;
      final rawData = response.data;

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
      throw Exception(e.message ?? 'Failed to add address.');
    }
  }

  /// Update an existing address (API Mapping #28 + #27: delete old and add updated)
  Future<void> updateAddress({required Address address}) async {
    try {
      if (address.id != null) {
        try {
          await deleteAddress(address.id!);
        } catch (_) {
          // Ignore delete failure if address only exists locally
        }
      }
      await addAddress(address: address);
    } catch (e) {
      developer.log('[AddressService] updateAddress error: $e', name: 'address');
      rethrow;
    }
  }

  /// Delete an address (API Mapping #28)
  /// POST /store/account/addresses/{id}/delete
  Future<void> deleteAddress(int addressId) async {
    try {
      final csrfToken = await _csrf.fetchToken(ApiEndpoints.addresses) ?? '';
      final path = '${ApiEndpoints.deleteAddress}/$addressId${ApiEndpoints.deleteAddressSuffix}';

      final formData = <String, String>{
        if (csrfToken.isNotEmpty) ...{
          '_csrf_token': csrfToken,
          'csrf_token': csrfToken,
        },
      };

      final formBody = Uri(queryParameters: formData).query;

      final response = await _dio.post<dynamic>(
        path,
        data: formBody,
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          responseType: ResponseType.plain,
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
          headers: {
            'User-Agent': 'SoftStoreBuyer/1.0 iOS',
            'Referer': '${EnvConfig.baseUrl}/store/account/addresses',
            if (csrfToken.isNotEmpty) 'X-CSRF-TOKEN': csrfToken,
            'Accept': 'text/html,application/xhtml+xml,*/*;q=0.9',
          },
        ),
      );

      final status = response.statusCode ?? 0;
      if (status == 302) {
        final location = response.headers.value('location') ?? '';
        if (location.contains('/login')) {
          throw Exception('Session expired. Please log in again.');
        }
        return;
      }
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.connectionTimeout) {
        throw Exception('No internet connection. Please try again.');
      }
      throw Exception(e.message ?? 'Failed to delete address.');
    }
  }

  /// Parse addresses from HTML response
  List<Address> _parseAddressesFromHtml(String html) {
    final doc = HtmlParserUtil.parse(html);
    final cards = doc.querySelectorAll('.address-card, .address-item, [class*="address"]');
    final addresses = <Address>[];
    int idCounter = 1;

    for (final card in cards) {
      final idAttr = card.attributes['data-id'] ??
          card.querySelector('button[data-id], a[data-id], form[data-id]')?.attributes['data-id'] ??
          card.querySelector('input[name="address_id"]')?.attributes['value'];
      final id = int.tryParse(idAttr ?? '') ?? idCounter++;

      final label = card.querySelector('.label, .address-label, .badge')?.text.trim() ?? 'Home';
      final name = card.querySelector('.name, .recipient-name, h5, h6')?.text.trim() ?? '';
      final phone = card.querySelector('.phone, .tel, .phone-number')?.text.trim() ?? '';
      final address = card.querySelector('.address, .address-text, p')?.text.trim() ?? '';
      final isDefault = card.classes.contains('default') ||
          card.querySelector('.badge-default, .default-badge') != null ||
          card.text.toLowerCase().contains('default address');

      if (name.isNotEmpty || address.isNotEmpty) {
        addresses.add(Address(
          id: id,
          label: label.isNotEmpty ? label : 'Home',
          name: name,
          phone: phone,
          address: address,
          isDefault: isDefault,
        ));
      }
    }

    return addresses;
  }
}
