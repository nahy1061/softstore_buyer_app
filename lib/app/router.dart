import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

// Feature screen imports
import '../features/auth/screens/login_screen.dart';
import '../features/auth/screens/register_screen.dart';
import '../features/auth/screens/splash_screen.dart';

import '../features/cart/screens/cart_screen.dart';

import '../features/catalog/screens/categories_screen.dart';
import '../features/catalog/screens/category_products_screen.dart';
import '../features/catalog/screens/seller_screen.dart';

import '../features/checkout/screens/checkout_screen.dart';
import '../features/deals/screens/deals_screen.dart';

import '../features/home/screens/home_screen.dart';

import '../features/orders/cubit/order_cubit.dart';
import '../features/orders/models/order_model.dart';
import '../features/orders/screens/order_confirmation_screen.dart';
import '../features/orders/screens/order_detail_screen.dart';
import '../features/orders/screens/order_lookup_screen.dart';
import '../features/orders/screens/orders_screen.dart';

import '../features/product/screens/product_detail_screen.dart';

import '../features/profile/screens/address_form_screen.dart';
import '../features/profile/screens/addresses_screen.dart';
import '../features/profile/screens/change_password_screen.dart';
import '../features/profile/screens/edit_profile_screen.dart';
import '../features/profile/screens/profile_hub_screen.dart';
import '../features/profile/screens/settings_screen.dart';

import '../features/support/models/ticket_model.dart';
import '../features/support/presentation/cubits/support_cubit.dart';
import '../features/support/data/support_repository.dart';
import '../features/support/presentation/screens/contact_support_screen.dart';
import '../features/support/presentation/screens/faq_screen.dart';
import '../features/support/presentation/screens/support_hub_screen.dart';
import '../features/support/presentation/screens/ticket_chat_screen.dart';
import '../features/support/presentation/screens/tickets_list_screen.dart';

import '../features/wishlist/screens/wishlist_screen.dart';

// Placeholder screen for secondary sub-routes if needed
class SecondaryPlaceholderScreen extends StatelessWidget {
  final String label;
  final int? navIndex;

  const SecondaryPlaceholderScreen({
    super.key,
    required this.label,
    this.navIndex,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(label)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.info_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(label, style: const TextStyle(fontSize: 16)),
          ],
        ),
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
  static const String orderLookup = '/track-order';
  static const String returns = '/returns';
  static const String profile = '/profile';
  static const String editProfile = '/profile/edit';
  static const String changePassword = '/profile/change-password';
  static const String settingsScreen = '/profile/settings';
  static const String addresses = '/addresses';
  static const String addressAdd = '/addresses/add';
  static const String notifications = '/notifications';
  static const String deals = '/deals';
  static const String support = '/support';
  static const String supportFaq = '/support/faq';
  static const String supportContact = '/support/contact';
  static const String supportTickets = '/support/tickets';
  static const String supportTicketChat = '/support/tickets/:id';
}

