import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../features/cart/cubit/cart_cubit.dart';
import '../../features/cart/cubit/cart_state.dart';

class AppBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const AppBottomNavBar({super.key, required this.currentIndex});

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(AppRoutes.home);
        break;
      case 1:
        context.go(AppRoutes.messages);
        break;
      case 2:
        context.go(AppRoutes.categories);
        break;
      case 3:
        context.go(AppRoutes.cart);
        break;
      case 4:
        context.go(AppRoutes.profile);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        return Container(
          height: 60,
          decoration: const BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Color(0xFFE5E7EB), width: 1),
            ),
          ),
          child: Row(
            children: [
              _buildNavItem(
                context: context,
                icon: Icons.home_outlined,
                activeIcon: Icons.home_filled,
                label: 'Home',
                index: 0,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.chat_bubble_outline_rounded,
                activeIcon: Icons.chat_bubble_rounded,
                label: 'Messages',
                index: 1,
              ),
              // Center Browse / Marketplace Logo Button
              Expanded(
                child: InkWell(
                  onTap: () => _navigate(context, 2),
                  splashColor: const Color(0xFFFF6A00).withValues(alpha: 0.12),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(
                            color: currentIndex == 2
                                ? const Color(0xFFFF6A00)
                                : const Color(0xFFE5E7EB),
                            width: currentIndex == 2 ? 2.0 : 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: currentIndex == 2
                                  ? const Color(0xFFFF6A00).withValues(alpha: 0.28)
                                  : Colors.black.withValues(alpha: 0.05),
                              blurRadius: currentIndex == 2 ? 6 : 3,
                              offset: const Offset(0, 1.5),
                            ),
                          ],
                        ),
                        padding: const EdgeInsets.all(2),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo.jpeg',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) => Container(
                              color: const Color(0xFFFF6A00),
                              alignment: Alignment.center,
                              child: const Text(
                                'S',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Browse',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: currentIndex == 2 ? FontWeight.w700 : FontWeight.w500,
                          color: currentIndex == 2 ? const Color(0xFFFF6A00) : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              _buildNavItem(
                context: context,
                icon: Icons.shopping_cart_outlined,
                activeIcon: Icons.shopping_cart,
                label: 'Cart',
                index: 3,
                badgeCount: cartState.itemCount,
              ),
              _buildNavItem(
                context: context,
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Me',
                index: 4,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildNavItem({
    required BuildContext context,
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    int badgeCount = 0,
  }) {
    final bool isActive = index == currentIndex;
    final Color color = isActive ? const Color(0xFFFF6A00) : const Color(0xFF6B7280);

    return Expanded(
      child: InkWell(
        onTap: () => _navigate(context, index),
        splashColor: const Color(0xFFFF6A00).withValues(alpha: 0.08),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isActive ? activeIcon : icon, color: color, size: 22),
                if (badgeCount > 0)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFFF6A00),
                        shape: BoxShape.circle,
                      ),
                      constraints: const BoxConstraints(minWidth: 14, minHeight: 14),
                      child: Text(
                        '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
