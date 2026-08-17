import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../cart/cubit/cart_cubit.dart';
import '../../cart/cubit/cart_state.dart';
import '../../cart/models/cart_item.dart';
import '../../cart/screens/cart_screen.dart';

class ProductDetailScreen extends StatelessWidget {
  final String slug;
  final String name;
  final int price;
  final int iconCodePoint;
  final List<Map<String, dynamic>> colors;

  const ProductDetailScreen({
    super.key,
    required this.slug,
    required this.name,
    required this.price,
    required this.iconCodePoint,
    this.colors = const [],
  });

  IconData get _icon =>
      // ignore: non_const_argument_for_const_parameter
      IconData(iconCodePoint, fontFamily: 'MaterialIcons');

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
                  ctx.go(AppRoutes.cart);
                }
              },
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.open_in_new,
                  color: AppColors.textSecondary, size: 22),
              onPressed: () {},
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
                  _OverviewTab(name: name, price: price, icon: _icon),
                  const _RatingsTab(),
                  _ProductDetailsTab(name: name),
                  _RecommendedTab(currentSlug: slug),
                ],
              ),
            ),
          ],
        ),
        bottomNavigationBar: _BottomBar(
          name: name,
          price: price,
          iconCodePoint: iconCodePoint,
          slug: slug,
          colors: colors,
        ),
      ),
    );
  }

}

