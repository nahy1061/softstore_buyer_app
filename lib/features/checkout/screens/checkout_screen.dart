import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../../cart/cubit/cart_cubit.dart';
import '../../cart/models/cart_models.dart';
import '../../cart/repository/cart_repository.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final CartRepository _repo = CartRepository.instance;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _couponCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  bool _isSubmitting = false;
  double _deliveryFee = 150.0;
  double _discountAmount = 0.0;
  String? _couponMessage;

  @override
  void initState() {
    super.initState();
    _fillUserData();
    _fetchShippingQuote();
  }

  void _fillUserData() {
    final authState = context.read<AuthCubit>().state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      _nameCtrl.text = user.fullName;
      _emailCtrl.text = user.email;
      if (user.phone != null) _phoneCtrl.text = user.phone!;
    }
  }

  Future<void> _fetchShippingQuote() async {
    final cartState = context.read<CartCubit>().state;
    if (cartState.items.isEmpty) return;

    final repoItems = cartState.items.map((i) {
      final numericId = int.tryParse(i.id) ?? i.id.hashCode.abs();
      return CartItem(
        uuid: i.id,
        productId: numericId,
        productName: i.name,
        quantity: i.quantity,
        unitPriceSnapshot: i.price.toDouble(),
      );
    }).toList();

    try {
      final quote = await _repo.getShippingQuote(repoItems);
      if (!mounted) return;
      setState(() {
        _deliveryFee = quote.deliveryFee;
      });
    } catch (_) {
      // Fallback delivery fee
    }
  }

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;

    final cartState = context.read<CartCubit>().state;
    final subtotal = cartState.items.fold(0.0, (sum, i) => sum + (i.price * i.quantity));
    try {
      final res = await _repo.validateCoupon(
        code: code,
        subtotal: subtotal,
      );
      if (!mounted) return;
      setState(() {
        if (res.valid) {
          _discountAmount = res.discountAmount;
          _couponMessage = 'Coupon applied successfully!';
        } else {
          _discountAmount = 0;
          _couponMessage = res.message.isNotEmpty ? res.message : 'Invalid coupon';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _couponMessage = 'Coupon validation failed';
      });
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final cartState = context.read<CartCubit>().state;
    if (cartState.items.isEmpty) return;

    setState(() => _isSubmitting = true);

    final repoItems = cartState.items.map((i) {
      final numericId = int.tryParse(i.id) ?? i.id.hashCode.abs();
      return CartItem(
        uuid: i.id,
        productId: numericId,
        productName: i.name,
        quantity: i.quantity,
        unitPriceSnapshot: i.price.toDouble(),
      );
    }).toList();

    final request = OrderRequest(
      items: repoItems,
      customerName: _nameCtrl.text.trim(),
      customerAddress: _addressCtrl.text.trim(),
      customerPhone: _phoneCtrl.text.trim(),
      customerEmail: _emailCtrl.text.trim(),
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      couponCode: _couponCtrl.text.trim().isEmpty ? null : _couponCtrl.text.trim(),
    );

    try {
      final result = await _repo.placeOrder(request);
      if (!mounted) return;

      if (result.success) {
        context.read<CartCubit>().clearCart();
        final invoice = result.invoiceNumber ?? 'ORD-${DateTime.now().millisecondsSinceEpoch}';
        context.go('/order-confirmation/$invoice');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.message ?? 'Order placement failed.'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _couponCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = context.watch<CartCubit>().state;
    final subtotal = cartState.items.fold(0.0, (sum, i) => sum + (i.price * i.quantity));
    final total = (subtotal + _deliveryFee - _discountAmount).clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Checkout'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingLg,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Contact Details Header
              Text('Shipping Details', style: AppTypography.sectionHeading),
              const SizedBox(height: AppSpacing.md),

              // Full Name
              TextFormField(
                controller: _nameCtrl,
                decoration: const InputDecoration(
                  labelText: 'Full Name *',
                  prefixIcon: Icon(Icons.person_outline),
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Email
              TextFormField(
                controller: _emailCtrl,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email Address *',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email is required';
                  if (!v.contains('@')) return 'Enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.md),

              // Phone
              TextFormField(
                controller: _phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone Number *',
                  prefixIcon: Icon(Icons.phone_outlined),
                  hintText: '0300 0000000',
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Phone is required' : null,
              ),
              const SizedBox(height: AppSpacing.md),

              // Address
              TextFormField(
                controller: _addressCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Full Delivery Address *',
                  prefixIcon: Icon(Icons.location_on_outlined),
                  hintText: 'House/Street/City/Province',
                ),
                validator: (v) => v == null || v.trim().isEmpty ? 'Address is required' : null,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Payment Method Card
              Card(
                child: Padding(
                  padding: AppSpacing.paddingLg,
                  child: Row(
                    children: [
                      const Icon(Icons.payments_outlined, color: AppColors.primary, size: 28),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Cash on Delivery (COD)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'Pay upon delivery at your doorstep',
                              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.check_circle, color: AppColors.primary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // Order Summary
              Text('Order Summary', style: AppTypography.sectionHeading),
              const SizedBox(height: AppSpacing.sm),

              Card(
                child: Padding(
                  padding: AppSpacing.paddingLg,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal'),
                          Text('PKR ${subtotal.toStringAsFixed(0)}'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Delivery Fee'),
                          Text('PKR ${_deliveryFee.toStringAsFixed(0)}'),
                        ],
                      ),
                      if (_discountAmount > 0) ...[
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Discount', style: TextStyle(color: Colors.green)),
                            Text('- PKR ${_discountAmount.toStringAsFixed(0)}',
                                style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ],
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          Text(
                            'PKR ${total.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton(
                  onPressed: _isSubmitting ? null : _submitOrder,
                  child: _isSubmitting
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Place Cash on Delivery Order',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
            ],
          ),
        ),
      ),
    );
  }
}
