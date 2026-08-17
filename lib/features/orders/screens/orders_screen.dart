import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/order_cubit.dart';
import '../cubit/order_state.dart';
import '../models/order_model.dart';
import '../widgets/order_card.dart';
import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  int _selectedTab = 0;

  static const _tabs = [
    'All',
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
    context.read<OrderCubit>().loadOrders();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        centerTitle: true,
        title: Text(
          'My Orders',
          style: AppTypography.screenTitle.copyWith(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => context.push(AppRoutes.orderLookup),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.xs,
              ),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Track Order',
              style: AppTypography.labelLarge.copyWith(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.xs),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
      body: Column(
        children: [
          // ── Filter tabs ──────────────────────────────────────────────
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.sm,
            ),
            child: SizedBox(
              height: 36,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _tabs.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final isSelected = _selectedTab == index;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedTab = index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.background,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppColors.primary
                              : AppColors.divider,
                          width: 1,
                        ),
                      ),
                      child: Text(
                        _tabs[index],
                        style: AppTypography.labelMedium.copyWith(
                          color: isSelected
                              ? Colors.white
                              : AppColors.textSecondary,
                          fontWeight:
                              isSelected ? FontWeight.w700 : FontWeight.w500,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // ── Orders list ─────────────────────────────────────────────
          Expanded(
            child: BlocBuilder<OrderCubit, OrderState>(
              builder: (context, state) {
                if (state is OrderLoading || state is OrderInitial) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primary,
                      strokeWidth: 2,
                    ),
                  );
                }
                if (state is OrderError) {
                  return _ErrorView(
                    message: state.message,
                    onRetry: () =>
                        context.read<OrderCubit>().loadOrders(),
                  );
                }
                if (state is OrderLoaded) {
                  final filtered = state.filtered;
                  final tabName = _tabs[_selectedTab].toLowerCase();

                  List<Order> displayOrders;
                  if (tabName == 'all') {
                    displayOrders = filtered;
                  } else if (tabName == 'cancelled') {
                    displayOrders = filtered
                        .where((o) =>
                            o.status == OrderStatus.cancelled ||
                            o.status == OrderStatus.refunded)
                        .toList();
                  } else {
                    final statusFilter = OrderStatus.values.firstWhere(
                      (s) => s.name == tabName,
                      orElse: () => OrderStatus.pending,
                    );
                    displayOrders = filtered
                        .where((o) => o.status == statusFilter)
                        .toList();
                  }

                  return _OrderList(
                    orders: displayOrders,
                    onOrderTap: (o) =>
                        context.push('/orders/${o.id}'),
                    emptyLabel: 'No ${_tabs[_selectedTab].toLowerCase()} orders',
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _OrderList extends StatelessWidget {
  final List<Order> orders;
  final void Function(Order) onOrderTap;
  final String emptyLabel;

  const _OrderList({
    required this.orders,
    required this.onOrderTap,
    this.emptyLabel = 'No orders yet',
  });

  @override
  Widget build(BuildContext context) {
    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.receipt_long_outlined,
                size: 40,
                color: AppColors.textDisabled,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              emptyLabel,
              style: AppTypography.sectionHeading.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Orders you place will appear here.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textDisabled,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return OrderCard(order: order, onTap: () => onOrderTap(order));
      },
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 52, color: AppColors.statusCancelled),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Something went wrong',
            style: AppTypography.sectionHeading
                .copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            message,
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xl),
          ElevatedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, size: 16),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
