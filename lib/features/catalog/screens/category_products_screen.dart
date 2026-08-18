import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/catalog_models.dart';
import '../repository/catalog_repository.dart';

class CategoryProductsScreen extends StatefulWidget {
  final String slug;
  final String? categoryName;

  const CategoryProductsScreen({
    super.key,
    required this.slug,
    this.categoryName,
  });

  @override
  State<CategoryProductsScreen> createState() => _CategoryProductsScreenState();
}

class _CategoryProductsScreenState extends State<CategoryProductsScreen> {
  final CatalogRepository _repo = CatalogRepository.instance;

  bool _isLoading = true;
  String? _error;
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final res = await _repo.searchProducts(
        query: '',
        category: widget.slug,
      );
      if (!mounted) return;
      setState(() {
        _products = res.products;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load category products from SoftStore.pk';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.categoryName ?? widget.slug.replaceAll('-', ' ');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          title.toUpperCase(),
          style: AppTypography.screenTitle.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _loadProducts,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading products from SoftStore.pk...',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : _products.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.storefront_outlined,
                          size: 64, color: AppColors.textDisabled),
                      const SizedBox(height: 16),
                      Text(
                        _error ?? 'No products in this category',
                        style: AppTypography.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadProducts,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadProducts,
                  child: GridView.builder(
                    padding: AppSpacing.paddingLg,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: AppSpacing.gridGap,
                      mainAxisSpacing: AppSpacing.gridGap,
                    ),
                    itemCount: _products.length,
                    itemBuilder: (context, index) {
                      final product = _products[index];
                      return GestureDetector(
                        onTap: () => context.push(
                          '/product/${product.slug}',
                          extra: {
                            'name': product.name,
                            'price': product.displayPrice.toInt(),
                            'imageUrl': product.imageUrl,
                          },
                        ),
                        child: Card(
                          elevation: AppDimensions.elevationCard,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppDimensions.radiusMd,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: AppColors.background,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(
                                          AppDimensions.radiusMd.topLeft.x),
                                      topRight: Radius.circular(
                                          AppDimensions.radiusMd.topRight.x),
                                    ),
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(
                                          AppDimensions.radiusMd.topLeft.x),
                                      topRight: Radius.circular(
                                          AppDimensions.radiusMd.topRight.x),
                                    ),
                                    child: product.imageUrl != null &&
                                            product.imageUrl!.isNotEmpty
                                        ? Image.network(
                                            product.imageUrl!,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                const Center(
                                              child: Icon(
                                                Icons.shopping_bag_outlined,
                                                size: 40,
                                                color: AppColors.primary,
                                              ),
                                            ),
                                          )
                                        : const Center(
                                            child: Icon(
                                              Icons.shopping_bag_outlined,
                                              size: 40,
                                              color: AppColors.primary,
                                            ),
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
                                      'PKR ${product.displayPrice.toStringAsFixed(0)}',
                                      style:
                                          AppTypography.pricePrimary.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
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
    );
  }
}
