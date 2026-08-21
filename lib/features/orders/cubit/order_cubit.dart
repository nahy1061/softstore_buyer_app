import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/failures.dart';
import '../../../core/services/notification_service.dart';
import '../data/order_service.dart';
import '../models/order_model.dart';
import '../repository/order_repository.dart';
import 'order_state.dart';

class OrderCubit extends Cubit<OrderState> {
  final OrderService _orderService;
  final OrderRepository _repo;

  OrderCubit({OrderService? orderService, OrderRepository? repository})
      : _orderService = orderService ?? OrderService(),
        _repo = repository ?? OrderRepository.instance,
        super(const OrderInitial());

  // ─── Load Orders ──────────────────────────────────────────────────────────

  Future<void> loadOrders() async {
    developer.log('[OrderCubit] loadOrders() called', name: 'orders');

    // 1. Clean stale dummy/fake orders from local storage
    // 2. Show loading state
    emit(const OrderLoading());

    // 3. Capture pending status overrides BEFORE clearing
    final currentLocal = await _repo.getLocalOrders();
    final statusOverrides = <String, OrderStatus>{};
    for (final o in currentLocal) {
      if (o.status == OrderStatus.cancelled ||
          o.status == OrderStatus.refunded) {
        statusOverrides[o.referenceNumber.toLowerCase()] = o.status;
      }
    }

    // 4. Clear ALL local orders
    await _repo.clearAllLocalOrders();

    // 5. Fetch remote orders from server
    try {
      final remoteOrders = await _orderService.fetchOrders();

      developer.log(
        '[OrderCubit] Remote fetch returned ${remoteOrders.length} orders',
        name: 'orders',
      );

      if (remoteOrders.isNotEmpty) {
        // Start with server orders, apply any pending status overrides.
        // Only override if the server order is NOT already in a terminal state
        // (delivered, cancelled, refunded) — server is the source of truth.
        final map = <String, Order>{};
        for (final o in remoteOrders) {
          final key = o.referenceNumber.toLowerCase();
          final overrideStatus = statusOverrides[key];
          if (overrideStatus != null) {
            final isRemoteTerminal = o.status == OrderStatus.delivered ||
                o.status == OrderStatus.cancelled ||
                o.status == OrderStatus.refunded;
            if (!isRemoteTerminal) {
              map[key] = o.copyWith(status: overrideStatus);
            } else {
              map[key] = o;
            }
          } else {
            map[key] = o;
          }
        }

        final merged = map.values.toList()
          ..sort((a, b) => b.placedAt.compareTo(a.placedAt));
        developer.log(
          '[OrderCubit] Emitting ${merged.length} server orders',
          name: 'orders',
        );
        emit(OrderLoaded(orders: merged));
      } else {
        // Server returned empty — user genuinely has no orders
        developer.log(
          '[OrderCubit] Server returned 0 orders — emitting empty list',
          name: 'orders',
        );
        emit(const OrderLoaded(orders: []));
      }
    } on AuthFailure {
      developer.log(
        '[OrderCubit] AuthFailure — session expired',
        name: 'orders',
      );
      emit(const OrderError(message: 'Session expired. Please login again.'));
    } on Failure catch (e) {
      developer.log(
        '[OrderCubit] Failure: ${e.runtimeType} — ${e.message}',
        name: 'orders',
      );
      emit(OrderError(message: e.message));
    } catch (e) {
      developer.log(
        '[OrderCubit] Unexpected error: $e',
        name: 'orders',
      );
      emit(const OrderError(message: 'Failed to load orders. Please try again.'));
    }
  }

  // ─── Search / Filter ──────────────────────────────────────────────────────

  void updateSearchQuery(String query) {
    final current = state;
    if (current is OrderLoaded) {
      emit(current.copyWith(searchQuery: query));
    }
  }

  void updateStatusFilters(List<OrderStatus> statuses) {
    final current = state;
    if (current is OrderLoaded) {
      emit(current.copyWith(statusFilters: statuses));
    }
  }

  void updateSortOption(OrderSortOption sort) {
    final current = state;
    if (current is OrderLoaded) {
      emit(current.copyWith(sortOption: sort));
    }
  }

  void updateDateRange({DateTime? from, DateTime? to, bool clearFrom = false, bool clearTo = false}) {
    final current = state;
    if (current is OrderLoaded) {
      emit(current.copyWith(dateFrom: from, dateTo: to, clearDateFrom: clearFrom, clearDateTo: clearTo));
    }
  }

