import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
  refunded,
}

extension OrderStatusExtension on OrderStatus {
  String get label {
    switch (this) {
      case OrderStatus.pending:      return 'Order Pending';
      case OrderStatus.confirmed:    return 'Confirmed';
      case OrderStatus.processing:   return 'Processing';
      case OrderStatus.shipped:      return 'Shipped';
      case OrderStatus.delivered:    return 'Delivered';
      case OrderStatus.cancelled:    return 'Cancelled';
      case OrderStatus.refunded:     return 'Refunded';
    }
  }

  String get shortLabel {
    switch (this) {
      case OrderStatus.pending:      return 'Pending';
      case OrderStatus.confirmed:    return 'Confirmed';
      case OrderStatus.processing:   return 'Processing';
      case OrderStatus.shipped:      return 'Shipped';
      case OrderStatus.delivered:    return 'Delivered';
      case OrderStatus.cancelled:    return 'Cancelled';
      case OrderStatus.refunded:     return 'Refunded';
    }
  }

  String get statusMessage {
    switch (this) {
      case OrderStatus.pending:
        return 'Your order has been placed and is awaiting seller confirmation.';
      case OrderStatus.confirmed:
        return 'The seller has confirmed your order and will begin processing soon.';
      case OrderStatus.processing:
        return 'Your order is being packed and prepared by the store.';
      case OrderStatus.shipped:
        return 'Your order is on the way to your delivery address.';
      case OrderStatus.delivered:
        return 'Your order has been delivered successfully.';
      case OrderStatus.cancelled:
        return 'This order was cancelled.';
      case OrderStatus.refunded:
        return 'A refund has been initiated for this order.';
    }
  }

  Color get color {
    switch (this) {
      case OrderStatus.pending:      return AppColors.statusPending;
      case OrderStatus.confirmed:    return AppColors.statusConfirmed;
      case OrderStatus.processing:   return AppColors.statusProcessing;
      case OrderStatus.shipped:      return AppColors.statusShipped;
      case OrderStatus.delivered:    return AppColors.statusDelivered;
      case OrderStatus.cancelled:    return AppColors.statusCancelled;
      case OrderStatus.refunded:     return AppColors.statusRefunded;
    }
  }

  Color get bgColor => color.withValues(alpha:0.10);
  Color get borderColor => color.withValues(alpha:0.30);

  IconData get icon {
    switch (this) {
      case OrderStatus.pending:      return Icons.schedule_rounded;
      case OrderStatus.confirmed:    return Icons.verified_rounded;
      case OrderStatus.processing:   return Icons.inventory_2_rounded;
      case OrderStatus.shipped:      return Icons.local_shipping_rounded;
      case OrderStatus.delivered:    return Icons.check_circle_rounded;
      case OrderStatus.cancelled:    return Icons.cancel_rounded;
      case OrderStatus.refunded:     return Icons.currency_exchange_rounded;
    }
  }

  /// 0=Received, 1=Confirmed, 2=Packing, 3=Shipped, 4=Delivered
  /// Returns -1 for cancelled/refunded (terminal non-delivery)
  int get fulfillmentStep {
    switch (this) {
      case OrderStatus.pending:      return 0;
      case OrderStatus.confirmed:    return 1;
      case OrderStatus.processing:   return 2;
      case OrderStatus.shipped:      return 3;
      case OrderStatus.delivered:    return 4;
      default:                       return -1;
    }
  }
}

// ─── OrderStatusEvent ────────────────────────────────────────────────────────

class OrderStatusEvent {
  final OrderStatus status;
  final DateTime timestamp;
  final String? note;

  const OrderStatusEvent({
    required this.status,
    required this.timestamp,
    this.note,
  });

  factory OrderStatusEvent.fromJson(Map<String, dynamic> json) {
    return OrderStatusEvent(
      status: OrderStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String).toLowerCase(),
        orElse: () => OrderStatus.pending,
      ),
      timestamp: DateTime.parse(json['timestamp'] as String),
      note: json['note'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'status': status.name,
        'timestamp': timestamp.toIso8601String(),
        if (note != null) 'note': note,
      };
}

// ─── OrderItem ────────────────────────────────────────────────────────────────

class OrderItem {
  final String id;
  final String name;
  final String? imageUrl;
  final int quantity;
  final double unitPrice;
  final String? variantLabel;
  final String? sku;

  const OrderItem({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.quantity,
    required this.unitPrice,
    this.variantLabel,
    this.sku,
  });

  double get subtotal => unitPrice * quantity;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id']?.toString() ?? '',
      name: json['name'] as String? ?? 'Item',
      imageUrl: json['image_url'] as String?,
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      variantLabel: json['variant_label'] as String?,
      sku: json['sku'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        if (imageUrl != null) 'image_url': imageUrl,
        'quantity': quantity,
        'unit_price': unitPrice,
        if (variantLabel != null) 'variant_label': variantLabel,
        if (sku != null) 'sku': sku,
      };
}

