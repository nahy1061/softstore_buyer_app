import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../models/catalog_models.dart';
import '../repository/catalog_repository.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  final CatalogRepository _repo = CatalogRepository.instance;

  bool _isLoading = true;
  String? _error;
  List<Category> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list = await _repo.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Failed to load categories from SoftStore.pk';
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
          'All Categories',
          style: AppTypography.screenTitle.copyWith(color: AppColors.textPrimary),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
            onPressed: _loadCategories,
            tooltip: 'Refresh categories',
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Loading categories from SoftStore.pk...',
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
            )
          : _categories.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.category_outlined,
                          size: 64, color: AppColors.textDisabled),
                      const SizedBox(height: 16),
                      Text(
                        _error ?? 'No categories found',
                        style: AppTypography.bodyLarge,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: _loadCategories,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCategories,
                  child: GridView.builder(
                    padding: AppSpacing.paddingLg,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 1.1,
                      crossAxisSpacing: AppSpacing.gridGap,
                      mainAxisSpacing: AppSpacing.gridGap,
                    ),
                    itemCount: _categories.length,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return GestureDetector(
                        onTap: () => context.push(
                          '/category-products/${category.slug}',
                          extra: {'name': category.name},
                        ),
                        child: Card(
                          elevation: AppDimensions.elevationCard,
                          shape: RoundedRectangleBorder(
                            borderRadius: AppDimensions.radiusMd,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.primary
                                      .withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: category.imageUrl != null &&
                                        category.imageUrl!.isNotEmpty
                                    ? ClipOval(
                                        child: Image.network(
                                          category.imageUrl!,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              const Icon(
                                            Icons.category_outlined,
                                            color: AppColors.primary,
                                            size: 28,
                                          ),
                                        ),
                                      )
                                    : const Icon(
                                        Icons.category_outlined,
                                        color: AppColors.primary,
                                        size: 28,
                                      ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.xs),
                                child: Text(
                                  category.name,
                                  style: AppTypography.productName.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (category.productCount != null)
                                Text(
                                  '${category.productCount} items',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textDisabled,
                                    fontSize: 11,
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
