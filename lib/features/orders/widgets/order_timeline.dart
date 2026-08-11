import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';

/// 5-step fulfillment tracker matching the web:
/// 1. Received  2. Confirmed  3. Packing  4. Shipped  5. Delivered
class OrderTimeline extends StatelessWidget {
  final OrderStatus currentStatus;

  const OrderTimeline({super.key, required this.currentStatus});

  static const _steps = ['Received', 'Confirmed', 'Packing', 'Shipped', 'Delivered'];

  @override
  Widget build(BuildContext context) {
    if (currentStatus == OrderStatus.cancelled ||
        currentStatus == OrderStatus.refunded) {
      return _TerminalBanner(status: currentStatus);
    }

    final step = currentStatus.fulfillmentStep; // 0–4

    return Column(
      children: [
        Row(
          children: List.generate(_steps.length * 2 - 1, (i) {
            if (i.isOdd) {
              final leftStep = i ~/ 2;
              final filled = leftStep < step;
              return Expanded(
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: filled ? AppColors.primary : AppColors.divider,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }
            final idx = i ~/ 2;
            final isDone = idx < step;
            final isActive = idx == step;
            return _StepDot(
              index: idx + 1,
              isDone: isDone,
              isActive: isActive,
            );
          }),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(_steps.length, (idx) {
            final isDone = idx < step;
            final isActive = idx == step;
            return Expanded(
              child: Text(
                _steps[idx],
                textAlign: idx == 0
                    ? TextAlign.left
                    : idx == _steps.length - 1
                        ? TextAlign.right
                        : TextAlign.center,
                style: AppTypography.overline.copyWith(
                  color: (isDone || isActive)
                      ? AppColors.textPrimary
                      : AppColors.textDisabled,
                  fontWeight:
                      isActive ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final int index;
  final bool isDone;
  final bool isActive;

  const _StepDot({
    required this.index,
    required this.isDone,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    if (isDone) {
      return Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check_rounded, size: 15, color: Colors.white),
      );
    }
    if (isActive) {
      return Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha:0.35),
              blurRadius: 8,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Center(
          child: Text(
            '$index',
            style: AppTypography.labelMedium.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      );
    }
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.divider, width: 1.5),
      ),
      child: Center(
        child: Text(
          '$index',
          style: AppTypography.overline.copyWith(
            color: AppColors.textDisabled,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _TerminalBanner extends StatelessWidget {
  final OrderStatus status;

  const _TerminalBanner({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: status.bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: status.borderColor),
      ),
      child: Row(
        children: [
          Icon(status.icon, color: status.color, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              status.statusMessage,
              style: AppTypography.bodySmall.copyWith(color: status.color),
            ),
          ),
        ],
      ),
    );
  }
}
