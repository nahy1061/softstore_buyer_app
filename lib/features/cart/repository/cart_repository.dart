import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
///  - Email OTP verification (checkout)
///  - Order placement
class CartRepository {
  CartRepository._();
  static final CartRepository instance = CartRepository._();

  final DioClient _client = DioClient();
  final CsrfService _csrf = CsrfService.instance;
  static final Set<String> _verifiedEmailsCache = {};

  /// Checks whether [email] has already been verified once on this device/account.
  Future<bool> isEmailVerified(String email) async {
    final sanitized = email.trim().toLowerCase();
    if (sanitized.isEmpty) return false;
    if (_verifiedEmailsCache.contains(sanitized)) return true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList('verified_emails') ?? [];
      if (list.contains(sanitized)) {
        _verifiedEmailsCache.add(sanitized);
        return true;
      }
    } catch (_) {}

    return false;
  }

  /// Marks [email] as permanently verified so repeat OTP prompts are skipped on future orders.
  Future<void> markEmailVerified(String email) async {
    final sanitized = email.trim().toLowerCase();
    if (sanitized.isEmpty) return;
    _verifiedEmailsCache.add(sanitized);

    try {
      final prefs = await SharedPreferences.getInstance();
      final list = (prefs.getStringList('verified_emails') ?? []).toSet();
      list.add(sanitized);
      await prefs.setStringList('verified_emails', list.toList());
      developer.log('[CartRepository] Email $sanitized permanently marked as verified', name: 'cart');
    } catch (_) {}
  }

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
    await HiveService.ensureBoxOpen();
    return HiveService.getItems();
  }

  Future<void> saveCart(List<CartItem> items) async {
    await HiveService.ensureBoxOpen();
    await HiveService.saveItems(items);
  }

  Future<void> clearCart() async {
    await HiveService.ensureBoxOpen();
    await HiveService.clearItems();
  }

  // ─── Cart-Server Sync ──────────────────────────────────────────────────────

  /// Syncs the local Hive cart to the server session for logged-in users.
  ///
  /// The backend manages cart via session cookies. This method sends each
  /// local cart item to the store's add-to-cart endpoint so the server-side
  /// session cart reflects the local state. Failures are non-fatal.
  Future<void> syncCartToServer(List<CartItem> items) async {
    if (items.isEmpty) return;

    try {
      final csrfToken = await _csrf
          .fetchToken(ApiEndpoints.storeHome)
          .timeout(const Duration(seconds: 3), onTimeout: () => null);

      for (final item in items) {
        try {
          await _client.post<dynamic>(
            ApiEndpoints.storeHome,
            data: {
              'product_id': item.productId,
              'quantity': item.quantity,
              if (item.variantId != null) 'variant_id': item.variantId,
              if (csrfToken != null) '_csrf_token': csrfToken,
            },
            options: Options(
              contentType: 'application/x-www-form-urlencoded',
              sendTimeout: const Duration(seconds: 3),
              receiveTimeout: const Duration(seconds: 3),
            ),
          );
        } catch (_) {
          // Individual item sync failure is non-fatal
        }
      }
    } catch (e) {
      developer.log('[Cart] Server sync notice: $e', name: 'cart');
    }
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

  // ─── Email OTP Verification (Checkout) ─────────────────────────────────────

  /// Sends a 6-digit OTP to the registered [email] for checkout verification via the mail server.
  Future<void> sendVerificationOtp(
    String email, {
    String? name,
    String? phone,
  }) async {
    final targetEmail = email.trim();
    if (targetEmail.isEmpty) {
      throw const AuthFailure(
          'Email address is required to receive verification code.');
    }

    developer.log(
        '[OTP] sendVerificationOtp dispatching email to $targetEmail',
        name: 'otp');

    try {
      final csrfToken = await _csrf
          .fetchToken(ApiEndpoints.checkoutPage)
          .timeout(const Duration(seconds: 3), onTimeout: () => null);

      final response = await _client.post<dynamic>(
        ApiEndpoints.sendCheckoutOtp,
        data: {
          'email': targetEmail,
          if (name != null && name.isNotEmpty) 'name': name.trim(),
          if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
        },
        options: Options(
          contentType: 'application/json',
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {
            if (csrfToken != null) 'X-CSRF-TOKEN': csrfToken,
            'Accept': 'application/json',
          },
        ),
      );

      final data = _parseJsonMap(response.data);
      developer.log(
          '[OTP] Server response ${response.statusCode}: ${response.data}',
          name: 'otp');

      final success = data?['success'] == true ||
          data?['sent'] == true ||
          (response.statusCode == 200 && data?['error'] == null);

      if (!success) {
        final err = data?['message']?.toString() ??
            data?['error']?.toString() ??
            'Failed to send verification code to email.';
        throw ServerFailure(err, statusCode: response.statusCode);
      }
    } on ServerFailure {
      rethrow;
    } on AuthFailure {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.data != null) {
        final respData = _parseJsonMap(e.response?.data);
        final err =
            respData?['error']?.toString() ?? respData?['message']?.toString();
        if (err != null && err.isNotEmpty) {
          throw ServerFailure(err, statusCode: e.response?.statusCode);
        }
      }
      if (e.response?.statusCode == 419) {
        final freshCsrf =
            await _csrf.refreshToken(ApiEndpoints.checkoutPage);
        if (freshCsrf != null) {
          final retryResponse = await _client.post<dynamic>(
            ApiEndpoints.sendCheckoutOtp,
            data: {
              'email': targetEmail,
              if (name != null && name.isNotEmpty) 'name': name.trim(),
              if (phone != null && phone.isNotEmpty) 'phone': phone.trim(),
            },
            options: Options(
              contentType: 'application/json',
              sendTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
              headers: {
                'X-CSRF-TOKEN': freshCsrf,
                'Accept': 'application/json',
              },
            ),
          );
          final retryData = _parseJsonMap(retryResponse.data);
          final retrySuccess = retryData?['success'] == true ||
              retryData?['sent'] == true ||
              (retryResponse.statusCode == 200 && retryData?['error'] == null);
          if (!retrySuccess) {
            final err = retryData?['message']?.toString() ??
                retryData?['error']?.toString() ??
                'Failed to send verification code';
            throw ServerFailure(err, statusCode: retryResponse.statusCode);
          }
          return;
        }
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkFailure('No internet connection.');
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const TimeoutFailure('Request timed out. Please try again.');
      }
      throw ServerFailure(
        e.message ?? 'Failed to send verification email',
        statusCode: e.response?.statusCode,
      );
    }
  }

  /// Verifies the 6-digit OTP code received on email for checkout verification.
  Future<void> verifyCheckoutOtp(String code) async {
    final trimmed = code.trim();
    if (trimmed.isEmpty) {
      throw const AuthFailure('Please enter the 6-digit code received on your email.');
    }

    try {
      final csrfToken = await _csrf
          .fetchToken(ApiEndpoints.checkoutPage)
          .timeout(const Duration(seconds: 3), onTimeout: () => null);

      final response = await _client.post<dynamic>(
        ApiEndpoints.verifyCheckoutOtp,
        data: {'code': trimmed},
        options: Options(
          contentType: 'application/json',
          sendTimeout: const Duration(seconds: 5),
          receiveTimeout: const Duration(seconds: 5),
          headers: {
            if (csrfToken != null) 'X-CSRF-TOKEN': csrfToken,
            'Accept': 'application/json',
          },
        ),
      );

      final data = _parseJsonMap(response.data);
      final success = data?['success'] == true ||
          data?['verified'] == true ||
          (response.statusCode == 200 && data?['error'] == null);

      if (!success) {
        final msg = data?['message']?.toString() ??
            data?['error']?.toString() ??
            'Invalid or expired verification code.';
        throw AuthFailure(msg);
      }
    } on AuthFailure {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.data != null) {
        final respData = _parseJsonMap(e.response?.data);
        final err =
            respData?['error']?.toString() ?? respData?['message']?.toString();
        if (err != null && err.isNotEmpty) {
          throw AuthFailure(err);
        }
      }
      if (e.response?.statusCode == 419) {
        final freshCsrf =
            await _csrf.refreshToken(ApiEndpoints.checkoutPage);
        if (freshCsrf != null) {
          final retryResponse = await _client.post<dynamic>(
            ApiEndpoints.verifyCheckoutOtp,
            data: {'code': trimmed},
            options: Options(
              contentType: 'application/json',
              sendTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
              headers: {
                'X-CSRF-TOKEN': freshCsrf,
                'Accept': 'application/json',
              },
            ),
          );
          final retryData = _parseJsonMap(retryResponse.data);
          final retrySuccess = retryData?['success'] == true ||
              retryData?['verified'] == true ||
              (retryResponse.statusCode == 200 && retryData?['error'] == null);
          if (!retrySuccess) {
            throw const AuthFailure('Invalid or expired verification code.');
          }
          return;
        }
      }
      if (e.type == DioExceptionType.connectionError) {
        throw const NetworkFailure('No internet connection.');
      }
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        throw const TimeoutFailure('Request timed out. Please try again.');
      }
      throw AuthFailure(
        e.message ?? 'Verification failed',
      );
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
              headers: {
                if (token.isNotEmpty) 'X-CSRF-TOKEN': token,
                'Accept': 'application/json',
              },
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
            options: Options(
              contentType: 'application/json',
              headers: {
                'X-CSRF-TOKEN': freshCsrf,
                'Accept': 'application/json',
              },
            ),
          );
          final placed = _handleOrderResponse(_parseJsonMap(retryResponse.data), retryResponse.data);
          if (placed.success && request.customerEmail.isNotEmpty) {
            markEmailVerified(request.customerEmail);
          }
          return placed;
        }
      }

      final placed = _handleOrderResponse(data, response.data);
      if (placed.success && request.customerEmail.isNotEmpty) {
        markEmailVerified(request.customerEmail);
      }
      return placed;
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
