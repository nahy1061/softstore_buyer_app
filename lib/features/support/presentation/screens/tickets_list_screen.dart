import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../app/router.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../models/support_category.dart';
import '../../models/ticket_model.dart';
import '../cubits/support_cubit.dart';
import '../cubits/support_state.dart';
import '../widgets/ticket_status_badge.dart';

class TicketsListScreen extends StatefulWidget {
  const TicketsListScreen({super.key});

  @override
  State<TicketsListScreen> createState() => _TicketsListScreenState();
}

class _TicketsListScreenState extends State<TicketsListScreen> {
  @override
  void initState() {
    super.initState();
    context.read<SupportCubit>().loadTickets();
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
          icon: const Icon(
            Icons.arrow_back_rounded,
            color: AppColors.textPrimary,
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.support);
            }
          },
        ),
        title: Text(
          'My Tickets',
          style: AppTypography.screenTitle.copyWith(
            color: AppColors.textPrimary,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              final cubit = context.read<SupportCubit>();
              context.push(AppRoutes.supportContact).then((_) {
                if (mounted) {
                  cubit.loadTickets();
                }
              });
            },
            icon: const Icon(
              Icons.add_circle_outline_rounded,
              color: AppColors.primary,
            ),
            tooltip: 'New Ticket',
          ),
        ],
      ),
      body: BlocBuilder<SupportCubit, SupportState>(
        builder: (context, state) {
          if (state is SupportLoading || state is SupportInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            );
          }

          if (state is SupportError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.xl),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.error,
                      size: 48,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'Something went wrong',
                      style: AppTypography.sectionHeading.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      state.message,
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    FilledButton(
                      onPressed: () =>
                          context.read<SupportCubit>().loadTickets(),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: AppDimensions.radiusMd,
                        ),
                      ),
                      child: Text(
                        'Retry',
                        style: AppTypography.buttonText.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          if (state is TicketsLoaded) {
            final tickets = state.tickets;
            if (tickets.isEmpty) {
              return _buildEmptyState();
            }
            return _buildTicketList(tickets);
          }

          return const Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        },
      ),
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
                color: AppColors.primary.withValues(alpha: 0.07),
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
              onPressed: () {
                final cubit = context.read<SupportCubit>();
                context.push(AppRoutes.supportContact).then((_) {
                  if (mounted) {
                    cubit.loadTickets();
                  }
                });
              },
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

  Widget _buildTicketList(List<Ticket> tickets) {
    return RefreshIndicator(
      onRefresh: () async => context.read<SupportCubit>().loadTickets(),
      color: AppColors.primary,
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        itemCount: tickets.length,
        separatorBuilder: (_, index) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          final ticket = tickets[index];
          return _TicketCard(
            ticket: ticket,
            onTap: () {
              final cubit = context.read<SupportCubit>();
              context.push('/support/tickets/${ticket.id}', extra: ticket).then(
                (_) {
                  if (mounted) {
                    cubit.loadTickets();
                  }
                },
              );
            },
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
    final statusColor = TicketStatusBadge.statusColor(ticket.status);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDimensions.radiusLg,
        border: Border(left: BorderSide(color: statusColor, width: 3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: AppDimensions.radiusLg,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    getSupportCategoryIcon(ticket.category),
                    size: 15,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      ticket.category.isNotEmpty ? ticket.category : 'General',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                  TicketStatusBadge(status: ticket.status, compact: true),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                ticket.subject,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              if (ticket.lastMessage.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceAlt,
                    borderRadius: AppDimensions.radiusSm,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 16,
                        color: AppColors.textDisabled,
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          ticket.lastMessage,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Text(
                    ticket.displayId,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.textDisabled,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(ticket.lastUpdatedAt),
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textDisabled,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 18,
                    color: statusColor,
                  ),
                ],
              ),
            ],
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
