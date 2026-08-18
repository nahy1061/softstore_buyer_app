import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/html_parser_util.dart';
import '../models/catalog_models.dart';

/// Handles all catalog (browse, search, product detail) API calls.
///
/// SoftStore's catalog is served as HTML from softstore.pk. This repository:
///  1. GETs each page
///  2. Parses schema.org JSON-LD where available
///  3. Parses HTML product cards (article.mkt-card, .mkt-card, etc.)
class CatalogRepository {
  CatalogRepository._();
  static final CatalogRepository instance = CatalogRepository._();

  final DioClient _client = DioClient();

  // ─── Homepage ─────────────────────────────────────────────────────────────

  Future<HomepageData> getHomepage() async {
    try {
      final response = await _client.get<String>(
        ApiEndpoints.homepage,
        options: Options(responseType: ResponseType.plain, followRedirects: true),
      );
      final html = response.data ?? '';
      return _parseHomepage(html);
    } on DioException catch (e) {
      throw _mapError(e);
    } catch (e, st) {
      developer.log('[Catalog] getHomepage error: $e', stackTrace: st, name: 'catalog');
      return const HomepageData(
        heroBanners: [],
        categories: [],
        topDeals: [],
        featuredProducts: [],
      );
    }
  }

  HomepageData _parseHomepage(String html) {
    // 1. Products: try JSON-LD first
    final jsonLdProducts = HtmlParserUtil.extractJsonLd(html)
        .where((b) =>
            b['@type'] == 'Product' ||
            (b['@type'] is List && (b['@type'] as List).contains('Product')))
        .toList();

    List<Product> products = jsonLdProducts.map(_productFromJsonLd).toList();

    // Fallback: parse HTML product cards directly if JSON-LD returns no products
    if (products.isEmpty) {
      products = _parseProductsFromHtml(html);
    }

    // 2. Categories
    final categories = _parseCategories(html);

    return HomepageData(
      heroBanners: products.take(5).toList(),
      categories: categories,
      topDeals: products.take(10).toList(),
      featuredProducts: products,
    );
  }

  // ─── Search ───────────────────────────────────────────────────────────────

