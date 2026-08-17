import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:softstore_buyer/features/cart/cubit/cart_cubit.dart';
import 'package:softstore_buyer/features/cart/models/cart_item.dart';
import 'package:softstore_buyer/features/cart/screens/cart_screen.dart';

void main() {
  testWidgets(
      'Requires selecting a delivery method before proceeding to payment',
      (WidgetTester tester) async {
    final cartCubit = CartCubit();
    cartCubit.addItem(CartItem(
      id: '1',
      productId: '1',
      productName: 'Wireless Earbuds',
      quantity: 1,
      unitPriceSnapshot: 4500,
      subtotalSnapshot: 4500,
      iconCodePoint: Icons.headphones.codePoint,
    ));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider<CartCubit>.value(
            value: cartCubit,
            child: const CartCheckoutSheet(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Verify delivery method section indicates required status
    expect(find.text('Delivery Method'), findsOneWidget);
    expect(find.text('REQUIRED'), findsOneWidget);
    expect(find.text('Please select a delivery method'), findsOneWidget);
    expect(find.text('Not selected'), findsOneWidget);

    // Try tapping "Proceed to Pay" without selecting delivery method
    final proceedButton = find.widgetWithText(ElevatedButton, 'Proceed to Pay');
    expect(proceedButton, findsOneWidget);
    await tester.tap(proceedButton);
    await tester.pumpAndSettle();

    // Verify SnackBar validation warning was shown
    expect(
        find.text('Please select a delivery method before proceeding to pay'),
        findsOneWidget);

    // Verify Delivery Method picker sheet was opened automatically
    expect(find.text('Select Delivery Method'), findsOneWidget);
    expect(find.text('Standard Delivery'), findsOneWidget);
    expect(find.text('Express Delivery'), findsOneWidget);
    expect(find.text('Collection Point / Pickup Station'), findsOneWidget);
    expect(find.text('Economy Saver'), findsOneWidget);

    // Verify payment sheet is NOT open yet
    expect(find.text('Select Payment Method'), findsNothing);

    // Select "Express Delivery" option
    final expressOptionFinder = find.text('Express Delivery');
    await tester.tap(expressOptionFinder);
    await tester.pumpAndSettle();

    // Confirm selection
    final confirmButtonFinder =
        find.widgetWithText(ElevatedButton, 'Confirm Delivery Method');
    expect(confirmButtonFinder, findsOneWidget);
    await tester.tap(confirmButtonFinder);
    await tester.pumpAndSettle();

    // Delivery picker sheet is closed
    expect(find.text('Select Delivery Method'), findsNothing);

    // Verify checkout screen updated with selected delivery method
    expect(find.text('REQUIRED'), findsNothing);
    expect(find.text('CHANGE'), findsOneWidget);
    expect(find.text('Express Delivery'), findsOneWidget);
    expect(find.text('PKR 450'), findsWidgets);

    // Now tap "Proceed to Pay" with delivery method selected
    await tester.tap(proceedButton);
    await tester.pumpAndSettle();

    // Verify Payment Method sheet is opened successfully
    expect(find.text('Select Payment Method'), findsOneWidget);
    expect(find.text('Credit/Debit Card'), findsOneWidget);
    expect(find.text('Cash on Delivery'), findsOneWidget);
  });
}
