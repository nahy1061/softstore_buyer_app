import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../models/catalog_models.dart';
import '../repository/catalog_repository.dart';

class SellerScreen extends StatefulWidget {
  final String slug;

  const SellerScreen({super.key, required this.slug});

  @override
  State<SellerScreen> createState() => _SellerScreenState();
}

class _SellerScreenState extends State<SellerScreen> {
  final CatalogRepository _repo = CatalogRepository.instance;

  bool _isLoading = true;
  String? _error;
  SellerProfile? _seller;

  @override
  void initState() {
    super.initState();
    _loadSeller();
  }

  Future<void> _loadSeller() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final data = await _repo.getSellerProfile(widget.slug);
      if (!mounted) return;
      setState(() {
        _seller = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load store profile from SoftStore.pk';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _seller?.name ?? 'Store Profile',
          style: AppTypography.screenTitle.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _loadSeller,
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
                    'Loading store from SoftStore.pk...',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : _seller == null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.storefront_outlined,
                          size: 64, color: AppColors.textDisabled),
                      const SizedBox(height: 16),
                      Text(_error ?? 'Store not found', style: AppTypography.bodyLarge),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadSeller,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Banner & Header
                      Container(
                        width: double.infinity,
                        color: Colors.white,
                        padding: AppSpacing.paddingLg,
                        child: Row(
                          children: [
                            Container(
                              width: 64,
                              height: 64,
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                              ),
                              child: _seller!.logoUrl != null
                                  ? ClipOval(
                                      child: Image.network(
                                        _seller!.logoUrl!,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, __, ___) => const Icon(
                                          Icons.storefront,
                                          color: AppColors.primary,
                                          size: 32,
                                        ),
                                      ),
                                    )
                                  : const Icon(
                                      Icons.storefront,
                                      color: AppColors.primary,
                                      size: 32,
                                    ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _seller!.name,
                                    style: AppTypography.sectionHeading.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  if (_seller!.description != null &&
                                      _seller!.description!.isNotEmpty)
                                    Text(
                                      _seller!.description!,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AppColors.textSecondary,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      // Products Section
                      Padding(
                        padding: AppSpacing.paddingLg,
                        child: Text(
                          'Store Products (${_seller!.products.length})',
                          style: AppTypography.sectionHeading,
                        ),
                      ),

                      if (_seller!.products.isEmpty)
                        const Padding(
                          padding: AppSpacing.paddingLg,
                          child: Center(
                            child: Text(
                              'No products listed by this store yet.',
                              style: TextStyle(color: AppColors.textDisabled),
                            ),
                          ),
                        )
                      else
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppSpacing.lg),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.72,
                            crossAxisSpacing: AppSpacing.gridGap,
                            mainAxisSpacing: AppSpacing.gridGap,
                          ),
                          itemCount: _seller!.products.length,
                          itemBuilder: (context, index) {
                            final product = _seller!.products[index];
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
                                        color: AppColors.background,
                                        child: product.imageUrl != null &&
                                                product.imageUrl!.isNotEmpty
                                            ? Image.network(
                                                product.imageUrl!,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_, __, ___) =>
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
                              ),
                            );
                          },
                        ),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
    );
  }
}
