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

  Future<void> loadOrders() async {
    // 1. Instantly load local orders so the screen renders immediately without lag
    final localOrders = await _repo.getLocalOrders();
    if (localOrders.isNotEmpty) {
      emit(OrderLoaded(orders: localOrders));
    } else {
      emit(const OrderLoading());
    }

    // 2. Fetch remote merged orders with quick timeout
    try {
      List<Order> orders = [];
      try {
        orders = await _orderService.fetchOrders();
      } catch (_) {}

      if (orders.isNotEmpty) {
        final currentLocal = await _repo.getLocalOrders();
        final map = <String, Order>{};
        for (final o in orders) {
          map[o.referenceNumber.toLowerCase()] = o;
        }
        for (final o in currentLocal) {
          final key = o.referenceNumber.toLowerCase();
          if (map.containsKey(key)) {
            if (o.status == OrderStatus.cancelled ||
                o.status == OrderStatus.refunded) {
              map[key] = map[key]!.copyWith(
                status: o.status,
                statusHistory: o.statusHistory.isNotEmpty
                    ? o.statusHistory
                    : map[key]!.statusHistory,
              );
            }
          } else {
            map[key] = o;
          }
        }
        orders = map.values.toList()
          ..sort((a, b) => b.placedAt.compareTo(a.placedAt));
      } else {
        orders = await _repo.getOrders();
      }

      if (orders.isEmpty) {
        orders = List<Order>.from(dummyOrders);
      }
      emit(OrderLoaded(orders: orders));
    } on AuthFailure {
      final currentLocal = await _repo.getLocalOrders();
      emit(OrderLoaded(orders: currentLocal.isNotEmpty ? currentLocal : List<Order>.from(dummyOrders)));
    } on Failure catch (e) {
      final currentLocal = await _repo.getLocalOrders();
      if (currentLocal.isNotEmpty) {
        emit(OrderLoaded(orders: currentLocal));
      } else {
        emit(OrderLoaded(orders: List<Order>.from(dummyOrders)));
      }
    } catch (e) {
      final currentLocal = await _repo.getLocalOrders();
      emit(OrderLoaded(orders: currentLocal.isNotEmpty ? currentLocal : List<Order>.from(dummyOrders)));
    }
  }

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

  Future<void> loadOrderDetail(String invoiceNumber) async {
    final cleanInvoice = invoiceNumber.trim();
    // 1. Check local orders first for instantaneous rendering
    final localOrders = await _repo.getLocalOrders();
    final localMatch = localOrders.where(
      (o) =>
          o.referenceNumber.toLowerCase() == cleanInvoice.toLowerCase() ||
          o.id.toLowerCase() == cleanInvoice.toLowerCase(),
    );
    if (localMatch.isNotEmpty) {
      emit(OrderDetailLoaded(order: localMatch.first));
    } else {
      emit(const OrderLoading());
    }

    try {
      final order = await _repo.getOrderDetail(cleanInvoice);
      NotificationService.instance.tagOrderTracking(
        orderId: order.id,
        referenceNumber: order.referenceNumber,
        status: order.status.name,
      );
      emit(OrderDetailLoaded(order: order));
    } on Failure catch (e) {
      if (localMatch.isEmpty) {
        try {
          final order = await _orderService.fetchOrderDetail(cleanInvoice);
          NotificationService.instance.tagOrderTracking(
            orderId: order.id,
            referenceNumber: order.referenceNumber,
            status: order.status.name,
          );
          emit(OrderDetailLoaded(order: order));
        } catch (_) {
          emit(OrderError(message: e.message));
        }
      }
    } catch (e) {
      if (localMatch.isEmpty) {
        emit(OrderError(message: 'Failed to load order detail: $e'));
      }
    }
  }

  /// Guest lookup by invoice/reference + phone number via POST /store/track-order
  Future<void> lookupOrder({
    required String referenceNumber,
    required String phone,
  }) async {
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
      emit(OrderLookupResult(order: order));
    } on NotFoundFailure {
      emit(const OrderLookupNotFound());
    } on Failure catch (e) {
      emit(OrderError(message: e.message));
    } catch (_) {
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

  Future<void> cancelOrder(String orderId, {String? reason}) async {
    emit(const OrderCancelling());
    try {
      await _repo.cancelOrder(orderId: orderId, reason: reason);
    } catch (_) {
      try {
        await _orderService.cancelOrder(orderId: orderId, reason: reason);
      } catch (_) {}
    }
    emit(OrderCancelled(orderId: orderId));
    await loadOrders();
  }

  Future<void> requestReturn(
    String orderId, {
    required String reason,
    String? details,
    String returnType = 'refund',
    List<Map<String, dynamic>> items = const [],
    List<String>? photoPaths,
  }) async {
    emit(const OrderReturning());
    try {
      await _repo.requestReturn(
        orderId: orderId,
        reason: reason,
        details: details,
        returnType: returnType,
        items: items,
        photoPaths: photoPaths,
      );
    } catch (_) {
      try {
        await _orderService.requestReturn(
          orderId: orderId,
          reason: reason,
          returnType: returnType,
          items: items,
          photoPaths: photoPaths,
        );
      } catch (_) {}
    }
    emit(OrderReturnRequested(orderId: orderId));
    await loadOrders();
  }

  void reset() => emit(const OrderInitial());
}
