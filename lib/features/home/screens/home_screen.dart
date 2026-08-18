import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_dimensions.dart';
// Shared bottom navigation bar used across all main screens
import '../../../core/widgets/app_bottom_nav_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String selectedCategory = 'All';
  int cartItems = 3;
  double cartTotal = 1250.00;

  final List<String> categories = ['All', 'Electronics', 'Groceries', 'Apparel', 'Home'];
  final List<Map<String, dynamic>> products = [
    {
      'name': 'Wireless Earbuds Pro', 'price': 4500,
      'category': 'Electronics', 'icon': Icons.headphones,
      'colors': [
        {'name': 'Black', 'value': 0xFF1A1A1A},
        {'name': 'White', 'value': 0xFFF5F5F5},
        {'name': 'Blue',  'value': 0xFF1565C0},
      ],
    },
    {'name': 'Organic Bananas (1 Dozen)', 'price': 350, 'category': 'Groceries', 'icon': Icons.shopping_basket, 'colors': <Map<String, dynamic>>[]},
    {
      'name': 'Smart Watch Series X', 'price': 12000,
      'category': 'Electronics', 'icon': Icons.watch,
      'colors': [
        {'name': 'Silver', 'value': 0xFFC0C0C0},
        {'name': 'Gold',   'value': 0xFFFFD700},
        {'name': 'Black',  'value': 0xFF1A1A1A},
      ],
    },
    {'name': 'Premium Olive Oil 1L', 'price': 2800, 'category': 'Groceries', 'icon': Icons.local_drink, 'colors': <Map<String, dynamic>>[]},
    {
      'name': 'Mechanical RGB Keyboard', 'price': 8500,
      'category': 'Electronics', 'icon': Icons.keyboard,
      'colors': [
        {'name': 'Black', 'value': 0xFF1A1A1A},
        {'name': 'White', 'value': 0xFFF5F5F5},
      ],
    },
    {'name': 'Artisan Sourdough Loaf', 'price': 450, 'category': 'Groceries', 'icon': Icons.bakery_dining, 'colors': <Map<String, dynamic>>[]},
    {
      'name': 'Premium T-Shirt', 'price': 1200,
      'category': 'Apparel', 'icon': Icons.checkroom,
      'colors': [
        {'name': 'Black', 'value': 0xFF1A1A1A},
        {'name': 'White', 'value': 0xFFF5F5F5},
        {'name': 'Red',   'value': 0xFFD32F2F},
        {'name': 'Navy',  'value': 0xFF1A237E},
      ],
    },
    {'name': 'Coffee Maker', 'price': 5500, 'category': 'Home', 'icon': Icons.coffee, 'colors': <Map<String, dynamic>>[]},
  ];

  @override
  Widget build(BuildContext context) {
    final filteredProducts = selectedCategory == 'All'
        ? products
        : products.where((p) => p['category'] == selectedCategory).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'SoftStore.pk',
          style: AppTypography.screenTitle.copyWith(color: AppColors.textPrimary),
        ),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: AppSpacing.paddingLg,
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search inventory...',
                hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textDisabled),
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                border: OutlineInputBorder(
                  borderRadius: AppDimensions.radiusMd,
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppDimensions.radiusMd,
                  borderSide: const BorderSide(color: AppColors.divider),
                ),
                filled: true,
                fillColor: AppColors.background,
              ),
            ),
          ),

          // Category Tabs
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.md),
                  child: GestureDetector(
                    onTap: () => setState(() => selectedCategory = category),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.lg,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primary : AppColors.background,
                        borderRadius: AppDimensions.radiusMd,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.divider,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          category,
                          style: AppTypography.labelMedium.copyWith(
                            color: isSelected ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

              // Products Grid
          Expanded(
            child: GridView.builder(
              padding: AppSpacing.paddingLg,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.75,
                crossAxisSpacing: AppSpacing.gridGap,
                mainAxisSpacing: AppSpacing.gridGap,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return _ProductCard(
                  productName: product['name'],
                  price: product['price'],
                  icon: product['icon'],
                  onTap: () => context.push(
                    '/product/${(product['name'] as String).toLowerCase().replaceAll(' ', '-')}',
                    extra: {
                      'name': product['name'] as String,
                      'price': product['price'] as int,
                      'iconCodePoint':
                          (product['icon'] as IconData).codePoint,
                      'colors': product['colors']
                          as List<Map<String, dynamic>>? ?? [],
                    },
                  ),
                );
              },
            ),
          ),

        ],
      ),

      // Shared bottom nav — index 0 = Marketplace (this screen)
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }
}

class _ProductCard extends StatelessWidget {
  final String productName;
  final int price;
  final IconData icon;
  final VoidCallback onTap;

  const _ProductCard({
    required this.productName,
    required this.price,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: AppDimensions.elevationCard,
        shape: RoundedRectangleBorder(borderRadius: AppDimensions.radiusMd),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Image Container
            Container(
              width: double.infinity,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(AppDimensions.radiusMd.topLeft.x),
                  topRight: Radius.circular(AppDimensions.radiusMd.topRight.x),
                ),
              ),
              child: Center(
                child: Icon(
                  icon,
                  size: 40,
                  color: AppColors.primary,
                ),
              ),
            ),

            // Product Info
            Expanded(
              child: Padding(
                padding: AppSpacing.paddingMd,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      productName,
                      style: AppTypography.productName,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.sm),

                    // Price
                    Text(
                      'PKR ${price.toString()}',
                      style: AppTypography.pricePrimary.copyWith(
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
