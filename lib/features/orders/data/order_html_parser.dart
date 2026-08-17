import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../models/order_model.dart';

/// Parses raw HTML responses from SoftStore order endpoints into strongly typed Order models.
class OrderHtmlParser {
  /// Parses the `/store/account/orders` HTML page into a List of [Order].
  static List<Order> parseOrdersList(String html) {
    if (html.isEmpty) return [];

    final doc = html_parser.parse(html);
    final List<Order> orders = [];

    // Select order card elements (checking various common PHP MVC template class conventions)
    var cardElements = doc.querySelectorAll('.order-card');
    if (cardElements.isEmpty) {
      cardElements = doc.querySelectorAll('[data-order-id], [data-invoice], .card.order-item, .orders-list .card');
    }
    if (cardElements.isEmpty) {
      // Fallback: check table rows in order tables
      final tableRows = doc.querySelectorAll('table.orders-table tbody tr, table.table-orders tbody tr, table tbody tr');
      if (tableRows.isNotEmpty) {
        for (final row in tableRows) {
          final order = _parseOrderFromTableRow(row);
          if (order != null) orders.add(order);
        }
        if (orders.isNotEmpty) return orders;
      }
    }

    for (int i = 0; i < cardElements.length; i++) {
      final card = cardElements[i];
      final order = _parseOrderFromCard(card, i + 1);
      if (order != null) {
        orders.add(order);
      }
    }

    return orders;
  }

  /// Parses a single order card DOM element into an [Order].
  static Order? _parseOrderFromCard(dom.Element card, int fallbackIndex) {
    try {
      // 1. Extract Invoice Number
      String? invoiceNumber;
      final invoiceLink = card.querySelector('a[href*="order"], a[href*="INV-"], a[data-invoice], [data-invoice]');
      if (invoiceLink != null) {
        invoiceNumber = invoiceLink.attributes['data-invoice'];
        if (invoiceNumber == null || invoiceNumber.isEmpty) {
          final href = invoiceLink.attributes['href'] ?? '';
          final match = RegExp(r'/orders/([A-Za-z0-9_\-]+)').firstMatch(href);
          if (match != null) invoiceNumber = match.group(1);
        }
      }

      if (invoiceNumber == null || invoiceNumber.isEmpty) {
        final cardText = card.text;
        final invMatch = RegExp(r'#?([A-Z0-9]{2,}-[A-Z0-9_\-]+)').firstMatch(cardText);
        if (invMatch != null) {
          invoiceNumber = invMatch.group(1);
        }
      }

      invoiceNumber ??= 'SS-${DateTime.now().year}$fallbackIndex';

      // 2. Extract Status
      final statusBadge = card.querySelector('.status-badge, .badge, .order-status, [class*="status"]');
      final statusText = statusBadge?.text.trim().toLowerCase() ?? 'pending';
      final status = _parseOrderStatus(statusText);

      // 3. Extract Date
      final dateEl = card.querySelector('.order-date, .date, time, .text-muted');
      final dateText = dateEl?.text.trim() ?? '';
      final placedAt = _parseDateTime(dateText);

      // 4. Extract Total Amount
      final totalEl = card.querySelector('.order-total, .total, .price, .amount');
      final totalText = totalEl?.text.trim() ?? card.text;
      final total = _extractPrice(totalText);

      // 5. Extract Store Name & Item count
      final storeEl = card.querySelector('.store-name, .seller-name, .merchant-name');
      final storeName = storeEl?.text.trim() ?? 'SoftStore Merchant';

      final itemsEl = card.querySelector('.item-count, .items-count');
      int itemCount = 1;
      if (itemsEl != null) {
        final match = RegExp(r'\d+').firstMatch(itemsEl.text);
        if (match != null) itemCount = int.tryParse(match.group(0)!) ?? 1;
      }

      return Order(
        id: invoiceNumber,
        referenceNumber: invoiceNumber,
        placedAt: placedAt,
        status: status,
        items: [
          OrderItem(
            id: 'item-$invoiceNumber',
            name: '$storeName Order ($itemCount item${itemCount > 1 ? 's' : ''})',
            quantity: itemCount,
            unitPrice: total / (itemCount > 0 ? itemCount : 1),
          ),
        ],
        deliveryAddress: const OrderAddress(
          name: 'Buyer',
          phone: '',
          addressLine: 'Standard Delivery Address',
          city: 'Pakistan',
        ),
        subtotal: total,
        deliveryFee: 0,
        discount: 0,
        storeName: storeName,
        statusHistory: [
          OrderStatusEvent(
            status: status,
            timestamp: placedAt,
            note: 'Order status: ${status.label}',
          ),
        ],
      );
    } catch (_) {
      return null;
    }
  }

