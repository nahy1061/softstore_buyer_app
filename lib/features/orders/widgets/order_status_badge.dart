import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../../../core/theme/app_typography.dart';

class OrderStatusBadge extends StatelessWidget {
  final OrderStatus status;
  final bool large;

  const OrderStatusBadge({super.key, required this.status, this.large = false});

  @override
  Widget build(BuildContext context) {
    final color = status.color;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 14 : 10,
        vertical: large ? 6 : 4,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(
        status.shortLabel.toUpperCase(),
        style: (large ? AppTypography.labelMedium : AppTypography.labelSmall)
            .copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
