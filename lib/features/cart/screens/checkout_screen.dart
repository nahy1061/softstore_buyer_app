import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../core/network/softstore_api_client.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../cubit/cart_cubit.dart';
import '../cubit/cart_state.dart';
import '../models/cart_item.dart';
import '../services/checkout_service.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _nameCtrl = TextEditingController(text: 'ali');
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _couponCtrl = TextEditingController();

  final CheckoutService _checkoutService = CheckoutService();

  String _selectedPayment = 'cod';
  bool _couponApplied = false;
  String? _couponMessage;
  int _couponDiscount = 0;
  bool _couponLoading = false;
  bool _placingOrder = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl.addListener(_onFieldChanged);
    _phoneCtrl.addListener(_onFieldChanged);
    _emailCtrl.addListener(_onFieldChanged);
    _addressCtrl.addListener(_onFieldChanged);
  }

  void _onFieldChanged() => setState(() {});

  bool get _canContinue =>
      _nameCtrl.text.trim().isNotEmpty &&
      _phoneCtrl.text.trim().isNotEmpty &&
      _addressCtrl.text.trim().isNotEmpty &&
      _emailCtrl.text.trim().isNotEmpty;

  @override
  void dispose() {
    _nameCtrl.removeListener(_onFieldChanged);
    _phoneCtrl.removeListener(_onFieldChanged);
    _emailCtrl.removeListener(_onFieldChanged);
    _addressCtrl.removeListener(_onFieldChanged);
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _notesCtrl.dispose();
    _couponCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyCoupon(CartState cartState) async {
    final code = _couponCtrl.text.trim();
    if (code.isEmpty) return;

    setState(() {
      _couponLoading = true;
      _couponMessage = null;
      _couponApplied = false;
      _couponDiscount = 0;
    });

    try {
      final result = await _checkoutService.validateCoupon(
        code,
        cartState.subtotal,
        cartState.items,
      );
      setState(() {
        _couponApplied = result.valid;
        _couponDiscount = result.discountAmount;
        _couponMessage = result.message;
        _couponLoading = false;
      });
    } catch (e) {
      setState(() {
        _couponLoading = false;
        _couponMessage = SoftstoreApiClient.humanReadableError(e);
      });
    }
  }

  Future<void> _placeOrder(CartState cartState) async {
    if (!_canContinue || _placingOrder) return;

    setState(() => _placingOrder = true);

    try {
      final result = await _checkoutService.placeOrder(
        items: cartState.items,
        customerName: _nameCtrl.text.trim(),
        customerAddress: _addressCtrl.text.trim(),
        customerPhone: _phoneCtrl.text.trim(),
        customerEmail: _emailCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        couponCode: _couponApplied ? _couponCtrl.text.trim() : null,
      );

      if (!mounted) return;
      context.read<CartCubit>().clearCart();

      final firstItem =
          cartState.items.isNotEmpty ? cartState.items.first : null;
      context.go('/order-confirmation/${result.invoiceNumber}', extra: {
        'invoiceNumber': result.invoiceNumber,
        'subtotal': cartState.subtotal,
        'delivery': cartState.freeDelivery ? 0 : cartState.deliveryFee,
        'productName': firstItem?.productName,
        'productQty': firstItem?.quantity,
        'productPrice': firstItem?.unitPriceSnapshot,
        'iconCodePoint': firstItem?.iconCodePoint,
      });
    } on EmailUnverifiedException {
      if (!mounted) return;
      setState(() => _placingOrder = false);
      _showOtpSheet(cartState);
    } catch (e) {
      if (!mounted) return;
      setState(() => _placingOrder = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Order failed: ${SoftstoreApiClient.humanReadableError(e)}'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  void _showOtpSheet(CartState cartState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _OtpVerificationSheet(
        email: _emailCtrl.text.trim(),
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        onVerified: () {
          // Auto-retry place order after successful verification
          _placeOrder(cartState);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, state) {
        final effectiveDelivery = state.freeDelivery ? 0 : state.deliveryFee;
        final total = state.subtotal + effectiveDelivery - _couponDiscount;

        return Scaffold(
          backgroundColor: const Color(0xFFF5F5F5),
          body: Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 200),
                  child: Column(
                    children: [
                      _buildDeliveryAddressSection(),
                      const SizedBox(height: 14),
                      _buildEmailSection(),
                      const SizedBox(height: 14),
                      _buildOrderNotesSection(),
                      const SizedBox(height: 14),
                      _buildCouponCodeSection(state),
                      const SizedBox(height: 14),
                      _buildPaymentMethodSection(),
                      const SizedBox(height: 14),
                      _buildOrderSummarySection(state),
                    ],
                  ),
                ),
              ),
              _buildBottomSummaryBar(state, total),
            ],
          ),
          bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: Colors.white,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.chevron_left_rounded,
                      color: AppColors.textPrimary,
                      size: 24,
                    ),
                  ),
                ),
              ),
              Text(
                'Checkout',
                style: AppTypography.screenTitle.copyWith(fontSize: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader({
    required IconData icon,
    required String label,
    String? trailing,
  }) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: Colors.white, size: 18),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: AppTypography.sectionHeading.copyWith(fontSize: 15),
        ),
        if (trailing != null) ...[
          const Spacer(),
          Text(
            trailing,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textDisabled,
              fontSize: 12,
            ),
          ),
        ],
      ],
    );
  }

  Widget _inputField({
    required IconData icon,
    required String placeholder,
    TextEditingController? controller,
    int maxLines = 1,
    bool enabled = true,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        enabled: enabled,
        keyboardType: keyboardType,
        style: AppTypography.bodyMedium.copyWith(
          color: AppColors.textPrimary,
          fontSize: 14,
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: AppColors.textDisabled, size: 20),
          hintText: placeholder,
          hintStyle: AppTypography.bodyMedium.copyWith(
            color: AppColors.textDisabled,
            fontSize: 14,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }

  Widget _card({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDimensions.radiusLg,
        boxShadow: AppDimensions.cardShadow,
      ),
      child: child,
    );
  }

  // ── Section 1: Delivery Address ──────────────────────────────────────────
  Widget _buildDeliveryAddressSection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(icon: Icons.location_on_rounded, label: 'Delivery Address'),
          const SizedBox(height: 16),
          _inputField(icon: Icons.person_outline, placeholder: 'Name', controller: _nameCtrl),
          const SizedBox(height: 10),
          _inputField(
            icon: Icons.phone_outlined,
            placeholder: 'Phone (03XXXXXXXXX)',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 10),
          _inputField(icon: Icons.my_location, placeholder: 'Full delivery address', controller: _addressCtrl),
        ],
      ),
    );
  }

  // ── Section 2: Email (for OTP verification) ─────────────────────────────
  Widget _buildEmailSection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.email_outlined,
            label: 'Email Address',
            trailing: 'Required',
          ),
          const SizedBox(height: 8),
          Text(
            'We\'ll send a verification code to confirm your order.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          _inputField(
            icon: Icons.alternate_email,
            placeholder: 'you@example.com',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
          ),
        ],
      ),
    );
  }

  // ── Section 3: Order Notes ───────────────────────────────────────────────
  Widget _buildOrderNotesSection() {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.notes_rounded,
            label: 'Order Notes',
            trailing: 'Optional',
          ),
          const SizedBox(height: 16),
          _inputField(
            icon: Icons.edit_note_rounded,
            placeholder: 'e.g. leave at gate, call before delivery...',
            controller: _notesCtrl,
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  // ── Section 4: Coupon Code ───────────────────────────────────────────────
  Widget _buildCouponCodeSection(CartState state) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.local_offer_outlined,
            label: 'Coupon Code',
            trailing: 'Optional',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _inputField(
                  icon: Icons.confirmation_num_outlined,
                  placeholder: 'Enter coupon code',
                  controller: _couponCtrl,
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _couponLoading ? null : () => _applyCoupon(state),
                child: Container(
                  height: 50,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: _couponApplied
                        ? AppColors.success
                        : AppColors.primary,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Center(
                    child: _couponLoading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            _couponApplied ? 'Applied' : 'Apply',
                            style: AppTypography.buttonText.copyWith(
                              color: Colors.white,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
          if (_couponMessage != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _couponApplied ? Icons.check_circle_outline : Icons.info_outline,
                  color: _couponApplied ? AppColors.success : AppColors.textSecondary,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _couponMessage!,
                    style: AppTypography.bodySmall.copyWith(
                      color: _couponApplied ? AppColors.success : AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  // ── Section 5: Payment Method ────────────────────────────────────────────
  Widget _buildPaymentMethodSection() {
    final isSelected = _selectedPayment == 'cod';

    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            icon: Icons.credit_card_rounded,
            label: 'Payment Method',
          ),
          const SizedBox(height: 16),
          GestureDetector(
            onTap: () => setState(() => _selectedPayment = 'cod'),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFFF1E6)
                    : const Color(0xFFF8F8F8),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.divider,
                  width: isSelected ? 1.5 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : const Color(0xFFEEEEEE),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.payments_rounded,
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cash on Delivery',
                          style: AppTypography.labelLarge.copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Pay the rider when your order arrives\n— nothing to pay now',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            height: 1.3,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 24,
                      height: 24,
                      decoration: const BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_rounded, color: Colors.white, size: 16),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: AppColors.success, size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'No card details needed. Inspect your parcel before you pay.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textDisabled,
                    fontSize: 11,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Section 6: Order Summary ─────────────────────────────────────────────
  Widget _buildOrderSummarySection(CartState state) {
    return _card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.shopping_bag_outlined, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Order Summary',
                style: AppTypography.sectionHeading.copyWith(fontSize: 15),
              ),
              const Spacer(),
              Text(
                '${state.itemCount} item${state.itemCount != 1 ? 's' : ''}',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textDisabled),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (state.items.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text(
                  'Your cart is empty',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textDisabled),
                ),
              ),
            )
          else
            ...state.items.map((item) => _orderItemTile(item)),
        ],
      ),
    );
  }

  Widget _orderItemTile(CartItem item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: AppColors.textDisabled, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty ${item.quantity} \u00D7 Rs ${item.unitPriceSnapshot}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Rs ${item.subtotalSnapshot}',
            style: AppTypography.labelLarge.copyWith(fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ── Sticky Bottom Summary Bar ────────────────────────────────────────────
  Widget _buildBottomSummaryBar(CartState state, int total) {
    final effectiveDelivery = state.freeDelivery ? 0 : state.deliveryFee;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Subtotal',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  Text('Rs ${state.subtotal}',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Delivery',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary)),
                  if (state.quoteLoading)
                    const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 1.5),
                    )
                  else if (state.freeDelivery)
                    Text(
                      'Free',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.success,
                        fontWeight: FontWeight.w600,
                      ),
                    )
                  else
                    Text('Rs $effectiveDelivery',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary)),
                ],
              ),
              if (_couponDiscount > 0) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Coupon Discount',
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.success)),
                    Text('- Rs $_couponDiscount',
                        style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.success, fontWeight: FontWeight.w600)),
                  ],
                ),
              ],
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Total',
                      style: AppTypography.sectionHeading.copyWith(fontSize: 16)),
                  Text('Rs $total',
                      style: AppTypography.pricePrimary.copyWith(
                          color: AppColors.primary, fontSize: 20)),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _canContinue && !_placingOrder
                      ? () => _placeOrder(state)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.4),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _placingOrder
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Place Order — Rs $total',
                          style: AppTypography.buttonText
                              .copyWith(color: Colors.white, fontSize: 15),
                        ),
                ),
              ),
              if (!_canContinue) ...[
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    'Fill in name, phone, email & address to continue',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.textDisabled,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── OTP Verification Bottom Sheet ─────────────────────────────────────────

class _OtpVerificationSheet extends StatefulWidget {
  final String email;
  final String name;
  final String phone;
  final VoidCallback onVerified;

  const _OtpVerificationSheet({
    required this.email,
    required this.name,
    required this.phone,
    required this.onVerified,
  });

  @override
  State<_OtpVerificationSheet> createState() => _OtpVerificationSheetState();
}

class _OtpVerificationSheetState extends State<_OtpVerificationSheet> {
  final List<TextEditingController> _otpCtrls =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocus = List.generate(6, (_) => FocusNode());

  final CheckoutService _checkoutService = CheckoutService();

  bool _verifying = false;
  bool _sending = false;
  String? _error;
  int _resendSeconds = 30;

  @override
  void initState() {
    super.initState();
    _sendCode();
    _startResendTimer();
  }

  void _sendCode() async {
    setState(() => _sending = true);
    try {
      await _checkoutService.sendVerificationCode(
        widget.email,
        name: widget.name,
        phone: widget.phone,
      );
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = SoftstoreApiClient.humanReadableError(e);
        });
      }
    }
    if (mounted) setState(() => _sending = false);
  }

  void _startResendTimer() {
    _resendSeconds = 30;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (!mounted) return false;
      if (_resendSeconds <= 0) return false;
      setState(() => _resendSeconds--);
      return _resendSeconds > 0;
    });
  }

  @override
  void dispose() {
    for (final c in _otpCtrls) {
      c.dispose();
    }
    for (final f in _otpFocus) {
      f.dispose();
    }
    super.dispose();
  }

  String get _otpCode => _otpCtrls.map((c) => c.text).join();

  void _verify() async {
    if (_otpCode.length < 6) {
      setState(() => _error = 'Please enter the full 6-digit code');
      return;
    }
    setState(() {
      _verifying = true;
      _error = null;
    });

    try {
      await _checkoutService.verifyCode(_otpCode);
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email verified successfully!'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
      widget.onVerified();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _verifying = false;
        _error = SoftstoreApiClient.humanReadableError(e);
      });
    }
  }

  void _resendOtp() async {
    setState(() => _sending = true);
    try {
      await _checkoutService.sendVerificationCode(
        widget.email,
        name: widget.name,
        phone: widget.phone,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(SoftstoreApiClient.humanReadableError(e)),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
    if (!mounted) return;
    setState(() => _sending = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code resent to ${widget.email}'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
    _startResendTimer();
  }

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final availableHeight = MediaQuery.of(context).size.height * 0.85;

    return Padding(
      padding: EdgeInsets.only(bottom: keyboardHeight),
      child: Container(
        height: availableHeight,
        decoration: const BoxDecoration(
          color: Color(0xFFF5F5F5),
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            // ── Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 10),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  const Icon(Icons.shield_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Verify Email',
                            style: AppTypography.screenTitle.copyWith(fontSize: 17)),
                        const SizedBox(height: 2),
                        Text(
                          'Code sent to ${widget.email}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: const Icon(Icons.close_rounded,
                        color: AppColors.textDisabled, size: 22),
                  ),
                ],
              ),
            ),
            const Divider(height: 1, color: AppColors.divider),

            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: bottomPadding + 24,
                ),
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.mail_outline_rounded,
                          color: AppColors.primary, size: 36),
                    ),
                    const SizedBox(height: 20),
                    Text('Enter Verification Code',
                        style: AppTypography.sectionHeading.copyWith(fontSize: 16)),
                    const SizedBox(height: 8),
                    Text(
                      'We sent a 6-digit code to your email.\nEnter it below to verify and place your order.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textSecondary,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 28),

                    // OTP fields
                    Row(
                      children: List.generate(6, (i) {
                        return Expanded(
                          child: Container(
                            height: 52,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _otpCtrls[i].text.isNotEmpty
                                    ? AppColors.primary
                                    : _error != null
                                        ? AppColors.error
                                        : AppColors.divider,
                                width: _otpCtrls[i].text.isNotEmpty ? 2 : 1,
                              ),
                              boxShadow: _otpCtrls[i].text.isNotEmpty
                                  ? [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(alpha: 0.15),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                            child: TextField(
                              controller: _otpCtrls[i],
                              focusNode: _otpFocus[i],
                              textAlign: TextAlign.center,
                              keyboardType: TextInputType.number,
                              maxLength: 1,
                              style: AppTypography.screenTitle.copyWith(
                                fontSize: 22,
                                color: AppColors.textPrimary,
                              ),
                              decoration: const InputDecoration(
                                counterText: '',
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                              onChanged: (value) {
                                setState(() => _error = null);
                                if (value.isNotEmpty && i < 5) {
                                  _otpFocus[i + 1].requestFocus();
                                } else if (value.isEmpty && i > 0) {
                                  _otpFocus[i - 1].requestFocus();
                                }
                                if (_otpCode.length == 6) _verify();
                              },
                            ),
                          ),
                        );
                      }),
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: AppColors.error, size: 16),
                          const SizedBox(width: 6),
                          Text(_error!,
                              style: AppTypography.bodySmall.copyWith(color: AppColors.error)),
                        ],
                      ),
                    ],

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _verifying ? null : _verify,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _verifying
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                    color: Colors.white, strokeWidth: 2.5),
                              )
                            : Text(
                                'Verify & Place Order',
                                style: AppTypography.buttonText
                                    .copyWith(color: Colors.white, fontSize: 15),
                              ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Wrap(
                      alignment: WrapAlignment.center,
                      children: [
                        Text(
                          "Didn't receive the code? ",
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        if (_resendSeconds > 0)
                          Text(
                            'Resend in ${_resendSeconds}s',
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.textDisabled,
                              fontSize: 13,
                            ),
                          )
                        else
                          GestureDetector(
                            onTap: _sending ? null : _resendOtp,
                            child: Text(
                              'Resend Code',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                      ],
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
