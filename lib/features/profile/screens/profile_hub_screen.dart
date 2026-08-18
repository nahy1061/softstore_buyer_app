import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../app/router.dart';
// Shared bottom navigation bar used across all main screens
import '../../../core/widgets/app_bottom_nav_bar.dart';

class ProfileHubScreen extends StatelessWidget {
  const ProfileHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              _ProfileHeader(),
              const SizedBox(height: AppSpacing.xl),
              _DashboardStatsSection(),
              const SizedBox(height: AppSpacing.xl),
              _MyOrdersEnhancedSection(),
              const SizedBox(height: AppSpacing.xl),
              _RecentlyViewedEnhancedSection(),
              const SizedBox(height: AppSpacing.xl),
              _QuickActionsEnhancedGrid(),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
      // Shared bottom nav — index 4 = Profile (this screen)
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 4),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: AppColors.surface,
      padding: AppSpacing.paddingXl,
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppColors.primary.withValues(alpha:0.1),
            child: const Icon(Icons.person, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Guest User', style: AppTypography.sectionHeading),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Sign in to access your orders and profile',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
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
  }
}

class _DashboardStatsSection extends StatelessWidget {
  const _DashboardStatsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          _StatCard(
            icon: Icons.shopping_bag_outlined,
            label: 'Orders',
            value: '12',
            color: AppColors.primary,
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatCard(
            icon: Icons.favorite_outline,
            label: 'Wishlist',
            value: '5',
            color: AppColors.error,
          ),
          const SizedBox(width: AppSpacing.sm),
          _StatCard(
            icon: Icons.star_outline,
            label: 'Reviews',
            value: '8',
            color: AppColors.secondary,
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
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
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: AppSpacing.xs),
            Text(
              value,
              style: AppTypography.titleLarge.copyWith(color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MyOrdersEnhancedSection extends StatelessWidget {
  const _MyOrdersEnhancedSection();

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
              Text(
                'My Orders',
                style: AppTypography.sectionHeading.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextButton(
                onPressed: () => context.go(AppRoutes.orders),
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          _OrderStatusRow(),
        ],
      ),
    );
  }
}

class _OrderStatusRow extends StatelessWidget {
  const _OrderStatusRow();

  @override
  Widget build(BuildContext context) {
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
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _OrderStatusItem(
            icon: Icons.access_time,
            label: 'Pending',
            count: '2',
            color: AppColors.warning,
          ),
          _OrderStatusItem(
            icon: Icons.local_shipping_outlined,
            label: 'Shipping',
            count: '1',
            color: AppColors.primary,
          ),
          _OrderStatusItem(
            icon: Icons.check_circle_outline,
            label: 'Delivered',
            count: '9',
            color: AppColors.success,
          ),
          _OrderStatusItem(
            icon: Icons.replay_outlined,
            label: 'Returns',
            count: '0',
            color: AppColors.error,
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

  const _OrderStatusItem({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          count,
          style: AppTypography.titleMedium.copyWith(color: color),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
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
            'Recently Viewed',
            style: AppTypography.sectionHeading.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 5,
              itemBuilder: (context, index) {
                return _ProductCard(
                  name: 'Product ${index + 1}',
                  price: 1999 + (index * 500),
                  iconCodePoint: Icons.shopping_bag.codePoint,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String name;
  final int price;
  final int iconCodePoint;

  const _ProductCard({
    required this.name,
    required this.price,
    required this.iconCodePoint,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      margin: const EdgeInsets.only(right: AppSpacing.sm),
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
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 60,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
            ),
            child: Icon(
              IconData(iconCodePoint, fontFamily: 'MaterialIcons'),
              color: AppColors.primary,
              size: 32,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTypography.labelSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  'Rs. $price',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionsEnhancedGrid extends StatelessWidget {
  const _QuickActionsEnhancedGrid();

  @override
  Widget build(BuildContext context) {
    final primaryActions = [
      _Action(
        Icons.chat_bubble_outline,
        'Messages',
        AppColors.success,
        () {},
      ),
      _Action(
        Icons.headset_mic_outlined,
        'Support',
        const Color(0xFF5B8CFF),
        () => context.go(AppRoutes.support),
      ),
      _Action(
        Icons.star_outline,
        'Reviews',
        AppColors.secondary,
        () {},
      ),
    ];

    final secondaryActions = [
      _Action(
        Icons.local_shipping_outlined,
        'Track',
        const Color(0xFF9B59B6),
        () => context.go(AppRoutes.orders),
      ),
      _Action(
        Icons.location_on_outlined,
        'Addresses',
        AppColors.success,
        () => context.go(AppRoutes.addresses),
      ),
      _Action(
        Icons.favorite_outline,
        'Wishlist',
        AppColors.error,
        () => context.go(AppRoutes.wishlist),
      ),
    ];

    const tertiaryActions = [
      _Action(
        Icons.settings_outlined,
        'Settings',
        AppColors.textSecondary,
        null,
      ),
      _Action(
        Icons.logout,
        'Sign Out',
        AppColors.error,
        null,
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
              fontWeight: FontWeight.w600,
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
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: primaryActions.map((action) => _ActionItem(action: action)).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: secondaryActions.map((action) => _ActionItem(action: action)).toList(),
                ),
                const SizedBox(height: AppSpacing.lg),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: tertiaryActions.map((action) => _ActionItem(action: action)).toList(),
                ),
              ],
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
    return GestureDetector(
      onTap: action.onTap,
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: action.color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(action.icon, color: action.color, size: 24),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            action.label,
            style: AppTypography.labelLarge.copyWith(
              color: action.color,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
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

class _ProfileMenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;

  const _ProfileMenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
            child: Text(
              title,
              style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary),
            ),
          ),
          const Divider(height: 1),
          ...items.map((item) => Column(
                children: [
                  item,
                  const Divider(height: 1, indent: AppSpacing.lg + 40),
                ],
              )),
        ],
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha:0.08),
                borderRadius: AppDimensions.radiusSm,
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}

class _SignOutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.surface,
      width: double.infinity,
      padding: AppSpacing.paddingLg,
      child: OutlinedButton.icon(
        onPressed: () {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Sign Out'),
              content: const Text('Are you sure you want to sign out?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    context.go(AppRoutes.login);
                  },
                  child: const Text('Sign Out',
                      style: TextStyle(color: AppColors.error)),
                ),
              ],
            ),
          );
        },
        icon: const Icon(Icons.logout, color: AppColors.error),
        label: const Text('Sign Out', style: TextStyle(color: AppColors.error)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
          minimumSize: const Size(double.infinity, AppDimensions.touchTarget),
        ),
      ),
    );
  }
}
