import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/errors/failures.dart';
import '../data/order_service.dart';
import '../models/order_model.dart';
import 'order_state.dart';

class OrderCubit extends Cubit<OrderState> {
  final OrderService _orderService;

  OrderCubit({OrderService? orderService})
      : _orderService = orderService ?? OrderService(),
        super(const OrderInitial());

  Future<void> loadOrders() async {
    emit(const OrderLoading());
    try {
      final orders = await _orderService.fetchOrders();
      emit(OrderLoaded(orders: orders));
    } on AuthFailure {
      // In guest or initial testing mode when no session cookie exists yet,
      // show empty loaded state with a clean empty list rather than hard crash.
      emit(const OrderLoaded(orders: []));
    } on Failure catch (e) {
      emit(OrderError(message: e.message));
    } catch (e) {
      emit(OrderError(message: 'Failed to load orders: $e'));
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

  Future<void> loadOrderDetail(String orderId) async {
    emit(const OrderLoading());
    try {
      final order = await _orderService.fetchOrderDetail(orderId);
      emit(OrderDetailLoaded(order: order));
    } on Failure catch (e) {
      emit(OrderError(message: e.message));
    } catch (e) {
      emit(OrderError(message: 'Failed to load order detail: $e'));
    }
  }

  /// Guest lookup by invoice/reference + phone number via POST /store/track-order
  Future<void> lookupOrder({
    required String referenceNumber,
    required String phone,
  }) async {
    emit(const OrderLoading());
    try {
      final order = await _orderService.trackGuestOrder(
        referenceNumber: referenceNumber,
        phone: phone,
      );
      emit(OrderLookupResult(order: order));
    } on NotFoundFailure {
      emit(const OrderLookupNotFound());
    } on Failure catch (e) {
      emit(OrderError(message: e.message));
    } catch (_) {
      emit(const OrderLookupNotFound());
    }
  }

  Future<void> cancelOrder(String orderId, {String? reason}) async {
    emit(const OrderCancelling());
    await Future.delayed(const Duration(milliseconds: 600));
    emit(OrderCancelled(orderId: orderId));
    loadOrders();
  }

  void reset() => emit(const OrderInitial());
}

