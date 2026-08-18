import 'dart:convert';
import 'package:dio/dio.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/softstore_api_client.dart';
import '../models/cart_item.dart';

/// Typed error for email_unverified response from the checkout endpoint.
class EmailUnverifiedException implements Exception {
  final String code;
  EmailUnverifiedException() : code = 'email_unverified';

  @override
  String toString() =>
      'Email not verified. Please verify your email to continue.';
}

/// Result of a successful order placement.
class OrderResult {
  final String invoiceNumber;
  final Map<String, dynamic> raw;

  const OrderResult({required this.invoiceNumber, required this.raw});

  factory OrderResult.fromJson(Map<String, dynamic> json) {
    return OrderResult(
      invoiceNumber: json['invoice_number'] as String? ??
          json['order_id'] as String? ??
          json['master_ref'] as String? ??
          '',
      raw: json,
    );
  }
}

/// Result of a shipping quote.
class ShippingQuote {
  final int deliveryFee;
  final double totalWeightKg;
  final bool free;
  final String currency;

  const ShippingQuote({
    required this.deliveryFee,
    required this.totalWeightKg,
    required this.free,
    required this.currency,
  });

  factory ShippingQuote.fromJson(Map<String, dynamic> json) {
    return ShippingQuote(
      deliveryFee: (json['delivery_fee'] as num?)?.toInt() ?? 0,
      totalWeightKg: (json['total_weight_kg'] as num?)?.toDouble() ?? 0.0,
      free: json['free'] as bool? ?? false,
      currency: json['currency'] as String? ?? 'PKR',
    );
  }
}

/// Result of coupon validation.
class CouponResult {
  final bool valid;
  final int discountAmount;
  final String message;
  final String? code;
  final bool freeShipping;

  const CouponResult({
    required this.valid,
    required this.discountAmount,
    required this.message,
    this.code,
    this.freeShipping = false,
  });

  factory CouponResult.fromJson(Map<String, dynamic> json) {
    final coupon = json['coupon'] as Map<String, dynamic>?;
    return CouponResult(
      valid: json['success'] as bool? ?? json['valid'] as bool? ?? false,
      discountAmount: (coupon?['discount_amount'] as num?)?.toInt() ??
          (json['discount_amount'] as num?)?.toInt() ??
          0,
      message: json['message'] as String? ?? '',
      code: coupon?['code'] as String?,
      freeShipping: coupon?['free_shipping'] as bool? ?? false,
    );
  }
}

/// Handles all checkout-related API calls to the SoftStore PHP backend.
///
/// All endpoints accept and return JSON (not form-encoded). The backend JS
/// uses `fetch()` with `Content-Type: application/json` and passes the CSRF
/// token via the `X-CSRF-TOKEN` header.
class CheckoutService {
  final SoftstoreApiClient _api = SoftstoreApiClient();

  /// Fetches a shipping quote from the server.
  /// POST /api/store/shipping-quote (JSON, no CSRF)
  Future<ShippingQuote> getShippingQuote(
    List<CartItem> items, {
    String? city,
  }) async {
    final body = {
      'items': items
          .map((item) => {
                'id': item.productId,
                'qty': item.quantity,
              })
          .toList(),
      if (city != null && city.isNotEmpty) 'city': city,
    };
    final response =
        await _api.postJson(ApiEndpoints.shippingQuote, data: body);
    return ShippingQuote.fromJson(response.data as Map<String, dynamic>);
  }

  /// Validates a coupon code against the server.
  /// POST /api/store/validate-coupon (JSON, no CSRF)
  Future<CouponResult> validateCoupon(
    String code,
    int subtotal,
    List<CartItem> items,
  ) async {
    final body = {
      'code': code,
      'items': items
          .map((item) => {
                'id': item.productId,
                'qty': item.quantity,
                if (item.variantId != null) 'variant_id': item.variantId,
              })
          .toList(),
    };
    final response =
        await _api.postJson(ApiEndpoints.validateCoupon, data: body);
    return CouponResult.fromJson(response.data as Map<String, dynamic>);
  }