  void clearFilters() {
    final current = state;
    if (current is OrderLoaded) {
      emit(current.copyWith(
        searchQuery: '',
        statusFilters: [],
        sortOption: OrderSortOption.newestFirst,
        clearDateFrom: true,
        clearDateTo: true,
      ));
    }
  }

  void filterByStatus(String? status) {
    final current = state;
    if (current is OrderLoaded) {
      emit(current.copyWith(
        activeFilter: status,
        clearActiveFilter: status == null,
      ));
    }
  }

  // ─── Order Detail ─────────────────────────────────────────────────────────

  Future<void> loadOrderDetail(String invoiceNumber) async {
    final cleanInvoice = invoiceNumber.trim();

    // Always show loading while we fetch from server
    emit(const OrderLoading());

    // 1. Try server for real data
    try {
      final order = await _repo.getOrderDetail(cleanInvoice);
      NotificationService.instance.tagOrderTracking(
        orderId: order.id,
        referenceNumber: order.referenceNumber,
        status: order.status.name,
      );
      emit(OrderDetailLoaded(order: order));
      NotificationService.instance.tagOrderTracking(
        orderId: order.id,
        referenceNumber: order.referenceNumber,
        status: order.status.name,
      );
      emit(OrderDetailLoaded(order: order));
      return;
    } on AuthFailure {
      emit(const OrderError(message: 'Session expired. Please login again.'));
      return;
    } catch (_) {}

    // 2. Fallback: try OrderService
    try {
      final order = await _orderService.fetchOrderDetail(cleanInvoice);
      NotificationService.instance.tagOrderTracking(
        orderId: order.id,
        referenceNumber: order.referenceNumber,
        status: order.status.name,
      );
      emit(OrderDetailLoaded(order: order));
    } catch (e) {
      emit(OrderError(message: 'Order not found. Please try again.'));
    }
  }

  // ─── Guest Order Tracking ─────────────────────────────────────────────────

  Future<void> lookupOrder({
    required String referenceNumber,
    required String phone,
  }) async {
    developer.log(
      '[OrderCubit] lookupOrder($referenceNumber, $phone)',
      name: 'orders',
    );
    emit(const OrderLoading());
    try {
      final order = await _repo.trackOrderGuest(
        invoiceNumber: referenceNumber.trim(),
        phone: phone.trim(),
      );
      NotificationService.instance.tagOrderTracking(
        orderId: order.id,
        referenceNumber: order.referenceNumber,
        status: order.status.name,
      );
      developer.log(
        '[OrderCubit] Repository returned order: ${order.referenceNumber} | ${order.status.name}',
        name: 'orders',
      );
      emit(OrderLookupResult(order: order));
    } on NotFoundFailure {
      developer.log(
        '[OrderCubit] Not found via repository — trying OrderService fallback',
        name: 'orders',
      );
      try {
        final order = await _orderService.trackGuestOrder(
          referenceNumber: referenceNumber.trim(),
          phone: phone.trim(),
        );
        developer.log(
          '[OrderCubit] Service fallback returned order: ${order.referenceNumber}',
          name: 'orders',
        );
        emit(OrderLookupResult(order: order));
      } catch (e) {
        developer.log(
          '[OrderCubit] Service fallback also failed: $e',
          name: 'orders',
        );
        emit(const OrderLookupNotFound());
      }
    } on Failure catch (e) {
      developer.log(
        '[OrderCubit] Failure: ${e.runtimeType} — ${e.message}',
        name: 'orders',
      );
      try {
        final order = await _orderService.trackGuestOrder(
          referenceNumber: referenceNumber.trim(),
          phone: phone.trim(),
        );
        emit(OrderLookupResult(order: order));
      } catch (_) {
        emit(OrderError(message: e.message));
      }
    } catch (e) {
      developer.log(
        '[OrderCubit] Unexpected error: $e',
        name: 'orders',
      );
      try {
        final order = await _orderService.trackGuestOrder(
          referenceNumber: referenceNumber.trim(),
          phone: phone.trim(),
        );
        emit(OrderLookupResult(order: order));
      } catch (_) {
        emit(const OrderLookupNotFound());
      }
    }
  }

  // ─── Cancel Order ─────────────────────────────────────────────────────────

