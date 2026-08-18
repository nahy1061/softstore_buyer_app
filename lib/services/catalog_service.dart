import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../core/networking/web_session_client.dart';
import '../core/models/product.dart';
import '../core/models/store.dart';
import '../core/constants/app_constants.dart';

class SearchSuggestResponse {
  final List<SuggestProduct> products;
  final List<MarketplaceCategory> categories;
  const SearchSuggestResponse({required this.products, required this.categories});
}

class SuggestProduct {
  final int id;
  final String productName;
  final String? imageUrl;
  final String? slug;
  final String? sellerName;
  final double sellingPrice;
  const SuggestProduct({
    required this.id,
    required this.productName,
    this.imageUrl,
    this.slug,
    this.sellerName,
    required this.sellingPrice,
  });
  factory SuggestProduct.fromJson(Map<String, dynamic> j) => SuggestProduct(
        id: j['id'] as int,
        productName: j['product_name'] as String? ?? '',
        imageUrl: j['image_url'] as String?,
        slug: j['slug'] as String?,
        sellerName: j['seller_name'] as String?,
        sellingPrice: _loose(j['selling_price']),
      );
}

class HomeResponse {
  final List<MarketplaceCategory> categories;
  List<Product> featured;
  final List<HeroCategory> heroCategories;
  final bool heroRankedBySales;
  final List<Store> stores;

  HomeResponse({
    required this.categories,
    required this.featured,
    required this.heroCategories,
    this.heroRankedBySales = false,
    this.stores = const [],
  });

  List<Product> get topDeals {
    final seen = <int>{};
    final all = [...featured, ...heroCategories.expand((c) => c.products)];
    final deals = all
        .where((p) => (p.pricing?.hasDiscount ?? false) && (p.pricing?.discountPercent ?? 0) > 0)
        .where((p) => seen.add(p.id))
        .toList();
    deals.sort((a, b) {
      final ia = a.imageUrl != null ? 1 : 0;
      final ib = b.imageUrl != null ? 1 : 0;
      if (ia != ib) return ib.compareTo(ia);
      return (b.pricing?.discountPercent ?? 0).compareTo(a.pricing?.discountPercent ?? 0);
    });
    return deals;
  }
}

class HeroCategory {
  final int id;
  final String name;
  final String slug;
  final List<Product> products;
  const HeroCategory({required this.id, required this.name, required this.slug, required this.products});
}

class SearchResponse {
  final List<Product> products;
  final int total;
  final int totalPages;
  final int page;
  final String sort;
  const SearchResponse({required this.products, required this.total, required this.totalPages, required this.page, required this.sort});
}

class StoreCategoryCount {
  final int id;
  final String categoryName;
  final String slug;
  final int productCount;
  const StoreCategoryCount({required this.id, required this.categoryName, required this.slug, required this.productCount});
}

class StoreDetailResponse {
  final String businessName;
  final String slug;
  final String? city;
  final double? rating;
  final List<Product> products;
  final int total;
  final int totalPages;
  final int page;
  final List<StoreCategoryCount> categories;
  bool isFollowing;
  int followerCount;
  final int tenantId;

  StoreDetailResponse({
    required this.businessName,
    required this.slug,
    this.city,
    this.rating,
    required this.products,
    required this.total,
    required this.totalPages,
    required this.page,
    required this.categories,
    required this.isFollowing,
    required this.followerCount,
    required this.tenantId,
  });
}

class ProductDetailResponse {
  final Product product;
  final ProductPricing pricing;
  final double availableStock;
  final List<String> gallery;
  final List<ProductVariant> variants;
  final List<Product> relatedProducts;
  final List<ProductReview> reviews;
  final String? whatsappUrl;
  bool isWishlisted;
  final bool canReview;

  ProductDetailResponse({
    required this.product,
    required this.pricing,
    required this.availableStock,
    required this.gallery,
    required this.variants,
    required this.relatedProducts,
    required this.reviews,
    this.whatsappUrl,
    required this.isWishlisted,
    this.canReview = false,
  });
}

class CatalogService {
  final _web = WebSessionClient.shared;

