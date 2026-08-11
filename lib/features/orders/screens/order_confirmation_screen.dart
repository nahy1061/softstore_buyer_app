import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_dimensions.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final String referenceNumber;

  const OrderConfirmationScreen({super.key, required this.referenceNumber});

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  // Resolve the matching dummy order or fallback
  Order get _order => dummyOrders.firstWhere(
        (o) => o.referenceNumber == widget.referenceNumber,
        orElse: () => dummyOrders.first,
      );

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            const SizedBox(height: AppSpacing.xl),

            // Animated success icon
            Center(
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 96,
                  height: 96,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.surface,
                    size: 52,
                  ),
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            FadeTransition(
              opacity: _fadeAnim,
              child: Column(
                children: [
                  Text(
                    'Order Placed!',
                    style: AppTypography.screenTitle.copyWith(
                      fontSize: 26,
                      color: AppColors.textPrimary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    'Your order has been confirmed and is being\nprepared by the store.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSpacing.xl),

                  // Reference number box
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xl,
                      vertical: AppSpacing.md,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.06),
                      borderRadius: AppDimensions.radiusMd,
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.2),
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'ORDER REFERENCE',
                          style: AppTypography.overline.copyWith(
                            color: AppColors.textSecondary,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          order.referenceNumber,
                          style: AppTypography.sectionHeading.copyWith(
                            color: AppColors.primary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Summary card
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppDimensions.radiusMd,
                      boxShadow: AppDimensions.cardShadow,
                    ),
                    child: Column(
                      children: [
                        _SummaryRow(
                          icon: Icons.store_rounded,
                          label: 'Store',
                          value: order.storeName,
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _SummaryRow(
                          icon: Icons.shopping_bag_outlined,
                          label: 'Items',
                          value:
                              '${order.totalItems} item${order.totalItems > 1 ? 's' : ''}',
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _SummaryRow(
                          icon: Icons.payments_outlined,
                          label: 'Total',
                          value: 'Rs. ${order.total.toStringAsFixed(0)}',
                          valueBold: true,
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _SummaryRow(
                          icon: Icons.local_shipping_outlined,
                          label: 'Delivery',
                          value: order.estimatedDelivery ?? 'To be confirmed',
                          valueColor: AppColors.statusShipped,
                        ),
                        const Divider(height: 1, indent: 16, endIndent: 16),
                        _SummaryRow(
                          icon: Icons.location_on_outlined,
                          label: 'Address',
                          value:
                              '${order.deliveryAddress.addressLine}, ${order.deliveryAddress.city}',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // COD notice
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withOpacity(0.1),
                      borderRadius: AppDimensions.radiusSm,
                      border: Border.all(
                        color: AppColors.secondary.withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.info_outline_rounded,
                          size: 18,
                          color: AppColors.warning,
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Payment will be collected on delivery. Please have the exact amount ready.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.warning,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),

                  // Track order CTA
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    icon: const Icon(Icons.local_shipping_rounded, size: 18),
                    label: Text(
                      'Track this Order',
                      style: AppTypography.buttonText,
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.surface,
                      minimumSize: const Size.fromHeight(AppDimensions.touchTarget),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: AppDimensions.radiusSm,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.md),

                  // Browse marketplace CTA
                  OutlinedButton(
                    onPressed: () {
                      // Navigate to home
                      Navigator.of(context)
                          .popUntil((route) => route.isFirst);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.divider),
                      minimumSize: const Size.fromHeight(AppDimensions.touchTarget),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppDimensions.radiusSm,
                      ),
                    ),
                    child: Text(
                      'Continue Shopping',
                      style: AppTypography.buttonText.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool valueBold;
  final Color? valueColor;

  const _SummaryRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueBold = false,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.textSecondary),
          const SizedBox(width: AppSpacing.md),
          SizedBox(
            width: 72,
            child: Text(
              label,
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: (valueBold ? AppTypography.labelLarge : AppTypography.bodyMedium)
                  .copyWith(
                color: valueColor ?? AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
