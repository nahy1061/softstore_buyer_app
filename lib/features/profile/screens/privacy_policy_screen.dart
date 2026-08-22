import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  Future<void> _sendEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'sales@softstore.pk',
      queryParameters: {'subject': 'Privacy & Data Protection Inquiry'},
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Privacy Policy', style: AppTypography.screenTitle),
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ListView(
        padding: AppSpacing.paddingLg,
        children: [
          // Header Card
          Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: AppDimensions.radiusMd,
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.sm),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: AppDimensions.radiusSm,
                      ),
                      child: const Icon(
                        Icons.shield_outlined,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'SoftStore Privacy Policy',
                            style: AppTypography.titleMedium.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Last updated: August 2026',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Your business data, your customers, and your transaction records — what we hold, why we hold it, and what you can do about it.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Section 1: Data Ownership & Tenant Isolation
          const _PolicySection(
            number: '1',
            title: 'Data Ownership & Tenant Isolation',
            icon: Icons.domain_verification_outlined,
            body:
                'Your business data, customer profiles, sales invoices, inventory records, and staff accounts belong to you. Every operational record is scoped to your business with a tenant_id, and that scoping is enforced on every request rather than left to individual queries to remember.\n\n'
                '• POS transactions, inventory ledger entries, and customer records are strictly tenant-scoped.\n'
                '• No business or store can view or access another business’s records.\n'
                '• Platform-administrator access is strictly audited with tamper-evident logging.',
          ),
          const SizedBox(height: AppSpacing.md),

          // Section 2: Information We Collect
          const _PolicySection(
            number: '2',
            title: 'Information We Collect',
            icon: Icons.data_usage_outlined,
            body:
                'We collect only what is strictly necessary to operate the service and marketplace:\n\n'
                '• Business Information: Store name, owner name, email address, phone number, address, and city.\n'
                '• Staff & Account Credentials: Names, verified email addresses, and securely salted/hashed passwords.\n'
                '• Transaction Data: Sales orders, purchase orders, refunds, returns, and real-time inventory movements.\n'
                '• Customer & Buyer Records: Contact details and delivery locations needed to fulfill orders.\n\n'
                'We DO NOT sell, rent, or share your personal or transaction data with third-party marketing brokers.',
          ),
          const SizedBox(height: AppSpacing.md),

          // Section 3: How We Use Your Data
          const _PolicySection(
            number: '3',
            title: 'How We Use Your Data',
            icon: Icons.tune_outlined,
            body:
                '• Operating POS registers, processing digital checkouts, and updating inventories.\n'
                '• Generating real-time analytics, revenue reports, and inventory management dashboards.\n'
                '• Sending essential transactional notifications, OTP codes, order status alerts, and invoice confirmations.\n'
                '• Fulfilling marketplace deliveries and customer support requests.\n'
                '• Detecting and preventing fraud, security abuse, and policy violations.',
          ),
          const SizedBox(height: AppSpacing.md),

          // Section 4: Data Security
          const _PolicySection(
            number: '4',
            title: 'Data Security Architecture',
            icon: Icons.lock_outline,
            body:
                '• Transport: All network communications are encrypted in transit via TLS 1.3.\n'
                '• Passwords: Salted and hashed using strong cryptographic functions; plaintext passwords are never stored.\n'
                '• Sessions: Protected with HttpOnly, Secure, and SameSite cookie policies.\n'
                '• CSRF Protection: Every state-altering request requires a cryptographically signed CSRF token.\n'
                '• Rate Limiting: Authentication endpoints are protected against brute-force attacks.\n'
                '• Append-Only Ledger: Stock movements and financial records are recorded sequentially and cannot be rewritten.',
          ),
          const SizedBox(height: AppSpacing.md),

          // Section 5: Third-Party Integrations
          const _PolicySection(
            number: '5',
            title: 'Third-Party Services',
            icon: Icons.extension_outlined,
            body:
                'Certain functions rely on verified third-party infrastructure providers:\n\n'
                '• Payment Gateways: JazzCash, EasyPaisa, and RAAST bank transfer integrations.\n'
                '• Delivery & Couriers: Logistics partners receive only the delivery address, recipient name, and contact number needed to fulfill parcels.\n'
                '• Push Notifications: OneSignal is used for transactional order updates and optional deal announcements.\n'
                '• CDN & Infrastructure: Fonts and secure assets are delivered via reliable global content delivery networks.',
          ),
          const SizedBox(height: AppSpacing.md),

          // Section 6: Data Retention & Deletion
          const _PolicySection(
            number: '6',
            title: 'Retention & Account Deletion',
            icon: Icons.auto_delete_outlined,
            body:
                '• Data is actively retained while your account remains open.\n'
                '• Upon account closure, data is retained for a 30-day grace period to prevent accidental loss.\n'
                '• After 30 days, tenant-scoped operational data is permanently purged from active databases.\n'
                '• Financial and tax invoice records are retained in compliance with applicable statutory obligations.\n'
                '• You can export your data at any time from your account dashboard before closure.',
          ),
          const SizedBox(height: AppSpacing.md),

          // Section 7: Your Rights
          const _PolicySection(
            number: '7',
            title: 'Your Privacy Rights',
            icon: Icons.assignment_turned_in_outlined,
            body:
                '• Access & Portability: Request an export of your saved profile, orders, and addresses.\n'
                '• Rectification: Update or correct your personal information at any time from Settings.\n'
                '• Deletion: Request the permanent deletion of your account and associated personal identifiers.\n'
                '• Communications Control: Opt out of marketing announcements via the Settings notification toggles.',
          ),
          const SizedBox(height: AppSpacing.lg),

          // Contact Box
          Container(
            padding: AppSpacing.paddingLg,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: AppDimensions.radiusMd,
              border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Questions or Data Requests?',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'For privacy queries, account deletion requests, or security disclosures, please reach out to our governance team.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                InkWell(
                  onTap: _sendEmail,
                  borderRadius: AppDimensions.radiusSm,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.email_outlined,
                            size: 18, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          'sales@softstore.pk',
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }
}

class _PolicySection extends StatelessWidget {
  final String number;
  final String title;
  final IconData icon;
  final String body;

  const _PolicySection({
    required this.number,
    required this.title,
    required this.icon,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.radiusMd,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  number,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  title,
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              Icon(icon, size: 20, color: AppColors.textSecondary),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            body,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
