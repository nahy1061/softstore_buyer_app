import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/csrf_service.dart';
import '../../../core/utils/html_parser_util.dart';
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
      currentOrders.removeWhere((o) =>
          o.referenceNumber.toLowerCase() == order.referenceNumber.toLowerCase() ||
          o.id.toLowerCase() == order.id.toLowerCase());
      currentOrders.insert(0, order);
      final rawList =
          currentOrders.map((o) => jsonEncode(o.toJson())).toList();
      await prefs.setStringList(StorageKeys.savedOrders, rawList);
    } catch (e) {
      developer.log('[Orders] Failed to save local order: $e', name: 'orders');
    }
  }

  Future<List<Order>> getLocalOrders() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final rawList = prefs.getStringList(StorageKeys.savedOrders) ?? [];
      return rawList
          .map((s) => Order.fromJson(jsonDecode(s) as Map<String, dynamic>))
          .toList();
    } catch (e) {
      developer.log('[Orders] Failed to get local orders: $e', name: 'orders');
      return [];
    }
  }

  // ─── Orders List ──────────────────────────────────────────────────────────

  Future<List<Order>> getOrders() async {
    List<Order> remoteOrders = [];
    try {
      final response = await _client.get<String>(
        ApiEndpoints.ordersList,
        options: Options(
          responseType: ResponseType.plain,
          sendTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
        ),
      );
      final html = response.data ?? '';
      if (!html.contains('404 Page Not Found') &&
          !html.contains('No orders') &&
          !html.contains('action="/login"')) {
        remoteOrders = _parseOrdersList(html);
      }
    } catch (e) {
      developer.log('[Orders] Remote fetch note: $e', name: 'orders');
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
    if (result.isEmpty) {
      return List<Order>.from(dummyOrders);
    }
    result.sort((a, b) => b.placedAt.compareTo(a.placedAt));
    return result;
  }

  List<Order> _parseOrdersList(String html) {
    final doc = HtmlParserUtil.parse(html);
    final orders = <Order>[];

    // Try common order card selectors
    final cards = doc.querySelectorAll(
        '.order-card, .order-item, [data-invoice], .order-row');

    for (final card in cards) {
      try {
        // Invoice number
        final invoiceLinkEl = card.querySelector('a[href*="/orders/"]');
        final href = invoiceLinkEl?.attributes['href'] ?? '';
        final invoiceMatch = RegExp(r'/orders/([^/]+)').firstMatch(href);
        final invoice = invoiceMatch?.group(1) ??
            card.attributes['data-invoice'] ??
            card.querySelector('.invoice-number, .order-id')?.text.trim() ??
            '';

        if (invoice.isEmpty) continue;

        // Date
        final dateText =
            card.querySelector('.order-date, .date, time')?.text.trim() ?? '';

        // Status
        final statusText = card
                .querySelector('.status, .badge, .order-status')
                ?.text
                .trim()
                .toLowerCase() ??
            'pending';
        final status = _parseStatus(statusText);

        // Total
        final totalText =
            card.querySelector('.total, .amount, .order-total')?.text ?? '';
        final total = _parseAmount(totalText);

        // Seller name
        final sellerName =
            card.querySelector('.seller-name, .store-name')?.text.trim() ?? '';

        orders.add(Order(
          id: invoice,
          referenceNumber: invoice,
          placedAt: _parseDate(dateText) ?? DateTime.now(),
          status: status,
          items: const [],
          deliveryAddress: const OrderAddress(
              name: '', phone: '', addressLine: '', city: ''),
          subtotal: total,
          deliveryFee: 0,
          storeName: sellerName,
        ));
      } catch (e) {
        developer.log('[Orders] Failed to parse order card: $e', name: 'orders');
      }
    }

    return orders;
  }

  // ─── Order Detail ─────────────────────────────────────────────────────────

  Future<Order> getOrderDetail(String invoiceNumber) async {
    final cleanInvoice = invoiceNumber.trim();
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
          sendTimeout: const Duration(seconds: 6),
          receiveTimeout: const Duration(seconds: 6),
        ),
      );
      final html = response.data ?? '';
      if (!html.contains('404') && !html.contains('not found') && !html.contains('action="/login"')) {
        final parsed = _parseOrderDetail(html, cleanInvoice);
        if (localMatch.isNotEmpty && localMatch.first.status == OrderStatus.cancelled) {
          return parsed.copyWith(status: OrderStatus.cancelled);
        }
        return parsed;
      }
    } catch (_) {}

    // 2. Try local orders
    if (localMatch.isNotEmpty) {
      return localMatch.first;
    }

    // 3. Fallback dummy orders
    final dummyMatch = dummyOrders.where(
      (o) =>
          o.referenceNumber.toLowerCase() == cleanInvoice.toLowerCase() ||
          o.id.toLowerCase() == cleanInvoice.toLowerCase(),
    );
    if (dummyMatch.isNotEmpty) {
      return dummyMatch.first;
    }

    throw const NotFoundFailure('Order not found.');
  }

  Order _parseOrderDetail(String html, String invoiceNumber) {
    final doc = HtmlParserUtil.parse(html);

    // Status
    final statusText = doc
            .querySelector('.order-status, .status-badge, .badge')
            ?.text
            .trim()
            .toLowerCase() ??
        'pending';
    final status = _parseStatus(statusText);

    // Customer info
    final customerName =
        HtmlParserUtil.queryText(doc, '.customer-name, [data-field="name"]') ??
            '';
    final customerAddress = HtmlParserUtil.queryText(
            doc, '.customer-address, [data-field="address"]') ??
        '';
    final customerPhone = HtmlParserUtil.queryText(
            doc, '.customer-phone, [data-field="phone"]') ??
        '';

    // Items
    final itemRows = doc.querySelectorAll(
        '.order-items tr, .order-item, .item-row');
    final items = <OrderItem>[];
    for (final row in itemRows) {
      final nameEl = row.querySelector('.product-name, .item-name, td:first-child');
      final name = nameEl?.text.trim() ?? '';
      if (name.isEmpty) continue;

      final imgEl = row.querySelector('img');
      final imageUrl = imgEl != null
          ? HtmlParserUtil.toAbsoluteUrl(
              imgEl.attributes['src'] ?? imgEl.attributes['data-src'] ?? '')
          : null;

      final cells = row.querySelectorAll('td');
      final qtyText = cells.length > 1 ? cells[1].text.trim() : '1';
      final priceText = cells.length > 2 ? cells[2].text.trim() : '0';
      final qty = int.tryParse(qtyText.replaceAll(RegExp(r'\D'), '')) ?? 1;
      final price = _parseAmount(priceText);

      items.add(OrderItem(
        id: '$invoiceNumber-${items.length}',
        name: name,
        imageUrl: imageUrl,
        quantity: qty,
        unitPrice: price,
      ));
    }

    // Pricing
    final subtotalText =
        HtmlParserUtil.queryText(doc, '.subtotal, [data-subtotal]') ?? '';
    final deliveryText =
        HtmlParserUtil.queryText(doc, '.delivery-fee, .shipping-fee') ?? '';
    final discountText =
        HtmlParserUtil.queryText(doc, '.discount, .coupon-discount') ?? '';
    final totalText =
        HtmlParserUtil.queryText(doc, '.order-total, .grand-total, .total') ??
            '';

    // Status history / timeline
    final timelineItems = doc.querySelectorAll(
        '.timeline-item, .status-event, .order-timeline li');
    final statusHistory = <OrderStatusEvent>[];
    for (final item in timelineItems) {
      final statusStr = item
              .querySelector('.status-label, .event-name, strong')
              ?.text
              .trim()
              .toLowerCase() ??
          '';
      final timestampStr =
          item.querySelector('.timestamp, .event-time, time')?.text.trim() ??
              '';
      final note =
          item.querySelector('.note, .message, p')?.text.trim();
      statusHistory.add(OrderStatusEvent(
        status: _parseStatus(statusStr),
        timestamp: _parseDate(timestampStr) ?? DateTime.now(),
        note: note,
      ));
    }

    // Seller
    final sellerName =
        HtmlParserUtil.queryText(doc, '.seller-name, .store-name') ?? '';
    final sellerPhone =
        HtmlParserUtil.queryText(doc, '.seller-phone, .store-phone');

    // Tracking
    String? courierName =
        HtmlParserUtil.queryText(doc, '.courier-name, .tracking-courier');
    String? trackingNumber =
        HtmlParserUtil.queryText(doc, '.tracking-number, .courier-tracking');

    return Order(
      id: invoiceNumber,
      referenceNumber: invoiceNumber,
      placedAt: DateTime.now(),
      status: status,
      items: items,
      deliveryAddress: OrderAddress(
        name: customerName,
        phone: customerPhone,
        addressLine: customerAddress,
        city: '',
      ),
      subtotal: _parseAmount(subtotalText),
      deliveryFee: _parseAmount(deliveryText),
      discount: _parseAmount(discountText),
      storeName: sellerName,
      storeContact: sellerPhone,
      statusHistory: statusHistory,
    );
  }

  // ─── Guest Order Tracking ─────────────────────────────────────────────────

  Future<Order> trackOrderGuest({
    required String invoiceNumber,
    required String phone,
  }) async {
    final cleanRef = invoiceNumber.trim();
    final cleanPhone = phone.trim();

    try {
      final csrfToken = await _csrf.fetchToken(ApiEndpoints.trackOrder);

      final response = await _client.post<String>(
        ApiEndpoints.trackOrder,
        data: {
          if (csrfToken != null) '_csrf_token': csrfToken,
          'invoice_number': cleanRef,
          'phone': cleanPhone,
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          responseType: ResponseType.plain,
          followRedirects: false,
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      final html = response.data ?? '';

      // Check if tracking found on server
      if (!html.toLowerCase().contains('not found') &&
          !html.toLowerCase().contains('invalid') &&
          html.trim().isNotEmpty) {
        return _parseOrderDetail(html, cleanRef);
      }
    } catch (e) {
      developer.log('[Orders] trackOrderGuest server lookup notice: $e', name: 'orders');
    }

    // Check locally saved orders
    final localOrders = await getLocalOrders();
    final match = localOrders.where(
      (o) =>
          o.referenceNumber.toLowerCase() == cleanRef.toLowerCase() ||
          o.id.toLowerCase() == cleanRef.toLowerCase() ||
          (cleanPhone.isNotEmpty && o.deliveryAddress.phone.replaceAll(RegExp(r'\D'), '').contains(cleanPhone.replaceAll(RegExp(r'\D'), ''))),
    );
    if (match.isNotEmpty) {
      return match.first;
    }

    // Check dummy preview orders
    final dummyMatch = dummyOrders.where(
      (o) =>
          o.referenceNumber.toLowerCase() == cleanRef.toLowerCase() ||
          o.id.toLowerCase() == cleanRef.toLowerCase(),
    );
    if (dummyMatch.isNotEmpty) {
      return dummyMatch.first;
    }

    throw const NotFoundFailure('Order not found. Check your invoice number and phone.');
  }

  // ─── Order Cancellation ───────────────────────────────────────────────────

  /// Cancels an order via API and ensures local status updates to cancelled.
  Future<bool> cancelOrder({
    required String orderId,
    String? reason,
  }) async {
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
            data: {
              'reason': reason ?? 'Cancelled by buyer',
            },
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

  Future<void> _markOrderCancelledLocally(String orderId, {String? reason}) async {
    try {
      final cleanId = orderId.trim().toLowerCase();
      final localOrders = await getLocalOrders();
      Order? targetOrder;

      final index = localOrders.indexWhere((o) =>
          o.id.toLowerCase() == cleanId ||
          o.referenceNumber.toLowerCase() == cleanId);

      final cancelEvent = OrderStatusEvent(
        status: OrderStatus.cancelled,
        timestamp: DateTime.now(),
        note: (reason != null && reason.trim().isNotEmpty)
            ? 'Cancelled by customer: $reason'
            : 'Cancelled by customer',
      );

      if (index >= 0) {
        targetOrder = localOrders[index];
        final updatedHistory =
            List<OrderStatusEvent>.from(targetOrder.statusHistory)
              ..add(cancelEvent);
        final updatedOrder = targetOrder.copyWith(
          status: OrderStatus.cancelled,
          statusHistory: updatedHistory,
        );
        localOrders[index] = updatedOrder;
      } else {
        // If not in local storage yet, look up in dummy orders or create entry
        final dummyMatch = dummyOrders.where((o) =>
            o.id.toLowerCase() == cleanId ||
            o.referenceNumber.toLowerCase() == cleanId);
        if (dummyMatch.isNotEmpty) {
          targetOrder = dummyMatch.first;
          final updatedHistory =
              List<OrderStatusEvent>.from(targetOrder.statusHistory)
                ..add(cancelEvent);
          localOrders.insert(
            0,
            targetOrder.copyWith(
              status: OrderStatus.cancelled,
              statusHistory: updatedHistory,
            ),
          );
        } else {
          localOrders.insert(
            0,
            Order(
              id: orderId,
              referenceNumber: orderId,
              placedAt: DateTime.now(),
              status: OrderStatus.cancelled,
              items: const [],
              deliveryAddress: const OrderAddress(
                  name: '', phone: '', addressLine: '', city: ''),
              subtotal: 0,
              deliveryFee: 0,
              storeName: 'SoftStore',
              statusHistory: [cancelEvent],
            ),
          );
        }
      }

      // Also update in-memory dummy list if matching
      for (var i = 0; i < dummyOrders.length; i++) {
        if (dummyOrders[i].id.toLowerCase() == cleanId ||
            dummyOrders[i].referenceNumber.toLowerCase() == cleanId) {
          final updatedHistory =
              List<OrderStatusEvent>.from(dummyOrders[i].statusHistory)
                ..add(cancelEvent);
          dummyOrders[i] = dummyOrders[i].copyWith(
            status: OrderStatus.cancelled,
            statusHistory: updatedHistory,
          );
        }
      }

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final rawList = localOrders.map((o) => jsonEncode(o.toJson())).toList();
      await prefs.setStringList(StorageKeys.savedOrders, rawList);
    } catch (e) {
      developer.log('[Orders] Failed to mark local order cancelled: $e',
          name: 'orders');
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
        fields['returned_quantity[$i]'] =
            (items[i]['quantity'] ?? 1).toString();
      }

      if (photoPaths != null && photoPaths.isNotEmpty) {
        final formData = FormData.fromMap(fields);
        for (final path in photoPaths) {
          formData.files.add(MapEntry(
            'photo[]',
            await MultipartFile.fromFile(path),
          ));
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
      final returnTypeLabel = returnType == 'replacement' ? 'Replacement' : 'Refund';
      final returnEvent = OrderStatusEvent(
        status: OrderStatus.refunded,
        timestamp: DateTime.now(),
        note: 'Return requested ($returnTypeLabel): $reason${details != null && details.trim().isNotEmpty ? " · ${details.trim()}" : ""}',
      );

      final index = localOrders.indexWhere((o) =>
          o.id.toLowerCase() == cleanId ||
          o.referenceNumber.toLowerCase() == cleanId);

      if (index >= 0) {
        final targetOrder = localOrders[index];
        final updatedHistory =
            List<OrderStatusEvent>.from(targetOrder.statusHistory)
              ..add(returnEvent);
        final updatedOrder = targetOrder.copyWith(
          status: OrderStatus.refunded,
          statusHistory: updatedHistory,
        );
        localOrders[index] = updatedOrder;
      } else {
        final dummyMatch = dummyOrders.where((o) =>
            o.id.toLowerCase() == cleanId ||
            o.referenceNumber.toLowerCase() == cleanId);
        if (dummyMatch.isNotEmpty) {
          final targetOrder = dummyMatch.first;
          final updatedHistory =
              List<OrderStatusEvent>.from(targetOrder.statusHistory)
                ..add(returnEvent);
          localOrders.insert(
            0,
            targetOrder.copyWith(
              status: OrderStatus.refunded,
              statusHistory: updatedHistory,
            ),
          );
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
                  name: '', phone: '', addressLine: '', city: ''),
              subtotal: 0,
              deliveryFee: 0,
              storeName: 'SoftStore',
              statusHistory: [returnEvent],
            ),
          );
        }
      }

      // Also update in-memory dummy list if matching
      for (var i = 0; i < dummyOrders.length; i++) {
        if (dummyOrders[i].id.toLowerCase() == cleanId ||
            dummyOrders[i].referenceNumber.toLowerCase() == cleanId) {
          final updatedHistory =
              List<OrderStatusEvent>.from(dummyOrders[i].statusHistory)
                ..add(returnEvent);
          dummyOrders[i] = dummyOrders[i].copyWith(
            status: OrderStatus.refunded,
            statusHistory: updatedHistory,
          );
        }
      }

      // Save to SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final rawList = localOrders.map((o) => jsonEncode(o.toJson())).toList();
      await prefs.setStringList(StorageKeys.savedOrders, rawList);
    } catch (e) {
      developer.log('[Orders] Failed to mark local order return: $e',
          name: 'orders');
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  OrderStatus _parseStatus(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('confirm')) return OrderStatus.confirmed;
    if (lower.contains('processing') || lower.contains('packing')) return OrderStatus.processing;
    if (lower.contains('ship') || lower.contains('dispatch')) return OrderStatus.shipped;
    if (lower.contains('deliver') || lower.contains('complete')) return OrderStatus.delivered;
    if (lower.contains('cancel')) return OrderStatus.cancelled;
    if (lower.contains('refund')) return OrderStatus.refunded;
    return OrderStatus.pending;
  }

  double _parseAmount(String text) {
    if (text.isEmpty) return 0;
    final cleaned = text
        .replaceAll('PKR', '')
        .replaceAll('Rs.', '')
        .replaceAll('Rs', '')
        .replaceAll(',', '')
        .replaceAll(' ', '');
    return double.tryParse(cleaned) ?? 0;
  }

  DateTime? _parseDate(String text) {
    if (text.isEmpty) return null;
    try {
      return DateTime.parse(text);
    } catch (_) {
      // Common Pakistani formats: "12 Aug 2026", "2026-08-12 10:30"
      final match = RegExp(r'(\d{4})-(\d{2})-(\d{2})').firstMatch(text);
      if (match != null) {
        return DateTime(
          int.parse(match.group(1)!),
          int.parse(match.group(2)!),
          int.parse(match.group(3)!),
        );
      }
      return null;
    }
  }

  Failure _mapError(DioException e) {
    developer.log('[Orders] DioException: ${e.message}', name: 'orders');
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkFailure('No internet connection.');
    }
    return ServerFailure(
      e.message ?? 'Server error',
      statusCode: e.response?.statusCode,
    );
  }
}
