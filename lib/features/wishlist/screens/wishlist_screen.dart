import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../../catalog/models/catalog_models.dart';
import '../repository/wishlist_repository.dart';

class WishlistScreen extends StatefulWidget {
  const WishlistScreen({super.key});

  @override
  State<WishlistScreen> createState() => _WishlistScreenState();
}

class _WishlistScreenState extends State<WishlistScreen> {
  final WishlistRepository _repo = WishlistRepository.instance;

  bool _isLoading = true;
  String? _error;
  List<Product> _items = [];

  @override
  void initState() {
    super.initState();
    _loadWishlist();
  }

  Future<void> _loadWishlist() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await _repo.getWishlist();
      if (!mounted) return;
      setState(() {
        _items = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load wishlist from SoftStore.pk';
        _isLoading = false;
      });
    }
  }

  Future<void> _removeItem(Product product) async {
    try {
      await _repo.toggleWishlist(
        productId: product.id,
        productSlug: product.slug,
      );
      setState(() {
        _items.removeWhere((p) => p.slug == product.slug);
      });
    } catch (_) {
      // Refresh list on error
      _loadWishlist();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = context.watch<AuthCubit>().state;
    final bool isAuthenticated = authState is AuthAuthenticated;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          'My Wishlist',
          style: AppTypography.screenTitle.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          if (isAuthenticated)
            IconButton(
              icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
              onPressed: _loadWishlist,
            ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
      body: !isAuthenticated
          ? Center(
              child: Padding(
                padding: AppSpacing.paddingLg,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.favorite_border,
                        size: 64, color: AppColors.textDisabled),
                    const SizedBox(height: 16),
                    Text(
                      'Sign in to view your wishlist',
                      style: AppTypography.sectionHeading,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Save your favorite products from SoftStore.pk and access them anytime',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textSecondary),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: 200,
                      height: 44,
                      child: FilledButton(
                        onPressed: () => context.push(AppRoutes.login),
                        child: const Text('Sign In'),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : _isLoading
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Loading wishlist from SoftStore.pk...',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : _items.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.favorite_outline,
                              size: 64, color: AppColors.textDisabled),
                          const SizedBox(height: 16),
                          Text(
                            _error ?? 'Your wishlist is empty',
                            style: AppTypography.bodyLarge,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Browse SoftStore.pk to add products you love',
                            style: AppTypography.bodySmall
                                .copyWith(color: AppColors.textSecondary),
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            onPressed: () => context.go(AppRoutes.home),
                            icon: const Icon(Icons.shopping_bag_outlined),
                            label: const Text('Browse Products'),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadWishlist,
                      child: GridView.builder(
                        padding: AppSpacing.paddingLg,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 0.72,
                          crossAxisSpacing: AppSpacing.gridGap,
                          mainAxisSpacing: AppSpacing.gridGap,
                        ),
                        itemCount: _items.length,
                        itemBuilder: (context, index) {
                          final product = _items[index];
                          return Card(
                            elevation: AppDimensions.elevationCard,
                            shape: RoundedRectangleBorder(
                              borderRadius: AppDimensions.radiusMd,
                            ),
                            child: Stack(
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => context.push(
                                          '/product/${product.slug}',
                                          extra: {
                                            'name': product.name,
                                            'price': product.displayPrice.toInt(),
                                            'imageUrl': product.imageUrl,
                                          },
                                        ),
                                        child: Container(
                                          width: double.infinity,
                                          color: AppColors.background,
                                          child: product.imageUrl != null &&
                                                  product.imageUrl!.isNotEmpty
                                              ? Image.network(
                                                  product.imageUrl!,
                                                  fit: BoxFit.cover,
                                                  errorBuilder:
                                                      (_, __, ___) =>
                                                          const Icon(
                                                    Icons.shopping_bag_outlined,
                                                    size: 36,
                                                    color: AppColors.primary,
                                                  ),
                                                )
                                              : const Icon(
                                                  Icons.shopping_bag_outlined,
                                                  size: 36,
                                                  color: AppColors.primary,
                                                ),
                                        ),
                                      ),
                                    ),
                                    Padding(
                                      padding: AppSpacing.paddingMd,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product.name,
                                            style: AppTypography.productName,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: AppSpacing.xs),
                                          Text(
                                            Formatters.pKRCurrency(product.displayPrice),
                                            style: AppTypography.pricePrimary
                                                .copyWith(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                Positioned(
                                  top: 4,
                                  right: 4,
                                  child: IconButton(
                                    icon: const Icon(Icons.favorite,
                                        color: Colors.red),
                                    onPressed: () => _removeItem(product),
                                    tooltip: 'Remove from wishlist',
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
    );
  }
}
