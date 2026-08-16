class Store {
  final int id;
  final String businessName;
  final String slug;
  final String? city;
  final String? address;
  final double? storeRating;
  final int? totalReviews;
  final int? productCount;

  const Store({
    required this.id,
    required this.businessName,
    required this.slug,
    this.city,
    this.address,
    this.storeRating,
    this.totalReviews,
    this.productCount,
  });

  factory Store.fromJson(Map<String, dynamic> j) => Store(
        id: j['id'] as int? ?? 0,
        businessName: j['business_name'] as String? ?? '',
        slug: j['slug'] as String? ?? '',
        city: j['city'] as String?,
        address: j['address'] as String?,
        storeRating: j['store_rating'] != null
            ? (j['store_rating'] is num
                ? (j['store_rating'] as num).toDouble()
                : double.tryParse(j['store_rating'].toString()))
            : null,
        totalReviews: j['total_reviews'] as int?,
        productCount: j['product_count'] as int?,
      );
}

