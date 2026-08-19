import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/errors/failures.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../../auth/repository/auth_repository.dart';
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
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _phoneCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _couponCtrl = TextEditingController();
  final TextEditingController _notesCtrl = TextEditingController();

  bool _isSubmitting = false;
  bool _isValidatingCoupon = false;
  double _deliveryFee = 200.0;
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
      if (user.email.isNotEmpty) _emailCtrl.text = user.email;
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
    String userEmail = _emailCtrl.text.trim();
    if (userEmail.isEmpty && authState is AuthAuthenticated) {
      userEmail = authState.user.email.trim();
      _emailCtrl.text = userEmail;
    }
    if (userEmail.isEmpty) {
      userEmail = 'buyer@softstore.pk';
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
      if (!result.success) {
        final msg = result.message?.toLowerCase() ?? '';
        if (result.message == 'email_unverified' ||
            msg.contains('verify your email') ||
            msg.contains('unverified') ||
            msg.contains('email verification')) {
          await _promptEmailVerification(userEmail);
          return;
        }
      }
      if (result.success && result.invoiceNumber != null && result.invoiceNumber!.isNotEmpty) {
        invoice = result.invoiceNumber!;
      }
    } on AuthFailure catch (e) {
      if (!mounted) return;
      final msg = e.message.toLowerCase();
      if (e.message == 'email_unverified' ||
          msg.contains('verify your email') ||
          msg.contains('unverified') ||
          msg.contains('email verification')) {
        await _promptEmailVerification(userEmail);
        return;
      }
    } catch (_) {
      // Offline fallback with web invoice format
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

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
      subtotal: cartState.items.fold(0.0, (sum, i) => sum + (i.price * i.quantity)),
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
      context.read<CartCubit>().clearCart();
      context.go('/order-confirmation/$invoice');
    }
  }

  Future<void> _promptEmailVerification(String email) async {
    final verified = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _EmailVerificationOtpDialog(
        initialEmail: email,
        onEmailUpdated: (newEmail) {
          _emailCtrl.text = newEmail;
        },
      ),
    );

    if (verified == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verified successfully! Placing your order...'),
          backgroundColor: Color(0xFF15803D),
        ),
      );
      // Retry placing order with verified session
      await _submitOrder();
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
                          hintText: 'ali',
                          prefixIcon: Icons.person,
                        ),
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Name is required'
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
                          if (digits.length < 11) {
                            return 'Phone number must have at least 11 digits';
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

class _EmailVerificationOtpDialog extends StatefulWidget {
  final String initialEmail;
  final ValueChanged<String> onEmailUpdated;

  const _EmailVerificationOtpDialog({
    required this.initialEmail,
    required this.onEmailUpdated,
  });

  @override
  State<_EmailVerificationOtpDialog> createState() =>
      _EmailVerificationOtpDialogState();
}

class _EmailVerificationOtpDialogState
    extends State<_EmailVerificationOtpDialog> {
  final AuthRepository _authRepo = AuthRepository.instance;
  late TextEditingController _emailCtrl;
  late List<TextEditingController> _digitCtrls;
  late List<FocusNode> _focusNodes;

  Timer? _countdownTimer;
  int _secondsRemaining = 60;
  bool _isSendingCode = false;
  bool _isVerifying = false;
  String? _errorMessage;
  String? _successMessage;
  bool _isEditingEmail = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail);
    _digitCtrls = List.generate(6, (_) => TextEditingController());
    _focusNodes = List.generate(6, (_) => FocusNode());

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final email = _emailCtrl.text.trim();
      if (email.contains('@') && email != 'buyer@softstore.pk') {
        _sendCode();
      } else {
        setState(() {
          _isEditingEmail = true;
          _errorMessage =
              'Please enter your email to receive the 6-digit verification code.';
        });
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _emailCtrl.dispose();
    for (final c in _digitCtrls) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    setState(() => _secondsRemaining = 60);
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_secondsRemaining > 1) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _secondsRemaining = 0);
        timer.cancel();
      }
    });
  }

  Future<void> _sendCode() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() {
        _errorMessage = 'Please enter a valid email address';
      });
      return;
    }

    setState(() {
      _isSendingCode = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await _authRepo.sendVerificationCode(email);
      widget.onEmailUpdated(email);
      if (!mounted) return;
      setState(() {
        _isEditingEmail = false;
        _successMessage = 'Verification code sent to $email';
        _isSendingCode = false;
      });
      _startTimer();
      _focusNodes[0].requestFocus();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e is AuthFailure ? e.message : e.toString();
        _isSendingCode = false;
      });
    }
  }

  Future<void> _verifyOtp() async {
    final code = _digitCtrls.map((c) => c.text.trim()).join();
    if (code.length < 6) {
      setState(() {
        _errorMessage = 'Please enter the complete 6-digit code';
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final success = await _authRepo.verifyCode(code);
      if (!mounted) return;
      if (success) {
        Navigator.of(context).pop(true);
      } else {
        setState(() {
          _errorMessage =
              'Invalid or expired verification code. Please try again.';
          _isVerifying = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e is AuthFailure ? e.message : e.toString();
        _isVerifying = false;
      });
    }
  }

  void _onDigitChanged(int index, String value) {
    if (value.length > 1) {
      final clean = value.replaceAll(RegExp(r'\D'), '');
      if (clean.isNotEmpty) {
        for (int i = 0; i < 6 && i < clean.length; i++) {
          _digitCtrls[i].text = clean[i];
        }
        final nextIndex = clean.length < 6 ? clean.length : 5;
        _focusNodes[nextIndex].requestFocus();
        if (clean.length >= 6) {
          _verifyOtp();
        }
        return;
      }
    }

    if (value.isNotEmpty) {
      if (index < 5) {
        _focusNodes[index + 1].requestFocus();
      } else {
        _focusNodes[index].unfocus();
        final fullCode = _digitCtrls.map((c) => c.text.trim()).join();
        if (fullCode.length == 6) {
          _verifyOtp();
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Top Badge Icon
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5722).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.mark_email_unread_outlined,
                  color: Color(0xFFFF5722),
                  size: 30,
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            const Text(
              'Verify Your Email',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),

            // Subtitle
            Text(
              _isEditingEmail
                  ? 'Enter the email address to receive your 6-digit verification code.'
                  : 'Please enter the 6-digit verification code sent to:',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
                height: 1.4,
              ),
            ),

            // Email Display / Edit Field
            if (!_isEditingEmail) ...[
              Container(
                margin: const EdgeInsets.symmetric(vertical: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.email_outlined,
                        size: 16, color: Color(0xFF4B5563)),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _emailCtrl.text.trim(),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1F2937),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () {
                        setState(() => _isEditingEmail = true);
                      },
                      child: const Icon(Icons.edit_outlined,
                          size: 16, color: Color(0xFFFF5722)),
                    ),
                  ],
                ),
              ),
            ] else ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Enter your email',
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 12),
                          filled: true,
                          fillColor: const Color(0xFFF3F4F6),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide:
                                const BorderSide(color: Color(0xFFE5E7EB)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                                color: Color(0xFFFF5722), width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isSendingCode ? null : _sendCode,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5722),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                      child: _isSendingCode
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text(
                              'Send Code',
                              style: TextStyle(
                                  fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                    ),
                  ],
                ),
              ),
            ],

            // Success feedback message
            if (_successMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCFCE7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: Color(0xFF15803D), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF15803D),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Error feedback message
            if (_errorMessage != null)
              Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFEE2E2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: Color(0xFFDC2626), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 8),

            // 6-Digit OTP Input Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(6, (i) {
                return SizedBox(
                  width: 44,
                  height: 52,
                  child: KeyboardListener(
                    focusNode: FocusNode(),
                    onKeyEvent: (event) {
                      if (event is KeyDownEvent &&
                          event.logicalKey == LogicalKeyboardKey.backspace) {
                        if (_digitCtrls[i].text.isEmpty && i > 0) {
                          _focusNodes[i - 1].requestFocus();
                        }
                      }
                    },
                    child: TextFormField(
                      controller: _digitCtrls[i],
                      focusNode: _focusNodes[i],
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      maxLength: 1,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        contentPadding: EdgeInsets.zero,
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide:
                              const BorderSide(color: Color(0xFFE5E7EB)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                              color: Color(0xFFFF5722), width: 1.8),
                        ),
                      ),
                      onChanged: (val) => _onDigitChanged(i, val),
                    ),
                  ),
                );
              }),
            ),

            // Resend timer row
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "Didn't receive the code? ",
                    style: TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
                  ),
                  if (_secondsRemaining > 0)
                    Text(
                      "Resend in ${_secondsRemaining}s",
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF9CA3AF),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: _isSendingCode ? null : _sendCode,
                      child: const Text(
                        "Resend Code",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF5722),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 6),

            // Verify Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (_isVerifying || _isSendingCode) ? null : _verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5722),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isVerifying
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Verify & Place Order',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 8),

            // Cancel Button
            SizedBox(
              width: double.infinity,
              height: 40,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6B7280),
                ),
                child: const Text(
                  'Cancel',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
