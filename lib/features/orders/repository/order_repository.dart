import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/csrf_service.dart';
import '../data/order_html_parser.dart';
import '../models/order_model.dart';

/// Handles all order-related API calls against the SoftStore backend.
///
/// All endpoints return HTML — data is scraped from DOM elements.
class OrderRepository {
  OrderRepository._();
  static final OrderRepository instance = OrderRepository._();

  final DioClient _client = DioClient();
  final CsrfService _csrf = CsrfService.instance;

  // ─── Local Orders Storage (SharedPreferences) ───────────────────────────

  Future<void> saveLocalOrder(Order order) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentOrders = await getLocalOrders();
      currentOrders.removeWhere(
        (o) =>
            o.referenceNumber.toLowerCase() ==
                order.referenceNumber.toLowerCase() ||
            o.id.toLowerCase() == order.id.toLowerCase(),
      );
      currentOrders.insert(0, order);
      final rawList = currentOrders.map((o) => jsonEncode(o.toJson())).toList();
      await prefs.setStringList(StorageKeys.savedOrders, rawList);
    } catch (e) {
      developer.log('[Orders] Failed to save local order: $e', name: 'orders');
    }
  }

  Future<List<Order>> getLocalOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(StorageKeys.savedOrders) ?? [];
      final orders = rawList
          .map((s) => Order.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
      return orders;
    } catch (e) {
      developer.log('[Orders] Failed to get local orders: $e', name: 'orders');
      return [];
    }
  }

  /// Clears ALL locally-saved orders. Called after a successful server fetch
  /// so that only real server data is displayed — no fake/dummy orders.
  Future<void> clearAllLocalOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(StorageKeys.savedOrders);
      developer.log('[Orders] Cleared all local orders', name: 'orders');
    } catch (e) {
      developer.log('[Orders] Failed to clear local orders: $e', name: 'orders');
    }
  }

  /// Clears ALL locally-saved orders on app start.
  /// After a successful server fetch, only real server data is shown.
  Future<List<Order>> cleanStaleLocalOrders() async {
    await clearAllLocalOrders();
    return [];
  }

  // ─── Orders List ──────────────────────────────────────────────────────────

  Future<List<Order>> getOrders() async {
    developer.log('[OrderRepo] getOrders() called', name: 'orders');
    List<Order> remoteOrders = [];
    try {
      final response = await _client.get<String>(
        ApiEndpoints.ordersList,
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: false,
          sendTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
        ),
      );
      final html = response.data ?? '';
      var status = response.statusCode ?? 0;
      final location = response.headers.value('location') ?? '';
      developer.log(
        '[OrderRepo] Response status: $status, '
        'location: $location, '
        'content length: ${html.length}',
        name: 'orders',
      );

      // Session expired — 302 redirect to login
      if (status >= 301 && status <= 308 && location.contains('login')) {
        throw const AuthFailure('Session expired. Please login again.');
      }
      // Non-login redirect (e.g. trailing slash normalization) — follow it
      if (status >= 301 && status <= 308 && location.isNotEmpty) {
        developer.log(
          '[OrderRepo] Non-login redirect ($status → $location) — following',
          name: 'orders',
        );
        final followedResponse = await _client.get<String>(
          location,
          options: Options(
            responseType: ResponseType.plain,
            followRedirects: true,
            sendTimeout: const Duration(seconds: 6),
            receiveTimeout: const Duration(seconds: 6),
          ),
        );
        final followedHtml = followedResponse.data ?? '';
        status = followedResponse.statusCode ?? 0;
        if (!followedHtml.contains('404 Page Not Found') &&
            !followedHtml.contains('No orders') &&
            !followedHtml.contains('action="/login"')) {
          remoteOrders = OrderHtmlParser.parseOrdersList(followedHtml);
          developer.log(
            '[OrderRepo] Parsed ${remoteOrders.length} remote orders (followed redirect)',
            name: 'orders',
          );
        }
      } else if (!html.contains('404 Page Not Found') && !html.contains('No orders')) {
        // Session expired — HTML is login page
        if (html.contains('action="/login"') && html.contains('name="password"')) {
          throw const AuthFailure('Session expired. Please login again.');
        }
        remoteOrders = OrderHtmlParser.parseOrdersList(html);
        developer.log(
          '[OrderRepo] Parsed ${remoteOrders.length} remote orders',
          name: 'orders',
        );
      } else {
        developer.log(
          '[OrderRepo] No orders page detected (404 or empty)',
          name: 'orders',
        );
      }
    } on AuthFailure {
      rethrow;
    } catch (e) {
      developer.log('[OrderRepo] Remote fetch note: $e', name: 'orders');
    }

    final localOrders = await getLocalOrders();
    final map = <String, Order>{};

    for (final order in remoteOrders) {
      map[order.referenceNumber.toLowerCase()] = order;
    }
    for (final order in localOrders) {
      final key = order.referenceNumber.toLowerCase();
      if (!map.containsKey(key) ||
          order.status == OrderStatus.cancelled ||
          order.status == OrderStatus.refunded) {
        map[key] = map.containsKey(key)
            ? map[key]!.copyWith(
                status: order.status,
                statusHistory: order.statusHistory.isNotEmpty
                    ? order.statusHistory
                    : map[key]!.statusHistory,
              )
            : order;
      }
    }

    final result = map.values.toList();
    result.sort((a, b) => b.placedAt.compareTo(a.placedAt));
    return result;
  }

  // ─── Order Detail ─────────────────────────────────────────────────────────

  Future<Order> getOrderDetail(String invoiceNumber) async {
    final cleanInvoice = invoiceNumber.trim();
    developer.log('[OrderRepo] getOrderDetail($cleanInvoice)', name: 'orders');

    final localOrders = await getLocalOrders();
    final localMatch = localOrders.where(
      (o) =>
          o.referenceNumber.toLowerCase() == cleanInvoice.toLowerCase() ||
          o.id.toLowerCase() == cleanInvoice.toLowerCase(),
    );

    // 1. Try remote
    try {
      final response = await _client.get<String>(
        '${ApiEndpoints.orderDetail}$cleanInvoice',
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: false,
          sendTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
        ),
      );
      final html = response.data ?? '';
      final status = response.statusCode ?? 0;
      final location = response.headers.value('location') ?? '';
      developer.log(
        '[OrderRepo] Detail response status: $status, '
        'location: $location, '
        'content length: ${html.length}',
        name: 'orders',
      );

      // Session expired
      if (status == 302 && location.contains('login')) {
        throw const AuthFailure('Session expired. Please login again.');
      }
      if (html.contains('action="/login"') && html.contains('name="password"')) {
        throw const AuthFailure('Session expired. Please login again.');
      }

      if (!html.contains('404') &&
          !html.contains('not found') &&
          !html.contains('action="/login"')) {
        final parsed = OrderHtmlParser.parseOrderDetail(
          html,
          defaultReferenceNumber: cleanInvoice,
        );
        return parsed;
      }
    } on AuthFailure {
      rethrow;
    } catch (e) {
      developer.log('[OrderRepo] Detail fetch error: $e', name: 'orders');
    }

    // 2. Try local orders
    if (localMatch.isNotEmpty) {
      return localMatch.first;
    }

    // 3. No local match — order not found
    throw const NotFoundFailure('Order not found.');
  }

  // ─── Guest Order Tracking ─────────────────────────────────────────────────

  /// Performs public guest order lookup via `GET /track-order?invoice=...&phone=...`.
  ///
  /// The live SoftStore site uses a plain GET form — no CSRF token is required.
  Future<Order> trackOrderGuest({
    required String invoiceNumber,
    required String phone,
  }) async {
    final cleanRef = invoiceNumber.trim();
    final cleanPhone = phone.trim();
    developer.log(
      '[OrderRepo] trackOrderGuest($cleanRef, $cleanPhone)',
      name: 'orders',
    );

    // GET /track-order?invoice=MKT-772ABDCD&phone=03001234567
    try {
      final response = await _client.get<String>(
        ApiEndpoints.trackOrder,
        queryParameters: {
          'invoice': cleanRef,
          'phone': cleanPhone,
        },
        options: Options(
          responseType: ResponseType.plain,
          followRedirects: true,
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      final html = response.data ?? '';
      final status = response.statusCode ?? 0;
      developer.log(
        '[OrderRepo] Track response: status=$status, '
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
      // Specifically it says: "No order found matching that invoice number and mobile number."
      final hasAlertDanger = html.contains('alert-danger') &&
          (html.toLowerCase().contains('no order found') ||
              html.toLowerCase().contains('no order matching') ||
              html.toLowerCase().contains('invoice number and mobile'));
      if (hasAlertDanger) {
        throw const NotFoundFailure(
          'No order found matching this invoice and phone number.',
        );
      }

      // Try to parse the order from HTML first — if we get meaningful data,
      // trust it even if the body happens to contain generic "not found" text
      // (e.g. in page footers or 404 help links).
      if (html.trim().isNotEmpty) {
        final order = OrderHtmlParser.parseOrderDetail(
          html,
          defaultReferenceNumber: cleanRef,
        );
        // Validate the parsed order has meaningful data (not just defaults)
        if (order.referenceNumber.isNotEmpty &&
            (order.items.isNotEmpty || order.storeName != 'SoftStore General')) {
          developer.log(
            '[OrderRepo] Successfully parsed tracked order: ${order.referenceNumber} | ${order.status.name}',
            name: 'orders',
          );
          return order;   
        }
        developer.log(
          '[OrderRepo] Parsed order has only default values — treating as not found',
          name: 'orders',
        );
      }
    } on Failure {
      rethrow;
    } catch (e) {
      developer.log(
        '[OrderRepo] trackOrderGuest server error: $e',
        name: 'orders',
      );
    }

    throw const NotFoundFailure(
      'Order not found. Check your invoice number and phone.',
    );
  }

  // ─── Order Cancellation ───────────────────────────────────────────────────

  /// Cancels an order via API and ensures local status updates to cancelled.
  Future<bool> cancelOrder({required String orderId, String? reason}) async {
    final cleanId = orderId.trim();
    bool serverSuccess = false;

    // 1. Send cancellation request to backend API
    try {
      // Primary: Web account order cancel endpoint
      final cancelPath =
          '${ApiEndpoints.orderDetail}$cleanId${ApiEndpoints.cancelOrderSuffix}';
      final csrfToken =
          await _csrf.fetchToken('${ApiEndpoints.orderDetail}$cleanId') ??
          await _csrf.fetchToken(ApiEndpoints.ordersList);

      try {
        final response = await _client.post<dynamic>(
          cancelPath,
          data: {
            if (csrfToken != null) ...{
              '_csrf_token': csrfToken,
              'csrf_token': csrfToken,
            },
            'reason': reason ?? 'Cancelled by buyer',
          },
          options: Options(
            contentType: 'application/x-www-form-urlencoded',
            responseType: ResponseType.plain,
            validateStatus: (s) => s != null && s < 500,
          ),
        );
        if (response.statusCode != null && response.statusCode! < 400) {
          serverSuccess = true;
        }
      } catch (_) {}

      // Secondary fallback: JSON API endpoint
      if (!serverSuccess) {
        try {
          final apiResponse = await _client.post<dynamic>(
            '${ApiEndpoints.apiCancelOrder}$cleanId/cancel',
            data: {'reason': reason ?? 'Cancelled by buyer'},
            options: Options(
              contentType: 'application/json',
              validateStatus: (s) => s != null && s < 500,
            ),
          );
          if (apiResponse.statusCode != null && apiResponse.statusCode! < 400) {
            serverSuccess = true;
          }
        } catch (_) {}
      }
    } catch (e) {
      developer.log('[Orders] Server cancellation notice: $e', name: 'orders');
    }

    // 2. Update local storage: change status to OrderStatus.cancelled & append to timeline history
    await _markOrderCancelledLocally(cleanId, reason: reason);

    return serverSuccess;
  }

  Future<void> _markOrderCancelledLocally(
    String orderId, {
    String? reason,
  }) async {
    try {
      final cleanId = orderId.trim().toLowerCase();
      final localOrders = await getLocalOrders();
      Order? targetOrder;

      final index = localOrders.indexWhere(
        (o) =>
            o.id.toLowerCase() == cleanId ||
            o.referenceNumber.toLowerCase() == cleanId,
      );

      final cancelEvent = OrderStatusEvent(
        status: OrderStatus.cancelled,
        timestamp: DateTime.now(),
        note: (reason != null && reason.trim().isNotEmpty)
            ? 'Cancelled by customer: $reason'
            : 'Cancelled by customer',
      );

      if (index >= 0) {
        targetOrder = localOrders[index];
        final updatedHistory = List<OrderStatusEvent>.from(
          targetOrder.statusHistory,
        )..add(cancelEvent);
        final updatedOrder = targetOrder.copyWith(
          status: OrderStatus.cancelled,
          statusHistory: updatedHistory,
        );
        localOrders[index] = updatedOrder;
      } else {
        // Order not in local storage yet — create a minimal entry
        localOrders.insert(
          0,
          Order(
            id: orderId,
            referenceNumber: orderId,
            placedAt: DateTime.now(),
            status: OrderStatus.cancelled,
            items: const [],
            deliveryAddress: const OrderAddress(
              name: '',
              phone: '',
              addressLine: '',
              city: '',
            ),
            subtotal: 0,
            deliveryFee: 0,
            storeName: 'SoftStore',
            statusHistory: [cancelEvent],
          ),
        );
      }

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final rawList = localOrders.map((o) => jsonEncode(o.toJson())).toList();
      await prefs.setStringList(StorageKeys.savedOrders, rawList);
    } catch (e) {
      developer.log(
        '[Orders] Failed to mark local order cancelled: $e',
        name: 'orders',
      );
    }
  }

  // ─── Return Order ──────────────────────────────────────────────────────────

  Future<bool> requestReturn({
    required String orderId,
    required String reason,
    String? details,
    String returnType = 'refund',
    List<Map<String, dynamic>> items = const [],
    List<String>? photoPaths,
  }) async {
    final cleanId = orderId.trim();
    bool serverSuccess = false;

    try {
      final returnPath =
          '${ApiEndpoints.orderDetail}$cleanId${ApiEndpoints.requestReturnSuffix}';
      final csrfToken =
          await _csrf.fetchToken('${ApiEndpoints.orderDetail}$cleanId') ??
          await _csrf.fetchToken(ApiEndpoints.ordersList);

      final fields = <String, dynamic>{
        if (csrfToken != null) ...{
          '_csrf_token': csrfToken,
          'csrf_token': csrfToken,
        },
        'reason': reason,
        'details': details ?? '',
        'comment': details ?? '',
        'return_type': returnType,
      };

      for (var i = 0; i < items.length; i++) {
        fields['product_id[$i]'] = items[i]['productId']?.toString() ?? '';
        fields['returned_quantity[$i]'] = (items[i]['quantity'] ?? 1)
            .toString();
      }

      if (photoPaths != null && photoPaths.isNotEmpty) {
        final formData = FormData.fromMap(fields);
        for (final path in photoPaths) {
          formData.files.add(
            MapEntry('photo[]', await MultipartFile.fromFile(path)),
          );
        }
        final response = await _client.post<dynamic>(
          returnPath,
          data: formData,
          options: Options(validateStatus: (s) => s != null && s < 500),
        );
        if (response.statusCode != null && response.statusCode! < 400) {
          serverSuccess = true;
        }
      } else {
        final response = await _client.post<dynamic>(
          returnPath,
          data: fields,
          options: Options(
            contentType: 'application/x-www-form-urlencoded',
            responseType: ResponseType.plain,
            validateStatus: (s) => s != null && s < 500,
          ),
        );
        if (response.statusCode != null && response.statusCode! < 400) {
          serverSuccess = true;
        }
      }
    } catch (e) {
      developer.log('[Orders] Return API error: $e', name: 'orders');
    }

    // Update local status & history
    await _markOrderReturnRequestedLocally(
      cleanId,
      reason: reason,
      returnType: returnType,
      details: details,
    );

    return serverSuccess;
  }

  Future<void> _markOrderReturnRequestedLocally(
    String orderId, {
    required String reason,
    String? returnType,
    String? details,
  }) async {
    try {
      final cleanId = orderId.trim().toLowerCase();
      final localOrders = await getLocalOrders();
      final returnTypeLabel = returnType == 'replacement'
          ? 'Replacement'
          : 'Refund';
      final returnEvent = OrderStatusEvent(
        status: OrderStatus.refunded,
        timestamp: DateTime.now(),
        note:
            'Return requested ($returnTypeLabel): $reason${details != null && details.trim().isNotEmpty ? " · ${details.trim()}" : ""}',
      );

      final index = localOrders.indexWhere(
        (o) =>
            o.id.toLowerCase() == cleanId ||
            o.referenceNumber.toLowerCase() == cleanId,
      );

      if (index >= 0) {
        final targetOrder = localOrders[index];
        final updatedHistory = List<OrderStatusEvent>.from(
          targetOrder.statusHistory,
        )..add(returnEvent);
        final updatedOrder = targetOrder.copyWith(
          status: OrderStatus.refunded,
          statusHistory: updatedHistory,
        );
        localOrders[index] = updatedOrder;
      } else {
        localOrders.insert(
          0,
          Order(
            id: orderId,
            referenceNumber: orderId,
            placedAt: DateTime.now(),
            status: OrderStatus.refunded,
            items: const [],
            deliveryAddress: const OrderAddress(
              name: '',
              phone: '',
              addressLine: '',
              city: '',
            ),
            subtotal: 0,
            deliveryFee: 0,
            storeName: 'SoftStore',
            statusHistory: [returnEvent],
          ),
        );
      }

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final rawList = localOrders.map((o) => jsonEncode(o.toJson())).toList();
      await prefs.setStringList(StorageKeys.savedOrders, rawList);
    } catch (e) {
      developer.log(
        '[Orders] Failed to mark local order return: $e',
        name: 'orders',
      );
    }
  }
}
