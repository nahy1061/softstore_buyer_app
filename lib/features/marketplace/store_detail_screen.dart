import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/product.dart';
import '../../services/catalog_service.dart';
import 'product_detail_screen.dart';

class StoreDetailScreen extends StatefulWidget {
  final String slug;
  const StoreDetailScreen({super.key, required this.slug});

  @override
  State<StoreDetailScreen> createState() => _StoreDetailScreenState();
}

class _StoreDetailScreenState extends State<StoreDetailScreen> {
  final _catalog = CatalogService();
  StoreDetailResponse? _detail;
  bool _loading = true;
  String? _error;
  int _page = 1;
  bool _loadingMore = false;
  final _scrollCtrl = ScrollController();
  String _sort = 'newest';
  String? _categoryFilter;

  @override
  void initState() {
    super.initState();
    _load();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200 && !_loadingMore) {
      final d = _detail;
      if (d != null && _page < d.totalPages) _loadMore();
    }
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final detail = await _catalog.storeDetail(widget.slug, category: _categoryFilter, sort: _sort);
      setState(() { _detail = detail; _loading = false; _page = 1; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore) return;
    setState(() => _loadingMore = true);
    try {
      final more = await _catalog.storeDetail(widget.slug, page: _page + 1, category: _categoryFilter, sort: _sort);
      setState(() {
        _detail!.products.addAll(more.products);
        _page++;
        _loadingMore = false;
      });
    } catch (_) {
      setState(() => _loadingMore = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.brandOrange))
          : _error != null
              ? Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Text(_error!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(onPressed: _load, child: const Text('Retry')),
                ]))
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final d = _detail!;
    return CustomScrollView(
      controller: _scrollCtrl,
      slivers: [
        SliverAppBar(
          expandedHeight: 160,
          pinned: true,
          backgroundColor: AppColors.brandOrange,
          foregroundColor: Colors.white,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.brandOrange, AppColors.brandAmber],
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 80, 16, 16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(d.businessName, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800)),
                  if (d.city != null) ...[
                    const SizedBox(height: 4),
                    Row(children: [
                      const Icon(Icons.location_on, color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(d.city!, style: const TextStyle(color: Colors.white70, fontSize: 13)),
                    ]),
                  ],
                  const SizedBox(height: 8),
                  Row(children: [
                    _StoreStatChip(icon: Icons.group, label: '${d.followerCount} followers'),
                    const SizedBox(width: 12),
                    _StoreStatChip(icon: Icons.inventory_2_outlined, label: '${d.total} products'),
                    if (d.rating != null) ...[
                      const SizedBox(width: 12),
                      _StoreStatChip(icon: Icons.star, label: d.rating!.toStringAsFixed(1)),
                    ],
                  ]),
                ]),
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(children: [
              Expanded(child: _SortDropdown(value: _sort, onChanged: (v) { _sort = v!; _load(); })),
            ]),
          ),
        ),
        if (d.products.isEmpty)
          const SliverFillRemaining(child: Center(child: Text('No products found.', style: TextStyle(color: Colors.grey))))
        else
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) {
                  if (i == d.products.length) {
                    return _loadingMore
                        ? const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator(color: AppColors.brandOrange)))
                        : const SizedBox.shrink();
                  }
                  return _ProductGridCard(
                    product: d.products[i],
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(identifier: d.products[i].slug ?? '${d.products[i].id}'))),
                  );
                },
                childCount: d.products.length + (_loadingMore ? 1 : 0),
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.68,
              ),
            ),
          ),
      ],
    );
  }
}

class _StoreStatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StoreStatChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, color: Colors.white, size: 13),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
      ]),
    );
  }
}

class _SortDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;
  const _SortDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: DropdownButton<String>(
        value: value,
        onChanged: onChanged,
        isExpanded: true,
        isDense: true,
        underline: const SizedBox.shrink(),
        items: const [
          DropdownMenuItem(value: 'newest', child: Text('Newest')),
          DropdownMenuItem(value: 'price_low', child: Text('Price: Low to High')),
          DropdownMenuItem(value: 'price_high', child: Text('Price: High to Low')),
          DropdownMenuItem(value: 'top_rated', child: Text('Top Rated')),
          DropdownMenuItem(value: 'best_selling', child: Text('Best Selling')),
        ],
      ),
    );
  }
}

class _ProductGridCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  const _ProductGridCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
              child: product.imageUrl != null
                  ? CachedNetworkImage(imageUrl: product.imageUrl!, fit: BoxFit.cover, width: double.infinity)
                  : Container(color: Colors.grey[100], child: const Center(child: Icon(Icons.image_outlined, size: 40, color: Colors.grey))),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(product.productName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Row(children: [
                Text('PKR ${_fmt(product.displayPrice)}', style: const TextStyle(color: AppColors.brandOrange, fontWeight: FontWeight.w800, fontSize: 14)),
                if (product.hasDiscount) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(color: AppColors.danger.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                    child: Text('${product.discountPercent.toInt()}%', style: const TextStyle(color: AppColors.danger, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ]),
            ]),
          ),
        ]),
      ),
    );
  }

  String _fmt(double v) => v.toInt().toString();
}
