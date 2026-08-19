import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../app/router.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
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
  int _wishlistCount = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProfileAndOrders();
  }

  Future<void> _loadProfileAndOrders() async {
    setState(() => _isLoading = true);
    try {
      context.read<ProfileCubit>().loadProfile();
      final results = await Future.wait([
        OrderRepository.instance.getOrders(),
        WishlistRepository.instance.getWishlist().catchError((_) => <dynamic>[]),
      ]);
      if (mounted) {
        setState(() {
          _orders = results[0] as List<Order>;
          _wishlistCount = (results[1] as List).length;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        final localOrders = await OrderRepository.instance.getLocalOrders();
        setState(() {
          _orders = localOrders.isNotEmpty ? localOrders : List<Order>.from(dummyOrders);
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfileAndOrders,
          color: AppColors.primary,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            child: Column(
              children: [
                const _ProfileHeader(),
                const SizedBox(height: AppSpacing.xl),
                _DashboardStatsSection(
                  ordersCount: _orders.length,
                  wishlistCount: _wishlistCount,
                ),
                const SizedBox(height: AppSpacing.xl),
                _MyOrdersEnhancedSection(orders: _orders),
                const SizedBox(height: AppSpacing.xl),
                const _RecentlyViewedEnhancedSection(),
                const SizedBox(height: AppSpacing.xl),
                const _QuickActionsEnhancedGrid(),
                const SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
      // Shared bottom nav — index 4 = Profile
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 4),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        final isAuthenticated = authState is AuthAuthenticated;
        final user = isAuthenticated ? authState.user : null;
        final userName = user != null && user.fullName.isNotEmpty
            ? user.fullName
            : (user != null && user.firstName.isNotEmpty
                ? user.firstName
                : 'Account User');
        final userEmail = user?.email ?? '';

        return Container(
          width: double.infinity,
          color: AppColors.surface,
          padding: AppSpacing.paddingXl,
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                child: Text(
                  isAuthenticated && userName.isNotEmpty
                      ? userName[0].toUpperCase()
                      : '?',
                  style: AppTypography.screenTitle.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                isAuthenticated ? userName : 'Guest User',
                style: AppTypography.sectionHeading.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                isAuthenticated
                    ? (userEmail.isNotEmpty
                        ? userEmail
                        : 'Manage your orders & settings')
                    : 'Sign in to access your orders and profile',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              if (isAuthenticated)
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => context.push('/profile/edit'),
                        icon: const Icon(Icons.edit_outlined, size: 16),
                        label: const Text('Edit Profile'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          side: const BorderSide(color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _confirmSignOut(context),
                        icon: const Icon(Icons.logout_rounded, size: 16),
                        label: const Text('Sign Out'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.error,
                          side: const BorderSide(color: AppColors.error),
                        ),
                      ),
                    ),
                  ],
                )
              else
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () => context.go(AppRoutes.login),
                        child: const Text('Sign In'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => context.go(AppRoutes.register),
                        child: const Text('Register'),
                      ),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  void _confirmSignOut(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out of your account?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<AuthCubit>().logout();
              context.go(AppRoutes.login);
            },
            child: const Text(
              'Sign Out',
              style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardStatsSection extends StatelessWidget {
  final int ordersCount;
  final int wishlistCount;

  const _DashboardStatsSection({
    required this.ordersCount,
    required this.wishlistCount,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileCubit, ProfileState>(
      builder: (context, state) {
        int displayOrders = ordersCount;
        int displayWishlist = wishlistCount;

        if (state is ProfileLoaded) {
          if (state.stats.totalOrders > 0) {
            displayOrders = state.stats.totalOrders;
          }
          if (state.stats.wishlistItems > 0) {
            displayWishlist = state.stats.wishlistItems;
          }
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              _StatCard(
                icon: Icons.shopping_bag_outlined,
                label: 'Total Orders',
                value: displayOrders.toString(),
                color: AppColors.primary,
                onTap: () => context.push(AppRoutes.orders),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatCard(
                icon: Icons.favorite_outline,
                label: 'Wishlist',
                value: displayWishlist.toString(),
                color: AppColors.error,
                onTap: () => context.push(AppRoutes.wishlist),
              ),
              const SizedBox(width: AppSpacing.sm),
              _StatCard(
                icon: Icons.star_outline,
                label: 'Reviews',
                value: displayOrders > 0 ? (displayOrders ~/ 2 + 1).toString() : '0',
                color: AppColors.secondary,
                onTap: () => context.push(AppRoutes.orders),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: AppSpacing.paddingMd,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: AppDimensions.radiusMd,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
            border: Border.all(
              color: AppColors.divider.withValues(alpha: 0.4),
              width: 0.8,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: AppSpacing.xs),
              Text(
                value,
                style: AppTypography.titleLarge.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textSecondary,
                  fontSize: 11,
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

class _MyOrdersEnhancedSection extends StatelessWidget {
  final List<Order> orders;

  const _MyOrdersEnhancedSection({required this.orders});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'My Orders',
                    style: AppTypography.sectionHeading.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (orders.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${orders.length}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.orders),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _OrderStatusRow(orders: orders),
        ],
      ),
    );
  }
}

class _OrderStatusRow extends StatelessWidget {
  final List<Order> orders;

  const _OrderStatusRow({required this.orders});

  @override
  Widget build(BuildContext context) {
    final pendingCount =
        orders.where((o) => o.status == OrderStatus.pending).length;
    final shippingCount = orders
        .where((o) =>
            o.status == OrderStatus.processing ||
            o.status == OrderStatus.shipped)
        .length;
    final deliveredCount =
        orders.where((o) => o.status == OrderStatus.delivered).length;
    final cancelledCount = orders
        .where((o) =>
            o.status == OrderStatus.cancelled ||
            o.status == OrderStatus.refunded)
        .length;

    return Container(
      padding: AppSpacing.paddingMd,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.radiusMd,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _OrderStatusItem(
            icon: Icons.access_time_rounded,
            label: 'Pending',
            count: pendingCount.toString(),
            color: AppColors.warning,
            onTap: () => context.push(AppRoutes.orders),
          ),
          _OrderStatusItem(
            icon: Icons.local_shipping_outlined,
            label: 'Shipping',
            count: shippingCount.toString(),
            color: AppColors.primary,
            onTap: () => context.push(AppRoutes.orders),
          ),
          _OrderStatusItem(
            icon: Icons.check_circle_outline_rounded,
            label: 'Delivered',
            count: deliveredCount.toString(),
            color: AppColors.success,
            onTap: () => context.push(AppRoutes.orders),
          ),
          _OrderStatusItem(
            icon: Icons.cancel_outlined,
            label: 'Cancelled',
            count: cancelledCount.toString(),
            color: AppColors.statusCancelled,
            onTap: () => context.push(AppRoutes.orders),
          ),
        ],
      ),
    );
  }
}

class _OrderStatusItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String count;
  final Color color;
  final VoidCallback? onTap;

  const _OrderStatusItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            count,
            style: AppTypography.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentlyViewedEnhancedSection extends StatelessWidget {
  const _RecentlyViewedEnhancedSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Shortcuts',
            style: AppTypography.sectionHeading.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _ShortcutCard(
                  icon: Icons.track_changes_rounded,
                  title: 'Track Order',
                  subtitle: 'Live Tracking',
                  color: const Color(0xFF5B8CFF),
                  onTap: () => context.push(AppRoutes.orderLookup),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: _ShortcutCard(
                  icon: Icons.location_on_outlined,
                  title: 'Saved Addresses',
                  subtitle: 'Delivery Places',
                  color: AppColors.success,
                  onTap: () => context.push(AppRoutes.addresses),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ShortcutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ShortcutCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppDimensions.radiusMd,
      child: Container(
        padding: AppSpacing.paddingMd,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppDimensions.radiusMd,
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
          border: Border.all(
            color: color.withValues(alpha: 0.25),
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodySmall.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textSecondary,
                      fontSize: 10,
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

class _QuickActionsEnhancedGrid extends StatelessWidget {
  const _QuickActionsEnhancedGrid();

  @override
  Widget build(BuildContext context) {
    final actions = [
      _Action(
        Icons.chat_bubble_outline_rounded,
        'Messages',
        AppColors.success,
        () => context.push(AppRoutes.messages),
      ),
      _Action(
        Icons.headset_mic_outlined,
        'Support',
        const Color(0xFF5B8CFF),
        () => context.push(AppRoutes.support),
      ),
      _Action(
        Icons.shopping_bag_outlined,
        'Orders',
        AppColors.primary,
        () => context.push(AppRoutes.orders),
      ),
      _Action(
        Icons.favorite_outline_rounded,
        'Wishlist',
        AppColors.error,
        () => context.push(AppRoutes.wishlist),
      ),
      _Action(
        Icons.location_on_outlined,
        'Addresses',
        AppColors.success,
        () => context.push(AppRoutes.addresses),
      ),
      _Action(
        Icons.settings_outlined,
        'Settings',
        AppColors.textSecondary,
        () => context.push('/profile/settings'),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: AppTypography.sectionHeading.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Container(
            padding: AppSpacing.paddingMd,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppDimensions.radiusMd,
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: AppColors.divider.withValues(alpha: 0.4),
                width: 0.8,
              ),
            ),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 16,
                crossAxisSpacing: 12,
                childAspectRatio: 0.95,
              ),
              itemCount: actions.length,
              itemBuilder: (context, index) =>
                  _ActionItem(action: actions[index]),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionItem extends StatelessWidget {
  final _Action action;

  const _ActionItem({required this.action});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: action.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: action.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(action.icon, color: action.color, size: 22),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            action.label,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _Action {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _Action(this.icon, this.label, this.color, this.onTap);
}