final GoRouter goRouter = GoRouter(
  initialLocation: AppRoutes.root,
  routes: [
    // Launch Splash Screen
    GoRoute(
      path: AppRoutes.root,
      builder: (context, state) => const SplashScreen(),
    ),
    GoRoute(
      path: AppRoutes.splash,
      builder: (context, state) => const SplashScreen(),
    ),

    // Home & Browsing
    GoRoute(
      path: AppRoutes.home,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.categories,
      builder: (context, state) => const CategoriesScreen(),
    ),
    GoRoute(
      path: AppRoutes.categoryProducts,
      builder: (context, state) {
        final slug = state.pathParameters['slug'] ?? '';
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final name = extra['name'] as String?;
        return CategoryProductsScreen(slug: slug, categoryName: name);
      },
    ),
    GoRoute(
      path: AppRoutes.productDetail,
      builder: (context, state) {
        final slug = state.pathParameters['slug'] ?? '';
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return ProductDetailScreen(
          slug: slug,
          name: extra['name'] as String? ?? slug,
          price: extra['price'] as int? ?? 0,
          imageUrl: extra['imageUrl'] as String?,
          iconCodePoint: extra['iconCodePoint'] as int? ?? 0xe59c,
          colors: (extra['colors'] as List?)
                  ?.cast<Map<String, dynamic>>() ??
              const [],
        );
      },
    ),
    GoRoute(
      path: AppRoutes.search,
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: AppRoutes.seller,
      builder: (context, state) {
        final slug = state.pathParameters['slug'] ?? '';
        return SellerScreen(slug: slug);
      },
    ),

    // Cart & Checkout
    GoRoute(
      path: AppRoutes.cart,
      builder: (context, state) => const CartScreen(),
    ),
    GoRoute(
      path: AppRoutes.wishlist,
      builder: (context, state) => const WishlistScreen(),
    ),
    GoRoute(
      path: AppRoutes.checkout,
      builder: (context, state) => const CheckoutScreen(),
    ),
    GoRoute(
      path: AppRoutes.orderConfirmation,
      builder: (context, state) {
        final ref = state.pathParameters['ref'] ?? '';
        final extra = state.extra as Map<String, dynamic>? ?? {};
        return OrderConfirmationScreen(
          referenceNumber: ref,
          invoiceNumber: extra['invoiceNumber'] as String?,
          subtotal: extra['subtotal'] as int?,
          delivery: extra['delivery'] as int?,
          productName: extra['productName'] as String?,
          productQty: extra['productQty'] as int?,
          productPrice: extra['productPrice'] as int?,
          iconCodePoint: extra['iconCodePoint'] as int?,
        );
      },
    ),

    // Orders & Returns
    GoRoute(
      path: AppRoutes.orders,
      builder: (context, state) => BlocProvider(
        create: (_) => OrderCubit(),
        child: const OrdersScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.orderDetail,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        final extraOrder = state.extra as Order?;
        final order = extraOrder ??
            Order(
              id: id,
              referenceNumber: id,
              placedAt: DateTime.now(),
              status: OrderStatus.pending,
              items: const [],
              deliveryAddress: const OrderAddress(
                name: 'Buyer',
                phone: '',
                addressLine: 'Delivery Address',
                city: 'Pakistan',
              ),
              subtotal: 0,
              deliveryFee: 0,
              storeName: 'SoftStore Merchant',
            );

        return BlocProvider(
          create: (_) => OrderCubit()..loadOrderDetail(id),
          child: OrderDetailScreen(order: order),
        );
      },
    ),
    GoRoute(
      path: AppRoutes.orderLookup,
      builder: (context, state) => BlocProvider(
        create: (_) => OrderCubit(),
        child: const OrderLookupScreen(),
      ),
    ),
    GoRoute(
      path: AppRoutes.returns,
      builder: (context, state) =>
          const SecondaryPlaceholderScreen(label: 'Returns', navIndex: 1),
    ),

    // Auth
    GoRoute(
      path: AppRoutes.login,
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: AppRoutes.register,
      builder: (context, state) => const RegisterScreen(),
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
          builder: (context, state) =>
              const AddressFormScreen(isEditing: false),
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
      builder: (context, state) =>
          const SecondaryPlaceholderScreen(label: 'Notifications', navIndex: 4),
    ),

    // Deals & Sponsors
    GoRoute(
      path: AppRoutes.deals,
      builder: (context, state) => const DealsScreen(),
    ),

    // Support
    GoRoute(
      path: AppRoutes.support,
      builder: (context, state) => const SupportHubScreen(),
      routes: [
        GoRoute(
          path: 'faq',
          builder: (context, state) => const FaqScreen(),
        ),
        GoRoute(
          path: 'contact',
          builder: (context, state) {
            final extra = state.extra as Map<String, dynamic>?;
            return BlocProvider(
              create: (_) => SupportCubit(repository: SupportRepository()),
              child: ContactSupportScreen(
                orderReference: extra?['orderReference'] as String?,
                orderId: extra?['orderId'] as int?,
                initialSubject: extra?['subject'] as String?,
                initialCategoryLabel: extra?['categoryLabel'] as String?,
              ),
            );
          },
        ),
        GoRoute(
          path: 'tickets',
          builder: (context, state) => BlocProvider(
            create: (_) => SupportCubit(repository: SupportRepository()),
            child: const TicketsListScreen(),
          ),
          routes: [
            GoRoute(
              path: ':id',
              builder: (context, state) {
                final id = int.tryParse(state.pathParameters['id'] ?? '') ?? 0;
                final ticket = state.extra as Ticket? ??
                    Ticket(
                      id: id,
                      subject: 'Ticket #$id',
                      category: '',
                      status: TicketStatus.open,
                      createdAt: DateTime.now(),
                      lastUpdatedAt: DateTime.now(),
                      lastMessage: '',
                    );
                return BlocProvider(
                  create: (_) => SupportCubit(repository: SupportRepository()),
                  child: TicketChatScreen(ticket: ticket),
                );
              },
            ),
          ],
        ),
      ],
    ),
  ],
);
