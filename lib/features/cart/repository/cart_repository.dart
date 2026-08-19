import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/utils/csrf_service.dart';
import '../models/cart_models.dart';

/// Manages the local cart and handles cart-related server calls.
///
/// Cart data is stored entirely client-side in Hive.
/// Server-side calls are made for:
///  - Shipping quote calculation
///  - Coupon code validation
///  - Order placement
class CartRepository {
  CartRepository._();
  static final CartRepository instance = CartRepository._();

  final DioClient _client = DioClient();
  final CsrfService _csrf = CsrfService.instance;

  Map<String, dynamic>? _parseJsonMap(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String && data.trim().isNotEmpty) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map<String, dynamic>) return decoded;
        if (decoded is Map) return Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    return null;
  }

  // ─── Local Cart (Hive) ────────────────────────────────────────────────

  Future<List<CartItem>> getCart() async {
    return HiveService.getItems();
  }

  Future<void> saveCart(List<CartItem> items) async {
    await HiveService.saveItems(items);
  }

  Future<void> clearCart() async {
    await HiveService.clearItems();
  }

  // ─── Shipping Quote ───────────────────────────────────────────────────────

  Future<ShippingQuote> getShippingQuote(List<CartItem> items) async {
    try {
      final payload = {
        'items': items
            .map((i) => {'id': i.productId, 'qty': i.quantity})
            .toList(),
      };

      final response = await _client.post<dynamic>(
        ApiEndpoints.shippingQuote,
        data: payload,
        options: Options(contentType: 'application/json'),
      );

      final data = _parseJsonMap(response.data);
      if (data == null) {
        return const ShippingQuote(deliveryFee: 300.0);
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
      final response = await _client.post<dynamic>(
        ApiEndpoints.validateCoupon,
        data: {'code': code.trim(), 'subtotal': subtotal},
        options: Options(contentType: 'application/json'),
      );
      final data = _parseJsonMap(response.data);
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

  Future<PlacedOrderResult> placeOrder(OrderRequest request) async {
    try {
      // Step 1: Fetch CSRF from checkout page with 3-second timeout
      final csrfToken = await _csrf
          .fetchToken(ApiEndpoints.checkoutPage)
          .timeout(const Duration(seconds: 3), onTimeout: () => null);

      final token = csrfToken ?? '';

      final payload = {
        '_csrf_token': token,
        'csrf_token': token,
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

      final response = await _client
          .post<dynamic>(
            ApiEndpoints.placeOrder,
            data: payload,
            options: Options(
              contentType: 'application/json',
              sendTimeout: const Duration(seconds: 4),
              receiveTimeout: const Duration(seconds: 4),
            ),
          )
          .timeout(const Duration(seconds: 5));

      final data = _parseJsonMap(response.data);

      if (response.statusCode == 419) {
        developer.log('[Cart] 419 — refreshing CSRF and retrying', name: 'cart');
        final freshCsrf =
            await _csrf.refreshToken(ApiEndpoints.checkoutPage);
        if (freshCsrf != null) {
          payload['_csrf_token'] = freshCsrf;
          payload['csrf_token'] = freshCsrf;
          final retryResponse = await _client.post<dynamic>(
            ApiEndpoints.placeOrder,
            data: payload,
            options: Options(contentType: 'application/json'),
          );
          return _handleOrderResponse(_parseJsonMap(retryResponse.data), retryResponse.data);
        }
      }

      return _handleOrderResponse(data, response.data);
    } on AuthFailure {
      rethrow;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  PlacedOrderResult _handleOrderResponse(Map<String, dynamic>? data, [dynamic rawData]) {
    if (data == null) {
      final rawStr = rawData?.toString() ?? '';
      if (rawStr.isNotEmpty) {
        final lower = rawStr.toLowerCase();
        if (lower.contains('email_unverified') ||
            lower.contains('verify your email') ||
            lower.contains('unverified') ||
            lower.contains('email verification')) {
          throw const AuthFailure('email_unverified');
        }
        if (lower.contains('order') || lower.contains('inv-') || lower.contains('invoice')) {
          final regex = RegExp(r'INV-[0-9\-]+', caseSensitive: false);
          final match = regex.firstMatch(rawStr);
          return PlacedOrderResult(
            success: true,
            invoiceNumber: match != null ? match.group(0) : null,
          );
        }
      }
      throw const ServerFailure('No response from server.');
    }
    final result = PlacedOrderResult.fromJson(data);

    final msg = result.message?.toLowerCase() ?? '';
    if (!result.success &&
        (result.message == 'email_unverified' ||
            msg.contains('verify your email') ||
            msg.contains('unverified') ||
            msg.contains('email verification'))) {
      throw const AuthFailure('email_unverified');
    }

    return result;
  }

  // ─── Error Mapping ────────────────────────────────────────────────────────

  Failure _mapError(DioException e) {
    developer.log('[Cart] DioException: ${e.message}', name: 'cart');
    final respData = e.response?.data;
    if (respData is Map) {
      final msg =
          (respData['message'] ?? respData['error'] ?? '').toString().toLowerCase();
      if (msg == 'email_unverified' ||
          msg.contains('verify your email') ||
          msg.contains('unverified') ||
          msg.contains('email verification')) {
        return const AuthFailure('email_unverified');
      }
    }
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
