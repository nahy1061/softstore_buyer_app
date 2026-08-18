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

  // ─── Get Wishlist ──────────────────────────────────────────────────────────

  Future<List<Product>> getWishlist() async {
    try {
      final response = await _client.get<String>(
        ApiEndpoints.wishlistPage,
        options: Options(responseType: ResponseType.plain),
      );
      return _parseWishlist(response.data ?? '');
    } on DioException catch (e) {
      throw _mapError(e);
    }
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
  }) async {
    try {
      // Fetch CSRF from the product page (as documented)
      final csrfToken = await _csrf.fetchToken(
          '${ApiEndpoints.productDetail}$productSlug');

      final response = await _client.post<Map<String, dynamic>>(
        ApiEndpoints.toggleWishlist,
        data: {
          if (csrfToken != null) '_csrf_token': csrfToken,
          'product_id': productId,
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
        ),
      );

      final data = response.data;
      if (data == null) return false;
      return data['added'] == true;
    } on DioException catch (e) {
      throw _mapError(e);
    }
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