  /// Parses an order from a table row element.
  static Order? _parseOrderFromTableRow(dom.Element row) {
    try {
      final cells = row.querySelectorAll('td');
      if (cells.length < 3) return null;

      final rowText = row.text;
      final invMatch = RegExp(r'([A-Za-z0-9]{2,}-[A-Za-z0-9_\-]+)').firstMatch(rowText);
      final invoiceNumber = invMatch?.group(1) ?? 'SS-${DateTime.now().millisecondsSinceEpoch}';

      final total = _extractPrice(rowText);
      final status = _parseOrderStatus(rowText.toLowerCase());
      final placedAt = _parseDateTime(rowText);

      return Order(
        id: invoiceNumber,
        referenceNumber: invoiceNumber,
        placedAt: placedAt,
        status: status,
        items: [
          OrderItem(
            id: 'item-$invoiceNumber',
            name: 'Order #$invoiceNumber',
            quantity: 1,
            unitPrice: total,
          ),
        ],
        deliveryAddress: const OrderAddress(
          name: 'Buyer',
          phone: '',
          addressLine: 'Delivery Address',
          city: 'Pakistan',
        ),
        subtotal: total,
        deliveryFee: 0,
        discount: 0,
        storeName: 'SoftStore Merchant',
      );
    } catch (_) {
      return null;
    }
  }

  /// Parses order detail / track order HTML page into a complete [Order] model.
  static Order parseOrderDetail(String html, {String? defaultReferenceNumber}) {
    final doc = html_parser.parse(html);

    // 1. Reference / Invoice Number
    String referenceNumber = defaultReferenceNumber ?? '';
    final invoiceEl = doc.querySelector('.invoice-number, [data-invoice], h1, h2, h3, .order-header');
    if (invoiceEl != null) {
      final match = RegExp(r'#?([A-Za-z0-9]{2,}-[A-Za-z0-9_\-]+)').firstMatch(invoiceEl.text);
      if (match != null) {
        referenceNumber = match.group(1)!;
      }
    }
    if (referenceNumber.isEmpty) {
      final match = RegExp(r'#?([A-Za-z0-9]{2,}-[A-Za-z0-9_\-]+)').firstMatch(html);
      referenceNumber = match?.group(1) ?? 'INV-${DateTime.now().millisecondsSinceEpoch}';
    }

    // 2. Status
    final statusEl = doc.querySelector('.status-badge, .order-status, .badge, .status');
    final status = _parseOrderStatus(statusEl?.text.toLowerCase() ?? doc.body?.text.toLowerCase() ?? 'pending');

    // 3. Placed At Date
    final dateEl = doc.querySelector('.order-date, .placed-date, time, .text-muted');
    final placedAt = _parseDateTime(dateEl?.text ?? '');

    // 4. Delivery Address & Customer Info
    String customerName = 'Buyer';
    String customerPhone = '';
    String addressLine = '';
    String city = 'Pakistan';

    final addressBlock = doc.querySelector('.shipping-address, .delivery-address, .address-box, .customer-info');
    if (addressBlock != null) {
      final lines = addressBlock.text.split('\n').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
      if (lines.isNotEmpty) customerName = lines.first;
      for (final line in lines) {
        if (RegExp(r'\+?92|\b03\d{2}').hasMatch(line)) {
          customerPhone = line;
        } else if (line != customerName) {
          addressLine = addressLine.isEmpty ? line : '$addressLine, $line';
        }
      }
    }

    // 5. Merchant / Store Info
    String storeName = 'SoftStore General';
    String? storeCity;
    String? storeContact;
    final storeBlock = doc.querySelector('.store-info, .merchant-info, .seller-info');
    if (storeBlock != null) {
      final nameEl = storeBlock.querySelector('.store-name, h4, h5, strong');
      if (nameEl != null) storeName = nameEl.text.trim();
    }

    // 6. Order Items
    final List<OrderItem> items = [];
    final itemRows = doc.querySelectorAll('.order-item, table.order-items tbody tr, .items-table tr, .item-row');
    for (int i = 0; i < itemRows.length; i++) {
      final row = itemRows[i];
      final nameEl = row.querySelector('.product-name, .item-name, a, td:first-child');
      final name = nameEl?.text.trim();
      if (name == null || name.isEmpty || name.toLowerCase() == 'item' || name.toLowerCase() == 'product') {
        continue;
      }

      final imgEl = row.querySelector('img');
      final imgUrl = imgEl?.attributes['src'] ?? imgEl?.attributes['data-src'];

      int qty = 1;
      final qtyEl = row.querySelector('.item-qty, .qty, [data-qty]');
      if (qtyEl != null) {
        final match = RegExp(r'\d+').firstMatch(qtyEl.text);
        if (match != null) qty = int.tryParse(match.group(0)!) ?? 1;
      } else {
        final cells = row.querySelectorAll('td');
        if (cells.length >= 2) {
          final match = RegExp(r'\d+').firstMatch(cells[1].text);
          if (match != null) qty = int.tryParse(match.group(0)!) ?? 1;
        }
      }

      double unitPrice = 0;
      final priceEl = row.querySelector('.item-price, .price, .subtotal');
      if (priceEl != null) {
        unitPrice = _extractPrice(priceEl.text);
      } else {
        final cells = row.querySelectorAll('td');
        if (cells.length >= 3) {
          unitPrice = _extractPrice(cells.last.text);
        }
      }

      items.add(
        OrderItem(
          id: 'item-$i',
          name: name,
          imageUrl: imgUrl,
          quantity: qty,
          unitPrice: unitPrice > 0 ? unitPrice : 100,
        ),
      );
    }

    // 7. Pricing Breakdown
    double subtotal = 0;
    double deliveryFee = 0;
    double discount = 0;

    final subtotalEl = doc.querySelector('.subtotal, [data-subtotal]');
    if (subtotalEl != null) subtotal = _extractPrice(subtotalEl.text);

    final deliveryEl = doc.querySelector('.delivery-fee, .shipping-fee');
    if (deliveryEl != null) deliveryFee = _extractPrice(deliveryEl.text);

    final discountEl = doc.querySelector('.discount, .coupon-discount');
    if (discountEl != null) discount = _extractPrice(discountEl.text);

    if (subtotal == 0 && items.isNotEmpty) {
      subtotal = items.fold(0, (sum, i) => sum + i.subtotal);
    }

    // 8. Status History / Timeline
    final List<OrderStatusEvent> statusHistory = [];
    final timelineItems = doc.querySelectorAll('.timeline-item, .status-step, .history-row, .timeline li');
    for (final tItem in timelineItems) {
      final tStatus = _parseOrderStatus(tItem.text.toLowerCase());
      final tDate = _parseDateTime(tItem.text);
      final noteEl = tItem.querySelector('.note, .comment, .text-muted');
      statusHistory.add(
        OrderStatusEvent(
          status: tStatus,
          timestamp: tDate,
          note: noteEl?.text.trim(),
        ),
      );
    }

    if (statusHistory.isEmpty) {
      statusHistory.add(
        OrderStatusEvent(
          status: status,
          timestamp: placedAt,
          note: 'Order status: ${status.label}',
        ),
      );
    }

    return Order(
      id: referenceNumber,
      referenceNumber: referenceNumber,
      placedAt: placedAt,
      status: status,
      items: items.isNotEmpty
          ? items
          : [
              OrderItem(
                id: 'item-$referenceNumber',
                name: 'Order Items ($referenceNumber)',
                quantity: 1,
                unitPrice: subtotal > 0 ? subtotal : 100,
              ),
            ],
      deliveryAddress: OrderAddress(
        name: customerName,
        phone: customerPhone,
        addressLine: addressLine.isNotEmpty ? addressLine : 'Delivery Address',
        city: city,
      ),
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discount: discount,
      storeName: storeName,
      storeCity: storeCity,
      storeContact: storeContact,
      statusHistory: statusHistory,
    );
  }

