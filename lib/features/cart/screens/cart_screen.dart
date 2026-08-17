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
// Shared bottom navigation bar used across all main screens
import '../../../core/widgets/app_bottom_nav_bar.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  final Set<String> _selectedIds = {};

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
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('My Cart'),
            backgroundColor: Colors.white,
            foregroundColor: AppColors.textPrimary,
            elevation: 0,
            centerTitle: false,
            bottom: const PreferredSize(
              preferredSize: Size.fromHeight(1),
              child: Divider(
                  height: 1, thickness: 1, color: Color(0xFFE8E8E8)),
            ),
            actions: _selectedIds.isEmpty
                ? null
                : [
                    IconButton(
                      icon: const Icon(Icons.delete_outline),
                      tooltip: 'Delete selected',
                      onPressed: () {
                        final toDelete = Set<String>.from(_selectedIds);
                        setState(() => _selectedIds.clear());
                        for (final id in toDelete) {
                          context.read<CartCubit>().removeItem(id);
                        }
                      },
                    ),
                  ],
          ),
          // Shared bottom nav — index 3 = Cart (this screen)
          bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
          body: state.items.isEmpty
              ? _buildEmptyView(context)
              : _buildCartView(context, state),
        );
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
              final productId = (p['name'] as String)
                  .toLowerCase()
                  .replaceAll(' ', '_');
              return _RecommendationCard(
                name: p['name'] as String,
                price: p['price'] as int,
                discount: p['discount'] as int,
                rating: p['rating'] as double,
                sold: p['sold'] as String,
                icon: iconData,
                onTap: () => context.push(
                  '/product/$productId',
                  extra: {
                    'name': p['name'] as String,
                    'price': p['price'] as int,
                    'iconCodePoint': iconData.codePoint,
                  },
                ),
                onAddToCart: () {
                  context.read<CartCubit>().addItem(
                        CartItem(
                          id: productId,
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

  void _showCheckoutSheet(BuildContext context) {
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

  Widget _buildCartView(BuildContext context, CartState state) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  itemCount: state.items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return _CartItemTile(
                      item: item,
                      isSelected: _selectedIds.contains(item.id),
                      onToggle: () => setState(() {
                        if (_selectedIds.contains(item.id)) {
                          _selectedIds.remove(item.id);
                        } else {
                          _selectedIds.add(item.id);
                        }
                      }),
                      onDelete: () {
                        setState(() => _selectedIds.remove(item.id));
                        context.read<CartCubit>().removeItem(item.id);
                      },
                    );
                  },
                ),

                // Marketplace recommendations
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 24),
                      Text(
                        'You might also like',
                        style: AppTypography.bodyMedium.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
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
                          final productId = (p['name'] as String)
                              .toLowerCase()
                              .replaceAll(' ', '_');
                          return _RecommendationCard(
                            name: p['name'] as String,
                            price: p['price'] as int,
                            discount: p['discount'] as int,
                            rating: p['rating'] as double,
                            sold: p['sold'] as String,
                            icon: iconData,
                            onTap: () => context.push(
                              '/product/$productId',
                              extra: {
                                'name': p['name'] as String,
                                'price': p['price'] as int,
                                'iconCodePoint': iconData.codePoint,
                              },
                            ),
                            onAddToCart: () {
                              context.read<CartCubit>().addItem(
                                    CartItem(
                                      id: productId,
                                      name: p['name'] as String,
                                      price: p['price'] as int,
                                      iconCodePoint: iconData.codePoint,
                                    ),
                                  );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
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
                  onPressed: () => _showCheckoutSheet(context),
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
  final bool isSelected;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _CartItemTile({
    required this.item,
    required this.isSelected,
    required this.onToggle,
    required this.onDelete,
  });

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
          Checkbox(
            value: isSelected,
            onChanged: (_) => onToggle(),
            activeColor: AppColors.primary,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
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
                onPressed: onDelete,
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

class CartCheckoutSheet extends StatefulWidget {
  const CartCheckoutSheet();

  @override
  State<CartCheckoutSheet> createState() => _CartCheckoutSheetState();
}

class _CartCheckoutSheetState extends State<CartCheckoutSheet> {
  static const int _shippingFee = 275;
  static const int _otherFees = 10;
  static const int _platformFee = 10;

  String get _deliveryRange {
    final now = DateTime.now();
    final start = now.add(const Duration(days: 5));
    final end = now.add(const Duration(days: 9));
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[start.month - 1]} ${start.day}–${end.day}';
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final grandTotal =
            state.totalPrice + _shippingFee + _otherFees + _platformFee;

        return Container(
          height: MediaQuery.of(context).size.height * 0.92,
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // ── Drag handle ───────────────────────────────────────────
              Container(
                color: Colors.white,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: const Color(0xFFDDDDDD),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Delivery Address ──────────────────────────────
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.location_on,
                                color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Muhammad Khalid, 03408014187',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14),
                                  ),
                                  const SizedBox(height: 5),
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          'HOME',
                                          style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          'House 12, Street 4, Model Town, Lahore, Punjab',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Color(0xFF666666)),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: () {},
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'EDIT',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ── Seller + Items ────────────────────────────────
                      Container(
                        color: Colors.white,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  16, 12, 16, 8),
                              child: Row(
                                children: const [
                                  Icon(Icons.storefront_outlined,
                                      size: 18,
                                      color: Color(0xFF444444)),
                                  SizedBox(width: 6),
                                  Text(
                                    'SoftStore Official',
                                    style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                            const Divider(
                                height: 1,
                                color: Color(0xFFEEEEEE)),

                            ...state.items.map((item) => Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 12),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 72,
                                        height: 72,
                                        decoration: BoxDecoration(
                                          color: AppColors.background,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Center(
                                          child: Icon(item.icon,
                                              size: 36,
                                              color: AppColors.primary),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.name,
                                              style: const TextStyle(
                                                  fontSize: 13),
                                              maxLines: 2,
                                              overflow:
                                                  TextOverflow.ellipsis,
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'PKR ${item.price}',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                            const SizedBox(height: 10),
                                            Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                _QtyButton(
                                                  icon: Icons.remove,
                                                  onTap: () => context
                                                      .read<CartCubit>()
                                                      .updateQuantity(
                                                          item.id,
                                                          item.quantity - 1),
                                                ),
                                                Padding(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 14),
                                                  child: Text(
                                                    '${item.quantity}',
                                                    style: const TextStyle(
                                                      fontWeight:
                                                          FontWeight.bold,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                                _QtyButton(
                                                  icon: Icons.add,
                                                  onTap: () => context
                                                      .read<CartCubit>()
                                                      .updateQuantity(
                                                          item.id,
                                                          item.quantity + 1),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(
                                    height: 1,
                                    color: Color(0xFFEEEEEE)),
                              ],
                            )),

                            // Guaranteed delivery row
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 12),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      'Guaranteed by $_deliveryRange',
                                      style:
                                          const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                  Text(
                                    'PKR $_shippingFee',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(width: 2),
                                  const Icon(Icons.chevron_right,
                                      size: 18,
                                      color: Color(0xFF888888)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ── Order Summary ─────────────────────────────────
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Order Summary',
                              style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                            const SizedBox(height: 12),
                            _summaryRow('Merchandise Subtotal',
                                'PKR ${state.totalPrice}'),
                            const SizedBox(height: 10),
                            _summaryRow('Discount', 'PKR 0',
                                valueColor: AppColors.primary),
                            const Divider(
                                height: 20,
                                color: Color(0xFFEEEEEE)),

                            // Voucher row
                            Row(
                              children: [
                                Icon(Icons.local_offer_outlined,
                                    size: 16,
                                    color: AppColors.primary),
                                const SizedBox(width: 8),
                                const Text('Voucher & Code',
                                    style: TextStyle(fontSize: 13)),
                                const Spacer(),
                                const Text(
                                  'Enter your voucher code',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: Color(0xFFAAAAAA)),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.chevron_right,
                                    size: 16,
                                    color: Color(0xFFAAAAAA)),
                              ],
                            ),
                            const Divider(
                                height: 20,
                                color: Color(0xFFEEEEEE)),

                            _summaryRow(
                                'Shipping Fee Total', 'PKR $_shippingFee'),
                            const SizedBox(height: 10),
                            _summaryRow('Other Fees', 'PKR $_otherFees'),
                            const SizedBox(height: 10),

                            // Platform Fee with info icon
                            Row(
                              children: [
                                const Text('Platform Fee',
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: Color(0xFF444444))),
                                const SizedBox(width: 4),
                                Icon(Icons.info_outline,
                                    size: 14,
                                    color: Colors.grey.shade400),
                                const Spacer(),
                                Text('PKR $_platformFee',
                                    style: const TextStyle(fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 14),
                          ],
                        ),
                      ),

                      const SizedBox(height: 8),

                      // ── Invoice row ───────────────────────────────────
                      Container(
                        color: Colors.white,
                        child: ListTile(
                          dense: true,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 16),
                          title: const Text('Invoice and Contact Info',
                              style: TextStyle(fontSize: 13)),
                          trailing: const Icon(Icons.chevron_right,
                              size: 20, color: Color(0xFF888888)),
                          onTap: () {},
                        ),
                      ),

                      const SizedBox(height: 80),
                    ],
                  ),
                ),
              ),

              // ── Bottom bar ────────────────────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                      top: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Proceed to Pay
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                          16, 0, 16, bottomPadding + 12),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => BlocProvider.value(
                                value: context.read<CartCubit>(),
                                child: const _PaymentMethodSheet(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                vertical: 14, horizontal: 16),
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Proceed to Pay',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15),
                              ),
                              Text(
                                'PKR $grandTotal',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13, color: Color(0xFF444444))),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            color: valueColor ?? const Color(0xFF222222),
          ),
        ),
      ],
    );
  }
}

