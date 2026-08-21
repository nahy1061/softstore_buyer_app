import 'package:flutter_test/flutter_test.dart';
import 'package:softstore_buyer_app/features/orders/cubit/order_cubit.dart';
import 'package:softstore_buyer_app/features/orders/cubit/order_state.dart';
import 'package:softstore_buyer_app/features/orders/models/order_model.dart';
import 'package:softstore_buyer_app/features/orders/data/order_service.dart';

final kTestOrders = [
  Order(
    id: '1',
    referenceNumber: 'INV-17225058001234',
    placedAt: DateTime(2024, 8, 1, 14, 30),
    status: OrderStatus.confirmed,
    storeName: 'TechZone Mobile Accessories',
    storeCity: 'Lahore',
    subtotal: 1200,
    deliveryFee: 100,
    deliveryAddress: const OrderAddress(
      name: 'Ali Khan',
      phone: '+92 300 1234567',
      addressLine: 'Street 1, F-7',
      city: 'Islamabad',
    ),
    items: const [
      OrderItem(id: 'i1', name: 'Samsung Fast Charger 25W', quantity: 1, unitPrice: 1200),
    ],
  ),
  Order(
    id: '2',
    referenceNumber: 'INV-17228505001234',
    placedAt: DateTime(2024, 8, 5, 9, 15),
    status: OrderStatus.cancelled,
    storeName: 'Fashion Hub',
    storeCity: 'Karachi',
    subtotal: 2500,
    deliveryFee: 200,
    deliveryAddress: const OrderAddress(
      name: 'Ali Khan',
      phone: '+92 300 1234567',
      addressLine: 'Street 1, F-7',
      city: 'Islamabad',
    ),
    items: const [
      OrderItem(id: 'i2', name: 'Denim Jacket', quantity: 1, unitPrice: 2500),
    ],
  ),
  Order(
    id: '3',
    referenceNumber: 'INV-17232885001234',
    placedAt: DateTime(2024, 8, 10, 16, 45),
    status: OrderStatus.delivered,
    storeName: 'Fresh Dairy Direct',
    storeCity: 'Rawalpindi',
    subtotal: 960,
    deliveryFee: 100,
    deliveryAddress: const OrderAddress(
      name: 'Ali Khan',
      phone: '+92 300 1234567',
      addressLine: 'Street 1, F-7',
      city: 'Islamabad',
    ),
    items: const [
      OrderItem(id: 'i3', name: 'Milk 1L', quantity: 2, unitPrice: 480),
    ],
  ),
  Order(
    id: '4',
    referenceNumber: 'INV-17231808001234',
    placedAt: DateTime(2024, 8, 9, 11, 0),
    status: OrderStatus.processing,
    storeName: 'Grocery Express',
    storeCity: 'Islamabad',
    subtotal: 550,
    deliveryFee: 120,
    deliveryAddress: const OrderAddress(
      name: 'Ali Khan',
      phone: '+92 300 1234567',
      addressLine: 'Street 1, F-7',
      city: 'Islamabad',
    ),
    items: const [
      OrderItem(id: 'i4', name: 'Cooking Oil 1L', quantity: 1, unitPrice: 550),
    ],
  ),
];

class FakeOrderService extends OrderService {
  @override
  Future<List<Order>> fetchOrders() async {
    return List<Order>.from(kTestOrders);
  }
}

