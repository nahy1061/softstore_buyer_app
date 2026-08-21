import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../../auth/screens/login_screen.dart';
import '../../catalog/models/catalog_models.dart';
import '../../catalog/repository/recently_viewed_repository.dart';
import '../../orders/models/order_model.dart';
import '../../orders/repository/order_repository.dart';
import '../../wishlist/repository/wishlist_repository.dart';
import '../cubit/profile_cubit.dart';
import '../cubit/profile_state.dart';

class ProfileHubScreen extends StatefulWidget {
  const ProfileHubScreen({super.key});

  @override
  State<ProfileHubScreen> createState() => _ProfileHubScreenState();
}

class _ProfileHubScreenState extends State<ProfileHubScreen> {
  List<Order> _orders = [];
  List<Product> _recentlyViewed = [];
  int _wishlistCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfileAndOrders();
  }

  Future<void> _loadProfileAndOrders() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      context.read<ProfileCubit>().loadProfile();
    }
    try {
      final results = await Future.wait([
        OrderRepository.instance.getOrders(),
        WishlistRepository.instance.getWishlist().catchError((_) => <Product>[]),
        RecentlyViewedRepository.instance.getRecentlyViewed(),
      ]);
      if (mounted) {
        setState(() {
          _orders = results[0] as List<Order>;
          _wishlistCount = (results[1] as List<Product>).length;
          _recentlyViewed = results[2] as List<Product>;
        });
      }
    } catch (_) {
      if (mounted) {
        final localOrders = await OrderRepository.instance.getLocalOrders();
        final recent = await RecentlyViewedRepository.instance.getRecentlyViewed();
        setState(() {
          _orders = localOrders;
          _recentlyViewed = recent;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final bool isAuthenticated = authState is AuthAuthenticated;

        return Scaffold(
          backgroundColor: isAuthenticated ? const Color(0xFFF6F7F9) : Colors.white,
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
              : SafeArea(
                  bottom: false,
                  child: RefreshIndicator(
                    onRefresh: _loadProfileAndOrders,
                    color: const Color(0xFFFF6A00),
                    child: BlocBuilder<ProfileCubit, ProfileState>(
                      builder: (context, profileState) {
                        String displayName = 'Account User';
                        String avatarLetter = 'U';
                        double totalSpent = 0.0;

                        if (profileState is ProfileLoaded &&
                            (profileState.user.firstName.isNotEmpty ||
                                profileState.user.lastName.isNotEmpty)) {
                          final pUser = profileState.user;
                          final pName = pUser.fullName.isNotEmpty
                              ? pUser.fullName
                              : '${pUser.firstName} ${pUser.lastName}'.trim();
                          if (pName.isNotEmpty) {
                            displayName = pName;
                            avatarLetter = pUser.initial;
                          }
                        } else {
                          final user = authState.user;
                          final fullName = user.fullName.isNotEmpty
                              ? user.fullName
                              : '${user.firstName} ${user.lastName}'.trim();
                          if (fullName.isNotEmpty) {
                            displayName = fullName;
                            avatarLetter = displayName[0].toUpperCase();
                          }
                        }

                        if (profileState is ProfileLoaded) {
                          if (profileState.stats.totalSpent > 0) {
                            totalSpent = profileState.stats.totalSpent;
                          }
                        }

                        if (totalSpent == 0 && _orders.isNotEmpty) {
                          totalSpent = _orders.fold<double>(
                            0.0,
                            (sum, order) => sum + (order.status != OrderStatus.cancelled ? order.total : 0.0),
                          );
                        }

                        return SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          child: Column(
                            children: [
                              // ── Header with soft peach gradient ───────────────────
                              _ProfileHeader(
                                displayName: displayName,
                                avatarLetter: avatarLetter,
                                wishlistCount: _wishlistCount,
                                followedCount: 1,
                                ordersCount: _orders.length,
                                totalSpent: totalSpent,
                              ),

                              const SizedBox(height: 12),

                              // ── My Orders Section ─────────────────────────────────
                              _MyOrdersSection(orders: _orders),

                              const SizedBox(height: 12),

                              // ── Recently Viewed Section ───────────────────────────
                              _RecentlyViewedSection(products: _recentlyViewed),

                              const SizedBox(height: 12),

                              // ── Quick Actions Section ─────────────────────────────
                              const _QuickActionsSection(),

                              const SizedBox(height: 24),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ),
          bottomNavigationBar: const AppBottomNavBar(currentIndex: 4),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Unauthenticated "Me" View
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
      padding: const EdgeInsets.only(
        top: 12,
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
                onPressed: () => context.push('/profile/settings'),
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
// My Orders Section with Live Counts
// ─────────────────────────────────────────────────────────────────────────────
class _MyOrdersSection extends StatelessWidget {
  final List<Order> orders;

  const _MyOrdersSection({required this.orders});

  @override
  Widget build(BuildContext context) {
    final pendingCount = orders.where((o) => o.status == OrderStatus.pending).length;
    final processingCount = orders.where((o) => o.status == OrderStatus.processing).length;
    final shippedCount = orders.where((o) => o.status == OrderStatus.shipped).length;
    final deliveredCount = orders.where((o) => o.status == OrderStatus.delivered).length;
    final refundCount = orders.where((o) => o.status == OrderStatus.refunded).length;
    final reviewsCount = deliveredCount > 0 ? (deliveredCount ~/ 2 + 1) : 0;

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
              Row(
                children: [
                  const Text(
                    'My Orders',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E2022),
                    ),
                  ),
                  if (orders.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6A00).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${orders.length}',
                        style: const TextStyle(
                          color: Color(0xFFFF6A00),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              InkWell(
                onTap: () => context.push(AppRoutes.orders),
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF757575),
                        ),
                      ),
                      SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: Color(0xFF9E9E9E),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 18),

          // 6 Status Action Icons Grid / Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _OrderStatusIcon(
                icon: Icons.payment_outlined,
                label: 'Unpaid',
                badgeCount: pendingCount,
                onTap: () => context.push(AppRoutes.orders),
              ),
              _OrderStatusIcon(
                icon: Icons.inventory_2_outlined,
                label: 'To Ship',
                badgeCount: processingCount,
                onTap: () => context.push(AppRoutes.orders),
              ),
              _OrderStatusIcon(
                icon: Icons.local_shipping_outlined,
                label: 'Shipped',
                badgeCount: shippedCount,
                onTap: () => context.push(AppRoutes.orders),
              ),
              _OrderStatusIcon(
                icon: Icons.check_circle_outline_rounded,
                label: 'Delivered',
                badgeCount: deliveredCount,
                onTap: () => context.push(AppRoutes.orders),
              ),
              _OrderStatusIcon(
                icon: Icons.star_border_rounded,
                label: 'Reviews',
                badgeCount: reviewsCount,
                onTap: () => context.push(AppRoutes.orders),
              ),
              _OrderStatusIcon(
                icon: Icons.assignment_return_outlined,
                label: 'Returns',
                badgeCount: refundCount,
                onTap: () => context.push(AppRoutes.returns),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Order Status Icon with Badge
// ─────────────────────────────────────────────────────────────────────────────
class _OrderStatusIcon extends StatelessWidget {
  final IconData icon;
  final String label;
  final int badgeCount;
  final VoidCallback onTap;

  const _OrderStatusIcon({
    required this.icon,
    required this.label,
    required this.badgeCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 4),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  size: 26,
                  color: const Color(0xFF2D3134),
                ),
                if (badgeCount > 0)
                  Positioned(
                    top: -6,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6A00),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 16),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Color(0xFF616161),
              ),
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
  final List<Product> products;

  const _RecentlyViewedSection({required this.products});

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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Recently Viewed',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1E2022),
                    ),
                  ),
                  if (products.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF6A00).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${products.length}',
                        style: const TextStyle(
                          color: Color(0xFFFF6A00),
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              if (products.isNotEmpty)
                InkWell(
                  onTap: () => context.push(AppRoutes.categories),
                  borderRadius: BorderRadius.circular(6),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'View All',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF757575),
                          ),
                        ),
                        SizedBox(width: 2),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: Color(0xFF9E9E9E),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          if (products.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                children: [
                  Icon(
                    Icons.history_rounded,
                    size: 38,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'No recently viewed products',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF757575),
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Items you browse will show up here',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF9E9E9E),
                    ),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: products.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _RecentlyViewedCard(product: product);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _RecentlyViewedCard extends StatelessWidget {
  final Product product;

  const _RecentlyViewedCard({required this.product});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(
        '/product/${product.slug}',
        extra: {
          'id': product.id,
          'name': product.name,
          'price': product.displayPrice.toInt(),
          'imageUrl': product.imageUrl,
        },
      ),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 120,
        decoration: BoxDecoration(
          color: const Color(0xFFFAFAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFEFEFEF)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Container
            Container(
              height: 96,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.vertical(top: Radius.circular(11)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(11)),
                child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                    ? Image.network(
                        product.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 32,
                            color: Color(0xFFBDBDBD),
                          ),
                        ),
                      )
                    : const Center(
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          size: 32,
                          color: Color(0xFFFF6A00),
                        ),
                      ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1E2022),
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rs ${product.displayPrice.toInt()}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFFF6A00),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Quick Actions Section
// ─────────────────────────────────────────────────────────────────────────────
class _QuickActionsSection extends StatelessWidget {
  const _QuickActionsSection();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _ActionData(
        icon: Icons.track_changes_rounded,
        label: 'Track Order',
        color: const Color(0xFF5B8CFF),
        onTap: () => context.push(AppRoutes.orderLookup),
      ),
      _ActionData(
        icon: Icons.location_on_outlined,
        label: 'Saved Addresses',
        color: const Color(0xFF00B074),
        onTap: () => context.push(AppRoutes.addresses),
      ),
      _ActionData(
        icon: Icons.favorite_outline_rounded,
        label: 'Wishlist',
        color: const Color(0xFFE53935),
        onTap: () => context.push(AppRoutes.wishlist),
      ),
      _ActionData(
        icon: Icons.rate_review_outlined,
        label: 'My Reviews',
        color: const Color(0xFFFF9800),
        onTap: () => context.push(AppRoutes.orders, extra: 5),
      ),
      _ActionData(
        icon: Icons.storefront_outlined,
        label: 'Followed Store',
        color: const Color(0xFF8B5CF6),
        onTap: () => context.push('/seller/softstore'),
      ),
      _ActionData(
        icon: Icons.headset_mic_outlined,
        label: 'Customer Support',
        color: const Color(0xFFFF6A00),
        onTap: () => context.push(AppRoutes.support),
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
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E2022),
            ),
          ),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            itemCount: actions.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 12,
              crossAxisSpacing: 10,
              childAspectRatio: 1.35,
            ),
            itemBuilder: (context, index) {
              final action = actions[index];
              return InkWell(
                onTap: action.onTap,
                borderRadius: BorderRadius.circular(12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: action.color.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(action.icon, color: action.color, size: 22),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      action.label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF374151),
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ActionData {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionData({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
}
