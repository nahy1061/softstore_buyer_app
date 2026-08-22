import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:softstore_buyer_app/features/auth/cubit/auth_cubit.dart';
import 'package:softstore_buyer_app/features/auth/cubit/auth_state.dart';
import 'package:softstore_buyer_app/features/auth/models/user_model.dart';
import 'package:softstore_buyer_app/features/cart/cubit/cart_cubit.dart';
import 'package:softstore_buyer_app/features/cart/models/cart_models.dart';
import 'package:softstore_buyer_app/features/catalog/models/catalog_models.dart';
import 'package:softstore_buyer_app/features/product/screens/product_detail_screen.dart';

/// Offline widget tests for the enhanced Product Detail Screen.
///
/// Note: the detail network fetch fails silently in the test environment,
/// so these tests exercise widget-level data (Product seed) and UI logic.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  /// Large viewport so below-the-fold widgets are tappable.
  void useLargeViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  late CartCubit cartCubit;
  late AuthCubit authCubit;

  setUp(() {
    cartCubit = CartCubit();
    authCubit = AuthCubit();
  });

  tearDown(() {
    cartCubit.close();
    authCubit.close();
  });

  Widget createTestApp({
    required String slug,
    required String name,
    required int price,
    String? sellerSlug,
    String? sellerName,
    int? sellerId,
    Product? product,
    bool authenticated = false,
  }) {
    if (authenticated) {
      authCubit.emit(const AuthAuthenticated(User(
        id: 'u1',
        firstName: 'Test',
        lastName: 'Buyer',
        email: 'buyer@test.pk',
        isEmailVerified: true,
      )));
    }

    final router = GoRouter(
      initialLocation: '/product/$slug',
      routes: [
        GoRoute(
          path: '/product/:slug',
          builder: (context, state) => ProductDetailScreen(
            slug: slug,
            name: name,
            price: price,
            iconCodePoint: Icons.shopping_bag.codePoint,
            sellerSlug: sellerSlug,
            sellerName: sellerName,
            sellerId: sellerId,
            product: product,
          ),
        ),
        GoRoute(
          path: '/checkout',
          builder: (context, state) =>
              const Scaffold(body: Text('Checkout Stub')),
        ),
        GoRoute(
          path: '/seller/:slug',
          builder: (context, state) => Scaffold(
            body: Text('SellerPage: ${state.pathParameters['slug']}'),
          ),
        ),
      ],
    );

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: cartCubit),
        BlocProvider.value(value: authCubit),
      ],
      child: MaterialApp.router(routerConfig: router),
    );
  }

  /// Reads the quantity value shown between the - / + buttons.
  int displayedQuantity(WidgetTester tester) {
    final qtyRow = find.ancestor(
      of: find.byIcon(Icons.add_rounded),
      matching: find.byType(Row),
    );
    final texts = find.descendant(of: qtyRow, matching: find.byType(Text));
    for (final w in tester.widgetList<Text>(texts)) {
      final v = int.tryParse(w.data ?? '');
      if (v != null && w.style?.fontSize != null) return v;
    }
    return -1;
  }

  group('Product header', () {
    testWidgets(
        'shows real price, share button, stock status, quantity selector',
        (tester) async {
      useLargeViewport(tester);
      await tester.pumpWidget(createTestApp(
        slug: 'wireless-earbuds',
        name: 'Wireless Earbuds',
        price: 2500,
        sellerSlug: 'gadget-hub',
        sellerName: 'Gadget Hub',
      ));
      await tester.pump();

      // Price comes from passed product data, not hardcoded
      expect(find.textContaining('2,500'), findsWidgets);
      // No hardcoded discount badge without discount data
      expect(find.text('-20%'), findsNothing);
      // Stock status defaults to In stock when unknown
      expect(find.text('In stock'), findsOneWidget);
      // Share button present
      expect(find.byIcon(Icons.share_outlined), findsOneWidget);
      // Quantity selector starts at minimum
      expect(find.text('Quantity'), findsOneWidget);
      expect(displayedQuantity(tester), 1);
    });

    testWidgets('shows delivery, COD and returns information card',
        (tester) async {
      useLargeViewport(tester);
      await tester.pumpWidget(createTestApp(
        slug: 'wireless-earbuds',
        name: 'Wireless Earbuds',
        price: 2500,
      ));
      await tester.pump();

      expect(find.text('Delivery'), findsOneWidget);
      expect(find.textContaining('Free delivery on orders over'),
          findsOneWidget);
      expect(find.text('Cash on Delivery'), findsOneWidget);
      expect(find.textContaining('Pay the rider when your order arrives'),
          findsOneWidget);
      expect(find.text('Returns'), findsOneWidget);
      expect(find.textContaining('within 7 days of delivery'),
          findsOneWidget);
    });

    testWidgets('shows discount badge computed from real discount data',
        (tester) async {
      useLargeViewport(tester);
      const product = Product(
        id: 101,
        name: 'Discounted Item',
        slug: 'discounted-item',
        displayPrice: 800,
        listPrice: 1000,
        discountPercent: 20,
      );

      await tester.pumpWidget(createTestApp(
        slug: 'discounted-item',
        name: 'Discounted Item',
        price: 800,
        product: product,
      ));
      await tester.pump();

      expect(find.text('-20%'), findsOneWidget);
    });
  });

  group('Quantity selector', () {
    testWidgets('increment increases quantity', (tester) async {
      useLargeViewport(tester);
      await tester.pumpWidget(createTestApp(
        slug: 'wireless-earbuds',
        name: 'Wireless Earbuds',
        price: 2500,
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();

      expect(displayedQuantity(tester), 3);
    });

    testWidgets('decrement cannot go below minimum of 1', (tester) async {
      useLargeViewport(tester);
      await tester.pumpWidget(createTestApp(
        slug: 'wireless-earbuds',
        name: 'Wireless Earbuds',
        price: 2500,
      ));
      await tester.pump();

      final remove = find.byIcon(Icons.remove_rounded);
      // At minimum, decrement is disabled
      final removeBtn = tester.widget<GestureDetector>(
        find.ancestor(of: remove, matching: find.byType(GestureDetector)),
      );
      expect(removeBtn.onTap, isNull);

      await tester.tap(remove);
      await tester.pump();
      expect(displayedQuantity(tester), 1);

      // Increment then decrement returns to minimum
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      expect(displayedQuantity(tester), 2);
      final enabledRemove = tester.widget<GestureDetector>(
        find.ancestor(of: remove, matching: find.byType(GestureDetector)),
      );
      expect(enabledRemove.onTap, isNotNull);
      await tester.tap(remove);
      await tester.pump();
      expect(displayedQuantity(tester), 1);
    });
  });

  group('Add to Cart', () {
    testWidgets('adds correct product with selected quantity',
        (tester) async {
      useLargeViewport(tester);
      const testProduct = Product(
        id: 101,
        name: 'Wireless Earbuds',
        slug: 'wireless-earbuds',
        displayPrice: 2500,
      );

      await tester.pumpWidget(createTestApp(
        slug: 'wireless-earbuds',
        name: 'Wireless Earbuds',
        price: 2500,
        product: testProduct,
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Add to Cart'));
      await tester.pumpAndSettle();

      expect(cartCubit.state.items, isNotEmpty);
      expect(cartCubit.state.items.first.productId, 101);
      expect(cartCubit.state.items.first.quantity, 3);
    });

    testWidgets('unknown stock keeps Add to Cart enabled as fallback',
        (tester) async {
      useLargeViewport(tester);
      await tester.pumpWidget(createTestApp(
        slug: 'mystery-item',
        name: 'Mystery Item',
        price: 900,
      ));
      await tester.pumpAndSettle();

      final addButton = tester.widget<ElevatedButton>(
        find.ancestor(
            of: find.text('Add to Cart'),
            matching: find.byType(ElevatedButton)),
      );
      expect(addButton.onPressed, isNotNull);
    });
  });

  group('Buy Now', () {
    testWidgets('checks out ONLY current product with selected quantity',
        (tester) async {
      useLargeViewport(tester);
      // Pre-existing selected item from another page must be excluded
      await cartCubit.clearCart();
      await cartCubit.addItem(const CartItem(
        uuid: 'other-item',
        productId: 999,
        productName: 'Other Product',
        quantity: 4,
        unitPriceSnapshot: 100.0,
      ));
      cartCubit.selectAll();
      expect(cartCubit.state.selectedIds, isNotEmpty);

      const testProduct = Product(
        id: 101,
        name: 'Wireless Earbuds',
        slug: 'wireless-earbuds',
        displayPrice: 2500,
      );

      await tester.pumpWidget(createTestApp(
        slug: 'wireless-earbuds',
        name: 'Wireless Earbuds',
        price: 2500,
        product: testProduct,
        authenticated: true,
      ));
      await tester.pump();

      await tester.tap(find.byIcon(Icons.add_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Buy Now'));
      await tester.pumpAndSettle();

      // Checkout stub reached
      expect(find.text('Checkout Stub'), findsOneWidget);

      // Only the Buy Now item selected, with chosen quantity
      final selected = cartCubit.state.selectedItems;
      expect(selected.length, 1);
      expect(selected.first.productId, 101);
      expect(selected.first.quantity, 2);

      // Other item still in cart, just not selected
      expect(cartCubit.state.items.any((i) => i.productId == 999), isTrue);
    });
  });

  group('Reviews section', () {
    testWidgets('overview shows empty reviews state with write action',
        (tester) async {
      useLargeViewport(tester);
      await tester.pumpWidget(createTestApp(
        slug: 'no-reviews-item',
        name: 'No Reviews Item',
        price: 1200,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Reviews (0)'), findsOneWidget);
      expect(find.text('Write a Review'), findsOneWidget);
    });

    testWidgets(
        'ratings tab shows error state and always-available store card',
        (tester) async {
      useLargeViewport(tester);
      await tester.pumpWidget(createTestApp(
        slug: 'no-reviews-item',
        name: 'No Reviews Item',
        price: 1200,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Ratings'));
      await tester.pumpAndSettle();

      // Detail fetch fails offline -> reviews show error state with retry
      expect(find.text('Reviews (0)'), findsOneWidget);
      expect(find.text('Unable to load reviews.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      // Store section is ALWAYS visible regardless of review load state
      expect(find.text('Visit Store'), findsOneWidget);
    });

    testWidgets('write review sheet opens for authenticated user',
        (tester) async {
      useLargeViewport(tester);
      await tester.pumpWidget(createTestApp(
        slug: 'no-reviews-item',
        name: 'No Reviews Item',
        price: 1200,
        authenticated: true,
      ));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Write a Review').first);
      await tester.pumpAndSettle();

      expect(find.text('Submit Review'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);

      // Close the sheet
      await tester.tap(find.byIcon(Icons.close).last);
      await tester.pumpAndSettle();
      expect(find.text('Submit Review'), findsNothing);
    });
  });

  group('Store section', () {
    testWidgets(
        'overview store card shows current product store and navigates',
        (tester) async {
      useLargeViewport(tester);
      const testProduct = Product(
        id: 103,
        name: 'Gaming Mouse',
        slug: 'gaming-mouse',
        displayPrice: 3200,
        seller: SellerStub(id: 15, name: 'Gear Zone', slug: 'gear-zone'),
      );

      await tester.pumpWidget(createTestApp(
        slug: 'gaming-mouse',
        name: 'Gaming Mouse',
        price: 3200,
        sellerSlug: 'gear-zone',
        sellerName: 'Gear Zone',
        product: testProduct,
      ));
      await tester.pumpAndSettle();

      expect(find.text('Gear Zone'), findsOneWidget);
      await tester.tap(find.text('Visit Store'));
      await tester.pumpAndSettle();

      expect(find.text('SellerPage: gear-zone'), findsOneWidget);
    });
  });
}
