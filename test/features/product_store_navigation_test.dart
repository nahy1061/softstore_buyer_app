import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:softstore_buyer_app/features/auth/cubit/auth_cubit.dart';
import 'package:softstore_buyer_app/features/cart/cubit/cart_cubit.dart';
import 'package:softstore_buyer_app/features/catalog/models/catalog_models.dart';
import 'package:softstore_buyer_app/features/catalog/screens/seller_screen.dart';
import 'package:softstore_buyer_app/features/product/screens/product_detail_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Product → Store Relationship Models', () {
    test('SellerStub model serialization and props', () {
      const seller = SellerStub(id: 42, name: 'Tech Store PK', slug: 'tech-store-pk');

      expect(seller.id, 42);
      expect(seller.name, 'Tech Store PK');
      expect(seller.slug, 'tech-store-pk');

      final json = seller.toJson();
      expect(json['id'], 42);
      expect(json['name'], 'Tech Store PK');
      expect(json['slug'], 'tech-store-pk');

      final fromJson = SellerStub.fromJson(json);
      expect(fromJson, equals(seller));
    });

    test('Product model store getters and serialization', () {
      const seller = SellerStub(id: 10, name: 'Gadget World', slug: 'gadget-world');
      const product = Product(
        id: 101,
        name: 'Wireless Earbuds',
        slug: 'wireless-earbuds',
        displayPrice: 2500.0,
        seller: seller,
      );

      // Verify store getters
      expect(product.storeId, 10);
      expect(product.sellerId, 10);
      expect(product.storeSlug, 'gadget-world');
      expect(product.sellerSlug, 'gadget-world');
      expect(product.storeName, 'Gadget World');
      expect(product.sellerName, 'Gadget World');

      final json = product.toJson();
      expect(json['seller_id'], 10);
      expect(json['seller_name'], 'Gadget World');
      expect(json['seller_slug'], 'gadget-world');

      final restored = Product.fromJson(json);
      expect(restored.seller?.id, 10);
      expect(restored.seller?.name, 'Gadget World');
      expect(restored.seller?.slug, 'gadget-world');
    });

    test('Product.fromJson parses alternative seller formats', () {
      // 1. Nested map
      final p1 = Product.fromJson({
        'id': 1,
        'name': 'Test 1',
        'slug': 'test-1',
        'displayPrice': 500,
        'seller': {'id': 5, 'name': 'Alpha Store', 'slug': 'alpha-store'},
      });
      expect(p1.sellerId, 5);
      expect(p1.sellerName, 'Alpha Store');
      expect(p1.sellerSlug, 'alpha-store');

      // 2. Flat seller_name / seller_slug / seller_id
      final p2 = Product.fromJson({
        'id': 2,
        'product_name': 'Test 2',
        'slug': 'test-2',
        'selling_price': '750',
        'seller_name': 'Beta Store',
        'seller_slug': 'beta-store',
        'seller_id': 9,
      });
      expect(p2.sellerId, 9);
      expect(p2.sellerName, 'Beta Store');
      expect(p2.sellerSlug, 'beta-store');

      // 3. String seller
      final p3 = Product.fromJson({
        'id': 3,
        'name': 'Test 3',
        'slug': 'test-3',
        'price': 1000,
        'seller': 'Gamma Traders',
      });
      expect(p3.sellerName, 'Gamma Traders');
      expect(p3.sellerSlug, 'gamma-traders');
    });

    test('ProductDetail store convenience getters', () {
      const seller = SellerStub(id: 15, name: 'Prime Goods', slug: 'prime-goods');
      const detail = ProductDetail(
        id: 202,
        name: 'Smart Watch Pro',
        slug: 'smart-watch-pro',
        displayPrice: 4500.0,
        seller: seller,
      );

      expect(detail.storeId, 15);
      expect(detail.sellerId, 15);
      expect(detail.storeSlug, 'prime-goods');
      expect(detail.sellerSlug, 'prime-goods');
      expect(detail.storeName, 'Prime Goods');
      expect(detail.sellerName, 'Prime Goods');
    });
  });

  group('Product Detail Screen - Store Button UI & Navigation', () {
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
      GoRouter? customRouter,
    }) {
      final router = customRouter ??
          GoRouter(
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
                path: '/seller/:slug',
                builder: (context, state) {
                  final sSlug = state.pathParameters['slug'] ?? '';
                  final extra = state.extra as Map<String, dynamic>? ?? {};
                  return Scaffold(
                    body: Column(
                      children: [
                        Text('SellerPage: $sSlug'),
                        Text('SellerName: ${extra['sellerName']}'),
                        if (extra['product'] != null)
                          Text('Product: ${(extra['product'] as Product).name}'),
                      ],
                    ),
                  );
                },
              ),
            ],
          );

      return MultiBlocProvider(
        providers: [
          BlocProvider.value(value: cartCubit),
          BlocProvider.value(value: authCubit),
        ],
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('Store button is present in bottom navigation bar', (tester) async {
      await tester.pumpWidget(
        createTestApp(
          slug: 'wireless-earbuds',
          name: 'Wireless Earbuds',
          price: 2500,
          sellerSlug: 'gadget-hub',
          sellerName: 'Gadget Hub',
        ),
      );
      await tester.pump();

      // Find the Store button with store icon and label
      expect(find.text('Store'), findsOneWidget);
      expect(find.byIcon(Icons.store_outlined), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      expect(find.text('Buy Now'), findsOneWidget);
      expect(find.text('Add to Cart'), findsOneWidget);
    });

    testWidgets('Tapping Store button navigates to seller page with correct slug and extra',
        (tester) async {
      const testProduct = Product(
        id: 101,
        name: 'Wireless Earbuds',
        slug: 'wireless-earbuds',
        displayPrice: 2500,
        seller: SellerStub(id: 7, name: 'Gadget Hub', slug: 'gadget-hub'),
      );

      await tester.pumpWidget(
        createTestApp(
          slug: 'wireless-earbuds',
          name: 'Wireless Earbuds',
          price: 2500,
          sellerSlug: 'gadget-hub',
          sellerName: 'Gadget Hub',
          product: testProduct,
        ),
      );
      await tester.pump();

      // Tap Store button in bottom bar
      final storeButton = find.text('Store');
      expect(storeButton, findsOneWidget);
      await tester.tap(storeButton);
      await tester.pumpAndSettle();

      // Verify navigation to seller page with correct store slug and product info
      expect(find.text('SellerPage: gadget-hub'), findsOneWidget);
      expect(find.text('SellerName: Gadget Hub'), findsOneWidget);
      expect(find.text('Product: Wireless Earbuds'), findsOneWidget);
    });

    testWidgets('Tapping floating store icon in gallery navigates to store', (tester) async {
      const testProduct = Product(
        id: 102,
        name: 'Mechanical Keyboard',
        slug: 'mech-keyboard',
        displayPrice: 6500,
        seller: SellerStub(id: 12, name: 'Keyboards Pro', slug: 'keyboards-pro'),
      );

      await tester.pumpWidget(
        createTestApp(
          slug: 'mech-keyboard',
          name: 'Mechanical Keyboard',
          price: 6500,
          sellerSlug: 'keyboards-pro',
          sellerName: 'Keyboards Pro',
          product: testProduct,
        ),
      );
      await tester.pump();

      // Tap the floating storefront icon on top of the image
      final floatingStoreIcon = find.byIcon(Icons.storefront_outlined);
      expect(floatingStoreIcon, findsOneWidget);
      await tester.tap(floatingStoreIcon);
      await tester.pumpAndSettle();

      expect(find.text('SellerPage: keyboards-pro'), findsOneWidget);
      expect(find.text('SellerName: Keyboards Pro'), findsOneWidget);
    });

    testWidgets('Tapping Visit Store in Ratings tab navigates to store', (tester) async {
      const testProduct = Product(
        id: 103,
        name: 'Gaming Mouse',
        slug: 'gaming-mouse',
        displayPrice: 3200,
        seller: SellerStub(id: 15, name: 'Gear Zone', slug: 'gear-zone'),
      );

      await tester.pumpWidget(
        createTestApp(
          slug: 'gaming-mouse',
          name: 'Gaming Mouse',
          price: 3200,
          sellerSlug: 'gear-zone',
          sellerName: 'Gear Zone',
          product: testProduct,
        ),
      );
      await tester.pump();

      // Switch to Ratings tab
      final ratingsTab = find.text('Ratings');
      expect(ratingsTab, findsOneWidget);
      await tester.tap(ratingsTab);
      await tester.pumpAndSettle();

      // Tap Visit Store button
      final visitStoreButton = find.text('Visit Store');
      expect(visitStoreButton, findsOneWidget);
      await tester.tap(visitStoreButton);
      await tester.pumpAndSettle();

      expect(find.text('SellerPage: gear-zone'), findsOneWidget);
      expect(find.text('SellerName: Gear Zone'), findsOneWidget);
    });
  });

  group('SellerScreen UI and Products Isolation', () {
    late AuthCubit authCubit;

    setUp(() {
      authCubit = AuthCubit();
    });

    tearDown(() {
      authCubit.close();
    });

    testWidgets('SellerScreen builds with store details and initial product', (tester) async {
      const initialProduct = Product(
        id: 999,
        name: 'Exclusive Store Item',
        slug: 'exclusive-item',
        displayPrice: 1500,
      );

      await tester.pumpWidget(
        BlocProvider.value(
          value: authCubit,
          child: const MaterialApp(
            home: SellerScreen(
              slug: 'test-store',
              sellerName: 'Test Official Store',
              initialProduct: initialProduct,
            ),
          ),
        ),
      );

      // Pump to allow async _loadSeller fallback
      await tester.pumpAndSettle();

      // Verify store name is displayed
      expect(find.text('Test Official Store'), findsOneWidget);
      // Verify Follow button exists
      expect(find.text('Follow'), findsOneWidget);
      // Verify Tabs exist
      expect(find.text('Products'), findsOneWidget);
      expect(find.text('Categories'), findsOneWidget);
      expect(find.text('Chat'), findsOneWidget);
      // Verify initial product is displayed in the products grid
      expect(find.text('Exclusive Store Item'), findsOneWidget);
    });
  });
}
