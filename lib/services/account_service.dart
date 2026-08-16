import '../core/networking/web_session_client.dart';
import '../core/networking/api_error.dart';
import '../core/models/buyer.dart';
import '../core/models/order.dart';
import '../core/models/address.dart';

class AccountService {
  final _web = WebSessionClient.shared;

  // MARK: - Dashboard
  Future<BuyerDashboardStats> dashboard() async {
    final html = await _web.fetchHtml('/marketplace/account');
    return _parseDashboard(html);
  }

  // MARK: - Profile
  Future<void> updateProfile(String firstName, String lastName, String? phone) async {
    final csrf = await _web.fetchCsrf('/marketplace/account/profile');
    final fields = <String, String>{
      '_csrf_token': csrf,
      'first_name': firstName,
      'last_name': lastName,
    };
    if (phone != null && phone.isNotEmpty) fields['phone'] = phone;
    final (:html, :finalUrl) = await _web.postForm('/marketplace/account/profile', fields);
    final err = _scrapeError(html);
    if (err != null) throw ApiError(err);
  }

  // MARK: - Addresses
  Future<List<Address>> addresses() async {
    final html = await _web.fetchHtml('/marketplace/account/addresses');
    return _parseAddresses(html);
  }

  Future<void> addAddress(Address address) async {
    final csrf = await _web.fetchCsrf('/marketplace/account/addresses');
    final fields = <String, String>{
      '_csrf_token': csrf,
      'recipient_name': address.recipientName,
      'address_line1': address.addressLine1,
      'city': address.city,
    };
    if (address.addressLine2 != null && address.addressLine2!.isNotEmpty) fields['address_line2'] = address.addressLine2!;
    if (address.state != null) fields['state'] = address.state!;
    if (address.postalCode != null) fields['postal_code'] = address.postalCode!;
    if (address.phone.isNotEmpty) fields['phone'] = address.phone;
    if (address.isDefault) fields['is_default'] = '1';
    final (:html, :finalUrl) = await _web.postForm('/marketplace/account/addresses', fields);
    final err = _scrapeError(html);
    if (err != null) throw ApiError(err);
  }

  Future<void> deleteAddress(int id) async {
    final csrf = await _web.fetchCsrf('/marketplace/account/addresses');
    await _web.postForm('/marketplace/account/addresses/$id/delete', {'_csrf_token': csrf});
  }

  // MARK: - Orders
  Future<OrderHistoryPage> orders(int page) async {
    final html = await _web.fetchHtml('/marketplace/account/orders?page=$page');
    return _parseOrders(html, page);
  }

  Future<OrderDetailResponse> orderDetail(int id) async {
    final html = await _web.fetchHtml('/marketplace/account/orders/$id');
    return _parseOrderDetail(html, id);
  }

  Future<TrackOrderResponse> trackOrder(String invoice, String phone) async {
    final html = await _web.fetchHtml('/track-order?invoice=${Uri.encodeQueryComponent(invoice)}&phone=${Uri.encodeQueryComponent(phone)}');
    return _parseTrackOrder(html);
  }

  Future<void> requestReturn({
    required int orderId,
    required String reason,
    required String returnType,
    required List<({int productId, double quantity})> items,
    List<({String filename, String mimeType, List<int> data})> photos = const [],
  }) async {
    final csrf = await _web.fetchCsrf('/marketplace/account/orders/$orderId');
    final fields = <String, String>{
      '_csrf_token': csrf,
      'reason': reason,
      'return_type': returnType,
    };
    for (int i = 0; i < items.length; i++) {
      fields['product_id[$i]'] = '${items[i].productId}';
      fields['returned_quantity[$i]'] = '${items[i].quantity}';
    }
    if (photos.isEmpty) {
      final (:html, :finalUrl) = await _web.postForm('/marketplace/account/orders/$orderId/return', fields);
      final err = _scrapeError(html);
      if (err != null) throw ApiError(err);
    } else {
      final (:html, :finalUrl) = await _web.postMultipart('/marketplace/account/orders/$orderId/return', fields, 'photo', photos);
      final err = _scrapeError(html);
      if (err != null) throw ApiError(err);
    }
  }