  Future<void> cancelOrder(String orderId, {String? reason}) async {
    emit(const OrderCancelling());
    bool success = false;

    // 1. Try repository (handles server + local status update)
    try {
      success = await _repo.cancelOrder(orderId: orderId, reason: reason);
    } catch (_) {}

    // 2. If repo didn't succeed, try service directly
    if (!success) {
      try {
        success = await _orderService.cancelOrder(orderId: orderId, reason: reason);
      } catch (_) {}
    }

    // 3. If server failed, still mark locally preserving real order data
    if (!success) {
      final existing = await _findExistingOrder(orderId);
      await _repo.saveLocalOrder(existing.copyWith(
        status: OrderStatus.cancelled,
        statusHistory: [
          ...existing.statusHistory,
          OrderStatusEvent(
            status: OrderStatus.cancelled,
            timestamp: DateTime.now(),
            note: reason ?? 'Cancelled by customer',
          ),
        ],
      ));
    }

    emit(OrderCancelled(orderId: orderId));
    await loadOrders();
  }

  // ─── Request Return ───────────────────────────────────────────────────────

  Future<void> requestReturn(
    String orderId, {
    required String reason,
    String? details,
    String returnType = 'refund',
    List<Map<String, dynamic>> items = const [],
    List<String>? photoPaths,
  }) async {
    emit(const OrderReturning());
    bool success = false;

    // 1. Try repository
    try {
      success = await _repo.requestReturn(
        orderId: orderId,
        reason: reason,
        details: details,
        returnType: returnType,
        items: items,
        photoPaths: photoPaths,
      );
    } catch (_) {}

    // 2. If repo didn't succeed, try service directly
    if (!success) {
      try {
        success = await _orderService.requestReturn(
          orderId: orderId,
          reason: reason,
          returnType: returnType,
          items: items,
          photoPaths: photoPaths,
        );
      } catch (_) {}
    }

    // 3. If server failed, still mark locally preserving real order data
    if (!success) {
      final existing = await _findExistingOrder(orderId);
      await _repo.saveLocalOrder(existing.copyWith(
        status: OrderStatus.refunded,
        statusHistory: [
          ...existing.statusHistory,
          OrderStatusEvent(
            status: OrderStatus.refunded,
            timestamp: DateTime.now(),
            note: 'Return requested: $reason',
          ),
        ],
      ));
    }

    emit(OrderReturnRequested(
      orderId: orderId,
      message: success
          ? 'Return request submitted successfully'
          : 'Return request saved locally. Server confirmation pending.',
    ));
    await loadOrders();
  }

  // ─── Returns ──────────────────────────────────────────────────────────────

  Future<void> loadReturns() async {
    emit(const OrderReturnsLoading());
    try {
      final returns = await _orderService.fetchReturns();
      emit(OrderReturnsLoaded(returns: returns));
    } catch (e) {
      emit(OrderReturnsError(message: 'Failed to load returns: $e'));
    }
  }

  void reset() => emit(const OrderInitial());

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Finds an existing order by ID, checking current state first, then local storage.
  /// Returns a minimal stub only if the order truly doesn't exist anywhere.
  Future<Order> _findExistingOrder(String orderId) async {
    // 1. Check current loaded state (has full server data)
    final currentState = state;
    if (currentState is OrderLoaded) {
      final match = currentState.orders.where(
        (o) =>
            o.referenceNumber.toLowerCase() == orderId.toLowerCase() ||
            o.id.toLowerCase() == orderId.toLowerCase(),
      );
      if (match.isNotEmpty) return match.first;
    }

    // 2. Check local SharedPreferences storage
    final localOrders = await _repo.getLocalOrders();
    final localMatch = localOrders.where(
      (o) =>
          o.referenceNumber.toLowerCase() == orderId.toLowerCase() ||
          o.id.toLowerCase() == orderId.toLowerCase(),
    );
    if (localMatch.isNotEmpty) return localMatch.first;

    // 3. Last resort — minimal stub (order not found anywhere)
    return Order(
      id: orderId,
      referenceNumber: orderId,
      placedAt: DateTime.now(),
      status: OrderStatus.pending,
      items: const [],
      deliveryAddress: const OrderAddress(name: '', phone: '', addressLine: '', city: ''),
      subtotal: 0,
      deliveryFee: 0,
      storeName: '',
    );
  }
}