  Future<SearchSuggestResponse> searchSuggest(String query) async {
    return _web.fetchJson<SearchSuggestResponse>(
      '/api/store/search-suggest',
      (data) {
        final m = data as Map<String, dynamic>;
        return SearchSuggestResponse(
          products: (m['products'] as List? ?? []).map((j) => SuggestProduct.fromJson(j as Map<String, dynamic>)).toList(),
          categories: (m['categories'] as List? ?? []).map((j) => MarketplaceCategory.fromJson(j as Map<String, dynamic>)).toList(),
        );
      },
      query: {'q': query},
    );
  }

  Future<HomeResponse> home() async {
    debugPrint('[CatalogService] home() start – fetching /store');
    final html = await _web.fetchHtml('/store');
    debugPrint('[CatalogService] /store OK len=${html.length}');
    final allProducts = _parseProductCards(html);
    debugPrint('[CatalogService] parsed products=${allProducts.length}');
    final categories = _parseCategories(html);
    debugPrint('[CatalogService] parsed categories=${categories.length}');

    final heroCategories = <HeroCategory>[];
    for (final cat in categories.take(2)) {
      try {
        final catHtml = await _web.fetchHtml('/store/category/${cat.slug}');
        final catProducts = _parseProductCards(catHtml);
        if (catProducts.isNotEmpty) {
          heroCategories.add(HeroCategory(id: cat.id, name: cat.categoryName, slug: cat.slug, products: catProducts));
        }
      } catch (_) {}
    }
    if (heroCategories.isEmpty) {
      heroCategories.add(HeroCategory(id: 1, name: 'New Arrivals', slug: 'general', products: allProducts));
    }

    final stores = _parseStoreListings(html);
    debugPrint('[CatalogService] parsed stores=${stores.length} heroCategories=${heroCategories.length}');
    return HomeResponse(categories: categories, featured: allProducts.take(20).toList(), heroCategories: heroCategories, stores: stores);
  }

  Future<SearchResponse> search({
    String query = '',
    String? categorySlug,
    String sort = 'newest',
    int page = 1,
    double? minPrice,
    double? maxPrice,
    int? minRating,
    bool inStockOnly = false,
  }) async {
    var path = '/store';
    if (categorySlug != null && categorySlug.isNotEmpty) path += '/category/$categorySlug';
    final params = <String>[];
    if (query.isNotEmpty) params.add('search=${Uri.encodeQueryComponent(query)}');
    final serverSort = _serverSort(sort);
    if (serverSort != null) params.add('sort=$serverSort');
    if (minPrice != null && minPrice > 0) params.add('min_price=${minPrice.toInt()}');
    if (maxPrice != null && maxPrice > 0) params.add('max_price=${maxPrice.toInt()}');
    if (minRating != null) params.add('min_rating=$minRating');
    if (inStockOnly) params.add('in_stock=1');
    if (page > 1) params.add('page=$page');
    if (params.isNotEmpty) path += '?${params.join('&')}';

    final html = await _web.fetchHtml(path);
    final products = _parseProductCards(html);
    final totalPages = _extractTotalPages(html);
    final totalM = RegExp(r'(\d+)\s+(?:product|result|item)').firstMatch(html);
    final total = totalM != null ? (int.tryParse(totalM.group(1)!) ?? products.length) : products.length;

    return SearchResponse(products: products, total: total, totalPages: totalPages.clamp(1, 9999), page: page, sort: sort);
  }

  Future<List<MarketplaceCategory>> categories() async {
    final html = await _web.fetchHtml('/store');
    return _parseCategories(html);
  }

  static final _categoryImageCache = <String, String?>{};

  Future<String?> categoryImage(String slug) async {
    if (_categoryImageCache.containsKey(slug)) return _categoryImageCache[slug];
    try {
      final html = await _web.fetchHtml('/store/category/$slug');
      final products = _parseProductCards(html);
      final url = products.isNotEmpty ? products.first.imageUrl : null;
      if (url != null) _categoryImageCache[slug] = url;
      return url;
    } catch (_) {
      return null;
    }
  }

  Future<ProductDetailResponse> productDetail(String identifier) async {
    final path = int.tryParse(identifier) != null ? '/store/product/$identifier' : '/product/$identifier';
    final html = await _web.fetchHtml(path);
    return _parseProductDetail(html, identifier);
  }

