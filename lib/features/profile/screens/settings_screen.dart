import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_dimensions.dart';
import '../models/notification_settings_model.dart';
import '../services/profile_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ProfileService _profileService = ProfileService();
  bool _orderNotifications = true;
  bool _promotionalNotifications = false;
  bool _emailNotifications = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _profileService.getNotificationSettings();
      if (mounted) {
        setState(() {
          _orderNotifications = settings.orderUpdates;
          _promotionalNotifications = settings.promotions;
          _emailNotifications = settings.emailNotifications;
        });
      }
    } catch (_) {}
  }

  Future<void> _updateSetting({
    bool? orderUpdates,
    bool? promotions,
    bool? emailNotifications,
  }) async {
    final newOrder = orderUpdates ?? _orderNotifications;
    final newPromos = promotions ?? _promotionalNotifications;
    final newEmail = emailNotifications ?? _emailNotifications;

    setState(() {
      _orderNotifications = newOrder;
      _promotionalNotifications = newPromos;
      _emailNotifications = newEmail;
    });

    final settings = NotificationSettings(
      orderUpdates: newOrder,
      promotions: newPromos,
      emailNotifications: newEmail,
    );

    try {
      await _profileService.updateNotificationSettings(settings);
      if (mounted) {
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Notification preferences updated',
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.primary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Preferences saved locally',
              style: AppTypography.bodySmall.copyWith(color: Colors.white),
            ),
            backgroundColor: AppColors.textSecondary,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Settings', style: AppTypography.screenTitle),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _SettingsSection(
              title: 'Account & Security',
              children: [
                _ActionTile(
                  icon: Icons.person_outline,
                  label: 'Edit Profile',
                  subtitle: 'Change name, phone and profile info',
                  onTap: () => context.push(AppRoutes.editProfile),
                ),
                _ActionTile(
                  icon: Icons.lock_outline,
                  label: 'Change Password',
                  subtitle: 'Update your account security password',
                  onTap: () => context.push(AppRoutes.changePassword),
                ),
                _ActionTile(
                  icon: Icons.location_on_outlined,
                  label: 'Saved Addresses',
                  subtitle: 'Manage your delivery locations',
                  onTap: () => context.push(AppRoutes.addresses),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _SettingsSection(
              title: 'Notifications',
              children: [
                _ToggleTile(
                  icon: Icons.local_shipping_outlined,
                  label: 'Order Updates',
                  subtitle: 'Get notified about your order status',
                  value: _orderNotifications,
                  onChanged: (val) => _updateSetting(orderUpdates: val),
                ),
                _ToggleTile(
                  icon: Icons.campaign_outlined,
                  label: 'Promotions & Offers',
                  subtitle: 'Deals, discounts and new arrivals',
                  value: _promotionalNotifications,
                  onChanged: (val) => _updateSetting(promotions: val),
                ),
                _ToggleTile(
                  icon: Icons.email_outlined,
                  label: 'Email Notifications',
                  subtitle: 'Receive updates via email',
                  value: _emailNotifications,
                  onChanged: (val) => _updateSetting(emailNotifications: val),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            _SettingsSection(
              title: 'About',
              children: [
                _InfoTile(
                  icon: Icons.info_outline,
                  label: 'App Version',
                  trailing: '1.0.0',
                ),
                _ActionTile(
                  icon: Icons.privacy_tip_outlined,
                  label: 'Privacy Policy',
                  onTap: () => context.push(AppRoutes.privacyPolicy),
                ),
                _ActionTile(
                  icon: Icons.description_outlined,
                  label: 'Terms of Service',
                  onTap: () => context.push(AppRoutes.termsAndConditions),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

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
          ...children,
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
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
                Text(label,
                    style: AppTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.w500)),
                Text(subtitle,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String trailing;

  const _InfoTile(
      {required this.icon, required this.label, required this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
              child: Text(label,
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.w500))),
          Text(trailing,
              style: AppTypography.bodyMedium
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    this.subtitle,
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
                  Text(
                    label,
                    style: AppTypography.bodyMedium
                        .copyWith(fontWeight: FontWeight.w500),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
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
