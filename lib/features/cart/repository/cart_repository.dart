import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/hive_service.dart';
import '../../../core/utils/csrf_service.dart';
import '../../../core/utils/html_parser_util.dart';
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
      // Step 1: Verify session is alive by fetching CSRF from checkout page
      String? csrfToken;
      try {
        final checkoutResponse = await _client.get<String>(
          ApiEndpoints.checkoutPage,
          options: Options(
            responseType: ResponseType.plain,
            validateStatus: (s) => s != null && s < 500,
            followRedirects: true,
            maxRedirects: 3,
          ),
        );
        final html = checkoutResponse.data ?? '';

        // If we got redirected to login or the page contains a login form,
        // the session is expired — throw immediately
        if (html.contains('action="/login"') && html.contains('name="password"')) {
          developer.log('[Cart] Session expired — checkout page shows login form', name: 'cart');
          throw const AuthFailure('Session expired. Please login again.');
        }

        csrfToken = HtmlParserUtil.extractCsrfToken(html);
      } catch (e) {
        if (e is AuthFailure) rethrow;
        developer.log('[Cart] CSRF fetch error: $e', name: 'cart');
      }

      final token = csrfToken ?? '';

      if (token.isEmpty) {
        developer.log('[Cart] WARNING: CSRF token is empty — order will likely fail with 419', name: 'cart');
      }

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

      developer.log('[Cart] Placing order — items: ${request.items.length}, email: ${request.customerEmail}', name: 'cart');

      final response = await _client
          .post<dynamic>(
            ApiEndpoints.placeOrder,
            data: payload,
            options: Options(
              contentType: 'application/json',
              sendTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ),
          )
          .timeout(const Duration(seconds: 20));

      // Handle 419 CSRF expired — refresh token and retry once
      if (response.statusCode == 419) {
        developer.log('[Cart] 419 — refreshing CSRF and retrying', name: 'cart');
        final freshCsrf =
            await _csrf.refreshToken(ApiEndpoints.checkoutPage);
        if (freshCsrf != null && freshCsrf.isNotEmpty) {
          payload['_csrf_token'] = freshCsrf;
          payload['csrf_token'] = freshCsrf;
          final retryResponse = await _client.post<dynamic>(
            ApiEndpoints.placeOrder,
            data: payload,
            options: Options(
              contentType: 'application/json',
              sendTimeout: const Duration(seconds: 15),
              receiveTimeout: const Duration(seconds: 15),
            ),
          ).timeout(const Duration(seconds: 20));
          return _handleOrderResponse(_parseJsonMap(retryResponse.data), retryResponse.data);
        }
      }

      return _handleOrderResponse(_parseJsonMap(response.data), response.data);
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
        // Try to extract invoice from raw HTML/JSON response
        final regex = RegExp(r'INV[- ]?[0-9\-]+', caseSensitive: false);
        final match = regex.firstMatch(rawStr);
        if (match != null) {
          return PlacedOrderResult(
            success: true,
            invoiceNumber: match.group(0),
          );
        }
      }
      throw const ServerFailure('No response from server. Please try again.');
    }

    // Check for email verification errors first
    final msg = (data['message'] ?? data['error'] ?? '').toString();
    final lowerMsg = msg.toLowerCase();
    if (lowerMsg.contains('email_unverified') ||
        lowerMsg.contains('verify your email') ||
        lowerMsg.contains('unverified') ||
        lowerMsg.contains('email verification')) {
      throw const AuthFailure('email_unverified');
    }

    final result = PlacedOrderResult.fromJson(data);

    // If server returned success but no invoice, try to extract from response
    if (result.success && (result.invoiceNumber == null || result.invoiceNumber!.isEmpty)) {
      final rawStr = rawData?.toString() ?? '';
      final regex = RegExp(r'INV[- ]?[0-9\-]+', caseSensitive: false);
      final match = regex.firstMatch(rawStr);
      if (match != null) {
        return PlacedOrderResult(
          success: true,
          invoiceNumber: match.group(0),
          invoices: result.invoices,
          discountAmount: result.discountAmount,
        );
      }
    }

    // If not successful, throw error with server message
    if (!result.success) {
      throw ServerFailure(
        result.message?.isNotEmpty == true ? result.message! : 'Order failed. Please try again.',
      );
    }

    if (result.invoiceNumber == null || result.invoiceNumber!.isEmpty) {
      throw const ServerFailure('Order placed but no invoice number received. Please check your orders.');
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
