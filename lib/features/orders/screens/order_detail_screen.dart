import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late Order currentOrder;

  @override
  void initState() {
    super.initState();
    currentOrder = widget.order;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OrderCubit, OrderState>(
      listener: (context, state) {
        if (state is OrderCancelled) {
          // Update order status to cancelled
          setState(() {
            currentOrder = Order(
              id: currentOrder.id,
              referenceNumber: currentOrder.referenceNumber,
              placedAt: currentOrder.placedAt,
              status: OrderStatus.cancelled,
              items: currentOrder.items,
              deliveryAddress: currentOrder.deliveryAddress,
              subtotal: currentOrder.subtotal,
              deliveryFee: currentOrder.deliveryFee,
              discount: currentOrder.discount,
              storeName: currentOrder.storeName,
              storeCity: currentOrder.storeCity,
              storeContact: currentOrder.storeContact,
              estimatedDelivery: currentOrder.estimatedDelivery,
              statusHistory: currentOrder.statusHistory,
            );
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Order cancelled successfully'),
              backgroundColor: AppColors.statusCancelled,
              duration: Duration(seconds: 2),
            ),
          );

          // Reload orders to update the orders list, then navigate back
          Future.delayed(const Duration(seconds: 2), () {
            if (!context.mounted) return;
            context.read<OrderCubit>().loadOrders();
            context.go('/orders');
          });
        }
        if (state is OrderError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
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
            'Order Details',
            style: AppTypography.screenTitle
                .copyWith(color: AppColors.textPrimary),
          ),
          actions: [
            // 3-dot menu
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded,
                  color: AppColors.textPrimary),
              onSelected: (value) {
                switch (value) {
                  case 'help':
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Opening support...')),
                    );
                    break;
                  case 'share':
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Sharing order...')),
                    );
                    break;
                }
              },
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem<String>(
                  value: 'share',
                  child: Row(
                    children: [
                      Icon(Icons.share_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Share'),
                    ],
                  ),
                ),
                const PopupMenuItem<String>(
                  value: 'help',
                  child: Row(
                    children: [
                      Icon(Icons.help_outline_rounded, size: 20),
                      SizedBox(width: 12),
                      Text('Need Help?'),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            _OrderHeaderCard(order: currentOrder),
            const SizedBox(height: AppSpacing.md),
            _FulfillmentCard(order: currentOrder),
            const SizedBox(height: AppSpacing.md),
            _StoreAndAddressRow(order: currentOrder),
            const SizedBox(height: AppSpacing.md),
            if (currentOrder.statusHistory.isNotEmpty) ...[
              _StatusHistoryCard(history: currentOrder.statusHistory),
              const SizedBox(height: AppSpacing.md),
            ],
            _OrderItemsCard(order: currentOrder),
            const SizedBox(height: AppSpacing.md),
            _PriceBreakdownCard(order: currentOrder),
            const SizedBox(height: AppSpacing.xl),
            _ActionButtons(order: currentOrder),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}

// ─── Header card ──────────────────────────────────────────────────────────────

class _OrderHeaderCard extends StatelessWidget {
  final Order order;
  const _OrderHeaderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return _Card(
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
                  letterSpacing: 1.2,
                  fontWeight: FontWeight.w700,
                ),
              ),
              OrderStatusBadge(status: order.status, large: true),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          GestureDetector(
            onTap: () {
              Clipboard.setData(
                  ClipboardData(text: order.referenceNumber));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invoice number copied'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Invoice #${order.referenceNumber}',
                    style: AppTypography.screenTitle.copyWith(
                      color: AppColors.textPrimary,
                      fontSize: 18,
                    ),
                  ),
                ),
                const Icon(Icons.copy_rounded,
                    size: 14, color: AppColors.textSecondary),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Placed on ${_formatFull(order.placedAt)}',
            style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'PKR ${order.total.toStringAsFixed(0)}',
            style: AppTypography.priceTotal.copyWith(
              color: AppColors.primary,
              fontSize: 22,
            ),
          ),
        ],
      ),
    );
  }

  String _formatFull(DateTime dt) {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final hour = dt.hour > 12
        ? dt.hour - 12
        : dt.hour == 0
            ? 12
            : dt.hour;
    final ampm = dt.hour >= 12 ? 'PM' : 'AM';
    final min = dt.minute.toString().padLeft(2, '0');
    return '${months[dt.month]} ${dt.day}, ${dt.year} · $hour:$min $ampm';
  }
}

// ─── Fulfillment / tracking card ──────────────────────────────────────────────