// ── Payment method sheet ───────────────────────────────────────────────────

class _PaymentMethodSheet extends StatefulWidget {
  const _PaymentMethodSheet();

  @override
  State<_PaymentMethodSheet> createState() => _PaymentMethodSheetState();
}

class _PaymentMethodSheetState extends State<_PaymentMethodSheet> {
  String _selected = 'card';

  static const int _shippingFee = 275;
  static const int _otherFees = 10;
  static const int _platformFee = 10;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final total =
            state.totalPrice + _shippingFee + _otherFees + _platformFee;

        return Container(
          height: MediaQuery.of(context).size.height * 0.92,
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────────────
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text(
                      'Select Payment Method',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.close,
                            color: Color(0xFF888888)),
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Info banner ────────────────────────────────
                      Container(
                        color: const Color(0xFFE8F0FE),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Icon(Icons.info_outline,
                                color: Color(0xFF1565C0), size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Please collect bank vouchers to avail bank '
                                'discounts and mega deals/flash sales.',
                                style: TextStyle(
                                    color: Color(0xFF1565C0),
                                    fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 10),

                      // ── Payment methods ────────────────────────────
                      Container(
                        color: Colors.white,
                        child: Column(
                          children: [
                            _methodRow(
                              id: 'card',
                              icon: _methodIcon(Icons.credit_card,
                                  const Color(0xFF1565C0),
                                  const Color(0xFFE8F0FE)),
                              title: 'Credit/Debit Card',
                              subtitle: 'VISA · Mastercard',
                              onTapOverride: () {
                                setState(() => _selected = 'card');
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => BlocProvider.value(
                                    value: context.read<CartCubit>(),
                                    child: const _CardDetailSheet(),
                                  ),
                                );
                              },
                            ),
                            const Divider(
                                height: 1,
                                indent: 68,
                                color: Color(0xFFEEEEEE)),
                            _methodRow(
                              id: 'cod',
                              icon: _methodIcon(
                                  Icons.payments_outlined,
                                  const Color(0xFF1976D2),
                                  const Color(0xFFE3F2FD)),
                              title: 'Cash on Delivery',
                              subtitle: 'Pay when you receive',
                              onTapOverride: () {
                                setState(() => _selected = 'cod');
                                showModalBottomSheet(
                                  context: context,
                                  isScrollControlled: true,
                                  backgroundColor: Colors.transparent,
                                  builder: (_) => BlocProvider.value(
                                    value: context.read<CartCubit>(),
                                    child: const _CodDetailSheet(),
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              // ── Bottom bar ─────────────────────────────────────────
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                      top: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                padding: EdgeInsets.fromLTRB(
                    16, 12, 16, bottomPadding + 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF666666))),
                        Text('PKR $total',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                        Text(
                          'PKR $total',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content:
                                  Text('Order placed successfully!'),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _methodRow({
    required String id,
    required Widget icon,
    required String title,
    String? subtitle,
    String? trailingLabel,
    bool disabled = false,
    VoidCallback? onTapOverride,
  }) {
    final textColor =
        disabled ? const Color(0xFFAAAAAA) : const Color(0xFF222222);
    final subColor =
        disabled ? const Color(0xFFCCCCCC) : const Color(0xFF888888);

    return InkWell(
      onTap: disabled
          ? null
          : onTapOverride ?? () => setState(() => _selected = id),
      child: Padding(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: textColor)),
                  if (subtitle != null)
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 12, color: subColor)),
                ],
              ),
            ),
            if (trailingLabel != null) ...[
              Text(trailingLabel,
                  style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF444444))),
              const SizedBox(width: 6),
            ],
            Icon(
              Icons.chevron_right,
              color: disabled
                  ? const Color(0xFFCCCCCC)
                  : const Color(0xFF888888),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _methodIcon(IconData icon, Color fg, Color bg) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(8)),
      child: Icon(icon, color: fg, size: 22),
    );
  }

  Widget _textIcon(String text, Color fg, Color bg,
      {double fontSize = 13}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(8)),
      child: Center(
        child: Text(text,
            style: TextStyle(
                color: fg,
                fontWeight: FontWeight.bold,
                fontSize: fontSize)),
      ),
    );
  }

  Widget _securityBadge(String label) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        border: Border.all(color: const Color(0xFFDDDDDD)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style:
            const TextStyle(fontSize: 9, color: Color(0xFF666666)),
      ),
    );
  }
}