  Future<StoreDetailResponse> storeDetail(String slug, {String? category, String search = '', String sort = 'newest', int page = 1}) async {
    var path = '/store/$slug';
    final params = <String>[];
    if (category != null && category.isNotEmpty) params.add('category=$category');
    if (search.isNotEmpty) params.add('search=${Uri.encodeQueryComponent(search)}');
    if (page > 1) params.add('page=$page');
    if (params.isNotEmpty) path += '?${params.join('&')}';
    final html = await _web.fetchHtml(path);
    return _parseStoreDetail(html, slug, page);
  }

  // MARK: - HTML Parsers

  List<Product> _parseProductCards(String html) {
    var products = _parseMktCards(html);
    if (products.isEmpty) products = _parseStoreCards(html);
    return products;
  }

  List<Product> _parseMktCards(String html) {
    final products = <Product>[];
    final seen = <int>{};
    // Window-based: find each data-id occurrence and extract sibling attrs regardless of order
    final idPat = RegExp(r'\bdata-(?:product-)?id="(\d+)"');
    for (final idMatch in idPat.allMatches(html)) {
      final id = int.tryParse(idMatch.group(1) ?? '') ?? 0;
      if (id <= 0 || seen.contains(id)) continue;
      // ±300-char window covers the same element's attribute list in any attribute order
      final wStart = (idMatch.start - 300).clamp(0, html.length);
      final wEnd   = (idMatch.end   + 300).clamp(0, html.length);
      final elem   = html.substring(wStart, wEnd);
      final nameM  = RegExp(r'\bdata-name="([^"]+)"').firstMatch(elem);
      final priceM = RegExp(r'\bdata-price="([0-9,]+(?:\.[0-9]+)?)"').firstMatch(elem);
      final imgM   = RegExp(r'\bdata-img="([^"]*)"').firstMatch(elem);
      if (nameM == null || priceM == null) continue;
      final name  = nameM.group(1)!;
      final price = double.tryParse(priceM.group(1)!.replaceAll(',', '')) ?? 0;
      if (price <= 0 || _isAdCopy(name)) continue;
      seen.add(id);
      final imgPath  = imgM?.group(1) ?? '';
      final imageUrl = imgPath.isEmpty ? null : _absoluteUrl(imgPath);
      // Wider window for product link and seller info
      final bigStart  = (idMatch.start - 800).clamp(0, html.length);
      final bigEnd    = (idMatch.end   + 200).clamp(0, html.length);
      final bigWindow = html.substring(bigStart, bigEnd);
      final slug = RegExp(r'href="/product/([^"]+)"').firstMatch(bigWindow)?.group(1);
      // Seller link: <a class="mkt-seller" href="/store/slug"><svg>...</svg><span>Name</span></a>
      final sellerLinkM = RegExp(r'href="/store/([^/"]+)"').firstMatch(bigWindow);
      final sellerSlug = sellerLinkM?.group(1);
      String? sellerName;
      if (sellerLinkM != null) {
        final afterLink = bigWindow.substring(sellerLinkM.end, (sellerLinkM.end + 250).clamp(0, bigWindow.length));
        sellerName = RegExp(r'<span[^>]*>\s*([^<]{2,60}?)\s*</span>').firstMatch(afterLink)?.group(1)?.trim();
      }
      final listPrice  = _cardListPrice(bigWindow, price);
      products.add(_makeProduct(
        id: id, name: name, price: price, slug: slug,
        imageUrl: imageUrl, sellerName: sellerName, sellerSlug: sellerSlug, listPrice: listPrice,
      ));
    }
    return products;
  }

