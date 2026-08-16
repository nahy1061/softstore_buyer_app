import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import '../../core/storage/cart_store.dart';
import '../../core/storage/session_store.dart';
import '../../core/constants/app_constants.dart';
import '../../services/checkout_service.dart';
import 'order_confirmation_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  final _cityCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _service = CheckoutService();
  bool _placingOrder = false;
  bool _fetchingQuote = false;
  ShippingQuote? _quote;

  @override
  void initState() {
    super.initState();
    _prefillFromSession();
    _cityCtrl.addListener(_onCityChanged);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  void _prefillFromSession() async {
    final session = context.read<SessionStore>();
    final buyer = session.buyer;
    if (buyer != null) {
      _nameCtrl.text = buyer.fullName;
      _emailCtrl.text = buyer.email;
      if (buyer.phone != null) _phoneCtrl.text = buyer.phone!;
    }
    // Also restore any previously saved delivery details.
    final prefs = await SharedPreferences.getInstance();
    if (_addressCtrl.text.isEmpty) {
      _addressCtrl.text = prefs.getString('checkout_address') ?? '';
    }
    if (_cityCtrl.text.isEmpty) {
      _cityCtrl.text = prefs.getString('checkout_city') ?? '';
    }
    if (_cityCtrl.text.isNotEmpty) _fetchQuote();
  }

  void _onCityChanged() {
    final city = _cityCtrl.text.trim();
    if (city.length >= 3) _fetchQuote();
  }

  Future<void> _fetchQuote() async {
    final city = _cityCtrl.text.trim();
    if (city.isEmpty) return;
    final cart = context.read<CartStore>();
    setState(() => _fetchingQuote = true);
    final q = await _service.shippingQuote(city: city, items: cart.items.toList());
    if (mounted) setState(() { _quote = q; _fetchingQuote = false; });
  }

  Future<void> _placeOrder() async {
    if (!_formKey.currentState!.validate()) return;

    final cart = context.read<CartStore>();
    if (cart.items.isEmpty) {
      _showSnack('Your cart is empty.');
      return;
    }

    setState(() => _placingOrder = true);

    // Persist delivery info for next time.
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('checkout_address', _addressCtrl.text.trim());
    await prefs.setString('checkout_city', _cityCtrl.text.trim());

    try {
      final invoice = await _service.checkout(
        CheckoutRequest(
          customerName: _nameCtrl.text.trim(),
          customerEmail: _emailCtrl.text.trim(),
          customerPhone: _phoneCtrl.text.trim(),
          addressLine1: _addressCtrl.text.trim(),
          city: _cityCtrl.text.trim(),
          notes: _notesCtrl.text.trim().isEmpty ? null : _notesCtrl.text.trim(),
          items: cart.items.toList(),
        ),
      );
      cart.clear();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderConfirmationScreen(invoiceNumber: invoice)),
      );
    } catch (e) {
      if (mounted) _showSnack(e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _placingOrder = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.danger),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartStore>();
    final subtotal = cart.subtotal;
    final freeDelivery = subtotal >= AppConstants.freeDeliveryThreshold;
    final deliveryFee = freeDelivery ? 0.0 : (_quote?.fee ?? 200.0);
    final total = subtotal + deliveryFee;

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(title: const Text('Checkout')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Delivery Address ────────────────────────────────────────────
            _SectionTitle(title: 'Delivery Details', icon: Icons.location_on_outlined),
            const SizedBox(height: 12),
            _Field(
              controller: _nameCtrl,
              label: 'Full Name',
              hint: 'Muhammad Ali',
              icon: Icons.person_outline,
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Name is required' : null,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _emailCtrl,
              label: 'Email Address',
              hint: 'you@example.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v?.trim().isEmpty ?? true) return 'Email is required';
                if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v!.trim())) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _phoneCtrl,
              label: 'Phone Number',
              hint: '03XX-XXXXXXX',
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Phone is required' : null,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _addressCtrl,
              label: 'Street Address',
              hint: 'House #, Street, Area',
              icon: Icons.home_outlined,
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'Address is required' : null,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 12),
            _Field(
              controller: _cityCtrl,
              label: 'City',
              hint: 'Karachi',
              icon: Icons.location_city_outlined,
              validator: (v) => (v?.trim().isEmpty ?? true) ? 'City is required' : null,
              textCapitalization: TextCapitalization.words,
            ),

            // ── Order Notes ─────────────────────────────────────────────────
            const SizedBox(height: 20),
            _SectionTitle(title: 'Order Notes (optional)', icon: Icons.note_outlined),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesCtrl,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Any special instructions for delivery...',
                alignLabelWithHint: true,
              ),
            ),

            // ── Payment Method ───────────────────────────────────────────────
            const SizedBox(height: 20),
            _SectionTitle(title: 'Payment Method', icon: Icons.payments_outlined),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(AppRadius.md),
                border: Border.all(color: AppColors.brandOrange, width: 1.5),
              ),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.brandOrange.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.money_outlined, color: AppColors.brandOrange, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Cash on Delivery', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                  Text('Pay when your order arrives.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                ])),
                const Icon(Icons.check_circle, color: AppColors.brandOrange, size: 22),
              ]),
            ),

            // ── Price Summary ────────────────────────────────────────────────
            const SizedBox(height: 20),
            _SectionTitle(title: 'Order Summary', icon: Icons.receipt_outlined),
            const SizedBox(height: 12),
            _SummaryCard(
              subtotal: subtotal,
              deliveryFee: deliveryFee,
              freeDelivery: freeDelivery,
              total: total,
              itemCount: cart.count,
              fetchingQuote: _fetchingQuote,
            ),
            const SizedBox(height: 24),

            // ── Place Order ─────────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _placingOrder ? null : _placeOrder,
                child: _placingOrder
                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                    : Text('Place Order · PKR ${total.toInt()}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Reusable form field
// ---------------------------------------------------------------------------

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final TextCapitalization textCapitalization;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section title
// ---------------------------------------------------------------------------

class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle({required this.title, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Icon(icon, size: 20, color: AppColors.brandOrange),
      const SizedBox(width: 8),
      Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
    ]);
  }
}

// ---------------------------------------------------------------------------
// Summary card
// ---------------------------------------------------------------------------

class _SummaryCard extends StatelessWidget {
  final double subtotal;
  final double deliveryFee;
  final bool freeDelivery;
  final double total;
  final int itemCount;
  final bool fetchingQuote;

  const _SummaryCard({
    required this.subtotal,
    required this.deliveryFee,
    required this.freeDelivery,
    required this.total,
    required this.itemCount,
    required this.fetchingQuote,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(children: [
        _Row(label: 'Subtotal ($itemCount items)', value: 'PKR ${subtotal.toInt()}'),
        const SizedBox(height: 8),
        _Row(
          label: 'Delivery',
          value: fetchingQuote
              ? '...'
              : (freeDelivery ? 'FREE' : 'PKR ${deliveryFee.toInt()}'),
          valueColor: freeDelivery ? AppColors.success : null,
        ),
        const Divider(height: 20),
        _Row(
          label: 'Total',
          value: 'PKR ${total.toInt()}',
          bold: true,
        ),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  final Color? valueColor;

  const _Row({required this.label, required this.value, this.bold = false, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final ts = TextStyle(
      fontSize: bold ? 15 : 14,
      fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
    );
    return Row(children: [
      Expanded(child: Text(label, style: ts)),
      Text(value, style: ts.copyWith(color: valueColor ?? (bold ? AppColors.brandOrange : null))),
    ]);
  }
}