// ── Overview tab ────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  final String name;
  final int price;
  final IconData icon;

  const _OverviewTab(
      {required this.name, required this.price, required this.icon});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product image
          Container(
            width: double.infinity,
            height: 280,
            color: Colors.white,
            child: Center(
              child: Icon(icon, size: 100, color: AppColors.primary),
            ),
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
                      'PKR $price',
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
                Row(
                  children: [
                    ...List.generate(
                      4,
                      (_) => const Icon(Icons.star,
                          color: Colors.amber, size: 16),
                    ),
                    const Icon(Icons.star_half,
                        color: Colors.amber, size: 16),
                    const SizedBox(width: 6),
                    Text('4.4',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                    const SizedBox(width: 4),
                    Text('(265 reviews)',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textDisabled)),
                    const SizedBox(width: 4),
                    Text('1.2k sold',
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
                  'High quality product with premium materials. '
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

// ── Ratings tab ─────────────────────────────────────────────────────────────

class _RatingsTab extends StatelessWidget {
  const _RatingsTab();

  static const _reviews = [
    {
      'text':
          'Really great product! The quality exceeded my expectations. Fast delivery too.',
      'reviewer': 'Rashid H.',
      'stars': 5,
    },
    {
      'text':
          'Good value for the price. Packaging could be better but product itself is decent.',
      'reviewer': '3***3',
      'stars': 4,
    },
    {
      'text':
          'Everything was good but packing was not great. Product might break during transit.',
      'reviewer': 'Dr K.',
      'stars': 5,
    },
  ];

  @override
  Widget build(BuildContext context) {
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
                Text('Ratings & Reviews (265)',
                    style: AppTypography.sectionHeading),
                Row(
                  children: [
                    Text('4.4',
                        style: AppTypography.sectionHeading
                            .copyWith(color: AppColors.textPrimary)),
                    const SizedBox(width: 4),
                    ...List.generate(
                      4,
                      (_) => const Icon(Icons.star,
                          color: Colors.amber, size: 16),
                    ),
                    const Icon(Icons.star_half,
                        color: Colors.amber, size: 16),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textSecondary, size: 18),
                  ],
                ),
              ],
            ),
          ),

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
                  const Icon(Icons.image_outlined,
                      size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Text('With images/videos (38)',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),

          // Review cards
          ..._reviews.map((r) => _ReviewCard(
                text: r['text'] as String,
                reviewer: r['reviewer'] as String,
                stars: r['stars'] as int,
              )),

          const SizedBox(height: 8),

          // Questions section
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Questions about this Product (49)',
                        style: AppTypography.sectionHeading),
                    Row(
                      children: [
                        Text('View All',
                            style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary)),
                        const Icon(Icons.chevron_right,
                            size: 16, color: AppColors.textSecondary),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Text('Q',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Is the product original?',
                        style: AppTypography.bodySmall),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.chat_bubble_outline,
                        size: 16, color: Colors.blue),
                    const SizedBox(width: 6),
                    Text('Ask Questions',
                        style: AppTypography.bodySmall
                            .copyWith(color: Colors.blue)),
                    const Icon(Icons.chevron_right,
                        size: 16, color: Colors.blue),
                  ],
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
                    const Expanded(
                      child: Text('SoftStore Official',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                    ElevatedButton(
                      onPressed: () {},
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
                        value: '86%',
                        label: 'Positive Seller',
                        highlight: 'High'),
                    _StoreStat(
                        value: '75%',
                        label: 'Ship on Time',
                        highlight: 'Medium'),
                    _StoreStat(
                        value: '--',
                        label: 'Chat Response',
                        highlight: null),
                  ],
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

class _ReviewCard extends StatelessWidget {
  final String text;
  final String reviewer;
  final int stars;

  const _ReviewCard(
      {required this.text, required this.reviewer, required this.stars});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      margin: const EdgeInsets.only(bottom: 2),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(text,
                    style: AppTypography.bodySmall.copyWith(height: 1.5),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 8),
                Row(
                  children: [
                    ...List.generate(
                      stars,
                      (_) => const Icon(Icons.star,
                          color: Colors.amber, size: 13),
                    ),
                    ...List.generate(
                      5 - stars,
                      (_) => const Icon(Icons.star_border,
                          color: Colors.amber, size: 13),
                    ),
                    const SizedBox(width: 6),
                    Text(reviewer,
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Thumbnail placeholder
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.divider),
            ),
            child: const Icon(Icons.image_outlined,
                color: AppColors.textDisabled, size: 28),
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
  const _ProductDetailsTab({required this.name});

  @override
  Widget build(BuildContext context) {
    final specs = [
      {'label': 'Brand', 'value': 'SoftStore'},
      {'label': 'Model', 'value': name},
      {'label': 'Condition', 'value': 'New'},
      {'label': 'Warranty', 'value': '1 Year'},
      {'label': 'Return Policy', 'value': '7 Days'},
      {'label': 'In the Box', 'value': 'Product + Manual'},
    ];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        color: Colors.white,
        child: Column(
          children: specs
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
                                    color: AppColors.textSecondary)),
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

// ── Recommended tab ─────────────────────────────────────────────────────────

class _RecommendedTab extends StatelessWidget {
  final String currentSlug;
  const _RecommendedTab({required this.currentSlug});

  static final _items = [
    {'name': 'Wireless Earbuds Pro', 'price': 4500, 'icon': Icons.headphones},
    {'name': 'Smart Watch Series X', 'price': 12000, 'icon': Icons.watch},
    {'name': 'Mechanical RGB Keyboard', 'price': 8500, 'icon': Icons.keyboard},
    {'name': 'Coffee Maker', 'price': 5500, 'icon': Icons.coffee},
    {'name': 'Premium T-Shirt', 'price': 1200, 'icon': Icons.checkroom},
    {'name': 'Premium Olive Oil 1L', 'price': 2800, 'icon': Icons.local_drink},
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.72,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _items.length,
      itemBuilder: (context, index) {
        final p = _items[index];
        final icon = p['icon'] as IconData;
        return Card(
          elevation: 1,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                height: 110,
                color: AppColors.background,
                child:
                    Center(child: Icon(icon, size: 48, color: AppColors.primary)),
              ),
              Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p['name'] as String,
                        style: AppTypography.productName,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Text('PKR ${p['price']}',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Bottom bar ───────────────────────────────────────────────────────────────

class _BottomBar extends StatelessWidget {
  final String name;
  final int price;
  final int iconCodePoint;
  final String slug;
  final List<Map<String, dynamic>> colors;

  const _BottomBar({
    required this.name,
    required this.price,
    required this.iconCodePoint,
    required this.slug,
    required this.colors,
  });

  void _showCheckout(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BlocProvider.value(
        value: context.read<CartCubit>(),
        child: const CartCheckoutSheet(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.divider)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      child: Row(
        children: [
          // Store
          _IconAction(
            icon: Icons.store_outlined,
            label: 'Store',
            onTap: () {},
          ),
          const SizedBox(width: 8),
          // Chat
          _IconAction(
            icon: Icons.chat_bubble_outline,
            label: 'Chat',
            onTap: () {},
          ),
          const SizedBox(width: 8),
          // Buy Now
          Expanded(
            child: SizedBox(
              height: 46,
              child: OutlinedButton(
                onPressed: () {
                  if (colors.isEmpty) {
                    context.read<CartCubit>().addItem(CartItem(
                          id: slug,
                          productId: slug,
                          productName: name,
                          quantity: 1,
                          unitPriceSnapshot: price,
                          subtotalSnapshot: price,
                          iconCodePoint: iconCodePoint,
                        ));
                    _showCheckout(context);
                    return;
                  }
                  showModalBottomSheet<String>(
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
                  ).then((selectedColor) {
                    if (selectedColor != null && context.mounted) {
                      context.read<CartCubit>().addItem(CartItem(
                            id: '${slug}_$selectedColor',
                            productId: slug,
                            productName: '$name ($selectedColor)',
                            quantity: 1,
                            unitPriceSnapshot: price,
                            subtotalSnapshot: price,
                            iconCodePoint: iconCodePoint,
                          ));
                      _showCheckout(context);
                    }
                  });
                },
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
                          id: slug,
                          productId: slug,
                          productName: name,
                          quantity: 1,
                          unitPriceSnapshot: price,
                          subtotalSnapshot: price,
                          iconCodePoint: iconCodePoint,
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
                  Navigator.of(context).pop(selectedName),
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
