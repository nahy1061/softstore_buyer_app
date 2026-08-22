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
import '../../auth/widgets/otp_verification_dialog.dart';
import '../../cart/cubit/cart_cubit.dart';
import '../../cart/cubit/cart_state.dart';
import '../../cart/models/cart_models.dart';
import '../../cart/repository/cart_repository.dart';
import '../../orders/models/order_model.dart' as order_models;
import '../../orders/repository/order_repository.dart';
import '../../profile/cubit/address_cubit.dart';
import '../../profile/cubit/address_state.dart';
import '../../profile/models/address_model.dart';
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

  /// Whether the saved default delivery address has been applied to the form.
  bool _defaultAddressApplied = false;

  List<CartItem> _selectedItems(CartState cartState) {
    if (cartState.hasSelection && cartState.selectedItems.isNotEmpty) {
      return cartState.selectedItems;
    }
    return cartState.items;
  }

  @override
  void initState() {
    super.initState();
    _fillUserData();
    _initDefaultAddressFetch();
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

  // ─── Default Delivery Address Autofill ───────────────────────────────────

  void _initDefaultAddressFetch() {
    final authState = context.read<AuthCubit>().state;
    if (authState is! AuthAuthenticated) return;

    final addressCubit = context.read<AddressCubit>();
    final cached = _addressesFromState(addressCubit.state);
    if (cached != null && cached.isNotEmpty) {
      _applyDefaultAddress(cached);
      return;
    }
    addressCubit.loadAddresses();
  }

  List<Address>? _addressesFromState(AddressState state) {
    if (state is AddressLoaded) return state.addresses;
    if (state is AddressAddSuccess) return state.addresses;
    if (state is AddressUpdateSuccess) return state.addresses;
    if (state is AddressDeleteSuccess) return state.addresses;
    return null;
  }

  Address? _pickDefaultAddress(List<Address> addresses) {
    bool hasContent(Address a) =>
        a.address.trim().isNotEmpty ||
        a.phone.trim().isNotEmpty ||
        a.name.trim().isNotEmpty;
    for (final a in addresses) {
      if (a.isDefault && hasContent(a)) return a;
    }
    for (final a in addresses) {
      if (hasContent(a)) return a;
    }
    return null;
  }

  void _applyDefaultAddress(List<Address> addresses) {
    if (_defaultAddressApplied) return;
    final savedAddress = _pickDefaultAddress(addresses);
    if (savedAddress == null) return;
    _defaultAddressApplied = true;

    final fullAddress = savedAddress.city.trim().isNotEmpty
        ? '${savedAddress.address.trim()}, ${savedAddress.city.trim()}'
        : savedAddress.address.trim();
    final savedName = savedAddress.name.trim();
    final savedPhone = savedAddress.phone.trim();

    if (fullAddress.isNotEmpty) _addressCtrl.text = fullAddress;
    if (savedName.isNotEmpty) _nameCtrl.text = savedName;
    if (savedPhone.isNotEmpty) {
      _phoneCtrl.text = savedPhone;
    } else if (_phoneCtrl.text.trim().isEmpty) {
      final authState = context.read<AuthCubit>().state;
      if (authState is AuthAuthenticated) {
        final userPhone = authState.user.phone?.trim() ?? '';
        if (userPhone.isNotEmpty) _phoneCtrl.text = userPhone;
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
    final subtotal = items.fold(0.0, (sum, i) => sum + (i.price * i.quantity));
    try {
      final res = await _repo.validateCoupon(code: code, subtotal: subtotal);
      if (!mounted) return;
      setState(() {
        _couponValid = res.valid;
        if (res.valid) {
          _discountAmount = res.discountAmount;
          _couponMessage = 'Coupon applied successfully!';
        } else {
          _discountAmount = 0;
          _couponMessage = res.message.isNotEmpty
              ? res.message
              : 'Invalid coupon';
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
    final user = authState is AuthAuthenticated ? authState.user : null;
    final userEmail = user?.email.trim() ?? '';
    final isPersistedVerified = userEmail.isNotEmpty
        ? await _repo.isEmailVerified(userEmail)
        : false;

    final emailVerified =
        _emailVerifiedInSession ||
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
      final targetEmail = userEmail.isNotEmpty
          ? userEmail
          : _phoneCtrl.text.trim();
      final verified = await OtpVerificationDialog.show(
        context,
        email: targetEmail,
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        title: 'Email Verification',
        subtitle: targetEmail.isNotEmpty
            ? 'Enter the 6-digit code sent to $targetEmail to place your order.'
            : 'Enter the 6-digit code sent to your registered email to place your order.',
        primaryButtonText: 'Verify & Place Order',
        autoSendOtp: true,
      );

      if (verified && mounted) {
        _emailVerifiedInSession = true;
        _submitOrder();
      }
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

    final orderEmail = userEmail.isNotEmpty ? userEmail : 'buyer@softstore.pk';

    final request = OrderRequest(
      items: repoItems,
      customerName: _nameCtrl.text.trim(),
      customerAddress: _addressCtrl.text.trim(),
      customerPhone: _phoneCtrl.text.trim(),
      customerEmail: orderEmail,
      notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
      couponCode: _couponCtrl.text.trim().isEmpty
          ? null
          : _couponCtrl.text.trim(),
    );

    final now = DateTime.now();
    final rand5 = 10000 + (now.microsecondsSinceEpoch % 90000);
    final fallbackInvoice =
        'INV-${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-$rand5';
    String invoice = fallbackInvoice;
    String? errorMsg;
    bool serverSuccess = false;

    try {
      final result = await _repo.placeOrder(request);
      if (result.success &&
          result.invoiceNumber != null &&
          result.invoiceNumber!.isNotEmpty) {
        invoice = result.invoiceNumber!;
        serverSuccess = true;
      } else {
        errorMsg = result.message ?? 'Order failed. Please try again.';
      }
    } on AuthFailure catch (e) {
      if (e.message == 'email_unverified') {
        if (!mounted) return;
        setState(() {
          _isSubmitting = false;
        });
        final targetEmail = userEmail.isNotEmpty
            ? userEmail
            : _phoneCtrl.text.trim();
        final verified = await OtpVerificationDialog.show(
          context,
          email: targetEmail,
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          title: 'Email Verification',
          subtitle: targetEmail.isNotEmpty
              ? 'Enter the 6-digit code sent to $targetEmail to place your order.'
              : 'Enter the 6-digit code sent to your registered email to place your order.',
          primaryButtonText: 'Verify & Place Order',
          autoSendOtp: true,
        );
        if (verified && mounted) {
          _emailVerifiedInSession = true;
          _submitOrder();
        }
        return;
      }
      errorMsg = e.message;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order note: ${e.message}'),
            backgroundColor: AppColors.warning,
          ),
        );
      }
    } catch (e) {
      errorMsg =
          'Failed to place order. Please check your connection and try again.';
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

    // If no invoice received, show error and stop
    if (invoice == fallbackInvoice && errorMsg != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
      return;
    }

    final firstItem = items.isNotEmpty ? items.first : null;
    final subtotal = items.fold(0.0, (sum, i) => sum + (i.price * i.quantity));

    final placedOrder = order_models.Order(
      id: invoice,
      referenceNumber: invoice,
      placedAt: now,
      status: serverSuccess
          ? order_models.OrderStatus.confirmed
          : order_models.OrderStatus.pending,
      items: items
          .map(
            (i) => order_models.OrderItem(
              id: i.id,
              name: i.name,
              quantity: i.quantity,
              unitPrice: i.price.toDouble(),
              sku: 'SKU-${i.id}',
            ),
          )
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
    final subtotal = items.fold(0.0, (sum, i) => sum + (i.price * i.quantity));
    final total = (subtotal + _deliveryFee - _discountAmount).clamp(
      0.0,
      double.infinity,
    );

    return BlocListener<AddressCubit, AddressState>(
      listener: (context, state) {
        final addresses = _addressesFromState(state);
        if (addresses == null) return;
        _applyDefaultAddress(addresses);
      },
      child: Scaffold(
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
                  border: Border.all(
                    color: const Color(0xFFE5E7EB),
                    width: 0.8,
                  ),
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
      ),
    );
  }
}
