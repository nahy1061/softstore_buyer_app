import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../../app/router.dart';
import '../../../core/config/env_config.dart';
import '../../../core/constants/app_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../../auth/screens/login_screen.dart';
import '../../cart/cubit/cart_cubit.dart';
import '../../cart/cubit/cart_state.dart';
import '../../cart/models/cart_models.dart';
import '../../catalog/models/catalog_models.dart';
import '../../catalog/repository/catalog_repository.dart';
import '../../catalog/repository/recently_viewed_repository.dart';
import '../../profile/repository/profile_repository.dart';
import '../../wishlist/repository/wishlist_repository.dart';

class ProductDetailScreen extends StatefulWidget {
  final int? id;
  final String slug;
  final String name;
  final int price;
  final String? imageUrl;
  final List<String> images;
  final int iconCodePoint;
  final List<Map<String, dynamic>> colors;
  final String? sellerSlug;
  final String? sellerName;
  final int? sellerId;
  final Product? product;

  const ProductDetailScreen({
    super.key,
    this.id,
    required this.slug,
    required this.name,
    required this.price,
    this.imageUrl,
    this.images = const [],
    required this.iconCodePoint,
    this.colors = const [],
    this.sellerSlug,
    this.sellerName,
    this.sellerId,
    this.product,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  bool _isWishlisted = false;
  bool _isTogglingWishlist = false;
  List<String> _allImages = [];
  String? _sellerSlug;
  String? _sellerName;
  int? _sellerId;
  Product? _currentProduct;
  ProductDetail? _detail;
  bool _detailLoading = true;
  bool _detailFailed = false;
  bool _isSubmittingReview = false;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    _isWishlisted = WishlistRepository.instance.isProductWishlisted(widget.slug);
    _allImages = [
      if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) widget.imageUrl!,
      ...widget.images,
    ];
    _sellerSlug = widget.sellerSlug ?? widget.product?.sellerSlug;
    _sellerName = widget.sellerName ?? widget.product?.sellerName;
    _sellerId = widget.sellerId ?? widget.product?.sellerId;
    _currentProduct = widget.product ??
        Product(
          id: widget.id ?? widget.slug.hashCode.abs(),
          name: widget.name,
          slug: widget.slug,
          imageUrl: widget.imageUrl,
          displayPrice: widget.price.toDouble(),
          seller: (_sellerName != null || _sellerSlug != null || _sellerId != null)
              ? SellerStub(
                  id: _sellerId,
                  name: _sellerName ?? _sellerSlug ?? '',
                  slug: _sellerSlug ??
                      _sellerName?.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-') ??
                      '',
                )
              : null,
        );
    _recordView();
    _fetchFullProductDetails();
  }

  void _recordView() {
    RecentlyViewedRepository.instance.recordProductView(
      _currentProduct ??
          Product(
            id: widget.id ?? 0,
            name: widget.name,
            slug: widget.slug,
            imageUrl: widget.imageUrl,
            displayPrice: widget.price.toDouble(),
            seller: (_sellerName != null || _sellerSlug != null || _sellerId != null)
                ? SellerStub(
                    id: _sellerId,
                    name: _sellerName ?? _sellerSlug ?? '',
                    slug: _sellerSlug ?? '',
                  )
                : null,
          ),
    );
  }

