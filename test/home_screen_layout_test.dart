import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:softstore_buyer/features/auth/cubit/auth_cubit.dart';
import 'package:softstore_buyer/features/cart/cubit/cart_cubit.dart';
import 'package:softstore_buyer/features/home/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen builds, scrolls, and hit-tests all components without errors', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(() => tester.view.resetPhysicalSize());

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider(create: (_) => AuthCubit()),
          BlocProvider(create: (_) => CartCubit()),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // 1. Verify all static components render
    expect(find.byType(HomeScreen), findsOneWidget);
    expect(find.text('Safe Payment'), findsOneWidget);
    expect(find.text('Fast Delivery'), findsOneWidget);
    expect(find.text('Free Return'), findsOneWidget);
    expect(find.text('General Store Items'), findsWidgets);

    // 2. Hit-test: Tap on Search TextField
    final searchField = find.byType(TextField);
    expect(searchField, findsOneWidget);
    await tester.tap(searchField);
    await tester.pump();

    // 3. Hit-test: Type search query
    await tester.enterText(searchField, 'Vichy');
    await tester.pump();

    // 4. Hit-test: Tap Search button
    final searchBtn = find.text('Search');
    expect(searchBtn, findsOneWidget);
    await tester.tap(searchBtn);
    await tester.pump();

    // 5. Hit-test: Tap on clear filter if present
    final clearBtn = find.text('Clear Filter');
    if (clearBtn.evaluate().isNotEmpty) {
      await tester.tap(clearBtn);
      await tester.pump();
    }

    // 6. Hit-test: Scroll vertically through all category rails
    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, -500));
    await tester.pump();

    await tester.drag(find.byType(SingleChildScrollView), const Offset(0, 500));
    await tester.pump();
  });
}