  Future<SearchResult> searchProducts({
    required String query,
    String? category,
    String? sort,
    int page = 1,
  }) async {
    try {
      final hasCategory = category != null &&
          category.trim().isNotEmpty &&
          category.trim().toLowerCase() != 'all';

      final endpoint = hasCategory
          ? '${ApiEndpoints.categoryProducts}${category.trim()}'
          : ApiEndpoints.search;

      final response = await _client.get<String>(
        endpoint,
        queryParameters: {
          if (query.trim().isNotEmpty) 'search': query.trim(),
          if (query.trim().isNotEmpty) 'q': query.trim(),
          if (sort != null && sort.isNotEmpty) 'sort': sort,
          if (page > 1) 'page': page,
        },
        options: Options(responseType: ResponseType.plain, followRedirects: true),
      );
      final html = response.data ?? '';
      return _parseSearchResults(html);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  SearchResult _parseSearchResults(String html) {
    if (HtmlParserUtil.hasNoResults(html)) {
      return const SearchResult(products: [], totalCount: 0);
    }

    final jsonLdProducts = HtmlParserUtil.extractJsonLd(html)
        .where((b) => b['@type'] == 'Product')
        .toList();

    List<Product> products = jsonLdProducts.map(_productFromJsonLd).toList();

    if (products.isEmpty) {
      products = _parseProductsFromHtml(html);
    }

    final doc = HtmlParserUtil.parse(html);

    // Total count
    final countText = HtmlParserUtil.queryText(
        doc, '.results-count, .search-count, [data-count], #mktProducts .t-sm');
    final totalCount = HtmlParserUtil.parseNumberFromText(countText);

    // Next page link
    final nextLink = doc.querySelector('.pagination .next, a[rel="next"], .mkt-pager a.next');

    return SearchResult(
      products: products,
      totalCount: totalCount ?? products.length,
      hasNextPage: nextLink != null,
    );
  }

  // ─── Product Detail ───────────────────────────────────────────────────────

  Future<ProductDetail> getProductDetail(String slug) async {
    try {
      final response = await _client.get<String>(
        '${ApiEndpoints.productDetail}$slug',
        options: Options(responseType: ResponseType.plain, followRedirects: true),
      );
      final html = response.data ?? '';
      return _parseProductDetail(html, slug);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  ProductDetail _parseProductDetail(String html, String slug) {
    final doc = HtmlParserUtil.parse(html);

    // Primary: schema.org Product JSON-LD
    final jsonLd = HtmlParserUtil.findJsonLdByType(html, 'Product');

    // ── Product ID ──
    int productId = 0;
    final contactLink = doc.querySelector('a[href*="product_id="]');
    if (contactLink != null) {
      final href = contactLink.attributes['href'] ?? '';
      final match = RegExp(r'product_id=(\d+)').firstMatch(href);
      if (match != null) productId = int.tryParse(match.group(1)!) ?? 0;
    }
    if (productId == 0) {
      final dataId = doc
              .querySelector('[data-product-id]')
              ?.attributes['data-product-id'] ??
          doc.querySelector('[data-id]')?.attributes['data-id'];
      productId = int.tryParse(dataId ?? '') ?? 0;
    }

    // ── Name, Price, Images ── from JSON-LD or HTML
    final name = jsonLd?['name'] as String? ??
        doc.querySelector('h1')?.text.trim() ??
        slug;

    double displayPrice = 0;
    double? listPrice;
    double? discountPercent;
    if (jsonLd != null) {
      final offers = jsonLd['offers'];
      if (offers is Map) {
        displayPrice =
            double.tryParse(offers['price']?.toString() ?? '') ?? 0;
        final highPrice = double.tryParse(offers['highPrice']?.toString() ?? '');
        if (highPrice != null && highPrice > displayPrice) {
          listPrice = highPrice;
          discountPercent =
              ((listPrice - displayPrice) / listPrice * 100).roundToDouble();
        }
      }
    }

    if (displayPrice == 0) {
      final priceText = doc.querySelector('.price, .product-price, .mkt-price')?.text;
      final parsedPrice = HtmlParserUtil.parseNumberFromText(priceText);
      if (parsedPrice != null) displayPrice = parsedPrice.toDouble();
    }

    final images = HtmlParserUtil.extractSchemaImages(jsonLd?['image']);

    // Add main image from HTML if JSON-LD images are empty
    if (images.isEmpty) {
      final mainImg = doc.querySelector('.product-image img, .mkt-card-im img, main img');
      final src = mainImg?.attributes['src'] ?? mainImg?.attributes['data-src'];
      if (src != null && src.isNotEmpty) {
        images.add(HtmlParserUtil.toAbsoluteUrl(src));
      }
    }

    // ── Variants ──
    final variantSelect = doc.querySelector('select[name="variant_id"]');
    final variants = <Variant>[];
    if (variantSelect != null) {
      for (final option in variantSelect.querySelectorAll('option')) {
        final id = int.tryParse(option.attributes['value'] ?? '');
        if (id != null && id > 0) {
          variants.add(Variant(id: id, label: option.text.trim()));
        }
      }
    }

    // ── Stock ──
    bool inStock = true;
    int? stockQty;
    if (jsonLd != null) {
      final availability = (jsonLd['offers'] as Map?)?['availability'] ?? '';
      inStock = availability.toString().contains('InStock');
    }
    final qtyInput = doc.querySelector('input[name="quantity"]');
    if (qtyInput != null) {
      final maxAttr = qtyInput.attributes['max'];
      stockQty = int.tryParse(maxAttr ?? '');
    }

    // ── Seller ──
    SellerStub? seller;
    final storeLink = doc.querySelector('a[href*="/store/"]');
    if (storeLink != null) {
      final href = storeLink.attributes['href'] ?? '';
      final storeSlug = href.replaceAll(RegExp(r'.*/store/'), '').split('/').first;
      seller = SellerStub(name: storeLink.text.trim(), slug: storeSlug);
    }

    // ── Specifications ──
    final specs = <Specification>[];
    final specRows = doc.querySelectorAll(
        'table.specs tr, .specifications tr, .product-specs tr');
    for (final row in specRows) {
      final cells = row.querySelectorAll('td, th');
      if (cells.length >= 2) {
        specs.add(Specification(
          label: cells[0].text.trim(),
          value: cells[1].text.trim(),
        ));
      }
    }

    // ── Description ──
    final descEl = doc.querySelector(
        '.product-description, [itemprop="description"], .description');
    final description = descEl?.innerHtml.trim();

    return ProductDetail(
      id: productId,
      name: name,
      slug: slug,
      description: description,
      images: images,
      displayPrice: displayPrice,
      listPrice: listPrice,
      discountPercent: discountPercent,
      variants: variants,
      inStock: inStock,
      stockQuantity: stockQty,
      seller: seller,
      specifications: specs,
    );
  }

  // ─── Categories ───────────────────────────────────────────────────────────

  Future<List<Category>> getCategories() async {
    try {
      final response = await _client.get<String>(
        ApiEndpoints.categories,
        options: Options(responseType: ResponseType.plain, followRedirects: true),
      );
      final html = response.data ?? '';
      return _parseCategories(html);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  List<Category> _parseCategories(String html) {
    final doc = HtmlParserUtil.parse(html);
    final categories = <Category>[];

    // 1. Parse category links from navigation rails and drawers
    final links = doc.querySelectorAll(
        '.ss-rail-scroll a[href*="/category/"], .mkt-cats-scroll a[href*="/category/"], .mkt-cat-link[href*="/category/"], nav a[href*="/category/"], a[href*="/store/category/"]');

    for (final a in links) {
      final href = a.attributes['href'] ?? '';
      final slug = href.split('/category/').last.split('?').first.trim();
      final nameEl = a.querySelector('span:first-child') ?? a;
      var name = nameEl.text.trim();

      // Clean category count suffixes e.g. "General Store Items 18"
      name = name.replaceAll(RegExp(r'\s*\d+$'), '').trim();

      final countText = a.querySelector('.c, .n, .cc-cnt')?.text;

      if (slug.isNotEmpty &&
          slug.toLowerCase() != 'all' &&
          int.tryParse(slug) == null &&
          !categories.any((c) => c.slug == slug)) {
        categories.add(Category(
          name: name,
          slug: slug,
          productCount: HtmlParserUtil.parseNumberFromText(countText),
        ));
      }
    }

    // 2. Fallback: elements with data-slug
    if (categories.isEmpty) {
      final cards = doc.querySelectorAll('.category-card, .category-item, [data-slug]');
      for (final el in cards) {
        final slug = el.attributes['data-slug'] ?? el.querySelector('a')?.attributes['href']?.split('/').last ?? '';
        final imgEl = el.querySelector('img');
        if (slug.isNotEmpty &&
            slug.toLowerCase() != 'all' &&
            int.tryParse(slug) == null &&
            !categories.any((c) => c.slug == slug)) {
          categories.add(Category(
            name: el.querySelector('h3, h4, .name, .title')?.text.trim() ?? el.text.trim(),
            slug: slug,
            imageUrl: imgEl != null
                ? HtmlParserUtil.toAbsoluteUrl(imgEl.attributes['src'] ?? imgEl.attributes['data-src'] ?? '')
                : null,
          ));
        }
      }
    }

    // 3. Fallback defaults if still empty
    if (categories.isEmpty) {
      return const [
        Category(name: 'General Store Items', slug: 'general', productCount: 12),
        Category(name: 'Personal Care & Hygiene', slug: 'personal-care', productCount: 7),
        Category(name: 'Beverages & Cold Drinks', slug: 'beverages', productCount: 1),
        Category(name: 'Furniture', slug: 'furniture', productCount: 1),
        Category(name: 'Mobile Accessories', slug: 'mobile-accessories', productCount: 1),
      ];
    }

    return categories;
  }

  // ─── Seller Profile ───────────────────────────────────────────────────────

  Future<SellerProfile> getSellerProfile(String slug) async {
    try {
      final response = await _client.get<String>(
        '${ApiEndpoints.sellerProfile}$slug',
        options: Options(responseType: ResponseType.plain, followRedirects: true),
      );
      final html = response.data ?? '';
      return _parseSellerProfile(html, slug);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  SellerProfile _parseSellerProfile(String html, String slug) {
    final doc = HtmlParserUtil.parse(html);

    final name = doc.querySelector('h1, .store-name, .seller-name')?.text.trim() ?? slug;
    final description =
        doc.querySelector('.store-description, .about, .seller-bio')?.text.trim();
    final logoEl = doc.querySelector('.store-logo img, .seller-logo img, .mkt-seller-av img');
    final bannerEl = doc.querySelector('.store-banner img, .seller-banner img');

    // Products on the seller store page
    final jsonLdProducts = HtmlParserUtil.extractJsonLd(html)
        .where((b) => b['@type'] == 'Product')
        .toList();
    List<Product> products = jsonLdProducts.map(_productFromJsonLd).toList();

    if (products.isEmpty) {
      products = _parseProductsFromHtml(html);
    }

    return SellerProfile(
      name: name,
      slug: slug,
      description: description,
      logoUrl: logoEl != null
          ? HtmlParserUtil.toAbsoluteUrl(
              logoEl.attributes['src'] ?? logoEl.attributes['data-src'] ?? '')
          : null,
      bannerUrl: bannerEl != null
          ? HtmlParserUtil.toAbsoluteUrl(
              bannerEl.attributes['src'] ??
                  bannerEl.attributes['data-src'] ??
                  '')
          : null,
      products: products,
    );
  }

  // ─── HTML Product Parser ──────────────────────────────────────────────────

  /// Parses SoftStore.pk HTML product cards (article.mkt-card, .mkt-card, etc.).
  List<Product> _parseProductsFromHtml(String html) {
    final doc = HtmlParserUtil.parse(html);
    final cardEls = doc.querySelectorAll(
        'article.mkt-card, .mkt-card, .product-card, .mkt-flash-card, article.product-item, .product-item');

    final products = <Product>[];

    for (final card in cardEls) {
      // 1. Add button or data attributes
      final addBtn = card.querySelector('button.mkt-add, button.js-add, [data-id]');
      final dataId = addBtn?.attributes['data-id'];
      final dataName = addBtn?.attributes['data-name'];
      final dataPrice = addBtn?.attributes['data-price'];
      final dataImg = addBtn?.attributes['data-img'];

      // 2. Link & Slug
      final linkEl = card.querySelector('a.mkt-name, a.mkt-card-im, a[href*="/product/"]');
      final href = linkEl?.attributes['href'] ?? '';
      final slug = href.contains('/product/')
          ? href.split('/product/').last.split('?').first.trim()
          : '';

      // 3. Name
      final name = dataName ?? card.querySelector('.mkt-name, .fc-name, h3, h4')?.text.trim() ?? '';
      if (name.isEmpty && slug.isEmpty) continue;

      // 4. Image URL
      final imgEl = card.querySelector('img');
      final rawImg = dataImg ?? imgEl?.attributes['src'] ?? imgEl?.attributes['data-src'] ?? '';
      final imageUrl = rawImg.isNotEmpty ? HtmlParserUtil.toAbsoluteUrl(rawImg) : null;

      // 5. Price
      double price = double.tryParse(dataPrice ?? '') ?? 0;
      if (price == 0) {
        final priceText = card.querySelector('.mkt-price, .fc-price, .price')?.text ?? '';
        final parsedPrice = HtmlParserUtil.parseNumberFromText(priceText);
        if (parsedPrice != null) price = parsedPrice.toDouble();
      }

      // 6. List price
      double? listPrice;
      final wasText = card.querySelector('.was, .fc-was')?.text;
      if (wasText != null) {
        final parsedWas = HtmlParserUtil.parseNumberFromText(wasText);
        if (parsedWas != null) listPrice = parsedWas.toDouble();
      }

      // 7. Product ID
      final id = int.tryParse(dataId ?? '') ??
          (slug.isNotEmpty ? slug.hashCode.abs() : name.hashCode.abs());

      products.add(Product(
        id: id,
        name: name.isNotEmpty ? name : slug,
        slug: slug.isNotEmpty ? slug : name.toLowerCase().replaceAll(' ', '-'),
        imageUrl: imageUrl,
        displayPrice: price,
        listPrice: listPrice,
      ));
    }

    return products;
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Builds a [Product] from a schema.org Product JSON-LD block.
  Product _productFromJsonLd(Map<String, dynamic> jsonLd) {
    final name = jsonLd['name'] as String? ?? '';
    final url = jsonLd['url'] as String? ?? '';
    final slug = url.split('/').last;

    final images = HtmlParserUtil.extractSchemaImages(jsonLd['image']);

    final offers = jsonLd['offers'];
    double price = 0;
    if (offers is Map) {
      price = double.tryParse(offers['price']?.toString() ?? '') ?? 0;
    }

    final id = int.tryParse(jsonLd['productID']?.toString() ?? '') ??
        int.tryParse(jsonLd['sku']?.toString() ?? '') ??
        url.hashCode.abs();

    return Product(
      id: id,
      name: name,
      slug: slug,
      imageUrl: images.isNotEmpty ? images.first : null,
      displayPrice: price,
    );
  }

  Failure _mapError(DioException e) {
    developer.log('[Catalog] DioException: ${e.message}, error: ${e.error}, type: ${e.type}', name: 'catalog');
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkFailure('No internet connection. Please check your network.');
    }
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const TimeoutFailure('Connection to SoftStore.pk timed out.');
    }
    final msg = e.message ?? e.error?.toString() ?? 'Server error';
    return ServerFailure(
      msg.isNotEmpty ? msg : 'Unable to connect to SoftStore.pk',
      statusCode: e.response?.statusCode,
    );
  }
}
