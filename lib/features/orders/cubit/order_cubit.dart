import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/order_model.dart';
import 'order_state.dart';

class OrderCubit extends Cubit<OrderState> {
  OrderCubit() : super(const OrderInitial());

  Future<void> loadOrders() async {
    emit(const OrderLoading());
    // Simulate network delay for now; replace with repository call later
    await Future.delayed(const Duration(milliseconds: 600));
    emit(OrderLoaded(orders: dummyOrders));
  }

  void filterByStatus(String? status) {
    final current = state;
    if (current is OrderLoaded) {
      emit(OrderLoaded(orders: current.orders, activeFilter: status));
    }
  }

  Future<void> loadOrderDetail(String orderId) async {
    emit(const OrderLoading());
    await Future.delayed(const Duration(milliseconds: 400));
    final order = dummyOrders.firstWhere(
      (o) => o.id == orderId,
      orElse: () => dummyOrders.first,
    );
    emit(OrderDetailLoaded(order: order));
  }

  /// Guest lookup by invoice/reference + phone number
  Future<void> lookupOrder({
    required String referenceNumber,
    required String phone,
  }) async {
    emit(const OrderLoading());
    await Future.delayed(const Duration(milliseconds: 800));
    try {
      final ref = referenceNumber.trim().toUpperCase();
      final ph = phone.trim().replaceAll(RegExp(r'\s+'), '');
      final match = dummyOrders.firstWhere(
        (o) =>
            o.referenceNumber.toUpperCase() == ref &&
            o.deliveryAddress.phone.replaceAll(RegExp(r'\s+'), '').endsWith(
                  ph.length >= 10 ? ph.substring(ph.length - 10) : ph,
                ),
        orElse: () => throw Exception('not_found'),
      );
      emit(OrderLookupResult(order: match));
    } catch (_) {
      emit(const OrderLookupNotFound());
    }
  }

  Future<void> cancelOrder(String orderId, {String? reason}) async {
    emit(const OrderCancelling());
    await Future.delayed(const Duration(milliseconds: 600));
    // Update the order status in dummyOrders
    final orderIndex = dummyOrders.indexWhere((o) => o.id == orderId);
    if (orderIndex != -1) {
      final cancelledOrder = dummyOrders[orderIndex];
      dummyOrders[orderIndex] = Order(
        id: cancelledOrder.id,
        referenceNumber: cancelledOrder.referenceNumber,
        placedAt: cancelledOrder.placedAt,
        status: OrderStatus.cancelled,
        items: cancelledOrder.items,
        deliveryAddress: cancelledOrder.deliveryAddress,
        subtotal: cancelledOrder.subtotal,
        deliveryFee: cancelledOrder.deliveryFee,
        discount: cancelledOrder.discount,
        storeName: cancelledOrder.storeName,
        storeCity: cancelledOrder.storeCity,
        storeContact: cancelledOrder.storeContact,
        estimatedDelivery: cancelledOrder.estimatedDelivery,
        statusHistory: [
          ...cancelledOrder.statusHistory,
          OrderStatusEvent(
            status: OrderStatus.cancelled,
            timestamp: DateTime.now(),
            note: reason ?? 'Cancelled by customer',
          ),
        ],
      );
    }
    emit(OrderCancelled(orderId: orderId));
    // Reload orders to reflect the cancellation in the orders list
    emit(OrderLoaded(orders: List.from(dummyOrders)));
  }

  void reset() => emit(const OrderInitial());
}
