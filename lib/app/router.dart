import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../features/home/screens/home_screen.dart';
import '../features/profile/screens/profile_hub_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/change_password_screen.dart';
import '../features/profile/screens/settings_screen.dart';
import '../features/profile/screens/addresses_screen.dart';
import '../features/profile/screens/address_form_screen.dart';
import '../core/widgets/app_bottom_nav.dart';
import '../features/orders/screens/orders_screen.dart';

// Placeholder screens (will be replaced with actual screens)
class PlaceholderScreen extends StatelessWidget {
  final String label;
  final int? navIndex;

  const PlaceholderScreen({super.key, required this.label, this.navIndex});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.construction, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              '$label\n(Coming Soon)',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18),
            ),
          ],
        ),
      ),
      bottomNavigationBar: navIndex != null
          ? AppBottomNav(currentIndex: navIndex!)
          : null,
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
  static const String editProfile = '/profile/edit';
  static const String changePassword = '/profile/change-password';
  static const String settingsScreen = '/profile/settings';
  static const String addresses = '/addresses';
  static const String addressAdd = '/addresses/add';
  static const String notifications = '/notifications';
  static const String support = '/support';
  static const String supportFaq = '/support/faq';
  static const String supportContact = '/support/contact';
  static const String supportTickets = '/support/tickets';
}

final GoRouter goRouter = GoRouter(
  initialLocation: AppRoutes.home,
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
      builder: (context, state) => const PlaceholderScreen(label: 'Cart', navIndex: 2),
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
      builder: (context, state) => const OrdersScreen(),
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

    // Auth
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const PlaceholderScreen(label: 'Login'),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const PlaceholderScreen(label: 'Register'),
    ),

    // Profile
    GoRoute(
      path: AppRoutes.profile,
      builder: (context, state) => const ProfileHubScreen(),
      routes: [
        GoRoute(
          path: 'edit',
          builder: (context, state) => const EditProfileScreen(),
        ),
        GoRoute(
          path: 'change-password',
          builder: (context, state) => const ChangePasswordScreen(),
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) => const SettingsScreen(),
        ),
      ],
    ),
    GoRoute(
      path: AppRoutes.addresses,
      builder: (context, state) => const AddressesScreen(),
      routes: [
        GoRoute(
          path: 'add',
          builder: (context, state) => const AddressFormScreen(isEditing: false),
        ),
        GoRoute(
          path: 'edit/:id',
          builder: (context, state) {
            final id = state.pathParameters['id'] ?? '';
            return AddressFormScreen(isEditing: true, addressId: id);
          },
        ),
      ],
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
);
