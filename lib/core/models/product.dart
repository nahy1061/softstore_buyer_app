class ProductPricing {
  final double unitPrice;
  final double listPrice;
  final double taxRate;
  final double unitTax;
  final double displayPrice;
  final double displayList;
  final bool hasDiscount;
  final double discountPercent;
  final String source;
  final int? dealProductId;

  const ProductPricing({
    required this.unitPrice,
    required this.listPrice,
    this.taxRate = 0,
    this.unitTax = 0,
    required this.displayPrice,
    required this.displayList,
    required this.hasDiscount,
    required this.discountPercent,
    this.source = 'selling_price',
    this.dealProductId,
  });

  factory ProductPricing.fromJson(Map<String, dynamic> j) => ProductPricing(
        unitPrice: _loose(j['unit_price']),
        listPrice: _loose(j['list_price']),
        taxRate: _loose(j['tax_rate']),
        unitTax: _loose(j['unit_tax']),
        displayPrice: _loose(j['display_price']),
        displayList: _loose(j['display_list']),
        hasDiscount: j['has_discount'] == true || j['has_discount'] == 1,
        discountPercent: _loose(j['discount_percent']),
        source: j['source'] as String? ?? 'selling_price',
        dealProductId: j['deal_product_id'] as int?,
      );
}

class Product {
  final int id;
  final int tenantId;
  final String productName;
  final String? slug;
  final String? sku;
  final String? description;
  double sellingPrice;
  double? marketplacePrice;
  double stockQuantity;
  final bool? isAgeRestricted;
  final String? imageUrl;
  double? avgRating;
  final int? reviewCount;
  final String? categoryName;
  final String? categorySlug;
  final String? sellerName;
  final String? sellerSlug;
  final String? sellerCity;
  final String? sellerWhatsapp;
  ProductPricing? pricing;
  bool? isWishlisted;

  Product({
    required this.id,
    this.tenantId = 0,
    required this.productName,
    this.slug,
    this.sku,
    this.description,
    required this.sellingPrice,
    this.marketplacePrice,
    this.stockQuantity = 1,
    this.isAgeRestricted,
    this.imageUrl,
    this.avgRating,
    this.reviewCount,
    this.categoryName,
    this.categorySlug,
    this.sellerName,
    this.sellerSlug,
    this.sellerCity,
    this.sellerWhatsapp,
    this.pricing,
    this.isWishlisted,
  });

  bool get inStock => stockQuantity > 0;

  double get displayPrice => pricing?.displayPrice ?? sellingPrice;
  double get displayListPrice => pricing?.displayList ?? marketplacePrice ?? sellingPrice;
  bool get hasDiscount => pricing?.hasDiscount ?? false;
  double get discountPercent => pricing?.discountPercent ?? 0;

  factory Product.fromJson(Map<String, dynamic> j) => Product(
        id: j['id'] as int,
        tenantId: j['tenant_id'] as int? ?? 0,
        productName: j['product_name'] as String? ?? '',
        slug: j['slug'] as String?,
        sku: j['sku'] as String?,
        description: j['description'] as String?,
        sellingPrice: _loose(j['selling_price']),
        marketplacePrice: j['marketplace_price'] != null ? _loose(j['marketplace_price']) : null,
        stockQuantity: _loose(j['stock_quantity']),
        isAgeRestricted: j['is_age_restricted'] == true || j['is_age_restricted'] == 1,
        imageUrl: j['image_url'] as String?,
        avgRating: j['avg_rating'] != null ? _loose(j['avg_rating']) : null,
        reviewCount: j['review_count'] as int?,
        categoryName: j['category_name'] as String?,
        categorySlug: j['category_slug'] as String?,
        sellerName: j['seller_name'] as String?,
        sellerSlug: j['seller_slug'] as String?,
        sellerCity: j['seller_city'] as String?,
        sellerWhatsapp: j['seller_whatsapp'] as String?,
        pricing: j['pricing'] != null ? ProductPricing.fromJson(j['pricing'] as Map<String, dynamic>) : null,
        isWishlisted: j['is_wishlisted'] == true || j['is_wishlisted'] == 1,
      );

  Product copyWith({bool? isWishlisted, ProductPricing? pricing}) => Product(
        id: id,
        tenantId: tenantId,
        productName: productName,
        slug: slug,
        sku: sku,
        description: description,
        sellingPrice: sellingPrice,
        marketplacePrice: marketplacePrice,
        stockQuantity: stockQuantity,
        isAgeRestricted: isAgeRestricted,
        imageUrl: imageUrl,
        avgRating: avgRating,
        reviewCount: reviewCount,
        categoryName: categoryName,
        categorySlug: categorySlug,
        sellerName: sellerName,
        sellerSlug: sellerSlug,
        sellerCity: sellerCity,
        sellerWhatsapp: sellerWhatsapp,
        pricing: pricing ?? this.pricing,
        isWishlisted: isWishlisted ?? this.isWishlisted,
      );
}

class ProductVariant {
  final int id;
  final int productId;
  final String? name;
  final String? sku;
  final double? sellingPrice;
  final double? stockQuantity;
  final Map<String, String>? attributes;
  final bool? isActive;

  const ProductVariant({
    required this.id,
    required this.productId,
    this.name,
    this.sku,
    this.sellingPrice,
    this.stockQuantity,
    this.attributes,
    this.isActive,
  });

  factory ProductVariant.fromJson(Map<String, dynamic> j) => ProductVariant(
        id: j['id'] as int,
        productId: j['product_id'] as int? ?? 0,
        name: j['name'] as String?,
        sku: j['sku'] as String?,
        sellingPrice: j['selling_price'] != null ? _loose(j['selling_price']) : null,
        stockQuantity: j['stock_quantity'] != null ? _loose(j['stock_quantity']) : null,
        isActive: j['is_active'] == true || j['is_active'] == 1,
      );

  bool get inStock => (stockQuantity ?? 1) > 0;
}

class ProductReview {
  final int id;
  final int rating;
  final String? title;
  final String? reviewText;
  final bool? isVerifiedPurchase;
  final String? firstName;
  final String? lastName;
  final String? createdAt;

  const ProductReview({
    required this.id,
    required this.rating,
    this.title,
    this.reviewText,
    this.isVerifiedPurchase,
    this.firstName,
    this.lastName,
    this.createdAt,
  });

  String get reviewerName {
    final parts = [firstName, lastName].where((p) => p != null && p.isNotEmpty);
    return parts.join(' ').trim().isEmpty ? 'Anonymous' : parts.join(' ');
  }
}

class MarketplaceCategory {
  final int id;
  final String categoryName;
  final String slug;
  final int? prodCount;
  final double? minPrice;
  final String? sampleImage;

  const MarketplaceCategory({
    required this.id,
    required this.categoryName,
    required this.slug,
    this.prodCount,
    this.minPrice,
    this.sampleImage,
  });

  factory MarketplaceCategory.fromJson(Map<String, dynamic> j) => MarketplaceCategory(
        id: j['id'] as int,
        categoryName: j['category_name'] as String? ?? '',
        slug: j['slug'] as String? ?? '',
        prodCount: j['prod_count'] as int?,
        minPrice: j['min_price'] != null ? _loose(j['min_price']) : null,
        sampleImage: j['sample_image'] as String?,
      );
}

double _loose(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}
