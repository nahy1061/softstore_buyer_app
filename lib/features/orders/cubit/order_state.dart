import 'package:equatable/equatable.dart';
import '../models/order_model.dart';

abstract class OrderState extends Equatable {
  const OrderState();

  @override
  List<Object?> get props => [];
}

class OrderInitial extends OrderState {
  const OrderInitial();
}

class OrderLoading extends OrderState {
  const OrderLoading();
}

class OrderLoaded extends OrderState {
  final List<Order> orders;
  final String? activeFilter;

  const OrderLoaded({required this.orders, this.activeFilter});

  List<Order> get filtered {
    if (activeFilter == null) return orders;
    return orders.where((o) => o.status.name == activeFilter).toList();
  }

  List<Order> get active => orders.where((o) =>
      o.status == OrderStatus.pending ||
      o.status == OrderStatus.processing ||
      o.status == OrderStatus.shipped).toList();

  List<Order> get delivered =>
      orders.where((o) => o.status == OrderStatus.delivered).toList();

  List<Order> get cancelled => orders.where((o) =>
      o.status == OrderStatus.cancelled ||
      o.status == OrderStatus.refunded).toList();

  @override
  List<Object?> get props => [orders, activeFilter];
}

class OrderDetailLoaded extends OrderState {
  final Order order;

  const OrderDetailLoaded({required this.order});

  @override
  List<Object?> get props => [order];
}

class OrderLookupResult extends OrderState {
  final Order order;

  const OrderLookupResult({required this.order});

  @override
  List<Object?> get props => [order];
}

class OrderLookupNotFound extends OrderState {
  const OrderLookupNotFound();
}

class OrderCancelling extends OrderState {
  const OrderCancelling();
}

class OrderCancelled extends OrderState {
  final String orderId;

  const OrderCancelled({required this.orderId});

  @override
  List<Object?> get props => [orderId];
}

class OrderError extends OrderState {
  final String message;

  const OrderError({required this.message});

  @override
  List<Object?> get props => [message];
}
