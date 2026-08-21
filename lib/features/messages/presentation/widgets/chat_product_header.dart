import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';

class ChatProductHeader extends StatelessWidget {
  final int? productId;
  final String? productName;
  final String? productImage;
  final double? productPrice;
  final VoidCallback? onViewProduct;
  final VoidCallback? onSendInquiry;

  const ChatProductHeader({
    super.key,
    this.productId,
    this.productName,
    this.productImage,
    this.productPrice,
    this.onViewProduct,
    this.onSendInquiry,
  });

  @override
  Widget build(BuildContext context) {
    if (productName == null || productName!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(
          bottom: BorderSide(color: AppColors.border, width: 1),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          // Product Thumbnail
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppDimensions.radiusSm,
              border: Border.all(color: AppColors.border),
            ),
            child: productImage != null && productImage!.isNotEmpty
                ? ClipRRect(
                    borderRadius: AppDimensions.radiusSm,
                    child: Image.network(
                      productImage!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.shopping_bag_outlined,
                        size: 22,
                        color: AppColors.primary,
                      ),
                    ),
                  )
                : const Icon(
                    Icons.shopping_bag_outlined,
                    size: 22,
                    color: AppColors.primary,
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Product Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  productName!,
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (productPrice != null && productPrice! > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    'PKR ${productPrice!.toStringAsFixed(0)}',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onSendInquiry != null) ...[
            const SizedBox(width: AppSpacing.xs),
            OutlinedButton(
              onPressed: onSendInquiry,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: 4,
                ),
                side: const BorderSide(color: AppColors.primary),
                minimumSize: const Size(0, 30),
                shape: RoundedRectangleBorder(
                  borderRadius: AppDimensions.radiusSm,
                ),
              ),
              child: Text(
                'Ask Seller',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
