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
  /// GET /marketplace/account/addresses
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
  /// POST /marketplace/account/addresses
  Future<void> addAddress({required Address address}) async {
    try {
      final csrfToken = await _csrf.fetchToken(ApiEndpoints.addresses) ?? '';

      final formData = <String, String>{
        if (csrfToken.isNotEmpty) ...{
          '_csrf_token': csrfToken,
          'csrf_token': csrfToken,
        },
        'recipient_name': address.name.trim(),
        'phone': address.phone.trim(),
        'address_line1': address.address.trim(),
        'address_line2': '',
        'city': address.city.isNotEmpty ? address.city.trim() : 'Islamabad',
        'state': 'Punjab',
        'postal_code': '',
        if (address.isDefault) 'is_default': '1',
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
            'Referer': '${EnvConfig.baseUrl}/marketplace/account/addresses',
            'Origin': EnvConfig.baseUrl,
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
  /// POST /marketplace/account/addresses/{id}/delete
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
            'Referer': '${EnvConfig.baseUrl}/marketplace/account/addresses',
            'Origin': EnvConfig.baseUrl,
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
    // Find all address cards on the page (.m-feature-card, .address-card, etc.)
    final cards = doc.querySelectorAll('.m-feature-card, .address-card, .address-item, .address-box, [class*="address-card"]');
    final addresses = <Address>[];
    int idCounter = 1;

    for (final card in cards) {
      // 1. Extract Address ID
      int? id;
      // Check for delete form action: e.g. /marketplace/account/addresses/13/delete
      final deleteFormAction = card.querySelector('form[action*="/delete"]')?.attributes['action'] ?? '';
      final deleteMatch = RegExp(r'/addresses/(\d+)/delete').firstMatch(deleteFormAction);
      if (deleteMatch != null) {
        id = int.tryParse(deleteMatch.group(1) ?? '');
      }

      id ??= int.tryParse(
        card.attributes['data-id'] ??
            card.attributes['data-address-id'] ??
            card.querySelector('button[data-id], a[data-id], form[data-id]')?.attributes['data-id'] ??
            card.querySelector('input[name="address_id"]')?.attributes['value'] ??
            '',
      );

      id ??= idCounter++;

      // 2. Extract Label (e.g. Home, Office)
      final label = card.querySelector('span.fw-bold, .label, .address-label, h5, h6')?.text.trim() ?? 'Home';

      // 3. Extract Recipient Name
      final nameEl = card.querySelector('.text-dark:not(span), .name, .recipient-name, .customer-name, strong, b');
      final name = nameEl?.text.trim() ?? '';

      // 4. Extract Details Block (Address, City, Phone)
      final detailsEl = card.querySelector('.text-muted.small, .address-details, .address-body, p');
      String addressLine = '';
      String city = '';
      String phone = '';

      if (detailsEl != null) {
        final text = detailsEl.text.trim();
        // Extract Phone
        final phoneMatch = RegExp(r'Phone:\s*([^\s\n\r<]+)').firstMatch(text);
        if (phoneMatch != null) {
          phone = phoneMatch.group(1)?.trim() ?? '';
        }

        // Clean lines for address and city
        final lines = detailsEl.innerHtml
            .split(RegExp(r'<br\s*/?>|\n'))
            .map((l) => (HtmlParserUtil.parse('<span>$l</span>').body?.text ?? '').trim())
            .where((l) => l.isNotEmpty && !l.toLowerCase().startsWith('phone:'))
            .toList();

        if (lines.isNotEmpty) {
          addressLine = lines.first;
        }
        if (lines.length > 1) {
          final parts = lines[1].split(',');
          if (parts.isNotEmpty) {
            city = parts[0].trim();
          }
        }
      }

      // Fallback for phone
      if (phone.isEmpty) {
        phone = card.querySelector('.phone, .tel, .phone-number')?.text.trim() ?? '';
      }

      // 5. Default badge
      final isDefault = card.classes.contains('default') ||
          card.querySelector('.m-badge, .badge, .default-badge') != null ||
          card.text.toLowerCase().contains('default');

      if (name.isNotEmpty || addressLine.isNotEmpty || phone.isNotEmpty) {
        addresses.add(Address(
          id: id,
          label: label.isNotEmpty ? label : 'Home',
          name: name,
          phone: phone,
          address: addressLine,
          city: city,
          isDefault: isDefault,
        ));
      }
    }

    return addresses;
  }
}