/// Verifies search bar and filter logic via the OrderCubit,
/// which is the business logic layer powering the UI.
/// Full widget tests are skipped due to _AnimatedSLogo infinite
/// animations in AppBottomNavBar preventing pump() from settling.
void main() {
  late OrderCubit cubit;

  setUp(() {
    cubit = OrderCubit(orderService: FakeOrderService());
  });

  tearDown(() {
    cubit.close();
  });

  group('Order Search - Cubit Logic', () {
    test('initial state is OrderInitial', () {
      expect(cubit.state, isA<OrderInitial>());
    });

    test('loadOrders emits OrderLoading then OrderLoaded', () async {
      expectLater(
        cubit.stream,
        emitsInOrder([
          isA<OrderLoading>(),
          isA<OrderLoaded>(),
        ]),
      );
      await cubit.loadOrders();
    });

    test('loaded state has 4 dummy orders', () async {
      await cubit.loadOrders();
      final state = cubit.state as OrderLoaded;
      expect(state.orders.length, 4);
    });

    test('search by reference number', () async {
      await cubit.loadOrders();
      cubit.updateSearchQuery('1722505800');
      final state = cubit.state as OrderLoaded;
      expect(state.filtered.length, 1);
      expect(state.filtered.first.referenceNumber, 'INV-17225058001234');
    });

    test('search by store name', () async {
      await cubit.loadOrders();
      cubit.updateSearchQuery('TechZone');
      final state = cubit.state as OrderLoaded;
      expect(state.filtered.length, 1);
      expect(state.filtered.first.storeName, 'TechZone Mobile Accessories');
    });

    test('search by item name', () async {
      await cubit.loadOrders();
      cubit.updateSearchQuery('Samsung');
      final state = cubit.state as OrderLoaded;
      expect(state.filtered.length, 1);
      expect(state.filtered.first.items.first.name, 'Samsung Fast Charger 25W');
    });

    test('search by store city', () async {
      await cubit.loadOrders();
      cubit.updateSearchQuery('Lahore');
      final state = cubit.state as OrderLoaded;
      expect(state.filtered.length, 1);
      expect(state.filtered.first.storeCity, 'Lahore');
    });

    test('search by delivery city', () async {
      await cubit.loadOrders();
      cubit.updateSearchQuery('Islamabad');
      final state = cubit.state as OrderLoaded;
      expect(state.filtered.length, 4);
    });

    test('search is case insensitive', () async {
      await cubit.loadOrders();
      cubit.updateSearchQuery('techzone');
      final state = cubit.state as OrderLoaded;
      expect(state.filtered.length, 1);
    });

    test('empty search returns all orders', () async {
      await cubit.loadOrders();
      cubit.updateSearchQuery('');
      final state = cubit.state as OrderLoaded;
      expect(state.filtered.length, 4);
    });

    test('no matching search returns empty list', () async {
      await cubit.loadOrders();
      cubit.updateSearchQuery('NONEXISTENT123');
      final state = cubit.state as OrderLoaded;
      expect(state.filtered, isEmpty);
    });

    test('partial match works', () async {
      await cubit.loadOrders();
      cubit.updateSearchQuery('Fresh');
      final state = cubit.state as OrderLoaded;
      expect(state.filtered.length, 1);
      expect(state.filtered.first.storeName, 'Fresh Dairy Direct');
    });

    test('clear search restores all orders', () async {
      await cubit.loadOrders();
      cubit.updateSearchQuery('TechZone');
      expect((cubit.state as OrderLoaded).filtered.length, 1);

      cubit.updateSearchQuery('');
      expect((cubit.state as OrderLoaded).filtered.length, 4);
    });
  });

  group('Order Filter - Status', () {
    test('filter by delivered status', () async {
      await cubit.loadOrders();
      cubit.updateStatusFilters([OrderStatus.delivered]);
      final state = cubit.state as OrderLoaded;
      expect(state.filtered.length, 1);
      expect(state.filtered.first.status, OrderStatus.delivered);
    });

    test('filter by multiple statuses', () async {
      await cubit.loadOrders();
      cubit.updateStatusFilters([OrderStatus.pending, OrderStatus.processing]);
      final state = cubit.state as OrderLoaded;
      expect(state.filtered.length, 1);
    });

    test('empty status filter returns all', () async {
      await cubit.loadOrders();
      cubit.updateStatusFilters([]);
      expect((cubit.state as OrderLoaded).filtered.length, 4);
    });
  });

  group('Order Filter - Sort', () {
    test('sort by newest first', () async {
      await cubit.loadOrders();
      cubit.updateSortOption(OrderSortOption.newestFirst);
      final state = cubit.state as OrderLoaded;
      expect(state.filtered.first.placedAt, DateTime(2024, 8, 10, 16, 45));
    });

    test('sort by oldest first', () async {
      await cubit.loadOrders();
      cubit.updateSortOption(OrderSortOption.oldestFirst);
      final state = cubit.state as OrderLoaded;
      expect(state.filtered.first.placedAt, DateTime(2024, 8, 1, 14, 30));
    });

    test('sort by price low to high', () async {
      await cubit.loadOrders();
      cubit.updateSortOption(OrderSortOption.priceLowToHigh);
      final state = cubit.state as OrderLoaded;
      expect(state.filtered.first.total, 670);
    });

    test('sort by price high to low', () async {
      await cubit.loadOrders();
      cubit.updateSortOption(OrderSortOption.priceHighToLow);
      final state = cubit.state as OrderLoaded;
      expect(state.filtered.first.total, 2700);
    });
  });

  group('Order Filter - Date Range', () {
    test('filter by date from', () async {
      await cubit.loadOrders();
      cubit.updateDateRange(from: DateTime(2024, 8, 5));
      expect((cubit.state as OrderLoaded).filtered.length, 3);
    });

    test('filter by date to', () async {
      await cubit.loadOrders();
      cubit.updateDateRange(to: DateTime(2024, 8, 5));
      expect((cubit.state as OrderLoaded).filtered.length, 2);
    });

    test('clear date range', () async {
      await cubit.loadOrders();
      cubit.updateDateRange(from: DateTime(2024, 8, 5));
      cubit.updateDateRange(clearFrom: true, clearTo: true);
      expect((cubit.state as OrderLoaded).dateFrom, isNull);
      expect((cubit.state as OrderLoaded).dateTo, isNull);
    });
  });

  group('Order Filter - Combined', () {
    test('search + status filter', () async {
      await cubit.loadOrders();
      cubit.updateSearchQuery('Islamabad');
      cubit.updateStatusFilters([OrderStatus.delivered]);
      final state = cubit.state as OrderLoaded;
      expect(state.filtered.length, 1);
      expect(state.filtered.first.status, OrderStatus.delivered);
    });

    test('search + sort', () async {
      await cubit.loadOrders();
      cubit.updateSearchQuery('Islamabad');
      cubit.updateSortOption(OrderSortOption.priceLowToHigh);
      final state = cubit.state as OrderLoaded;
      expect(state.filtered.first.total, 670);
    });

    test('clearFilters resets everything', () async {
      await cubit.loadOrders();
      cubit.updateSearchQuery('test');
      cubit.updateStatusFilters([OrderStatus.delivered]);
      cubit.updateSortOption(OrderSortOption.priceHighToLow);
      cubit.updateDateRange(from: DateTime(2024, 8, 1));

      cubit.clearFilters();
      final state = cubit.state as OrderLoaded;
      expect(state.searchQuery, isEmpty);
      expect(state.statusFilters, isEmpty);
      expect(state.sortOption, OrderSortOption.newestFirst);
      expect(state.dateFrom, isNull);
      expect(state.dateTo, isNull);
    });
  });

  group('Filter Count', () {
    test('returns 0 when no filters active', () async {
      await cubit.loadOrders();
      expect((cubit.state as OrderLoaded).activeFilterCount, 0);
    });

    test('counts status filter', () async {
      await cubit.loadOrders();
      cubit.updateStatusFilters([OrderStatus.delivered]);
      expect((cubit.state as OrderLoaded).activeFilterCount, 1);
    });

    test('counts date filter', () async {
      await cubit.loadOrders();
      cubit.updateDateRange(from: DateTime(2024, 8, 1));
      expect((cubit.state as OrderLoaded).activeFilterCount, 1);
    });

    test('counts sort filter when non-default', () async {
      await cubit.loadOrders();
      cubit.updateSortOption(OrderSortOption.priceHighToLow);
      expect((cubit.state as OrderLoaded).activeFilterCount, 1);
    });

    test('counts all three filter types', () async {
      await cubit.loadOrders();
      cubit.updateStatusFilters([OrderStatus.delivered]);
      cubit.updateDateRange(from: DateTime(2024, 8, 1));
      cubit.updateSortOption(OrderSortOption.priceHighToLow);
      expect((cubit.state as OrderLoaded).activeFilterCount, 3);
    });
  });

  group('Tab Filter', () {
    test('filterByStatus sets active tab', () async {
      await cubit.loadOrders();
      cubit.filterByStatus('pending');
      expect((cubit.state as OrderLoaded).activeFilter, 'pending');
    });

    test('filterByStatus(null) clears active tab', () async {
      await cubit.loadOrders();
      cubit.filterByStatus('pending');
      cubit.filterByStatus(null);
      expect((cubit.state as OrderLoaded).activeFilter, isNull);
    });
  });
}
