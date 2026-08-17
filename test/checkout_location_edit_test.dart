import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:softstore_buyer/features/cart/cubit/cart_cubit.dart';
import 'package:softstore_buyer/features/cart/models/cart_item.dart';
import 'package:softstore_buyer/features/cart/screens/cart_screen.dart';

void main() {
  testWidgets('Checkout sheet displays Edit button and updates delivery location from saved address',
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

    // Verify initial delivery location is displayed
    expect(find.text('Muhammad Khalid, 03408014187'), findsOneWidget);
    expect(find.text('HOME'), findsOneWidget);
    expect(
        find.text('House 12, Street 4, Model Town, Lahore, Punjab'), findsOneWidget);

    // Verify EDIT button is present in front of location
    final editButtonFinder = find.widgetWithText(OutlinedButton, 'EDIT');
    expect(editButtonFinder, findsOneWidget);

    // Tap EDIT button to open location edit sheet
    await tester.tap(editButtonFinder);
    await tester.pumpAndSettle();

    // Verify Edit Delivery Location bottom sheet is visible
    expect(find.text('Edit Delivery Location'), findsOneWidget);
    expect(find.text('Saved Addresses'), findsOneWidget);
    expect(find.text('Location Details'), findsOneWidget);

    // Select the 'OFFICE' saved address
    final officeTileFinder = find.text('Office 401, Plaza 33, Main Boulevard, Gulberg III, Lahore, Punjab\nPhone: 03408014187');
    expect(officeTileFinder, findsOneWidget);
    await tester.tap(officeTileFinder);
    await tester.pumpAndSettle();

    // Save Location
    final saveButtonFinder = find.widgetWithText(ElevatedButton, 'Save Location');
    expect(saveButtonFinder, findsOneWidget);
    await tester.tap(saveButtonFinder);
    await tester.pumpAndSettle();

    // Verify checkout screen is updated with the edited/selected location
    expect(find.text('OFFICE'), findsOneWidget);
    expect(
        find.text('Office 401, Plaza 33, Main Boulevard, Gulberg III, Lahore, Punjab'),
        findsOneWidget);
  });

  testWidgets('Checkout sheet allows editing custom location fields manually',
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

    // Tap location directly to open edit sheet
    final locationFinder = find.text('House 12, Street 4, Model Town, Lahore, Punjab');
    await tester.tap(locationFinder);
    await tester.pumpAndSettle();

    // Select 'OTHER' chip
    final otherChipFinder = find.widgetWithText(ChoiceChip, 'OTHER');
    expect(otherChipFinder, findsOneWidget);
    await tester.ensureVisible(otherChipFinder);
    await tester.pumpAndSettle();
    await tester.tap(otherChipFinder);
    await tester.pumpAndSettle();

    // Edit full name
    final nameFieldFinder = find.widgetWithText(TextFormField, 'Muhammad Khalid');
    await tester.ensureVisible(nameFieldFinder);
    await tester.enterText(nameFieldFinder, 'Ali Hassan');

    // Edit street address
    final streetFieldFinder =
        find.widgetWithText(TextFormField, 'House 12, Street 4, Model Town');
    await tester.ensureVisible(streetFieldFinder);
    await tester.enterText(streetFieldFinder, 'Flat 5B, Sky View Towers, F-11');

    // Edit city
    final cityFieldFinder = find.widgetWithText(TextFormField, 'Lahore');
    await tester.ensureVisible(cityFieldFinder);
    await tester.enterText(cityFieldFinder, 'Islamabad');

    // Edit province
    final provinceFieldFinder = find.widgetWithText(TextFormField, 'Punjab');
    await tester.ensureVisible(provinceFieldFinder);
    await tester.enterText(provinceFieldFinder, 'ICT');

    // Save
    final saveBtn = find.widgetWithText(ElevatedButton, 'Save Location');
    await tester.tap(saveBtn);
    await tester.pumpAndSettle();

    // Verify updated details on checkout sheet
    expect(find.text('Ali Hassan, 03408014187'), findsOneWidget);
    expect(find.text('OTHER'), findsOneWidget);
    expect(
        find.text('Flat 5B, Sky View Towers, F-11, Islamabad, ICT'),
        findsOneWidget);
  });
}
