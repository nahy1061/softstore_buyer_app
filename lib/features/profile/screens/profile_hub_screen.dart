import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../app/router.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';

class ProfileHubScreen extends StatelessWidget {
  const ProfileHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Profile', style: AppTypography.screenTitle),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _ProfileHeader(),
            const SizedBox(height: AppSpacing.md),
            _ProfileMenuSection(
              title: 'My Account',
              items: [
                _MenuItem(
                  icon: Icons.person_outline,
                  label: 'Edit Profile',
                  subtitle: 'Update your name and phone',
                  onTap: () => context.go(AppRoutes.editProfile),
                ),
                _MenuItem(
                  icon: Icons.lock_outline,
                  label: 'Change Password',
                  subtitle: 'Update your password',
                  onTap: () => context.go(AppRoutes.changePassword),
                ),
                _MenuItem(
                  icon: Icons.location_on_outlined,
                  label: 'Saved Addresses',
                  subtitle: 'Manage delivery addresses',
                  onTap: () => context.go(AppRoutes.addresses),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _ProfileMenuSection(
              title: 'Shopping',
              items: [
                _MenuItem(
                  icon: Icons.receipt_long_outlined,
                  label: 'My Orders',
                  subtitle: 'Track and manage your orders',
                  onTap: () => context.go(AppRoutes.orders),
                ),
                _MenuItem(
                  icon: Icons.favorite_outline,
                  label: 'Wishlist',
                  subtitle: 'Products you have saved',
                  onTap: () => context.go(AppRoutes.wishlist),
                ),
                _MenuItem(
                  icon: Icons.replay_outlined,
                  label: 'Returns',
                  subtitle: 'View and track return requests',
                  onTap: () => context.go(AppRoutes.returns),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _ProfileMenuSection(
              title: 'Support & More',
              items: [
                _MenuItem(
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  subtitle: 'Manage notification preferences',
                  onTap: () => context.go(AppRoutes.notifications),
                ),
                _MenuItem(
                  icon: Icons.help_outline,
                  label: 'Help & Support',
                  subtitle: 'FAQs, contact us, tickets',
                  onTap: () => context.push(AppRoutes.support),
                ),
                _MenuItem(
                  icon: Icons.settings_outlined,
                  label: 'Settings',
                  subtitle: 'App preferences',
                  onTap: () => context.go(AppRoutes.settingsScreen),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _SignOutButton(),
            const SizedBox(height: AppSpacing.xl),
          ],
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
            backgroundColor: AppColors.primary.withValues(alpha: 0.1),
            child: const Icon(Icons.person, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Guest User', style: AppTypography.sectionHeading),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Sign in to access your orders and profile',
            style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary),
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
              style: AppTypography.labelLarge
                  .copyWith(color: AppColors.textSecondary),
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
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: AppDimensions.radiusSm,
              ),
              child: Icon(icon, color: AppColors.primary, size: 20),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: AppTypography.bodyMedium
                          .copyWith(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary, size: 20),
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
        label: const Text('Sign Out',
            style: TextStyle(color: AppColors.error)),
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.error),
          minimumSize:
              const Size(double.infinity, AppDimensions.touchTarget),
        ),
      ),
    );
  }
}
