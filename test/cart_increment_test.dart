import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:softstore_buyer_app/features/cart/cubit/cart_cubit.dart';
import 'package:softstore_buyer_app/features/cart/models/cart_models.dart';
import 'package:softstore_buyer_app/features/cart/screens/cart_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('CartItem equality detects quantity changes', () {
    const item1 = CartItem(
      uuid: 'item_1',
      productId: 101,
      productName: 'Sample Product',
      quantity: 1,
      unitPriceSnapshot: 500.0,
    );

    final item2 = item1.copyWith(quantity: 2);

    expect(item1 == item2, isFalse,
        reason: 'Items with different quantities must not be equal');
    expect(item2.quantity, 2);
  });

  test('CartCubit updates and increments quantity', () async {
    final cubit = CartCubit();
    await cubit.clearCart();

    const item = CartItem(
      uuid: 'item_1',
      productId: 101,
      productName: 'Sample Product',
      quantity: 1,
      unitPriceSnapshot: 500.0,
    );

    await cubit.addItem(item);
    expect(cubit.state.items.first.quantity, 1);

    await cubit.updateQuantity('item_1', 2);
    expect(cubit.state.items.first.quantity, 2);

    await cubit.updateQuantity('item_1', 3);
    expect(cubit.state.items.first.quantity, 3);
  });

  testWidgets('CartScreen + button increments item quantity in UI',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final cartCubit = CartCubit();
    await cartCubit.clearCart();
    await cartCubit.addItem(const CartItem(
      uuid: 'item_1',
      productId: 101,
      productName: 'Sample Product',
      quantity: 1,
      unitPriceSnapshot: 500.0,
    ));

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<CartCubit>.value(
          value: cartCubit,
          child: const CartScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1'), findsWidgets);
    expect(find.byIcon(Icons.add), findsWidgets);

    // Tap the '+' button in the cart item tile
    await tester.tap(find.byIcon(Icons.add).first);
    await tester.pumpAndSettle();

    // Verify quantity incremented to 2 in the state and UI
    expect(cartCubit.state.items.first.quantity, 2);
    expect(find.text('2'), findsWidgets);
  });

  testWidgets('CartScreen Select All checkbox selects and deletes all items',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final cartCubit = CartCubit();
    await cartCubit.clearCart();
    await cartCubit.addItem(const CartItem(
      uuid: 'item_1',
      productId: 101,
      productName: 'Product 1',
      quantity: 1,
      unitPriceSnapshot: 500.0,
    ));
    await cartCubit.addItem(const CartItem(
      uuid: 'item_2',
      productId: 102,
      productName: 'Product 2',
      quantity: 2,
      unitPriceSnapshot: 1000.0,
    ));

    await tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<CartCubit>.value(
          value: cartCubit,
          child: const CartScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Select All bar is visible
    expect(find.text('Select All (2 items)'), findsOneWidget);

    // Tap Select All
    await tester.tap(find.text('Select All (2 items)'));
    await tester.pumpAndSettle();

    // Verify Delete (2) button appears
    expect(find.text('Delete (2)'), findsOneWidget);
    expect(find.text('Deselect All (2)'), findsOneWidget);

    // Tap Delete (2)
    await tester.tap(find.text('Delete (2)'));
    await tester.pumpAndSettle();

    // Verify all items are removed and empty view is shown
    expect(cartCubit.state.items.isEmpty, isTrue);
    expect(find.text('There are no items in this cart'), findsOneWidget);
  });
}
