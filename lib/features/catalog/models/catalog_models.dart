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

  @override
  List<Object?> get props => [id, slug];
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

  @override
  List<Object?> get props => [id, slug];
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
