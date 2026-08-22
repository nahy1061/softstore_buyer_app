import 'package:equatable/equatable.dart';

// ─── Category ────────────────────────────────────────────────────────────────

class Category extends Equatable {
  final String name;
  final String slug;
  final String? imageUrl;
  final int? productCount;

  const Category({
    required this.name,
    required this.slug,
    this.imageUrl,
    this.productCount,
  });

  @override
  List<Object?> get props => [slug];
}

// ─── Seller (stub) ────────────────────────────────────────────────────────────

class SellerStub extends Equatable {
  final int? id;
  final String name;
  final String slug;

  const SellerStub({this.id, required this.name, required this.slug});

  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'slug': slug,
  };

  factory SellerStub.fromJson(Map<String, dynamic> json) => SellerStub(
    id: (json['id'] as num?)?.toInt() ??
        (json['seller_id'] as num?)?.toInt() ??
        (json['store_id'] as num?)?.toInt() ??
        (json['tenant_id'] as num?)?.toInt(),
    name: json['name'] as String? ??
        json['seller_name'] as String? ??
        json['store_name'] as String? ??
        '',
    slug: json['slug'] as String? ??
        json['seller_slug'] as String? ??
        json['store_slug'] as String? ??
        '',
  );

  @override
  List<Object?> get props => [id, slug, name];
}

// ─── Product (list item) ─────────────────────────────────────────────────────

class Product extends Equatable {
  final int id;
  final String name;
  final String slug;
  final String? imageUrl;
  final double displayPrice;
  final double? listPrice;
  final double? discountPercent;
  final bool inStock;
  final SellerStub? seller;

  const Product({
    required this.id,
    required this.name,
    required this.slug,
    this.imageUrl,
    required this.displayPrice,
    this.listPrice,
    this.discountPercent,
    this.inStock = true,
    this.seller,
  });

  /// Store/Seller convenience getters
  int? get storeId => seller?.id;
  int? get sellerId => seller?.id;
  String? get storeSlug => seller?.slug;
  String? get sellerSlug => seller?.slug;
  String? get storeName => seller?.name;
  String? get sellerName => seller?.name;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'slug': slug,
    'imageUrl': imageUrl,
    'displayPrice': displayPrice,
    'listPrice': listPrice,
    'discountPercent': discountPercent,
    'inStock': inStock,
    if (seller != null) ...{
      'seller_id': seller!.id,
      'seller_name': seller!.name,
      'seller_slug': seller!.slug,
      'seller': seller!.toJson(),
    },
  };

  factory Product.fromJson(Map<String, dynamic> json) {
    SellerStub? parsedSeller;
    if (json['seller'] is Map<String, dynamic>) {
      parsedSeller =
          SellerStub.fromJson(json['seller'] as Map<String, dynamic>);
    } else if (json['seller'] is String &&
        (json['seller'] as String).isNotEmpty) {
      final sName = json['seller'] as String;
      parsedSeller = SellerStub(
        name: sName,
        slug: sName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-'),
      );
    } else if (json['seller_name'] != null ||
        json['seller_slug'] != null ||
        json['store_name'] != null ||
        json['store_slug'] != null ||
        json['seller_id'] != null ||
        json['store_id'] != null ||
        json['tenant_id'] != null) {
      final sName = json['seller_name']?.toString() ??
          json['store_name']?.toString() ??
          json['vendor_name']?.toString() ??
          '';
      final sSlug = json['seller_slug']?.toString() ??
          json['store_slug']?.toString() ??
          (sName.isNotEmpty
              ? sName.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')
              : '');
      final sId = (json['seller_id'] as num?)?.toInt() ??
          (json['store_id'] as num?)?.toInt() ??
          (json['tenant_id'] as num?)?.toInt();
      if (sName.isNotEmpty || sSlug.isNotEmpty || sId != null) {
        parsedSeller = SellerStub(
          id: sId,
          name: sName.isNotEmpty
              ? sName
              : (sSlug.isNotEmpty ? sSlug : 'Store'),
          slug: sSlug.isNotEmpty
              ? sSlug
              : (sId != null ? 'store-$sId' : 'store'),
        );
      }
    }

    final rawId = json['id'];
    final id = rawId is num
        ? rawId.toInt()
        : (int.tryParse(rawId?.toString() ?? '') ?? 0);

    final rawDisplayPrice =
        json['displayPrice'] ?? json['selling_price'] ?? json['price'];
    final displayPrice = rawDisplayPrice is num
        ? rawDisplayPrice.toDouble()
        : (double.tryParse(rawDisplayPrice?.toString() ?? '') ?? 0.0);

    final rawListPrice = json['listPrice'] ?? json['original_price'];
    final listPrice = rawListPrice is num
        ? rawListPrice.toDouble()
        : double.tryParse(rawListPrice?.toString() ?? '');

    final rawDiscount = json['discountPercent'];
    final discountPercent = rawDiscount is num
        ? rawDiscount.toDouble()
        : double.tryParse(rawDiscount?.toString() ?? '');

    return Product(
      id: id,
      name: json['name'] as String? ?? json['product_name'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? json['image_url'] as String?,
      displayPrice: displayPrice,
      listPrice: listPrice,
      discountPercent: discountPercent,
      inStock: json['inStock'] as bool? ?? true,
      seller: parsedSeller,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? slug,
    String? imageUrl,
    double? displayPrice,
    double? listPrice,
    double? discountPercent,
    bool? inStock,
    SellerStub? seller,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      imageUrl: imageUrl ?? this.imageUrl,
      displayPrice: displayPrice ?? this.displayPrice,
      listPrice: listPrice ?? this.listPrice,
      discountPercent: discountPercent ?? this.discountPercent,
      inStock: inStock ?? this.inStock,
      seller: seller ?? this.seller,
    );
  }

  @override
  List<Object?> get props => [id, slug, seller];
}

