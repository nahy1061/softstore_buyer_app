import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../app/router.dart';
import '../cart/cubit/cart_cubit.dart';
import '../cart/cubit/cart_state.dart';

class AppShell extends StatelessWidget {
  final Widget child;
  const AppShell({super.key, required this.child});

  bool _isProductDetail(BuildContext context) =>
      GoRouterState.of(context).uri.toString().startsWith('/product/');

  int _selectedIndex(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/orders')) return 1;
    if (location.startsWith('/cart')) return 2;
    if (location.startsWith('/profile') || location.startsWith('/addresses')) return 3;
    return 0;
  }

  String _getTitle(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();
    if (location.startsWith('/cart')) return 'Your cart';
    if (location.startsWith('/orders')) return 'Your orders';
    if (location.startsWith('/profile')) return 'Your profile';
    if (location.startsWith('/wishlist')) return 'Your wishlist';
    return 'SoftStore.pk';
  }

  @override
  Widget build(BuildContext context) {
    final isProduct = _isProductDetail(context);
    return Scaffold(
      backgroundColor: AppColors.background,
      // Product detail has its own Scaffold — hide shell chrome
      appBar: isProduct
          ? null
          : AppBar(
              title: Text(
                _getTitle(context),
                style: AppTypography.screenTitle
                    .copyWith(color: AppColors.textPrimary),
              ),
              centerTitle: false,
              elevation: 0,
              backgroundColor: Colors.white,
            ),
      body: child,
      bottomNavigationBar: isProduct
          ? null
          : Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Divider(height: 1, color: AppColors.divider),
          BlocBuilder<CartCubit, CartState>(
            builder: (context, cartState) {
              return BottomNavigationBar(
                currentIndex: _selectedIndex(context),
                type: BottomNavigationBarType.fixed,
                selectedItemColor: AppColors.primary,
                unselectedItemColor: AppColors.textDisabled,
                selectedLabelStyle: AppTypography.labelSmall,
                unselectedLabelStyle: AppTypography.labelSmall,
                backgroundColor: Colors.white,
                elevation: 0,
                onTap: (index) {
                  switch (index) {
                    case 0:
                      context.go(AppRoutes.home);
                      break;
                    case 1:
                      context.go(AppRoutes.orders);
                      break;
                    case 2:
                      context.go(AppRoutes.cart);
                      break;
                    case 3:
                      context.go(AppRoutes.profile);
                      break;
                  }
                },
                items: [
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.storefront_outlined),
                    activeIcon: Icon(Icons.storefront),
                    label: 'Marketplace',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.receipt_long_outlined),
                    activeIcon: Icon(Icons.receipt_long),
                    label: 'Orders',
                  ),
                  BottomNavigationBarItem(
                    icon: Badge(
                      isLabelVisible: cartState.itemCount > 0,
                      label: Text('${cartState.itemCount}'),
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.shopping_cart_outlined),
                    ),
                    activeIcon: Badge(
                      isLabelVisible: cartState.itemCount > 0,
                      label: Text('${cartState.itemCount}'),
                      backgroundColor: AppColors.primary,
                      child: const Icon(Icons.shopping_cart),
                    ),
                    label: 'Cart',
                  ),
                  const BottomNavigationBarItem(
                    icon: Icon(Icons.person_outline),
                    activeIcon: Icon(Icons.person),
                    label: 'Profile',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