  Future<List<ReturnRequest>> returns() async {
    final html = await _web.fetchHtml('/marketplace/account/returns');
    return _parseReturns(html);
  }

  // MARK: - Wishlist
  Future<List<WishlistItem>> wishlist() async {
    final html = await _web.fetchHtml('/marketplace/account/wishlist');
    return _parseWishlist(html);
  }

  Future<({bool success, String? action})> toggleWishlist(int productId) async {
    final pageHtml = await _web.fetchHtml('/product/$productId');
    final csrf = _web.scrapeCSRF(pageHtml);
    if (csrf == null) throw ApiError('Could not read security token.');
    return _web.postFormJson<({bool success, String? action})>(
      '/api/marketplace/wishlist/toggle',
      {'product_id': '$productId', '_csrf_token': csrf},
      csrf,
      (j) => (success: j['success'] == true, action: j['action'] as String?),
    );
  }

  Future<void> submitReview(int productId, int rating, String reviewText) async {
    final pageHtml = await _web.fetchHtml('/product/$productId');
    final csrf = _web.scrapeCSRF(pageHtml) ?? '';
    await _web.postJson<Map<String, dynamic>>(
      '/marketplace/account/reviews',
      {'product_id': productId, 'rating': rating, 'review_text': reviewText},
      (j) => j,
      csrfToken: csrf,
    );
  }

  // MARK: - HTML Parsers

  BuyerDashboardStats _parseDashboard(String html) {
    int cleanInt(String s) => int.tryParse(s.replaceAll(',', '')) ?? 0;
    double cleanDbl(String s) => double.tryParse(s.replaceAll(',', '')) ?? 0;

    final primary = RegExp(r'(?:fw-bold[^"]*mb-1|mb-1[^"]*fw-bold)[^"]*">\s*(?:PKR\s*)?([0-9,]+)', dotAll: true)
        .allMatches(html).map((m) => m.group(1) ?? '').toList();
    if (primary.length >= 3) {
      return BuyerDashboardStats(totalOrders: cleanInt(primary[0]), totalSpent: cleanDbl(primary[1]), wishlistItems: cleanInt(primary[2]));
    }
    final orders = int.tryParse(RegExp(r'[Tt]otal\s+[Oo]rder[s]?[^>]*>\s*([0-9,]+)').firstMatch(html)?.group(1)?.replaceAll(',', '') ?? '') ?? 0;
    final spentRaw = RegExp(r'(?:PKR|Rs\.?)\s*([0-9,]+(?:\.[0-9]+)?)').firstMatch(html)?.group(1) ?? '0';
    final wishlist = int.tryParse(RegExp(r'[Ww]ishlist[^>]*>\s*([0-9]+)').firstMatch(html)?.group(1) ?? '') ?? 0;
    return BuyerDashboardStats(totalOrders: orders, totalSpent: cleanDbl(spentRaw), wishlistItems: wishlist);
  }

