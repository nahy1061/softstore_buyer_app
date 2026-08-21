import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
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
  Product? _currentProduct;
  ProductDetail? _detail;

  @override
  void initState() {
    super.initState();
    _recordView();
    _isWishlisted = WishlistRepository.instance.isProductWishlisted(widget.slug);
    _allImages = [
      if (widget.imageUrl != null && widget.imageUrl!.isNotEmpty) widget.imageUrl!,
      ...widget.images,
    ];
    _currentProduct = Product(
      id: widget.id ?? widget.slug.hashCode.abs(),
      name: widget.name,
      slug: widget.slug,
      imageUrl: widget.imageUrl,
      displayPrice: widget.price.toDouble(),
    );
    _fetchFullProductDetails();
  }

  void _recordView() {
    RecentlyViewedRepository.instance.recordProductView(
      Product(
        id: widget.id ?? 0,
        name: widget.name,
        slug: widget.slug,
        imageUrl: widget.imageUrl,
        displayPrice: widget.price.toDouble(),
      ),
    );
  }

  Future<void> _fetchFullProductDetails() async {
    if (widget.slug.isEmpty) return;
    try {
      final detail = await CatalogRepository.instance.getProductDetail(widget.slug);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        if (detail.seller != null) {
          if (detail.seller!.slug.isNotEmpty) _sellerSlug = detail.seller!.slug;
          if (detail.seller!.name.isNotEmpty) _sellerName = detail.seller!.name;
        }
        _currentProduct = Product(
          id: detail.id,
          name: detail.name,
          slug: detail.slug,
          imageUrl: detail.images.isNotEmpty ? detail.images.first : widget.imageUrl,
          displayPrice: detail.displayPrice,
          listPrice: detail.listPrice,
          discountPercent: detail.discountPercent,
          seller: detail.seller,
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
      });
    } catch (_) {}
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
                    price: widget.price,
                    imageUrl: widget.imageUrl,
                    images: _allImages,
                    sellerSlug: _sellerSlug,
                    sellerName: _sellerName,
                    product: _currentProduct,
                    rating: _detail?.rating ?? 0.0,
                    ratingCount: _detail?.ratingCount ?? 0,
                    description: _detail?.description,
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
          price: widget.price,
          imageUrl: widget.imageUrl,
          sellerSlug: _sellerSlug,
          sellerName: _sellerName,
          product: _currentProduct,
          iconCodePoint: widget.iconCodePoint,
          slug: widget.slug,
          colors: widget.colors,
        ),
      ),
    );
  }
}

