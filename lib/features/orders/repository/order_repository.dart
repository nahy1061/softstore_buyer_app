import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
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

  // ─── Orders List ──────────────────────────────────────────────────────────

  Future<List<Order>> getOrders() async {
    try {
      final response = await _client.get<String>(
        ApiEndpoints.ordersList,
        options: Options(responseType: ResponseType.plain),
      );
      final html = response.data ?? '';
      return _parseOrdersList(html);
    } on DioException catch (e) {
      throw _mapError(e);
    }
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
    try {
      final response = await _client.get<String>(
        '${ApiEndpoints.orderDetail}$invoiceNumber',
        options: Options(responseType: ResponseType.plain),
      );
      final html = response.data ?? '';
      return _parseOrderDetail(html, invoiceNumber);
    } on DioException catch (e) {
      throw _mapError(e);
    }
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
    try {
      final csrfToken = await _csrf.fetchToken(ApiEndpoints.trackOrder);

      final response = await _client.post<String>(
        ApiEndpoints.trackOrder,
        data: {
          if (csrfToken != null) '_csrf_token': csrfToken,
          'invoice_number': invoiceNumber.trim(),
          'phone': phone.trim(),
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          responseType: ResponseType.plain,
          followRedirects: false,
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      final html = response.data ?? '';

      // Check if tracking found
      if (html.toLowerCase().contains('not found') ||
          html.toLowerCase().contains('invalid')) {
        throw const NotFoundFailure('Order not found. Check your invoice number and phone.');
      }

      return _parseOrderDetail(html, invoiceNumber);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ─── Returns ──────────────────────────────────────────────────────────────

  Future<void> requestReturn({
    required String invoiceNumber,
    required String reason,
    required String details,
  }) async {
    try {
      final path =
          '${ApiEndpoints.orderDetail}$invoiceNumber${ApiEndpoints.requestReturnSuffix}';
      final csrfToken = await _csrf.fetchToken(path);

      await _client.post<String>(
        path,
        data: FormData.fromMap({
          if (csrfToken != null) '_csrf_token': csrfToken,
          'reason': reason,
          'details': details,
        }),
        options: Options(
          contentType: 'multipart/form-data',
          responseType: ResponseType.plain,
          validateStatus: (s) => s != null && s < 500,
        ),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  OrderStatus _parseStatus(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('confirm') || lower.contains('processing') ||
        lower.contains('packing')) return OrderStatus.processing;
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
