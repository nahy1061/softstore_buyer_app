import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../cubit/order_cubit.dart';
import '../cubit/order_state.dart';
import '../models/order_model.dart';
import '../widgets/order_status_badge.dart';
import '../widgets/order_timeline.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_dimensions.dart';

class OrderLookupScreen extends StatefulWidget {
  const OrderLookupScreen({super.key});

  @override
  State<OrderLookupScreen> createState() => _OrderLookupScreenState();
}

class _OrderLookupScreenState extends State<OrderLookupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _refCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  @override
  void dispose() {
    _refCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _lookup() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    context.read<OrderCubit>().lookupOrder(
          referenceNumber: _refCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
        );
  }

  void _reset() {
    _refCtrl.clear();
    _phoneCtrl.clear();
    context.read<OrderCubit>().reset();
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
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Track Order',
          style: AppTypography.screenTitle
              .copyWith(color: AppColors.textPrimary),
        ),
      ),
      body: BlocBuilder<OrderCubit, OrderState>(
        builder: (context, state) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              // ── Page heading ──────────────────────────────────────────
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                    vertical: AppSpacing.xs,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'LIVE FULFILMENT TRACKER',
                    style: AppTypography.overline.copyWith(
                      color: Colors.white,
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Track Your Marketplace Order',
                style: AppTypography.screenTitle.copyWith(
                  fontSize: 22,
                  color: AppColors.textPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Enter your order invoice number to check live processing, packing, and courier dispatch updates managed directly by the store merchant.',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),

              // ── Search form ───────────────────────────────────────────
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppDimensions.radiusMd,
                  boxShadow: AppDimensions.cardShadow,
                  border: Border.all(color: AppColors.divider, width: 0.8),
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Invoice / Order Number',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                TextFormField(
                                  controller: _refCtrl,
                                  textCapitalization:
                                      TextCapitalization.characters,
                                  decoration: InputDecoration(
                                    hintText: 'SS-20240809-0117',
                                    prefixIcon: const Padding(
                                      padding: EdgeInsets.only(
                                          left: 12, right: 4, top: 14),
                                      child: Text(
                                        '#',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.textSecondary,
                                        ),
                                      ),
                                    ),
                                    prefixIconConstraints:
                                        const BoxConstraints(
                                            minWidth: 0, minHeight: 0),
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.md,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Phone Number',
                                  style: AppTypography.labelMedium.copyWith(
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: AppSpacing.xs),
                                TextFormField(
                                  controller: _phoneCtrl,
                                  keyboardType: TextInputType.phone,
                                  decoration: const InputDecoration(
                                    hintText: '03123456789',
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.md,
                                    ),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    if (v.trim().length < 10) {
                                      return 'Invalid number';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed:
                              state is OrderLoading ? null : _lookup,
                          icon: state is OrderLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.search_rounded, size: 18),
                          label: Text(
                            state is OrderLoading
                                ? 'Searching...'
                                : 'Track Live Status',
                            style: AppTypography.buttonText,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              if (state is OrderLookupNotFound)
                _NotFoundCard(onRetry: _reset),

              if (state is OrderLookupResult) ...[
                _LookupResultCard(order: state.order),
                const SizedBox(height: AppSpacing.lg),
                OutlinedButton(
                  onPressed: _reset,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textPrimary,
                    side: const BorderSide(color: AppColors.divider),
                    minimumSize: const Size.fromHeight(
                        AppDimensions.touchTarget),
                    shape: RoundedRectangleBorder(
                        borderRadius: AppDimensions.radiusSm),
                  ),
                  child: const Text('Track Another Order'),
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}

// ─── Not found ────────────────────────────────────────────────────────────────

class _NotFoundCard extends StatelessWidget {
  final VoidCallback onRetry;
  const _NotFoundCard({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.radiusMd,
        border: Border.all(
            color: AppColors.statusCancelled.withValues(alpha:0.3)),
        boxShadow: AppDimensions.cardShadow,
      ),
      child: Column(
        children: [
          const Icon(Icons.search_off_rounded,
              size: 52, color: AppColors.textDisabled),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Order Not Found',
            style: AppTypography.sectionHeading
                .copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'No order matched that invoice number and phone number. Please double-check and try again.',
            style: AppTypography.bodySmall
                .copyWith(color: AppColors.textSecondary),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Try Again'),
          ),
        ],
      ),
    );
  }
}

// ─── Lookup result card ────────────────────────────────────────────────────────

class _LookupResultCard extends StatelessWidget {
  final Order order;
  const _LookupResultCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.radiusMd,
        boxShadow: AppDimensions.cardShadow,
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'MARKETPLACE ORDER',
                      style: AppTypography.overline.copyWith(
                        color: AppColors.textSecondary,
                        letterSpacing: 1.1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    OrderStatusBadge(status: order.status, large: true),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Invoice #${order.referenceNumber}',
                  style: AppTypography.screenTitle.copyWith(
                    color: AppColors.textPrimary,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Placed on ${_fmt(order.placedAt)}',
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'PKR ${order.total.toStringAsFixed(0)}',
                  style: AppTypography.priceTotal.copyWith(
                    color: AppColors.primary,
                    fontSize: 20,
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // Fulfillment
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Fulfillment Progress',
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                OrderTimeline(currentStatus: order.status),
                const SizedBox(height: AppSpacing.md),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: order.status.bgColor,
                    borderRadius: AppDimensions.radiusSm,
                    border: Border.all(color: order.status.borderColor),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(order.status.icon,
                          color: order.status.color, size: 18),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.status.label,
                              style: AppTypography.labelMedium.copyWith(
                                color: order.status.color,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              order.status.statusMessage,
                              style: AppTypography.bodySmall.copyWith(
                                color: order.status.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // Store + Address
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'STORE MERCHANT',
                        style: AppTypography.overline.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(order.storeName,
                          style: AppTypography.labelLarge
                              .copyWith(color: AppColors.textPrimary)),
                      if (order.storeCity != null)
                        Text('Location: ${order.storeCity}',
                            style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary)),
                      if (order.storeContact != null)
                        Text('Contact: ${order.storeContact}',
                            style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary)),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.lg),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SHIPPING ADDRESS',
                        style: AppTypography.overline.copyWith(
                          color: AppColors.textSecondary,
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(order.deliveryAddress.name,
                          style: AppTypography.labelLarge
                              .copyWith(color: AppColors.textPrimary)),
                      Text(
                          '${order.deliveryAddress.addressLine}, ${order.deliveryAddress.city}',
                          style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary)),
                      Text('Payment Method: CASH ON DELIVERY (UNPAID)',
                          style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary)),
                    ],
                  ),
                ),
              ],
            ),
          ),

          if (order.statusHistory.isNotEmpty) ...[
            const Divider(height: 1, color: AppColors.divider),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seller Status History & Updates',
                    style: AppTypography.sectionHeading
                        .copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ...order.statusHistory
                      .map((e) => _HistoryRow(event: e)),
                ],
              ),
            ),
          ],

          // CTA
          Padding(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, 0, AppSpacing.lg, AppSpacing.lg),
            child: ElevatedButton.icon(
              onPressed: () => context.push('/orders/${order.referenceNumber}', extra: order),
              icon: const Icon(Icons.open_in_new_rounded, size: 16),
              label: const Text('View Full Order Details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                minimumSize:
                    const Size.fromHeight(AppDimensions.touchTarget),
                elevation: 0,
                shape: RoundedRectangleBorder(
                    borderRadius: AppDimensions.radiusSm),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(DateTime dt) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month]} ${dt.day}, ${dt.year} · $h:$m $ap';
  }
}

class _HistoryRow extends StatelessWidget {
  final OrderStatusEvent event;
  const _HistoryRow({required this.event});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                  color: event.status.color, shape: BoxShape.circle),
            ),
            Container(width: 2, height: 24, color: AppColors.divider),
          ]),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(event.status.label,
                        style: AppTypography.labelMedium
                            .copyWith(color: event.status.color)),
                    Text(_fmtShort(event.timestamp),
                        style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary)),
                  ],
                ),
                if (event.note != null) ...[
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: Text('Seller Note: ${event.note}',
                        style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtShort(DateTime dt) {
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final h = dt.hour > 12 ? dt.hour - 12 : dt.hour == 0 ? 12 : dt.hour;
    final ap = dt.hour >= 12 ? 'PM' : 'AM';
    final m = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month]} ${dt.day}, ${dt.year} · $h:$m $ap';
  }
}

