import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/csrf_service.dart';
import '../../../core/utils/html_parser_util.dart';
import '../../catalog/models/catalog_models.dart';

/// Manages the wishlist — fetching from server and toggling items.
///
/// Quirks documented in API_MAPPING.md:
///  - Wishlist HTML uses `onclick="mpToggleWishlist(ID)"` — ID must be parsed from onclick
///  - CSRF token for toggle must come from the PRODUCT PAGE, not the wishlist page
///  - Toggle returns JSON {success, added}
class WishlistRepository {
  WishlistRepository._();
  static final WishlistRepository instance = WishlistRepository._();

  final DioClient _client = DioClient();
  final CsrfService _csrf = CsrfService.instance;

  // In-memory synced cache for immediate consistency
  final Map<String, Product> _cachedWishlist = {};

  // ─── Get Wishlist ──────────────────────────────────────────────────────────

  Future<List<Product>> getWishlist() async {
    try {
      final response = await _client.get<String>(
        ApiEndpoints.wishlistPage,
        options: Options(responseType: ResponseType.plain),
      );
      final remoteList = _parseWishlist(response.data ?? '');
      for (final p in remoteList) {
        _cachedWishlist[p.slug] = p;
      }
      return _cachedWishlist.values.toList();
    } on DioException catch (e) {
      if (_cachedWishlist.isNotEmpty) {
        return _cachedWishlist.values.toList();
      }
      throw _mapError(e);
    } catch (_) {
      return _cachedWishlist.values.toList();
    }
  }

  bool isProductWishlisted(String slug) {
    return _cachedWishlist.containsKey(slug);
  }

  void addLocalProduct(Product product) {
    _cachedWishlist[product.slug] = product;
  }

  void removeLocalProduct(String slug) {
    _cachedWishlist.remove(slug);
  }

  List<Product> _parseWishlist(String html) {
    final doc = HtmlParserUtil.parse(html);
    final products = <Product>[];

    // Wishlist uses m-feature-card divs with mpToggleWishlist(ID) onclick
    final cards = doc.querySelectorAll(
        '[onclick*="mpToggleWishlist"], .m-feature-card, .wishlist-item');

    for (final card in cards) {
      try {
        // Extract ID from onclick="mpToggleWishlist(12345)"
        final onclick = card.attributes['onclick'] ??
            card.querySelector('[onclick*="mpToggleWishlist"]')
                ?.attributes['onclick'] ??
            '';
        final idMatch = RegExp(r'mpToggleWishlist\((\d+)\)').firstMatch(onclick);
        final id = int.tryParse(idMatch?.group(1) ?? '');
        if (id == null) continue;

        final nameEl = card.querySelector('.product-name, h3, h4, .name, a');
        final name = nameEl?.text.trim() ?? '';

        final imgEl = card.querySelector('img');
        final imageUrl = imgEl != null
            ? HtmlParserUtil.toAbsoluteUrl(
                imgEl.attributes['src'] ?? imgEl.attributes['data-src'] ?? '')
            : null;

        // Price is in separate div outside product link per docs
        final priceText = card.querySelector('.price, .product-price')?.text ?? '';
        final price = double.tryParse(
                priceText
                    .replaceAll('PKR', '')
                    .replaceAll('Rs', '')
                    .replaceAll(',', '')
                    .trim()) ??
            0;

        final linkEl = card.querySelector('a[href*="/product/"]');
        final href = linkEl?.attributes['href'] ?? '';
        final slug = href.split('/').last;

        products.add(Product(
          id: id,
          name: name,
          slug: slug,
          imageUrl: imageUrl,
          displayPrice: price,
        ));
      } catch (e) {
        developer.log('[Wishlist] Parse error: $e', name: 'wishlist');
      }
    }

    return products;
  }

  // ─── Toggle Wishlist ───────────────────────────────────────────────────────

  /// Adds or removes [productSlug] from the wishlist.
  ///
  /// Returns true if the item was added, false if removed.
  ///
  /// IMPORTANT: CSRF token MUST come from the product detail page,
  /// not the wishlist page (which has no CSRF token).
  Future<bool> toggleWishlist({
    required int productId,
    required String productSlug,
    Product? product,
  }) async {
    bool isAdded = true;
    try {
      // Fetch CSRF from the product page (as documented)
      final csrfToken = await _csrf.fetchToken(
          '${ApiEndpoints.productDetail}$productSlug') ??
          await _csrf.fetchToken(ApiEndpoints.homepage);

      try {
        final response = await _client.post(
          ApiEndpoints.toggleWishlist,
          data: {
            if (csrfToken != null) ...{
              '_csrf_token': csrfToken,
              'csrf_token': csrfToken,
            },
            'product_id': productId,
          },
          options: Options(
            contentType: 'application/x-www-form-urlencoded',
            responseType: ResponseType.plain,
          ),
        );

        final raw = response.data;
        if (raw != null) {
          final str = raw.toString();
          if (str.contains('"added":true') ||
              str.contains('"added": 1') ||
              str.contains('"status":"added"') ||
              str.contains('"in_wishlist":true') ||
              str.contains('added to wishlist')) {
            isAdded = true;
          } else if (str.contains('"added":false') ||
              str.contains('"added": 0') ||
              str.contains('"status":"removed"') ||
              str.contains('"in_wishlist":false') ||
              str.contains('removed from wishlist')) {
            isAdded = false;
          }
        }
      } catch (_) {
        final fallbackRes = await _client.post(
          '/api/marketplace/wishlist/toggle',
          data: {
            if (csrfToken != null) ...{
              '_csrf_token': csrfToken,
              'csrf_token': csrfToken,
            },
            'product_id': productId,
          },
          options: Options(
            contentType: 'application/x-www-form-urlencoded',
            responseType: ResponseType.plain,
          ),
        );
        final raw = fallbackRes.data;
        if (raw != null) {
          final str = raw.toString();
          if (str.contains('"added":true') || str.contains('"in_wishlist":true')) {
            isAdded = true;
          } else if (str.contains('"added":false') || str.contains('"in_wishlist":false')) {
            isAdded = false;
          }
        }
      }
    } on DioException catch (e) {
      developer.log('[Wishlist] DioException: ${e.message}', name: 'wishlist');
      // If network fails, toggle locally
      isAdded = !_cachedWishlist.containsKey(productSlug);
    } catch (_) {
      isAdded = !_cachedWishlist.containsKey(productSlug);
    }

    if (isAdded) {
      if (product != null) {
        _cachedWishlist[productSlug] = product;
      } else if (!_cachedWishlist.containsKey(productSlug)) {
        _cachedWishlist[productSlug] = Product(
          id: productId,
          name: productSlug.replaceAll('-', ' '),
          slug: productSlug,
          displayPrice: 0.0,
        );
      }
    } else {
      _cachedWishlist.remove(productSlug);
    }

    return isAdded;
  }

  Failure _mapError(DioException e) {
    developer.log('[Wishlist] DioException: ${e.message}', name: 'wishlist');
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkFailure('No internet connection.');
    }
    return ServerFailure(e.message ?? 'Server error',
        statusCode: e.response?.statusCode);
  }
}