class _FulfillmentCard extends StatelessWidget {
  final Order order;
  const _FulfillmentCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fulfillment Progress',
            style: AppTypography.sectionHeading
                .copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.lg),
          OrderTimeline(currentStatus: order.status),
          const SizedBox(height: AppSpacing.lg),
          // Status alert box
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
          if (order.estimatedDelivery != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Icon(Icons.local_shipping_outlined,
                    size: 13, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  order.estimatedDelivery!,
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ─── Store merchant + Shipping address (side-by-side) ────────────────────────

class _StoreAndAddressRow extends StatelessWidget {
  final Order order;
  const _StoreAndAddressRow({required this.order});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _Card(
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
                const SizedBox(height: AppSpacing.sm),
                Text(
                  order.storeName,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (order.storeCity != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Location: ${order.storeCity}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
                if (order.storeContact != null) ...[
                  const SizedBox(height: 3),
                  Text(
                    'Contact: ${order.storeContact}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _Card(
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
                const SizedBox(height: AppSpacing.sm),
                Text(
                  order.deliveryAddress.name,
                  style: AppTypography.labelLarge.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${order.deliveryAddress.addressLine}, ${order.deliveryAddress.city}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Payment Method: CASH ON DELIVERY (UNPAID)',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Seller status history ────────────────────────────────────────────────────

class _StatusHistoryCard extends StatelessWidget {
  final List<OrderStatusEvent> history;
  const _StatusHistoryCard({required this.history});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Seller Status History & Updates',
            style: AppTypography.sectionHeading
                .copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          ...history.asMap().entries.map((e) => _HistoryEventRow(
            event: e.value,
            isLast: e.key == history.length - 1,
          )),
        ],
      ),
    );
  }
}

class _HistoryEventRow extends StatelessWidget {
  final OrderStatusEvent event;
  final bool isLast;
  const _HistoryEventRow({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: event.status.color,
                  shape: BoxShape.circle,
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 30,
                  color: event.status.color.withValues(alpha: 0.3),
                  margin: const EdgeInsets.symmetric(vertical: 4),
                ),
            ],
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.status.label,
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
                if (event.note != null)
                  Text(
                    event.note!,
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                Text(
                  _formatTime(event.timestamp),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textDisabled,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inDays > 0) return '${diff.inDays} day${diff.inDays > 1 ? 's' : ''} ago';
    if (diff.inHours > 0) return '${diff.inHours} hour${diff.inHours > 1 ? 's' : ''} ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes} minute${diff.inMinutes > 1 ? 's' : ''} ago';
    return 'Just now';
  }
}

// ─── Order items table ────────────────────────────────────────────────────────

class _OrderItemsCard extends StatelessWidget {
  final Order order;
  const _OrderItemsCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Order Items',
            style: AppTypography.sectionHeading
                .copyWith(color: AppColors.textPrimary),
          ),
          const SizedBox(height: AppSpacing.md),
          // Table header
          Container(
            padding: const EdgeInsets.symmetric(
              vertical: AppSpacing.sm,
              horizontal: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: AppDimensions.radiusSm,
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 5,
                  child: Text(
                    'Item Name',
                    style: AppTypography.overline.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                SizedBox(
                  width: 40,
                  child: Text(
                    'Qty',
                    style: AppTypography.overline.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(
                  width: 80,
                  child: Text(
                    'Subtotal',
                    style: AppTypography.overline.copyWith(
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: AppSpacing.md, color: AppColors.divider),
          ...order.items.map((item) => _ItemTableRow(item: item)),
        ],
      ),
    );
  }
}

class _ItemTableRow extends StatelessWidget {
  final OrderItem item;
  const _ItemTableRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.divider),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image placeholder
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.divider),
              ),
              child: Center(
                child: Icon(
                  Icons.image_not_supported_outlined,
                  size: 24,
                  color: AppColors.textDisabled,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (item.sku != null || item.variantLabel != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (item.sku != null) 'SKU: ${item.sku}',
                        if (item.variantLabel != null) item.variantLabel!,
                      ].join(' · '),
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Qty: ${item.quantity}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      Text(
                        'PKR ${item.subtotal.toStringAsFixed(0)}',
                        style: AppTypography.labelMedium.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Price breakdown card ──────────────────────────────────────────────────────

class _PriceBreakdownCard extends StatelessWidget {
  final Order order;
  const _PriceBreakdownCard({required this.order});

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          _PriceRow(label: 'Subtotal', value: 'PKR ${order.subtotal.toStringAsFixed(0)}'),
          _PriceRow(label: 'Delivery Fee', value: 'PKR ${order.deliveryFee.toStringAsFixed(0)}'),
          if (order.discount > 0)
            _PriceRow(
              label: 'Discount',
              value: '- PKR ${order.discount.toStringAsFixed(0)}',
              valueColor: AppColors.statusDelivered,
            ),
          const Divider(color: AppColors.divider),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total',
                style: AppTypography.labelLarge.copyWith(
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                'PKR ${order.total.toStringAsFixed(0)}',
                style: AppTypography.priceTotal.copyWith(
                  fontSize: 18,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              const Icon(Icons.payments_outlined,
                  size: 13, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Text(
                'Cash on Delivery (Unpaid)',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _PriceRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodyMedium.copyWith(
              color: valueColor ?? AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Action buttons ───────────────────────────────────────────────────────────

class _ActionButtons extends StatelessWidget {
  final Order order;
  const _ActionButtons({required this.order});

  bool get _canCancel =>
      order.status == OrderStatus.pending ||
      order.status == OrderStatus.processing;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Cancel order button for pending and processing orders only
        if (_canCancel)
          OutlinedButton.icon(
            onPressed: () => _showCancellationReasonDialog(context),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.statusCancelled,
              side: const BorderSide(color: AppColors.statusCancelled),
              minimumSize:
                  const Size.fromHeight(AppDimensions.touchTarget),
              shape: RoundedRectangleBorder(
                  borderRadius: AppDimensions.radiusSm),
            ),
            icon: const Icon(Icons.close_rounded, size: 18),
            label: const Text('Cancel Order'),
          ),
        if (order.status == OrderStatus.delivered) ...[
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Adding items to cart...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Reorder'),
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
          const SizedBox(height: AppSpacing.md),
          OutlinedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Return initiated...'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            icon: const Icon(Icons.assignment_return_rounded, size: 18),
            label: const Text('Request Return'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.textPrimary,
              side: const BorderSide(color: AppColors.divider),
              minimumSize:
                  const Size.fromHeight(AppDimensions.touchTarget),
              shape: RoundedRectangleBorder(
                  borderRadius: AppDimensions.radiusSm),
            ),
          ),
        ],
      ],
    );
  }

  void _showCancellationReasonDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _OrderCancellationReasonDialog(
        orderId: order.id,
        parentContext: context,
      ),
    );
  }
}

// ─── Shared card container ────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.radiusMd,
        boxShadow: AppDimensions.cardShadow,
        border: Border.all(color: AppColors.divider, width: 0.8),
      ),
      child: child,
    );
  }
}

// ─── Order-Level Cancellation Reason Dialog ────────────────────────────────────

class _OrderCancellationReasonDialog extends StatefulWidget {
  final String orderId;
  final BuildContext parentContext;

  const _OrderCancellationReasonDialog({
    required this.orderId,
    required this.parentContext,
  });

  @override
  State<_OrderCancellationReasonDialog> createState() =>
      _OrderCancellationReasonDialogState();
}

class _OrderCancellationReasonDialogState extends State<_OrderCancellationReasonDialog> {
  String? selectedReason;
  final customReasonCtrl = TextEditingController();

  @override
  void dispose() {
    customReasonCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Cancel Order',
                  style: AppTypography.sectionHeading,
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Please select a reason for cancellation',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    ...cancellationReasons.map((reason) =>
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                        child: InkWell(
                          onTap: () =>
                              setState(() => selectedReason = reason),
                          child: Row(
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(3),
                                  border: Border.all(
                                    color: selectedReason == reason
                                        ? AppColors.primary
                                        : AppColors.divider,
                                    width: 2,
                                  ),
                                ),
                                child: selectedReason == reason
                                    ? const Icon(
                                      Icons.check,
                                      size: 14,
                                      color: AppColors.primary,
                                    )
                                    : null,
                              ),
                              const SizedBox(width: AppSpacing.md),
                              Expanded(
                                child: Text(
                                  reason,
                                  style: AppTypography.bodySmall,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextField(
                      controller: customReasonCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'Other reason (optional)...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(6),
                        ),
                        contentPadding: const EdgeInsets.all(AppSpacing.md),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Keep Order'),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: ElevatedButton(
                    onPressed: (selectedReason != null ||
                            customReasonCtrl.text.isNotEmpty)
                        ? () {
                          final reason =
                              selectedReason ?? customReasonCtrl.text;
                          Navigator.pop(context);
                          widget.parentContext
                              .read<OrderCubit>()
                              .cancelOrder(widget.orderId);
                          ScaffoldMessenger.of(widget.parentContext)
                              .showSnackBar(
                            SnackBar(
                              content: Text(
                                'Order cancelled\nReason: $reason',
                              ),
                              backgroundColor: AppColors.primary,
                              duration: const Duration(seconds: 3),
                            ),
                          );
                        }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.statusCancelled,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Confirm Cancel'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
