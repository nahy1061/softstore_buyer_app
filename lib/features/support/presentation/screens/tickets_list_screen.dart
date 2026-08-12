import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/ticket_model.dart';

class TicketsListScreen extends StatefulWidget {
  const TicketsListScreen({super.key});

  @override
  State<TicketsListScreen> createState() => _TicketsListScreenState();
}

class _TicketsListScreenState extends State<TicketsListScreen> {
  List<Ticket> _tickets = List.from(kMockTickets);
  bool _isLoading = false;

  Future<void> _refresh() async {
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _tickets = List.from(kMockTickets);
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        leading: BackButton(color: AppColors.textPrimary),
        title: Text(
          'My Tickets',
          style: AppTypography.screenTitle.copyWith(color: AppColors.textPrimary),
        ),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.supportContact),
            icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
            tooltip: 'New Ticket',
          ),
        ],
      ),
      body: _tickets.isEmpty ? _buildEmptyState() : _buildTicketList(),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.confirmation_number_outlined,
                color: AppColors.primary,
                size: 40,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(
              'No Tickets Yet',
              style: AppTypography.sectionHeading.copyWith(
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'You haven\'t submitted any support tickets.\nNeed help? Contact us anytime.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => context.push(AppRoutes.supportContact),
              icon: const Icon(Icons.add, size: 18),
              label: Text(
                'Create a Ticket',
                style: AppTypography.buttonText.copyWith(color: Colors.white),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.xl,
                  vertical: AppSpacing.md,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: AppDimensions.radiusMd,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTicketList() {
    return RefreshIndicator(
      onRefresh: _refresh,
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: _tickets.length,
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final ticket = _tickets[index];
          return _TicketCard(
            ticket: ticket,
            onTap: () => context.push('/support/tickets/${ticket.id}'),
          );
        },
      ),
    );
  }
}

class _TicketCard extends StatelessWidget {
  final Ticket ticket;
  final VoidCallback onTap;

  const _TicketCard({required this.ticket, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDimensions.radiusMd,
        border: Border.all(color: AppColors.divider),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimensions.radiusMd,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: ticket ID + status badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ticket.id,
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  _StatusBadge(status: ticket.status),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              // Subject
              Text(
                ticket.subject,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: AppSpacing.xs),

              // Category
              Row(
                children: [
                  Icon(
                    _categoryIcon(ticket.category),
                    size: 14,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    ticket.category,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // Last message preview
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: AppDimensions.radiusSm,
                ),
                child: Text(
                  ticket.lastMessage,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Bottom row: date + chevron
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(ticket.lastUpdatedAt),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textDisabled,
                    ),
                  ),
                  const Icon(
                    Icons.chevron_right,
                    size: 18,
                    color: AppColors.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Order issue':
        return Icons.shopping_bag_outlined;
      case 'Delivery problem':
        return Icons.local_shipping_outlined;
      case 'Return & refund':
        return Icons.assignment_return_outlined;
      case 'Payment issue':
        return Icons.payment_outlined;
      case 'Account problem':
        return Icons.person_outline;
      default:
        return Icons.help_outline;
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[dt.month]} ${dt.day}, ${dt.year}';
  }
}

class _StatusBadge extends StatelessWidget {
  final TicketStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 3),
      decoration: BoxDecoration(
        color: _backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        _label,
        style: AppTypography.labelSmall.copyWith(
          color: _textColor,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String get _label {
    switch (status) {
      case TicketStatus.open:
        return 'Open';
      case TicketStatus.inProgress:
        return 'In Progress';
      case TicketStatus.resolved:
        return 'Resolved';
      case TicketStatus.closed:
        return 'Closed';
    }
  }

  Color get _textColor {
    switch (status) {
      case TicketStatus.open:
        return AppColors.primary;
      case TicketStatus.inProgress:
        return AppColors.statusPending;
      case TicketStatus.resolved:
        return AppColors.success;
      case TicketStatus.closed:
        return AppColors.textSecondary;
    }
  }

  Color get _backgroundColor {
    switch (status) {
      case TicketStatus.open:
        return AppColors.primary.withValues(alpha: 0.1);
      case TicketStatus.inProgress:
        return AppColors.statusPending.withValues(alpha: 0.1);
      case TicketStatus.resolved:
        return AppColors.success.withValues(alpha: 0.1);
      case TicketStatus.closed:
        return AppColors.textSecondary.withValues(alpha: 0.1);
    }
  }
}
