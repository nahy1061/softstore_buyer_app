import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../app/router.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../models/cart_item.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  static final List<Map<String, dynamic>> _recommendations = [
    {
      'name': 'Wireless Earbuds Pro',
      'price': 4500,
      'discount': 50,
      'rating': 4.4,
      'sold': '13.3k',
      'icon': Icons.headphones,
    },
    {
      'name': 'Smart Watch Series X',
      'price': 12000,
      'discount': 33,
      'rating': 4.8,
      'sold': '24.8k',
      'icon': Icons.watch,
    },
    {
      'name': 'Mechanical RGB Keyboard',
      'price': 8500,
      'discount': 23,
      'rating': 4.3,
      'sold': '5.2k',
      'icon': Icons.keyboard,
    },
    {
      'name': 'Coffee Maker',
      'price': 5500,
      'discount': 21,
      'rating': 4.6,
      'sold': '8.1k',
      'icon': Icons.coffee,
    },
    {
      'name': 'Premium T-Shirt',
      'price': 1200,
      'discount': 40,
      'rating': 4.5,
      'sold': '3.9k',
      'icon': Icons.checkroom,
    },
    {
      'name': 'Premium Olive Oil 1L',
      'price': 2800,
      'discount': 20,
      'rating': 4.7,
      'sold': '6.4k',
      'icon': Icons.local_drink,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        return state.items.isEmpty
            ? _buildEmptyView(context)
            : _buildCartView(context, state);
      },
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────

  Widget _buildEmptyView(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            color: AppColors.surface,
            padding:
                const EdgeInsets.fromLTRB(24, 48, 24, 40),
            child: Column(
              children: [
                const _EmptyCartIllustration(),
                const SizedBox(height: 28),
                Text(
                  'There are no items in this cart',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () => context.go(AppRoutes.home),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                      foregroundColor: AppColors.primary,
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'CONTINUE SHOPPING',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 12),
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.62,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: _recommendations.length,
            itemBuilder: (context, index) {
              final p = _recommendations[index];
              final iconData = p['icon'] as IconData;
              return _RecommendationCard(
                name: p['name'] as String,
                price: p['price'] as int,
                discount: p['discount'] as int,
                rating: p['rating'] as double,
                sold: p['sold'] as String,
                icon: iconData,
                onAddToCart: () {
                  context.read<CartCubit>().addItem(
                        CartItem(
                          id: (p['name'] as String)
                              .toLowerCase()
                              .replaceAll(' ', '_'),
                          name: p['name'] as String,
                          price: p['price'] as int,
                          iconCodePoint: iconData.codePoint,
                        ),
                      );
                },
              );
            },
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Cart items view ──────────────────────────────────────────────────────

  void _showCheckoutSheet(BuildContext context, CartState state) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CheckoutSheet(state: state),
    );
  }

  Widget _buildCartView(BuildContext context, CartState state) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: state.items.length,
            separatorBuilder: (_, _) =>
                const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final item = state.items[index];
              return _CartItemTile(item: item);
            },
          ),
        ),

        // Bottom checkout bar
        Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: const Border(
              top: BorderSide(color: AppColors.divider),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha:0.06),
                blurRadius: 8,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal (${state.itemCount} items)',
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.textSecondary)),
                  Text(
                    'PKR ${state.totalPrice}',
                    style: AppTypography.pricePrimary.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _showCheckoutSheet(context, state),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'Checkout (${state.itemCount})',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Cart item tile ─────────────────────────────────────────────────────────

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppDimensions.radiusMd,
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          // Tappable: icon + name + price → navigate to product detail
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => context.push(
                '/product/${item.id}',
                extra: {
                  'name': item.name,
                  'price': item.price,
                  'iconCodePoint': item.iconCodePoint,
                },
              ),
              child: Row(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child:
                          Icon(item.icon, size: 36, color: AppColors.primary),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: AppTypography.productName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'PKR ${item.price}',
                          style: AppTypography.pricePrimary
                              .copyWith(color: AppColors.primary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Qty controls + delete — NOT inside the navigate GestureDetector
          Column(
            children: [
              IconButton(
                onPressed: () => context.read<CartCubit>().removeItem(item.id),
                icon: const Icon(Icons.delete_outline,
                    color: AppColors.textSecondary, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _QtyButton(
                    icon: Icons.remove,
                    onTap: () => context
                        .read<CartCubit>()
                        .updateQuantity(item.id, item.quantity - 1),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text(
                      '${item.quantity}',
                      style: AppTypography.labelMedium
                          .copyWith(fontWeight: FontWeight.bold),
                    ),
                  ),
                  _QtyButton(
                    icon: Icons.add,
                    onTap: () => context
                        .read<CartCubit>()
                        .updateQuantity(item.id, item.quantity + 1),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Checkout bottom sheet ──────────────────────────────────────────────────

class _CheckoutSheet extends StatelessWidget {
  final CartState state;
  const _CheckoutSheet({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 4),

          // Header row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Order Summary',
                  style: AppTypography.sectionHeading.copyWith(fontSize: 16),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close, color: AppColors.textSecondary),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // Items list — capped height so sheet never exceeds 70% screen
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.42,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: state.items.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 20, color: AppColors.divider),
              itemBuilder: (context, index) {
                final item = state.items[index];
                return Row(
                  children: [
                    // Icon placeholder
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Icon(item.icon,
                            size: 32, color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: AppTypography.productName,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'PKR ${item.price}',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                    // Quantity badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: AppColors.divider),
                      ),
                      child: Text(
                        'x${item.quantity}',
                        style: AppTypography.labelMedium.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Item total
                    Text(
                      'PKR ${item.total}',
                      style: AppTypography.pricePrimary.copyWith(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          const Divider(height: 1, color: AppColors.divider),

          // Totals
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Subtotal',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                    Text('PKR ${state.totalPrice}',
                        style: AppTypography.bodyMedium),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Shipping',
                        style: AppTypography.bodyMedium
                            .copyWith(color: AppColors.textSecondary)),
                    Text('Free',
                        style: AppTypography.bodyMedium.copyWith(
                            color: Colors.green,
                            fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 10),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total',
                        style: AppTypography.sectionHeading
                            .copyWith(fontSize: 15)),
                    Text(
                      'PKR ${state.totalPrice}',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                        fontSize: 17,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Place Order button
          Padding(
            padding: EdgeInsets.fromLTRB(
                16, 0, 16, MediaQuery.of(context).padding.bottom + 16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order placed successfully!'),
                      backgroundColor: AppColors.primary,
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text(
                  'Place Order',
                  style: TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _QtyButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.divider),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: AppColors.textPrimary),
      ),
    );
  }
}

// ── Empty cart illustration ────────────────────────────────────────────────

class _EmptyCartIllustration extends StatelessWidget {
  const _EmptyCartIllustration();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 160,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned(
            bottom: 10,
            child: Container(
              width: 100,
              height: 12,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha:0.12),
                borderRadius: BorderRadius.circular(50),
              ),
            ),
          ),
          Positioned(
            top: 10,
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 100,
              color: AppColors.primary.withValues(alpha:0.55),
            ),
          ),
          Positioned(
            top: 28,
            child: Icon(
              Icons.shopping_bag,
              size: 38,
              color: AppColors.primary.withValues(alpha:0.85),
            ),
          ),
          const Positioned(
            top: 4,
            right: 14,
            child: Text('+',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 22,
                    fontWeight: FontWeight.bold)),
          ),
          const Positioned(
            top: 18,
            left: 10,
            child: Text('+',
                style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 14,
                    fontWeight: FontWeight.bold)),
          ),
          Positioned(
            top: 50,
            left: 4,
            child: Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha:0.35),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 20,
            right: 4,
            child: Container(
              width: 5,
              height: 5,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha:0.3),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recommendation card ───────────────────────────────────────────────────

class _RecommendationCard extends StatelessWidget {
  final String name;
  final int price;
  final int discount;
  final double rating;
  final String sold;
  final IconData icon;
  final VoidCallback onAddToCart;

  const _RecommendationCard({
    required this.name,
    required this.price,
    required this.discount,
    required this.rating,
    required this.sold,
    required this.icon,
    required this.onAddToCart,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppDimensions.elevationCard,
      shape:
          RoundedRectangleBorder(borderRadius: AppDimensions.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            height: 120,
            color: AppColors.background,
            child: Center(
              child: Icon(icon, size: 50, color: AppColors.primary),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: AppTypography.productName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text('Rs.$price',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 13)),
                    const SizedBox(width: 4),
                    Text('-$discount%',
                        style: const TextStyle(
                            color: AppColors.primary, fontSize: 11)),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const Icon(Icons.star,
                        color: Colors.amber, size: 13),
                    const SizedBox(width: 2),
                    Text('$rating ($sold sold)',
                        style: const TextStyle(
                            fontSize: 10,
                            color: AppColors.textSecondary)),
                    const Spacer(),
                    GestureDetector(
                      onTap: onAddToCart,
                      child: Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                            Icons.shopping_cart_outlined,
                            color: Colors.white,
                            size: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