  List<Address> _parseAddresses(String html) {
    final addresses = <Address>[];
    final seen = <int>{};

    for (final (idx, m) in RegExp(r'(?:m-feature-card|address-card)[^"]*"([\s\S]{0,1500}?)</form>', dotAll: true).allMatches(html).indexed) {
      final card = m.group(1) ?? '';
      final addrIdStr = RegExp(r'action="/marketplace/account/addresses/(\d+)/delete"').firstMatch(card)?.group(1)
          ?? RegExp(r'/addresses/(\d+)').firstMatch(card)?.group(1);
      final addrId = int.tryParse(addrIdStr ?? '') ?? (idx + 1);
      if (seen.contains(addrId)) continue;
      seen.add(addrId);

      String s(String p) => (RegExp(p, dotAll: true).firstMatch(card)?.group(1) ?? '').stripHtmlTags().decodeHtmlEntities().trim();

      final recipientName = s(r'fw-bold[^>]*>([^<]{2,80})<') != '' ? s(r'fw-bold[^>]*>([^<]{2,80})<') : s(r'recipient[^>]*>([^<]{2,80})<');
      final line1 = s(r'address(?:_line1)?[^>]*>([^<]{2,120})<').isNotEmpty ? s(r'address(?:_line1)?[^>]*>([^<]{2,120})<') : s(r'text-muted[^>]*>([^<]{5,120})<');
      final line2Raw = RegExp(r'address_line2[^>]*>([^<]{2,120})<').firstMatch(card)?.group(1)?.stripHtmlTags().decodeHtmlEntities();
      final city = s(r'city[^>]*>([^<]{2,60})<').isNotEmpty ? s(r'city[^>]*>([^<]{2,60})<') : '';
      final phone = RegExp(r'phone[^>]*>([0-9\+\- ]{7,16})<').firstMatch(card)?.group(1) ?? '';
      final isDefault = card.toLowerCase().contains('default') && !card.toLowerCase().contains('set as default');

      addresses.add(Address(
        id: addrId,
        recipientName: recipientName.isNotEmpty ? recipientName : 'Address ${idx + 1}',
        phone: phone,
        addressLine1: line1.isNotEmpty ? line1 : 'Address',
        addressLine2: line2Raw?.isNotEmpty == true ? line2Raw : null,
        city: city,
        isDefault: isDefault,
      ));
    }
    return addresses;
  }

  OrderHistoryPage _parseOrders(String html, int page) {
    double? cleanN(String s) => double.tryParse(s.replaceAll(',', ''));
    final orders = <Order>[];
    final seen = <int>{};

    for (final m in RegExp(r'href="/marketplace/account/orders/(\d+)"([\s\S]{0,2000}?)(?=href="/marketplace/account/orders/\d+"|</table>|</ul>|$)', dotAll: true).allMatches(html)) {
      final id = int.tryParse(m.group(1) ?? '') ?? 0;
      if (id <= 0 || seen.contains(id)) continue;
      seen.add(id);
      final card = m.group(2) ?? '';
      final createdAt = RegExp(r'text-muted[^>]*>\s*([^<]{6,30})').firstMatch(card)?.group(1)
          ?? RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})').firstMatch(card)?.group(1) ?? '';
      final itemsCount = int.tryParse(RegExp(r'(\d+)\s*[Ii]tem').firstMatch(card)?.group(1) ?? '') ?? 0;
      final businessName = RegExp(r'fw-semibold[^>]*>\s*([^<]+)').firstMatch(card)?.group(1)?.stripHtmlTags();
      final grandTotal = cleanN(RegExp(r'PKR\s*([\d,\.]+)').firstMatch(card)?.group(1) ?? '')
          ?? cleanN(RegExp(r'Rs\.?\s*([\d,\.]+)').firstMatch(card)?.group(1) ?? '') ?? 0;
      final statusRaw = RegExp(r'm-badge[^"]*"[^>]*>\s*([A-Za-z ]+?)\s*</(?:span|div|td)>').firstMatch(card)?.group(1)
          ?? RegExp(r'badge[^>]*>\s*([A-Za-z]+)\s*</(?:span|div)>').firstMatch(card)?.group(1) ?? '';
      final status = OrderStatus.fromString(statusRaw);
      final invoiceNo = RegExp(r'#([A-Z0-9\-]+)').firstMatch(card)?.group(1) ?? '#$id';