// ─── Variant ─────────────────────────────────────────────────────────────────

class Variant extends Equatable {
  final int id;
  final String label;
  final double? priceAdjustment;

  const Variant({
    required this.id,
    required this.label,
    this.priceAdjustment,
  });

  @override
  List<Object?> get props => [id];
}

// ─── Specification ────────────────────────────────────────────────────────────

class Specification extends Equatable {
  final String label;
  final String value;

  const Specification({required this.label, required this.value});

  @override
  List<Object?> get props => [label, value];
}

// ─── Product Review ─────────────────────────────────────────────────────────

class ProductReview extends Equatable {
  final String reviewer;
  final int rating;
  final String text;
  final String? date;
  final List<String> images;

  const ProductReview({
    required this.reviewer,
    required this.rating,
    required this.text,
    this.date,
    this.images = const [],
  });

  @override
  List<Object?> get props => [reviewer, rating, text, date];
}

// ─── ProductDetail ────────────────────────────────────────────────────────────

class ProductDetail extends Equatable {
  final int id;
  final String name;
  final String slug;
  final String? description;
  final List<String> images;
  final double displayPrice;
  final double? listPrice;
  final double? discountPercent;
  final List<Variant> variants;
  final bool inStock;
  final int? stockQuantity; // 9999 = unknown (sentinel)
  final SellerStub? seller;
  final List<Specification> specifications;
  final double rating;
  final int ratingCount;
  final List<ProductReview> reviews;
  final List<Product> relatedProducts;
  final String? category;
  final String? categorySlug;

  const ProductDetail({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    this.images = const [],
    required this.displayPrice,
    this.listPrice,
    this.discountPercent,
    this.variants = const [],
    this.inStock = true,
    this.stockQuantity,
    this.seller,
    this.specifications = const [],
    this.rating = 4.5,
    this.ratingCount = 0,
    this.reviews = const [],
    this.relatedProducts = const [],
    this.category,
    this.categorySlug,
  });

  /// True if stock is known and limited
  bool get hasKnownStock =>
      stockQuantity != null && stockQuantity != 9999;

  /// Store/Seller convenience getters
  int? get storeId => seller?.id;
  int? get sellerId => seller?.id;
  String? get storeSlug => seller?.slug;
  String? get sellerSlug => seller?.slug;
  String? get storeName => seller?.name;
  String? get sellerName => seller?.name;

  @override
  List<Object?> get props => [id, slug];
}

// ─── Seller Profile ───────────────────────────────────────────────────────────

class SellerProfile extends Equatable {
  final int? id;
  final String name;
  final String slug;
  final String? description;
  final String? logoUrl;
  final String? bannerUrl;
  final double? rating;
  final int? ratingCount;
  final List<Product> products;
  final List<Category> categories;

  const SellerProfile({
    this.id,
    required this.name,
    required this.slug,
    this.description,
    this.logoUrl,
    this.bannerUrl,
    this.rating,
    this.ratingCount,
    this.products = const [],
    this.categories = const [],
  });

  @override
  List<Object?> get props => [id, slug];
}

// ─── HomepageData ─────────────────────────────────────────────────────────────

class HomepageData {
  final List<Product> heroBanners;
  final List<Category> categories;
  final List<Product> topDeals;
  final List<Product> featuredProducts;

  const HomepageData({
    this.heroBanners = const [],
    this.categories = const [],
    this.topDeals = const [],
    this.featuredProducts = const [],
  });
}

// ─── SearchResult ─────────────────────────────────────────────────────────────

class SearchResult {
  final List<Product> products;
  final int? totalCount;
  final bool hasNextPage;

  const SearchResult({
    this.products = const [],
    this.totalCount,
    this.hasNextPage = false,
  });
}
