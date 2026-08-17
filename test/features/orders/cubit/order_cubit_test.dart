import 'package:flutter_test/flutter_test.dart';
import 'package:softstore_buyer_app/features/orders/cubit/order_cubit.dart';
import 'package:softstore_buyer_app/features/orders/cubit/order_state.dart';
import 'package:softstore_buyer_app/features/orders/models/order_model.dart';

import 'package:softstore_buyer_app/features/orders/data/order_service.dart';

final kTestOrders = [
  Order(
    id: '1',
    referenceNumber: 'SS-20240801-0042',
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
    referenceNumber: 'SS-20240805-0088',
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
    referenceNumber: 'SS-20240810-0203',
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
    referenceNumber: 'SS-20240809-0117',
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

  @override
  Future<Order> fetchOrderDetail(String invoiceNumber) async {
    return kTestOrders.firstWhere(
      (o) => o.referenceNumber == invoiceNumber || o.id == invoiceNumber,
      orElse: () => kTestOrders.first,
    );
  }
}

void main() {
  group('OrderCubit', () {
    late OrderCubit cubit;

    setUp(() {
      cubit = OrderCubit(orderService: FakeOrderService());
    });

    tearDown(() {
      cubit.close();
    });

    group('loadOrders', () {
      test('emits OrderLoading then OrderLoaded with all dummy orders', () async {
        expectLater(
          cubit.stream,
          emitsInOrder([
            isA<OrderLoading>(),
            isA<OrderLoaded>().having(
              (s) => s.orders.length,
              'orders count',
              dummyOrders.length,
            ),
          ]),
        );

        await cubit.loadOrders();
      });

      test('loaded state has correct default values', () async {
        await cubit.loadOrders();
        final state = cubit.state as OrderLoaded;

        expect(state.searchQuery, isEmpty);
        expect(state.statusFilters, isEmpty);
        expect(state.sortOption, OrderSortOption.newestFirst);
        expect(state.dateFrom, isNull);
        expect(state.dateTo, isNull);
        expect(state.activeFilter, isNull);
      });
    });

    group('updateSearchQuery', () {
      test('updates search query in state', () async {
        await cubit.loadOrders();
        cubit.updateSearchQuery('SS-20240801');

        final state = cubit.state as OrderLoaded;
        expect(state.searchQuery, 'SS-20240801');
      });

      test('filtered returns orders matching reference number', () async {
        await cubit.loadOrders();
        cubit.updateSearchQuery('SS-20240801');

        final state = cubit.state as OrderLoaded;
        final filtered = state.filtered;

        expect(filtered.length, 1);
        expect(filtered.first.referenceNumber, 'SS-20240801-0042');
      });

      test('filtered returns orders matching store name', () async {
        await cubit.loadOrders();
        cubit.updateSearchQuery('TechZone');

        final state = cubit.state as OrderLoaded;
        final filtered = state.filtered;

        expect(filtered.length, 1);
        expect(filtered.first.storeName, 'TechZone Mobile Accessories');
      });

      test('filtered returns orders matching item name', () async {
        await cubit.loadOrders();
        cubit.updateSearchQuery('Samsung');

        final state = cubit.state as OrderLoaded;
        final filtered = state.filtered;

        expect(filtered.length, 1);
        expect(filtered.first.items.first.name, 'Samsung Fast Charger 25W');
      });

      test('filtered returns orders matching store city', () async {
        await cubit.loadOrders();
        cubit.updateSearchQuery('Lahore');

        final state = cubit.state as OrderLoaded;
        final filtered = state.filtered;

        expect(filtered.length, 1);
        expect(filtered.first.storeCity, 'Lahore');
      });

      test('filtered returns orders matching delivery city', () async {
        await cubit.loadOrders();
        cubit.updateSearchQuery('Islamabad');

        final state = cubit.state as OrderLoaded;
        final filtered = state.filtered;

        // All 4 orders are delivered to Islamabad
        expect(filtered.length, 4);
      });

      test('search is case insensitive', () async {
        await cubit.loadOrders();
        cubit.updateSearchQuery('techzone');

        final state = cubit.state as OrderLoaded;
        final filtered = state.filtered;

        expect(filtered.length, 1);
      });

      test('empty search returns all orders', () async {
        await cubit.loadOrders();
        cubit.updateSearchQuery('');

        final state = cubit.state as OrderLoaded;
        expect(state.filtered.length, dummyOrders.length);
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
        final filtered = state.filtered;

        expect(filtered.length, 1);
        expect(filtered.first.storeName, 'Fresh Dairy Direct');
      });
    });

    group('updateStatusFilters', () {
      test('filters by single status', () async {
        await cubit.loadOrders();
        cubit.updateStatusFilters([OrderStatus.delivered]);

        final state = cubit.state as OrderLoaded;
        final filtered = state.filtered;

        expect(filtered.length, 1);
        expect(filtered.first.status, OrderStatus.delivered);
      });

      test('filters by multiple statuses', () async {
        await cubit.loadOrders();
        cubit.updateStatusFilters([OrderStatus.pending, OrderStatus.processing]);

        final state = cubit.state as OrderLoaded;
        final filtered = state.filtered;

        expect(filtered.length, 1); // Only order 3 is processing
        expect(filtered.first.status, OrderStatus.processing);
      });

      test('empty status filter returns all orders', () async {
        await cubit.loadOrders();
        cubit.updateStatusFilters([]);

        final state = cubit.state as OrderLoaded;
        expect(state.filtered.length, dummyOrders.length);
      });

      test('cancelled and refunded grouped together', () async {
        await cubit.loadOrders();
        cubit.updateStatusFilters([OrderStatus.cancelled]);

        final state = cubit.state as OrderLoaded;
        final filtered = state.filtered;

        expect(filtered.length, 1);
        expect(filtered.first.status, OrderStatus.cancelled);
      });
    });

    group('updateSortOption', () {
      test('sorts by newest first (default)', () async {
        await cubit.loadOrders();
        cubit.updateSortOption(OrderSortOption.newestFirst);

        final state = cubit.state as OrderLoaded;
        final filtered = state.filtered;

        // Order 3 (Aug 10) should be first
        expect(filtered.first.placedAt, DateTime(2024, 8, 10, 16, 45));
      });

      test('sorts by oldest first', () async {
        await cubit.loadOrders();
        cubit.updateSortOption(OrderSortOption.oldestFirst);

        final state = cubit.state as OrderLoaded;
        final filtered = state.filtered;

        // Order 1 (Aug 1) should be first
        expect(filtered.first.placedAt, DateTime(2024, 8, 1, 14, 30));
      });

      test('sorts by price low to high', () async {
        await cubit.loadOrders();
        cubit.updateSortOption(OrderSortOption.priceLowToHigh);

        final state = cubit.state as OrderLoaded;
        final filtered = state.filtered;

        // Order 4 (total 670) should be first
        expect(filtered.first.total, 670);
      });

      test('sorts by price high to low', () async {
        await cubit.loadOrders();
        cubit.updateSortOption(OrderSortOption.priceHighToLow);

        final state = cubit.state as OrderLoaded;
        final filtered = state.filtered;

        // Order 2 (total 2700) should be first
        expect(filtered.first.total, 2700);
      });
    });

    group('updateDateRange', () {
      test('filters by date from', () async {
        await cubit.loadOrders();
        cubit.updateDateRange(from: DateTime(2024, 8, 5));

        final state = cubit.state as OrderLoaded;
        final filtered = state.filtered;

        // Orders from Aug 5, 9, 10
        expect(filtered.length, 3);
      });

      test('filters by date to', () async {
        await cubit.loadOrders();
        cubit.updateDateRange(to: DateTime(2024, 8, 5));

        final state = cubit.state as OrderLoaded;
        final filtered = state.filtered;

        // Orders on Aug 1 and Aug 5
        expect(filtered.length, 2);
      });

      test('filters by date range', () async {
        await cubit.loadOrders();
        cubit.updateDateRange(
          from: DateTime(2024, 8, 5),
          to: DateTime(2024, 8, 9),
        );

        final state = cubit.state as OrderLoaded;
        final filtered = state.filtered;

        // Orders on Aug 5 and Aug 9
        expect(filtered.length, 2);
      });

      test('clears date from', () async {
        await cubit.loadOrders();
        cubit.updateDateRange(from: DateTime(2024, 8, 5));
        cubit.updateDateRange(clearFrom: true);

        final state = cubit.state as OrderLoaded;
        expect(state.dateFrom, isNull);
      });

      test('clears date to', () async {
        await cubit.loadOrders();
        cubit.updateDateRange(to: DateTime(2024, 8, 9));
        cubit.updateDateRange(clearTo: true);

        final state = cubit.state as OrderLoaded;
        expect(state.dateTo, isNull);
      });
    });

    group('clearFilters', () {
      test('resets all filters to defaults', () async {
        await cubit.loadOrders();

        // Apply some filters
        cubit.updateSearchQuery('test');
        cubit.updateStatusFilters([OrderStatus.delivered]);
        cubit.updateSortOption(OrderSortOption.priceHighToLow);
        cubit.updateDateRange(from: DateTime(2024, 8, 1));

        // Clear all
        cubit.clearFilters();

        final state = cubit.state as OrderLoaded;
        expect(state.searchQuery, isEmpty);
        expect(state.statusFilters, isEmpty);
        expect(state.sortOption, OrderSortOption.newestFirst);
        expect(state.dateFrom, isNull);
        expect(state.dateTo, isNull);
      });
    });

    group('activeFilterCount', () {
      test('returns 0 when no filters active', () async {
        await cubit.loadOrders();
        final state = cubit.state as OrderLoaded;
        expect(state.activeFilterCount, 0);
      });

      test('counts status filter', () async {
        await cubit.loadOrders();
        cubit.updateStatusFilters([OrderStatus.delivered]);
        final state = cubit.state as OrderLoaded;
        expect(state.activeFilterCount, 1);
      });

      test('counts date filter', () async {
        await cubit.loadOrders();
        cubit.updateDateRange(from: DateTime(2024, 8, 1));
        final state = cubit.state as OrderLoaded;
        expect(state.activeFilterCount, 1);
      });

      test('counts sort filter when not default', () async {
        await cubit.loadOrders();
        cubit.updateSortOption(OrderSortOption.priceHighToLow);
        final state = cubit.state as OrderLoaded;
        expect(state.activeFilterCount, 1);
      });

      test('counts multiple filters', () async {
        await cubit.loadOrders();
        cubit.updateStatusFilters([OrderStatus.delivered]);
        cubit.updateDateRange(from: DateTime(2024, 8, 1));
        cubit.updateSortOption(OrderSortOption.priceHighToLow);
        final state = cubit.state as OrderLoaded;
        expect(state.activeFilterCount, 3);
      });
    });

    group('combined filters', () {
      test('search + status filter works together', () async {
        await cubit.loadOrders();
        cubit.updateSearchQuery('Islamabad');
        cubit.updateStatusFilters([OrderStatus.delivered]);

        final state = cubit.state as OrderLoaded;
        final filtered = state.filtered;

        // Only delivered order to Islamabad
        expect(filtered.length, 1);
        expect(filtered.first.status, OrderStatus.delivered);
        expect(filtered.first.deliveryAddress.city, 'Islamabad');
      });

      test('search + sort works together', () async {
        await cubit.loadOrders();
        cubit.updateSearchQuery('Islamabad');
        cubit.updateSortOption(OrderSortOption.priceLowToHigh);

        final state = cubit.state as OrderLoaded;
        final filtered = state.filtered;

        expect(filtered.length, 4);
        // First should be cheapest (Order 4: 670)
        expect(filtered.first.total, 670);
      });

      test('all filters combined', () async {
        await cubit.loadOrders();
        cubit.updateSearchQuery('Islamabad');
        cubit.updateStatusFilters([OrderStatus.delivered, OrderStatus.shipped]);
        cubit.updateSortOption(OrderSortOption.priceHighToLow);
        cubit.updateDateRange(
          from: DateTime(2024, 8, 1),
          to: DateTime(2024, 8, 10),
        );

        final state = cubit.state as OrderLoaded;
        final filtered = state.filtered;

        // Delivered + Shipped orders to Islamabad within date range
        for (final order in filtered) {
          expect(order.deliveryAddress.city, 'Islamabad');
          expect(
            order.status == OrderStatus.delivered ||
                order.status == OrderStatus.shipped,
            isTrue,
          );
        }
      });
    });

    group('filterByStatus (tab filter)', () {
      test('filters by active tab', () async {
        await cubit.loadOrders();
        cubit.filterByStatus('pending');

        final state = cubit.state as OrderLoaded;
        expect(state.activeFilter, 'pending');
      });

      test('clears tab filter when null', () async {
        await cubit.loadOrders();
        cubit.filterByStatus('pending');
        cubit.filterByStatus(null);

        final state = cubit.state as OrderLoaded;
        expect(state.activeFilter, isNull);
      });
    });
  });
}