  /// Maps a status string from HTML to [OrderStatus] enum.
  static OrderStatus _parseOrderStatus(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('cancel')) return OrderStatus.cancelled;
    if (lower.contains('refund')) return OrderStatus.refunded;
    if (lower.contains('deliver')) return OrderStatus.delivered;
    if (lower.contains('ship') || lower.contains('dispatch') || lower.contains('transit')) {
      return OrderStatus.shipped;
    }
    if (lower.contains('process') || lower.contains('pack')) {
      return OrderStatus.processing;
    }
    if (lower.contains('confirm')) return OrderStatus.confirmed;
    return OrderStatus.pending;
  }

  /// Extracts numeric price amount from currency string.
  static double _extractPrice(String text) {
    final cleaned = text.replaceAll(',', '').replaceAll('Rs.', '').replaceAll('PKR', '').replaceAll('Rs', '');
    final match = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(cleaned);
    if (match != null) {
      return double.tryParse(match.group(1)!) ?? 0.0;
    }
    return 0.0;
  }

  /// Parses date/time strings in multiple formats.
  static DateTime _parseDateTime(String text) {
    try {
      final isoMatch = RegExp(r'\d{4}-\d{2}-\d{2}(?:T|\s)\d{2}:\d{2}(?::\d{2})?').firstMatch(text);
      if (isoMatch != null) {
        return DateTime.parse(isoMatch.group(0)!);
      }

      final dateMatch = RegExp(r'(\d{1,2})[\s\-\/]([A-Za-z]+|\d{1,2})[\s\-\/](\d{4})').firstMatch(text);
      if (dateMatch != null) {
        final day = int.tryParse(dateMatch.group(1)!) ?? 1;
        final monthStr = dateMatch.group(2)!;
        final year = int.tryParse(dateMatch.group(3)!) ?? DateTime.now().year;

        int month = 1;
        if (int.tryParse(monthStr) != null) {
          month = int.parse(monthStr);
        } else {
          const months = ['jan', 'feb', 'mar', 'apr', 'may', 'jun', 'jul', 'aug', 'sep', 'oct', 'nov', 'dec'];
          final idx = months.indexWhere((m) => monthStr.toLowerCase().startsWith(m));
          if (idx != -1) month = idx + 1;
        }

        return DateTime(year, month, day);
      }
    } catch (_) {}

    return DateTime.now();
  }
}
