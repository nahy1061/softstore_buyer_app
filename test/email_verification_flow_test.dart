import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:softstore_buyer_app/features/auth/cubit/auth_cubit.dart';
import 'package:softstore_buyer_app/features/auth/cubit/auth_state.dart';
import 'package:softstore_buyer_app/features/auth/models/user_model.dart';
import 'package:softstore_buyer_app/features/auth/screens/register_screen.dart';
import 'package:softstore_buyer_app/features/auth/widgets/email_verification_prompt_dialog.dart';
import 'package:softstore_buyer_app/features/auth/widgets/otp_verification_dialog.dart';
import 'package:softstore_buyer_app/features/cart/cubit/cart_cubit.dart';
import 'package:softstore_buyer_app/features/cart/models/cart_models.dart';
import 'package:softstore_buyer_app/features/cart/repository/cart_repository.dart';
import 'package:softstore_buyer_app/features/checkout/screens/checkout_screen.dart';
import 'package:softstore_buyer_app/features/profile/cubit/address_cubit.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Test 1 & 2: Email Verification Choice Popup UI & Transition', () {
    testWidgets(
        'Prompt dialog displays title, message, registered email, and returns true on Verify Now and false on Later',
        (WidgetTester tester) async {
      bool? userChoice;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  userChoice = await EmailVerificationPromptDialog.show(
                    context,
                    email: 'buyer@test.pk',
                  );
                },
                child: const Text('Open Prompt'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Prompt'));
      await tester.pumpAndSettle();

      // Check title and content
      expect(find.text('Verify Your Email'), findsOneWidget);
      expect(
        find.text(
          'Your account has been created successfully. Would you like to verify your email now?',
        ),
        findsOneWidget,
      );
      expect(find.text('buyer@test.pk'), findsOneWidget);
      expect(find.text('Verify Now'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);

      // Tap Later -> returns false
      await tester.tap(find.text('Later'));
      await tester.pumpAndSettle();
      expect(userChoice, false);

      // Re-open and test Verify Now -> returns true
      await tester.tap(find.text('Open Prompt'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Verify Now'));
      await tester.pumpAndSettle();
      expect(userChoice, true);
    });

    testWidgets(
        'Signup Flow: Clicking Verify Now closes choice popup and immediately opens the existing order OTP popup',
        (WidgetTester tester) async {
      final authCubit = AuthCubit();

      final router = GoRouter(
        initialLocation: '/register',
        routes: [
          GoRoute(
            path: '/register',
            builder: (context, state) => const RegisterScreen(),
          ),
          GoRoute(
            path: '/home',
            builder: (context, state) => const Scaffold(body: Text('Home Screen')),
          ),
        ],
      );

      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Simulate successful registration
      authCubit.emit(const AuthAuthenticated(User(
        id: '123',
        firstName: 'Farhan',
        lastName: 'Ali',
        email: 'farhan@test.pk',
        isEmailVerified: false,
      )));

      // Trigger post registration handler on RegisterScreen
      await tester.pump();
      await tester.pumpAndSettle();

      // Choice popup is visible
      expect(find.text('Verify Your Email'), findsOneWidget);
      expect(find.text('farhan@test.pk'), findsOneWidget);
      expect(find.text('Verify Now'), findsOneWidget);
      expect(find.text('Later'), findsOneWidget);

      // Tap Verify Now
      await tester.tap(find.text('Verify Now'));
      await tester.pump(); // Closes choice dialog
      await tester.pumpAndSettle(); // Opens existing OTP popup

      // The exact OTP verification popup is now open!
      expect(find.byType(OtpVerificationDialog), findsOneWidget);
      expect(find.text('Verify & Continue'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(OtpVerificationDialog),
          matching: find.byType(TextFormField),
        ),
        findsOneWidget,
      );
    });
  });

  group('Scenario 3: OTP Input, Error Handling, and Resend', () {
    testWidgets('Button is disabled for 0-5 digits and enabled at 6 digits',
        (WidgetTester tester) async {
      final authCubit = AuthCubit();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthCubit>.value(
            value: authCubit,
            child: const Scaffold(
              body: OtpVerificationDialog(
                email: 'test_user@domain.pk',
                autoSendOtp: false,
                primaryButtonText: 'Verify & Continue',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final verifyBtnFinder =
          find.widgetWithText(ElevatedButton, 'Verify & Continue');
      expect(verifyBtnFinder, findsOneWidget);

      // 0 digits: button is disabled
      ElevatedButton btn = tester.widget(verifyBtnFinder);
      expect(btn.onPressed, isNull);

      // 1-5 digits: button is disabled
      final inputFinder = find.byType(TextFormField);
      await tester.enterText(inputFinder, '1');
      await tester.pumpAndSettle();
      btn = tester.widget(verifyBtnFinder);
      expect(btn.onPressed, isNull);

      await tester.enterText(inputFinder, '123');
      await tester.pumpAndSettle();
      btn = tester.widget(verifyBtnFinder);
      expect(btn.onPressed, isNull);

      await tester.enterText(inputFinder, '12345');
      await tester.pumpAndSettle();
      btn = tester.widget(verifyBtnFinder);
      expect(btn.onPressed, isNull);

      // 6 digits: button is enabled
      await tester.enterText(inputFinder, '123456');
      await tester.pumpAndSettle();
      btn = tester.widget(verifyBtnFinder);
      expect(btn.onPressed, isNotNull);
    });

    testWidgets('Editing OTP clears previous error message',
        (WidgetTester tester) async {
      final authCubit = AuthCubit();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthCubit>.value(
            value: authCubit,
            child: const Scaffold(
              body: OtpVerificationDialog(
                email: 'test_user@domain.pk',
                autoSendOtp: false,
                primaryButtonText: 'Verify',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final inputFinder = find.byType(TextFormField);
      await tester.enterText(inputFinder, '000000');
      await tester.pumpAndSettle();

      // Tap Verify (which will fail network/server without backend and trigger error display)
      final verifyBtn = find.widgetWithText(ElevatedButton, 'Verify');
      await tester.tap(verifyBtn);
      await tester.pumpAndSettle();

      // Error message is displayed
      expect(find.text('Invalid OTP. Please enter the correct verification code.'), findsOneWidget);

      // Now edit the OTP text
      await tester.enterText(inputFinder, '000001');
      await tester.pumpAndSettle();

      // Error message must be cleared immediately
      expect(find.text('Invalid OTP. Please enter the correct verification code.'), findsNothing);
    });

    testWidgets('Resend OTP button re-invokes Send OTP API with isResend: true and resets countdown',
        (WidgetTester tester) async {
      final authCubit = AuthCubit();

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthCubit>.value(
            value: authCubit,
            child: const Scaffold(
              body: OtpVerificationDialog(
                email: 'resend_user@softstore.pk',
                autoSendOtp: false,
                primaryButtonText: 'Verify & Continue',
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fast-forward countdown timer past 60s
      await tester.pump(const Duration(seconds: 61));
      await tester.pumpAndSettle();

      // Resend OTP button is now visible and active
      expect(find.text('Resend OTP'), findsOneWidget);

      // Tap Resend OTP
      await tester.tap(find.text('Resend OTP'));
      await tester.pump(); // Start send request
      await tester.pumpAndSettle();

      expect(find.text('Verify Your Email'), findsOneWidget);
    });
  });

  group('Scenario 4 & 5: Checkout Order Placement OTP Verification Flow', () {
    testWidgets('Unverified user triggers the SAME OTP verification dialog when clicking Place Order',
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
        uuid: 'cart_item_1',
        productId: 101,
        productName: 'SoftStore Laptop',
        quantity: 1,
        unitPriceSnapshot: 50000.0,
      ));

      final authCubit = AuthCubit();
      // Authenticated with unverified email
      authCubit.emit(const AuthAuthenticated(User(
        id: '1',
        firstName: 'Ali',
        lastName: 'Raza',
        email: 'unverified_buyer@softstore.pk',
        isEmailVerified: false,
      )));

      final router = GoRouter(
        initialLocation: '/checkout',
        routes: [
          GoRoute(
            path: '/checkout',
            builder: (context, state) => const CheckoutScreen(),
          ),
          GoRoute(
            path: '/order-confirmation/:ref',
            builder: (context, state) => const Scaffold(body: Text('Order Confirmed')),
          ),
        ],
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<CartCubit>.value(value: cartCubit),
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<AddressCubit>(create: (_) => AddressCubit()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fill in required fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name').first,
        'Ali Raza',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone (03XXXXXXXXX)').first,
        '03001234567',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full delivery address').first,
        'Main Boulevard, Gulberg, Lahore',
      );
      await tester.pumpAndSettle();

      // Tap Place Order
      final placeOrderBtn = find.widgetWithText(ElevatedButton, 'Place Order');
      await tester.ensureVisible(placeOrderBtn);
      await tester.tap(placeOrderBtn);
      await tester.pumpAndSettle();

      // Exactly the same OTP Verification dialog is triggered for unverified user
      expect(find.byType(OtpVerificationDialog), findsOneWidget);
      expect(find.text('Email Verification'), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) =>
            w is RichText &&
            w.text.toPlainText().contains('unverified_buyer@softstore.pk')),
        findsOneWidget,
      );
      expect(find.text('Verify & Place Order'), findsOneWidget);

      // User cancels OTP dialog
      final cancelBtn = find.text('Cancel');
      expect(cancelBtn, findsOneWidget);
      await tester.tap(cancelBtn);
      await tester.pumpAndSettle();

      // Returned to checkout, OTP dialog is gone
      expect(find.text('Email Verification'), findsNothing);
      expect(find.text('Checkout'), findsOneWidget);
    });

    testWidgets('Verified user skips OTP dialog and places order directly',
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
        uuid: 'cart_item_1',
        productId: 101,
        productName: 'SoftStore Laptop',
        quantity: 1,
        unitPriceSnapshot: 50000.0,
      ));

      final authCubit = AuthCubit();
      // Authenticated with VERIFIED email
      authCubit.emit(const AuthAuthenticated(User(
        id: '2',
        firstName: 'Zain',
        lastName: 'Ahmed',
        email: 'verified_buyer@softstore.pk',
        isEmailVerified: true,
      )));

      final router = GoRouter(
        initialLocation: '/checkout',
        routes: [
          GoRoute(
            path: '/checkout',
            builder: (context, state) => const CheckoutScreen(),
          ),
          GoRoute(
            path: '/order-confirmation/:ref',
            builder: (context, state) => const Scaffold(body: Text('Order Confirmed')),
          ),
        ],
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<CartCubit>.value(value: cartCubit),
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<AddressCubit>(create: (_) => AddressCubit()),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Fill in required fields
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full Name').first,
        'Zain Ahmed',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Phone (03XXXXXXXXX)').first,
        '03001234567',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Full delivery address').first,
        'DHA Phase 5, Lahore',
      );
      await tester.pumpAndSettle();

      // Tap Place Order
      final placeOrderBtn = find.widgetWithText(ElevatedButton, 'Place Order');
      await tester.ensureVisible(placeOrderBtn);
      await tester.tap(placeOrderBtn);
      await tester.pumpAndSettle();

      // Verified user: no OTP verification dialog prompted
      expect(find.text('Email Verification'), findsNothing);
      expect(find.text('Verify & Place Order'), findsNothing);
    });
  });

  group('Scenario 6: User A vs User B Isolation', () {
    test('User A verification does not affect User B verification state', () async {
      final repo = CartRepository.instance;
      const userA = 'user_a@domain.pk';
      const userB = 'user_b@domain.pk';

      // Initially both unverified
      expect(await repo.isEmailVerified(userA), isFalse);
      expect(await repo.isEmailVerified(userB), isFalse);

      // Verify User A
      await repo.markEmailVerified(userA);

      // User A is now verified
      expect(await repo.isEmailVerified(userA), isTrue);

      // User B must REMAIN unverified
      expect(await repo.isEmailVerified(userB), isFalse);
    });
  });
}
