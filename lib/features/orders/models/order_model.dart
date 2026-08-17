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
      id: json['id'] as String,
      name: json['name'] as String,
      imageUrl: json['image_url'] as String?,
      quantity: json['quantity'] as int,
      unitPrice: (json['unit_price'] as num).toDouble(),
      variantLabel: json['variant_label'] as String?,
      sku: json['sku'] as String?,
    );
  }
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
      name: json['name'] as String,
      phone: json['phone'] as String,
      addressLine: json['address_line'] as String,
      city: json['city'] as String,
    );
  }
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
      id: json['id'] as String,
      referenceNumber: json['reference_number'] as String,
      placedAt: DateTime.parse(json['placed_at'] as String),
      status: OrderStatus.values.firstWhere(
        (s) => s.name == (json['status'] as String).toLowerCase(),
        orElse: () => OrderStatus.pending,
      ),
      items: (json['items'] as List)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      deliveryAddress: OrderAddress.fromJson(
          json['delivery_address'] as Map<String, dynamic>),
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['delivery_fee'] as num).toDouble(),
      discount: (json['discount'] as num?)?.toDouble() ?? 0,
      storeName: json['store_name'] as String,
      storeCity: json['store_city'] as String?,
      storeContact: json['store_contact'] as String?,
      estimatedDelivery: json['estimated_delivery'] as String?,
      statusHistory: (json['status_history'] as List? ?? [])
          .map((e) => OrderStatusEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
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

// ─── Dummy data for UI preview ────────────────────────────────────────────────

final List<Order> dummyOrders = [
  Order(
    id: '1',
    referenceNumber: 'SS-20260817-0001',
    placedAt: DateTime(2026, 8, 17, 13, 9),
    status: OrderStatus.pending,
    storeName: 'SoftStore General',
    storeCity: 'Islamabad',
    storeContact: '03001234567',
    estimatedDelivery: 'Expected Aug 20',
    subtotal: 400,
    deliveryFee: 0,
    discount: 0,
    deliveryAddress: const OrderAddress(
      name: 'Naheed',
      phone: '+92 312 1234567',
      addressLine: 'House 12, Street 5, G-10/4',
      city: 'Islamabad',
    ),
    items: const [
      OrderItem(
        id: 'i1',
        name: 'FF6F00',
        quantity: 1,
        unitPrice: 400,
        imageUrl: 'https://via.placeholder.com/112/FF6F00/FFFFFF?text=Coke',
        sku: 'SKU-01-FF6F00',
      ),
    ],
    statusHistory: [
      OrderStatusEvent(
        status: OrderStatus.pending,
        timestamp: DateTime(2026, 8, 17, 13, 9),
        note: 'Order placed by customer',
      ),
    ],
  ),
  Order(
    id: '2',
    referenceNumber: 'SS-20260812-0002',
    placedAt: DateTime(2026, 8, 12, 17, 1),
    status: OrderStatus.pending,
    storeName: 'SoftStore General',
    storeCity: 'Islamabad',
    storeContact: '03001234567',
    estimatedDelivery: 'Expected Aug 15',
    subtotal: 950,
    deliveryFee: 0,
    discount: 0,
    deliveryAddress: const OrderAddress(
      name: 'Naheed',
      phone: '+92 312 1234567',
      addressLine: 'House 12, Street 5, G-10/4',
      city: 'Islamabad',
    ),
    items: const [
      OrderItem(
        id: 'i2',
        name: 'FF6F00',
        quantity: 1,
        unitPrice: 950,
        imageUrl: 'https://via.placeholder.com/112/FF6F00/FFFFFF?text=Coke',
        sku: 'SKU-02-FF6F00',
      ),
    ],
    statusHistory: [
      OrderStatusEvent(
        status: OrderStatus.pending,
        timestamp: DateTime(2026, 8, 12, 17, 1),
        note: 'Order placed by customer',
      ),
    ],
  ),
  Order(
    id: '3',
    referenceNumber: 'SS-20240810-0203',
    placedAt: DateTime(2024, 8, 10, 16, 45),
    status: OrderStatus.delivered,
    storeName: 'Fresh Dairy Direct',
    storeCity: 'Islamabad',
    storeContact: '03451234567',
    estimatedDelivery: 'Delivered on Aug 13',
    subtotal: 960,
    deliveryFee: 100,
    deliveryAddress: const OrderAddress(
      name: 'Munaza Khan',
      phone: '+92 312 1234567',
      addressLine: 'House 12, Street 5, G-10/4',
      city: 'Islamabad',
    ),
    items: const [
      OrderItem(
        id: 'i5',
        name: 'Farm Fresh Eggs (30pcs)',
        quantity: 1,
        unitPrice: 480,
        sku: 'SKU-03-EGG30',
      ),
      OrderItem(
        id: 'i6',
        name: 'Full Cream Milk 1L',
        quantity: 4,
        unitPrice: 120,
        sku: 'SKU-03-MILK1L',
      ),
    ],
    statusHistory: [
      OrderStatusEvent(
        status: OrderStatus.pending,
        timestamp: DateTime(2024, 8, 10, 16, 45),
        note: 'Order placed by customer',
      ),
      OrderStatusEvent(
        status: OrderStatus.processing,
        timestamp: DateTime(2024, 8, 10, 18, 0),
        note: 'Seller confirmed and is packing',
      ),
      OrderStatusEvent(
        status: OrderStatus.delivered,
        timestamp: DateTime(2024, 8, 13, 14, 0),
        note: 'Delivered to customer',
      ),
    ],
  ),
  Order(
    id: '4',
    referenceNumber: 'SS-20240805-0088',
    placedAt: DateTime(2024, 8, 5, 9, 15),
    status: OrderStatus.cancelled,
    storeName: 'HomeStyle Household',
    storeCity: 'Lahore',
    subtotal: 550,
    deliveryFee: 120,
    deliveryAddress: const OrderAddress(
      name: 'Munaza Khan',
      phone: '+92 312 1234567',
      addressLine: 'House 12, Street 5, G-10/4',
      city: 'Islamabad',
    ),
    items: const [
      OrderItem(
        id: 'i7',
        name: 'Surf Excel Bar Soap Pack x6',
        quantity: 1,
        unitPrice: 550,
        sku: 'SKU-04-SE6PK',
      ),
    ],
    statusHistory: [
      OrderStatusEvent(
        status: OrderStatus.pending,
        timestamp: DateTime(2024, 8, 5, 9, 15),
        note: 'Order placed by customer',
      ),
      OrderStatusEvent(
        status: OrderStatus.cancelled,
        timestamp: DateTime(2024, 8, 5, 11, 0),
        note: 'Cancelled by customer request',
      ),
    ],
  ),
];
