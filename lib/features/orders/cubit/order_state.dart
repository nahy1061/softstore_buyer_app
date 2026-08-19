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
  final String searchQuery;
  final List<OrderStatus> statusFilters;
  final OrderSortOption sortOption;
  final DateTime? dateFrom;
  final DateTime? dateTo;

  const OrderLoaded({
    required this.orders,
    this.activeFilter,
    this.searchQuery = '',
    this.statusFilters = const [],
    this.sortOption = OrderSortOption.newestFirst,
    this.dateFrom,
    this.dateTo,
  });

  List<Order> get filtered {
    var result = List<Order>.from(orders);

    // Apply search query
    if (searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      result = result.where((o) {
        return o.referenceNumber.toLowerCase().contains(query) ||
            o.storeName.toLowerCase().contains(query) ||
            o.storeCity?.toLowerCase().contains(query) == true ||
            o.items.any((item) => item.name.toLowerCase().contains(query)) ||
            o.deliveryAddress.city.toLowerCase().contains(query);
      }).toList();
    }

    // Apply status filters (from filter sheet)
    if (statusFilters.isNotEmpty) {
      result = result.where((o) => statusFilters.contains(o.status)).toList();
    }

    // Apply active tab filter
    if (activeFilter != null) {
      result = result.where((o) => o.status.name == activeFilter).toList();
    }

    // Apply date range
    if (dateFrom != null) {
      result = result.where((o) => o.placedAt.isAfter(dateFrom!) || o.placedAt.isAtSameMomentAs(dateFrom!)).toList();
    }
    if (dateTo != null) {
      final endOfDay = DateTime(dateTo!.year, dateTo!.month, dateTo!.day, 23, 59, 59);
      result = result.where((o) => o.placedAt.isBefore(endOfDay) || o.placedAt.isAtSameMomentAs(endOfDay)).toList();
    }

    // Apply sort
    switch (sortOption) {
      case OrderSortOption.newestFirst:
        result.sort((a, b) => b.placedAt.compareTo(a.placedAt));
        break;
      case OrderSortOption.oldestFirst:
        result.sort((a, b) => a.placedAt.compareTo(b.placedAt));
        break;
      case OrderSortOption.priceLowToHigh:
        result.sort((a, b) => a.total.compareTo(b.total));
        break;
      case OrderSortOption.priceHighToLow:
        result.sort((a, b) => b.total.compareTo(a.total));
        break;
    }

    return result;
  }

  int get activeFilterCount {
    int count = 0;
    if (statusFilters.isNotEmpty) count++;
    if (dateFrom != null || dateTo != null) count++;
    if (sortOption != OrderSortOption.newestFirst) count++;
    return count;
  }

  List<Order> get active => orders.where((o) =>
      o.status == OrderStatus.pending ||
      o.status == OrderStatus.confirmed ||
      o.status == OrderStatus.processing ||
      o.status == OrderStatus.shipped).toList();

  List<Order> get delivered =>
      orders.where((o) => o.status == OrderStatus.delivered).toList();

  List<Order> get cancelled => orders.where((o) =>
      o.status == OrderStatus.cancelled ||
      o.status == OrderStatus.refunded).toList();

  OrderLoaded copyWith({
    List<Order>? orders,
    String? activeFilter,
    bool clearActiveFilter = false,
    String? searchQuery,
    List<OrderStatus>? statusFilters,
    OrderSortOption? sortOption,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool clearDateFrom = false,
    bool clearDateTo = false,
  }) {
    return OrderLoaded(
      orders: orders ?? this.orders,
      activeFilter: clearActiveFilter ? null : activeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilters: statusFilters ?? this.statusFilters,
      sortOption: sortOption ?? this.sortOption,
      dateFrom: clearDateFrom ? null : (dateFrom ?? this.dateFrom),
      dateTo: clearDateTo ? null : (dateTo ?? this.dateTo),
    );
  }

  @override
  List<Object?> get props => [orders, activeFilter, searchQuery, statusFilters, sortOption, dateFrom, dateTo];
}

enum OrderSortOption {
  newestFirst,
  oldestFirst,
  priceLowToHigh,
  priceHighToLow,
}

extension OrderSortOptionExtension on OrderSortOption {
  String get label {
    switch (this) {
      case OrderSortOption.newestFirst:
        return 'Newest First';
      case OrderSortOption.oldestFirst:
        return 'Oldest First';
      case OrderSortOption.priceLowToHigh:
        return 'Price: Low to High';
      case OrderSortOption.priceHighToLow:
        return 'Price: High to Low';
    }
  }
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

class OrderReturning extends OrderState {
  const OrderReturning();
}

class OrderReturnRequested extends OrderState {
  final String orderId;
  final String message;

  const OrderReturnRequested({
    required this.orderId,
    this.message = 'Return request submitted successfully',
  });

  @override
  List<Object?> get props => [orderId, message];
}

class OrderError extends OrderState {
  final String message;

  const OrderError({required this.message});

  @override
  List<Object?> get props => [message];
}
