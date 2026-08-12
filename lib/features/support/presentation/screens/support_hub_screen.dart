import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class SupportHubScreen extends StatelessWidget {
  const SupportHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: BackButton(color: AppColors.textPrimary),
        title: Text(
          'Help & Support',
          style: AppTypography.screenTitle.copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero banner
            Container(
              width: double.infinity,
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xl,
                AppSpacing.lg,
                AppSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      borderRadius: AppDimensions.radiusMd,
                    ),
                    child: const Icon(
                      Icons.support_agent_rounded,
                      color: AppColors.primary,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    'How can we help?',
                    style: AppTypography.screenTitle.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Find answers, contact support, or track your tickets.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1, color: AppColors.divider),
            const SizedBox(height: AppSpacing.lg),

            // Main options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'GET HELP',
                style: AppTypography.overline.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            _SupportOptionCard(
              icon: Icons.help_outline_rounded,
              title: 'Help Centre & FAQ',
              subtitle: 'Browse answers to common questions',
              onTap: () => context.push(AppRoutes.supportFaq),
            ),
            _SupportOptionCard(
              icon: Icons.headset_mic_outlined,
              title: 'Contact Support',
              subtitle: 'Open a ticket or reach us directly',
              onTap: () => context.push(AppRoutes.supportContact),
            ),
            _SupportOptionCard(
              icon: Icons.confirmation_number_outlined,
              title: 'My Tickets',
              subtitle: 'View and reply to your support tickets',
              onTap: () => context.push(AppRoutes.supportTickets),
            ),

            const SizedBox(height: AppSpacing.xl),

            // Quick contact
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: Text(
                'QUICK CONTACT',
                style: AppTypography.overline.copyWith(
                  color: AppColors.textSecondary,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            Container(
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: AppDimensions.radiusLg,
                border: Border.all(color: AppColors.divider),
              ),
              child: Column(
                children: [
                  _QuickContactTile(
                    icon: Icons.chat_outlined,
                    label: 'WhatsApp',
                    value: '+92-300-9999999',
                    subtitle: 'Mon–Sat, 9am–9pm PKT',
                    onTap: () => launchUrl(
                      Uri.parse('https://wa.me/923009999999'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.divider),
                  _QuickContactTile(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: 'info@softstore.pk',
                    subtitle: 'Best for detailed queries',
                    onTap: () => launchUrl(
                      Uri.parse('mailto:info@softstore.pk'),
                      mode: LaunchMode.externalApplication,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _SupportOptionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _SupportOptionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(
          AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDimensions.radiusLg,
        border: Border.all(color: AppColors.divider),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimensions.radiusLg,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.08),
                  borderRadius: AppDimensions.radiusMd,
                ),
                child: Icon(icon, color: AppColors.primary, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: AppColors.textSecondary,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickContactTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final VoidCallback onTap;

  const _QuickContactTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: AppDimensions.radiusLg,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(icon, color: AppColors.primary, size: 22),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: AppDimensions.radiusSm,
              ),
              child: Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
