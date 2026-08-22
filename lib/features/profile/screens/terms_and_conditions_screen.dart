import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  Future<void> _sendEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: 'sales@softstore.pk',
      queryParameters: {'subject': 'Terms & Conditions Inquiry'},
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
        title: Text('Terms & Conditions', style: AppTypography.screenTitle),
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
                        Icons.description_outlined,
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
                            'Platform Agreement',
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
                  'The legal agreement governing your use of the SoftStore.pk platform, buyer marketplace, subscription services, and point-of-sale registers.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // 1. Acceptance of Terms
          const _TermsSection(
            number: '1',
            title: 'Acceptance of These Terms',
            icon: Icons.check_circle_outline,
            body:
                'By accessing or using SoftStore.pk ("the Platform"), creating an account, or browsing the marketplace, you agree to be bound by these Terms and Conditions. If you are using the Platform on behalf of a business, you confirm you have legal authority to bind that entity.',
          ),
          const SizedBox(height: AppSpacing.md),

          // 2. What the Service Is
          const _TermsSection(
            number: '2',
            title: 'Scope of Service',
            icon: Icons.storefront_outlined,
            body:
                '• Marketplace: A multi-vendor retail storefront where verified merchants sell items and buyers purchase with transparent cash-on-delivery or online payment options.\n'
                '• Cloud POS: Point-of-sale terminals with barcode scanning, instant receipting, and real-time inventory synchronization.\n'
                '• Business Management: CRM, orders, tracking, analytics, and stock ledger management.\n'
                '• Multi-Tenant Infrastructure: Secure SaaS system ensuring your business and order data is isolated from all other users.',
          ),
          const SizedBox(height: AppSpacing.md),

          // 3. Account Registration & Security
          const _TermsSection(
            number: '3',
            title: 'Account Registration & Security',
            icon: Icons.manage_accounts_outlined,
            body:
                '• Accuracy: Registration details (name, email, phone number, address) must be authentic, valid, and up to date.\n'
                '• Confidentiality: You are solely responsible for safeguarding your login credentials and passwords.\n'
                '• Shared Logins: Shared or pooled accounts that compromise security audit trails are strictly prohibited.\n'
                '• Unauthorized Activity: Notify us immediately if you suspect unauthorized access to your account.',
          ),
          const SizedBox(height: AppSpacing.md),

          // 4. Orders, Pricing & Checkout
          const _TermsSection(
            number: '4',
            title: 'Orders, Pricing & Billing',
            icon: Icons.payments_outlined,
            body:
                '• Pricing: All item prices are displayed in Pakistani Rupees (PKR).\n'
                '• Order Commitment: Placing an order constitutes a binding intent to purchase. Accurate delivery details must be provided.\n'
                '• Cash on Delivery: COD orders require accurate contact verification. Courier partners collect payment upon physical delivery.',
          ),
          const SizedBox(height: AppSpacing.md),

          // 5. Marketplace Seller & Buyer Obligations
          const _TermsSection(
            number: '5',
            title: 'Marketplace Obligations',
            icon: Icons.handshake_outlined,
            body:
                '• Genuine Products: Sellers may only list authentic, legally permitted goods with truthful specifications and genuine pricing.\n'
                '• Delivery Timelines: Sellers must dispatch confirmed orders within their committed fulfillment windows.\n'
                '• Returns & Refunds: Legitimate return and refund requests must be honored under platform return guidelines.\n'
                '• Rating Integrity: Manipulation of customer reviews, product ratings, or search algorithms is strictly banned.',
          ),
          const SizedBox(height: AppSpacing.md),

          // 6. Prohibited Activities
          const _TermsSection(
            number: '6',
            title: 'Prohibited Activity',
            icon: Icons.block_outlined,
            body:
                '• Attempting to access unauthorized user accounts, seller databases, or server infrastructure.\n'
                '• Engaging in fraudulent transactions, counterfeit merchandise listings, or illegal activities.\n'
                '• Scraping, reverse engineering, or exploiting platform software or APIs.\n'
                '• Circumventing rate limits, authentication barriers, or security firewalls.',
          ),
          const SizedBox(height: AppSpacing.md),

          // 7. Service Availability
          const _TermsSection(
            number: '7',
            title: 'Service Availability',
            icon: Icons.cloud_done_outlined,
            body:
                '• We endeavor to keep the Platform operational 24/7 with advance notice for scheduled maintenance.\n'
                '• SoftStore is not liable for service interruptions caused by third-party hosting outages, upstream telecom disruptions, or external courier network delays.',
          ),
          const SizedBox(height: AppSpacing.md),

          // 8. Limitation of Liability
          const _TermsSection(
            number: '8',
            title: 'Limitation of Liability',
            icon: Icons.gavel_outlined,
            body:
                'To the fullest extent permitted by Pakistani law, SoftStore and its parent entity SoftSkills Engineering (Pvt) Ltd shall not be liable for indirect, incidental, or consequential damages resulting from the use or inability to use the Platform or third-party merchant listings.',
          ),
          const SizedBox(height: AppSpacing.md),

          // 9. Termination
          const _TermsSection(
            number: '9',
            title: 'Termination & Account Closure',
            icon: Icons.cancel_outlined,
            body:
                '• You may close your account at any time via Settings.\n'
                '• SoftStore reserves the right to suspend or terminate accounts that breach these Terms, participate in fraud, or fail order compliance obligations.',
          ),
          const SizedBox(height: AppSpacing.md),

          // 10. Governing Law
          const _TermsSection(
            number: '10',
            title: 'Governing Law & Jurisdiction',
            icon: Icons.account_balance_outlined,
            body:
                'These Terms are governed by and construed in accordance with the laws of the Islamic Republic of Pakistan. Any unresolved disputes shall be submitted to arbitration in Lahore, Pakistan, under the Arbitration Act 1940.',
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
                  'Questions regarding these Terms?',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'If you require legal clarification or wish to report a policy concern, please contact our legal and support team.',
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

class _TermsSection extends StatelessWidget {
  final String number;
  final String title;
  final IconData icon;
  final String body;

  const _TermsSection({
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
