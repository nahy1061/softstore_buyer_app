import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme/app_theme.dart';
import '../../core/storage/cart_store.dart';
import '../../core/storage/session_store.dart';
import '../../core/constants/app_constants.dart';
import '../../core/models/cart_item.dart';
import '../checkout/checkout_screen.dart';
import '../auth/auth_flow_view.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartStore>();
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(cart.count > 0 ? 'Cart (${cart.count})' : 'Cart'),
        actions: [
          if (cart.items.isNotEmpty)
            TextButton(
              onPressed: () => _confirmClear(context, cart),
              child: const Text('Clear', style: TextStyle(color: AppColors.danger)),
            ),
        ],
      ),
      body: cart.items.isEmpty ? _EmptyCart() : _CartBody(cart: cart),
      bottomNavigationBar: cart.items.isNotEmpty ? _CheckoutBar(cart: cart) : null,
    );
  }

  void _confirmClear(BuildContext context, CartStore cart) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () { cart.clear(); Navigator.pop(context); },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state
// ---------------------------------------------------------------------------

class _EmptyCart extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 100, height: 100,
          decoration: const BoxDecoration(color: Color(0xFFF0F0F0), shape: BoxShape.circle),
          child: const Icon(Icons.shopping_cart_outlined, size: 50, color: Colors.grey),
        ),
        const SizedBox(height: 20),
        const Text('Your cart is empty', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        const Text('Add items from the marketplace to get started.', style: TextStyle(color: Colors.grey), textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Browse Products'),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Main cart body
// ---------------------------------------------------------------------------

class _CartBody extends StatelessWidget {
  final CartStore cart;
  const _CartBody({required this.cart});

  @override
  Widget build(BuildContext context) {
    final subtotal = cart.subtotal;
    final freeDelivery = subtotal >= AppConstants.freeDeliveryThreshold;

    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        // Free delivery banner
        _DeliveryBanner(subtotal: subtotal, freeDelivery: freeDelivery),
        const SizedBox(height: 12),

        // Cart items
        ...cart.items.map((item) => _CartItemTile(item: item, cart: cart)),

        // Saved for later
        if (cart.savedItems.isNotEmpty) ...[
          const SizedBox(height: 20),
          const Text('Saved for Later', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...cart.savedItems.map((item) => _SavedItemTile(item: item, cart: cart)),
        ],

        // Price summary card
        const SizedBox(height: 16),
        _PriceSummaryCard(cart: cart),
        const SizedBox(height: 90),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Free delivery banner
// ---------------------------------------------------------------------------

class _DeliveryBanner extends StatelessWidget {
  final double subtotal;
  final bool freeDelivery;
  const _DeliveryBanner({required this.subtotal, required this.freeDelivery});

  @override
  Widget build(BuildContext context) {
    final msg = freeDelivery
        ? 'You qualify for free delivery!'
        : 'Add PKR ${(AppConstants.freeDeliveryThreshold - subtotal).toInt()} more for free delivery';
    final color = freeDelivery ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Row(children: [
        Icon(freeDelivery ? Icons.local_shipping : Icons.local_shipping_outlined, color: color, size: 20),
        const SizedBox(width: 10),
        Expanded(
          child: Text(msg, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: color)),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Cart item tile
// ---------------------------------------------------------------------------

class _CartItemTile extends StatelessWidget {
  final CartItem item;
  final CartStore cart;
  const _CartItemTile({required this.item, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Thumbnail
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: item.imageUrl != null
              ? CachedNetworkImage(imageUrl: item.imageUrl!, width: 76, height: 76, fit: BoxFit.cover)
              : Container(
                  width: 76, height: 76,
                  color: const Color(0xFFF0F0F0),
                  child: const Icon(Icons.image_outlined, color: Colors.grey),
                ),
        ),
        const SizedBox(width: 12),
        // Info
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(item.productName, maxLines: 2, overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            if (item.variantLabel != null) ...[
              const SizedBox(height: 2),
              Text(item.variantLabel!, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            ],
            const SizedBox(height: 6),
            RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: 'PKR ${item.unitPriceSnapshot.toInt()}',
                    style: const TextStyle(color: AppColors.brandOrange, fontWeight: FontWeight.w700, fontSize: 13),
                  ),
                  TextSpan(
                    text: ' × ${item.quantity}',
                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                  ),
                  TextSpan(
                    text: ' = PKR ${item.lineTotal.toInt()}',
                    style: const TextStyle(color: AppColors.brandOrange, fontWeight: FontWeight.w800, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Row(children: [
              // Quantity controls
              _QtyButton(icon: Icons.remove, onTap: () {
                if (item.quantity > 1) cart.updateQuantity(item.id, item.quantity - 1);
              }),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
              _QtyButton(icon: Icons.add, onTap: () => cart.updateQuantity(item.id, item.quantity + 1)),
              const SizedBox(width: 12),
              // Save for later
              GestureDetector(
                onTap: () => cart.saveForLater(item.id),
                child: const Text('Save', style: TextStyle(color: AppColors.brandOrange, fontSize: 12, fontWeight: FontWeight.w500)),
              ),
              const SizedBox(width: 12),
              // Remove
              GestureDetector(
                onTap: () => cart.removeItem(item.id),
                child: const Text('Remove', style: TextStyle(color: AppColors.danger, fontSize: 12, fontWeight: FontWeight.w500)),
              ),
            ]),
          ]),
        ),
      ]),
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
        width: 30, height: 30,
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(icon, size: 16, color: AppColors.brandOrange),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Saved for later tile
// ---------------------------------------------------------------------------

class _SavedItemTile extends StatelessWidget {
  final CartItem item;
  final CartStore cart;
  const _SavedItemTile({required this.item, required this.cart});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Row(children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: item.imageUrl != null
              ? CachedNetworkImage(imageUrl: item.imageUrl!, width: 56, height: 56, fit: BoxFit.cover)
              : Container(width: 56, height: 56, color: const Color(0xFFF0F0F0),
                  child: const Icon(Icons.image_outlined, color: Colors.grey, size: 24)),
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(item.productName, maxLines: 1, overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 3),
          Text('PKR ${item.unitPriceSnapshot.toInt()}', style: const TextStyle(color: AppColors.brandOrange, fontWeight: FontWeight.w700)),
        ])),
        TextButton(
          onPressed: () => cart.moveToCart(item.id),
          child: const Text('Move to Cart', style: TextStyle(color: AppColors.brandOrange, fontSize: 12)),
        ),
        IconButton(
          onPressed: () {
            final saved = cart.savedItems;
            final idx = saved.indexWhere((i) => i.id == item.id);
            if (idx >= 0) {
              // Remove from saved list directly via move then immediate remove workaround.
              cart.moveToCart(item.id);
              cart.removeItem(item.id);
            }
          },
          icon: const Icon(Icons.close, size: 18, color: Colors.grey),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Price summary card
// ---------------------------------------------------------------------------

class _PriceSummaryCard extends StatelessWidget {
  final CartStore cart;
  const _PriceSummaryCard({required this.cart});

  @override
  Widget build(BuildContext context) {
    final subtotal = cart.subtotal;
    final freeDelivery = subtotal >= AppConstants.freeDeliveryThreshold;
    const deliveryFee = 200.0; // Standard estimate
    final delivery = freeDelivery ? 0.0 : deliveryFee;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Price Summary', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        _PriceRow(label: 'Subtotal (${cart.count} items)', value: 'PKR ${subtotal.toInt()}'),
        const SizedBox(height: 8),
        _PriceRow(
          label: 'Delivery',
          value: freeDelivery ? 'FREE' : 'PKR ${delivery.toInt()}',
          valueColor: freeDelivery ? AppColors.success : null,
        ),
        const Divider(height: 24),
        _PriceRow(
          label: 'Total',
          value: 'PKR ${(subtotal + delivery).toInt()}',
          bold: true,
        ),
        if (!freeDelivery) ...[
          const SizedBox(height: 8),
          Text(
            'Add PKR ${(AppConstants.freeDeliveryThreshold - subtotal).toInt()} more for free delivery',
            style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 12),
          ),
        ],
      ]),
    );
  }
}

class _PriceRow extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _PriceRow({required this.label, required this.value, this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final style = TextStyle(
      fontSize: bold ? 15 : 14,
      fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
    );
    return Row(children: [
      Expanded(child: Text(label, style: style)),
      Text(
        value,
        style: style.copyWith(color: valueColor ?? (bold ? AppColors.brandOrange : AppColors.textPrimaryLight)),
      ),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Checkout bottom bar
// ---------------------------------------------------------------------------

class _CheckoutBar extends StatelessWidget {
  final CartStore cart;
  const _CheckoutBar({required this.cart});

  @override
  Widget build(BuildContext context) {
    final subtotal = cart.subtotal;
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 14, offset: const Offset(0, -4))],
      ),
      child: Row(children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Subtotal', style: TextStyle(color: Colors.grey, fontSize: 12)),
          Text(
            'PKR ${subtotal.toInt()}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.brandOrange),
          ),
        ]),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: () => _proceed(context),
            style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
            child: const Text('Proceed to Checkout', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Future<void> _proceed(BuildContext context) async {
    final session = context.read<SessionStore>();
    if (!session.isSignedIn) {
      final ok = await AuthFlowView.showAuthSheet(
        context,
        contextMessage: 'Sign in to place your order',
      );
      if (!ok || !context.mounted) return;
    }
    if (!context.mounted) return;
    Navigator.push(context, MaterialPageRoute(builder: (_) => const CheckoutScreen()));
  }
}
