import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/conversation_model.dart';

class ConversationCard extends StatelessWidget {
  final ConversationThread conversation;
  final VoidCallback onTap;

  const ConversationCard({
    super.key,
    required this.conversation,
    required this.onTap,
  });

  String _formatTimestamp(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasUnread = conversation.isUnread || conversation.unreadCount > 0;

    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: AppColors.primary.withValues(alpha: 0.04),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Avatar / Initial
              Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.border,
                        width: 1,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: conversation.sellerAvatar != null &&
                            conversation.sellerAvatar!.isNotEmpty
                        ? ClipOval(
                            child: Image.network(
                              conversation.sellerAvatar!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => _buildAvatarFallback(),
                            ),
                          )
                        : _buildAvatarFallback(),
                  ),
                  if (conversation.productImage != null &&
                      conversation.productImage!.isNotEmpty)
                    Positioned(
                      bottom: -2,
                      right: -2,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.white, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: Image.network(
                            conversation.productImage!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.shopping_bag,
                              size: 10,
                              color: AppColors.primary,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: AppSpacing.md),
              // Content (Seller name, product title, message preview)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            conversation.sellerName,
                            style: AppTypography.bodyLarge.copyWith(
                              fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          _formatTimestamp(conversation.lastMessageTime),
                          style: AppTypography.labelSmall.copyWith(
                            color: hasUnread ? AppColors.primary : AppColors.textDisabled,
                            fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                    if (conversation.productName != null &&
                        conversation.productName!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(
                            Icons.shopping_bag_outlined,
                            size: 13,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              conversation.productName!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w500,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            conversation.lastMessage.isNotEmpty
                                ? conversation.lastMessage
                                : 'Tap to view conversation',
                            style: AppTypography.bodySmall.copyWith(
                              color: hasUnread
                                  ? AppColors.textPrimary
                                  : AppColors.textSecondary,
                              fontWeight:
                                  hasUnread ? FontWeight.w600 : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (hasUnread) ...[
                          const SizedBox(width: AppSpacing.sm),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: AppDimensions.radiusSm,
                            ),
                            constraints: const BoxConstraints(minWidth: 18),
                            alignment: Alignment.center,
                            child: Text(
                              conversation.unreadCount > 0
                                  ? '${conversation.unreadCount}'
                                  : '',
                              style: AppTypography.badge.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAvatarFallback() {
    final initial = conversation.sellerName.isNotEmpty
        ? conversation.sellerName[0].toUpperCase()
        : 'S';
    return Text(
      initial,
      style: AppTypography.sectionHeading.copyWith(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
        fontSize: 18,
      ),
    );
  }
}
