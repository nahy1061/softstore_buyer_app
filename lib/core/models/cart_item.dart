class CartItem {
  final int productId;
  final int? variantId;
  int quantity;
  final String productName;
  final String? imageUrl;
  final double unitPriceSnapshot;
  final String? variantLabel;
  final bool isAgeRestricted;

  CartItem({
    required this.productId,
    this.variantId,
    this.quantity = 1,
    required this.productName,
    this.imageUrl,
    required this.unitPriceSnapshot,
    this.variantLabel,
    this.isAgeRestricted = false,
  });

  String get id => variantId != null ? '$productId-$variantId' : '$productId';
  double get lineTotal => unitPriceSnapshot * quantity;

  Map<String, dynamic> toJson() => {
        'product_id': productId,
        'variant_id': variantId,
        'quantity': quantity,
        'product_name': productName,
        'image_url': imageUrl,
        'unit_price_snapshot': unitPriceSnapshot,
        'variant_label': variantLabel,
        'is_age_restricted': isAgeRestricted,
      };

  factory CartItem.fromJson(Map<String, dynamic> j) => CartItem(
        productId: j['product_id'] as int,
        variantId: j['variant_id'] as int?,
        quantity: j['quantity'] as int? ?? 1,
        productName: j['product_name'] as String? ?? '',
        imageUrl: j['image_url'] as String?,
        unitPriceSnapshot: (j['unit_price_snapshot'] as num?)?.toDouble() ?? 0.0,
        variantLabel: j['variant_label'] as String?,
        isAgeRestricted: j['is_age_restricted'] == true,
      );
}
