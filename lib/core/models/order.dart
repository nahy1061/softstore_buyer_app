enum OrderStatus {
  pending,
  confirmed,
  processing,
  shipped,
  delivered,
  cancelled,
  deliveryFailed,
  refunded;

  static OrderStatus fromString(String s) {
    final normalized = s.toLowerCase().trim().replaceAll(' ', '_');
    return OrderStatus.values.firstWhere(
      (e) => e.name == normalized || e.name.replaceAll('_', '') == normalized.replaceAll('_', ''),
      orElse: () => OrderStatus.pending,
    );
  }

  String get label {
    switch (this) {
      case OrderStatus.deliveryFailed: return 'Delivery Failed';
      default: return name[0].toUpperCase() + name.substring(1);
    }
  }

  bool get isActive => this != OrderStatus.cancelled && this != OrderStatus.deliveryFailed && this != OrderStatus.refunded;
}

class SaleItem {
  final int id;
  final int saleId;
  final int productId;
  final String productName;
  final String? sku;
  final String? imageUrl;
  final double unitPrice;
  final double quantity;
  final double subtotal;
  final double taxAmount;
  final double totalAmount;

  const SaleItem({
    required this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    this.sku,
    this.imageUrl,
    required this.unitPrice,
    required this.quantity,
    required this.subtotal,
    this.taxAmount = 0,
    required this.totalAmount,
  });

  factory SaleItem.fromJson(Map<String, dynamic> j) => SaleItem(
        id: j['id'] as int? ?? 0,
        saleId: j['sale_id'] as int? ?? 0,
        productId: j['product_id'] as int? ?? 0,
        productName: j['product_name'] as String? ?? '',
        sku: j['sku'] as String?,
        imageUrl: j['image_url'] as String?,
        unitPrice: _loose(j['unit_price']),
        quantity: _loose(j['quantity']),
        subtotal: _loose(j['subtotal']),
        taxAmount: _loose(j['tax_amount']),
        totalAmount: _loose(j['total_amount']),
      );
}

class Order {
  final int id;
  final int tenantId;
  final String invoiceNumber;
  final double subtotal;
  final double taxAmount;
  final double discountAmount;
  final double deliveryFee;
  final double grandTotal;
  final OrderStatus saleStatus;
  final String? businessName;
  final String? customerName;
  final String? customerAddress;
  final String? customerPhone;
  final String createdAt;
  final int? itemsCount;
  final List<SaleItem>? items;

  const Order({
    required this.id,
    this.tenantId = 0,
    required this.invoiceNumber,
    required this.subtotal,
    this.taxAmount = 0,
    this.discountAmount = 0,
    this.deliveryFee = 0,
    required this.grandTotal,
    required this.saleStatus,
    this.businessName,
    this.customerName,
    this.customerAddress,
    this.customerPhone,
    required this.createdAt,
    this.itemsCount,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> j) => Order(
        id: j['id'] as int,
        tenantId: j['tenant_id'] as int? ?? 0,
        invoiceNumber: j['invoice_number'] as String? ?? '#${j['id']}',
        subtotal: _loose(j['subtotal']),
        taxAmount: _loose(j['tax_amount']),
        discountAmount: _loose(j['discount_amount']),
        deliveryFee: _loose(j['delivery_fee']),
        grandTotal: _loose(j['grand_total']),
        saleStatus: OrderStatus.fromString(j['sale_status'] as String? ?? 'pending'),
        businessName: j['business_name'] as String?,
        customerName: j['customer_name'] as String?,
        customerAddress: j['customer_address'] as String?,
        customerPhone: j['customer_phone'] as String?,
        createdAt: j['created_at'] as String? ?? '',
        itemsCount: j['items_count'] as int?,
        items: (j['items'] as List?)?.map((i) => SaleItem.fromJson(i as Map<String, dynamic>)).toList(),
      );
}

class OrderHistoryPage {
  final List<Order> orders;
  final int total;
  final int page;
  final int perPage;
  final int totalPages;

  const OrderHistoryPage({
    required this.orders,
    required this.total,
    required this.page,
    this.perPage = 10,
    required this.totalPages,
  });
}

class OrderStatusEvent {
  final int id;
  final int saleId;
  final OrderStatus newStatus;
  final String? notes;
  final String createdAt;

  const OrderStatusEvent({
    required this.id,
    required this.saleId,
    required this.newStatus,
    this.notes,
    required this.createdAt,
  });
}

class ReturnRequest {
  final int id;
  final String status;
  final String? reason;
  final String? returnType;
  final String? createdAt;

  const ReturnRequest({
    required this.id,
    required this.status,
    this.reason,
    this.returnType,
    this.createdAt,
  });
}

class ReturnEligibility {
  final bool eligible;
  final String? reason;
  final ReturnRequest? existing;

  const ReturnEligibility({required this.eligible, this.reason, this.existing});
}

class OrderDetailResponse {
  final Order order;
  final List<OrderStatusEvent> statusHistory;
  final ReturnEligibility returnEligibility;

  const OrderDetailResponse({
    required this.order,
    required this.statusHistory,
    required this.returnEligibility,
  });
}

class TrackOrderResponse {
  final Order order;
  final List<SaleItem> items;
  final List<OrderStatusEvent> statusHistory;

  const TrackOrderResponse({
    required this.order,
    required this.items,
    required this.statusHistory,
  });
}

double _loose(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}
