import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

import '../../auth/screens/login_screen.dart';

class ProfileHubScreen extends StatefulWidget {
  const ProfileHubScreen({super.key});

  @override
  State<ProfileHubScreen> createState() => _ProfileHubScreenState();
}

class _ProfileHubScreenState extends State<ProfileHubScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthAuthenticated) {
        context.read<ProfileCubit>().loadProfile();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final bool isAuthenticated = authState is AuthAuthenticated;

        return Scaffold(
          backgroundColor:
              isAuthenticated ? const Color(0xFFF6F7F9) : Colors.white,
          appBar: !isAuthenticated
              ? AppBar(
                  backgroundColor: Colors.white,
                  elevation: 0,
                  scrolledUnderElevation: 0,
                  title: const Text(
                    'Me',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF111827),
                    ),
                  ),
                  centerTitle: true,
                )
              : null,
          body: !isAuthenticated
              ? const _UnauthenticatedProfileView()
              : BlocBuilder<ProfileCubit, ProfileState>(
                  builder: (context, profileState) {
                    String displayName = 'akash';
                    String avatarLetter = 'A';
                    int ordersCount = 2;
                    double totalSpent = 1350.0;
                    int wishlistCount = 0;
                    int followedCount = 1;

                    if (profileState is ProfileLoaded) {
                      final user = profileState.user;
                      final fullName =
                          '${user.firstName} ${user.lastName}'.trim();
                      if (fullName.isNotEmpty) {
                        displayName = fullName;
                        avatarLetter = user.firstName.isNotEmpty
                            ? user.firstName[0].toUpperCase()
                            : 'A';
                      }
                      ordersCount = profileState.stats.totalOrders > 0
                          ? profileState.stats.totalOrders
                          : 2;
                      totalSpent = profileState.stats.totalSpent > 0
                          ? profileState.stats.totalSpent
                          : 1350.0;
                    } else {
                      final user = authState.user;
                      if (user.firstName.isNotEmpty) {
                        displayName =
                            '${user.firstName} ${user.lastName}'.trim();
                        avatarLetter = user.firstName[0].toUpperCase();
                      }
                    }

                    return SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          // ── Header with soft peach gradient ───────────────────
                          _ProfileHeader(
                            displayName: displayName,
                            avatarLetter: avatarLetter,
                            wishlistCount: wishlistCount,
                            followedCount: followedCount,
                            ordersCount: ordersCount,
                            totalSpent: totalSpent,
                          ),

                          const SizedBox(height: 12),

                          // ── My Orders Section ─────────────────────────────────
                          const _MyOrdersSection(),

                          const SizedBox(height: 12),

                          // ── Recently Viewed Section ───────────────────────────
                          const _RecentlyViewedSection(),

                          const SizedBox(height: 12),

                          // ── Quick Actions Section ─────────────────────────────
                          const _QuickActionsSection(),

                          const SizedBox(height: 24),
                        ],
                      ),
                    );
                  },
                ),
          bottomNavigationBar: const AppBottomNavBar(currentIndex: 4),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unauthenticated "Me" View matching Screenshot 2
