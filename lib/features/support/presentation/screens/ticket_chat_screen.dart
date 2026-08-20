import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_durations.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/ticket_model.dart';
import '../cubits/support_cubit.dart';
import '../cubits/support_state.dart';
import '../widgets/ticket_status_badge.dart';

class TicketChatScreen extends StatefulWidget {
  final Ticket ticket;

  const TicketChatScreen({super.key, required this.ticket});

  @override
  State<TicketChatScreen> createState() => _TicketChatScreenState();
}

class _TicketChatScreenState extends State<TicketChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  List<TicketMessage> _messages = [];
  bool _isSending = false;
  late Ticket _currentTicket;

  @override
  void initState() {
    super.initState();
    _currentTicket = widget.ticket;
    // Seed initial message with description
    _seedInitialDescription();

    // Fetch messages and start polling
    final cubit = context.read<SupportCubit>();
    cubit.loadMessages(widget.ticket.id);

    if (widget.ticket.status == TicketStatus.open ||
        widget.ticket.status == TicketStatus.inProgress) {
      cubit.startPolling(
        widget.ticket.id,
        interval: const Duration(seconds: 5),
      );
    }
  }

  void _seedInitialDescription() {
    if (widget.ticket.lastMessage.isNotEmpty) {
      _messages = [
        TicketMessage(
          id: 1,
          text: widget.ticket.lastMessage,
          sender: MessageSender.buyer,
          sentAt: widget.ticket.createdAt,
        ),
      ];
    }
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() {
      _isSending = true;
      _messages = [
        ..._messages,
        TicketMessage(
          id: _messages.length + 1,
          text: text,
          sender: MessageSender.buyer,
          sentAt: DateTime.now(),
        ),
      ];
    });

    _messageController.clear();
    _scrollToBottom();

    if (mounted) {
      context.read<SupportCubit>().sendMessage(widget.ticket.id, text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isClosed =
        _currentTicket.status == TicketStatus.closed ||
        _currentTicket.status == TicketStatus.resolved;

    return BlocListener<SupportCubit, SupportState>(
      listener: (context, state) {
        if (state is MessagesLoaded) {
          setState(() {
            _isSending = false;
            // If backend returned messages, use them; ensure initial description is preserved at top
            if (state.messages.isNotEmpty) {
              // Filter out status change messages — they update the badge, not the chat
              _messages = state.messages
                  .where((m) => !SupportCubit.isStatusChangeMessage(m))
                  .toList();

              // Detect status changes from the full message list (before filtering)
              final cubit = context.read<SupportCubit>();
              final updated = cubit.detectStatusChange(state.messages, _currentTicket);
              if (updated != null) {
                _currentTicket = updated;
                // Restart polling if ticket is now open/inProgress
                if (updated.status == TicketStatus.open ||
                    updated.status == TicketStatus.inProgress) {
                  cubit.startPolling(updated.id, interval: const Duration(seconds: 5));
                } else {
                  cubit.stopPolling();
                }
              }
            } else if (_messages.isEmpty) {
              _seedInitialDescription();
            }
          });
          _scrollToBottom();
        } else if (state is MessageSent) {
          setState(() => _isSending = false);
          context.read<SupportCubit>().loadMessages(widget.ticket.id);
        } else if (state is SupportError) {
          setState(() => _isSending = false);
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: Colors.black12,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.textPrimary,
            ),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go(AppRoutes.supportTickets);
              }
            },
          ),
          titleSpacing: 0,
          title: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.support_agent_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.ticket.subject,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      widget.ticket.displayId,
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: TicketStatusBadge(
                status: _currentTicket.status,
                compact: true,
              ),
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: AppColors.primary,
                onRefresh: () async {
                  context.read<SupportCubit>().loadMessages(widget.ticket.id);
                },
                child: _messages.isEmpty
                    ? ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.height * 0.25,
                          ),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 48,
                                  color: AppColors.textDisabled,
                                ),
                                const SizedBox(height: AppSpacing.md),
                                Text(
                                  'No messages yet',
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Send a message to contact our support team',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textDisabled,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isFirst = index == 0;
                          final showDateSeparator =
                              isFirst ||
                              !_isSameDay(
                                _messages[index - 1].sentAt,
                                message.sentAt,
                              );
                          return Column(
                            children: [
                              if (showDateSeparator)
                                _DateSeparator(date: message.sentAt),
                              _ChatBubble(message: message, index: index),
                            ],
                          );
                        },
                      ),
              ),
            ),
            isClosed ? _buildClosedBanner() : _buildMessageInput(),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: MediaQuery.of(context).padding.bottom + AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.divider)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              maxLines: 4,
              minLines: 1,
              textCapitalization: TextCapitalization.sentences,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Type your message...',
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textDisabled,
                ),
                filled: true,
                fillColor: AppColors.surfaceAlt,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                border: OutlineInputBorder(
                  borderRadius: AppDimensions.radiusMd,
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppDimensions.radiusMd,
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppDimensions.radiusMd,
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: AppDimensions.radiusMd,
            ),
            child: IconButton(
              onPressed: _isSending ? null : _sendMessage,
              icon: _isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(
                      Icons.send_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
              padding: EdgeInsets.zero,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClosedBanner() {
    final isResolved = _currentTicket.status == TicketStatus.resolved;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isResolved
            ? AppColors.success.withValues(alpha: 0.06)
            : AppColors.background,
        border: const Border(top: BorderSide(color: AppColors.divider)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isResolved ? Icons.check_circle_rounded : Icons.lock_outline,
            size: 16,
            color: isResolved ? AppColors.success : AppColors.textSecondary,
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            isResolved
                ? 'This ticket has been resolved'
                : 'This ticket is closed',
            style: AppTypography.bodySmall.copyWith(
              color: isResolved ? AppColors.success : AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

class _ChatBubble extends StatelessWidget {
  final TicketMessage message;
  final int index;

  const _ChatBubble({required this.message, required this.index});

  @override
  Widget build(BuildContext context) {
    final isBuyer = message.sender == MessageSender.buyer;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: isBuyer
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isBuyer) ...[
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.support_agent_rounded,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment: isBuyer
                  ? CrossAxisAlignment.end
                  : CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  decoration: BoxDecoration(
                    color: isBuyer ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(16),
                      topRight: const Radius.circular(16),
                      bottomLeft: Radius.circular(isBuyer ? 16 : 4),
                      bottomRight: Radius.circular(isBuyer ? 4 : 16),
                    ),
                    border: isBuyer
                        ? null
                        : Border.all(color: AppColors.divider),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    message.text,
                    style: AppTypography.bodyMedium.copyWith(
                      color: isBuyer ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatTime(message.sentAt),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textDisabled,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          if (isBuyer) const SizedBox(width: AppSpacing.xs),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
        ? 12
        : dt.hour;
    final min = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$min $ampm';
  }
}

class _DateSeparator extends StatelessWidget {
  final DateTime date;

  const _DateSeparator({required this.date});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            _formatDate(date),
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    const months = [
      '',
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }
}