// ─── OrderAddress ─────────────────────────────────────────────────────────────

class OrderAddress {
  final String name;
  final String phone;
  final String addressLine;
  final String city;

  const OrderAddress({
    required this.name,
    required this.phone,
    required this.addressLine,
    required this.city,
  });

  factory OrderAddress.fromJson(Map<String, dynamic> json) {
    return OrderAddress(
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      addressLine: json['address_line'] as String? ?? json['addressLine'] as String? ?? '',
      city: json['city'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'phone': phone,
        'address_line': addressLine,
        'city': city,
      };
}

// ─── Order ────────────────────────────────────────────────────────────────────

class Order {
  final String id;
  final String referenceNumber;
  final DateTime placedAt;
  final OrderStatus status;
  final List<OrderItem> items;
  final OrderAddress deliveryAddress;
  final double subtotal;
  final double deliveryFee;
  final double discount;
  final String storeName;
  final String? storeCity;
  final String? storeContact;
  final String? estimatedDelivery;
  final List<OrderStatusEvent> statusHistory;

  Order({
    required this.id,
    required this.referenceNumber,
    required this.placedAt,
    required this.status,
    required this.items,
    required this.deliveryAddress,
    required this.subtotal,
    required this.deliveryFee,
    this.discount = 0,
    required this.storeName,
    this.storeCity,
    this.storeContact,
    this.estimatedDelivery,
    this.statusHistory = const [],
  });

  double get total => subtotal + deliveryFee - discount;
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id']?.toString() ?? '',
      referenceNumber: json['reference_number']?.toString() ?? json['id']?.toString() ?? '',
      placedAt: json['placed_at'] != null
          ? (DateTime.tryParse(json['placed_at'] as String) ?? DateTime.now())
          : DateTime.now(),
      status: OrderStatus.values.firstWhere(
        (s) => s.name.toLowerCase() == (json['status'] as String? ?? 'pending').toLowerCase(),
        orElse: () => OrderStatus.pending,
      ),
      items: (json['items'] as List? ?? [])
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      deliveryAddress: json['delivery_address'] != null
          ? OrderAddress.fromJson(
              json['delivery_address'] as Map<String, dynamic>)
          : const OrderAddress(name: '', phone: '', addressLine: '', city: ''),
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      deliveryFee: (json['delivery_fee'] as num?)?.toDouble() ?? 0.0,
      discount: (json['discount'] as num?)?.toDouble() ?? 0.0,
      storeName: json['store_name'] as String? ?? 'SoftStore Partner Store',
      storeCity: json['store_city'] as String?,
      storeContact: json['store_contact'] as String?,
      estimatedDelivery: json['estimated_delivery'] as String?,
      statusHistory: (json['status_history'] as List? ?? [])
          .map((e) => OrderStatusEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  Order copyWith({
    String? id,
    String? referenceNumber,
    DateTime? placedAt,
    OrderStatus? status,
    List<OrderItem>? items,
    OrderAddress? deliveryAddress,
    double? subtotal,
    double? deliveryFee,
    double? discount,
    String? storeName,
    String? storeCity,
    String? storeContact,
    String? estimatedDelivery,
    List<OrderStatusEvent>? statusHistory,
  }) {
    return Order(
      id: id ?? this.id,
      referenceNumber: referenceNumber ?? this.referenceNumber,
      placedAt: placedAt ?? this.placedAt,
      status: status ?? this.status,
      items: items ?? this.items,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      storeName: storeName ?? this.storeName,
      storeCity: storeCity ?? this.storeCity,
      storeContact: storeContact ?? this.storeContact,
      estimatedDelivery: estimatedDelivery ?? this.estimatedDelivery,
      statusHistory: statusHistory ?? this.statusHistory,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'reference_number': referenceNumber,
        'placed_at': placedAt.toIso8601String(),
        'status': status.name,
        'items': items.map((e) => e.toJson()).toList(),
        'delivery_address': deliveryAddress.toJson(),
        'subtotal': subtotal,
        'delivery_fee': deliveryFee,
        'discount': discount,
        'store_name': storeName,
        if (storeCity != null) 'store_city': storeCity,
        if (storeContact != null) 'store_contact': storeContact,
        if (estimatedDelivery != null) 'estimated_delivery': estimatedDelivery,
        'status_history': statusHistory.map((e) => e.toJson()).toList(),
      };
}

// ─── Cancellation Reasons ─────────────────────────────────────────────────────

const List<String> cancellationReasons = [
  'Shipping cost is too high',
  'Delivery time is too long',
  'Decided for alternative product',
  'Duplicate order',
  'Want to place a new order with more/different items',
  'Seller asked me to cancel / informed that item is out of stock',
  'Change of Delivery Address',
  'Forgot to use voucher/voucher issue',
  'Don\'t want this order/item anymore',
  'Found cheaper elsewhere',
  'Change payment method',
];
