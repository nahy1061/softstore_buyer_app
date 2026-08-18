import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/csrf_service.dart';
import '../models/cart_models.dart';

/// Manages the local cart and handles cart-related server calls.
///
/// Cart data is stored entirely client-side in SharedPreferences.
/// Server-side calls are made for:
///  - Shipping quote calculation
///  - Coupon code validation
///  - Order placement
class CartRepository {
  CartRepository._();
  static final CartRepository instance = CartRepository._();

  final DioClient _client = DioClient();
  final CsrfService _csrf = CsrfService.instance;

  // ─── Local Cart (SharedPreferences) ──────────────────────────────────────

  Future<List<CartItem>> getCart() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(StorageKeys.cartItems) ?? [];
    return raw
        .map((s) => CartItem.fromJson(jsonDecode(s) as Map<String, dynamic>))
        .toList();
  }

  Future<void> saveCart(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      StorageKeys.cartItems,
      items.map((i) => jsonEncode(i.toJson())).toList(),
    );
  }

  Future<void> clearCart() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.cartItems);
  }

  // ─── Shipping Quote ───────────────────────────────────────────────────────

  /// Calculates the delivery fee for a set of cart items.
  ///
  /// Always call this before displaying the cart total and before checkout.
  Future<ShippingQuote> getShippingQuote(List<CartItem> items) async {
    try {
      final payload = {
        'items': items
            .map((i) => {'id': i.productId, 'qty': i.quantity})
            .toList(),
      };

      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.shippingQuote,
        data: payload,
        options: Options(contentType: 'application/json'),
      );

      final data = response.data;
      if (data == null) {
        throw const ServerFailure('Invalid shipping quote response.');
      }
      return ShippingQuote.fromJson(data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ─── Coupon Validation ────────────────────────────────────────────────────

  Future<CouponResult> validateCoupon({
    required String code,
    required double subtotal,
  }) async {
    try {
      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.validateCoupon,
        data: {'code': code.trim(), 'subtotal': subtotal},
        options: Options(contentType: 'application/json'),
      );
      final data = response.data;
      if (data == null) {
        return const CouponResult(
            valid: false, discountAmount: 0, message: 'Invalid coupon.');
      }
      return CouponResult.fromJson(data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ─── Place Order ──────────────────────────────────────────────────────────

  /// Places a COD order.
  ///
  /// Flow:
  ///  1. GET /store/checkout → extract CSRF token(s)
  ///  2. POST /store/checkout with JSON body containing both token fields
  ///  3. If server returns email_unverified → caller must trigger OTP flow
  ///
  /// Throws [AuthFailure] with message `'email_unverified'` when email is not
  /// yet verified in the session — the caller should then call
  /// [AuthRepository.sendVerificationCode] and retry.
  Future<PlacedOrderResult> placeOrder(OrderRequest request) async {
    try {
      // Step 1: Fetch CSRF from checkout page
      final csrfToken =
          await _csrf.fetchToken(ApiEndpoints.checkoutPage);
      if (csrfToken == null) {
        throw const ServerFailure('Unable to load checkout page.');
      }

      // Step 2: Build payload
      final payload = {
        '_csrf_token': csrfToken,
        'csrf_token': csrfToken, // Server requires BOTH fields
        'items': request.items
            .map((i) => {
                  'id': i.productId,
                  'qty': i.quantity,
                  if (i.variantId != null) 'variant_id': i.variantId,
                })
            .toList(),
        'customer_name': request.customerName,
        'customer_address': request.customerAddress,
        'customer_phone': request.customerPhone,
        'customer_email': request.customerEmail,
        if (request.notes != null && request.notes!.isNotEmpty)
          'notes': request.notes,
        'payment_method': 'cod',
        'age_confirmed': true,
        if (request.couponCode != null) 'coupon_code': request.couponCode,
      };

      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.placeOrder,
        data: payload,
        options: Options(contentType: 'application/json'),
      );

      final data = response.data;

      // Handle 419 CSRF expiry — refresh and retry once
      if (response.statusCode == 419) {
        developer.log('[Cart] 419 — refreshing CSRF and retrying', name: 'cart');
        final freshCsrf =
            await _csrf.refreshToken(ApiEndpoints.checkoutPage);
        if (freshCsrf != null) {
          payload['_csrf_token'] = freshCsrf;
          payload['csrf_token'] = freshCsrf;
          final retryResponse = await _client.post<Map<String, dynamic>>(
            ApiEndpoints.placeOrder,
            data: payload,
            options: Options(contentType: 'application/json'),
          );
          return _handleOrderResponse(retryResponse.data);
        }
      }

      return _handleOrderResponse(data);
    } on AuthFailure {
      rethrow;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  PlacedOrderResult _handleOrderResponse(Map<String, dynamic>? data) {
    if (data == null) {
      throw const ServerFailure('No response from server.');
    }
    final result = PlacedOrderResult.fromJson(data);

    // Email not verified — caller must trigger OTP flow
    if (!result.success && result.message == 'email_unverified') {
      throw const AuthFailure('email_unverified');
    }

    return result;
  }

  // ─── Error Mapping ────────────────────────────────────────────────────────

  Failure _mapError(DioException e) {
    developer.log('[Cart] DioException: ${e.message}', name: 'cart');
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkFailure('No internet connection.');
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const TimeoutFailure('Request timed out.');
    }
    return ServerFailure(
      e.message ?? 'Server error',
      statusCode: e.response?.statusCode,
    );
  }
}