// ── Overview tab ────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final String name;
  final int price;
  final String? imageUrl;
  final List<String> images;
  final String? sellerSlug;
  final String? sellerName;
  final Product? product;
  final double rating;
  final int ratingCount;
  final String? description;
  final IconData icon;
  final bool isWishlisted;
  final VoidCallback onWishlistToggle;

  const _OverviewTab({
    required this.name,
    required this.price,
    this.imageUrl,
    this.images = const [],
    this.sellerSlug,
    this.sellerName,
    this.product,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.description,
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
            sellerSlug: sellerSlug,
            sellerName: sellerName,
            product: product,
            icon: icon,
            isWishlisted: isWishlisted,
            onWishlistToggle: onWishlistToggle,
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
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Text('-20%',
                          style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 12,
                              fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(name, style: AppTypography.sectionHeading),
                const SizedBox(height: 10),
                // Rating row
                if (rating > 0)
                  Row(
                    children: [
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
                    ],
                  )
                else
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
                const SizedBox(height: 16),
                // Delivery info
                Row(
                  children: [
                    const Icon(Icons.local_shipping_outlined,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text('Free delivery',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                    const Spacer(),
                    const Icon(Icons.verified_outlined,
                        size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 6),
                    Text('100% Authentic',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Description section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Description', style: AppTypography.sectionHeading),
                const SizedBox(height: 8),
                Text(
                  description != null && description!.isNotEmpty
                      ? description!.replaceAll(RegExp(r'<[^>]*>'), '').trim()
                      : 'High quality product with premium materials. '
                          'Designed for everyday use and built to last. '
                          'Comes with a 1-year warranty and free returns within 7 days.',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary, height: 1.5),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

// ── Product Image Gallery (Multi-Image Swiper + Wide-Image Dual View) ─────────

class _ProductImageGallery extends StatefulWidget {
  final String? imageUrl;
  final List<String> images;
  final String? sellerSlug;
  final String? sellerName;
  final Product? product;
  final IconData icon;
  final bool isWishlisted;
  final VoidCallback onWishlistToggle;

  const _ProductImageGallery({
    required this.imageUrl,
    this.images = const [],
    this.sellerSlug,
    this.sellerName,
    this.product,
    required this.icon,
    required this.isWishlisted,
    required this.onWishlistToggle,
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
                        onTap: () {
                          final seller = widget.sellerSlug?.isNotEmpty == true
                              ? widget.sellerSlug!
                              : (widget.sellerName?.isNotEmpty == true
                                  ? widget.sellerName!.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                                  : 'softstore-official');
                          context.push(
                            '/seller/$seller',
                            extra: {
                              'sellerName': widget.sellerName,
                              'product': widget.product,
                            },
                          );
                        },
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

  const _RatingsTab({
    this.rating = 0.0,
    this.ratingCount = 0,
    this.reviews = const [],
    this.sellerSlug,
    this.sellerName,
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
                Text('Ratings & Reviews ($totalCount)',
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

          if (totalCount > 0)
            // Filter chip
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.divider),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.verified_outlined,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text('Verified Purchases ($totalCount)',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ),
            ),

          // Real Review cards
          if (effectiveReviews.isNotEmpty)
            ...effectiveReviews.map((r) => _ReviewCard(
                  text: r.text,
                  reviewer: r.reviewer,
                  stars: r.rating,
                ))
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
            child: Column(
              children: [
                Row(
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
                      onPressed: () {
                        final store = sellerSlug?.isNotEmpty == true
                            ? sellerSlug!
                            : 'softstore-official';
                        context.push('/seller/$store');
                      },
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
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StoreStat(
                        value: '95%',
                        label: 'Positive Seller',
                        highlight: 'High'),
                    _StoreStat(
                        value: '98%',
                        label: 'Ship on Time',
                        highlight: 'High'),
                    _StoreStat(
                        value: '100%',
                        label: 'Authentic Store',
                        highlight: 'High'),
                  ],
                ),
              ],
            ),
          ),

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

  const _ReviewCard({
    required this.text,
    required this.reviewer,
    required this.stars,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(AppSpacing.lg),
      margin: const EdgeInsets.only(bottom: 1),
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
              const Spacer(),
              Text(
                'Verified Buyer',
                style: TextStyle(fontSize: 11, color: Colors.green.shade700, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(text, style: AppTypography.bodyMedium),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.account_circle, size: 16, color: AppColors.textDisabled),
              const SizedBox(width: 6),
              Text(reviewer,
                  style: AppTypography.bodySmall
                      .copyWith(color: AppColors.textSecondary)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StoreStat extends StatelessWidget {
  final String value;
  final String label;
  final String? highlight;

  const _StoreStat(
      {required this.value, required this.label, required this.highlight});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(value,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              if (highlight != null) ...[
                const SizedBox(width: 4),
                Text(highlight!,
                    style: TextStyle(
                        color: highlight == 'High'
                            ? Colors.green
                            : Colors.orange,
                        fontSize: 11)),
              ],
            ],
          ),
          Text(label,
              style: AppTypography.bodySmall
                  .copyWith(color: AppColors.textSecondary)),
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
      // 1. Fetch products belonging strictly to the same category
      final targetCat = widget.categorySlug?.isNotEmpty == true
          ? widget.categorySlug!
          : (widget.category?.isNotEmpty == true
              ? widget.category!.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')
              : null);

      if (targetCat != null && targetCat.isNotEmpty) {
        final catResult = await CatalogRepository.instance.searchProducts(
          query: '',
          category: targetCat,
        );
        if (!mounted) return;
        final list = catResult.products.where((p) => p.slug != widget.currentSlug).toList();
        if (list.isNotEmpty) {
          setState(() {
            _products = list;
            _loading = false;
          });
          return;
        }
      }

      // 2. Search marketplace for matching product category/type keywords
      final searchTarget = widget.category?.isNotEmpty == true
          ? widget.category!
          : widget.currentName
              .split(' ')
              .where((w) => w.length > 2 && !['and', 'for', 'with', 'the'].contains(w.toLowerCase()))
              .take(2)
              .join(' ');

      if (searchTarget.isNotEmpty) {
        final result = await CatalogRepository.instance.searchProducts(
          query: searchTarget,
          category: targetCat,
        );
        if (!mounted) return;
        final list = result.products.where((p) => p.slug != widget.currentSlug).toList();
        if (list.isNotEmpty) {
          setState(() {
            _products = list;
            _loading = false;
          });
          return;
        }
      }

      // 3. Fallback to marketplace featured products
      final homeData = await CatalogRepository.instance.getHomepage();
      if (!mounted) return;
      final fallback = homeData.featuredProducts.isNotEmpty
          ? homeData.featuredProducts
          : homeData.topDeals;
      setState(() {
        _products = fallback.where((p) => p.slug != widget.currentSlug).toList();
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
          onTap: () => context.push(
            '/product/${p.slug}',
            extra: {
              'id': p.id,
              'name': p.name,
              'price': p.displayPrice.toInt(),
              'imageUrl': p.imageUrl,
            },
          ),
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
      final item = CartItem(
        uuid: slug,
        productId: id ?? slug.hashCode.abs(),
        productName: name,
        productSlug: slug,
        quantity: 1,
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
            onTap: () {
              final seller = sellerSlug?.isNotEmpty == true
                  ? sellerSlug!
                  : (sellerName?.isNotEmpty == true
                      ? sellerName!.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')
                      : 'softstore-official');
              context.push(
                '/seller/$seller',
                extra: {
                  'sellerName': sellerName,
                  'product': product,
                },
              );
            },
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
                onPressed: () => _handleBuyNow(context),
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
                onPressed: () {
                  context.read<CartCubit>().addItem(
                        CartItem(
                          uuid: slug,
                          productId: id ?? slug.hashCode.abs(),
                          productName: name,
                          productSlug: slug,
                          quantity: 1,
                          unitPriceSnapshot: price.toDouble(),
                          imageUrl: imageUrl,
                        ),
                      );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Added to cart'),
                      backgroundColor: AppColors.primary,
                      duration: const Duration(seconds: 1),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('Add to Cart',
                    style: TextStyle(fontWeight: FontWeight.bold)),
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

  const _ColorSheet({
    required this.name,
    required this.price,
    required this.iconCodePoint,
    required this.slug,
    required this.colors,
  });

  @override
  State<_ColorSheet> createState() => _ColorSheetState();
}

class _ColorSheetState extends State<_ColorSheet> {
  int _selectedIndex = 0;
  int _quantity = 1;

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
                    onTap: () {
                      if (_quantity > 1) {
                        setState(() => _quantity--);
                      }
                    },
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
                    onTap: () => setState(() => _quantity++),
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
  final VoidCallback onTap;
  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFDDDDDD)),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF333333)),
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
