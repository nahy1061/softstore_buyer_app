import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/errors/failures.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../../auth/cubit/auth_state.dart';
import '../../cart/cubit/cart_cubit.dart';
import '../../cart/cubit/cart_state.dart';
import '../../cart/models/cart_models.dart';
import '../../cart/repository/cart_repository.dart';
import '../../orders/models/order_model.dart' as order_models;
import '../../orders/repository/order_repository.dart';
import '../widgets/coupon_code_section.dart';
import '../widgets/delivery_address_section.dart';
import '../widgets/order_notes_section.dart';
import '../widgets/order_summary_section.dart';

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

  /// Whether the user's email has been verified in this checkout session.
  bool _emailVerifiedInSession = false;
  Timer? _otpResendTimer;

  List<CartItem> _selectedItems(CartState cartState) {
    return cartState.selectedItems;
  }

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
    final items = _selectedItems(cartState);
    if (items.isEmpty) return;

    final repoItems = items.map((i) {
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
    final items = _selectedItems(cartState);
    final subtotal =
        items.fold(0.0, (sum, i) => sum + (i.price * i.quantity));
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

  // ─── Order Submission ────────────────────────────────────────────────────

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;

    // ── Guard: ensure email is verified before placing order ──────────
    final authState = context.read<AuthCubit>().state;
    final user =
        authState is AuthAuthenticated ? authState.user : null;
    final userEmail = user?.email.trim() ?? '';
    final isPersistedVerified = userEmail.isNotEmpty
        ? await _repo.isEmailVerified(userEmail)
        : false;

    final emailVerified = _emailVerifiedInSession ||
        (user?.isEmailVerified ?? false) ||
        isPersistedVerified;

    developer.log(
      '[Checkout] _submitOrder: emailVerified=$emailVerified '
      '_emailVerifiedInSession=$_emailVerifiedInSession '
      'isPersistedVerified=$isPersistedVerified '
      'user.isEmailVerified=${user?.isEmailVerified}',
      name: 'checkout',
    );

    if (!emailVerified) {
      if (!mounted) return;
      _showOtpVerificationDialog();
      return;
    }

    final cartState = context.read<CartCubit>().state;
    final items = _selectedItems(cartState);
    if (items.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Your cart is empty. Please add items first.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final repoItems = items.map((i) {
      final numericId = i.productId;
      return CartItem(
        uuid: i.id,
        productId: numericId,
        productName: i.name,
        quantity: i.quantity,
        unitPriceSnapshot: i.price.toDouble(),
      );
    }).toList();

    final orderEmail =
        userEmail.isNotEmpty ? userEmail : 'buyer@softstore.pk';

    final request = OrderRequest(
      items: repoItems,
      customerName: _nameCtrl.text.trim(),
      customerAddress: _addressCtrl.text.trim(),
      customerPhone: _phoneCtrl.text.trim(),
      customerEmail: orderEmail,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      couponCode:
          _couponCtrl.text.trim().isEmpty ? null : _couponCtrl.text.trim(),
    );

    final now = DateTime.now();
    final rand5 = 10000 + (now.microsecondsSinceEpoch % 90000);
    final fallbackInvoice =
        'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$rand5';
    String invoice = fallbackInvoice;
    bool serverSuccess = false;

    try {
      final result = await _repo.placeOrder(request);
      if (result.success &&
          result.invoiceNumber != null &&
          result.invoiceNumber!.isNotEmpty) {
        invoice = result.invoiceNumber!;
        serverSuccess = true;
      }
    } on AuthFailure catch (e) {
      if (e.message == 'email_unverified') {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
        });
        _showOtpVerificationDialog();
        return;
      }
      // Other auth errors — show but continue with local fallback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order note: ${e.message}'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      // Network or server error — continue with local fallback
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Server unavailable. Order saved locally. Error: ${e.toString().length > 80 ? e.toString().substring(0, 80) : e.toString()}',
            ),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }

    final firstItem = items.isNotEmpty ? items.first : null;
    final subtotal =
        items.fold(0.0, (sum, i) => sum + (i.price * i.quantity));

    final placedOrder = order_models.Order(
      id: invoice,
      referenceNumber: invoice,
      placedAt: now,
      status: serverSuccess
          ? order_models.OrderStatus.confirmed
          : order_models.OrderStatus.pending,
      items: items
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
          status: serverSuccess
              ? order_models.OrderStatus.confirmed
              : order_models.OrderStatus.pending,
          timestamp: now,
          note: serverSuccess
              ? 'Order confirmed by server'
              : 'Order placed by customer (pending server confirmation)',
        ),
      ],
    );

    await _orderRepo.saveLocalOrder(placedOrder);

    if (mounted) {
      final cubit = context.read<CartCubit>();
      if (cubit.state.hasSelection) {
        cubit.removeSelected();
      } else {
        cubit.clearCart();
      }
      context.go(
        '/order-confirmation/$invoice',
        extra: {
          'invoiceNumber': invoice,
          'subtotal': subtotal.toInt(),
          'delivery': _deliveryFee.toInt(),
          'productName': firstItem?.name ?? 'SoftStore Item',
          'productQty': firstItem?.quantity ?? 1,
          'productPrice':
              firstItem?.price.toInt() ?? cartState.totalPrice.toInt(),
          'iconCodePoint':
              firstItem?.iconCodePoint ?? Icons.inventory_2_outlined.codePoint,
          'customerName': _nameCtrl.text.trim(),
          'customerPhone': _phoneCtrl.text.trim(),
          'customerAddress': _addressCtrl.text.trim(),
          'customerCity': 'Lahore',
        },
      );
    }
  }

  @override
  void dispose() {
    _otpResendTimer?.cancel();
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
    final items = _selectedItems(cartState);
    final subtotal =
        items.fold(0.0, (sum, i) => sum + (i.price * i.quantity));
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
                border:
                    Border.all(color: const Color(0xFFE5E7EB), width: 0.8),
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
              // ── 1. Delivery Address Card ─────────────────────────────────
              DeliveryAddressSection(
                nameController: _nameCtrl,
                phoneController: _phoneCtrl,
                addressController: _addressCtrl,
              ),
              const SizedBox(height: 16),

              // ── 2. Order Notes Card ──────────────────────────────────────
              OrderNotesSection(notesController: _notesCtrl),
              const SizedBox(height: 16),

              // ── 3. Coupon Code Card ──────────────────────────────────────
              CouponCodeSection(
                couponController: _couponCtrl,
                isValidating: _isValidatingCoupon,
                message: _couponMessage,
                isValid: _couponValid,
                onApply: _applyCoupon,
              ),
              const SizedBox(height: 20),

              // ── 4. Order Summary Card ────────────────────────────────────
              OrderSummarySection(
                subtotal: subtotal,
                deliveryFee: _deliveryFee,
                discountAmount: _discountAmount,
                total: total,
                isSubmitting: _isSubmitting,
                onSubmit: _submitOrder,
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 3),
    );
  }

  // ─── OTP Verification Dialog ────────────────────────────────────────

  void _showOtpVerificationDialog() {
    final otpCtrl = TextEditingController();
    bool sending = false;
    bool verifying = false;
    String? error;
    String? success;
    int resendSeconds = 0;

    final authState = context.read<AuthCubit>().state;
    final user = authState is AuthAuthenticated ? authState.user : null;
    final email = user?.email.trim() ?? '';
    final userName = user?.fullName ?? '';
    final userPhone = user?.phone ?? '';

    void sendOtp(StateSetter setDialogState) async {
      setDialogState(() {
        sending = true;
        error = null;
        success = null;
      });
      try {
        await _repo.sendVerificationOtp(
          email,
          name: userName,
          phone: userPhone,
        );
        setDialogState(() {
          sending = false;
          success = email.isNotEmpty
              ? 'Verification code sent to $email'
              : 'Verification code sent to your email';
          resendSeconds = 60;
        });
        _otpResendTimer?.cancel();
        _otpResendTimer = Timer.periodic(const Duration(seconds: 1), (t) {
          if (resendSeconds <= 0) {
            t.cancel();
          } else {
            setDialogState(() => resendSeconds--);
          }
        });
      } catch (e) {
        setDialogState(() {
          sending = false;
          error = e is Failure
              ? e.message
              : (e is AuthFailure
                  ? e.message
                  : 'Failed to send code. Please try again.');
        });
      }
    }

    bool dialogBuilt = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            if (!dialogBuilt) {
              dialogBuilt = true;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                sendOtp(setDialogState);
              });
            }
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              content: SizedBox(
                width: 340,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: const BoxDecoration(
                        color: Color(0xFFFFF3E0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_unread_outlined,
                        color: Color(0xFFFF6F00),
                        size: 26,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Email Verification',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      email.isNotEmpty
                          ? 'Enter the 6-digit code sent to $email to place your order.'
                          : 'Enter the 6-digit code sent to your registered email to place your order.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F4F6),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFE5E7EB), width: 0.8),
                      ),
                      child: TextFormField(
                        controller: otpCtrl,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        style: const TextStyle(
                          fontSize: 20,
                          letterSpacing: 10,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF111827),
                        ),
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(
                          hintText: '• • • • • •',
                          hintStyle: TextStyle(
                            color: Color(0xFF9CA3AF),
                            fontSize: 16,
                            letterSpacing: 4,
                          ),
                          counterText: '',
                          border: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 14, vertical: 14),
                        ),
                      ),
                    ),
                    if (error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        error!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    if (success != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        success!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF16A34A),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        onPressed: (verifying || otpCtrl.text.trim().length != 6)
                            ? null
                            : () async {
                                setDialogState(() => verifying = true);
                                try {
                                  await _repo
                                      .verifyCheckoutOtp(otpCtrl.text.trim());
                                  if (!mounted) return;
                                  if (email.isNotEmpty) {
                                    await _repo.markEmailVerified(email);
                                  }
                                  _emailVerifiedInSession = true;
                                  _otpResendTimer?.cancel();
                                  if (dialogContext.mounted) {
                                    Navigator.of(dialogContext).pop();
                                  }
                                  _submitOrder();
                                } catch (e) {
                                  setDialogState(() {
                                    verifying = false;
                                    error = e is AuthFailure
                                        ? e.message
                                        : 'Invalid or expired code.';
                                  });
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFF6F00),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: verifying
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
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
                    const SizedBox(height: 10),
                    Center(
                      child: resendSeconds > 0
                          ? Text(
                              'Resend code in ${resendSeconds}s',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF9CA3AF),
                              ),
                            )
                          : GestureDetector(
                              onTap: sending
                                  ? null
                                  : () => sendOtp(setDialogState),
                              child: Text(
                                sending ? 'Sending...' : 'Resend Code',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFFFF6F00),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: GestureDetector(
                        onTap: () {
                          _otpResendTimer?.cancel();
                          Navigator.of(dialogContext).pop();
                        },
                        child: const Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 13,
                            color: Color(0xFF9CA3AF),
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    ).then((_) {
      _otpResendTimer?.cancel();
    });
  }
}