// ── Cash on Delivery detail sheet ─────────────────────────────────────────

class _CodDetailSheet extends StatelessWidget {
  const _CodDetailSheet();

  static const int _shippingFee = 275;
  static const int _otherFees = 10;
  static const int _platformFee = 10;

  static const List<String> _bullets = [
    'You may pay in cash upon receiving your parcel.',
    'Cash Payment Fee (7%), with a maximum cap of PKR 100 applies only to '
        'Cash on Delivery payment method. There is no extra fee when using '
        'other payment methods.',
    'In case you have opted for cash on delivery (doorstep or collection '
        'point), you are requested to keep the exact change amount required '
        'for the payment.',
    'Before agreeing to receive the parcel, check if your delivery status '
        'has been updated to \'Out for Delivery\' on SoftStore App.',
    'Before receiving, confirm that the airway bill shows that the parcel '
        'is from SoftStore.',
    'Before you make your payment, confirm your order number, sender '
        'information, and tracking number on the parcel.',
  ];

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final subtotal =
            state.totalPrice + _shippingFee + _otherFees + _platformFee;
        final codFee = (subtotal * 0.07).round().clamp(0, 100);
        final total = subtotal + codFee;

        return Container(
          height: MediaQuery.of(context).size.height * 0.92,
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.arrow_back,
                            color: Color(0xFF333333)),
                      ),
                    ),
                    const Text(
                      'Cash on Delivery',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Info banner
                      Container(
                        color: const Color(0xFFE8F0FE),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Icon(Icons.info_outline,
                                color: Color(0xFF1565C0), size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Please collect bank vouchers to avail bank '
                                'discounts and mega deals/flash sales.',
                                style: TextStyle(
                                    color: Color(0xFF1565C0),
                                    fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // COD icon + bullets
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(
                            16, 16, 16, 20),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: const Color(0xFFE3F2FD),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                  Icons.payments_outlined,
                                  color: Color(0xFF1976D2),
                                  size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: _bullets.map((b) {
                                  return Padding(
                                    padding: const EdgeInsets.only(
                                        bottom: 12),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text('• ',
                                            style: TextStyle(
                                                fontSize: 13,
                                                height: 1.5)),
                                        Expanded(
                                          child: Text(b,
                                              style: const TextStyle(
                                                  fontSize: 13,
                                                  height: 1.5,
                                                  color:
                                                      Color(0xFF333333))),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom bar
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                      top: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                padding: EdgeInsets.fromLTRB(
                    16, 12, 16, bottomPadding + 12),
                child: Column(
                  children: [
                    _sumRow('Subtotal', 'PKR $subtotal'),
                    const SizedBox(height: 6),
                    _sumRow('Cash Payment Fee (7%)', 'PKR $codFee'),
                    const SizedBox(height: 6),
                    _sumRow('Total Amount', 'PKR $total',
                        valueColor: AppColors.primary,
                        bold: true),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final nav = Navigator.of(context);
                          final msg =
                              ScaffoldMessenger.of(context);
                          nav.pop();
                          nav.pop();
                          nav.pop();
                          msg.showSnackBar(const SnackBar(
                            content: Text('Order placed successfully!'),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Confirm Order',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sumRow(String label, String value,
      {Color? valueColor, bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 13,
                color: bold
                    ? const Color(0xFF222222)
                    : const Color(0xFF666666),
                fontWeight:
                    bold ? FontWeight.w600 : FontWeight.normal)),
        Text(value,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: valueColor ?? const Color(0xFF222222))),
      ],
    );
  }
}

// ── Credit/Debit Card sheet ────────────────────────────────────────────────

class _CardDetailSheet extends StatefulWidget {
  const _CardDetailSheet();

  @override
  State<_CardDetailSheet> createState() => _CardDetailSheetState();
}

class _CardDetailSheetState extends State<_CardDetailSheet> {
  static const int _shippingFee = 275;
  static const int _otherFees = 10;
  static const int _platformFee = 10;

  final _cardNumberCtrl = TextEditingController();
  final _expiryCtrl = TextEditingController();
  final _cvvCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void dispose() {
    _cardNumberCtrl.dispose();
    _expiryCtrl.dispose();
    _cvvCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final total =
            state.totalPrice + _shippingFee + _otherFees + _platformFee;

        return Container(
          height: MediaQuery.of(context).size.height * 0.92,
          decoration: const BoxDecoration(
            color: Color(0xFFF5F5F5),
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Icon(Icons.arrow_back,
                            color: Color(0xFF333333)),
                      ),
                    ),
                    const Text(
                      'Credit/Debit Card',
                      style: TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Info banner
                      Container(
                        color: const Color(0xFFE8F0FE),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Icon(Icons.info_outline,
                                color: Color(0xFF1565C0), size: 16),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Please collect bank vouchers to avail bank '
                                'discounts and mega deals/flash sales.',
                                style: TextStyle(
                                    color: Color(0xFF1565C0),
                                    fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Payment protection banner
                      Container(
                        color: const Color(0xFFF0FAF0),
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.verified_user,
                                color: Color(0xFF2E7D32), size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Covered by SoftStore Payment Protection',
                              style: TextStyle(
                                  color: Color(0xFF2E7D32),
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Card form
                      Container(
                        color: Colors.white,
                        padding: const EdgeInsets.fromLTRB(
                            16, 12, 16, 16),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              // Card brand logos
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.end,
                                children: [
                                  _brandBadge('MC',
                                      const Color(0xFFEB001B),
                                      Colors.white),
                                  const SizedBox(width: 4),
                                  _brandBadge('VISA',
                                      const Color(0xFF1A1F71),
                                      Colors.white),
                                  const SizedBox(width: 4),
                                  _brandBadge('UP',
                                      const Color(0xFF005BAC),
                                      Colors.white),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Card number
                              _cardField(
                                controller: _cardNumberCtrl,
                                hint: 'Card number',
                                keyboardType: TextInputType.number,
                              ),
                              const SizedBox(height: 10),

                              // Expiry + CVV
                              Row(
                                children: [
                                  Expanded(
                                    child: _cardField(
                                      controller: _expiryCtrl,
                                      hint: 'Expiry (MM/YY)',
                                      keyboardType:
                                          TextInputType.number,
                                      suffixIcon: Icons.help_outline,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: _cardField(
                                      controller: _cvvCtrl,
                                      hint: 'CVV',
                                      keyboardType:
                                          TextInputType.number,
                                      obscureText: true,
                                      suffixIcon: Icons.help_outline,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),

                              // Name on card
                              _cardField(
                                controller: _nameCtrl,
                                hint: 'Name on card',
                                suffixIcon: Icons.help_outline,
                              ),
                              const SizedBox(height: 12),

                              // Save card note
                              const Text(
                                'We will save this card for your convenience. '
                                'If required, you can remove the card in the '
                                '"Payment Options" section in the "Account" menu.',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF888888),
                                    height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Bottom bar
              Container(
                decoration: const BoxDecoration(
                  color: Colors.white,
                  border: Border(
                      top: BorderSide(color: Color(0xFFEEEEEE))),
                ),
                padding: EdgeInsets.fromLTRB(
                    16, 12, 16, bottomPadding + 12),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal',
                            style: TextStyle(
                                fontSize: 13,
                                color: Color(0xFF666666))),
                        Text('PKR $total',
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total Amount',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500)),
                        Text('PKR $total',
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          if (_cardNumberCtrl.text.isEmpty ||
                              _expiryCtrl.text.isEmpty ||
                              _cvvCtrl.text.isEmpty ||
                              _nameCtrl.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content:
                                    Text('Please fill all card details'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                            return;
                          }
                          final nav = Navigator.of(context);
                          final msg =
                              ScaffoldMessenger.of(context);
                          nav.pop();
                          nav.pop();
                          nav.pop();
                          msg.showSnackBar(const SnackBar(
                            content: Text('Order placed successfully!'),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ));
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: 14),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        child: const Text('Pay Now',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _cardField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    IconData? suffixIcon,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            color: Color(0xFFAAAAAA), fontSize: 14),
        suffixIcon: suffixIcon != null
            ? Icon(suffixIcon,
                color: const Color(0xFFAAAAAA), size: 18)
            : null,
        contentPadding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide:
              const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _brandBadge(String text, Color bg, Color fg) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(3)),
      child: Text(text,
          style: TextStyle(
              color: fg,
              fontSize: 10,
              fontWeight: FontWeight.bold)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────

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
  final VoidCallback onTap;

  const _RecommendationCard({
    required this.name,
    required this.price,
    required this.discount,
    required this.rating,
    required this.sold,
    required this.icon,
    required this.onAddToCart,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: AppDimensions.elevationCard,
      shape:
          RoundedRectangleBorder(borderRadius: AppDimensions.radiusMd),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
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
      ),
    );
  }
}
