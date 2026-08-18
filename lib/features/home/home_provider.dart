import 'package:flutter/foundation.dart';
import '../../core/models/product.dart';
import '../../services/catalog_service.dart';
import '../../services/account_service.dart';

enum HomeLoadState { idle, loading, loaded, error }

class HomeProvider extends ChangeNotifier {
  final _catalog = CatalogService();
  final _account = AccountService();

  HomeLoadState _state = HomeLoadState.idle;
  HomeResponse? _data;
  String? _error;

  HomeLoadState get state => _state;
  HomeResponse? get data => _data;
  String? get error => _error;

  Future<void> load() async {
    _state = HomeLoadState.loading;
    _error = null;
    notifyListeners();
    try {
      final home = await _catalog.home();
      // Deduplicate featured: remove products that already appear in topDeals
      // or heroCategory rails so Just For You shows fresh content.
      final alreadyShown = <int>{
        ...home.topDeals.map((p) => p.id),
        ...home.heroCategories.expand((c) => c.products).map((p) => p.id),
      };
      home.featured = home.featured.where((p) => !alreadyShown.contains(p.id)).toList();
      _data = home;
      _state = HomeLoadState.loaded;
    } catch (e, st) {
      debugPrint('[HomeProvider] ERROR: $e\n$st');
      _error = e.toString().replaceFirst('Exception: ', '');
      _state = HomeLoadState.error;
    }
    notifyListeners();
  }

  Future<void> toggleWishlist(int productId) async {
    if (_data == null) return;
    // Optimistic update across featured and hero category products.
    final prev = HomeResponse(
      categories: _data!.categories,
      featured: List.of(_data!.featured),
      heroCategories: _data!.heroCategories,
    );

    Product toggled(Product p) =>
        p.id == productId ? p.copyWith(isWishlisted: !(p.isWishlisted ?? false)) : p;

    _data!.featured = _data!.featured.map(toggled).toList();
    notifyListeners();

    try {
      await _account.toggleWishlist(productId);
    } catch (_) {
      // Revert on failure.
      _data = prev;
      notifyListeners();
    }
  }
}
