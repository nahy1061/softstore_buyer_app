import '../core/networking/web_session_client.dart';
import '../core/networking/api_error.dart';
import '../core/models/cart_item.dart';

class ShippingQuote {
  final double fee;
  final bool isFree;
  final String? note;

  const ShippingQuote({required this.fee, required this.isFree, this.note});
}

class CheckoutRequest {
  final String customerName;
  final String customerEmail;
  final String customerPhone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String? notes;
  final List<CartItem> items;

  const CheckoutRequest({
    required this.customerName,
    required this.customerEmail,
    required this.customerPhone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    this.notes,
    required this.items,
  });
}

class CheckoutService {
  final _web = WebSessionClient.shared;

  /// Calls /api/store/shipping-quote to get a delivery fee estimate.
  Future<ShippingQuote> shippingQuote({
    required String city,
    required List<CartItem> items,
  }) async {
    try {
      final cartItems = items
          .map((i) => {
                'product_id': i.productId,
                'quantity': i.quantity,
                if (i.variantId != null) 'variant_id': i.variantId,
              })
          .toList();

      final csrf = await _web.fetchCsrf('/store');
      return await _web.postJson<ShippingQuote>(
        '/api/store/shipping-quote',
        {'city': city, 'cart_items': cartItems},
        (json) {
          final fee = _loose(json['fee'] ?? json['shipping_fee'] ?? json['amount'] ?? 0);
          final isFree = json['is_free'] == true || fee == 0;
          final note = json['note'] as String? ?? json['message'] as String?;
          return ShippingQuote(fee: fee, isFree: isFree, note: note);
        },
        csrfToken: csrf,
      );
    } catch (_) {
      // Silently fall back to a default estimate if the endpoint fails.
      return const ShippingQuote(fee: 200.0, isFree: false);
    }
  }

  /// Submits the checkout form and returns the invoice number.
  ///
  /// The server expects either HTML form or JSON; we send JSON.
  Future<String> checkout(CheckoutRequest req) async {
    // Fetch a fresh CSRF token from the checkout page.
    final html = await _web.fetchHtml('/store/checkout');
    final csrf = _web.scrapeCSRF(html) ?? '';

    final itemsPayload = req.items
        .map((i) => {
              'product_id': i.productId,
              'quantity': i.quantity,
              if (i.variantId != null) 'variant_id': i.variantId,
            })
        .toList();

    final body = <String, dynamic>{
      'customer_name': req.customerName,
      'customer_email': req.customerEmail,
      'customer_phone': req.customerPhone,
      'address_line1': req.addressLine1,
      if (req.addressLine2 != null && req.addressLine2!.isNotEmpty) 'address_line2': req.addressLine2,
      'city': req.city,
      'notes': req.notes ?? '',
      'payment_method': 'cod',
      'items': itemsPayload,
      '_csrf_token': csrf,
      'csrf_token': csrf,
    };

    return await _web.postJson<String>(
      '/store/checkout',
      body,
      (json) {
        // Server returns {success, invoice, invoice_number, order_id, ...}
        final success = json['success'] == true || json['status'] == 'success';
        if (!success) {
          final msg = json['message'] as String? ?? json['error'] as String? ?? 'Checkout failed.';
          throw ApiError(msg);
        }
        final invoice = json['invoice'] as String?
            ?? json['invoice_number'] as String?
            ?? json['order_number'] as String?
            ?? '${json['order_id'] ?? json['id'] ?? ''}';
        if (invoice.isEmpty) throw ApiError('Order placed but invoice number missing.');
        return invoice;
      },
      csrfToken: csrf,
    );
  }
}

double _loose(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}
