import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/order_cubit.dart';
import '../cubit/order_state.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';

class ReturnsListScreen extends StatefulWidget {
  const ReturnsListScreen({super.key});

  @override
  State<ReturnsListScreen> createState() => _ReturnsListScreenState();
}

class _ReturnsListScreenState extends State<ReturnsListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<OrderCubit>().loadReturns();
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
          'My Returns',
          style: AppTypography.screenTitle.copyWith(
            color: AppColors.textPrimary,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 1),
      body: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          if (state is OrderReturnsLoading) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
                strokeWidth: 2,
              ),
            );
          }

          if (state is OrderReturnsError) {
            return _ErrorView(
              message: state.message,
              onRetry: () => context.read<OrderCubit>().loadReturns(),
            );
          }

          if (state is OrderReturnsLoaded) {
            final returns = state.returns;

            if (returns.isEmpty) {
              return RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () => context.read<OrderCubit>().loadReturns(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: SizedBox(
                    height: MediaQuery.of(context).size.height * 0.6,
                    child: Center(
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
                              Icons.assignment_return_outlined,
                              size: 40,
                              color: AppColors.textDisabled,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'No returns yet',
                            style: AppTypography.sectionHeading.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'Return requests you submit will appear here.',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textDisabled,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }

            return RefreshIndicator(
              color: AppColors.primary,
              onRefresh: () => context.read<OrderCubit>().loadReturns(),
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg,
                  vertical: AppSpacing.md,
                ),
                itemCount: returns.length,
                itemBuilder: (context, index) {
                  final returnItem = returns[index];
                  return _ReturnCard(returnItem: returnItem);
                },
              ),
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ReturnCard extends StatelessWidget {
  final Map<String, dynamic> returnItem;

  const _ReturnCard({required this.returnItem});

  @override
  Widget build(BuildContext context) {
    final id = returnItem['id'] ?? 0;
    final status = (returnItem['status'] ?? 'Pending').toString();
    final reason = (returnItem['reason'] ?? '').toString();
    final date = (returnItem['created_at'] ?? '').toString();
    final invoiceNumber = (returnItem['invoiceNumber'] ?? '').toString();
    final productName = (returnItem['productName'] ?? '').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: AppColors.divider.withValues(alpha: 0.5),
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                id > 0 ? 'Return #$id' : 'Return Request',
                style: AppTypography.sectionHeading.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
              _StatusBadge(status: status),
            ],
          ),
          if (invoiceNumber.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Invoice: $invoiceNumber',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          if (productName.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              productName,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w500,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (reason.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Reason: $reason',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (date.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(
                  Icons.calendar_today_outlined,
                  size: 14,
                  color: AppColors.textDisabled,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  date,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textDisabled,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (backgroundColor, textColor) = _statusColors(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status,
        style: AppTypography.labelSmall.copyWith(
          color: textColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  (Color, Color) _statusColors(String status) {
    final lower = status.toLowerCase();
    if (lower.contains('approved') || lower.contains('completed')) {
      return (AppColors.statusDelivered.withValues(alpha: 0.15), AppColors.statusDelivered);
    } else if (lower.contains('rejected') || lower.contains('denied')) {
      return (AppColors.statusCancelled.withValues(alpha: 0.15), AppColors.statusCancelled);
    } else if (lower.contains('processing') || lower.contains('review')) {
      return (AppColors.statusProcessing.withValues(alpha: 0.15), AppColors.statusProcessing);
    } else {
      return (AppColors.statusPending.withValues(alpha: 0.15), AppColors.statusPending);
    }
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
