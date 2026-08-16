import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/theme/app_theme.dart';
import '../../core/models/product.dart';
import '../../core/models/cart_item.dart';
import '../../core/storage/cart_store.dart';
import '../../core/storage/session_store.dart';
import '../../services/catalog_service.dart';
import '../../services/account_service.dart';
import 'store_detail_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final String identifier;
  const ProductDetailScreen({super.key, required this.identifier});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  final _catalog = CatalogService();
  final _account = AccountService();
  ProductDetailResponse? _detail;
  bool _loading = true;
  String? _error;
  int _selectedVariantIdx = -1;
  int _quantity = 1;
  int _galleryIdx = 0;
  bool _togglingWishlist = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _loading = true; _error = null; });
    try {
      final detail = await _catalog.productDetail(widget.identifier);
      setState(() { _detail = detail; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  ProductVariant? get _selectedVariant => _selectedVariantIdx >= 0 && _detail != null && _selectedVariantIdx < _detail!.variants.length
      ? _detail!.variants[_selectedVariantIdx]
      : null;

  double get _effectivePrice {
    if (_selectedVariant?.sellingPrice != null) return _selectedVariant!.sellingPrice!;
    return _detail?.product.displayPrice ?? 0;
  }

  void _addToCart() {
    final d = _detail;
    if (d == null) return;
    if (d.variants.isNotEmpty && _selectedVariantIdx < 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select a variant')));
      return;
    }
    CartStore.instance.addItem(CartItem(
      productId: d.product.id,
      variantId: _selectedVariant?.id,
      quantity: _quantity,
      productName: d.product.productName,
      imageUrl: d.gallery.isNotEmpty ? d.gallery.first : null,
      unitPriceSnapshot: _effectivePrice,
      variantLabel: _selectedVariant?.name,
      isAgeRestricted: d.product.isAgeRestricted ?? false,
    ));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Added to cart'),
        action: SnackBarAction(label: 'View Cart', onPressed: () => Navigator.of(context).popUntil((r) => r.isFirst)),
      ),
    );
  }

  Future<void> _toggleWishlist() async {
    if (!SessionStore.instance.isSignedIn) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please sign in to save items')));
      return;
    }
    if (_togglingWishlist) return;
    setState(() { _togglingWishlist = true; });
    try {
      await _account.toggleWishlist(_detail!.product.id);
      setState(() {
        _detail!.isWishlisted = !_detail!.isWishlisted;
        _detail!.product.isWishlisted = _detail!.isWishlisted;
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    } finally {
      if (mounted) setState(() { _togglingWishlist = false; });
    }
  }

  Future<void> _contactSeller() async {
    final slug = _detail?.product.sellerSlug;
    if (slug != null) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => StoreDetailScreen(slug: slug)));
    }
  }

  Future<void> _openWhatsapp() async {
    final url = _detail?.whatsappUrl;
    if (url != null) {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) await launchUrl(uri);
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
      bottomNavigationBar: _detail != null ? _buildBottomBar() : null,
    );
  }

  Widget _buildContent() {
    final d = _detail!;
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 320,
          pinned: true,
          backgroundColor: Colors.white,
          foregroundColor: Colors.black,
          actions: [
            IconButton(
              onPressed: _toggleWishlist,
              icon: _togglingWishlist
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.brandOrange))
                  : Icon(d.isWishlisted ? Icons.favorite : Icons.favorite_border,
                      color: d.isWishlisted ? AppColors.danger : Colors.grey),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: _buildGallery(d.gallery),
          ),
        ),
        SliverToBoxAdapter(child: _buildDetails(d)),
      ],
    );
  }

  Widget _buildGallery(List<String> gallery) {
    if (gallery.isEmpty) {
      return Container(color: Colors.grey[100], child: const Center(child: Icon(Icons.image_outlined, size: 80, color: Colors.grey)));
    }
    return Stack(children: [
      PageView.builder(
        itemCount: gallery.length,
        onPageChanged: (i) => setState(() => _galleryIdx = i),
        itemBuilder: (_, i) => CachedNetworkImage(
          imageUrl: gallery[i],
          fit: BoxFit.contain,
          placeholder: (_, __) => Container(color: Colors.grey[100]),
          errorWidget: (_, __, ___) => Container(color: Colors.grey[100], child: const Icon(Icons.image_outlined, color: Colors.grey)),
        ),
      ),
      if (gallery.length > 1)
        Positioned(
          bottom: 12,
          left: 0, right: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(gallery.length, (i) => Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: _galleryIdx == i ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: _galleryIdx == i ? AppColors.brandOrange : Colors.grey[300],
                borderRadius: BorderRadius.circular(4),
              ),
            )),
          ),
        ),
    ]);
  }

  Widget _buildDetails(ProductDetailResponse d) {
    final p = d.product;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Price
        Row(children: [
          Text(
            'PKR ${_formatPrice(_effectivePrice)}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.brandOrange),
          ),
          if (p.hasDiscount) ...[
            const SizedBox(width: 10),
            Text(
              'PKR ${_formatPrice(p.displayListPrice)}',
              style: const TextStyle(fontSize: 15, color: Colors.grey, decoration: TextDecoration.lineThrough),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: AppColors.danger, borderRadius: BorderRadius.circular(6)),
              child: Text('${p.discountPercent.toInt()}% OFF', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
            ),
          ],
        ]),
        const SizedBox(height: 10),
        // Title
        Text(p.productName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, height: 1.3)),
        const SizedBox(height: 8),
        // Stock
        Row(children: [
          Icon(p.inStock ? Icons.check_circle : Icons.cancel, size: 16, color: p.inStock ? AppColors.success : AppColors.danger),
          const SizedBox(width: 5),
          Text(p.inStock ? 'In Stock' : 'Out of Stock', style: TextStyle(color: p.inStock ? AppColors.success : AppColors.danger, fontWeight: FontWeight.w600)),
        ]),
        // Seller
        if (p.sellerName != null) ...[
          const SizedBox(height: 12),
          GestureDetector(
            onTap: _contactSeller,
            child: Row(children: [
              const Icon(Icons.store_outlined, size: 18, color: Colors.grey),
              const SizedBox(width: 6),
              Text(p.sellerName!, style: const TextStyle(color: AppColors.brandOrange, fontWeight: FontWeight.w600)),
              if (p.sellerCity != null) Text(' · ${p.sellerCity}', style: const TextStyle(color: Colors.grey, fontSize: 13)),
            ]),
          ),
        ],
        // Variants
        if (d.variants.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text('Select Variant', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: d.variants.asMap().entries.map((e) {
              final v = e.value;
              final selected = _selectedVariantIdx == e.key;
              return GestureDetector(
                onTap: () => setState(() => _selectedVariantIdx = e.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.brandOrange : Colors.white,
                    border: Border.all(color: selected ? AppColors.brandOrange : Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: Text(v.name ?? 'Variant ${e.key + 1}', style: TextStyle(color: selected ? Colors.white : Colors.black, fontWeight: selected ? FontWeight.w600 : FontWeight.normal)),
                ),
              );
            }).toList(),
          ),
        ],
        // Quantity
        const SizedBox(height: 16),
        Row(children: [
          const Text('Quantity:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          const SizedBox(width: 16),
          _QuantityControl(
            value: _quantity,
            onDecrement: () => setState(() { if (_quantity > 1) _quantity--; }),
            onIncrement: () => setState(() { if (_quantity < (d.availableStock.toInt().clamp(1, 99))) _quantity++; }),
          ),
        ]),
        const SizedBox(height: 20),
        // Description
        if (p.description != null && p.description!.isNotEmpty) ...[
          const Divider(),
          const SizedBox(height: 12),
          const Text('Description', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          Text(p.description!, style: const TextStyle(height: 1.6, color: Colors.black87)),
          const SizedBox(height: 16),
        ],
        // WhatsApp
        if (d.whatsappUrl != null) ...[
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _openWhatsapp,
            icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
            label: const Text('WhatsApp Seller'),
            style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFF25D366), side: const BorderSide(color: Color(0xFF25D366))),
          ),
          const SizedBox(height: 12),
        ],
        // Reviews
        if (d.reviews.isNotEmpty) ...[
          const Divider(),
          const SizedBox(height: 12),
          Text('Reviews (${d.reviews.length})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 8),
          ...d.reviews.take(3).map((r) => _ReviewTile(review: r)),
          const SizedBox(height: 16),
        ],
        // Related
        if (d.relatedProducts.isNotEmpty) ...[
          const Divider(),
          const SizedBox(height: 12),
          const Text('Related Products', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          const SizedBox(height: 12),
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: d.relatedProducts.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) {
                final rp = d.relatedProducts[i];
                return GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductDetailScreen(identifier: rp.slug ?? '${rp.id}'))),
                  child: Container(
                    width: 130,
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(AppRadius.md), border: Border.all(color: Colors.grey[200]!)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.md)),
                        child: rp.imageUrl != null
                            ? CachedNetworkImage(imageUrl: rp.imageUrl!, height: 110, width: 130, fit: BoxFit.cover)
                            : Container(height: 110, color: Colors.grey[100], child: const Center(child: Icon(Icons.image_outlined, color: Colors.grey))),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(rp.productName, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                          const SizedBox(height: 4),
                          Text('PKR ${_formatPrice(rp.displayPrice)}', style: const TextStyle(color: AppColors.brandOrange, fontWeight: FontWeight.w700, fontSize: 12)),
                        ]),
                      ),
                    ]),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 80),
        ],
      ]),
    );
  }

  Widget _buildBottomBar() {
    final p = _detail!.product;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 12, offset: const Offset(0, -4))],
      ),
      child: Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: p.inStock ? _addToCart : null,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: const BorderSide(color: AppColors.brandOrange),
              foregroundColor: AppColors.brandOrange,
            ),
            child: const Text('Add to Cart', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: p.inStock ? () { _addToCart(); } : null,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              backgroundColor: AppColors.brandOrange,
            ),
            child: const Text('Buy Now', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ]),
    );
  }

  String _formatPrice(double price) {
    if (price == price.toInt().toDouble()) return price.toInt().toString();
    return price.toStringAsFixed(0);
  }
}

class _QuantityControl extends StatelessWidget {
  final int value;
  final VoidCallback onDecrement;
  final VoidCallback onIncrement;
  const _QuantityControl({required this.value, required this.onDecrement, required this.onIncrement});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      IconButton(onPressed: onDecrement, icon: const Icon(Icons.remove_circle_outline), color: AppColors.brandOrange),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(border: Border.all(color: Colors.grey[300]!), borderRadius: BorderRadius.circular(8)),
        child: Text('$value', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
      ),
      IconButton(onPressed: onIncrement, icon: const Icon(Icons.add_circle_outline), color: AppColors.brandOrange),
    ]);
  }
}

class _ReviewTile extends StatelessWidget {
  final ProductReview review;
  const _ReviewTile({required this.review});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(AppRadius.sm)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          ...List.generate(5, (i) => Icon(i < review.rating ? Icons.star : Icons.star_border, size: 16, color: AppColors.brandAmber)),
          const SizedBox(width: 8),
          Text(review.reviewerName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const Spacer(),
          if (review.createdAt != null) Text(review.createdAt!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        ]),
        if (review.reviewText != null && review.reviewText!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(review.reviewText!, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ]),
    );
  }
}