  /// Sends a verification code to the given email address.
  /// POST /store/checkout/send-code (JSON, no CSRF)
  Future<void> sendVerificationCode(
    String email, {
    String? name,
    String? phone,
  }) async {
    await _api.postJson(
      ApiEndpoints.sendVerificationCode,
      data: {
        'email': email,
        if (name != null && name.isNotEmpty) 'name': name,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );
  }

  /// Verifies the code sent to the email.
  /// POST /store/checkout/verify-code (JSON, no CSRF)
  Future<void> verifyCode(String code) async {
    final response = await _api.postJson(
      ApiEndpoints.verifyCode,
      data: {'code': code},
    );
    final data = response.data;
    // Response may be a Map or may need parsing.
    final Map<String, dynamic> json;
    if (data is Map<String, dynamic>) {
      json = data;
    } else if (data is String) {
      json = jsonDecode(data) as Map<String, dynamic>;
    } else {
      throw Exception('Unexpected response format from verify-code');
    }
    if (json['success'] != true) {
      throw Exception(json['message'] as String? ?? 'Invalid verification code');
    }
  }

  /// Places an order via the session-cookie PHP checkout form.
  ///
  /// Uses CSRF-protected POST to /store/checkout with JSON body encoded as
  /// `text/plain` (to avoid CORS preflight).  The CSRF token is sent in the
  /// body fields `_csrf_token` and `csrf_token`, not as a header.
  ///
  /// Throws [EmailUnverifiedException] if the server responds with
  /// `{ success: false, message: "email_unverified" }`.
  Future<OrderResult> placeOrder({
    required List<CartItem> items,
    required String customerName,
    required String customerAddress,
    required String customerPhone,
    required String customerEmail,
    String? customerCity,
    String? notes,
    String? couponCode,
  }) async {
    try {
      final response = await _api.csrfProtectedRequest(
        pageUrl: ApiEndpoints.checkoutPage,
        endpoint: ApiEndpoints.placeOrder,
        buildBody: (csrfToken) {
          final body = <String, dynamic>{
            '_csrf_token': csrfToken,
            'csrf_token': csrfToken,
            'customer_name': customerName,
            'customer_phone': customerPhone,
            'customer_address': customerAddress,
            'customer_email': customerEmail,
            'customer_city': customerCity ?? '',
            'payment_method': 'cod',
            'notes': notes ?? '',
            'coupon_code': couponCode ?? '',
            'items': items
                .map((item) => {
                      'id': item.productId,
                      'qty': item.quantity,
                      if (item.variantId != null)
                        'variant_id': item.variantId,
                    })
                .toList(),
          };
          return body;
        },
      );

      // The backend may return JSON or HTML. Try to parse as JSON first.
      final data = _parseResponseData(response.data);

      // Handle email_unverified interrupt
      if (data['success'] == false &&
          data['message'] == 'email_unverified') {
        throw EmailUnverifiedException();
      }

      return OrderResult.fromJson(data);
    } on DioException catch (e) {
      final raw = e.response?.data;
      if (raw != null) {
        final data = _parseResponseData(raw);
        if (data['success'] == false &&
            data['message'] == 'email_unverified') {
          throw EmailUnverifiedException();
        }
      }
      rethrow;
    }
  }

  /// Safely parse response data — may be a Map, a JSON string, or HTML.
  Map<String, dynamic> _parseResponseData(dynamic rawData) {
    if (rawData is Map<String, dynamic>) return rawData;
    if (rawData is String) {
      try {
        final parsed = jsonDecode(rawData);
        if (parsed is Map<String, dynamic>) return parsed;
      } catch (_) {
        // Not JSON — might be an HTML error page. Try to extract JSON
        // from a <script> or just return an error map.
      }
      // Look for embedded JSON in HTML response.
      final jsonMatch =
          RegExp(r'\{[^{}]*"success"[^{}]*\}').firstMatch(rawData);
      if (jsonMatch != null) {
        try {
          final parsed = jsonDecode(jsonMatch.group(0)!);
          if (parsed is Map<String, dynamic>) return parsed;
        } catch (_) {}
      }
      throw Exception(
        'Server returned an unexpected response. Please try again.',
      );
    }
    return <String, dynamic>{};
  }
}