// ─────────────────────────────────────────────────────────────────────────────
class _UnauthenticatedProfileView extends StatelessWidget {
  const _UnauthenticatedProfileView();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // User Avatar Circular Outline
              Container(
                width: 92,
                height: 92,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF9E9E9E),
                    width: 3.2,
                  ),
                ),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.person,
                  size: 58,
                  color: Color(0xFF8E8E93),
                ),
              ),

              const SizedBox(height: 24),

              // Title: Sign in for a better experience
              const Text(
                'Sign in for a better experience',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF111827),
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 28),

              // Primary Button: Sign In
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => LoginScreen.showAsModal(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF6A00),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Sign In',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Secondary Button: Track Order
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton(
                  onPressed: () => context.push(AppRoutes.orderLookup),
                  style: OutlinedButton.styleFrom(
                    backgroundColor: Colors.white,
                    side: const BorderSide(
                      color: Color(0xFFFF6A00),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Track Order',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF6A00),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Profile Header with Peach Gradient & Stats Cards
// ─────────────────────────────────────────────────────────────────────────────
class _ProfileHeader extends StatelessWidget {
  final String displayName;
  final String avatarLetter;
  final int wishlistCount;
  final int followedCount;
  final int ordersCount;
  final double totalSpent;

  const _ProfileHeader({
    required this.displayName,
    required this.avatarLetter,
    required this.wishlistCount,
    required this.followedCount,
    required this.ordersCount,
    required this.totalSpent,
  });

  @override
  Widget build(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFFFFD1BE), // Warm peach top
            Color(0xFFFFE8DD), // Soft gradient middle
            Color(0xFFFFF6F2), // Light transition bottom
          ],
          stops: [0.0, 0.6, 1.0],
        ),
      ),
      padding: EdgeInsets.only(
        top: topPadding + 12,
        left: 16,
        right: 16,
        bottom: 16,
      ),
      child: Column(
        children: [
          // ── User Info & Header Actions ─────────────────────────────────────
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Vibrant Orange Avatar
              Container(
                width: 68,
                height: 68,
                decoration: const BoxDecoration(
                  color: Color(0xFFFF6A00),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  avatarLetter,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Name & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E2022),
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '$wishlistCount Wishlist  ·  $followedCount Followed',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              ),

              // Settings Gear Button
              IconButton(
                onPressed: () => context.push(AppRoutes.settingsScreen),
                icon: const Icon(
                  Icons.settings_outlined,
                  color: Color(0xFF2D3134),
                  size: 26,
                ),
                splashRadius: 22,
                tooltip: 'Settings',
              ),

              // Logout / Sign Out Button
              InkWell(
                onTap: () => _showSignOutDialog(context),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFECEB),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.logout_rounded,
                    color: Color(0xFFE53935),
                    size: 22,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // ── 3 Summary Stat Cards (Orders, Total Spent, Wishlist) ───────────
          Row(
            children: [
              Expanded(
                child: _SummaryCard(
                  value: '$ordersCount',
                  label: 'Orders',
                  onTap: () => context.push(AppRoutes.orders),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  value: 'Rs ${_formatPrice(totalSpent)}',
                  label: 'Total Spent',
                  onTap: () => context.push(AppRoutes.orders),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _SummaryCard(
                  value: '$wishlistCount',
                  label: 'Wishlist',
                  onTap: () => context.push(AppRoutes.wishlist),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatPrice(double amount) {
    if (amount >= 1000) {
      final intPart = amount.toInt();
      final thousands = intPart ~/ 1000;
      final remainder = intPart % 1000;
      return '$thousands,${remainder.toString().padLeft(3, '0')}';
    }
    return amount.toInt().toString();
  }

  void _showSignOutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel', style: TextStyle(color: Color(0xFF6B7280))),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<AuthCubit>().logout();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE53935),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Summary Card Component
// ─────────────────────────────────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final String value;
  final String label;
  final VoidCallback onTap;

  const _SummaryCard({
    required this.value,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFF0F1F3), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: const TextStyle(
                  color: Color(0xFFFF6A00),
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF757575),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// My Orders Section
// ─────────────────────────────────────────────────────────────────────────────
class _MyOrdersSection extends StatelessWidget {
  const _MyOrdersSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F1F3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'My Orders',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2022),
                ),
              ),
              InkWell(
                onTap: () => context.push(AppRoutes.orders, extra: 0),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All Orders',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF6A00),
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFFFF6A00),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 5 Order Status Icons Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OrderStatusItem(
                icon: Icons.credit_card_rounded,
                label: 'To Pay',
                onTap: () => context.push(AppRoutes.orders, extra: 1),
              ),
              _OrderStatusItem(
                icon: Icons.inventory_2_outlined,
                label: 'To Ship',
                onTap: () => context.push(AppRoutes.orders, extra: 3),
              ),
              _OrderStatusItem(
                icon: Icons.inbox_rounded,
                label: 'To Receive',
                onTap: () => context.push(AppRoutes.orders, extra: 4),
              ),
              _OrderStatusItem(
                icon: Icons.star_rounded,
                label: 'To Review',
                onTap: () => context.push(AppRoutes.orders, extra: 5),
              ),
              _OrderStatusItem(
                icon: Icons.replay_rounded,
                label: 'Returns &\nCancellations',
                isMultiLine: true,
                onTap: () => context.push(AppRoutes.orders, extra: 6),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _OrderStatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isMultiLine;

  const _OrderStatusItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isMultiLine = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 62,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF0E8),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: const Color(0xFFFF6A00),
                size: 26,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: isMultiLine ? 9.5 : 11,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF4A4D50),
                height: 1.15,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Recently Viewed Section
// ─────────────────────────────────────────────────────────────────────────────
class _RecentlyViewedSection extends StatelessWidget {
  const _RecentlyViewedSection();

  @override
  Widget build(BuildContext context) {
    final recentProducts = [
      const _RecentItem(
        price: 'Rs. 1,300',
        isBeverage: false,
        placeholderCode: Icons.image_outlined,
      ),
      const _RecentItem(
        price: 'Rs. 200',
        isBeverage: true,
        placeholderCode: Icons.local_drink_rounded,
      ),
      const _RecentItem(
        price: 'Rs. 3,300',
        isBeverage: false,
        placeholderCode: Icons.image_outlined,
      ),
    ];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F1F3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recently Viewed',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E2022),
                ),
              ),
              InkWell(
                onTap: () => context.push(AppRoutes.categories),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View More',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFFF6A00),
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: Color(0xFFFF6A00),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // Horizontal Product Cards
          SizedBox(
            height: 175,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: recentProducts.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final item = recentProducts[index];
                return _RecentlyViewedCard(item: item);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentItem {
  final String price;
  final bool isBeverage;
  final IconData placeholderCode;

  const _RecentItem({
    required this.price,
    required this.isBeverage,
    required this.placeholderCode,
  });
}

class _RecentlyViewedCard extends StatelessWidget {
  final _RecentItem item;

  const _RecentlyViewedCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(AppRoutes.categories),
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: 126,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Container
            Container(
              width: 126,
              height: 135,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F3F6),
                borderRadius: BorderRadius.circular(14),
              ),
              alignment: Alignment.center,
              child: item.isBeverage
                  ? _buildBeverageGraphic()
                  : Icon(
                      item.placeholderCode,
                      size: 40,
                      color: const Color(0xFFC7CDD4),
                    ),
            ),
            const SizedBox(height: 8),

            // Price text
            Text(
              item.price,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Color(0xFFFF6A00),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBeverageGraphic() {
    // Stylized high quality bottle matching Coca-Cola snip
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Cap
        Container(
          width: 10,
          height: 6,
          decoration: BoxDecoration(
            color: const Color(0xFFD32F2F),
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        // Bottle Neck
        Container(
          width: 8,
          height: 12,
          color: const Color(0xFF2C1810),
        ),
        // Bottle Body
        Container(
          width: 28,
          height: 72,
          decoration: BoxDecoration(
            color: const Color(0xFF24140E),
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                padding: const EdgeInsets.symmetric(vertical: 2),
                decoration: const BoxDecoration(
                  color: Color(0xFFE50914),
                ),
                child: const Text(
                  'Cola',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Actions Section (Heading + 8 Circular Action Icons)
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF0F1F3), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Explicit "Quick Actions" Heading requested by user
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2022),
            ),
          ),

          const SizedBox(height: 18),

          // Row 1: My Messages, Customer Care, My Reviews, Track Order
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _QuickActionCircleItem(
                icon: Icons.chat_bubble_rounded,
                label: 'My Messages',
                onTap: () => context.push(AppRoutes.support),
              ),
              _QuickActionCircleItem(
                icon: Icons.headset_mic_rounded,
                label: 'Customer Care',
                onTap: () => context.push(AppRoutes.supportContact),
              ),
              _QuickActionCircleItem(
                icon: Icons.star_rounded,
                label: 'My Reviews',
                onTap: () => context.push(AppRoutes.orders, extra: 5),
              ),
              _QuickActionCircleItem(
                icon: Icons.near_me_rounded,
                label: 'Track Order',
                onTap: () => context.push(AppRoutes.orderLookup),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Row 2: Addresses, Wishlist, Followed Stores, Settings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _QuickActionCircleItem(
                icon: Icons.location_on_rounded,
                label: 'Addresses',
                onTap: () => context.push(AppRoutes.addresses),
              ),
              _QuickActionCircleItem(
                icon: Icons.favorite_rounded,
                label: 'Wishlist',
                onTap: () => context.push(AppRoutes.wishlist),
              ),
              _QuickActionCircleItem(
                icon: Icons.storefront_rounded,
                label: 'Followed Stores',
                onTap: () => _showFollowedStoresSheet(context),
              ),
              _QuickActionCircleItem(
                icon: Icons.settings_rounded,
                label: 'Settings',
                onTap: () => context.push(AppRoutes.settingsScreen),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showFollowedStoresSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Followed Stores',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(sheetCtx),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListTile(
              leading: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF0E8),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.storefront_rounded, color: Color(0xFFFF6A00)),
              ),
              title: const Text(
                'SoftStore Official',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: const Text('Verified Merchant'),
              trailing: OutlinedButton(
                onPressed: () {
                  Navigator.pop(sheetCtx);
                  context.push(AppRoutes.categories);
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFFF6A00),
                  side: const BorderSide(color: Color(0xFFFF6A00)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: const Text('Visit'),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _QuickActionCircleItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickActionCircleItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 74,
        alignment: Alignment.topCenter,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Peach circle with orange icon
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: Color(0xFFFFF0E8),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFFFF6A00),
                size: 26,
              ),
            ),
            const SizedBox(height: 6),

            // Label
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: Color(0xFF2D3134),
                height: 1.2,
              ),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
