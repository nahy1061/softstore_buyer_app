import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/buyer.dart';
import '../../services/account_service.dart';
import '../marketplace/product_detail_screen.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});
  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final _svc = AccountService();
  List<WishlistItem> _items = [];
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final items = await _svc.wishlist();
      setState(() { _items = items; _loading = false; });
    } catch (_) { setState(() => _loading = false); }
  }

  Future<void> _remove(WishlistItem item) async {
    try {
      await _svc.toggleWishlist(item.productId);
      _load();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Wishlist')),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandOrange))
          : _items.isEmpty
              ? const Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.favorite_outline, size: 64, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Your wishlist is empty', style: TextStyle(fontSize: 16, color: Colors.grey)),
                ]))
              : GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, childAspectRatio: 0.72, mainAxisSpacing: 12, crossAxisSpacing: 12),
                  itemCount: _items.length,
                  itemBuilder: (_, i) {
                    final item = _items[i];
                    return GestureDetector(
                      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(identifier: '${item.productId}'))),
                      child: Container(
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))]),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Stack(children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
                              child: item.imageUrl != null
                                  ? CachedNetworkImage(imageUrl: item.imageUrl!, height: 140, width: double.infinity, fit: BoxFit.cover)
                                  : Container(height: 140, color: Colors.grey[100], child: const Center(child: Icon(Icons.image_outlined, color: Colors.grey, size: 40))),
                            ),
                            Positioned(top: 8, right: 8, child: GestureDetector(
                              onTap: () => _remove(item),
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]),
                                child: const Icon(Icons.favorite, color: AppColors.danger, size: 18),
                              ),
                            )),
                          ]),
                          Padding(
                            padding: const EdgeInsets.all(10),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, height: 1.3)),
                              const SizedBox(height: 4),
                              Text('PKR ${item.sellingPrice.toInt()}', style: const TextStyle(color: AppColors.brandOrange, fontWeight: FontWeight.w700)),
                            ]),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
    );
  }
}
