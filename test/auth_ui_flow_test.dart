import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:softstore_buyer_app/features/auth/cubit/auth_cubit.dart';
import 'package:softstore_buyer_app/features/auth/screens/login_screen.dart';
import 'package:softstore_buyer_app/features/auth/screens/register_screen.dart';
import 'package:softstore_buyer_app/features/cart/cubit/cart_cubit.dart';
import 'package:softstore_buyer_app/features/product/screens/product_detail_screen.dart';
import 'package:softstore_buyer_app/features/profile/cubit/profile_cubit.dart';
import 'package:softstore_buyer_app/features/profile/screens/profile_hub_screen.dart';

void main() {
  group('Auth UI & Flow Tests matching screenshots', () {
    testWidgets('LoginScreen displays all fields and actions from Screenshot 3',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthCubit>(
            create: (_) => AuthCubit(),
            child: const LoginScreen(),
          ),
        ),
      );

      // Verify header subtitle
      expect(find.text('Sign in to manage your account'), findsOneWidget);

      // Verify form fields
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);

      // Verify Forgot password?
      expect(find.text('Forgot password?'), findsOneWidget);

      // Verify Sign In button
      expect(find.text('Sign In'), findsOneWidget);

      // Verify Divider
      expect(find.text('or'), findsOneWidget);

      // Verify Google Button
      expect(find.text('Continue with Google'), findsOneWidget);

      // Verify Footer Create an account link
      expect(find.text('New to SoftStore? '), findsOneWidget);
      expect(find.text('Create an account'), findsOneWidget);
    });

    testWidgets(
        'RegisterScreen displays all 6 fields and actions from Screenshot 1',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<AuthCubit>(
            create: (_) => AuthCubit(),
            child: const RegisterScreen(),
          ),
        ),
      );

      // Verify Header
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Create your account'), findsOneWidget);

      // Verify 6 input fields
      expect(find.text('First name'), findsOneWidget);
      expect(find.text('Last name (optional)'), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Phone (optional)'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm password'), findsOneWidget);

      // Verify Create Account button
      expect(find.text('Create Account'), findsOneWidget);

      // Verify Divider
      expect(find.text('or'), findsOneWidget);

      // Verify Google Sign Up
      expect(find.text('Sign up with Google'), findsOneWidget);
    });

    testWidgets(
        'ProfileHubScreen displays unauthenticated view from Screenshot 2 when logged out',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>(create: (_) => AuthCubit()),
              BlocProvider<ProfileCubit>(create: (_) => ProfileCubit()),
              BlocProvider<CartCubit>(create: (_) => CartCubit()),
            ],
            child: const ProfileHubScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify App bar Me title
      expect(find.text('Me'), findsWidgets);

      // Verify user avatar icon
      expect(find.byIcon(Icons.person), findsWidgets);

      // Verify heading
      expect(find.text('Sign in for a better experience'), findsOneWidget);

      // Verify Sign In & Track Order buttons
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Track Order'), findsOneWidget);

      // Tap Sign In and verify Login modal opens
      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('Sign in to manage your account'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });

    testWidgets('ProductDetailScreen Buy Now triggers Login modal when unauthenticated',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<AuthCubit>(create: (_) => AuthCubit()),
              BlocProvider<CartCubit>(create: (_) => CartCubit()),
            ],
            child: const Scaffold(
              body: ProductDetailScreen(
                slug: 'test-product',
                name: 'Test Product',
                price: 1500,
                iconCodePoint: 0xe59c,
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find and tap Buy Now
      final buyNowBtn = find.text('Buy Now');
      expect(buyNowBtn, findsOneWidget);

      await tester.tap(buyNowBtn);
      await tester.pumpAndSettle();

      // Verify login modal appears
      expect(find.text('Sign in to manage your account'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
    });
  });
}