  List<Product> _parseStoreCards(String html) {
    final products = <Product>[];
    final seen = <int>{};
    // Anchor on the addToCart JS call which always carries id, name, and price
    final pattern = RegExp(r"""addToCart\(this,\s*(\d+),\s*'([^']*)',\s*([\d.]+)""");
    for (final m in pattern.allMatches(html)) {
      final id    = int.tryParse(m.group(1) ?? '') ?? 0;
      final name  = m.group(2) ?? '';
      final price = double.tryParse(m.group(3) ?? '') ?? 0;
      if (id <= 0 || seen.contains(id) || price <= 0 || _isAdCopy(name)) continue;
      seen.add(id);
      final winStart    = (m.start - 600).clamp(0, html.length);
      final window      = html.substring(winStart, m.end);
      final slugMatches = RegExp(r'href="/product/([^"]+)"').allMatches(window).toList();
      final slug        = slugMatches.isNotEmpty ? slugMatches.last.group(1) : null;
      final imgMatches  = RegExp(r'<img[^>]+src="([^"]+)"').allMatches(window).toList();
      final imgPath     = imgMatches.isNotEmpty ? (imgMatches.last.group(1) ?? '') : '';
      final sellerName  = RegExp(r'href="/store/[^"]+">([^<]+)</a>').firstMatch(window)?.group(1)?.stripHtmlTags();
      final listPrice   = _cardListPrice(window, price);
      final imageUrl    = imgPath.isEmpty ? null : _absoluteUrl(imgPath);
      products.add(_makeProduct(
        id: id, name: name, price: price, slug: slug,
        imageUrl: imageUrl, sellerName: sellerName, sellerSlug: null, listPrice: listPrice,
      ));
    }
    return products;
  }

  bool _isAdCopy(String name) {
    final t = name.trim();
    if (t.isEmpty) return true;
    final lower = t.toLowerCase();
    const adPhrases = ['% off', 'sale', 'discount', 'free shipping', 'free delivery', 'limited time', 'buy now', 'shop now', 'flash sale', 'deal of the day', 'hurry', 'offer ends', 'grand opening'];
    if (adPhrases.any((p) => lower.contains(p))) return true;
    final hasLower = t.contains(RegExp(r'[a-z]'));
    final hasDigit = t.contains(RegExp(r'[0-9]'));
    if (!hasLower && !hasDigit && t.length > 25) return true;
    return false;
  }

  double _cardListPrice(String window, double fallback) {
    double cleanN(String s) => double.tryParse(s.replaceAll(',', '')) ?? 0.0;
    var m = RegExp(r'data-compare-(?:at-)?price="([0-9,]+)"').firstMatch(window);
    if (m != null) return cleanN(m.group(1)!);
    m = RegExp(r'<(?:del|s)[^>]*>\s*(?:Rs\.?\s*|PKR\s*)?([0-9,]+(?:\.[0-9]+)?)\s*</(?:del|s)>').firstMatch(window);
    if (m != null) return cleanN(m.group(1)!);
    return fallback;
  }

  Product _makeProduct({required int id, required String name, required double price, String? slug, String? imageUrl, String? sellerName, String? sellerSlug, double? listPrice}) {
    final lp = listPrice ?? price;
    final hasDiscount = lp > price && price > 0;
    final discountPct = hasDiscount ? ((lp - price) / lp * 100).roundToDouble() : 0.0;
    final pricing = hasDiscount
        ? ProductPricing(unitPrice: price, listPrice: lp, displayPrice: price, displayList: lp, hasDiscount: true, discountPercent: discountPct)
        : null;
    return Product(
      id: id,
      productName: name.trim().decodeHtmlEntities(),
      slug: slug,
      sellingPrice: price,
      marketplacePrice: lp,
      stockQuantity: 1,
      imageUrl: imageUrl,
      sellerName: sellerName,
      sellerSlug: sellerSlug,
      pricing: pricing,
      isWishlisted: false,
    );
  }

  List<MarketplaceCategory> _parseCategories(String html) {
    final cats = <MarketplaceCategory>[];
    final seen = <String>{};
    int idx = 0;
    final linkPat = RegExp(r'href="/store/category/([^"]+)"');
    for (final m in linkPat.allMatches(html)) {
      final slug = m.group(1)!;
      if (slug.isEmpty || seen.contains(slug)) continue;
      final wEnd = (m.end + 250).clamp(0, html.length);
      final window = html.substring(m.end, wEnd);
      // Real HTML: <a href="/store/category/foo" class="mkt-cat-link"><span>Name</span><span class="n">4</span></a>
      // Also handle simple inline text: <a href="/store/category/foo">General Store Items</a>
      final nameM = RegExp(r'<span[^>]*>\s*([^<]{2,80}?)\s*</span>').firstMatch(window)
          ?? RegExp(r'>\s*([A-Za-z][^<\n]{1,79}?)\s*<').firstMatch(window);
      if (nameM == null) continue;
      final name = nameM.group(1)!.trim().decodeHtmlEntities();
      if (name.isEmpty) continue;
      final countM = RegExp(r'<span[^>]*\bn\b[^"]*"[^>]*>\s*(\d+)\s*</span>').firstMatch(window);
      final count = int.tryParse(countM?.group(1) ?? '');
      seen.add(slug);
      cats.add(MarketplaceCategory(id: idx + 1, categoryName: name, slug: slug, prodCount: count));
      idx++;
    }
    return cats;
  }

