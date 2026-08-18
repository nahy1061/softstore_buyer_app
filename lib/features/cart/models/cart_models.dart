import 'dart:convert';
import 'package:equatable/equatable.dart';

// ─── CartItem ─────────────────────────────────────────────────────────────────

class CartItem extends Equatable {
  final String uuid;
  final int productId;
  final String productName;
  final String? productSlug;
  final int? variantId;
  final String? variantLabel;
  final int quantity;
  final double unitPriceSnapshot;
  final String? imageUrl;

  const CartItem({
    required this.uuid,
    required this.productId,
    required this.productName,
    this.productSlug,
    this.variantId,
    this.variantLabel,
    required this.quantity,
    required this.unitPriceSnapshot,
    this.imageUrl,
  });

  double get subtotal => unitPriceSnapshot * quantity;

  CartItem copyWith({int? quantity, double? unitPriceSnapshot}) {
    return CartItem(
      uuid: uuid,
      productId: productId,
      productName: productName,
      productSlug: productSlug,
      variantId: variantId,
      variantLabel: variantLabel,
      quantity: quantity ?? this.quantity,
      unitPriceSnapshot: unitPriceSnapshot ?? this.unitPriceSnapshot,
      imageUrl: imageUrl,
    );
  }

  Map<String, dynamic> toJson() => {
        'uuid': uuid,
        'productId': productId,
        'productName': productName,
        if (productSlug != null) 'productSlug': productSlug,
        if (variantId != null) 'variantId': variantId,
        if (variantLabel != null) 'variantLabel': variantLabel,
        'quantity': quantity,
        'unitPriceSnapshot': unitPriceSnapshot,
        if (imageUrl != null) 'imageUrl': imageUrl,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        uuid: json['uuid'] as String,
        productId: json['productId'] as int,
        productName: json['productName'] as String,
        productSlug: json['productSlug'] as String?,
        variantId: json['variantId'] as int?,
        variantLabel: json['variantLabel'] as String?,
        quantity: json['quantity'] as int,
        unitPriceSnapshot:
            (json['unitPriceSnapshot'] as num).toDouble(),
        imageUrl: json['imageUrl'] as String?,
      );

  @override
  List<Object?> get props => [uuid];
}

// ─── ShippingQuote ────────────────────────────────────────────────────────────

class ShippingQuote {
  final double deliveryFee;
  final double? totalWeightKg;
  final bool isFree;
  final String currency;

  const ShippingQuote({
    required this.deliveryFee,
    this.totalWeightKg,
    this.isFree = false,
    this.currency = 'PKR',
  });

  factory ShippingQuote.fromJson(Map<String, dynamic> json) => ShippingQuote(
        deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0,
        totalWeightKg: (json['total_weight_kg'] as num?)?.toDouble(),
        isFree: json['free'] == true,
        currency: json['currency'] as String? ?? 'PKR',
      );
}

// ─── CouponResult ─────────────────────────────────────────────────────────────

class CouponResult {
  final bool valid;
  final double discountAmount;
  final String message;

  const CouponResult({
    required this.valid,
    required this.discountAmount,
    required this.message,
  });

  factory CouponResult.fromJson(Map<String, dynamic> json) => CouponResult(
        valid: json['valid'] == true,
        discountAmount: (json['discount_amount'] as num?)?.toDouble() ?? 0,
        message: json['message'] as String? ?? '',
      );
}

// ─── OrderRequest ─────────────────────────────────────────────────────────────

class OrderRequest {
  final List<CartItem> items;
  final String customerName;
  final String customerAddress;
  final String customerPhone;
  final String customerEmail;
  final String? notes;
  final String? couponCode;

  const OrderRequest({
    required this.items,
    required this.customerName,
    required this.customerAddress,
    required this.customerPhone,
    required this.customerEmail,
    this.notes,
    this.couponCode,
  });
}

// ─── PlacedOrderResult ────────────────────────────────────────────────────────

class PlacedOrderResult {
  final bool success;
  final String? invoiceNumber;
  final List<String> invoices;
  final double? discountAmount;
  final String? message;

  const PlacedOrderResult({
    required this.success,
    this.invoiceNumber,
    this.invoices = const [],
    this.discountAmount,
    this.message,
  });

  factory PlacedOrderResult.fromJson(Map<String, dynamic> json) =>
      PlacedOrderResult(
        success: json['success'] == true,
        invoiceNumber: json['invoice_number'] as String?,
        invoices: (json['invoices'] as List?)?.cast<String>() ?? [],
        discountAmount: (json['discount_amount'] as num?)?.toDouble(),
        message: json['message'] as String?,
      );
}
