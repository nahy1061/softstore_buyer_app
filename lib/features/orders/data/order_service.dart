import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/csrf_extractor.dart';
import '../models/order_model.dart';
import 'order_html_parser.dart';

/// Network service for fetching and managing orders against SoftStore backend.
class OrderService {
  final DioClient _client;

  OrderService({DioClient? client}) : _client = client ?? DioClient();

  /// Fetches authenticated user's orders list from `/store/account/orders`.
  Future<List<Order>> fetchOrders() async {
    try {
      final response = await _client.get<String>(
        ApiEndpoints.getOrders,
        options: Options(
          responseType: ResponseType.plain,
        ),
      );

      final html = response.data ?? '';

      // If page is 404 or empty, return empty list
      if (html.contains('404 Page Not Found') || html.contains('No orders')) {
        return [];
      }

      // Check if session expired or redirected to login
      if (_isSessionExpired(response, html)) {
        return [];
      }

      return OrderHtmlParser.parseOrdersList(html);
    } on Failure {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw const AuthFailure('Session expired. Please log in to view your orders.');
      }
      throw NetworkFailure(e.message ?? 'Failed to load orders.');
    } catch (e) {
      throw ServerFailure('Unable to load orders: $e');
    }
  }

  /// Fetches details for a specific order by invoice number from `/store/account/orders/{invoiceNumber}`.
  Future<Order> fetchOrderDetail(String invoiceNumber) async {
    try {
      final cleanInvoice = invoiceNumber.trim();
      final path = '${ApiEndpoints.getOrderDetail}/$cleanInvoice';

      final response = await _client.get<String>(
        path,
        options: Options(
          responseType: ResponseType.plain,
        ),
      );

      final html = response.data ?? '';

      if (_isSessionExpired(response, html)) {
        throw const AuthFailure('Session expired. Please log in.');
      }

      return OrderHtmlParser.parseOrderDetail(
        html,
        defaultReferenceNumber: cleanInvoice,
      );
    } on Failure {
      rethrow;
    } on DioException catch (e) {
      throw NetworkFailure(e.message ?? 'Failed to load order details.');
    } catch (e) {
      throw ServerFailure('Unable to load order detail: $e');
    }
  }

  /// Performs public guest order lookup via `POST /store/track-order`.
  Future<Order> trackGuestOrder({
    required String referenceNumber,
    required String phone,
  }) async {
    try {
      final cleanRef = referenceNumber.trim();
      final cleanPhone = phone.trim();

      // 1. Fetch CSRF token from tracking page or homepage
      final pageResponse = await _client.get<String>(
        ApiEndpoints.trackOrder,
        options: Options(responseType: ResponseType.plain),
      );
      final pageHtml = pageResponse.data ?? '';
      final csrfToken = CsrfExtractor.extract(pageHtml) ?? '';

      // 2. Submit track-order form with form-url-encoded data
      final response = await _client.post<String>(
        ApiEndpoints.trackOrder,
        data: {
          '_csrf_token': csrfToken,
          'csrf_token': csrfToken,
          'invoice_number': cleanRef,
          'invoice': cleanRef,
          'phone': cleanPhone,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          responseType: ResponseType.plain,
        ),
      );

      final html = response.data ?? '';

      // Check for error feedback in HTML
      if (html.contains('invalid-feedback') && !html.contains('d-none') && (html.contains('not found') || html.contains('No order'))) {
        throw const NotFoundFailure('No order found matching this invoice and phone number.');
      }

      final order = OrderHtmlParser.parseOrderDetail(
        html,
        defaultReferenceNumber: cleanRef,
      );

      return order;
    } on Failure {
      rethrow;
    } on DioException catch (e) {
      throw NetworkFailure(e.message ?? 'Failed to track order.');
    } catch (e) {
      throw ServerFailure('Unable to track order: $e');
    }
  }

  /// Submits an order return request to `/store/account/orders/{orderId}/return`.
  Future<bool> requestReturn({
    required String orderId,
    required String reason,
    required String returnType,
    required List<Map<String, dynamic>> items,
    List<String>? photoPaths,
  }) async {
    try {
      final orderUrl = '${ApiEndpoints.getOrderDetail}/$orderId';
      final pageResponse = await _client.get<String>(
        orderUrl,
        options: Options(responseType: ResponseType.plain),
      );
      final csrfToken = CsrfExtractor.extract(pageResponse.data ?? '') ?? '';

      final Map<String, dynamic> fields = {
        '_csrf_token': csrfToken,
        'csrf_token': csrfToken,
        'reason': reason,
        'return_type': returnType,
      };

      for (var i = 0; i < items.length; i++) {
        fields['product_id[$i]'] = items[i]['productId'].toString();
        fields['returned_quantity[$i]'] = (items[i]['quantity'] ?? 1).toString();
      }

      final returnPath = '$orderUrl${ApiEndpoints.requestReturnSuffix}';

      if (photoPaths != null && photoPaths.isNotEmpty) {
        final formData = FormData.fromMap(fields);
        for (final path in photoPaths) {
          formData.files.add(MapEntry(
            'photo[]',
            await MultipartFile.fromFile(path),
          ));
        }
        final res = await _client.post(
          returnPath,
          data: formData,
          options: Options(validateStatus: (s) => s != null && s < 500),
        );
        return res.statusCode == 200 || res.statusCode == 302;
      } else {
        final res = await _client.post<String>(
          returnPath,
          data: fields,
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
            validateStatus: (s) => s != null && s < 500,
          ),
        );
        return res.statusCode == 200 || res.statusCode == 302;
      }
    } catch (e) {
      throw ServerFailure('Failed to submit return request: $e');
    }
  }

  /// Fetches returns history list from `/store/account/returns`.
  Future<List<Map<String, dynamic>>> fetchReturns() async {
    try {
      final response = await _client.get<String>(
        ApiEndpoints.returnsList,
        options: Options(responseType: ResponseType.plain),
      );
      final html = response.data ?? '';
      if (_isSessionExpired(response, html)) {
        return [];
      }
      return OrderHtmlParser.parseReturnsList(html);
    } catch (e) {
      return [];
    }
  }

  bool _isSessionExpired(Response response, String html) {
    if (response.statusCode == 302) {
      final location = response.headers.value('location') ?? '';
      if (location.contains('login')) return true;
    }
    // Check if HTML contains login form inputs instead of account dashboard
    if (html.contains('name="email"') && html.contains('name="password"') && html.contains('action="/login"')) {
      return true;
    }
    return false;
  }
}