  ProductDetailResponse _parseProductDetail(String html, String identifier) {
    // Primary: parse the PRODUCT JS variable embedded in every product detail page
    String? jsName, jsSeller, jsImgPath;
    int? jsId;
    double? jsPrice;
    final jsM = RegExp(r'var\s+PRODUCT\s*=\s*\{([^}]+)\}', dotAll: true).firstMatch(html);
    if (jsM != null) {
      final js = jsM.group(1)!;
      jsId      = int.tryParse(RegExp(r'\bid\s*:\s*(\d+)').firstMatch(js)?.group(1) ?? '');
      jsName    = RegExp(r'\bname\s*:\s*"((?:[^"\\]|\\.)*)"').firstMatch(js)?.group(1)?.replaceAll(r'\"', '"');
      jsPrice   = double.tryParse(RegExp(r'\bprice\s*:\s*(\d+(?:\.\d+)?)').firstMatch(js)?.group(1) ?? '');
      jsSeller  = RegExp(r'\bseller\s*:\s*"([^"]+)"').firstMatch(js)?.group(1);
      jsImgPath = RegExp(r'\bimg\s*:\s*"((?:[^"\\]|\\.)*)"').firstMatch(js)?.group(1)?.replaceAll(r'\/', '/');
    }

    // OG title has " | SoftStore.pk" suffix — strip it
    final ogTitleRaw = RegExp(r'<meta property="og:title" content="([^"]+)"').firstMatch(html)?.group(1);
    final ogTitle = ogTitleRaw != null
        ? (RegExp(r'^(.+?)\s*\|\s*SoftStore\.pk\s*$').firstMatch(ogTitleRaw)?.group(1) ?? ogTitleRaw)
        : null;

    // Name: JS var → cleaned OG title → h1
    final name = (jsName ?? ogTitle
        ?? RegExp(r'<h1[^>]*>\s*([^<]{2,120}?)\s*<').firstMatch(html)?.group(1)
        ?? '').decodeHtmlEntities();

    // Image: PRODUCT.img → og:image → pdMainImg
    final ogImage = RegExp(r'<meta property="og:image" content="([^"]+)"').firstMatch(html)?.group(1);
    final rawImg = jsImgPath != null ? _absoluteUrl(jsImgPath) : (ogImage
        ?? RegExp(r'id="pdMainImg"[^>]*src="([^"]+)"').firstMatch(html)?.group(1)
        ?? RegExp(r'src="([^"]+)"[^>]*id="pdMainImg"').firstMatch(html)?.group(1));

    // Price: <span id="pdPriceNow"> → PRODUCT.price → data-price (mkt card context)
    final priceNowM = RegExp(r'id="pdPriceNow"[^>]*>\s*(?:Rs\.?\s*)?([\d,]+)').firstMatch(html);
    final price = priceNowM != null
        ? (double.tryParse(priceNowM.group(1)!.replaceAll(',', '')) ?? 0)
        : (jsPrice ?? double.tryParse(
              RegExp(r'data-price="([^"]+)"').firstMatch(html)?.group(1) ?? '') ?? 0);

    // ID: PRODUCT.id → data-product-id (wishlist btn) → data-id → numeric identifier
    final productId = jsId
        ?? int.tryParse(RegExp(r'data-product-id="(\d+)"').firstMatch(html)?.group(1) ?? '')
        ?? int.tryParse(RegExp(r'data-id="(\d+)"').firstMatch(html)?.group(1) ?? '')
        ?? int.tryParse(identifier)
        ?? 0;

    // Gallery: main img + any additional gallery thumbnails
    final List<String> images = [];
    if (rawImg != null && rawImg.isNotEmpty) images.add(rawImg);
    for (final m in RegExp(r'<button[^>]*data-idx="(\d+)"[^>]*data-src="([^"]+)"').allMatches(html)) {
      final url = _absoluteUrl(m.group(2)!);
      if (!images.contains(url)) images.add(url);
    }

    // Seller info: <a class="pd-seller" href="/store/{slug}">
    String? sellerName = jsSeller;
    String? sellerSlug, sellerCity, sellerWhatsapp, whatsappUrl;
    final pdSellerM = RegExp(r'class="pd-seller"\s+href="/store/([^"]+)"|href="/store/([^"]+)"\s+class="pd-seller"').firstMatch(html);
    if (pdSellerM != null) {
      sellerSlug = pdSellerM.group(1) ?? pdSellerM.group(2);
      final wEnd = (pdSellerM.end + 450).clamp(0, html.length);
      final window = html.substring(pdSellerM.end, wEnd);
      if (sellerName == null) {
        final nm = RegExp(r'g-sans[^>]*>\s*([^<]{2,60}?)\s*<').firstMatch(window)
            ?? RegExp(r'fw-bold[^>]*>\s*([^<]{2,60}?)\s*<').firstMatch(window);
        sellerName = nm?.group(1)?.trim();
      }
      // City is before "· Visit store": "Quetta &middot; Visit store"
      final cityM = RegExp(r't-sm[^>]*>[\s\S]{0,20}?([A-Za-z][^<·&\n]{1,35}?)\s*(?:&middot;|·|\n|<)').firstMatch(window);
      sellerCity = cityM?.group(1)?.trim();
    }
    // Fallback seller slug from link near product heading
    if (sellerSlug == null) {
      sellerSlug = RegExp(r'href="/store/([^/"]+)"').firstMatch(html)?.group(1);
    }

    // WhatsApp
    final waMN = RegExp(r'href="https://wa\.me/([0-9]+)"').firstMatch(html)?.group(1);
    whatsappUrl = waMN != null ? 'https://wa.me/$waMN' : null;
    sellerWhatsapp = waMN;

    // Discount / list price
    double cleanN(String s) => double.tryParse(s.replaceAll(',', '').trim()) ?? 0.0;
    double listPrice = price;
    var discM = RegExp(r'data-compare-(?:at-)?price="([0-9,]+(?:\.[0-9]*)?)"').firstMatch(html);
    if (discM != null) {
      listPrice = cleanN(discM.group(1)!);
    } else {
      discM = RegExp(r'<(?:del|s)[^>]*>\s*(?:Rs\.?\s*|PKR\s*)?([0-9,]+(?:\.[0-9]+)?)\s*</(?:del|s)>').firstMatch(html);
      if (discM != null) listPrice = cleanN(discM.group(1)!);
    }
    final hasDiscount = listPrice > price && price > 0;
    final discountPct = hasDiscount ? ((listPrice - price) / listPrice * 100).roundToDouble() : 0.0;

    // Stock
    bool inStock = !html.contains('Out of stock') && !html.contains('out-of-stock') && !html.contains('pd-stock out');
    double stockQty = inStock ? 9999 : 0;
    for (final pat in [r'data-stock="(\d+)"', r'data-quantity="(\d+)"', r'data-available-stock="(\d+)"']) {
      final sm = RegExp(pat).firstMatch(html);
      if (sm != null) { stockQty = double.tryParse(sm.group(1)!) ?? stockQty; break; }
    }
    if (!inStock) stockQty = 0;

    // Wishlist state
    final isWishlisted = html.contains('btn-wishlist active') || html.contains('is-wishlisted') || html.contains('wishlist-active');
    final canReview = html.contains('pd-review-form') || html.contains('can-review');

    final pricing = ProductPricing(unitPrice: price, listPrice: listPrice, displayPrice: price, displayList: listPrice, hasDiscount: hasDiscount, discountPercent: discountPct);

    final product = Product(
      id: productId, productName: name,
      slug: identifier.contains('-') ? identifier : null,
      sellingPrice: price, marketplacePrice: listPrice, stockQuantity: stockQty,
      imageUrl: images.isNotEmpty ? images.first : null,
      sellerName: sellerName, sellerSlug: sellerSlug, sellerCity: sellerCity, sellerWhatsapp: sellerWhatsapp,
      pricing: pricing, isWishlisted: isWishlisted,
    );

    final related = _parseProductCards(html).where((p) => p.id != productId).take(10).toList();

    return ProductDetailResponse(
      product: product, pricing: pricing, availableStock: stockQty,
      gallery: images.map(_absoluteUrl).toList(),
      variants: _parseVariants(html, productId),
      relatedProducts: related,
      reviews: _parseReviews(html),
      whatsappUrl: whatsappUrl,
      isWishlisted: isWishlisted,
      canReview: canReview,
    );
  }

