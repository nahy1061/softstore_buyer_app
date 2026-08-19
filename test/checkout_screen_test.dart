import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:softstore_buyer_app/features/auth/cubit/auth_cubit.dart';
import 'package:softstore_buyer_app/features/cart/cubit/cart_cubit.dart';
import 'package:softstore_buyer_app/features/cart/models/cart_models.dart';
import 'package:softstore_buyer_app/features/checkout/screens/checkout_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'CheckoutScreen renders delivery form without email OTP field and places order',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final cartCubit = CartCubit();
    cartCubit.addItem(const CartItem(
      uuid: 'item_1',
      productId: 101,
      productName: 'Sample Product',
      quantity: 2,
      unitPriceSnapshot: 500.0,
    ));

    final authCubit = AuthCubit();

    await tester.pumpWidget(
      MaterialApp(
        home: MultiBlocProvider(
          providers: [
            BlocProvider<CartCubit>.value(value: cartCubit),
            BlocProvider<AuthCubit>.value(value: authCubit),
          ],
          child: const CheckoutScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify UI components
    expect(find.text('Checkout'), findsOneWidget);
    expect(find.text('Delivery Address'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Phone (03XXXXXXXXX)'), findsOneWidget);
    expect(find.text('Full delivery address'), findsOneWidget);
    expect(find.text('Place Order'), findsOneWidget);

    // Verify Email OTP field is NOT present
    expect(find.text('Email (for order OTP verification)'), findsNothing);
    expect(find.text('Verify OTP'), findsNothing);

    // Fill in delivery form
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name').first,
        'Muhammad Ali');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone (03XXXXXXXXX)').first,
        '03001234567');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Full delivery address').first,
        'House 1, Street 2, Lahore');
    await tester.pumpAndSettle();

    // Tap Place Order
    final placeOrderBtn = find.widgetWithText(ElevatedButton, 'Place Order');
    expect(placeOrderBtn, findsOneWidget);
    await tester.ensureVisible(placeOrderBtn);
    await tester.tap(placeOrderBtn);
    await tester.pump();

    // Verify no OTP dialog is prompted
    expect(find.text('Verify Your Email'), findsNothing);
  });
}
