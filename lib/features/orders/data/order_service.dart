import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../core/config/env_config.dart';
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
  /// Server identifies user via SOFTSTORE_SESSID cookie — returns ONLY that user's orders.
  Future<List<Order>> fetchOrders() async {
    try {
      // Log cookie state so we can verify the session is being sent
      try {
        final cookies = await _client.cookieJar.loadForRequest(
          Uri.parse('${EnvConfig.baseUrl}${ApiEndpoints.getOrders}'),
        );
        final sessid = cookies.where((c) => c.name == 'SOFTSTORE_SESSID').toList();
        developer.log(
          '[OrderService] Cookies for ${ApiEndpoints.getOrders}: '
          '${cookies.map((c) => c.name).toList()} '
          '${sessid.isNotEmpty ? "(SOFTSTORE_SESSID present, length=${sessid.first.value.length})" : "(NO SOFTSTORE_SESSID!)"}',
          name: 'orders',
        );
      } catch (e) {
        developer.log('[OrderService] Cookie check failed: $e', name: 'orders');
      }

      developer.log(
        '[OrderService] Fetching orders from ${ApiEndpoints.getOrders}',
        name: 'orders',
      );

      // First attempt — followRedirects:false so we can detect login redirects
      Response<String> response = await _client.get<String>(
        ApiEndpoints.getOrders,
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: false,
        ),
      );

      String html = response.data ?? '';
      int status = response.statusCode ?? 0;
      String location = response.headers.value('location') ?? '';

      developer.log(
        '[OrderService] Response status: $status, '
        'location: $location, '
        'content length: ${html.length}, '
        'preview: ${html.length > 300 ? html.substring(0, 300) : html}',
        name: 'orders',
      );

      // Session expired — redirect to /login
      if (status >= 301 && status <= 308 && location.contains('login')) {
        developer.log(
          '[OrderService] Session expired detected ($status → $location)',
          name: 'orders',
        );
        throw const AuthFailure('Session expired. Please login again.');
      }

      // Non-login redirect (e.g. trailing slash, CDN) — follow it transparently
      if (status >= 301 && status <= 308 && location.isNotEmpty) {
        developer.log(
          '[OrderService] Non-login redirect ($status → $location) — following',
          name: 'orders',
        );
        final followedResponse = await _client.get<String>(
          location,
          options: Options(
            responseType: ResponseType.plain,
            followRedirects: true,
          ),
        );
        html = followedResponse.data ?? '';
        status = followedResponse.statusCode ?? 0;
        developer.log(
          '[OrderService] Followed response status: $status, '
          'content length: ${html.length}',
          name: 'orders',
        );
      }

      // Session expired — HTML contains login form
      if (_isLoginHtml(html)) {
        developer.log(
          '[OrderService] Session expired detected (login form in HTML)',
          name: 'orders',
        );
        throw const AuthFailure('Session expired. Please login again.');
      }

      // Empty response body
      if (html.trim().isEmpty) {
        developer.log(
          '[OrderService] Empty response body — treating as no orders',
          name: 'orders',
        );
        return [];
      }

      // Empty page / 404 — user genuinely has no orders
      if (html.contains('404 Page Not Found') || html.contains('No orders')) {
        developer.log(
          '[OrderService] No orders page detected (404 or empty)',
          name: 'orders',
        );
        return [];
      }

      final orders = OrderHtmlParser.parseOrdersList(html);
      developer.log(
        '[OrderService] Parsed ${orders.length} orders from HTML',
        name: 'orders',
      );
      for (final o in orders) {
        developer.log(
          '[OrderService]   - ${o.referenceNumber} | ${o.status.name} | ${o.storeName}',
          name: 'orders',
        );
      }
      return orders;
    } on Failure {
      rethrow;
    } on DioException catch (e) {
      developer.log(
        '[OrderService] DioException: type=${e.type}, '
        'status=${e.response?.statusCode}, message=${e.message}',
        name: 'orders',
      );
      // Unwrap AuthFailure from interceptor (it's stored in e.error)
      if (e.error is AuthFailure) {
        throw e.error as AuthFailure;
      }
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw const AuthFailure('Session expired. Please log in to view your orders.');
      }
      throw NetworkFailure(e.message ?? 'Failed to load orders.');
    } catch (e) {
      developer.log(
        '[OrderService] Unexpected error: $e',
        name: 'orders',
      );
      if (e is Failure) rethrow;
      throw ServerFailure('Unable to load orders: $e');
    }
  }

  /// Fetches details for a specific order by invoice number from `/store/account/orders/{invoiceNumber}`.
  Future<Order> fetchOrderDetail(String invoiceNumber) async {
    try {
      final cleanInvoice = invoiceNumber.trim();
      final path = '${ApiEndpoints.getOrderDetail}/$cleanInvoice';

      developer.log(
        '[OrderService] Fetching order detail from $path',
        name: 'orders',
      );

      final response = await _client.get<String>(
        path,
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: false,
        ),
      );

      final html = response.data ?? '';
      final status = response.statusCode ?? 0;
      final location = response.headers.value('location') ?? '';

      developer.log(
        '[OrderService] Detail response status: $status, '
        'location: $location, '
        'content length: ${html.length}',
        name: 'orders',
      );

      if (status == 302 && location.contains('login')) {
        throw const AuthFailure('Session expired. Please log in.');
      }
      if (_isLoginHtml(html)) {
        throw const AuthFailure('Session expired. Please log in.');
      }

      return OrderHtmlParser.parseOrderDetail(
        html,
        defaultReferenceNumber: cleanInvoice,
      );
    } on Failure {
      rethrow;
    } on DioException catch (e) {
      if (e.error is AuthFailure) {
        throw e.error as AuthFailure;
      }
      throw NetworkFailure(e.message ?? 'Failed to load order details.');
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Unable to load order detail: $e');
    }
  }

  /// Performs public guest order lookup via `GET /track-order?invoice=...&phone=...`.
  ///
  /// The live SoftStore site uses a plain GET form — no CSRF token is required.
  /// On success the response body contains the order tracking card HTML.
  /// On failure the response body contains an `alert-danger` div with a
  /// "No order found matching that invoice number and mobile number" message.
  Future<Order> trackGuestOrder({
    required String referenceNumber,
    required String phone,
  }) async {
    try {
      final cleanRef = referenceNumber.trim();
      final cleanPhone = phone.trim();

      developer.log(
        '[OrderService] trackGuestOrder($cleanRef, $cleanPhone)',
        name: 'orders',
      );

      // GET /track-order?invoice=MKT-772ABDCD&phone=03001234567
      // The live site form uses method="GET" with fields: invoice, phone
      final response = await _client.get<String>(
        ApiEndpoints.trackOrder,
        queryParameters: {
          'invoice': cleanRef,
          'phone': cleanPhone,
        },
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: true,
        ),
      );

      final html = response.data ?? '';
      final status = response.statusCode ?? 0;

      developer.log(
        '[OrderService] Track response: status=$status, '
        'length=${html.length}, preview=${html.length > 300 ? html.substring(0, 300) : html}',
        name: 'orders',
      );

      // Session expired
      if (html.contains('action="/login"') && html.contains('name="password"')) {
        throw const AuthFailure('Session expired. Please login again.');
      }

      // Server returned a hard 404 or 500 error page
      if (html.contains('404 Page Not Found') || html.contains('500 Server Error')) {
        throw const NotFoundFailure('Order not found on server.');
      }

      // The server renders an `alert-danger` div when lookup fails.
      // This is the ONLY reliable not-found signal — avoids false-positives
      // from "not found" text appearing in page footers or help links.
      final hasAlertDanger = html.contains('alert-danger') &&
          (html.toLowerCase().contains('no order found') ||
              html.toLowerCase().contains('no order matching') ||
              html.toLowerCase().contains('invoice number and mobile'));
      if (hasAlertDanger) {
        throw const NotFoundFailure(
          'No order found matching this invoice and phone number.',
        );
      }

      // Check for empty response
      if (html.trim().isEmpty) {
        throw const NotFoundFailure('No response from server. Please try again.');
      }

      final order = OrderHtmlParser.parseOrderDetail(
        html,
        defaultReferenceNumber: cleanRef,
      );

      // Validate the parsed order has meaningful data
      if (order.referenceNumber.isEmpty ||
          (order.items.isEmpty &&
              order.storeName == 'SoftStore General' &&
              order.subtotal == 0)) {
        throw const NotFoundFailure(
          'Order not found. Please check your invoice number and phone.',
        );
      }

      developer.log(
        '[OrderService] Tracked order: ${order.referenceNumber} | ${order.status.name}',
        name: 'orders',
      );

      return order;
    } on Failure {
      rethrow;
    } on DioException catch (e) {
      if (e.error is AuthFailure) {
        throw e.error as AuthFailure;
      }
      throw NetworkFailure(e.message ?? 'Failed to track order.');
    } catch (e) {
      if (e is Failure) rethrow;
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

  /// Cancels an order via `/store/account/orders/{orderId}/cancel`
  Future<bool> cancelOrder({
    required String orderId,
    String? reason,
  }) async {
    try {
      final cleanInvoice = orderId.trim();
      final orderUrl = '${ApiEndpoints.getOrderDetail}/$cleanInvoice';
      final pageResponse = await _client.get<String>(
        orderUrl,
        options: Options(responseType: ResponseType.plain),
      );
      final csrfToken = CsrfExtractor.extract(pageResponse.data ?? '') ?? '';

      final cancelPath = '$orderUrl${ApiEndpoints.cancelOrderSuffix}';
      final res = await _client.post<String>(
        cancelPath,
        data: {
          if (csrfToken.isNotEmpty) ...{
            '_csrf_token': csrfToken,
            'csrf_token': csrfToken,
          },
          'reason': reason ?? 'Cancelled by buyer',
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      return res.statusCode == 200 || res.statusCode == 302;
    } catch (e) {
      throw ServerFailure('Failed to cancel order: $e');
    }
  }

  /// Fetches returns history list from `/store/account/returns`.
  Future<List<Map<String, dynamic>>> fetchReturns() async {
    try {
      final response = await _client.get<String>(
        ApiEndpoints.returnsList,
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: false,
        ),
      );
      final html = response.data ?? '';
      final status = response.statusCode ?? 0;
      final location = response.headers.value('location') ?? '';

      developer.log(
        '[OrderService] Returns response status: $status, '
        'location: $location, '
        'content length: ${html.length}',
        name: 'orders',
      );

      if (status == 302 && location.contains('login')) {
        throw const AuthFailure('Session expired. Please log in to view returns.');
      }
      if (_isLoginHtml(html)) {
        throw const AuthFailure('Session expired. Please log in to view returns.');
      }
      return OrderHtmlParser.parseReturnsList(html);
    } on Failure {
      rethrow;
    } on DioException catch (e) {
      if (e.error is AuthFailure) {
        throw e.error as AuthFailure;
      }
      if (e.response?.statusCode == 401 || e.response?.statusCode == 403) {
        throw const AuthFailure('Session expired. Please log in to view returns.');
      }
      throw NetworkFailure(e.message ?? 'Failed to load returns.');
    } catch (e) {
      if (e is Failure) rethrow;
      throw ServerFailure('Unable to load returns: $e');
    }
  }

  /// Detects if the HTML response is actually a login page (session expired).
  ///
  /// Requires BOTH a login form action AND a password field so we don't
  /// false-positive on pages that merely reference passwords (e.g. account
  /// settings, footer text, password managers).
  bool _isLoginHtml(String html) {
    if (html.isEmpty) return false;
    // A login page has an <action="/login"> form AND a password input
    final hasLoginFormAction = html.contains('action="/login"') ||
        html.contains("action='/login'");
    final hasPasswordInput = html.contains('name="password"') ||
        html.contains("name='password'");
    // Must have both — prevents matching e.g. account settings or support pages
    if (hasLoginFormAction && hasPasswordInput) return true;
    // Final check: page <title> explicitly says login
    final hasLoginTitle = html.toLowerCase().contains('<title>login') ||
        html.toLowerCase().contains('<title>sign in');
    return hasLoginTitle && hasPasswordInput;
  }
}
