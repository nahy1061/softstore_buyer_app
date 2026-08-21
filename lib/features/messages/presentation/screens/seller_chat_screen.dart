import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_durations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/chat_message_model.dart';
import '../../models/conversation_model.dart';
import '../cubits/seller_chat_cubit.dart';
import '../cubits/seller_chat_state.dart';
import '../widgets/chat_bubble.dart';
import '../widgets/chat_product_header.dart';

class SellerChatScreen extends StatelessWidget {
  final String? threadUrl;
  final ConversationThread? threadInfo;
  final int? productId;
  final String? productName;
  final String? productImage;
  final double? productPrice;
  final String? sellerName;

  const SellerChatScreen({
    super.key,
    this.threadUrl,
    this.threadInfo,
    this.productId,
    this.productName,
    this.productImage,
    this.productPrice,
    this.sellerName,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) {
        final cubit = SellerChatCubit();
        final effectiveThreadUrl = threadUrl ?? threadInfo?.threadUrl;

        if (effectiveThreadUrl != null && effectiveThreadUrl.isNotEmpty) {
          cubit.loadThread(
            effectiveThreadUrl,
            threadInfo: threadInfo,
            productId: productId ?? threadInfo?.productId,
            productName: productName ?? threadInfo?.productName,
            productImage: productImage ?? threadInfo?.productImage,
            sellerName: sellerName ?? threadInfo?.sellerName,
          );
        } else if (productId != null) {
          cubit.startChatWithProduct(
            productId: productId!,
            initialMessage: '',
            productName: productName,
            productImage: productImage,
            sellerName: sellerName,
          );
        }
        return cubit;
      },
      child: _SellerChatScreenContent(
        initialProductName: productName ?? threadInfo?.productName,
        initialProductImage: productImage ?? threadInfo?.productImage,
        initialProductPrice: productPrice ?? threadInfo?.productPrice,
        initialSellerName: sellerName ?? threadInfo?.sellerName ?? 'Seller',
        productId: productId ?? threadInfo?.productId,
      ),
    );
  }
}

class _SellerChatScreenContent extends StatefulWidget {
  final String? initialProductName;
  final String? initialProductImage;
  final double? initialProductPrice;
  final String initialSellerName;
  final int? productId;

  const _SellerChatScreenContent({
    this.initialProductName,
    this.initialProductImage,
    this.initialProductPrice,
    required this.initialSellerName,
    this.productId,
  });

  @override
  State<_SellerChatScreenContent> createState() => _SellerChatScreenContentState();
}

class _SellerChatScreenContentState extends State<_SellerChatScreenContent> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _showQuickChips = true;

  final List<String> _quickInquiries = [
    'Is this product in stock?',
    'How many days will delivery take?',
    'Is cash on delivery available?',
    'What is the warranty period?',
  ];

  @override
  void initState() {
    super.initState();
    context.read<SellerChatCubit>().startPolling(interval: const Duration(seconds: 5));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: AppDurations.normal,
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendMessage([String? customText]) {
    final text = (customText ?? _messageController.text).trim();
    if (text.isEmpty) return;

    context.read<SellerChatCubit>().sendMessage(text);
    _messageController.clear();
    setState(() {
      _showQuickChips = false;
    });
    _scrollToBottom();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black12,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: BlocBuilder<SellerChatCubit, SellerChatState>(
          builder: (context, state) {
            String name = widget.initialSellerName;
            if (state is SellerChatLoaded && state.sellerName != null && state.sellerName!.isNotEmpty) {
              name = state.sellerName!;
            }
            return Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'S',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        name,
                        style: AppTypography.bodyLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'SoftStore Verified Seller',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
      body: BlocConsumer<SellerChatCubit, SellerChatState>(
        listener: (context, state) {
          if (state is SellerChatLoaded) {
            _scrollToBottom();
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              // Product Preview Header
              _buildProductHeader(state),
              // Message Feed
              Expanded(
                child: _buildMessagesArea(context, state),
              ),
              // Quick Inquiry Suggestion Chips
              if (_showQuickChips && (state is! SellerChatLoaded || state.messages.isEmpty))
                _buildQuickChips(),
              // Message Input Bar
              _buildInputBar(state),
            ],
          );
        },
      ),
    );
  }

  Widget _buildProductHeader(SellerChatState state) {
    String? pName = widget.initialProductName;
    String? pImg = widget.initialProductImage;
    double? pPrice = widget.initialProductPrice;
    int? pId = widget.productId;

    if (state is SellerChatLoaded) {
      pName = state.productName ?? pName;
      pImg = state.productImage ?? pImg;
      pPrice = state.threadInfo?.productPrice ?? pPrice;
      pId = state.productId ?? pId;
    }

    if (pName == null || pName.isEmpty) {
      return const SizedBox.shrink();
    }

    return ChatProductHeader(
      productId: pId,
      productName: pName,
      productImage: pImg,
      productPrice: pPrice,
      onSendInquiry: () {
        _sendMessage('Hello, I am interested in this product: $pName');
      },
    );
  }

  Widget _buildMessagesArea(BuildContext context, SellerChatState state) {
    if (state is SellerChatLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (state is SellerChatError) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xxl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 40,
                color: AppColors.error,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                state.message,
                textAlign: TextAlign.center,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              OutlinedButton(
                onPressed: () {
                  if (widget.productId != null) {
                    context.read<SellerChatCubit>().startChatWithProduct(
                          productId: widget.productId!,
                          initialMessage: '',
                          productName: widget.initialProductName,
                          productImage: widget.initialProductImage,
                          sellerName: widget.initialSellerName,
                        );
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (state is SellerChatLoaded) {
      final messages = state.messages;
      if (messages.isEmpty) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'Start a conversation with ${widget.initialSellerName}',
                  style: AppTypography.bodyLarge.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  'Ask about availability, dimensions, delivery, or custom orders.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        );
      }

      return ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
        itemCount: messages.length,
        itemBuilder: (context, index) {
          final msg = messages[index];
          return ChatBubble(
            message: msg,
            onRetry: () => context.read<SellerChatCubit>().retryMessage(msg),
          );
        },
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildQuickChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: _quickInquiries.map((chipText) {
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.xs),
              child: ActionChip(
                label: Text(chipText),
                labelStyle: AppTypography.labelSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontSize: 11,
                ),
                backgroundColor: AppColors.background,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: AppDimensions.radiusSm,
                ),
                onPressed: () => _sendMessage(chipText),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildInputBar(SellerChatState state) {
    final isSending = state is SellerChatLoaded && state.isSending;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        MediaQuery.of(context).padding.bottom + AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: AppDimensions.radiusMd,
                border: Border.all(color: AppColors.border),
              ),
              child: TextField(
                controller: _messageController,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
                decoration: InputDecoration(
                  hintText: 'Type your message to seller...',
                  hintStyle: AppTypography.bodySmall.copyWith(
                    color: AppColors.textDisabled,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Material(
            color: AppColors.primary,
            borderRadius: AppDimensions.radiusMd,
            child: InkWell(
              onTap: isSending ? null : () => _sendMessage(),
              borderRadius: AppDimensions.radiusMd,
              child: Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                child: isSending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      )
                    : const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
