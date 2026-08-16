import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/order.dart';
import '../../services/account_service.dart';
import 'order_detail_screen.dart';

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});
  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final _svc = AccountService();
  List<Order> _orders = [];
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  bool _hasMore = true;
  final _scrollCtrl = ScrollController();

  @override
  void initState() {
    super.initState();
    _load();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() { _scrollCtrl.dispose(); super.dispose(); }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 && !_loadingMore && _hasMore) {
      _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _page = 1; _hasMore = true; });
    try {
      final page = await _svc.orders(1);
      setState(() {
        _orders = page.orders;
        _hasMore = page.page < page.totalPages;
        _loading = false;
      });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore) return;
    setState(() => _loadingMore = true);
    try {
      final next = _page + 1;
      final page = await _svc.orders(next);
      setState(() {
        _orders.addAll(page.orders);
        _page = next;
        _hasMore = next < page.totalPages;
        _loadingMore = false;
      });
    } catch (_) { setState(() => _loadingMore = false); }
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
      appBar: AppBar(title: const Text('My Orders')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandOrange))
          : _orders.isEmpty
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('No orders yet', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ]))
              : RefreshIndicator(
                  onRefresh: _load,
                  color: AppColors.brandOrange,
                  child: ListView.builder(
                    controller: _scrollCtrl,
                    padding: const EdgeInsets.all(12),
                    itemCount: _orders.length + (_loadingMore ? 1 : 0),
                    itemBuilder: (_, i) {
                      if (i == _orders.length) return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.brandOrange)));
                      final order = _orders[i];
                      final statusColor = _statusColor(order.saleStatus);
                      return GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderDetailScreen(orderId: order.id))),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: Colors.grey[200]!)),
                          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Row(children: [
                              Expanded(child: Text(order.invoiceNumber, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                                child: Text(order.saleStatus.label, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12)),
                              ),
                            ]),
                            const SizedBox(height: 6),
                            Text(order.createdAt, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                            const SizedBox(height: 8),
                            Row(children: [
                              Text('${order.itemsCount ?? 0} item${(order.itemsCount ?? 0) == 1 ? '' : 's'}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
                              const Spacer(),
                              Text('PKR ${order.grandTotal.toInt()}', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.brandOrange, fontSize: 15)),
                            ]),
                          ]),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
