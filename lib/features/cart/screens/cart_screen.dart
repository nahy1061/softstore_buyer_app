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
import '../models/cart_models.dart';
import '../models/cart_models.dart' as cart_models;
import '../repository/cart_repository.dart' as cart_repo;
import '../../orders/models/order_model.dart';
import '../../orders/repository/order_repository.dart';
// Shared bottom navigation bar used across all main screens
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../../core/utils/validators.dart';

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
                  final price = (p['price'] as num).toDouble();
                  context.read<CartCubit>().addItem(
                        CartItem(
                          uuid: productId,
                          productId: productId.hashCode.abs(),
                          productName: p['name'] as String,
                          quantity: 1,
                          unitPriceSnapshot: price,
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
    context.go('/checkout');
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
                              final price = (p['price'] as num).toDouble();
                              context.read<CartCubit>().addItem(
                                    CartItem(
                                      uuid: productId,
                                      productId: productId.hashCode.abs(),
                                      productName: p['name'] as String,
                                      quantity: 1,
                                      unitPriceSnapshot: price,
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
                    'PKR ${state.subtotal}',
                    style: AppTypography.pricePrimary.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Delivery',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.textSecondary)),
                  if (state.quoteLoading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  else if (state.freeDelivery)
                    Text(
                      'Free',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    Text(
                      'PKR ${state.deliveryFee}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
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
                    'Checkout (${state.itemCount})  —  PKR ${state.total}',
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
  const CartCheckoutSheet({super.key});

  @override
  State<CartCheckoutSheet> createState() => _CartCheckoutSheetState();
}

class _CartCheckoutSheetState extends State<CartCheckoutSheet> {
  static const int _otherFees = 10;
  static const int _platformFee = 10;

  // Active delivery address state
  String _recipientName = 'Muhammad Khalid';
  String _recipientPhone = '03408014187';
  String _addressLabel = 'HOME';
  String _streetAddress = 'House 12, Street 4, Model Town';
  String _city = 'Lahore';
  String _province = 'Punjab';

  // Delivery method state
  DeliveryOption? _selectedDeliveryOption;
  late final List<DeliveryOption> _deliveryOptions;

  @override
  void initState() {
    super.initState();
    _deliveryOptions = DeliveryOption.getDeliveryOptions();
  }

  void _openEditLocationSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CheckoutLocationEditSheet(
        initialName: _recipientName,
        initialPhone: _recipientPhone,
        initialLabel: _addressLabel,
        initialStreet: _streetAddress,
        initialCity: _city,
        initialProvince: _province,
        onSave: ({
          required String name,
          required String phone,
          required String label,
          required String street,
          required String city,
          required String province,
        }) {
          setState(() {
            _recipientName = name;
            _recipientPhone = phone;
            _addressLabel = label;
            _streetAddress = street;
            _city = city;
            _province = province;
          });
        },
      ),
    );
  }

  void _openDeliveryMethodPickerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _DeliveryOptionPickerSheet(
        options: _deliveryOptions,
        initialSelected: _selectedDeliveryOption,
        onSelect: (DeliveryOption option) {
          setState(() {
            _selectedDeliveryOption = option;
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final shippingFee = _selectedDeliveryOption?.fee ?? 0;
        final grandTotal =
            state.totalPrice + shippingFee + _otherFees + _platformFee;

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
                            Container(
                              margin: const EdgeInsets.only(top: 2),
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.location_on,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: InkWell(
                                onTap: _openEditLocationSheet,
                                borderRadius: BorderRadius.circular(6),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '$_recipientName, $_recipientPhone',
                                      style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14),
                                    ),
                                    const SizedBox(height: 5),
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 6,
                                                  vertical: 2),
                                          decoration: BoxDecoration(
                                            color: AppColors.primary
                                                .withValues(alpha: 0.12),
                                            borderRadius:
                                                BorderRadius.circular(3),
                                          ),
                                          child: Text(
                                            _addressLabel.toUpperCase(),
                                            style: const TextStyle(
                                              color: AppColors.primary,
                                              fontSize: 10,
                                              fontWeight:
                                                  FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            '$_streetAddress, $_city, $_province',
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
                            ),
                            const SizedBox(width: 8),
                            // Edit button in front of location
                            OutlinedButton.icon(
                              onPressed: _openEditLocationSheet,
                              icon: const Icon(
                                Icons.edit_outlined,
                                size: 14,
                                color: AppColors.primary,
                              ),
                              label: const Text(
                                'EDIT',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(
                                    color: AppColors.primary, width: 1.2),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 6),
                                minimumSize: Size.zero,
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(6),
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

                            // ── Delivery Method Selector ───────────────────
                            _buildDeliveryMethodSection(),
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
                              'Shipping Fee Total',
                              _selectedDeliveryOption == null
                                  ? 'Not selected'
                                  : 'PKR ${_selectedDeliveryOption!.fee}',
                              valueColor: _selectedDeliveryOption == null
                                  ? AppColors.error
                                  : null,
                            ),
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
                      Material(
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
                            if (_selectedDeliveryOption == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                      'Please select a delivery method before proceeding to pay'),
                                  backgroundColor: AppColors.error,
                                  behavior: SnackBarBehavior.floating,
                                  duration: Duration(seconds: 3),
                                ),
                              );
                              _openDeliveryMethodPickerSheet();
                              return;
                            }

                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => BlocProvider.value(
                                value: context.read<CartCubit>(),
                                child: _PaymentMethodSheet(
                                  shippingFee: _selectedDeliveryOption!.fee,
                                  deliveryMethodTitle:
                                      _selectedDeliveryOption!.title,
                                  customerName: _recipientName,
                                  customerPhone: _recipientPhone,
                                  customerAddress: _streetAddress,
                                  customerCity: _city,
                                ),
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

  Widget _buildDeliveryMethodSection() {
    final option = _selectedDeliveryOption;
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_shipping_outlined,
                  size: 18, color: Color(0xFF444444)),
              const SizedBox(width: 8),
              const Text(
                'Delivery Method',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: Color(0xFF222222),
                ),
              ),
              const SizedBox(width: 6),
              if (option == null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'REQUIRED',
                    style: TextStyle(
                      color: AppColors.error,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              const Spacer(),
              TextButton(
                onPressed: _openDeliveryMethodPickerSheet,
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  option == null ? 'SELECT' : 'CHANGE',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Material(
            color: option == null
                ? AppColors.error.withValues(alpha: 0.04)
                : const Color(0xFFFAFAFA),
            borderRadius: BorderRadius.circular(8),
            child: InkWell(
              onTap: _openDeliveryMethodPickerSheet,
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: option == null
                        ? AppColors.error.withValues(alpha: 0.4)
                        : const Color(0xFFE0E0E0),
                    width: option == null ? 1.2 : 1,
                  ),
                ),
                child: option == null
                    ? Row(
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              color: AppColors.error, size: 22),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: const [
                                Text(
                                  'Please select a delivery method',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.error,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  'Choose Standard, Express, Collection Point, or Saver',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF777777),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right,
                              color: AppColors.error, size: 20),
                        ],
                      )
                    : Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              option.icon,
                              color: AppColors.primary,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      option.title,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                        color: Color(0xFF222222),
                                      ),
                                    ),
                                    if (option.badge != null) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 5, vertical: 1.5),
                                        decoration: BoxDecoration(
                                          color: AppColors.primary
                                              .withValues(alpha: 0.12),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          option.badge!,
                                          style: const TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  option.estimatedDelivery,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFF555555),
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  option.description,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF888888),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'PKR ${option.fee}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF222222),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
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

// ── Checkout Location Edit Sheet ───────────────────────────────────────────

class _CheckoutLocationEditSheet extends StatefulWidget {
  final String initialName;
  final String initialPhone;
  final String initialLabel;
  final String initialStreet;
  final String initialCity;
  final String initialProvince;
  final void Function({
    required String name,
    required String phone,
    required String label,
    required String street,
    required String city,
    required String province,
  }) onSave;

  const _CheckoutLocationEditSheet({
    required this.initialName,
    required this.initialPhone,
    required this.initialLabel,
    required this.initialStreet,
    required this.initialCity,
    required this.initialProvince,
    required this.onSave,
  });

  @override
  State<_CheckoutLocationEditSheet> createState() =>
      _CheckoutLocationEditSheetState();
}

class _CheckoutLocationEditSheetState
    extends State<_CheckoutLocationEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _streetCtrl;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _provinceCtrl;
  late String _selectedLabel;

  static final List<Map<String, String>> _savedAddresses = [
    {
      'id': '1',
      'label': 'HOME',
      'name': 'Muhammad Khalid',
      'phone': '03408014187',
      'street': 'House 12, Street 4, Model Town',
      'city': 'Lahore',
      'province': 'Punjab',
    },
    {
      'id': '2',
      'label': 'OFFICE',
      'name': 'Muhammad Khalid',
      'phone': '03408014187',
      'street': 'Office 401, Plaza 33, Main Boulevard, Gulberg III',
      'city': 'Lahore',
      'province': 'Punjab',
    },
    {
      'id': '3',
      'label': 'OTHER',
      'name': 'Muhammad Khalid',
      'phone': '03001234567',
      'street': 'House 45, Street 10, Sector F-10/2',
      'city': 'Islamabad',
      'province': 'Federal Capital',
    },
  ];

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.initialName);
    _phoneCtrl = TextEditingController(text: widget.initialPhone);
    _streetCtrl = TextEditingController(text: widget.initialStreet);
    _cityCtrl = TextEditingController(text: widget.initialCity);
    _provinceCtrl = TextEditingController(text: widget.initialProvince);
    _selectedLabel = widget.initialLabel.toUpperCase();
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _streetCtrl.dispose();
    _cityCtrl.dispose();
    _provinceCtrl.dispose();
    super.dispose();
  }

  void _applySavedAddress(Map<String, String> address) {
    setState(() {
      _nameCtrl.text = address['name'] ?? '';
      _phoneCtrl.text = address['phone'] ?? '';
      _streetCtrl.text = address['street'] ?? '';
      _cityCtrl.text = address['city'] ?? '';
      _provinceCtrl.text = address['province'] ?? '';
      _selectedLabel = (address['label'] ?? 'HOME').toUpperCase();
    });
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    widget.onSave(
      name: _nameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      label: _selectedLabel,
      street: _streetCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      province: _provinceCtrl.text.trim(),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final viewInsets = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // ── Drag Handle + Header ──────────────────────────────────────
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Column(
              children: [
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Edit Delivery Location',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close, color: Color(0xFF777777), size: 22),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Content ───────────────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(16, 16, 16, viewInsets + 16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Saved addresses quick pick
                    const Text(
                      'Saved Addresses',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._savedAddresses.map((addr) {
                      final isSelected = _streetCtrl.text.trim() == addr['street'] &&
                          _cityCtrl.text.trim() == addr['city'];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          child: InkWell(
                            onTap: () => _applySavedAddress(addr),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: isSelected
                                      ? AppColors.primary
                                      : const Color(0xFFE0E0E0),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: Icon(
                                      isSelected
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_off,
                                      size: 20,
                                      color: isSelected
                                          ? AppColors.primary
                                          : const Color(0xFF999999),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Text(
                                              addr['name'] ?? '',
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                                fontSize: 13,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Container(
                                              padding: const EdgeInsets.symmetric(
                                                  horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: AppColors.primary
                                                    .withValues(alpha: 0.1),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                addr['label'] ?? '',
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  color: AppColors.primary,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          '${addr['street']}, ${addr['city']}, ${addr['province']}\nPhone: ${addr['phone']}',
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF666666),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    const SizedBox(height: 16),
                    const Divider(color: Color(0xFFE0E0E0)),
                    const SizedBox(height: 12),

                    // Manual Edit Section
                    const Text(
                      'Location Details',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Address Label Selector
                    const Text(
                      'Address Label',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: ['HOME', 'OFFICE', 'OTHER'].map((label) {
                        final isSelected = _selectedLabel == label;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(label),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() => _selectedLabel = label);
                              }
                            },
                            selectedColor: AppColors.primary.withValues(alpha: 0.15),
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFF555555),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                              fontSize: 12,
                            ),
                            side: BorderSide(
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFFDDDDDD),
                            ),
                            backgroundColor: Colors.white,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    // Recipient Name
                    _buildInputField(
                      controller: _nameCtrl,
                      label: 'Full Name',
                      hint: 'Recipient\'s name',
                      icon: Icons.person_outline,
                      validator: Validators.fullName,
                    ),
                    const SizedBox(height: 14),

                    // Contact Phone
                    _buildInputField(
                      controller: _phoneCtrl,
                      label: 'Phone Number',
                      hint: '03XXXXXXXXX',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      validator: (v) => (v?.isEmpty ?? true)
                          ? 'Phone is required'
                          : Validators.pakistaniPhone(v),
                    ),
                    const SizedBox(height: 14),

                    // Street Address
                    _buildInputField(
                      controller: _streetCtrl,
                      label: 'Street Address',
                      hint: 'House/Flat no, Street, Area',
                      icon: Icons.home_outlined,
                      maxLines: 2,
                      validator: Validators.address,
                    ),
                    const SizedBox(height: 14),

                    // City and Province Row
                    Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            controller: _cityCtrl,
                            label: 'City',
                            hint: 'e.g. Lahore',
                            icon: Icons.location_city_outlined,
                            validator: Validators.city,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildInputField(
                            controller: _provinceCtrl,
                            label: 'Province / State',
                            hint: 'e.g. Punjab',
                            icon: Icons.map_outlined,
                            validator: (v) => (v?.isEmpty ?? true)
                                ? 'Province is required'
                                : null,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ),

          // ── Bottom Action Button ──────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _save,
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
                  'Save Location',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Color(0xFF666666),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 13, color: Color(0xFFAAAAAA)),
            prefixIcon: Icon(icon, size: 20, color: const Color(0xFF777777)),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.error),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Delivery Option Model & Picker Sheet ───────────────────────────────────

class DeliveryOption {
  final String id;
  final String title;
  final String estimatedDelivery;
  final int fee;
  final IconData icon;
  final String description;
  final String? badge;

  const DeliveryOption({
    required this.id,
    required this.title,
    required this.estimatedDelivery,
    required this.fee,
    required this.icon,
    required this.description,
    this.badge,
  });

  static List<DeliveryOption> getDeliveryOptions() {
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    final stdStart = now.add(const Duration(days: 5));
    final stdEnd = now.add(const Duration(days: 9));
    final stdRange =
        '${months[stdStart.month - 1]} ${stdStart.day}–${stdEnd.day}';

    final expStart = now.add(const Duration(days: 2));
    final expEnd = now.add(const Duration(days: 3));
    final expRange =
        '${months[expStart.month - 1]} ${expStart.day}–${expEnd.day}';

    final pickStart = now.add(const Duration(days: 4));
    final pickEnd = now.add(const Duration(days: 7));
    final pickRange =
        '${months[pickStart.month - 1]} ${pickStart.day}–${pickEnd.day}';

    final ecoStart = now.add(const Duration(days: 7));
    final ecoEnd = now.add(const Duration(days: 12));
    final ecoRange =
        '${months[ecoStart.month - 1]} ${ecoStart.day}–${ecoEnd.day}';

    return [
      DeliveryOption(
        id: 'standard',
        title: 'Standard Delivery',
        estimatedDelivery: 'Guaranteed by $stdRange',
        fee: 275,
        icon: Icons.local_shipping_outlined,
        description: 'Doorstep delivery via standard courier network',
        badge: 'POPULAR',
      ),
      DeliveryOption(
        id: 'express',
        title: 'Express Delivery',
        estimatedDelivery: 'Guaranteed by $expRange',
        fee: 450,
        icon: Icons.electric_bolt_outlined,
        description: 'Priority fast delivery to your address',
        badge: 'FASTEST',
      ),
      DeliveryOption(
        id: 'pickup',
        title: 'Collection Point / Pickup Station',
        estimatedDelivery: 'Available for pickup by $pickRange',
        fee: 150,
        icon: Icons.storefront_outlined,
        description: 'Self pick-up at nearest SoftStore service station',
        badge: 'SAVE PKR 125',
      ),
      DeliveryOption(
        id: 'economy',
        title: 'Economy Saver',
        estimatedDelivery: 'Estimated by $ecoRange',
        fee: 180,
        icon: Icons.savings_outlined,
        description: 'Economical delivery for non-urgent parcels',
        badge: 'SAVER',
      ),
    ];
  }
}

class _DeliveryOptionPickerSheet extends StatefulWidget {
  final List<DeliveryOption> options;
  final DeliveryOption? initialSelected;
  final ValueChanged<DeliveryOption> onSelect;

  const _DeliveryOptionPickerSheet({
    required this.options,
    this.initialSelected,
    required this.onSelect,
  });

  @override
  State<_DeliveryOptionPickerSheet> createState() =>
      _DeliveryOptionPickerSheetState();
}

class _DeliveryOptionPickerSheetState
    extends State<_DeliveryOptionPickerSheet> {
  late DeliveryOption? _current;

  @override
  void initState() {
    super.initState();
    _current = widget.initialSelected;
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF7F7F7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              border: Border(bottom: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            child: Column(
              children: [
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
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Select Delivery Method',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF222222),
                      ),
                    ),
                    InkWell(
                      onTap: () => Navigator.of(context).pop(),
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.close,
                            color: Color(0xFF777777), size: 22),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Options List
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: widget.options.map((opt) {
                  final isSelected = _current?.id == opt.id;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Material(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      child: InkWell(
                        onTap: () {
                          setState(() => _current = opt);
                        },
                        borderRadius: BorderRadius.circular(10),
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : const Color(0xFFE0E0E0),
                              width: isSelected ? 1.8 : 1,
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 2),
                                child: Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  color: isSelected
                                      ? AppColors.primary
                                      : const Color(0xFF999999),
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Flexible(
                                          child: Text(
                                            opt.title,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 13,
                                              color: Color(0xFF222222),
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        if (opt.badge != null) ...[
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 5, vertical: 1.5),
                                            decoration: BoxDecoration(
                                              color: AppColors.primary
                                                  .withValues(alpha: 0.12),
                                              borderRadius:
                                                  BorderRadius.circular(3),
                                            ),
                                            child: Text(
                                              opt.badge!,
                                              style: const TextStyle(
                                                color: AppColors.primary,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      opt.estimatedDelivery,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF444444),
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      opt.description,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF888888),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'PKR ${opt.fee}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13,
                                  color: isSelected
                                      ? AppColors.primary
                                      : const Color(0xFF222222),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          // Bottom confirm button
          Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Color(0xFFEEEEEE))),
            ),
            padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPadding + 12),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _current == null
                    ? null
                    : () {
                        widget.onSelect(_current!);
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Delivery method selected: ${_current!.title}'),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      },
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
                  'Confirm Delivery Method',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shared Order Placement Processor ───────────────────────────────────────

Future<void> _processOrderPlacement({
  required BuildContext context,
  required CartState cartState,
  required int shippingFee,
  required String paymentMethod,
  String customerName = 'Muhammad Khalid',
  String customerPhone = '03408014187',
  String customerAddress = 'House 12, Street 4, Model Town, Lahore',
  String customerCity = 'Lahore',
}) async {
  final now = DateTime.now();
  // Standard web invoice format: INV-YYYYMMDD-XXXXX
  final rand5 = 10000 + (now.microsecondsSinceEpoch % 90000);
  final invoice =
      'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$rand5';

  final orderItems = cartState.items.map((i) {
    return OrderItem(
      id: i.id,
      name: i.name,
      quantity: i.quantity,
      unitPrice: i.price.toDouble(),
      sku: 'SKU-${i.id}',
    );
  }).toList();

  final repoItems = cartState.items.map((i) {
    final numId = i.productId;
    return cart_models.CartItem(
      uuid: i.id,
      productId: numId,
      productName: i.name,
      quantity: i.quantity,
      unitPriceSnapshot: i.price.toDouble(),
    );
  }).toList();

  final orderRequest = cart_models.OrderRequest(
    items: repoItems,
    customerName: customerName,
    customerAddress: customerAddress,
    customerPhone: customerPhone,
    customerEmail: 'buyer@softstore.pk',
  );

  String finalInvoice = invoice;

  try {
    final result =
        await cart_repo.CartRepository.instance.placeOrder(orderRequest);
    if (result.success &&
        result.invoiceNumber != null &&
        result.invoiceNumber!.isNotEmpty) {
      finalInvoice = result.invoiceNumber!;
    }
  } catch (_) {
    // Graceful offline fallback with exact web invoice format
  }

  final placedOrder = Order(
    id: finalInvoice,
    referenceNumber: finalInvoice,
    placedAt: now,
    status: OrderStatus.pending,
    items: orderItems,
    deliveryAddress: OrderAddress(
      name: customerName,
      phone: customerPhone,
      addressLine: customerAddress,
      city: customerCity,
    ),
    subtotal: cartState.totalPrice.toDouble(),
    deliveryFee: shippingFee.toDouble(),
    discount: 0,
    storeName: 'SoftStore Official Partner',
    storeCity: customerCity,
    estimatedDelivery: 'Expected in 2-3 business days',
    statusHistory: [
      OrderStatusEvent(
        status: OrderStatus.pending,
        timestamp: now,
        note: 'Order placed via $paymentMethod by customer',
      ),
    ],
  );

  await OrderRepository.instance.saveLocalOrder(placedOrder);

  if (context.mounted) {
    context.read<CartCubit>().clearCart();

    final firstItem = orderItems.isNotEmpty ? orderItems.first : null;

    Navigator.of(context, rootNavigator: true)
        .popUntil((route) => route.isFirst);

    context.go(
      '/order-confirmation/$finalInvoice',
      extra: {
        'invoiceNumber': finalInvoice,
        'subtotal': cartState.totalPrice.toInt(),
        'delivery': shippingFee,
        'productName': firstItem?.name ?? 'Marketplace Item',
        'productQty': firstItem?.quantity ?? 1,
        'productPrice': firstItem?.unitPrice.toInt() ?? cartState.totalPrice.toInt(),
        'iconCodePoint': Icons.inventory_2_outlined.codePoint,
      },
    );
  }
}

// ── Payment method sheet ───────────────────────────────────────────────────

class _PaymentMethodSheet extends StatefulWidget {
  final int shippingFee;
  final String deliveryMethodTitle;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String customerCity;

  const _PaymentMethodSheet({
    this.shippingFee = 275,
    this.deliveryMethodTitle = 'Standard Delivery',
    this.customerName = 'Muhammad Khalid',
    this.customerPhone = '03408014187',
    this.customerAddress = 'House 12, Street 4, Model Town, Lahore',
    this.customerCity = 'Lahore',
  });

  @override
  State<_PaymentMethodSheet> createState() => _PaymentMethodSheetState();
}

class _PaymentMethodSheetState extends State<_PaymentMethodSheet> {
  String _selected = 'card';

  static const int _otherFees = 10;
  static const int _platformFee = 10;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final total =
            state.totalPrice + widget.shippingFee + _otherFees + _platformFee;

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

                      // ── Payment methods ────────────────────
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
                                    child: _CardDetailSheet(
                                      shippingFee: widget.shippingFee,
                                    ),
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
                                    child: _CodDetailSheet(
                                      shippingFee: widget.shippingFee,
                                    ),
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
                          if (_selected == 'cod') {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => BlocProvider.value(
                                value: context.read<CartCubit>(),
                                child: _CodDetailSheet(
                                  shippingFee: widget.shippingFee,
                                  customerName: widget.customerName,
                                  customerPhone: widget.customerPhone,
                                  customerAddress: widget.customerAddress,
                                  customerCity: widget.customerCity,
                                ),
                              ),
                            );
                            return;
                          }
                          if (_selected == 'card') {
                            showModalBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              backgroundColor: Colors.transparent,
                              builder: (_) => BlocProvider.value(
                                value: context.read<CartCubit>(),
                                child: _CardDetailSheet(
                                  shippingFee: widget.shippingFee,
                                  customerName: widget.customerName,
                                  customerPhone: widget.customerPhone,
                                  customerAddress: widget.customerAddress,
                                  customerCity: widget.customerCity,
                                ),
                              ),
                            );
                            return;
                          }

                          _processOrderPlacement(
                            context: context,
                            cartState: state,
                            shippingFee: widget.shippingFee,
                            paymentMethod: _selected == 'jazzcash'
                                ? 'JazzCash'
                                : _selected == 'easypaisa'
                                    ? 'EasyPaisa'
                                    : 'Bank Transfer',
                            customerName: widget.customerName,
                            customerPhone: widget.customerPhone,
                            customerAddress: widget.customerAddress,
                            customerCity: widget.customerCity,
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
}

// ── Cash on Delivery detail sheet ─────────────────────────────────────────

class _CodDetailSheet extends StatefulWidget {
  final int shippingFee;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String customerCity;

  const _CodDetailSheet({
    this.shippingFee = 275,
    this.customerName = 'Muhammad Khalid',
    this.customerPhone = '03408014187',
    this.customerAddress = 'House 12, Street 4, Model Town, Lahore',
    this.customerCity = 'Lahore',
  });

  @override
  State<_CodDetailSheet> createState() => _CodDetailSheetState();
}

class _CodDetailSheetState extends State<_CodDetailSheet> {
  static const int _otherFees = 10;
  static const int _platformFee = 10;

  bool _isProcessing = false;

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
            state.totalPrice + widget.shippingFee + _otherFees + _platformFee;
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
                        onPressed: _isProcessing
                            ? null
                            : () async {
                                setState(() => _isProcessing = true);
                                try {
                                  await _processOrderPlacement(
                                    context: context,
                                    cartState: state,
                                    shippingFee: widget.shippingFee,
                                    paymentMethod: 'Cash on Delivery',
                                    customerName: widget.customerName,
                                    customerPhone: widget.customerPhone,
                                    customerAddress: widget.customerAddress,
                                    customerCity: widget.customerCity,
                                  );
                                } catch (_) {
                                  if (mounted) {
                                    setState(() => _isProcessing = false);
                                  }
                                }
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
                        child: _isProcessing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text('Confirm Order',
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
  final int shippingFee;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String customerCity;

  const _CardDetailSheet({
    this.shippingFee = 275,
    this.customerName = 'Muhammad Khalid',
    this.customerPhone = '03408014187',
    this.customerAddress = 'House 12, Street 4, Model Town, Lahore',
    this.customerCity = 'Lahore',
  });

  @override
  State<_CardDetailSheet> createState() => _CardDetailSheetState();
}

class _CardDetailSheetState extends State<_CardDetailSheet> {
  static const int _otherFees = 10;
  static const int _platformFee = 10;

  bool _isProcessing = false;

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
            state.totalPrice + widget.shippingFee + _otherFees + _platformFee;

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
                        onPressed: _isProcessing
                            ? null
                            : () async {
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
                                setState(() => _isProcessing = true);
                                try {
                                  await _processOrderPlacement(
                                    context: context,
                                    cartState: state,
                                    shippingFee: widget.shippingFee,
                                    paymentMethod: 'Credit/Debit Card',
                                    customerName: widget.customerName,
                                    customerPhone: widget.customerPhone,
                                    customerAddress: widget.customerAddress,
                                    customerCity: widget.customerCity,
                                  );
                                } catch (_) {
                                  if (mounted) {
                                    setState(() => _isProcessing = false);
                                  }
                                }
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
                        child: _isProcessing
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text('Pay Now',
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
