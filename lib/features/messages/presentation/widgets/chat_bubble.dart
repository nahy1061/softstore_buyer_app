import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/chat_message_model.dart';

class ChatBubble extends StatelessWidget {
  final ChatMessage message;
  final VoidCallback? onRetry;

  const ChatBubble({
    super.key,
    required this.message,
    this.onRetry,
  });

  String _formatTime(DateTime time) {
    final hour = time.hour > 12 ? time.hour - 12 : (time.hour == 0 ? 12 : time.hour);
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _copyToClipboard(BuildContext context) {
    Clipboard.setData(ClipboardData(text: message.text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Message copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isBuyer = message.isFromBuyer;
    final isSystem = message.sender == MessageSender.system;

    if (isSystem) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: AppDimensions.radiusSm,
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            message.text,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: isBuyer ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isBuyer) ...[
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: const Icon(
                Icons.store_rounded,
                size: 16,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: GestureDetector(
              onLongPress: () => _copyToClipboard(context),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: isBuyer ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: AppDimensions.radiusMd.topLeft,
                    topRight: AppDimensions.radiusMd.topRight,
                    bottomLeft: isBuyer
                        ? AppDimensions.radiusMd.bottomLeft
                        : Radius.zero,
                    bottomRight: isBuyer
                        ? Radius.zero
                        : AppDimensions.radiusMd.bottomRight,
                  ),
                  border: isBuyer
                      ? null
                      : Border.all(color: AppColors.border, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 3,
                      offset: const Offset(0, 1),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: isBuyer
                      ? CrossAxisAlignment.end
                      : CrossAxisAlignment.start,
                  children: [
                    Text(
                      message.text,
                      style: AppTypography.bodyMedium.copyWith(
                        color: isBuyer ? Colors.white : AppColors.textPrimary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _formatTime(message.sentAt),
                          style: AppTypography.labelSmall.copyWith(
                            fontSize: 10,
                            color: isBuyer
                                ? Colors.white.withValues(alpha: 0.75)
                                : AppColors.textDisabled,
                          ),
                        ),
                        if (isBuyer) ...[
                          const SizedBox(width: 4),
                          _buildStatusIcon(),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (message.isFailed && onRetry != null) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(
                Icons.refresh_rounded,
                color: AppColors.error,
                size: 20,
              ),
              onPressed: onRetry,
              tooltip: 'Retry message',
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusIcon() {
    if (message.isSending) {
      return const SizedBox(
        width: 10,
        height: 10,
        child: CircularProgressIndicator(
          strokeWidth: 1.5,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
        ),
      );
    }
    if (message.isFailed) {
      return const Icon(
        Icons.error_outline_rounded,
        size: 12,
        color: Colors.amberAccent,
      );
    }
    return const Icon(
      Icons.done_all_rounded,
      size: 13,
      color: Colors.white70,
    );
  }
}
