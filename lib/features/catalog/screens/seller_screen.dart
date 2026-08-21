import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../../auth/screens/login_screen.dart';
import '../../wishlist/repository/wishlist_repository.dart';
import '../models/catalog_models.dart';
import '../repository/catalog_repository.dart';

class SellerScreen extends StatefulWidget {
  final String slug;
  final String? sellerName;
  final Product? initialProduct;

  const SellerScreen({
    super.key,
    required this.slug,
    this.sellerName,
    this.initialProduct,
  });

  @override
  State<SellerScreen> createState() => _SellerScreenState();
}

class _SellerScreenState extends State<SellerScreen> with SingleTickerProviderStateMixin {
  final CatalogRepository _repo = CatalogRepository.instance;
  late TabController _tabController;

  bool _isLoading = true;
  String? _error;
  SellerProfile? _seller;
  bool _isFollowing = false;
  bool _isFollowLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSeller();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSeller() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _repo.getSellerProfile(widget.slug, sellerName: widget.sellerName);
      if (!mounted) return;

      // Ensure the seller's specific products list contains the product the user came from
      final productList = <Product>[...data.products];
      if (widget.initialProduct != null &&
          !productList.any((p) => p.slug == widget.initialProduct!.slug)) {
        productList.insert(0, widget.initialProduct!);
      }

      setState(() {
        _seller = SellerProfile(
          name: widget.sellerName?.isNotEmpty == true
              ? widget.sellerName!
              : (data.name.isNotEmpty && data.name != widget.slug ? data.name : _formatSlug(widget.slug)),
          slug: widget.slug,
          description: data.description,
          logoUrl: data.logoUrl,
          bannerUrl: data.bannerUrl,
          products: productList,
        );
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      // Provide clean seller profile tailored strictly to this specific seller and product
      final displayName = widget.sellerName?.isNotEmpty == true
          ? widget.sellerName!
          : _formatSlug(widget.slug);

      final productList = <Product>[];
      if (widget.initialProduct != null) {
        productList.add(widget.initialProduct!);
      }

      setState(() {
        _seller = SellerProfile(
          name: displayName,
          slug: widget.slug,
          products: productList,
        );
        _isLoading = false;
      });
    }
  }

  String _formatSlug(String s) {
    return s
        .split('-')
        .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
        .join(' ');
  }