  Future<void> _fetchFullProductDetails() async {
    if (widget.slug.isEmpty) return;
    setState(() {
      _detailLoading = true;
      _detailFailed = false;
    });
    try {
      final detail = await CatalogRepository.instance.getProductDetail(widget.slug);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _detailLoading = false;
        if (detail.seller != null) {
          if (detail.seller!.slug.isNotEmpty) _sellerSlug = detail.seller!.slug;
          if (detail.seller!.name.isNotEmpty) _sellerName = detail.seller!.name;
          if (detail.seller!.id != null) _sellerId = detail.seller!.id;
        }
        _currentProduct = Product(
          id: detail.id != 0 ? detail.id : (widget.id ?? detail.slug.hashCode.abs()),
          name: detail.name.isNotEmpty ? detail.name : widget.name,
          slug: detail.slug.isNotEmpty ? detail.slug : widget.slug,
          imageUrl: detail.images.isNotEmpty ? detail.images.first : widget.imageUrl,
          displayPrice: detail.displayPrice > 0 ? detail.displayPrice : widget.price.toDouble(),
          listPrice: detail.listPrice,
          discountPercent: detail.discountPercent,
          seller: detail.seller ?? _currentProduct?.seller,
        );
        if (detail.images.isNotEmpty) {
          final set = <String>{};
          for (final img in detail.images) {
            if (img.isNotEmpty) set.add(img);
          }
          if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
            set.add(widget.imageUrl!);
          }
          _allImages = set.toList();
        }
        _quantity = 1;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _detailFailed = true);
    } finally {
      if (mounted && _detailLoading) {
        setState(() => _detailLoading = false);
      }
    }
  }

  // ─── Derived product values (real API data, widget args as fallback) ────────

  int get _effectivePrice {
    final p = _detail?.displayPrice ?? 0;
    if (p > 0) return p.round();
    return widget.price;
  }

  double? get _effectiveDiscountPercent {
    final d = _detail?.discountPercent;
    if (d != null && d > 0) return d;
    final list = _detail?.listPrice;
    final price = _detail?.displayPrice ?? 0;
    if (list != null && list > price && price > 0) {
      return ((1 - price / list) * 100).roundToDouble();
    }
    return null;
  }

  bool get _inStock => !(_detail?.hasKnownStock == true && (_detail?.stockQuantity ?? 0) <= 0);

  int get _maxQuantity {
    final stock = _detail?.stockQuantity;
    if (_detail?.hasKnownStock == true && stock != null && stock > 0) return stock;
    return 99;
  }

  int get _currentProductId =>
      (_currentProduct?.id != null && _currentProduct!.id != 0)
          ? _currentProduct!.id
          : (widget.id ?? widget.slug.hashCode.abs());

  String get _storeSlug {
    if (_sellerSlug?.isNotEmpty == true) return _sellerSlug!;
    if (_currentProduct?.sellerSlug?.isNotEmpty == true) {
      return _currentProduct!.sellerSlug!;
    }
    if (_sellerName?.isNotEmpty == true) {
      return _sellerName!.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    }
    if (_currentProduct?.sellerName?.isNotEmpty == true) {
      return _currentProduct!.sellerName!
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    }
    return 'softstore-official';
  }

  void _openStore(BuildContext context) {
    context.push(
      '/seller/$_storeSlug',
      extra: {
        'sellerName': _sellerName ?? _currentProduct?.sellerName,
        'product': _currentProduct,
        'sellerId': _sellerId ?? _currentProduct?.sellerId,
      },
    );
  }

  // ─── Quantity selector ─────────────────────────────────────────────────────

  void _incrementQuantity() {
    if (!_inStock) return;
    setState(() {
      if (_quantity < _maxQuantity) _quantity++;
    });
  }

  void _decrementQuantity() {
    setState(() {
      if (_quantity > AppConfig.minCartItemQty) _quantity--;
    });
  }

  // ─── Share ─────────────────────────────────────────────────────────────────

  Future<void> _shareProduct() async {
    final url = '${EnvConfig.baseUrl}/product/${widget.slug}';
    try {
      await Share.share(
        '${widget.name}\n$url',
        subject: widget.name,
      );
    } catch (_) {}
  }

  // ─── Reviews ───────────────────────────────────────────────────────────────

  bool get _hasUserReviewed {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return false;
    final fullName = authState.user.fullName.trim().toLowerCase();
    if (fullName.isEmpty) return false;
    final reviews = _detail?.reviews ?? const [];
    return reviews.any((r) => r.reviewer.trim().toLowerCase() == fullName);
  }

  Future<void> _openWriteReviewSheet() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      final loggedIn = await LoginScreen.showAsModal(context);
      if (loggedIn != true &&
          mounted &&
          context.read<AuthCubit>().state is! AuthAuthenticated) {
        return;
      }
    }
    if (!mounted) return;

    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _WriteReviewSheet(
        productName: _detail?.name.isNotEmpty == true ? _detail!.name : widget.name,
        isSubmitting: _isSubmittingReview,
      ),
    );
    if (result == null || !mounted) return;

    final rating = (result['rating'] as int?) ?? 5;
    final text = (result['text'] as String?)?.trim() ?? '';
    if (text.isEmpty) return;

    setState(() => _isSubmittingReview = true);
    final ok = await ProfileRepository.instance.submitReview(
      productId: _currentProductId,
      rating: rating,
      reviewText: text,
    );
    if (!mounted) return;
    setState(() => _isSubmittingReview = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Unable to submit your review right now. '
              'Reviews may require a verified purchase.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final reviewerName = authState is AuthAuthenticated
        ? authState.user.fullName
        : 'You';
    final newReview = ProductReview(
      reviewer: reviewerName.isNotEmpty ? reviewerName : 'You',
      rating: rating,
      text: text,
      date: _formatReviewDate(DateTime.now()),
    );
    setState(() {
      final old = _detail;
      if (old != null) {
        final reviews = [newReview, ...old.reviews];
        final count = old.ratingCount + 1;
        final avg =
            ((old.rating * old.ratingCount) + rating) / count.clamp(1, 1 << 31);
        _detail = ProductDetail(
          id: old.id,
          name: old.name,
          slug: old.slug,
          description: old.description,
          images: old.images,
          displayPrice: old.displayPrice,
          listPrice: old.listPrice,
          discountPercent: old.discountPercent,
          variants: old.variants,
          inStock: old.inStock,
          stockQuantity: old.stockQuantity,
          seller: old.seller,
          specifications: old.specifications,
          rating: avg.clamp(0, 5),
          ratingCount: count,
          reviews: reviews,
          relatedProducts: old.relatedProducts,
          category: old.category,
          categorySlug: old.categorySlug,
        );
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thanks! Your review has been submitted.'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatReviewDate(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  IconData get _icon =>
      // ignore: non_const_argument_for_const_parameter
      IconData(widget.iconCodePoint, fontFamily: 'MaterialIcons');
  Future<void> _handleWishlistToggle() async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      final loggedIn = await LoginScreen.showAsModal(context);
      if (loggedIn != true &&
          mounted &&
          context.read<AuthCubit>().state is! AuthAuthenticated) {
        return;
      }
    }
    if (!mounted) return;

    setState(() => _isTogglingWishlist = true);
    final targetState = !_isWishlisted;

    try {
      final added = await WishlistRepository.instance.toggleWishlist(
        productId: widget.id ?? widget.slug.hashCode.abs(),
        productSlug: widget.slug,
        product: Product(
          id: widget.id ?? widget.slug.hashCode.abs(),
          name: widget.name,
          slug: widget.slug,
          displayPrice: widget.price.toDouble(),
          imageUrl: widget.imageUrl,
        ),
      );
      if (!mounted) return;
      setState(() {
        _isWishlisted = added;
        _isTogglingWishlist = false;
      });
      _showWishlistSnackBar(isAdded: added);
    } catch (_) {
      if (!mounted) return;
      if (targetState) {
        WishlistRepository.instance.addLocalProduct(Product(
          id: widget.id ?? widget.slug.hashCode.abs(),
          name: widget.name,
          slug: widget.slug,
          displayPrice: widget.price.toDouble(),
          imageUrl: widget.imageUrl,
        ));
      } else {
        WishlistRepository.instance.removeLocalProduct(widget.slug);
      }
      setState(() {
        _isWishlisted = targetState;
        _isTogglingWishlist = false;
      });
      _showWishlistSnackBar(isAdded: targetState);
    }
  }

  void _showWishlistSnackBar({required bool isAdded}) {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 6,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        backgroundColor: const Color(0xFF1E2022),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isAdded ? const Color(0xFFFF6A00) : const Color(0xFF374151),
            width: 1.2,
          ),
        ),
        content: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: isAdded
                    ? const Color(0xFFFF6A00).withValues(alpha: 0.18)
                    : Colors.white.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                isAdded ? Icons.favorite : Icons.heart_broken_rounded,
                color: isAdded ? const Color(0xFFFF6A00) : const Color(0xFF9E9E9E),
                size: 18,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isAdded ? 'Added to Wishlist' : 'Removed from Wishlist',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isAdded
                        ? 'Saved in your SoftStore account'
                        : 'Item removed from saved list',
                    style: const TextStyle(
                      color: Color(0xFFB0B0B0),
                      fontSize: 11.5,
                    ),
                  ),
                ],
              ),
            ),
            if (isAdded) ...[
              const SizedBox(width: 8),
              InkWell(
                onTap: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  context.push(AppRoutes.wishlist);
                },
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFF6A00),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'View',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
        duration: const Duration(milliseconds: 2400),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          automaticallyImplyLeading: false,
          leading: Builder(
            builder: (ctx) => IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
              onPressed: () {
                if (ctx.canPop()) {
                  ctx.pop();
                } else {
                  ctx.go(AppRoutes.home);
                }
              },
            ),
          ),
          actions: [
            // Wishlist Toggle Button
            IconButton(
              icon: _isTogglingWishlist
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary,
                      ),
                    )
                  : Icon(
                      _isWishlisted ? Icons.favorite : Icons.favorite_border_rounded,
                      color: _isWishlisted ? Colors.red : AppColors.textSecondary,
                      size: 24,
                    ),
              tooltip: 'Wishlist',
              onPressed: _isTogglingWishlist ? null : _handleWishlistToggle,
            ),
            BlocBuilder<CartCubit, CartState>(
              builder: (blocContext, state) => Stack(
                alignment: Alignment.center,
                children: [
                  Builder(
                    builder: (ctx) => IconButton(
                      icon: const Icon(Icons.shopping_cart_outlined,
                          color: AppColors.textSecondary, size: 22),
                      onPressed: () => ctx.go(AppRoutes.cart),
                    ),
                  ),
                  if (state.itemCount > 0)
                    Positioned(
                      top: 8,
                      right: 6,
                      child: Container(
                        width: 16,
                        height: 16,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${state.itemCount}',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 9,
                                fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: Column(
          children: [
            // Tab bar
            Container(
              color: Colors.white,
              child: TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.textSecondary,
                labelStyle: AppTypography.labelMedium
                    .copyWith(fontWeight: FontWeight.bold),
                unselectedLabelStyle: AppTypography.labelMedium,
                indicatorColor: AppColors.primary,
                indicatorWeight: 2.5,
                tabs: const [
                  Tab(text: 'Overview'),
                  Tab(text: 'Ratings'),
                  Tab(text: 'Product Details'),
                  Tab(text: 'Recommended'),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _OverviewTab(
                    name: widget.name,
                    currentSlug: widget.slug,
                    price: _effectivePrice,
                    imageUrl: widget.imageUrl,
                    images: _allImages,
                    sellerSlug: _sellerSlug,
                    sellerName: _sellerName,
                    product: _currentProduct,
                    rating: _detail?.rating ?? 0.0,
                    ratingCount: _detail?.ratingCount ?? 0,
                    reviews: _detail?.reviews ?? const [],
                    description: _detail?.description,
                    category: _detail?.category,
                    categorySlug: _detail?.categorySlug,
                    discountPercent: _effectiveDiscountPercent,
                    inStock: _inStock,
                    stockQuantity:
                        _detail?.hasKnownStock == true ? _detail!.stockQuantity : null,
                    quantity: _quantity,
                    maxQuantity: _maxQuantity,
                    onQuantityIncrement: _incrementQuantity,
                    onQuantityDecrement: _decrementQuantity,
                    onShare: _shareProduct,
                    onOpenStore: _openStore,
                    onSeeAllReviews: () =>
                        DefaultTabController.maybeOf(context)?.animateTo(1),
                    onWriteReview: _openWriteReviewSheet,
                    icon: _icon,
                    isWishlisted: _isWishlisted,
                    onWishlistToggle: _handleWishlistToggle,
                  ),
                  _RatingsTab(
                    rating: _detail?.rating ?? 0.0,
                    ratingCount: _detail?.ratingCount ?? 0,
                    reviews: _detail?.reviews ?? const [],
                    sellerSlug: _sellerSlug,
                    sellerName: _sellerName,
                    product: _currentProduct,
                    isLoading: _detailLoading,
                    isFailed: _detailFailed,
                    hasReviewed: _hasUserReviewed,
                    onRetry: _fetchFullProductDetails,
                    onOpenStore: _openStore,
                    onWriteReview: _openWriteReviewSheet,
                  ),
                  _ProductDetailsTab(
                    name: widget.name,
                    specifications: _detail?.specifications ?? const [],
                    description: _detail?.description,
                  ),
                  _RecommendedTab(
                    currentSlug: widget.slug,
                    currentName: widget.name,
                    category: _detail?.category,
                    categorySlug: _detail?.categorySlug,
                    relatedProducts: _detail?.relatedProducts ?? const [],
                  ),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _BottomBar(
          id: widget.id,
          name: widget.name,
          price: _effectivePrice,
          imageUrl: widget.imageUrl,
          sellerSlug: _sellerSlug,
          sellerName: _sellerName,
          product: _currentProduct,
          iconCodePoint: widget.iconCodePoint,
          slug: widget.slug,
          colors: widget.colors,
          quantity: _quantity,
          maxQuantity: _maxQuantity,
          inStock: _inStock,
          storeSlug: _storeSlug,
        ),
      ),
    );
  }
}

// ── Overview tab ────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final String name;
  final String currentSlug;
  final int price;
  final String? imageUrl;
  final List<String> images;
  final String? sellerSlug;
  final String? sellerName;
  final Product? product;
  final double rating;
  final int ratingCount;
  final List<ProductReview> reviews;
  final String? description;
  final String? category;
  final String? categorySlug;
  final double? discountPercent;
  final bool inStock;
  final int? stockQuantity;
  final int quantity;
  final int maxQuantity;
  final VoidCallback onQuantityIncrement;
  final VoidCallback onQuantityDecrement;
  final Future<void> Function() onShare;
  final void Function(BuildContext) onOpenStore;
  final VoidCallback? onSeeAllReviews;
  final VoidCallback onWriteReview;
  final IconData icon;
  final bool isWishlisted;
  final VoidCallback onWishlistToggle;

  const _OverviewTab({
    required this.name,
    required this.currentSlug,
    required this.price,
    this.imageUrl,
    this.images = const [],
    this.sellerSlug,
    this.sellerName,
    this.product,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.reviews = const [],
    this.description,
    this.category,
    this.categorySlug,
    this.discountPercent,
    this.inStock = true,
    this.stockQuantity,
    this.quantity = 1,
    this.maxQuantity = 99,
    required this.onQuantityIncrement,
    required this.onQuantityDecrement,
    required this.onShare,
    required this.onOpenStore,
    this.onSeeAllReviews,
    required this.onWriteReview,
    required this.icon,
    required this.isWishlisted,
    required this.onWishlistToggle,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveImages = <String>[];
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      effectiveImages.add(imageUrl!);
    }
    for (final img in images) {
      if (img.isNotEmpty && !effectiveImages.contains(img)) {
        effectiveImages.add(img);
      }
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image — Full frame multi-image gallery swiper
          _ProductImageGallery(
            imageUrl: imageUrl,
            images: effectiveImages,
            icon: icon,
            isWishlisted: isWishlisted,
            onWishlistToggle: onWishlistToggle,
            onOpenStore: () => onOpenStore(context),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // Price & name
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      Formatters.pKRCurrency(price),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (discountPercent != null && discountPercent! > 0) ...[
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '-${discountPercent!.round()}%',
                          style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Share button
                    IconButton(
                      onPressed: () => onShare(),
                      icon: const Icon(Icons.share_outlined,
                          size: 20, color: AppColors.textSecondary),
                      tooltip: 'Share',
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(name, style: AppTypography.sectionHeading),
                const SizedBox(height: 10),
                // Stock status
                if (!inStock)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.remove_circle_outline,
                            size: 15, color: AppColors.error),
                        const SizedBox(width: 5),
                        Text('Out of stock',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.error)),
                      ],
                    ),
                  )
                else if (stockQuantity != null && stockQuantity! <= 10)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 15, color: Color(0xFF16A34A)),
                        const SizedBox(width: 5),
                        Text('Only $stockQuantity left in stock',
                            style: AppTypography.bodySmall
                                .copyWith(color: Color(0xFF16A34A))),
                      ],
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 15, color: Color(0xFF16A34A)),
                        const SizedBox(width: 5),
                        Text('In stock',
                            style: AppTypography.bodySmall
                                .copyWith(color: Color(0xFF16A34A))),
                      ],
                    ),
                  ),
                // Rating row
                GestureDetector(
                  onTap: onSeeAllReviews,
                  behavior: HitTestBehavior.opaque,
                  child: Row(
                    children: [
                      if (rating > 0) ...[
                        ...List.generate(
                          rating.floor().clamp(0, 5),
                          (_) => const Icon(Icons.star,
                              color: Colors.amber, size: 16),
                        ),
                        if (rating - rating.floor() >= 0.3)
                          const Icon(Icons.star_half,
                              color: Colors.amber, size: 16),
                        const SizedBox(width: 6),
                        Text(rating.toStringAsFixed(1),
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textSecondary)),
                        if (ratingCount > 0) ...[
                          const SizedBox(width: 4),
                          Text('($ratingCount reviews)',
                              style: AppTypography.bodySmall
                                  .copyWith(color: AppColors.textDisabled)),
                        ],
                      ] else
                        Row(
                          children: [
                            ...List.generate(
                              5,
                              (_) => const Icon(Icons.star_border,
                                  color: Color(0xFFD1D5DB), size: 16),
                            ),
                            const SizedBox(width: 6),
                            Text('No ratings yet',
                                style: AppTypography.bodySmall
                                    .copyWith(color: AppColors.textDisabled)),
                          ],
                        ),
                      if (onSeeAllReviews != null && ratingCount > 0) ...[
                        const Spacer(),
                        const Icon(Icons.chevron_right_rounded,
                            size: 18, color: AppColors.textDisabled),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                // Quantity selector
                _QuantitySelector(
                  quantity: quantity,
                  maxQuantity: maxQuantity,
                  inStock: inStock,
                  onIncrement: onQuantityIncrement,
                  onDecrement: onQuantityDecrement,
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Delivery / COD / Returns information card
          const _DeliveryInfoCard(),

          const SizedBox(height: 8),

          // Store section
          _StoreSectionCard(
            storeName: sellerName?.isNotEmpty == true
                ? sellerName!
                : (sellerSlug?.isNotEmpty == true
                    ? sellerSlug!
                        .split('-')
                        .map((w) =>
                            w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
                        .join(' ')
                    : 'SoftStore Official'),
            onOpenStore: () => onOpenStore(context),
          ),

          const SizedBox(height: 8),

          // Description section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(AppSpacing.lg),
            width: double.infinity,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description', style: AppTypography.sectionHeading),
                const SizedBox(height: 8),
                Text(
                  description != null && description!.trim().isNotEmpty
                      ? description!.replaceAll(RegExp(r'<[^>]*>'), '').trim()
                      : 'No description available for this product.',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary, height: 1.6),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Reviews preview
          _ReviewsPreviewSection(
            rating: rating,
            ratingCount: ratingCount,
            reviews: reviews,
            isLoading: false,
            onSeeAll: onSeeAllReviews,
            onWriteReview: onWriteReview,
          ),

          const SizedBox(height: 8),

          // You may also like
          _YouMayAlsoLikeSection(
            currentSlug: currentSlug,
            currentName: name,
            category: category,
            categorySlug: categorySlug,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Shared: related products loader ──────────────────────────────────────────

/// Loads related/matching products for the CURRENT product, excluding it.
Future<List<Product>> loadRelatedProducts({
  required String currentSlug,
  String? currentName,
  String? category,
  String? categorySlug,
}) async {
  final targetCat = categorySlug?.isNotEmpty == true
      ? categorySlug!
      : (category?.isNotEmpty == true
          ? category!.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')
          : null);

  // 1. Products belonging strictly to the same category
  if (targetCat != null && targetCat.isNotEmpty) {
    try {
      final catResult = await CatalogRepository.instance.searchProducts(
        query: '',
        category: targetCat,
      );
      final list =
          catResult.products.where((p) => p.slug != currentSlug).toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}
  }

  // 2. Marketplace search for matching product category/type keywords
  final searchTarget = category?.isNotEmpty == true
      ? category!
      : (currentName ?? '')
          .split(' ')
          .where((w) =>
              w.length > 2 &&
              !['and', 'for', 'with', 'the'].contains(w.toLowerCase()))
          .take(2)
          .join(' ');

  if (searchTarget.isNotEmpty) {
    try {
      final result = await CatalogRepository.instance.searchProducts(
        query: searchTarget,
        category: targetCat,
      );
      final list =
          result.products.where((p) => p.slug != currentSlug).toList();
      if (list.isNotEmpty) return list;
    } catch (_) {}
  }

  // 3. Fallback to marketplace featured products
  try {
    final homeData = await CatalogRepository.instance.getHomepage();
    final fallback = homeData.featuredProducts.isNotEmpty
        ? homeData.featuredProducts
        : homeData.topDeals;
    return fallback.where((p) => p.slug != currentSlug).toList();
  } catch (_) {}

  return const [];
}

void openProductDetail(BuildContext context, Product p) {
  context.push(
    '/product/${p.slug}',
    extra: {
      'id': p.id,
      'name': p.name,
      'price': p.displayPrice.toInt(),
      'imageUrl': p.imageUrl,
      'sellerSlug': p.sellerSlug,
      'sellerName': p.sellerName,
      'sellerId': p.sellerId,
      'product': p,
    },
  );
}

// ── Quantity selector ────────────────────────────────────────────────────────

class _QuantitySelector extends StatelessWidget {
  final int quantity;
  final int maxQuantity;
  final bool inStock;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;

  const _QuantitySelector({
    required this.quantity,
    required this.maxQuantity,
    required this.inStock,
    required this.onIncrement,
    required this.onDecrement,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('Quantity',
            style: AppTypography.bodyMedium
                .copyWith(fontWeight: FontWeight.w600)),
        const Spacer(),
        _QtyBtn(
          icon: Icons.remove_rounded,
          onTap:
              quantity > AppConfig.minCartItemQty ? onDecrement : null,
        ),
        Container(
          constraints: const BoxConstraints(minWidth: 56),
          alignment: Alignment.center,
          child: Text(
            '$quantity',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
        _QtyBtn(
          icon: Icons.add_rounded,
          onTap:
              inStock && quantity < maxQuantity ? onIncrement : null,
        ),
      ],
    );
  }
}

// ── Delivery / COD / Returns information card ────────────────────────────────

class _DeliveryInfoCard extends StatelessWidget {
  const _DeliveryInfoCard();

  @override
  Widget build(BuildContext context) {
    final threshold = NumberFormat.decimalPattern()
        .format(AppConfig.freeDeliveryThreshold.toInt());

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _infoTile(
            icon: Icons.local_shipping_outlined,
            title: 'Delivery',
            subtitle:
                'Free delivery on orders over Rs $threshold. Nationwide shipping available.',
          ),
          const SizedBox(height: 14),
          _infoTile(
            icon: Icons.payments_outlined,
            title: 'Cash on Delivery',
            subtitle:
                'Pay the rider when your order arrives. No advance payment required.',
          ),
          const SizedBox(height: 14),
          _infoTile(
            icon: Icons.assignment_return_outlined,
            title: 'Returns',
            subtitle:
                'Request a return within ${AppConfig.returnEligibilityWindow.inDays} days of delivery for eligible items.',
          ),
        ],
      ),
    );
  }

  Widget _infoTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: AppTypography.bodyMedium
                      .copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 2),
              Text(subtitle,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary, height: 1.4)),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Store section card ───────────────────────────────────────────────────────

class _StoreSectionCard extends StatelessWidget {
  final String storeName;
  final VoidCallback onOpenStore;

  const _StoreSectionCard({
    required this.storeName,
    required this.onOpenStore,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(Icons.storefront_outlined,
                color: AppColors.primary, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(storeName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 15)),
                const SizedBox(height: 2),
                Text('View all products from this store',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
            onPressed: onOpenStore,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              foregroundColor: AppColors.primary,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            child: const Text('Visit Store',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ── Reviews preview section ──────────────────────────────────────────────────

class _ReviewsPreviewSection extends StatelessWidget {
  final double rating;
  final int ratingCount;
  final List<ProductReview> reviews;
  final bool isLoading;
  final VoidCallback? onSeeAll;
  final VoidCallback onWriteReview;

  const _ReviewsPreviewSection({
    required this.rating,
    required this.ratingCount,
    required this.reviews,
    this.isLoading = false,
    this.onSeeAll,
    required this.onWriteReview,
  });

  @override
  Widget build(BuildContext context) {
    final totalCount = ratingCount > 0 ? ratingCount : reviews.length;
    final previews = reviews.take(2).toList();

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Reviews ($totalCount)', style: AppTypography.sectionHeading),
              const Spacer(),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text('See All',
                      style: TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13)),
                ),
            ],
          ),
          const SizedBox(height: 4),
          if (rating > 0)
            Row(
              children: [
                Text(rating.toStringAsFixed(1),
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(width: 6),
                ...List.generate(
                  rating.floor().clamp(0, 5),
                  (_) => const Icon(Icons.star, color: Colors.amber, size: 15),
                ),
                if (rating - rating.floor() >= 0.3)
                  const Icon(Icons.star_half, color: Colors.amber, size: 15),
              ],
            )
          else
            Text('No ratings yet',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textDisabled)),
          const SizedBox(height: 12),
          if (isLoading)
            ...List.generate(
              2,
              (_) => Container(
                margin: const EdgeInsets.only(bottom: 10),
                height: 64,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            )
          else if (previews.isNotEmpty)
            ...previews.map((r) => _ReviewCard(
                  text: r.text,
                  reviewer: r.reviewer,
                  stars: r.rating,
                  date: r.date,
                ))
          else
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No reviews yet',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: onWriteReview,
                      icon: const Icon(Icons.rate_review_outlined, size: 17),
                      label: const Text('Write a Review'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

// ── You may also like section ────────────────────────────────────────────────

class _YouMayAlsoLikeSection extends StatefulWidget {
  final String currentSlug;
  final String currentName;
  final String? category;
  final String? categorySlug;

  const _YouMayAlsoLikeSection({
    required this.currentSlug,
    required this.currentName,
    this.category,
    this.categorySlug,
  });

  @override
  State<_YouMayAlsoLikeSection> createState() =>
      _YouMayAlsoLikeSectionState();
}

class _YouMayAlsoLikeSectionState extends State<_YouMayAlsoLikeSection> {
  List<Product>? _products;
  String? _loadedForKey;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void didUpdateWidget(covariant _YouMayAlsoLikeSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentSlug != widget.currentSlug ||
        oldWidget.categorySlug != widget.categorySlug ||
        oldWidget.category != widget.category) {
      setState(() => _products = null);
      _fetch();
    }
  }

  Future<void> _fetch() async {
    final key =
        '${widget.currentSlug}|${widget.category ?? ''}|${widget.categorySlug ?? ''}';
    if (_loadedForKey == key || widget.currentSlug.isEmpty) return;
    _loadedForKey = key;
    final products = await loadRelatedProducts(
      currentSlug: widget.currentSlug,
      currentName: widget.currentName,
      category: widget.category,
      categorySlug: widget.categorySlug,
    );
    if (!mounted) return;
    setState(() => _products = products);
  }

  @override
  Widget build(BuildContext context) {
    final products = _products;
    final loading = products == null;

    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('You may also like', style: AppTypography.sectionHeading),
          const SizedBox(height: 12),
          if (loading)
            SizedBox(
              height: 170,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: 3,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (_, __) => Container(
                  width: 130,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            )
          else if (products.isEmpty)
            Text('No recommendations found',
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textDisabled))
          else
            SizedBox(
              height: 190,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.length.clamp(0, 10),
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final p = products[index];
                  return GestureDetector(
                    onTap: () => openProductDetail(context, p),
                    child: Container(
                      width: 140,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(11)),
                              child: Container(
                                width: double.infinity,
                                color: AppColors.background,
                                child: p.imageUrl != null &&
                                        p.imageUrl!.isNotEmpty
                                    ? Image.network(
                                        p.imageUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) =>
                                            const Center(
                                          child: Icon(
                                              Icons.shopping_bag_outlined,
                                              color: AppColors.primary,
                                              size: 30),
                                        ),
                                      )
                                    : const Center(
                                        child: Icon(Icons.shopping_bag_outlined,
                                            color: AppColors.primary,
                                            size: 30),
                                      ),
                              ),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: AppTypography.bodySmall.copyWith(
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  Formatters.pKRCurrency(p.displayPrice),
                                  style: const TextStyle(
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

// ── Write review bottom sheet ────────────────────────────────────────────────

class _WriteReviewSheet extends StatefulWidget {
  final String productName;
  final bool isSubmitting;

  const _WriteReviewSheet({
    required this.productName,
    this.isSubmitting = false,
  });

  @override
  State<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends State<_WriteReviewSheet> {
  int _rating = 5;
  final TextEditingController _textCtrl = TextEditingController();

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final enabled = !widget.isSubmitting && _textCtrl.text.trim().isNotEmpty;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Spacer(),
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFDDDDDD),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close,
                      color: Color(0xFF888888), size: 20),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text('Write a Review', style: AppTypography.sectionHeading),
            const SizedBox(height: 2),
            Text(widget.productName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTypography.bodySmall
                    .copyWith(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                final selected = i < _rating;
                return IconButton(
                  onPressed: () => setState(() => _rating = i + 1),
                  icon: Icon(
                    selected ? Icons.star_rounded : Icons.star_border_rounded,
                    color: selected ? Colors.amber : const Color(0xFFD1D5DB),
                    size: 34,
                  ),
                );
              }),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _textCtrl,
              maxLines: 4,
              maxLength: 500,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Share your experience with this product...',
                hintStyle:
                    AppTypography.bodyMedium.copyWith(color: Colors.grey),
                filled: true,
                fillColor: AppColors.background,
                contentPadding: const EdgeInsets.all(12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: enabled
                    ? () => Navigator.of(context)
                        .pop({'rating': _rating, 'text': _textCtrl.text})
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.4),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
                child: widget.isSubmitting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Submit Review',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Product Image Gallery (Multi-Image Swiper + Wide-Image Dual View) ─────────

class _ProductImageGallery extends StatefulWidget {
  final String? imageUrl;
  final List<String> images;
  final IconData icon;
  final bool isWishlisted;
  final VoidCallback onWishlistToggle;
  final VoidCallback onOpenStore;

  const _ProductImageGallery({
    required this.imageUrl,
    this.images = const [],
    required this.icon,
    required this.isWishlisted,
    required this.onWishlistToggle,
    required this.onOpenStore,
  });

  @override
  State<_ProductImageGallery> createState() => _ProductImageGalleryState();
}

class _ProductImageGalleryState extends State<_ProductImageGallery> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isWide = false;
  ImageStream? _imageStream;
  ImageStreamListener? _imageListener;

  List<String> get _galleryImages {
    final list = <String>[];
    for (final img in widget.images) {
      if (img.isNotEmpty && !list.contains(img)) list.add(img);
    }
    if (list.isEmpty && widget.imageUrl != null && widget.imageUrl!.isNotEmpty) {
      list.add(widget.imageUrl!);
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _checkImageDimensions();
  }

  @override
  void didUpdateWidget(covariant _ProductImageGallery oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageUrl != widget.imageUrl || oldWidget.images != widget.images) {
      _checkImageDimensions();
    }
  }

  void _checkImageDimensions() {
    final list = _galleryImages;
    if (list.isEmpty) return;

    final imageProvider = NetworkImage(list.first);
    _imageStream = imageProvider.resolve(const ImageConfiguration());
    _imageListener = ImageStreamListener((ImageInfo info, bool _) {
      final width = info.image.width;
      final height = info.image.height;
      if (mounted) {
        setState(() {
          // Only auto-split single wide images when there are no multiple separate images
          _isWide = list.length == 1 && (width / height) >= 1.25;
        });
      }
    }, onError: (_, __) {});
    _imageStream?.addListener(_imageListener!);
  }

  @override
  void dispose() {
    if (_imageStream != null && _imageListener != null) {
      _imageStream!.removeListener(_imageListener!);
    }
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final list = _galleryImages;
    final bool hasMultiple = list.length > 1;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          height: 340,
          color: const Color(0xFFF9FAFB),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (list.isEmpty)
                Center(
                  child: Icon(widget.icon, size: 100, color: AppColors.primary),
                )
              else if (hasMultiple)
                // Multi-Image Gallery: Full Swiper for all uploaded product photos
                PageView.builder(
                  controller: _pageController,
                  itemCount: list.length,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  itemBuilder: (context, index) {
                    final imgUrl = list[index];
                    return Image.network(
                      imgUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: double.infinity,
                      errorBuilder: (_, __, ___) => Center(
                        child: Icon(widget.icon, size: 100, color: AppColors.primary),
                      ),
                    );
                  },
                )
              else if (_isWide)
                // Single Wide Image: Dual View Split
                PageView(
                  controller: _pageController,
                  onPageChanged: (page) => setState(() => _currentPage = page),
                  children: [
                    GestureDetector(
                      onTap: () => _pageController.animateToPage(
                        1,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.centerLeft,
                          maxWidth: double.infinity,
                          child: Image.network(
                            list.first,
                            fit: BoxFit.cover,
                            height: 340,
                            alignment: Alignment.centerLeft,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(widget.icon, size: 100, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _pageController.animateToPage(
                        0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      ),
                      child: ClipRect(
                        child: OverflowBox(
                          alignment: Alignment.centerRight,
                          maxWidth: double.infinity,
                          child: Image.network(
                            list.first,
                            fit: BoxFit.cover,
                            height: 340,
                            alignment: Alignment.centerRight,
                            errorBuilder: (_, __, ___) => Center(
                              child: Icon(widget.icon, size: 100, color: AppColors.primary),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              else
                // Single Regular Image: Full Frame Cover
                Image.network(
                  list.first,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  errorBuilder: (_, __, ___) => Center(
                    child: Icon(widget.icon, size: 100, color: AppColors.primary),
                  ),
                ),

              // Multi-Image / Wide Image Page Indicator Badge
              if (hasMultiple || _isWide)
                Positioned(
                  bottom: 12,
                  left: 0,
                  right: 0,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '${_currentPage + 1}/${hasMultiple ? list.length : 2}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Floating Store & Message Icons on Top-Left corner of Product Image
              Positioned(
                top: 14,
                left: 14,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Material(
                      color: Colors.white.withValues(alpha: 0.95),
                      shape: const CircleBorder(),
                      elevation: 3,
                      shadowColor: Colors.black26,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: widget.onOpenStore,
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.storefront_outlined,
                            color: Color(0xFF1F2937),
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Material(
                      color: Colors.white.withValues(alpha: 0.95),
                      shape: const CircleBorder(),
                      elevation: 3,
                      shadowColor: Colors.black26,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () => context.push(AppRoutes.messages),
                        child: const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Icon(
                            Icons.chat_bubble_outline_rounded,
                            color: Color(0xFF1F2937),
                            size: 19,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Floating Wishlist Heart on the top-right corner of image
              Positioned(
                top: 14,
                right: 14,
                child: Material(
                  color: Colors.white.withValues(alpha: 0.95),
                  shape: const CircleBorder(),
                  elevation: 3,
                  shadowColor: Colors.black26,
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: widget.onWishlistToggle,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Icon(
                        widget.isWishlisted
                            ? Icons.favorite
                            : Icons.favorite_border_rounded,
                        color: widget.isWishlisted
                            ? Colors.red
                            : AppColors.textSecondary,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        // Thumbnail strip for multiple images
        if (hasMultiple)
          Container(
            height: 64,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final isSelected = _currentPage == index;
                return GestureDetector(
                  onTap: () {
                    _pageController.animateToPage(
                      index,
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? const Color(0xFFFF6A00) : const Color(0xFFE5E7EB),
                        width: isSelected ? 2.5 : 1,
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: Image.network(
                        list[index],
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 20),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ── Ratings tab ─────────────────────────────────────────────────────────────

class _RatingsTab extends StatelessWidget {
  final double rating;
  final int ratingCount;
  final List<ProductReview> reviews;
  final String? sellerSlug;
  final String? sellerName;
  final Product? product;
  final bool isLoading;
  final bool isFailed;
  final bool hasReviewed;
  final Future<void> Function()? onRetry;
  final void Function(BuildContext)? onOpenStore;
  final VoidCallback? onWriteReview;

  const _RatingsTab({
    this.rating = 0.0,
    this.ratingCount = 0,
    this.reviews = const [],
    this.sellerSlug,
    this.sellerName,
    this.product,
    this.isLoading = false,
    this.isFailed = false,
    this.hasReviewed = false,
    this.onRetry,
    this.onOpenStore,
    this.onWriteReview,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveReviews = reviews;
    final totalCount = ratingCount > 0 ? ratingCount : effectiveReviews.length;
    final storeTitle = sellerName?.isNotEmpty == true
        ? sellerName!
        : (sellerSlug?.isNotEmpty == true
            ? sellerSlug!.split('-').map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '').join(' ')
            : 'SoftStore Official');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rating summary header
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Reviews ($totalCount)',
                    style: AppTypography.sectionHeading),
                if (rating > 0)
                  Row(
                    children: [
                      Text(rating.toStringAsFixed(1),
                          style: AppTypography.sectionHeading
                              .copyWith(color: AppColors.textPrimary)),
                      const SizedBox(width: 4),
                      ...List.generate(
                        rating.floor().clamp(0, 5),
                        (_) => const Icon(Icons.star,
                            color: Colors.amber, size: 16),
                      ),
                      if (rating - rating.floor() >= 0.3)
                        const Icon(Icons.star_half,
                            color: Colors.amber, size: 16),
                    ],
                  )
                else
                  Text('No ratings yet',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textDisabled)),
              ],
            ),
          ),

          // Write a Review / You reviewed this
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: hasReviewed
                ? Row(
                    children: [
                      const Icon(Icons.check_circle_outline,
                          size: 16, color: Color(0xFF16A34A)),
                      const SizedBox(width: 6),
                      Text('You reviewed this',
                          style: AppTypography.bodySmall.copyWith(
                              color: Color(0xFF16A34A),
                              fontWeight: FontWeight.w600)),
                    ],
                  )
                : SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onWriteReview,
                      icon: const Icon(Icons.rate_review_outlined, size: 17),
                      label: const Text('Write a Review'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
          ),

          // Loading state
          if (isLoading)
            ...List.generate(
              3,
              (_) => Container(
                margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                height: 80,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: AppColors.primary),
                ),
              ),
            )
          else if (isFailed)
            // Error state with retry
            Container(
              color: Colors.white,
              margin: const EdgeInsets.symmetric(vertical: 4),
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              child: Column(
                children: [
                  const Icon(Icons.cloud_off_outlined,
                      size: 40, color: AppColors.textDisabled),
                  const SizedBox(height: 8),
                  Text('Unable to load reviews.',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),
                  if (onRetry != null) ...[
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => onRetry!(),
                      icon: const Icon(Icons.refresh_rounded, size: 17),
                      label: const Text('Retry'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: const BorderSide(color: AppColors.primary),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ],
              ),
            )
          else ...[
            // Real review cards
            if (effectiveReviews.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                child: Column(
                  children: effectiveReviews
                      .map((r) => _ReviewCard(
                            text: r.text,
                            reviewer: r.reviewer,
                            stars: r.rating,
                            date: r.date,
                          ))
                      .toList(),
                ),
              )
            else if (totalCount == 0)
              Container(
                color: Colors.white,
                padding: const EdgeInsets.all(24),
                margin: const EdgeInsets.symmetric(vertical: 4),
                width: double.infinity,
                child: Column(
                  children: [
                    const Icon(Icons.rate_review_outlined,
                        size: 40, color: AppColors.textDisabled),
                    const SizedBox(height: 8),
                    Text(
                      'No reviews yet for this product',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // Store info
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.divider),
                    ),
                    child: const Icon(Icons.store,
                        color: AppColors.primary, size: 28),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(storeTitle,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                  ElevatedButton(
                    onPressed: onOpenStore != null
                        ? () => onOpenStore!(context)
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Visit Store',
                        style: TextStyle(fontSize: 13)),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  final String text;
  final String reviewer;
  final int stars;
  final String? date;

  const _ReviewCard({
    required this.text,
    required this.reviewer,
    required this.stars,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 10),
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ...List.generate(
                stars.clamp(1, 5),
                (_) =>
                    const Icon(Icons.star, color: Colors.amber, size: 14),
              ),
              if (date != null && date!.isNotEmpty) ...[
                const Spacer(),
                Text(date!,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textDisabled)),
              ],
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: AppTypography.bodyMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.account_circle,
                  size: 16, color: AppColors.textDisabled),
              const SizedBox(width: 6),
              Expanded(
                child: Text(reviewer,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.textSecondary)),
              ),
              const Icon(Icons.verified_outlined,
                  size: 13, color: Colors.green),
              const SizedBox(width: 4),
              Text('Verified Purchase',
                  style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Product Details tab ─────────────────────────────────────────────────────

class _ProductDetailsTab extends StatelessWidget {
  final String name;
  final List<Specification> specifications;
  final String? description;

  const _ProductDetailsTab({
    required this.name,
    this.specifications = const [],
    this.description,
  });

  @override
  Widget build(BuildContext context) {
    final specsList = specifications.isNotEmpty
        ? specifications.map((s) => {'label': s.label, 'value': s.value}).toList()
        : [
            {'label': 'Brand', 'value': 'SoftStore'},
            {'label': 'Model', 'value': name},
            {'label': 'Condition', 'value': '100% Brand New & Original'},
            {'label': 'Warranty', 'value': '1 Year Official Warranty'},
            {'label': 'Return Policy', 'value': '7 Days Free Easy Returns'},
            {'label': 'Authenticity', 'value': '100% Verified Quality'},
          ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        color: Colors.white,
        child: Column(
          children: specsList
              .map(
                (s) => Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: Text(s['label']!,
                                style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textSecondary, fontWeight: FontWeight.w600)),
                          ),
                          Expanded(
                            flex: 3,
                            child: Text(s['value']!,
                                style: AppTypography.bodySmall),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, color: AppColors.divider),
                  ],
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

// ── Recommended tab (Loads related and matching type products in the same category) ──

class _RecommendedTab extends StatefulWidget {
  final String currentSlug;
  final String currentName;
  final String? category;
  final String? categorySlug;
  final List<Product> relatedProducts;

  const _RecommendedTab({
    required this.currentSlug,
    required this.currentName,
    this.category,
    this.categorySlug,
    this.relatedProducts = const [],
  });

  @override
  State<_RecommendedTab> createState() => _RecommendedTabState();
}

class _RecommendedTabState extends State<_RecommendedTab> {
  List<Product> _products = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _products = widget.relatedProducts;
    _fetchRelatedProducts();
  }

  @override
  void didUpdateWidget(covariant _RecommendedTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.relatedProducts != oldWidget.relatedProducts && widget.relatedProducts.isNotEmpty) ||
        widget.categorySlug != oldWidget.categorySlug ||
        widget.category != oldWidget.category) {
      if (widget.relatedProducts.isNotEmpty) {
        setState(() => _products = widget.relatedProducts);
      } else {
        _fetchRelatedProducts();
      }
    }
  }

  Future<void> _fetchRelatedProducts() async {
    if (_products.isNotEmpty) return;
    setState(() => _loading = true);

    try {
      final list = await loadRelatedProducts(
        currentSlug: widget.currentSlug,
        currentName: widget.currentName,
        category: widget.category,
        categorySlug: widget.categorySlug,
      );
      if (!mounted) return;
      setState(() {
        _products = list;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading && _products.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF6A00)),
      );
    }

    if (_products.isEmpty) {
      return const Center(
        child: Text(
          'No related recommendations found',
          style: TextStyle(color: AppColors.textSecondary),
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _products.length,
      itemBuilder: (context, index) {
        final p = _products[index];
        return GestureDetector(
          onTap: () => openProductDetail(context, p),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(14)),
                    child: Container(
                      width: double.infinity,
                      color: const Color(0xFFF9FAFB),
                      child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                          ? Image.network(
                              p.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 36),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.shopping_bag_outlined, color: AppColors.primary, size: 36),
                            ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.name,
                        style: AppTypography.productName.copyWith(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.pKRCurrency(p.displayPrice),
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Bottom bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final int? id;
  final String name;
  final int price;
  final String? imageUrl;
  final String? sellerSlug;
  final String? sellerName;
  final Product? product;
  final int iconCodePoint;
  final String slug;
  final List<Map<String, dynamic>> colors;
  final int quantity;
  final int maxQuantity;
  final bool inStock;
  final String storeSlug;

  const _BottomBar({
    this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.sellerSlug,
    this.sellerName,
    this.product,
    required this.iconCodePoint,
    required this.slug,
    required this.colors,
    this.quantity = 1,
    this.maxQuantity = 99,
    this.inStock = true,
    required this.storeSlug,
  });

  void _showCheckout(BuildContext context) {
    context.push(AppRoutes.checkout);
  }

  Future<void> _handleBuyNow(BuildContext context) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      final loggedIn = await LoginScreen.showAsModal(context);
      if (loggedIn != true &&
          context.mounted &&
          context.read<AuthCubit>().state is! AuthAuthenticated) {
        return;
      }
    }
    if (!context.mounted) return;

    if (colors.isEmpty) {
      // Buy Now must check out ONLY this product + selected quantity:
      // drop any previously selected cart items, then add/select this one.
      context.read<CartCubit>().clearSelection();
      final item = CartItem(
        uuid: slug,
        productId: id ?? slug.hashCode.abs(),
        productName: name,
        productSlug: slug,
        quantity: quantity.clamp(1, maxQuantity),
        unitPriceSnapshot: price.toDouble(),
        imageUrl: imageUrl,
      );
      await context.read<CartCubit>().addItem(item);
      if (context.mounted) {
        _showCheckout(context);
      }
      return;
    }

    final selectedVariant = await showModalBottomSheet<dynamic>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<CartCubit>(),
        child: _ColorSheet(
          name: name,
          price: price,
          iconCodePoint: iconCodePoint,
          slug: slug,
          colors: colors,
          initialQuantity: quantity,
          maxQuantity: maxQuantity,
        ),
      ),
    );

    if (selectedVariant != null && context.mounted) {
      String? colorName;
      int qty = 1;
      if (selectedVariant is Map) {
        colorName = selectedVariant['color']?.toString();
        qty = (selectedVariant['quantity'] as int?) ?? 1;
      } else if (selectedVariant is String) {
        colorName = selectedVariant;
      }

      context.read<CartCubit>().clearSelection();
      final item = CartItem(
        uuid: (colorName != null && colorName.isNotEmpty)
            ? '${slug}_$colorName'
            : slug,
        productId: id ?? slug.hashCode.abs(),
        productName: (colorName != null && colorName.isNotEmpty)
            ? '$name ($colorName)'
            : name,
        productSlug: slug,
        variantLabel: colorName,
        quantity: qty,
        unitPriceSnapshot: price.toDouble(),
        imageUrl: imageUrl,
      );
      await context.read<CartCubit>().addItem(item);
      if (context.mounted) {
        _showCheckout(context);
      }
    }
  }

  Future<void> _handleChat(BuildContext context) async {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) {
      final loggedIn = await LoginScreen.showAsModal(context);
      if (loggedIn != true &&
          context.mounted &&
          context.read<AuthCubit>().state is! AuthAuthenticated) {
        return;
      }
    }
    if (!context.mounted) return;

    context.push(
      AppRoutes.sellerChat,
      extra: {
        'productId': id ?? slug.hashCode.abs(),
        'productName': name,
        'productImage': imageUrl,
        'productPrice': price.toDouble(),
        'sellerName': sellerName ?? 'Store Seller',
      },
    );
  }

  void _handleStoreTap(BuildContext context) {
    // Navigate to the store page for the CURRENT product
    final String? displayName = sellerName?.isNotEmpty == true
        ? sellerName
        : (product?.sellerName?.isNotEmpty == true ? product!.sellerName : null);

    context.push(
      '/seller/$storeSlug',
      extra: {
        'sellerName': displayName,
        'product': product,
        'sellerId': product?.sellerId,
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: AppColors.divider, width: 1),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Row(
        children: [
          // Store
          _IconAction(
            icon: Icons.store_outlined,
            label: 'Store',
            onTap: () => _handleStoreTap(context),
          ),
          const SizedBox(width: 8),
          // Chat
          _IconAction(
            icon: Icons.chat_bubble_outline,
            label: 'Chat',
            onTap: () => _handleChat(context),
          ),
          const SizedBox(width: 8),
          // Buy Now
          Expanded(
            child: SizedBox(
              height: 46,
              child: OutlinedButton(
                onPressed: inStock ? () => _handleBuyNow(context) : null,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  foregroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Buy Now',
                    style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Add to Cart
          Expanded(
            child: SizedBox(
              height: 46,
              child: ElevatedButton(
                onPressed: inStock
                    ? () {
                        context.read<CartCubit>().addItem(
                              CartItem(
                                uuid: slug,
                                productId: id ?? slug.hashCode.abs(),
                                productName: name,
                                productSlug: slug,
                                quantity: quantity.clamp(1, maxQuantity),
                                unitPriceSnapshot: price.toDouble(),
                                imageUrl: imageUrl,
                              ),
                            );
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Added $quantity to cart'),
                            backgroundColor: AppColors.primary,
                            duration: const Duration(seconds: 1),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor:
                      AppColors.primary.withValues(alpha: 0.4),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Text(inStock ? 'Add to Cart' : 'Out of Stock',
                    style: const TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Color selection sheet ─────────────────────────────────────────────────

class _ColorSheet extends StatefulWidget {
  final String name;
  final int price;
  final int iconCodePoint;
  final String slug;
  final List<Map<String, dynamic>> colors;
  final int initialQuantity;
  final int maxQuantity;

  const _ColorSheet({
    required this.name,
    required this.price,
    required this.iconCodePoint,
    required this.slug,
    required this.colors,
    this.initialQuantity = 1,
    this.maxQuantity = 99,
  });

  @override
  State<_ColorSheet> createState() => _ColorSheetState();
}

class _ColorSheetState extends State<_ColorSheet> {
  late int _selectedIndex = 0;
  late int _quantity =
      widget.initialQuantity.clamp(1, widget.maxQuantity);

  // ignore: non_const_argument_for_const_parameter
  IconData get _icon => IconData(widget.iconCodePoint,
      fontFamily: 'MaterialIcons');

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final selected = widget.colors[_selectedIndex];
    final selectedName = selected['name'] as String;
    final originalPrice = (widget.price * 1.25).round();

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      padding:
          EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle + close
          Row(
            children: [
              const Spacer(),
              Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFDDDDDD),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => Navigator.of(context).pop(),
                child: const Icon(Icons.close,
                    color: Color(0xFF888888), size: 20),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Product info row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(_icon,
                      size: 38, color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PKR ${widget.price}',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'PKR $originalPrice',
                    style: const TextStyle(
                      color: Color(0xFFAAAAAA),
                      fontSize: 13,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    selectedName,
                    style: const TextStyle(
                        fontSize: 13, color: Color(0xFF555555)),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 16),

          // Color Family heading
          Row(
            children: const [
              Text(
                'Color Family',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Color swatches
          Row(
            children: List.generate(widget.colors.length, (i) {
              final c = widget.colors[i];
              final colorValue = c['value'] as int;
              final colorName = c['name'] as String;
              final isSelected = i == _selectedIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: GestureDetector(
                  onTap: () => setState(() => _selectedIndex = i),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Color(colorValue),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary
                                : const Color(0xFFDDDDDD),
                            width: isSelected ? 2.5 : 1,
                          ),
                        ),
                        child: isSelected
                            ? Align(
                                alignment: Alignment.bottomRight,
                                child: Container(
                                  margin: const EdgeInsets.all(3),
                                  width: 16,
                                  height: 16,
                                  decoration: const BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.check,
                                      color: Colors.white, size: 10),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        colorName,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? AppColors.primary
                              : const Color(0xFF555555),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          const SizedBox(height: 14),

          // Quantity row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Quantity',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              Row(
                children: [
                  _QtyBtn(
                    icon: Icons.remove,
                    onTap: _quantity > 1
                        ? () {
                            setState(() => _quantity--);
                          }
                        : null,
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      '$_quantity',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ),
                  _QtyBtn(
                    icon: Icons.add,
                    onTap: _quantity < widget.maxQuantity
                        ? () => setState(() => _quantity++)
                        : null,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Buy Now button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () =>
                  Navigator.of(context).pop({'color': selectedName, 'quantity': _quantity}),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Buy Now',
                style: TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  const _QtyBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          border: Border.all(
              color: disabled
                  ? const Color(0xFFE5E7EB)
                  : const Color(0xFFDDDDDD)),
          borderRadius: BorderRadius.circular(8),
          color: disabled ? const Color(0xFFF9FAFB) : Colors.white,
        ),
        child: Icon(icon,
            size: 16, color: disabled ? const Color(0xFFC4C4C4) : const Color(0xFF333333)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

class _IconAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _IconAction(
      {required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.textSecondary, size: 22),
          const SizedBox(height: 2),
          Text(label,
              style: AppTypography.labelSmall
                  .copyWith(color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