  List<ProductVariant> _parseVariants(String html, int productId) {
    final selectM = RegExp(r'<select[^>]*name="variant_id"[^>]*>(.*?)</select>', dotAll: true).firstMatch(html);
    if (selectM == null) return [];
    final block = selectM.group(1)!;
    final variants = <ProductVariant>[];
    for (final m in RegExp(r'<option[^>]*value="(\d+)"([^>]*)>([^<]+)</option>', dotAll: true).allMatches(block)) {
      final variantId = int.tryParse(m.group(1) ?? '') ?? 0;
      if (variantId <= 0) continue;
      final label = (m.group(3) ?? '').trim().decodeHtmlEntities();
      if (label.isEmpty) continue;
      final attrs = m.group(2) ?? '';
      final optionPrice = double.tryParse(RegExp(r'data-price="([\d.]+)"').firstMatch(attrs)?.group(1) ?? '');
      final optionStock = double.tryParse(RegExp(r'data-stock="(\d+)"').firstMatch(attrs)?.group(1) ?? '');
      variants.add(ProductVariant(id: variantId, productId: productId, name: label, sellingPrice: optionPrice, stockQuantity: optionStock));
    }
    return variants;
  }

  List<ProductReview> _parseReviews(String html) {
    final reviews = <ProductReview>[];
    for (final m in RegExp(r'data-rating="(\d)"[^>]*>([\s\S]{0,600}?)</div>\s*</div>', dotAll: true).allMatches(html)) {
      final rating = int.tryParse(m.group(1) ?? '') ?? 0;
      final body = (m.group(2) ?? '').stripHtmlTags().decodeHtmlEntities().trim();
      if (rating > 0 && body.isNotEmpty && body.length < 2000) {
        reviews.add(ProductReview(id: reviews.length + 1, rating: rating, reviewText: body));
      }
    }
    return reviews;
  }

