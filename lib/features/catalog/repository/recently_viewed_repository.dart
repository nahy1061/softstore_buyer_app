import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/storage_keys.dart';
import '../models/catalog_models.dart';

/// Manages recently viewed products in local storage (SharedPreferences).
class RecentlyViewedRepository {
  RecentlyViewedRepository._();
  static final RecentlyViewedRepository instance = RecentlyViewedRepository._();

  static const int _maxItems = 20;

  /// Records a viewed product, moving it to the front and persisting to SharedPreferences.
  Future<void> recordProductView(Product product) async {
    if (product.slug.isEmpty && product.id <= 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentList = await getRecentlyViewed();

      // Remove existing duplicate by id or slug
      final updated = currentList
          .where((p) =>
              (product.id > 0 ? p.id != product.id : true) &&
              (product.slug.isNotEmpty ? p.slug != product.slug : true))
          .toList();

      // Insert at the front (most recent)
      updated.insert(0, product);

      // Keep only up to _maxItems
      final toSave = updated.take(_maxItems).toList();

      final jsonStringList = toSave.map((p) => jsonEncode(p.toJson())).toList();
      await prefs.setStringList(StorageKeys.recentlyViewed, jsonStringList);
    } catch (_) {}
  }

  /// Retrieves the list of recently viewed products from local storage.
  Future<List<Product>> getRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = prefs.getStringList(StorageKeys.recentlyViewed);
      if (list == null || list.isEmpty) {
        return [];
      }
      return list
          .map((item) {
            try {
              return Product.fromJson(jsonDecode(item) as Map<String, dynamic>);
            } catch (_) {
              return null;
            }
          })
          .whereType<Product>()
          .where((p) => p.name.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Clears recently viewed products.
  Future<void> clearRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(StorageKeys.recentlyViewed);
    } catch (_) {}
  }
}