      orders.add(Order(id: id, invoiceNumber: invoiceNo, subtotal: grandTotal, grandTotal: grandTotal, saleStatus: status, businessName: businessName?.isNotEmpty == true ? businessName : null, createdAt: createdAt, itemsCount: itemsCount));
    }

    if (orders.isEmpty) {
      for (final m in RegExp(r'href="/marketplace/account/orders/(\d+)"').allMatches(html)) {
        final id = int.tryParse(m.group(1) ?? '') ?? 0;
        if (id <= 0 || seen.contains(id)) continue;
        seen.add(id);
        orders.add(Order(id: id, invoiceNumber: '#$id', subtotal: 0, grandTotal: 0, saleStatus: OrderStatus.pending, createdAt: ''));
      }
    }

    final totalPages = int.tryParse(RegExp(r'page=(\d+)[^"]*"[^>]*aria-label="Last"').firstMatch(html)?.group(1) ?? '') ?? 1;
    return OrderHistoryPage(orders: orders, total: orders.length, page: page, totalPages: totalPages.clamp(1, 9999));
  }

  OrderDetailResponse _parseOrderDetail(String html, int id) {
    double? cleanN(String s) => double.tryParse(s.replaceAll(',', ''));

    final statusRaw = (RegExp(r'm-badge[^"]*"[^>]*>\s*([A-Za-z ]+?)\s*</(?:div|span)>').firstMatch(html)?.group(1)
        ?? RegExp(r'status[^>]*>\s*([A-Za-z ]+?)\s*</(?:div|span|td)>').firstMatch(html)?.group(1) ?? 'pending').toLowerCase();
    final status = OrderStatus.fromString(statusRaw);

    final grandTotal = cleanN(RegExp(r'[Gg]rand\s+[Tt]otal.*?(?:PKR|Rs\.?)\s*([\d,\.]+)', dotAll: true).firstMatch(html)?.group(1) ?? '')
        ?? cleanN(RegExp(r'(?:PKR|Rs\.?)\s*([\d,\.]+)').firstMatch(html)?.group(1) ?? '') ?? 0;
    final subtotal = cleanN(RegExp(r'[Ss]ubtotal.*?(?:PKR|Rs\.?)\s*([\d,\.]+)', dotAll: true).firstMatch(html)?.group(1) ?? '') ?? grandTotal;
    final delivery = cleanN(RegExp(r'[Dd]elivery.*?(?:PKR|Rs\.?)\s*([\d,\.]+)', dotAll: true).firstMatch(html)?.group(1) ?? '') ?? 0;
    final discount = cleanN(RegExp(r'[Dd]iscount.*?(?:PKR|Rs\.?)\s*([\d,\.]+)', dotAll: true).firstMatch(html)?.group(1) ?? '') ?? 0;

    final createdAt = RegExp(r'[Pp]laced\s+on\s+([^<]{6,30})').firstMatch(html)?.group(1) ?? '';
    final invoiceNo = RegExp(r'[Oo]rder\s*#\s*(\S+)').firstMatch(html)?.group(1)
        ?? RegExp(r'[Ii]nvoice[:\s#]*([A-Z0-9\-]+)').firstMatch(html)?.group(1) ?? '$id';
    final businessName = RegExp(r'[Ss]tore.*?fw-semibold.*?>([^<]+)<', dotAll: true).firstMatch(html)?.group(1)?.stripHtmlTags();
    final customerName = RegExp(r'[Rr]ecipient[^>]*>\s*([^<]+)').firstMatch(html)?.group(1)?.stripHtmlTags();
    final customerAddress = RegExp(r'[Dd]elivery\s*[Aa]ddress[^>]*>\s*([^<]+)').firstMatch(html)?.group(1)?.stripHtmlTags();
    final customerPhone = RegExp(r'[Pp]hone[^>]*>\s*([0-9\+\- ]{7,16})').firstMatch(html)?.group(1);

    final items = _parseOrderItems(html, id);
    final statusHistory = _parseTimeline(html, id);
    final returnEligibility = _makeReturnEligibility(status, statusHistory);

    final order = Order(
      id: id, invoiceNumber: invoiceNo,
      subtotal: subtotal, taxAmount: 0, discountAmount: discount, deliveryFee: delivery,
      grandTotal: grandTotal, saleStatus: status,
      businessName: businessName?.isNotEmpty == true ? businessName : null,
      customerName: customerName, customerAddress: customerAddress, customerPhone: customerPhone,
      createdAt: createdAt,
      itemsCount: items.isEmpty ? null : items.length,
      items: items.isEmpty ? null : items,
    );

    return OrderDetailResponse(order: order, statusHistory: statusHistory, returnEligibility: returnEligibility);
  }

  TrackOrderResponse _parseTrackOrder(String html) {
    double? cleanN(String s) => double.tryParse(s.replaceAll(',', ''));

    final statusRaw = (RegExp(r'(?:badge|status)[^>]*>\s*([A-Za-z][A-Za-z ]+?)\s*</(?:span|div|td)>').firstMatch(html)?.group(1) ?? 'pending').toLowerCase();
    final status = OrderStatus.fromString(statusRaw);
    final grandTotal = cleanN(RegExp(r'[Gg]rand\s*[Tt]otal[^>]*>\s*(?:PKR\s*)?([\d,\.]+)').firstMatch(html)?.group(1) ?? '')
        ?? cleanN(RegExp(r'PKR\s*([\d,\.]+)').firstMatch(html)?.group(1) ?? '') ?? 0;
    final invoiceNo = RegExp(r'Invoice[:\s#]*([A-Z0-9\-]+)').firstMatch(html)?.group(1)
        ?? RegExp(r'Order\s*#?\s*([A-Z0-9\-]+)').firstMatch(html)?.group(1) ?? '';
    final createdAt = RegExp(r'[Pp]laced\s+on\s+([^<]{5,30})').firstMatch(html)?.group(1)
        ?? RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})').firstMatch(html)?.group(1) ?? '';
    final deliveryFee = cleanN(RegExp(r'[Dd]elivery[^>]*>.*?(?:PKR\s*)?([\d,\.]+)', dotAll: true).firstMatch(html)?.group(1) ?? '') ?? 0;
    final subtotal = cleanN(RegExp(r'[Ss]ubtotal[^>]*>.*?(?:PKR\s*)?([\d,\.]+)', dotAll: true).firstMatch(html)?.group(1) ?? '') ?? grandTotal;

    final statusHistory = _parseTimeline(html, 0);
    final items = _parseOrderItems(html, 0);

    final order = Order(
      id: 0, invoiceNumber: invoiceNo,
      subtotal: subtotal, deliveryFee: deliveryFee, grandTotal: grandTotal,
      saleStatus: status, createdAt: createdAt,
      itemsCount: items.isEmpty ? null : items.length,
      items: items.isEmpty ? null : items,
    );

    return TrackOrderResponse(order: order, items: items, statusHistory: statusHistory);
  }

  List<SaleItem> _parseOrderItems(String html, int saleId) {
    final items = <SaleItem>[];
    double? cleanN(String s) => double.tryParse(s.replaceAll(',', '').replaceAll(RegExp(r'[^0-9.]'), ''));

    RegExpMatch? tableM;
    for (final m in RegExp(r'<table[^>]*>([\s\S]*?)</table>', dotAll: true).allMatches(html)) {
      final b = m.group(1)?.toLowerCase() ?? '';
      if (b.contains('product') || b.contains('item') || b.contains('qty')) {
        tableM = m;
        break;
      }
    }

    final tableHtml = tableM?.group(1) ?? html;

    for (final rowM in RegExp(r'<tr[^>]*>([\s\S]{0,600}?)</tr>', dotAll: true).allMatches(tableHtml)) {
      final row = rowM.group(1) ?? '';
      if (!row.contains('product') && !row.contains('item') && !row.toLowerCase().contains('qty')) continue;
      final cells = RegExp(r'<td[^>]*>([\s\S]{0,200}?)</td>', dotAll: true).allMatches(row).map((m) => m.group(1) ?? '').toList();
      if (cells.length < 2) continue;
      final nameCell = cells.firstWhere((c) => c.stripHtmlTags().trim().isNotEmpty, orElse: () => '');
      final name = nameCell.stripHtmlTags().decodeHtmlEntities().trim();
      if (name.length < 3 || name.toLowerCase().startsWith('product') || name.toLowerCase().startsWith('qty')) continue;
      final imgSrc = RegExp(r'<img[^>]+src="([^"]+)"').firstMatch(row)?.group(1);
      final imgUrl = imgSrc != null ? (imgSrc.startsWith('http') ? imgSrc : 'https://beta.softstore.pk${imgSrc.startsWith('/') ? imgSrc : '/$imgSrc'}') : null;
      final productId = int.tryParse(RegExp(r'href="/product/(\d+)"').firstMatch(row)?.group(1) ?? '') ?? 0;
      final priceCell = cells.lastWhere((c) => c.contains('PKR') || RegExp(r'[\d,]+').hasMatch(c), orElse: () => '');
      final lineTotal = cleanN(priceCell.replaceAll(RegExp(r'[^0-9.,]'), '')) ?? 0;
      final qtyCell = cells.firstWhere((c) => c != priceCell && c != nameCell && c.stripHtmlTags().trim().length <= 4, orElse: () => '');
      final qty = double.tryParse(qtyCell.stripHtmlTags().trim()) ?? 1;
      items.add(SaleItem(id: items.length + 1, saleId: saleId, productId: productId, productName: name, imageUrl: imgUrl, unitPrice: qty > 0 ? lineTotal / qty : lineTotal, quantity: qty, subtotal: lineTotal, totalAmount: lineTotal));
    }
    return items;
  }

  List<OrderStatusEvent> _parseTimeline(String html, int saleId) {
    final events = <OrderStatusEvent>[];
    final timelineM = RegExp(r'track-timeline[\s\S]{0,6000}').firstMatch(html);
    final timelineHtml = timelineM?.group(0) ?? html;

    int eventId = 1;
    for (final m in RegExp(r'<(?:li|tr|div)[^>]*>([\s\S]{0,500}?)</(?:li|tr|div)>', dotAll: true).allMatches(timelineHtml)) {
      final row = m.group(1) ?? '';
      final lower = row.toLowerCase();
      if (!lower.contains('status') && !lower.contains('confirmed') && !lower.contains('shipped') && !lower.contains('delivered') && !lower.contains('processing')) continue;
      final statusRaw = RegExp(r'(?:badge|status)[^>]*>\s*([A-Za-z][A-Za-z ]+?)\s*<').firstMatch(row)?.group(1)?.toLowerCase() ?? '';
      if (statusRaw.isEmpty) continue;
      final status = OrderStatus.fromString(statusRaw);
      final date = RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}[^<]{0,10})').firstMatch(row)?.group(1)
          ?? RegExp(r'(\d{4}-\d{2}-\d{2}[^<]{0,10})').firstMatch(row)?.group(1) ?? '';
      final notes = RegExp(r'<(?:small|p)[^>]*>\s*([^<]{3,200}?)\s*<').firstMatch(row)?.group(1)?.stripHtmlTags();
      events.add(OrderStatusEvent(id: eventId++, saleId: saleId, newStatus: status, notes: notes?.isNotEmpty == true ? notes : null, createdAt: date));
    }
    return events;
  }

  List<WishlistItem> _parseWishlist(String html) {
    final items = <WishlistItem>[];
    final seen = <int>{};

    for (final m in RegExp(r'<div\s+class="m-feature-card[^"]*"[^>]*>([\s\S]{0,2000}?)mpToggleWishlist\((\d+)', dotAll: true).allMatches(html)) {
      final productId = int.tryParse(m.group(2) ?? '') ?? 0;
      if (productId <= 0 || seen.contains(productId)) continue;
      seen.add(productId);
      final card = m.group(1) ?? '';
      final imgSrc = RegExp(r'<img[^>]+src="([^"]+)"').firstMatch(card)?.group(1);
      final name = (RegExp(r'<img[^>]+alt="([^"]{2,120})"').firstMatch(card)?.group(1)
          ?? RegExp(r'fw-bold[^>]*>\s*([^<]{2,120}?)\s*<').firstMatch(card)?.group(1)
          ?? 'Product $productId').stripHtmlTags().decodeHtmlEntities().trim();
      final priceStr = RegExp(r'PKR\s*([\d,\.]+)').firstMatch(card)?.group(1) ?? '0';
      final price = double.tryParse(priceStr.replaceAll(',', '')) ?? 0;
      final absoluteImg = imgSrc != null ? (imgSrc.startsWith('http') ? imgSrc : 'https://beta.softstore.pk${imgSrc.startsWith('/') ? imgSrc : '/$imgSrc'}') : null;
      items.add(WishlistItem(id: productId, productId: productId, productName: name, sellingPrice: price, imageUrl: absoluteImg));
    }

    if (items.isEmpty) {
      for (final m in RegExp(r'href="/product/(\d+)"').allMatches(html)) {
        final pid = int.tryParse(m.group(1) ?? '') ?? 0;
        if (pid <= 0 || seen.contains(pid)) continue;
        seen.add(pid);
        items.add(WishlistItem(id: pid, productId: pid, productName: 'Product $pid', sellingPrice: 0));
      }
    }
    return items;
  }

  List<ReturnRequest> _parseReturns(String html) {
    final requests = <ReturnRequest>[];
    final seen = <int>{};
    for (final m in RegExp(r'href="/marketplace/account/returns/(\d+)"([\s\S]{0,600}?)(?=href="/marketplace/account|</table|$)', dotAll: true).allMatches(html)) {
      final id = int.tryParse(m.group(1) ?? '') ?? 0;
      if (id <= 0 || seen.contains(id)) continue;
      seen.add(id);
      final card = m.group(2) ?? '';
      final status = RegExp(r'badge[^>]*>\s*([A-Za-z _]+?)\s*</(?:span|div)').firstMatch(card)?.group(1) ?? 'pending';
      final reason = RegExp(r'[Rr]eason[^>]*>\s*([^<]{3,200})').firstMatch(card)?.group(1)?.stripHtmlTags();
      final createdAt = RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})').firstMatch(card)?.group(1);
      requests.add(ReturnRequest(id: id, status: status, reason: reason, createdAt: createdAt));
    }
    return requests;
  }

  ReturnEligibility _makeReturnEligibility(OrderStatus status, List<OrderStatusEvent> history) {
    if (status != OrderStatus.delivered) {
      return const ReturnEligibility(eligible: false, reason: 'Returns are only available once an order has been delivered.');
    }
    final deliveredEvent = history.lastWhere((e) => e.newStatus == OrderStatus.delivered, orElse: () => const OrderStatusEvent(id: 0, saleId: 0, newStatus: OrderStatus.delivered, createdAt: ''));
    if (deliveredEvent.createdAt.isNotEmpty) {
      final date = _parseDate(deliveredEvent.createdAt);
      if (date != null) {
        final daysSince = DateTime.now().difference(date).inDays;
        if (daysSince > 7) {
          return const ReturnEligibility(eligible: false, reason: 'The 7-day return window for this order has passed.');
        }
      }
    }
    return const ReturnEligibility(eligible: true);
  }

  DateTime? _parseDate(String raw) {
    final trimmed = raw.trim();
    final formats = ['dd/MM/yyyy', 'MM/dd/yyyy', 'yyyy-MM-dd'];
    for (final fmt in formats) {
      try {
        return _parseWithFormat(trimmed, fmt);
      } catch (_) {}
    }
    return null;
  }

  DateTime? _parseWithFormat(String s, String fmt) {
    final m = RegExp(r'(\d+)[/-](\d+)[/-](\d+)').firstMatch(s);
    if (m == null) return null;
    final a = int.tryParse(m.group(1)!) ?? 0;
    final b = int.tryParse(m.group(2)!) ?? 0;
    final c = int.tryParse(m.group(3)!) ?? 0;
    if (fmt == 'yyyy-MM-dd') return DateTime(a, b, c);
    if (fmt == 'dd/MM/yyyy') return DateTime(c, b, a);
    if (fmt == 'MM/dd/yyyy') return DateTime(c, a, b);
    return null;
  }

  String? _scrapeError(String html) {
    return RegExp(r'alert[^>]*danger[^>]*>.*?<span>([^<]{5,200})</span>', dotAll: true).firstMatch(html)?.group(1)
        ?? RegExp(r'alert-danger[^>]*>\s*([^<]{5,200}?)\s*<').firstMatch(html)?.group(1);
  }
}

extension _StrExt on String {
  String stripHtmlTags() => replaceAll(RegExp(r'<[^>]+>'), '');
  String decodeHtmlEntities() => replaceAll('&amp;', '&').replaceAll('&lt;', '<').replaceAll('&gt;', '>').replaceAll('&quot;', '"').replaceAll('&#39;', "'").replaceAll('&nbsp;', ' ');
}