  StoreDetailResponse _parseStoreDetail(String html, String slug, int page) {
    final storeName = (RegExp(r'<h1[^>]*>\s*([^<]{2,80}?)\s*</h1>').firstMatch(html)?.group(1)
        ?? RegExp(r'og:title"[^>]*content="([^"]+)"').firstMatch(html)?.group(1)
        ?? slug).stripHtmlTags().decodeHtmlEntities();
    final tenantId = int.tryParse(RegExp(r'data-tenant-id="(\d+)"').firstMatch(html)?.group(1) ?? '') ?? 0;
    final isFollowing = RegExp(r'data-following="([01])"').firstMatch(html)?.group(1) == '1';
    final followerStr = RegExp(r'id="storeFollowerCount">\s*([0-9,]+)\s*<').firstMatch(html)?.group(1) ?? '0';
    final followerCount = int.tryParse(followerStr.replaceAll(',', '')) ?? 0;
    // City from og:title: "StoreName, City — SoftStore Marketplace"
    final storeOgTitle = RegExp(r'og:title"\s+content="([^"]+)"').firstMatch(html)?.group(1);
    final city = storeOgTitle != null
        ? RegExp(r',\s*([^—,\|]{2,40?})\s*(?:—|$)').firstMatch(storeOgTitle)?.group(1)?.trim()
        : RegExp(r'fa-map-marker[^>]*></i>\s*([^<]{2,40})').firstMatch(html)?.group(1)?.stripHtmlTags();
    final rating = double.tryParse(RegExp(r'(?:store|seller)[^>]*rating[^>]*>\s*([0-9.]+)\s*</(?:span|div)').firstMatch(html)?.group(1) ?? '');
    final products = _parseProductCards(html);
    final totalPages = _extractTotalPages(html);
    final total = int.tryParse(RegExp(r'(\d+)\s+[Pp]roduct').firstMatch(html)?.group(1) ?? '') ?? products.length;

    return StoreDetailResponse(
      businessName: storeName, slug: slug, city: city, rating: rating,
      products: products, total: total, totalPages: totalPages.clamp(1, 9999),
      page: page, categories: [], isFollowing: isFollowing,
      followerCount: followerCount, tenantId: tenantId,
    );
  }