  Future<void> _toggleFollow() async {
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

    setState(() => _isFollowLoading = true);
    final target = !_isFollowing;

    try {
      if (target) {
        await _repo.followStore(widget.slug);
      } else {
        await _repo.unfollowStore(widget.slug);
      }
      if (!mounted) return;
      setState(() {
        _isFollowing = target;
        _isFollowLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isFollowing = target;
        _isFollowLoading = false;
      });
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isFollowing ? 'Following store' : 'Unfollowed store'),
          backgroundColor: _isFollowing ? const Color(0xFFFF6A00) : const Color(0xFF374151),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final storeName = _seller?.name.isNotEmpty == true
        ? _seller!.name
        : widget.slug
            .split('-')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');

    final avatarLetter = storeName.isNotEmpty ? storeName[0].toUpperCase() : 'S';

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF6A00)),
            )
          : NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  SliverToBoxAdapter(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        // Soft Silver / Grey Header Backdrop matching screenshot
                        Container(
                          height: 180,
                          width: double.infinity,
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFFE5E7EB),
                                Color(0xFFF3F4F6),
                                Color(0xFFF9FAFB),
                              ],
                            ),
                          ),
                          child: SafeArea(
                            bottom: false,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  // Rounded Back Button
                                  Material(
                                    color: Colors.white,
                                    shape: const CircleBorder(),
                                    elevation: 2,
                                    shadowColor: Colors.black12,
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () {
                                        if (context.canPop()) {
                                          context.pop();
                                        } else {
                                          context.go(AppRoutes.home);
                                        }
                                      },
                                      child: const Padding(
                                        padding: EdgeInsets.all(10.0),
                                        child: Icon(
                                          Icons.arrow_back_ios_new_rounded,
                                          size: 18,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                    ),
                                  ),
                                  // Rounded Cart Button
                                  Material(
                                    color: Colors.white,
                                    shape: const CircleBorder(),
                                    elevation: 2,
                                    shadowColor: Colors.black12,
                                    child: InkWell(
                                      customBorder: const CircleBorder(),
                                      onTap: () => context.go(AppRoutes.cart),
                                      child: const Padding(
                                        padding: EdgeInsets.all(10.0),
                                        child: Icon(
                                          Icons.shopping_cart_outlined,
                                          size: 19,
                                          color: Color(0xFF1F2937),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // Floating White Store Profile Card matching screenshot
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 110, 16, 0),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  // Peach Circle Avatar with Letter
                                  Container(
                                    width: 58,
                                    height: 58,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFE5D9),
                                      shape: BoxShape.circle,
                                    ),
                                    alignment: Alignment.center,
                                    child: _seller?.logoUrl != null && _seller!.logoUrl!.isNotEmpty
                                        ? ClipOval(
                                            child: Image.network(
                                              _seller!.logoUrl!,
                                              fit: BoxFit.cover,
                                              width: 58,
                                              height: 58,
                                              errorBuilder: (_, __, ___) => Text(
                                                avatarLetter,
                                                style: const TextStyle(
                                                  fontSize: 26,
                                                  fontWeight: FontWeight.bold,
                                                  color: Color(0xFFFF6A00),
                                                ),
                                              ),
                                            ),
                                          )
                                        : Text(
                                            avatarLetter,
                                            style: const TextStyle(
                                              fontSize: 26,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFFFF6A00),
                                            ),
                                          ),
                                  ),
                                  const SizedBox(width: 14),

                                  // Store Name & Subtitle
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          storeName,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF111827),
                                            letterSpacing: -0.2,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 4),
                                        const Text(
                                          'New Seller',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF6B7280),
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Bright Orange Follow Button
                                  SizedBox(
                                    height: 40,
                                    child: ElevatedButton(
                                      onPressed: _isFollowLoading ? null : _toggleFollow,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: _isFollowing
                                            ? const Color(0xFFF3F4F6)
                                            : const Color(0xFFFF6A00),
                                        foregroundColor:
                                            _isFollowing ? const Color(0xFF374151) : Colors.white,
                                        elevation: 0,
                                        padding: const EdgeInsets.symmetric(horizontal: 20),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                      child: _isFollowLoading
                                          ? const SizedBox(
                                              width: 16,
                                              height: 16,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: Colors.white,
                                              ),
                                            )
                                          : Text(
                                              _isFollowing ? 'Following' : 'Follow',
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              // Followers Count
                              const Text(
                                '0 Followers',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Color(0xFF6B7280),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Tab Bar (Products, Categories, Chat)
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverTabBarDelegate(
                      TabBar(
                        controller: _tabController,
                        labelColor: const Color(0xFFFF6A00),
                        unselectedLabelColor: const Color(0xFF6B7280),
                        indicatorColor: const Color(0xFFFF6A00),
                        indicatorWeight: 2.5,
                        indicatorSize: TabBarIndicatorSize.tab,
                        labelStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                        tabs: const [
                          Tab(text: 'Products'),
                          Tab(text: 'Categories'),
                          Tab(text: 'Chat'),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                controller: _tabController,
                children: [
                  // Tab 1: Products
                  _buildProductsTab(),

                  // Tab 2: Categories
                  _buildCategoriesTab(),

                  // Tab 3: Chat
                  _buildChatTab(),
                ],
              ),
            ),
    );
  }

  Widget _buildProductsTab() {
    final products = _seller?.products ?? [];

    if (products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.inventory_2_outlined, size: 56, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 12),
            const Text(
              'No products available yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Check back soon for new items',
              style: TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return _SellerProductCard(product: product);
      },
    );
  }

  Widget _buildCategoriesTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.category_outlined, size: 56, color: Color(0xFF9CA3AF)),
          const SizedBox(height: 12),
          const Text(
            'All Store Categories',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Color(0xFF4B5563),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Browsing items from ${_seller?.name ?? 'store'}',
            style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _buildChatTab() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.chat_outlined, size: 56, color: Color(0xFFFF6A00)),
          const SizedBox(height: 14),
          Text(
            'Chat with ${_seller?.name ?? 'Seller'}',
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Ask questions about products or orders',
            style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => context.push(AppRoutes.messages),
            icon: const Icon(Icons.message_outlined, size: 18),
            label: const Text('Start Conversation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF6A00),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Seller Product Card matching screenshot layout
// ─────────────────────────────────────────────────────────────────────────────
class _SellerProductCard extends StatefulWidget {
  final Product product;

  const _SellerProductCard({required this.product});

  @override
  State<_SellerProductCard> createState() => _SellerProductCardState();
}

class _SellerProductCardState extends State<_SellerProductCard> {
  late bool _isWishlisted;

  @override
  void initState() {
    super.initState();
    _isWishlisted = WishlistRepository.instance.isProductWishlisted(widget.product.slug);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.product;

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
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with Wishlist Heart in top-right
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
                    child: Container(
                      color: const Color(0xFFF3F4F6),
                      child: p.imageUrl != null && p.imageUrl!.isNotEmpty
                          ? Image.network(
                              p.imageUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Icon(Icons.image_outlined, color: Colors.grey, size: 36),
                              ),
                            )
                          : const Center(
                              child: Icon(Icons.image_outlined, color: Colors.grey, size: 36),
                            ),
                    ),
                  ),
                  // Wishlist heart button
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.white.withValues(alpha: 0.95),
                      shape: const CircleBorder(),
                      elevation: 2,
                      shadowColor: Colors.black26,
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: () async {
                          final authState = context.read<AuthCubit>().state;
                          if (authState is! AuthAuthenticated) {
                            final loggedIn = await LoginScreen.showAsModal(context);
                            if (loggedIn != true &&
                                mounted &&
                                context.read<AuthCubit>().state is! AuthAuthenticated) {
                              return;
                            }
                          }
                          final added = await WishlistRepository.instance.toggleWishlist(
                            productId: p.id,
                            productSlug: p.slug,
                            product: p,
                          );
                          if (mounted) {
                            setState(() => _isWishlisted = added);
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Icon(
                            _isWishlisted ? Icons.favorite : Icons.favorite_border_rounded,
                            color: _isWishlisted ? Colors.red : const Color(0xFF1F2937),
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Product Name & Orange Price
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF1F2937),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    Formatters.pKRCurrency(p.displayPrice),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6A00),
                    ),
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

// ─────────────────────────────────────────────────────────────────────────────
// SliverTabBarDelegate
// ─────────────────────────────────────────────────────────────────────────────
class _SliverTabBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverTabBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.white,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverTabBarDelegate oldDelegate) {
    return false;
  }
}
