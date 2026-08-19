import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../../cart/cubit/cart_cubit.dart';
import '../../cart/models/cart_models.dart';
import '../../cart/repository/cart_repository.dart';
import '../../orders/models/order_model.dart' as order_models;
import '../../orders/repository/order_repository.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _repo = CartRepository.instance;
  final _orderRepo = OrderRepository.instance;

  final TextEditingController _nameCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _couponCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  bool _isSubmitting = false;
  bool _isValidatingCoupon = false;
  double _deliveryFee = 300.0;
  double _discountAmount = 0.0;
  String? _couponMessage;
  bool _couponValid = false;

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
      if (user.fullName.isNotEmpty) _nameCtrl.text = user.fullName;
      if (user.phone != null && user.phone!.isNotEmpty) {
        _phoneCtrl.text = user.phone!;
      }
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
        _deliveryFee = quote.deliveryFee > 0 ? quote.deliveryFee : 300.0;
      });
    } catch (_) {
      // Keep default delivery fee
    }
  }

  Future<void> _applyCoupon() async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;

    setState(() => _isValidatingCoupon = true);

    final cartState = context.read<CartCubit>().state;
    final subtotal =
        cartState.items.fold(0.0, (sum, i) => sum + (i.price * i.quantity));
    try {
      final res = await _repo.validateCoupon(
        code: code,
        subtotal: subtotal,
      );
      if (!mounted) return;
      setState(() {
        _couponValid = res.valid;
        if (res.valid) {
          _discountAmount = res.discountAmount;
          _couponMessage = 'Coupon applied successfully!';
        } else {
          _discountAmount = 0;
          _couponMessage =
              res.message.isNotEmpty ? res.message : 'Invalid coupon';
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _couponValid = false;
        _couponMessage = 'Coupon validation failed';
      });
    } finally {
      if (mounted) setState(() => _isValidatingCoupon = false);
    }
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final cartState = context.read<CartCubit>().state;
    if (cartState.items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty. Please add items first.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final repoItems = cartState.items.map((i) {
      final numericId = i.productId;
      return CartItem(
        uuid: i.id,
        productId: numericId,
        productName: i.name,
        quantity: i.quantity,
        unitPriceSnapshot: i.price.toDouble(),
      );
    }).toList();

    final authState = context.read<AuthCubit>().state;
    String userEmail = 'buyer@softstore.pk';
    if (authState is AuthAuthenticated && authState.user.email.isNotEmpty) {
      userEmail = authState.user.email.trim();
    }

    final request = OrderRequest(
      items: repoItems,
      customerName: _nameCtrl.text.trim(),
      customerAddress: _addressCtrl.text.trim(),
      customerPhone: _phoneCtrl.text.trim(),
      customerEmail: userEmail,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      couponCode:
          _couponCtrl.text.trim().isEmpty ? null : _couponCtrl.text.trim(),
    );

    final now = DateTime.now();
    final rand5 = 10000 + (now.microsecondsSinceEpoch % 90000);
    final fallbackInvoice =
        'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$rand5';
    String invoice = fallbackInvoice;

    try {
      final result = await _repo.placeOrder(request);
      if (result.success &&
          result.invoiceNumber != null &&
          result.invoiceNumber!.isNotEmpty) {
        invoice = result.invoiceNumber!;
      }
    } catch (_) {
      // Graceful local fallback
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

    final firstItem =
        cartState.items.isNotEmpty ? cartState.items.first : null;
    final subtotal =
        cartState.items.fold(0.0, (sum, i) => sum + (i.price * i.quantity));

    final placedOrder = order_models.Order(
      id: invoice,
      referenceNumber: invoice,
      placedAt: now,
      status: order_models.OrderStatus.pending,
      items: cartState.items
          .map((i) => order_models.OrderItem(
                id: i.id,
                name: i.name,
                quantity: i.quantity,
                unitPrice: i.price.toDouble(),
                sku: 'SKU-${i.id}',
              ))
          .toList(),
      deliveryAddress: order_models.OrderAddress(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        addressLine: _addressCtrl.text.trim(),
        city: 'Lahore',
      ),
      subtotal: subtotal,
      deliveryFee: _deliveryFee,
      discount: _discountAmount,
      storeName: 'SoftStore Official Partner',
      estimatedDelivery: 'Expected in 2-3 business days',
      statusHistory: [
        order_models.OrderStatusEvent(
          status: order_models.OrderStatus.pending,
          timestamp: now,
          note: 'Order placed by customer',
        ),
      ],
    );

    await _orderRepo.saveLocalOrder(placedOrder);

    if (mounted) {
      final firstItem = cartState.items.isNotEmpty ? cartState.items.first : null;
      context.read<CartCubit>().clearCart();
      context.go(
        '/order-confirmation/$invoice',
        extra: {
          'invoiceNumber': invoice,
          'subtotal': subtotal.toInt(),
          'delivery': _deliveryFee.toInt(),
          'productName': firstItem?.name,
          'productQty': firstItem?.quantity,
          'productPrice': firstItem?.price.toInt(),
          'iconCodePoint': firstItem?.iconCodePoint,
        },
      );
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _couponCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cartState = context.watch<CartCubit>().state;
    final subtotal =
        cartState.items.fold(0.0, (sum, i) => sum + (i.price * i.quantity));
    final total = (subtotal + _deliveryFee - _discountAmount)
        .clamp(0.0, double.infinity);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFB),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Color(0xFF111827),
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 14, top: 8, bottom: 8),
          child: InkWell(
            onTap: () {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go(AppRoutes.cart);
              }
            },
            borderRadius: BorderRadius.circular(20),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF3F4F6),
                border: Border.all(color: const Color(0xFFE5E7EB), width: 0.8),
              ),
              child: const Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFF1F2937),
                size: 24,
              ),
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── 1. Delivery Address Card ──────────────────────────────────
              _buildCardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Color(0xFFFF5722),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.priority_high_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Delivery Address',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Full Name Field
                    _buildInputWrapper(
                      child: TextFormField(
                        controller: _nameCtrl,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _buildInputDecoration(
                          hintText: 'Full Name',
                          prefixIcon: Icons.person_outline,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Full Name is required'
                            : null,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Phone Field
                    _buildInputWrapper(
                      child: TextFormField(
                        controller: _phoneCtrl,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _buildInputDecoration(
                          hintText: 'Phone (03XXXXXXXXX)',
                          prefixIcon: Icons.phone_outlined,
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Phone number is required';
                          }
                          final digits = v.replaceAll(RegExp(r'\D'), '');
                          if (digits.length < 10) {
                            return 'Phone number must have at least 10 digits';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Full Address Field
                    _buildInputWrapper(
                      child: TextFormField(
                        controller: _addressCtrl,
                        maxLines: 2,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _buildInputDecoration(
                          hintText: 'Full delivery address',
                          prefixIcon: Icons.near_me_outlined,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Delivery address is required'
                            : null,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── 2. Order Notes Card ───────────────────────────────────────
              _buildCardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF5722),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.receipt_long_outlined,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Order Notes',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Optional',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Order notes multiline input
                    _buildInputWrapper(
                      child: TextFormField(
                        controller: _notesCtrl,
                        maxLines: 3,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _buildInputDecoration(
                          hintText:
                              'e.g. leave at gate, call before delivery...',
                          prefixIcon: Icons.chat_bubble_outline_rounded,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ── 3. Coupon Code Card ───────────────────────────────────────
              _buildCardContainer(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Transform.rotate(
                          angle: -0.2,
                          child: const Icon(
                            Icons.local_offer,
                            color: Color(0xFFFF5722),
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Coupon Code',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        const Spacer(),
                        const Text(
                          'Optional',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Coupon input field with Apply action
                    _buildInputWrapper(
                      child: TextFormField(
                        controller: _couponCtrl,
                        textInputAction: TextInputAction.done,
                        style: const TextStyle(
                          fontSize: 15,
                          color: Color(0xFF111827),
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _buildInputDecoration(
                          hintText: 'Enter coupon code',
                          prefixIcon: Icons.confirmation_number_outlined,
                          suffix: InkWell(
                            onTap:
                                _isValidatingCoupon ? null : _applyCoupon,
                            borderRadius: BorderRadius.circular(8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              child: _isValidatingCoupon
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Color(0xFFFF5722),
                                      ),
                                    )
                                  : const Text(
                                      'Apply',
                                      style: TextStyle(
                                        color: Color(0xFFFF5722),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (_couponMessage != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _couponMessage!,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: _couponValid
                              ? const Color(0xFF16A34A)
                              : const Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── 4. Order Summary Card ─────────────────────────────────────
              _buildCardContainer(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Subtotal',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        Text(
                          'Rs ${subtotal.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Delivery',
                          style: TextStyle(
                            fontSize: 15,
                            color: Color(0xFF4B5563),
                          ),
                        ),
                        Text(
                          'Rs ${_deliveryFee.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF111827),
                          ),
                        ),
                      ],
                    ),
                    if (_discountAmount > 0) ...[
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Discount',
                            style: TextStyle(
                              fontSize: 15,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                          Text(
                            '- Rs ${_discountAmount.toStringAsFixed(0)}',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        const Text(
                          'Total',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF111827),
                          ),
                        ),
                        Text(
                          'Rs ${total.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFFFF5722),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Green Cash on Delivery banner
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F5E9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.payments_outlined,
                            color: Color(0xFF15803D),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Pay Rs ${total.toStringAsFixed(0)} in cash on delivery',
                              style: const TextStyle(
                                color: Color(0xFF15803D),
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Submit Order Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _submitOrder,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF5722),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : const Text(
                                'Place Order',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }

  Widget _buildCardContainer({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEFEFEF), width: 1.2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildInputWrapper({required Widget child}) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 0.8),
      ),
      child: child,
    );
  }

  InputDecoration _buildInputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF9CA3AF),
        fontSize: 14,
        fontWeight: FontWeight.normal,
      ),
      prefixIcon: Icon(
        prefixIcon,
        color: const Color(0xFF6B7280),
        size: 20,
      ),
      suffixIcon: suffix != null
          ? Padding(
              padding: const EdgeInsets.only(right: 8),
              child: suffix,
            )
          : null,
      border: InputBorder.none,
      focusedBorder: InputBorder.none,
      enabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }
}
