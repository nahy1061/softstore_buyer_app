import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';
import '../models/order_model.dart';
import '../repository/order_repository.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final String referenceNumber;
  final String? invoiceNumber;
  final int? subtotal;
  final int? delivery;
  final String? productName;
  final int? productQty;
  final int? productPrice;
  final int? iconCodePoint;

  const OrderConfirmationScreen({
    super.key,
    required this.referenceNumber,
    this.invoiceNumber,
    this.subtotal,
    this.delivery,
    this.productName,
    this.productQty,
    this.productPrice,
    this.iconCodePoint,
  });

  @override
  State<OrderConfirmationScreen> createState() =>
      _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  // Mock data with prop overrides
  int get _subtotal => widget.subtotal ?? 200;
  int get _delivery => widget.delivery ?? 200;
  int get _total => _subtotal + _delivery;
  String get _invoice => widget.invoiceNumber ?? widget.referenceNumber;
  String get _productName => widget.productName ?? 'SoftStore Item';
  int get _productQty => widget.productQty ?? 1;
  int get _productPrice => widget.productPrice ?? _subtotal;
  IconData get _productIcon {
    if (widget.iconCodePoint != null) {
      // ignore: non_const_argument_for_const_parameter
      return IconData(widget.iconCodePoint!, fontFamily: 'MaterialIcons');
    }
    return const IconData(0xe539, fontFamily: 'MaterialIcons'); // local_drink
  }

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.4, 1.0, curve: Curves.easeOut),
    );
    _animController.forward();
    _ensureSavedLocally();
  }

  Future<void> _ensureSavedLocally() async {
    final inv = _invoice;
    final now = DateTime.now();
    final order = Order(
      id: inv,
      referenceNumber: inv,
      placedAt: now,
      status: OrderStatus.pending,
      items: [
        OrderItem(
          id: 'item-1',
          name: _productName,
          quantity: _productQty,
          unitPrice: _productPrice.toDouble(),
          sku: 'SKU-$inv',
        ),
      ],
      deliveryAddress: const OrderAddress(
        name: 'Customer',
        phone: '03408014187',
        addressLine: 'Delivery Address',
        city: 'Lahore',
      ),
      subtotal: _subtotal.toDouble(),
      deliveryFee: _delivery.toDouble(),
      discount: 0,
      storeName: 'SoftStore Official Partner',
      storeCity: 'Lahore',
      estimatedDelivery: 'Expected in 2-3 business days',
      statusHistory: [
        OrderStatusEvent(
          status: OrderStatus.pending,
          timestamp: now,
          note: 'Order placed successfully',
        ),
      ],
    );
    await OrderRepository.instance.saveLocalOrder(order);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
              child: Column(
                children: [
                  // ── Success Header ─────────────────────────────────
                  _buildSuccessHeader(),
                  const SizedBox(height: 8),
                  _buildPaymentSummaryCard(),
                  const SizedBox(height: 14),
                  _buildInvoiceBanner(),
                  const SizedBox(height: 14),
                  _buildOrderItemsCard(),
                ],
              ),
            ),
          ),

          // ── Sticky Bottom CTA ───────────────────────────────────
          _buildBottomCta(),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 0),
    );
  }

  // ── Success Header ─────────────────────────────────────────────────────
  Widget _buildSuccessHeader() {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        children: [
          // Green checkmark circle peeking off top
          ScaleTransition(
            scale: _scaleAnim,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.check_rounded,
                color: Color(0xFF16A34A),
                size: 56,
              ),
            ),
          ),
          const SizedBox(height: 20),
          FadeTransition(
            opacity: _fadeAnim,
            child: Column(
              children: [
                Text(
                  'Order Placed Successfully!',
                  style: AppTypography.screenTitle.copyWith(
                    fontSize: 22,
                    color: AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Order placed successfully! Your order is\nnow pending seller confirmation.',
                  textAlign: TextAlign.center,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.4,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Payment Summary Card ───────────────────────────────────────────────
  Widget _buildPaymentSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDimensions.radiusLg,
        boxShadow: AppDimensions.cardShadow,
      ),
      child: Column(
        children: [
          // COD badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.payments_rounded,
                    color: Color(0xFF16A34A), size: 16),
                const SizedBox(width: 6),
                Text(
                  'Cash on Delivery',
                  style: AppTypography.bodySmall.copyWith(
                    color: const Color(0xFF16A34A),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Amount to pay on delivery',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Rs $_total',
            style: AppTypography.pricePrimary.copyWith(
              color: const Color(0xFFEA580C),
              fontSize: 40,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),

          // Subtotal row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
              Text('Rs $_subtotal',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 10),

          // Delivery row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Delivery',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textSecondary)),
              Text('Rs $_delivery',
                  style: AppTypography.bodyMedium
                      .copyWith(color: AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 14),

          // Helper text
          Text(
            'Keep Rs $_total in cash ready — pay the rider\nwhen your order arrives.',
            textAlign: TextAlign.center,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textDisabled,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Invoice Number Banner ──────────────────────────────────────────────
  Widget _buildInvoiceBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: const Color(0xFFFDECE1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          Text(
            'Invoice Number',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _invoice,
            style: const TextStyle(
              fontFamily: 'Roboto Mono',
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFFEA580C),
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // ── Order Items Card ───────────────────────────────────────────────────
  Widget _buildOrderItemsCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: AppDimensions.radiusLg,
        boxShadow: AppDimensions.cardShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.inventory_2_outlined,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'In this order',
                style:
                    AppTypography.sectionHeading.copyWith(fontSize: 15),
              ),
              const Spacer(),
              Text(
                '1 item',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textDisabled,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Product row
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.divider),
                ),
                child: Icon(_productIcon,
                    color: AppColors.textDisabled, size: 28),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _productName,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Qty $_productQty',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Rs $_productPrice',
                style: AppTypography.labelLarge.copyWith(fontSize: 15),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Sticky Bottom CTA ─────────────────────────────────────────────────
  Widget _buildBottomCta() {
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
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
          child: SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                context.go('/orders');
              },
              icon: const Icon(Icons.inventory_2_outlined, size: 20),
              label: Text(
                'Track Order',
                style: AppTypography.buttonText
                    .copyWith(color: Colors.white, fontSize: 16),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
