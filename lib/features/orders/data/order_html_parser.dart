import 'dart:developer' as developer;

import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

import '../models/order_model.dart';

/// Parses raw HTML responses from SoftStore order endpoints into strongly typed Order models.
///
/// Uses `package:html` to parse HTML into a DOM tree, then queries with CSS selectors.
/// Multiple fallback strategies ensure we extract orders from any HTML structure.
class OrderHtmlParser {
  // ── Safe DOM query helpers ────────────────────────────────────────────────

  static List<dom.Element> _qAll(dom.Document doc, String sel) {
    try {
      return doc.querySelectorAll(sel);
    } catch (_) {
      return [];
    }
  }

  static dom.Element? _q(dom.Document doc, String sel) {
    try {
      return doc.querySelector(sel);
    } catch (_) {
      return null;
    }
  }

  static List<dom.Element> _qAllOn(dom.Element el, String sel) {
    try {
      return el.querySelectorAll(sel);
    } catch (_) {
      return [];
    }
  }

  static dom.Element? _qOn(dom.Element el, String sel) {
    try {
      return el.querySelector(sel);
    } catch (_) {
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ORDERS LIST PARSER  (/store/account/orders)
  // ══════════════════════════════════════════════════════════════════════════

  /// Parses the orders list HTML page into a list of [Order].
  static List<Order> parseOrdersList(String html) {
    if (html.isEmpty) {
      _log('Empty HTML — returning 0 orders');
      return [];
    }

    _log('parseOrdersList: ${html.length} chars');
    final doc = html_parser.parse(html);

    // ── Phase 1: Find all links to individual order pages ────────────────
    // This is the most reliable strategy — every order page has a link like
    // /store/account/orders/INV-XXXXX or /orders/INV-XXXXX.
    final orderLinks = _qAll(doc, 'a[href*="/orders/"]');
    _log('Phase 1: found ${orderLinks.length} <a> links containing /orders/');

    // Build a map: invoiceNumber → {anchor, container}
    final Map<String, _OrderLinkInfo> linkMap = {};
    for (final anchor in orderLinks) {
      final href = anchor.attributes['href'] ?? '';
      final match = RegExp(r'/orders/([A-Za-z0-9][A-Za-z0-9_\-]+)').firstMatch(href);
      if (match == null) continue;
      final invoice = match.group(1)!;
      // Skip generic "orders" list links
      if (invoice.toLowerCase() == 'orders' || invoice.isEmpty) continue;
      // Skip if already seen (keep the first/outermost link per invoice)
      if (linkMap.containsKey(invoice)) continue;

      // Walk up the DOM to find the nearest meaningful container
      final container = _findOrderContainer(anchor);
      linkMap[invoice] = _OrderLinkInfo(anchor: anchor, container: container);
    }
    _log('Phase 1: extracted ${linkMap.length} unique order invoices: ${linkMap.keys.toList()}');

    if (linkMap.isNotEmpty) {
      final orders = <Order>[];
      int idx = 0;
      for (final entry in linkMap.entries) {
        idx++;
        final order = _buildOrderFromLink(entry.key, entry.value, idx);
        if (order != null) orders.add(order);
      }
      if (orders.isNotEmpty) {
        _log('Phase 1 success: ${orders.length} orders parsed');
        return orders;
      }
    }

    // ── Phase 2: Table rows ─────────────────────────────────────────────
    final tableRows = _qAll(doc, 'table tbody tr');
    _log('Phase 2: found ${tableRows.length} table rows');

    if (tableRows.isNotEmpty) {
      final orders = <Order>[];
      for (final row in tableRows) {
        final order = _buildOrderFromTableRow(row);
        if (order != null) orders.add(order);
      }
      if (orders.isNotEmpty) {
        _log('Phase 2 success: ${orders.length} orders parsed');
        return orders;
      }
    }

    // ── Phase 3: Card-like containers ───────────────────────────────────
    // Try Bootstrap card classes, common e-commerce patterns
    final cardSelectors = [
      '.order-card',
      '.card',
      '[data-order-id]',
      '[data-invoice]',
      '.order-item',
      '.order-row',
      '.order',
      '.list-group-item',
      '.panel',
      '.well',
    ];
    for (final sel in cardSelectors) {
      final cards = _qAll(doc, sel);
      if (cards.isEmpty) continue;
      _log('Phase 3: selector "$sel" found ${cards.length} elements');

      final orders = <Order>[];
      for (final card in cards) {
        final order = _buildOrderFromCard(card, orders.length + 1);
        if (order != null) orders.add(order);
      }
      if (orders.isNotEmpty) {
        _log('Phase 3 success: ${orders.length} orders parsed via "$sel"');
        return orders;
      }
    }

    // ── Phase 4: Regex scan of raw HTML ─────────────────────────────────
    // Last resort: find invoice patterns anywhere in the HTML
    _log('Phase 4: regex scan of raw HTML');
    final invoicePattern = RegExp(
      r'(?:INV|ORD|SS)[\-_]?(\d{4,}[\-_]?\d{0,}[\-_]?\d{0,})',
      caseSensitive: false,
    );
    final allMatches = invoicePattern.allMatches(html);
    final seenInvoices = <String>{};
    final orders = <Order>[];

    for (final m in allMatches) {
      final raw = m.group(0)!;
      // Deduplicate
      if (seenInvoices.contains(raw.toLowerCase())) continue;
      seenInvoices.add(raw.toLowerCase());

      // Try to find nearby context (status, amount)
      final startPos = (m.start - 200).clamp(0, html.length);
      final endPos = (m.end + 200).clamp(0, html.length);
      final context = html.substring(startPos, endPos);

      final status = _parseStatus(context.toLowerCase());
      final amount = _extractPrice(context);
      final date = _parseDateTime(context);

      orders.add(Order(
        id: raw,
        referenceNumber: raw,
        placedAt: date,
        status: status,
        items: const [],
        deliveryAddress: const OrderAddress(
          name: '',
          phone: '',
          addressLine: '',
          city: '',
        ),
        subtotal: amount,
        deliveryFee: 0,
        storeName: 'SoftStore',
      ));
    }
    _log('Phase 4: found ${orders.length} orders via regex');

    if (orders.isEmpty) {
      _logDiagnostic(doc, html);
    }

    return orders;
  }

  // ── Container finder ────────────────────────────────────────────────────

  /// Walks up the DOM from [anchor] to find the nearest meaningful container
  /// (div, li, tr, article, section) that wraps the entire order entry.
  static dom.Element? _findOrderContainer(dom.Element anchor) {
    dom.Element? node = anchor;
    dom.Element? lastGood;

    // Walk up max 8 levels, looking for a container that has meaningful text
    for (int i = 0; i < 8 && node != null; i++) {
      node = node.parent;
      if (node == null) break;

      final tag = node.localName;
      // Stop at these tags — they're likely the order container
      if (tag == 'div' || tag == 'li' || tag == 'tr' || tag == 'article' || tag == 'section') {
        final text = node.text.trim();
        // Only accept if it has enough content (at least 10 chars)
        if (text.length >= 10) {
          lastGood = node;
          // If it has multiple children or substantial text, this is likely the card
          if (node.children.length >= 2 || text.length > 30) {
            return node;
          }
        }
      }
    }
    return lastGood ?? anchor.parent;
  }

  // ── Order builder from link + container ──────────────────────────────────

  static Order? _buildOrderFromLink(String invoice, _OrderLinkInfo info, int index) {
    try {
      final container = info.container;
      final containerText = container?.text ?? info.anchor.text;

      // Try to extract status from specific elements within the container first.
      // This avoids false positives from "Cash on Delivery" or "Cancel Order" button text
      // that appear in the full container text.
      OrderStatus status = OrderStatus.pending;
      String? statusSource;
      if (container != null) {
        for (final sel in ['.status', '.badge', '.status-badge', '[class*="status"]',
            '.label', '.order-status', '.badge-pill']) {
          final el = _qOn(container, sel);
          if (el != null) {
            final text = el.text.trim();
            if (text.isNotEmpty && text.length < 50 && text.toLowerCase() != 'status') {
              status = _parseStatus(text.toLowerCase());
              statusSource = text;
              break;
            }
          }
        }
      }
      // Fallback: use container text only if no specific element found
      if (statusSource == null) {
        status = _parseStatus(containerText.toLowerCase());
      }

      final date = _extractDateNearby(containerText);

      // Try targeted CSS selectors first to avoid extracting invoice numbers as prices
      double amount = 0;
      if (container != null) {
        for (final sel in ['.order-total', '.subtotal', '[class*="total"]', '.amount']) {
          final el = _qOn(container, sel);
          if (el != null) {
            amount = _extractPrice(el.text);
            if (amount > 0) break;
          }
        }
      }
      // Fallback: scan container text for PKR/Rs price patterns only
      if (amount == 0) {
        final priceMatch = RegExp(r'(?:PKR|Rs\.?)\s*([\d,]+(?:\.\d+)?)').firstMatch(containerText);
        if (priceMatch != null) {
          amount = double.tryParse(priceMatch.group(1)!.replaceAll(',', '')) ?? 0;
        }
      }
      // Last resort: use generic extract on container text (may pick up invoice numbers)
      if (amount == 0) {
        amount = _extractPrice(containerText);
      }
      final storeName = _extractStoreName(container);

      return Order(
        id: invoice,
        referenceNumber: invoice,
        placedAt: date,
        status: status,
        items: const [],
        deliveryAddress: const OrderAddress(
          name: '',
          phone: '',
          addressLine: '',
          city: '',
        ),
        subtotal: amount,
        deliveryFee: 0,
        storeName: storeName.isNotEmpty ? storeName : 'SoftStore',
        statusHistory: [
          OrderStatusEvent(
            status: status,
            timestamp: date,
            note: 'Order placed',
          ),
        ],
      );
    } catch (e) {
      _log('Error building order from link $invoice: $e');
      return null;
    }
  }

  // ── Order builder from table row ─────────────────────────────────────────

  static Order? _buildOrderFromTableRow(dom.Element row) {
    try {
      final rowText = row.text;

      // Find invoice number
      String? invoice;
      // First try: link in the row
      final link = _qOn(row, 'a[href*="/orders/"]');
      if (link != null) {
        final href = link.attributes['href'] ?? '';
        final m = RegExp(r'/orders/([A-Za-z0-9][A-Za-z0-9_\-]+)').firstMatch(href);
        if (m != null) invoice = m.group(1);
      }
      // Second try: regex in row text
      invoice ??= _extractInvoiceFromText(rowText);
      if (invoice == null) return null;

      // Try to extract status from specific elements first
      OrderStatus status = OrderStatus.pending;
      for (final sel in ['.status', '.badge', '.status-badge', '[class*="status"]', '.label']) {
        final el = _qOn(row, sel);
        if (el != null) {
          final text = el.text.trim();
          if (text.isNotEmpty && text.length < 50 && text.toLowerCase() != 'status') {
            status = _parseStatus(text.toLowerCase());
            break;
          }
        }
      }
      // Fallback: row text
      if (status == OrderStatus.pending) {
        status = _parseStatus(rowText.toLowerCase());
      }

      final amount = _extractPrice(rowText);
      final date = _parseDateTime(rowText);
      final storeName = _extractStoreName(row);

      return Order(
        id: invoice,
        referenceNumber: invoice,
        placedAt: date,
        status: status,
        items: const [],
        deliveryAddress: const OrderAddress(
          name: '',
          phone: '',
          addressLine: '',
          city: '',
        ),
        subtotal: amount,
        deliveryFee: 0,
        storeName: storeName.isNotEmpty ? storeName : 'SoftStore',
      );
    } catch (e) {
      _log('Error building order from table row: $e');
      return null;
    }
  }

  // ── Order builder from card element ──────────────────────────────────────

  static Order? _buildOrderFromCard(dom.Element card, int index) {
    try {
      final cardText = card.text;

      // Find invoice
      String? invoice;
      // Try data attributes
      invoice = card.attributes['data-order-id'] ?? card.attributes['data-invoice'];
      // Try link inside card
      if (invoice == null || invoice.isEmpty) {
        final link = _qOn(card, 'a[href*="/orders/"]');
        if (link != null) {
          final href = link.attributes['href'] ?? '';
          final m = RegExp(r'/orders/([A-Za-z0-9][A-Za-z0-9_\-]+)').firstMatch(href);
          if (m != null) invoice = m.group(1);
        }
      }
      // Try regex in card text
      invoice ??= _extractInvoiceFromText(cardText);
      if (invoice == null) return null;

      // Try to extract status from specific elements first
      OrderStatus status = OrderStatus.pending;
      for (final sel in ['.status', '.badge', '.status-badge', '[class*="status"]', '.label']) {
        final el = _qOn(card, sel);
        if (el != null) {
          final text = el.text.trim();
          if (text.isNotEmpty && text.length < 50 && text.toLowerCase() != 'status') {
            status = _parseStatus(text.toLowerCase());
            break;
          }
        }
      }
      // Fallback: card text
      if (status == OrderStatus.pending) {
        status = _parseStatus(cardText.toLowerCase());
      }

      final amount = _extractPrice(cardText);
      final date = _extractDateNearby(cardText);
      final storeName = _extractStoreName(card);

      return Order(
        id: invoice,
        referenceNumber: invoice,
        placedAt: date,
        status: status,
        items: const [],
        deliveryAddress: const OrderAddress(
          name: '',
          phone: '',
          addressLine: '',
          city: '',
        ),
        subtotal: amount,
        deliveryFee: 0,
        storeName: storeName.isNotEmpty ? storeName : 'SoftStore',
      );
    } catch (e) {
      _log('Error building order from card: $e');
      return null;
    }
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  ORDER DETAIL PARSER  (/store/account/orders/{invoice})
  // ══════════════════════════════════════════════════════════════════════════

  /// Parses the order detail / track-order HTML page into a complete [Order].
  static Order parseOrderDetail(String html, {String? defaultReferenceNumber}) {
    final doc = html_parser.parse(html);

    // ── 1. Reference / Invoice Number ────────────────────────────────────
    String ref = defaultReferenceNumber ?? '';
    if (ref.isEmpty) {
      // Try prominent headings
      for (final sel in ['h1', 'h2', 'h3', '.invoice-number', '[data-invoice]', '.order-header']) {
        final el = _q(doc, sel);
        if (el != null) {
          final m = _extractInvoiceFromText(el.text);
          if (m != null) {
            ref = m;
            break;
          }
        }
      }
    }
    if (ref.isEmpty) {
      final m = _extractInvoiceFromText(html);
      ref = m ?? 'INV-${DateTime.now().millisecondsSinceEpoch}';
    }

    // ── 2. Status ────────────────────────────────────────────────────────
    OrderStatus status = OrderStatus.pending;
    for (final sel in [
      '.status-badge', '.order-status', '.badge', '.status',
      '[class*="status"]', '.label', '.badge-pill',
      '.order-status-badge', '.status-label',
    ]) {
      final el = _q(doc, sel);
      if (el != null) {
        final text = el.text.trim().toLowerCase();
        if (text.isNotEmpty && text != 'status') {
          status = _parseStatus(text);
          break;
        }
      }
    }
    // Fallback: scan body text for status keywords (more targeted)
    // Don't use entire body text — it contains "Cash on Delivery", "Cancel Order", etc.
    // instead look at specific elements that likely hold the status badge.
    if (status == OrderStatus.pending) {
      for (final sel in [
        '.badge', '.label', '[class*="badge"]', '[class*="label"]',
        'strong', 'b', 'h3', 'h4', 'h5',
        '.order-status', '.status-badge',
      ]) {
        final els = _qAll(doc, sel);
        for (final el in els) {
          final text = el.text.trim();
          if (text.isNotEmpty && text.length < 50) {
            final parsed = _parseStatus(text.toLowerCase());
            if (parsed != OrderStatus.pending) {
              status = parsed;
              break;
            }
          }
        }
        if (status != OrderStatus.pending) break;
      }
    }

    // ── 3. Date ──────────────────────────────────────────────────────────
    DateTime placedAt = DateTime.now();
    for (final sel in ['.order-date', '.placed-date', 'time', '.date', '.text-muted']) {
      final el = _q(doc, sel);
      if (el != null) {
        final d = _parseDateTime(el.text);
        if (d.isBefore(DateTime.now().add(const Duration(days: 1)))) {
          placedAt = d;
          break;
        }
      }
    }

    // ── 4. Customer / Shipping Info ──────────────────────────────────────
    String customerName = 'Buyer';
    String customerPhone = '';
    String addressLine = '';
    String city = '';

    for (final sel in [
      '.shipping-address', '.delivery-address', '.address-box',
      '.customer-info', '.address', '.shipping-info', '.delivery-info',
      '.recipient', '.billing-address', '[class*="shipping"]',
      '[class*="delivery-address"]', '[class*="recipient"]',
    ]) {
      final block = _q(doc, sel);
      if (block != null) {
        _parseAddressBlock(block, (name, phone, addr, c) {
          customerName = name;
          customerPhone = phone;
          addressLine = addr;
          city = c;
        });
        break;
      }
    }

    // ── 5. Store / Merchant ──────────────────────────────────────────────
    String storeName = 'SoftStore General';
    String? storeContact;
    for (final sel in [
      '.store-info', '.merchant-info', '.seller-info', '.shop-info',
      '.vendor-info', '[class*="store"]', '[class*="seller"]',
      '[class*="merchant"]', '[class*="vendor"]',
    ]) {
      final block = _q(doc, sel);
      if (block != null) {
        final nameEl = _qOn(block, '.store-name, h4, h5, strong, a');
        if (nameEl != null) storeName = nameEl.text.trim();
        final phoneEl = _qOn(block, '.phone, .contact, [class*="phone"]');
        if (phoneEl != null) storeContact = phoneEl.text.trim();
        break;
      }
    }

    // ── 6. Order Items ───────────────────────────────────────────────────
    final items = _parseOrderItems(doc);

    // ── 7. Pricing ───────────────────────────────────────────────────────
    double subtotal = 0;
    double deliveryFee = 0;
    double discount = 0;

    for (final sel in [
      '.subtotal', '[data-subtotal]', '.order-subtotal',
      '.order-total', '.items-total',
    ]) {
      final el = _q(doc, sel);
      if (el != null) {
        subtotal = _extractPrice(el.text);
        break;
      }
    }
    for (final sel in [
      '.delivery-fee', '.shipping-fee', '.delivery', '.shipping',
      '.shipping-cost', '.delivery-cost', '[class*="shipping"]',
    ]) {
      final el = _q(doc, sel);
      if (el != null) {
        deliveryFee = _extractPrice(el.text);
        break;
      }
    }
    for (final sel in [
      '.discount', '.coupon-discount', '.savings',
      '.order-discount', '.voucher', '[class*="discount"]',
    ]) {
      final el = _q(doc, sel);
      if (el != null) {
        discount = _extractPrice(el.text);
        break;
      }
    }

    // If subtotal is 0, try to extract from total element
    if (subtotal == 0) {
      for (final sel in [
        '.order-total', '.grand-total', '.total',
        '[class*="total"]', '.amount-due', '.final-total',
      ]) {
        final el = _q(doc, sel);
        if (el != null) {
          final total = _extractPrice(el.text);
          if (total > 0) {
            subtotal = total;
            break;
          }
        }
      }
    }

    // If still 0, sum from items
    if (subtotal == 0 && items.isNotEmpty) {
      subtotal = items.fold(0, (sum, i) => sum + i.subtotal);
    }

    // ── 8. Status History / Timeline ─────────────────────────────────────
    final history = _parseTimeline(doc);

    return Order(
      id: ref,
      referenceNumber: ref,
      placedAt: placedAt,
      status: status,
      items: items,
      deliveryAddress: OrderAddress(
        name: customerName,
        phone: customerPhone,
        addressLine: addressLine.isNotEmpty ? addressLine : 'Delivery Address',
        city: city.isNotEmpty ? city : 'Pakistan',
      ),
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      discount: discount,
      storeName: storeName,
      storeContact: storeContact,
      statusHistory: history.isNotEmpty
          ? history
          : [
              OrderStatusEvent(
                status: status,
                timestamp: placedAt,
                note: 'Order placed',
              ),
            ],
    );
  }

  // ── Items parser ────────────────────────────────────────────────────────

  static List<OrderItem> _parseOrderItems(dom.Document doc) {
    final items = <OrderItem>[];

    // Try multiple selectors for order items
    final selectors = [
      '.order-item', '.item-row', 'table.order-items tbody tr',
      '.items-table tr', '.product-row', '.cart-item', '.line-item',
      '.product-item', '.order-product', 'table tbody tr',
    ];

    List<dom.Element> rows = [];
    for (final sel in selectors) {
      rows = _qAll(doc, sel);
      if (rows.isNotEmpty) break;
    }

    // If no specific rows, try any table with product-like content
    if (rows.isEmpty) {
      final tables = _qAll(doc, 'table');
      for (final table in tables) {
        final trs = _qAllOn(table, 'tr');
        if (trs.length > 1) {
          rows = trs;
          break;
        }
      }
    }

    for (int i = 0; i < rows.length; i++) {
      final row = rows[i];
      final rowText = row.text.trim();

      // Skip header rows
      final lower = rowText.toLowerCase();
      if (lower.startsWith('product') || lower.startsWith('item') || lower.startsWith('name')) {
        continue;
      }

      // Extract name
      String? name;
      for (final sel in ['.product-name', '.item-name', '.name', 'a', 'td:first-child']) {
        final el = _qOn(row, sel);
        if (el != null) {
          final t = el.text.trim();
          if (t.isNotEmpty && t.length > 1 && !t.toLowerCase().startsWith('item')) {
            name = t;
            break;
          }
        }
      }
      if (name == null || name.isEmpty) {
        // Use first meaningful text from the row
        final parts = rowText.split(RegExp(r'\s{2,}'));
        name = parts.firstWhere(
          (p) => p.trim().length > 2 && !RegExp(r'^\d+$').hasMatch(p.trim()),
          orElse: () => '',
        );
      }
      if (name.isEmpty) continue;

      // Extract image
      final imgEl = _qOn(row, 'img');
      final imgUrl = imgEl?.attributes['src'] ?? imgEl?.attributes['data-src'];

      // Extract quantity
      int qty = 1;
      for (final sel in ['.item-qty', '.qty', '[data-qty]', '.quantity']) {
        final el = _qOn(row, sel);
        if (el != null) {
          final m = RegExp(r'\d+').firstMatch(el.text);
          if (m != null) qty = int.tryParse(m.group(0)!) ?? 1;
          break;
        }
      }
      if (qty == 1) {
        // Try second cell for quantity
        final cells = _qAllOn(row, 'td');
        if (cells.length >= 2) {
          final m = RegExp(r'\d+').firstMatch(cells[1].text);
          if (m != null) qty = int.tryParse(m.group(0)!) ?? 1;
        }
      }

      // Extract price
      double price = 0;
      for (final sel in ['.item-price', '.price', '.unit-price', '.cost']) {
        final el = _qOn(row, sel);
        if (el != null) {
          price = _extractPrice(el.text);
          if (price > 0) break;
        }
      }
      if (price == 0) {
        // Try last cell for price
        final cells = _qAllOn(row, 'td');
        if (cells.isNotEmpty) {
          price = _extractPrice(cells.last.text);
        }
      }

      items.add(OrderItem(
        id: 'item-$i',
        name: name,
        imageUrl: imgUrl,
        quantity: qty,
        unitPrice: price > 0 ? price : 0,
      ));
    }

    return items;
  }

  // ── Timeline parser ─────────────────────────────────────────────────────

  static List<OrderStatusEvent> _parseTimeline(dom.Document doc) {
    final history = <OrderStatusEvent>[];

    final selectors = [
      '.timeline-item',
      '.status-step',
      '.history-row',
      '.timeline li',
      '.order-timeline li',
      '.step',
      '.progress-step',
    ];

    List<dom.Element> items = [];
    for (final sel in selectors) {
      items = _qAll(doc, sel);
      if (items.isNotEmpty) break;
    }

    for (final item in items) {
      final text = item.text.toLowerCase();
      final status = _parseStatus(text);
      final timestamp = _parseDateTime(item.text);
      final noteEl = _qOn(item, '.note, .comment, .text-muted, .description, p');
      history.add(OrderStatusEvent(
        status: status,
        timestamp: timestamp,
        note: noteEl?.text.trim(),
      ));
    }

    return history;
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  RETURNS LIST PARSER
  // ══════════════════════════════════════════════════════════════════════════

  static List<Map<String, dynamic>> parseReturnsList(String html) {
    if (html.isEmpty) return [];
    final doc = html_parser.parse(html);
    final List<Map<String, dynamic>> returns = [];

    final rows = _qAll(doc, 'table tbody tr');
    if (rows.isEmpty) rows.addAll(_qAll(doc, '.return-card'));
    if (rows.isEmpty) rows.addAll(_qAll(doc, '.list-group-item'));

    for (final row in rows) {
      try {
        final idMatch = RegExp(r'#?(\d+)').firstMatch(row.text);
        final id = idMatch != null ? int.tryParse(idMatch.group(1)!) ?? 0 : 0;
        final statusEl = _qOn(row, '.badge, [class*="status"]');
        final status = statusEl?.text.trim() ?? 'Pending';
        final reasonEl = _qOn(row, '[class*="reason"], td:nth-child(3)');
        final reason = reasonEl?.text.trim() ?? '';
        final dateEl = _qOn(row, '[class*="date"], time, td:nth-child(4)');
        final date = dateEl?.text.trim() ?? '';

        if (id > 0 || reason.isNotEmpty) {
          returns.add({
            'id': id,
            'status': status,
            'reason': reason,
            'created_at': date,
          });
        }
      } catch (_) {}
    }
    return returns;
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  HELPER: EXTRACT DATA FROM TEXT
  // ══════════════════════════════════════════════════════════════════════════

  /// Extracts an invoice number from raw text using common patterns.
  static String? _extractInvoiceFromText(String text) {
    // Common patterns: INV-20240809-0117, ORD-12345, SS-20240809-0117, #INV-12345
    final patterns = [
      RegExp(r'((?:INV|ORD|SS)[\-_]\d{4,}[\-_]?\d{0,}[\-_]?\d{0,})', caseSensitive: false),
      RegExp(r'#([A-Z0-9]{2,}[\-_][A-Z0-9_\-]+)'),
      RegExp(r'([A-Z]{2,}[\-_]\d{4,})'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(text);
      if (m != null) return m.group(1) ?? m.group(0);
    }
    return null;
  }

  /// Extracts store name from a DOM element by looking for common selectors.
  static String _extractStoreName(dom.Element? el) {
    if (el == null) return '';
    for (final sel in ['.store-name', '.seller-name', '.merchant-name', '.shop-name']) {
      final nameEl = _qOn(el, sel);
      if (nameEl != null) {
        final text = nameEl.text.trim();
        if (text.isNotEmpty) return text;
      }
    }
    return '';
  }

  /// Extracts a date from surrounding text (scans for date-like patterns).
  static DateTime _extractDateNearby(String text) {
    // Try to find a date pattern in the text
    final date = _parseDateTime(text);
    // If we got "now" but text has a year-like number, try harder
    if (date == DateTime.now() && RegExp(r'20\d{2}').hasMatch(text)) {
      return _parseDateTime(text);
    }
    return date;
  }

  /// Parses address block into components.
  static void _parseAddressBlock(
    dom.Element block,
    void Function(String name, String phone, String address, String city) onResult,
  ) {
    final lines = block.text
        .split(RegExp(r'[\n,]+'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    String name = 'Buyer';
    String phone = '';
    String address = '';
    String city = '';

    for (final line in lines) {
      if (RegExp(r'\+?92|\b03\d{2}').hasMatch(line)) {
        phone = line;
      } else if (line.length > 3 && name == 'Buyer') {
        name = line;
      } else {
        address = address.isEmpty ? line : '$address, $line';
      }
    }

    // Try to extract city (last part of address)
    if (address.contains(',')) {
      final parts = address.split(',');
      city = parts.last.trim();
    }

    onResult(name, phone, address, city);
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  HELPER: STATUS / PRICE / DATE PARSERS
  // ══════════════════════════════════════════════════════════════════════════

  static OrderStatus _parseStatus(String text) {
    final lower = text.toLowerCase();
    // Use exact status keywords to avoid false positives from page-wide text.
    // e.g., "Cash on Delivery" contains "delivery" NOT "delivered" — must not match.
    // "Cancel Order" button contains "cancel" NOT "cancelled" — must not match.
    // "Shipping Address" contains "shipping" NOT "shipped" — must not match.
    if (lower.contains('delivered')) return OrderStatus.delivered;
    if (lower.contains('refund')) return OrderStatus.refunded;
    if (lower.contains('shipped') || lower.contains('dispatched') ||
        lower.contains('in transit') || lower.contains('out for delivery')) {
      return OrderStatus.shipped;
    }
    if (lower.contains('processing') || lower.contains('packing') ||
        lower.contains('preparing')) {
      return OrderStatus.processing;
    }
    if (lower.contains('confirmed')) return OrderStatus.confirmed;
    if (lower.contains('cancelled') || lower.contains('canceled')) {
      return OrderStatus.cancelled;
    }
    return OrderStatus.pending;
  }

  static double _extractPrice(String text) {
    final cleaned = text
        .replaceAll(',', '')
        .replaceAll('PKR', '')
        .replaceAll('Rs.', '')
        .replaceAll('Rs', '')
        .replaceAll('PKR ', '')
        .trim();

    // Find all number matches and return the first valid price.
    // Skip numbers that are likely invoice IDs (8+ digits like 20240809),
    // phone numbers (11 digits starting with 0), or timestamps.
    final allMatches = RegExp(r'(\d+(?:\.\d+)?)').allMatches(cleaned);
    for (final match in allMatches) {
      final numStr = match.group(1)!;
      final value = double.tryParse(numStr);
      if (value == null || value <= 0) continue;

      // Skip numbers that are almost certainly not prices:
      // - 8+ digits: invoice IDs (20240809), timestamps, phone numbers
      // - 4-digit numbers starting with 20 that look like years (2024)
      if (numStr.length >= 8) continue;
      if (numStr.length == 4 && numStr.startsWith('20') && value >= 2000 && value <= 2100) continue;

      return value;
    }
    return 0.0;
  }

  static DateTime _parseDateTime(String text) {
    // ISO: 2024-08-09T10:30:00 or 2024-08-09 10:30
    final isoMatch = RegExp(r'(\d{4}-\d{2}-\d{2}(?:T|\s)\d{2}:\d{2}(?::\d{2})?)').firstMatch(text);
    if (isoMatch != null) {
      try {
        return DateTime.parse(isoMatch.group(1)!);
      } catch (_) {}
    }

    // Day Month Year: 09 Aug 2024, 9 August 2024
    final dmMatch = RegExp(r'(\d{1,2})\s+([A-Za-z]+)\s+(\d{4})').firstMatch(text);
    if (dmMatch != null) {
      final day = int.tryParse(dmMatch.group(1)!) ?? 1;
      final monthStr = dmMatch.group(2)!;
      final year = int.tryParse(dmMatch.group(3)!) ?? DateTime.now().year;
      final month = _monthToNum(monthStr);
      if (month > 0) return DateTime(year, month, day);
    }

    // Month Day, Year: Aug 09, 2024
    final mdMatch = RegExp(r'([A-Za-z]+)\s+(\d{1,2}),?\s+(\d{4})').firstMatch(text);
    if (mdMatch != null) {
      final monthStr = mdMatch.group(1)!;
      final day = int.tryParse(mdMatch.group(2)!) ?? 1;
      final year = int.tryParse(mdMatch.group(3)!) ?? DateTime.now().year;
      final month = _monthToNum(monthStr);
      if (month > 0) return DateTime(year, month, day);
    }

    // YYYY-MM-DD
    final ymdMatch = RegExp(r'(\d{4})-(\d{2})-(\d{2})').firstMatch(text);
    if (ymdMatch != null) {
      final year = int.tryParse(ymdMatch.group(1)!) ?? DateTime.now().year;
      final month = int.tryParse(ymdMatch.group(2)!) ?? 1;
      final day = int.tryParse(ymdMatch.group(3)!) ?? 1;
      return DateTime(year, month, day);
    }

    return DateTime.now();
  }

  static int _monthToNum(String month) {
    const months = {
      'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
      'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
    };
    final lower = month.toLowerCase().substring(0, 3.clamp(0, month.length));
    return months[lower] ?? 0;
  }

  // ══════════════════════════════════════════════════════════════════════════
  //  DIAGNOSTIC LOGGING
  // ══════════════════════════════════════════════════════════════════════════

  static void _log(String msg) {
    developer.log('[OrderParser] $msg', name: 'orders');
  }

  static void _logDiagnostic(dom.Document doc, String html) {
    final bodyText = doc.body?.text ?? '';
    _log('=== DIAGNOSTIC (no orders found) ===');
    _log('Body text length: ${bodyText.length}');
    _log('Body preview: ${bodyText.length > 500 ? bodyText.substring(0, 500) : bodyText}');

    // Dump all links
    final allLinks = _qAll(doc, 'a[href]');
    final hrefs = allLinks
        .map((a) => a.attributes['href'] ?? '')
        .where((h) => h.isNotEmpty)
        .take(30)
        .toList();
    _log('All links (${hrefs.length}): $hrefs');

    // Dump all classes on divs
    final divs = _qAll(doc, 'div[class]');
    final classes = divs
        .map((d) => d.attributes['class'] ?? '')
        .where((c) => c.isNotEmpty)
        .take(30)
        .toList();
    _log('Div classes (${classes.length}): $classes');

    // Dump all table structures
    final tables = _qAll(doc, 'table');
    _log('Tables found: ${tables.length}');
    for (int i = 0; i < tables.length.clamp(0, 3); i++) {
      final rows = _qAllOn(tables[i], 'tr');
      _log('  Table $i: ${rows.length} rows, first row text: ${rows.isNotEmpty ? rows.first.text.substring(0, rows.first.text.length.clamp(0, 100)) : "empty"}');
    }

    _log('=== END DIAGNOSTIC ===');
  }
}

// ── Internal helper class ────────────────────────────────────────────────

class _OrderLinkInfo {
  final dom.Element anchor;
  final dom.Element? container;

  const _OrderLinkInfo({required this.anchor, this.container});
}
