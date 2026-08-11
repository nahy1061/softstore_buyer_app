import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/screens/home_screen.dart';
import '../features/cart/screens/cart_screen.dart';
import '../features/shell/app_shell.dart';


// Placeholder screen body — no Scaffold (shell provides it)
class PlaceholderScreen extends StatelessWidget {
  final String label;

  const PlaceholderScreen({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.construction, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            '$label\n(Placeholder)',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 18),
          ),
        ],
      ),
    );
  }
}

// Route paths
abstract final class AppRoutes {
  static const String root = '/';
  static const String splash = '/splash';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String categories = '/categories';
  static const String categoryProducts = '/category-products/:slug';
  static const String productDetail = '/product/:slug';
  static const String search = '/search';
  static const String seller = '/seller/:slug';
  static const String cart = '/cart';
  static const String wishlist = '/wishlist';
  static const String checkout = '/checkout';
  static const String checkoutDelivery = '/checkout/delivery';
  static const String checkoutOtp = '/checkout/otp';
  static const String checkoutReview = '/checkout/review';
  static const String orderConfirmation = '/order-confirmation/:ref';
  static const String orders = '/orders';
  static const String orderDetail = '/orders/:id';
  static const String returns = '/returns';
  static const String profile = '/profile';
  static const String addresses = '/addresses';
  static const String notifications = '/notifications';
  static const String support = '/support';
  static const String supportFaq = '/support/faq';
  static const String supportContact = '/support/contact';
  static const String supportTickets = '/support/tickets';
}

final GoRouter goRouter = GoRouter(
  initialLocation: AppRoutes.home,
  routes: [
    ShellRoute(
      builder: (context, state, child) => AppShell(child: child),
      routes: [
        // Home & Browsing
        GoRoute(
          path: AppRoutes.home,
          builder: (context, state) => const HomeScreen(),
        ),
        GoRoute(
          path: AppRoutes.categories,
          builder: (context, state) => const PlaceholderScreen(label: 'Categories'),
        ),
        GoRoute(
          path: AppRoutes.categoryProducts,
          builder: (context, state) {
            final slug = state.pathParameters['slug'] ?? '';
            return PlaceholderScreen(label: 'Category: $slug');
          },
        ),
        GoRoute(
          path: AppRoutes.productDetail,
          builder: (context, state) {
            final slug = state.pathParameters['slug'] ?? '';
            return PlaceholderScreen(label: 'Product: $slug');
          },
        ),
        GoRoute(
          path: AppRoutes.search,
          builder: (context, state) => const PlaceholderScreen(label: 'Search'),
        ),
        GoRoute(
          path: AppRoutes.seller,
          builder: (context, state) {
            final slug = state.pathParameters['slug'] ?? '';
            return PlaceholderScreen(label: 'Seller: $slug');
          },
        ),

        // Cart & Checkout
        GoRoute(
          path: AppRoutes.cart,
          builder: (context, state) => const CartScreen(),
        ),
        GoRoute(
          path: AppRoutes.wishlist,
          builder: (context, state) => const PlaceholderScreen(label: 'Wishlist'),
        ),
        GoRoute(
          path: AppRoutes.checkout,
          builder: (context, state) => const PlaceholderScreen(label: 'Checkout'),
          routes: [
            GoRoute(
              path: 'delivery',
              builder: (context, state) => const PlaceholderScreen(label: 'Delivery Address'),
            ),
            GoRoute(
              path: 'otp',
              builder: (context, state) => const PlaceholderScreen(label: 'OTP Verification'),
            ),
            GoRoute(
              path: 'review',
              builder: (context, state) => const PlaceholderScreen(label: 'Order Review'),
            ),
          ],
        ),
        GoRoute(
          path: AppRoutes.orderConfirmation,
          builder: (context, state) {
            final ref = state.pathParameters['ref'] ?? '';
            return PlaceholderScreen(label: 'Order Confirmation: $ref');
          },
        ),

        // Orders & Returns
        GoRoute(
          path: AppRoutes.orders,
          builder: (context, state) => const PlaceholderScreen(label: 'Orders'),
        ),
        GoRoute(
          path: AppRoutes.orderDetail,
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return PlaceholderScreen(label: 'Order Detail: $id');
          },
        ),
        GoRoute(
          path: AppRoutes.returns,
          builder: (context, state) => const PlaceholderScreen(label: 'Returns'),
        ),

        // Profile & Account
        GoRoute(
          path: AppRoutes.profile,
          builder: (context, state) => const PlaceholderScreen(label: 'Profile'),
        ),
        GoRoute(
          path: AppRoutes.addresses,
          builder: (context, state) => const PlaceholderScreen(label: 'Addresses'),
        ),

        // Notifications
        GoRoute(
          path: AppRoutes.notifications,
          builder: (context, state) => const PlaceholderScreen(label: 'Notifications'),
        ),

        // Support
        GoRoute(
          path: AppRoutes.support,
          builder: (context, state) => const PlaceholderScreen(label: 'Support'),
          routes: [
            GoRoute(
              path: 'faq',
              builder: (context, state) => const PlaceholderScreen(label: 'FAQ'),
            ),
            GoRoute(
              path: 'contact',
              builder: (context, state) => const PlaceholderScreen(label: 'Contact Us'),
            ),
            GoRoute(
              path: 'tickets',
              builder: (context, state) => const PlaceholderScreen(label: 'Support Tickets'),
            ),
          ],
        ),
      ],
    ),

    // Auth routes — outside the shell (no header/footer)
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const Scaffold(
        body: Center(child: PlaceholderScreen(label: 'Login')),
      ),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const Scaffold(
        body: Center(child: PlaceholderScreen(label: 'Register')),
      ),
    ),
  ],
);
