import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/order.dart';
import '../../services/account_service.dart';
import 'request_return_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;
  const OrderDetailScreen({super.key, required this.orderId});
  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final _svc = AccountService();
  OrderDetailResponse? _detail;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final d = await _svc.orderDetail(widget.orderId);
      setState(() { _detail = d; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Color _statusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending: return AppColors.warning;
      case OrderStatus.confirmed: return AppColors.brandOrange;
      case OrderStatus.processing: return AppColors.brandAmber;
      case OrderStatus.shipped: return Colors.blue;
      case OrderStatus.delivered: return AppColors.success;
      case OrderStatus.cancelled: return AppColors.danger;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(_detail?.order.invoiceNumber ?? 'Order'),
        actions: [
          if (_detail?.returnEligibility.eligible == true)
            TextButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => RequestReturnScreen(order: _detail!.order))),
              child: const Text('Return', style: TextStyle(color: AppColors.brandOrange)),
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandOrange))
          : _detail == null
              ? const Center(child: Text('Could not load order'))
              : _buildBody(),
    );
  }

  Widget _buildBody() {
    final d = _detail!;
    final order = d.order;
    final statusColor = _statusColor(order.saleStatus);

    return ListView(padding: const EdgeInsets.all(16), children: [
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: Colors.grey[200]!)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(order.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Text(order.saleStatus.label, style: TextStyle(color: statusColor, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 6),
          Row(children: [
            const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.grey),
            const SizedBox(width: 4),
            Text(order.createdAt, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ]),
        ]),
      ),
      const SizedBox(height: 12),
      if (order.items != null && order.items!.isNotEmpty) ...[
        _sectionHeader('Order Items'),
        ...order.items!.map((item) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.sm), border: Border.all(color: Colors.grey[200]!)),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.productName, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text('Qty: ${item.quantity.toInt()}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ])),
            Text('PKR ${item.subtotal.toInt()}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.brandOrange)),
          ]),
        )),
        const SizedBox(height: 12),
      ],
      _sectionHeader('Price Summary'),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: Colors.grey[200]!)),
        child: Column(children: [
          _row('Subtotal', 'PKR ${order.subtotal.toInt()}'),
          _row('Delivery', 'PKR ${order.deliveryFee.toInt()}'),
          if (order.discountAmount > 0) _row('Discount', '- PKR ${order.discountAmount.toInt()}', valueColor: AppColors.success),
          const Divider(height: 20),
          _row('Total', 'PKR ${order.grandTotal.toInt()}', bold: true),
        ]),
      ),
      if (d.statusHistory.isNotEmpty) ...[
        const SizedBox(height: 12),
        _sectionHeader('Status History'),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: Colors.grey[200]!)),
          child: Column(children: d.statusHistory.map((e) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(width: 8, height: 8, margin: const EdgeInsets.only(top: 4, right: 10), decoration: BoxDecoration(color: AppColors.brandOrange, shape: BoxShape.circle)),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(e.newStatus.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                if (e.notes != null) Text(e.notes!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(e.createdAt, style: const TextStyle(color: Colors.grey, fontSize: 11)),
              ])),
            ]),
          )).toList()),
        ),
      ],
      const SizedBox(height: 24),
    ]);
  }

  Widget _sectionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
  );

  Widget _row(String label, String value, {bool bold = false, Color? valueColor}) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(children: [
      Expanded(child: Text(label, style: const TextStyle(color: Colors.grey))),
      Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w700 : FontWeight.w500, color: valueColor ?? (bold ? AppColors.brandOrange : Colors.black87))),
    ]),
  );
}
