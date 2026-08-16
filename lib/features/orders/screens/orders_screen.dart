import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_bottom_nav.dart';
import '../../../app/router.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final List<String> _tabs = [
    'Pending',
    'Confirmed',
    'Processing',
    'Shipped',
    'Delivered',
    'Cancelled',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showTrackOrderDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => _TrackOrderDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.go(AppRoutes.profile),
        ),
        title: Text('My Orders', style: AppTypography.screenTitle),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () => _showTrackOrderDialog(context),
            icon: const Icon(Icons.my_location_outlined,
                color: AppColors.primary, size: 24),
            tooltip: 'Track Order',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTypography.labelMedium
              .copyWith(fontWeight: FontWeight.w600),
          unselectedLabelStyle: AppTypography.labelMedium,
          indicatorColor: AppColors.primary,
          indicatorWeight: 2.5,
          tabAlignment: TabAlignment.start,
          tabs: _tabs.map((t) => Tab(text: t)).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs
            .map((_) => const _EmptyOrdersState())
            .toList(),
      ),
      bottomNavigationBar: const AppBottomNav(currentIndex: 1),
    );
  }
}

class _EmptyOrdersState extends StatelessWidget {
  const _EmptyOrdersState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            size: 72,
            color: AppColors.textDisabled,
          ),
          const SizedBox(height: AppSpacing.lg),
          Text(
            'No orders yet',
            style: AppTypography.sectionHeading
                .copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Your placed orders will show up here.',
            style: AppTypography.bodyMedium
                .copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Track Order Dialog ──────────────────────────────────────────────────────

class _TrackOrderDialog extends StatefulWidget {
  @override
  State<_TrackOrderDialog> createState() => _TrackOrderDialogState();
}

class _TrackOrderDialogState extends State<_TrackOrderDialog> {
  final _invoiceController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _invoiceController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Container(
        padding: AppSpacing.paddingXl,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.local_shipping_outlined,
                  color: AppColors.primary, size: 28),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Track Your Order',
                style: AppTypography.sectionHeading
                    .copyWith(fontSize: 18)),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Enter your invoice number and phone number',
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),

            // Invoice Input
            TextFormField(
              controller: _invoiceController,
              decoration: InputDecoration(
                labelText: 'Invoice Number',
                prefixIcon: const Icon(Icons.receipt_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Phone Input
            TextFormField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.divider),
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text('Cancel',
                        style: AppTypography.labelMedium
                            .copyWith(color: AppColors.textSecondary)),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Track order logic here
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content:
                                Text('Tracking your order...')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      minimumSize: const Size(double.infinity, 48),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text('Track Order',
                        style: AppTypography.labelMedium
                            .copyWith(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