  Map<String, dynamic>? _extractProductJsonLd(String html) {
    final pattern = RegExp(r'<script[^>]+type="application/ld\+json"[^>]*>(.*?)</script>', dotAll: true, caseSensitive: false);
    for (final m in pattern.allMatches(html)) {
      final json = m.group(1)?.trim();
      if (json == null) continue;
      try {
        final parsed = jsonDecode(json);
        if (parsed is Map<String, dynamic> && _isProductNode(parsed)) return parsed;
        if (parsed is Map<String, dynamic>) {
          final graph = parsed['@graph'];
          if (graph is List) {
            for (final node in graph) {
              if (node is Map<String, dynamic> && _isProductNode(node)) return node;
            }
          }
        }
      } catch (_) {}
    }
    return null;
  }

  bool _isProductNode(Map<String, dynamic> json) {
    final t = json['@type'];
    if (t is String) return t == 'Product';
    if (t is List) return t.contains('Product');
    return false;
  }

  int _extractTotalPages(String html) {
    final m = RegExp(r'page=(\d+)[^"]*"[^>]*(?:aria-label="Last"|>Last<)').firstMatch(html);
    if (m != null) return int.tryParse(m.group(1)!) ?? 1;
    final nums = RegExp(r'[?&]page=(\d+)').allMatches(html).map((m) => int.tryParse(m.group(1)!) ?? 0).toList();
    return nums.isEmpty ? 1 : nums.reduce((a, b) => a > b ? a : b);
  }

  List<Store> _parseStoreListings(String html) {
    final stores = <Store>[];
    final seen = <String>{};
    int idx = 0;
    // mkt-seller-card: <a class="mkt-seller-card" href="/store/{slug}">
    for (final m in RegExp(r'href="/store/([^"]+)"\s+class="mkt-seller-card"|class="mkt-seller-card"\s+href="/store/([^"]+)"').allMatches(html)) {
      final slug = m.group(1) ?? m.group(2) ?? '';
      if (slug.isEmpty || seen.contains(slug)) continue;
      seen.add(slug);
      final wEnd = (m.end + 350).clamp(0, html.length);
      final window = html.substring(m.end, wEnd);
      // Name: <span class="d-block g-sans" ...>StoreName</span>
      final nameM = RegExp(r'g-sans[^>]*>\s*([^<]{2,60}?)\s*<').firstMatch(window)
          ?? RegExp(r'fw-bold[^>]*>\s*([^<]{2,60}?)\s*<').firstMatch(window)
          ?? RegExp(r'<span[^>]*>\s*([A-Z][^<]{1,59}?)\s*</span>').firstMatch(window);
      final name = nameM?.group(1)?.trim() ?? slug;
      // City: <span class="d-block t-sm" ...>City</span>
      final cityM = RegExp(r't-sm[^>]*>\s*([^<]{2,40}?)\s*<').firstMatch(window);
      final city = cityM?.group(1)?.trim();
      stores.add(Store(id: ++idx, businessName: name, slug: slug, city: city));
    }
    return stores;
  }

  String _absoluteUrl(String path) {
    if (path.startsWith('//')) return 'https:$path';
    if (!path.startsWith('http')) {
      return '${AppConstants.baseUrl}${path.startsWith('/') ? path : '/$path'}';
    }
    return path;
  }

  String? _serverSort(String sort) {
    switch (sort) {
      case 'newest':
      case 'relevance': return null;
      case 'price_low': return 'price-low';
      case 'price_high': return 'price-high';
      case 'best_selling': return 'best-selling';
      case 'top_rated': return 'top-rated';
      default: return sort;
    }
  }
}

double _loose(dynamic v) {
  if (v == null) return 0.0;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? 0.0;
  return 0.0;
}

extension _StringExt on String {
  String decodeHtmlEntities() => replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<').replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"').replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ');

  String stripHtmlTags() => replaceAll(RegExp(r'<[^>]+>'), '');
}
