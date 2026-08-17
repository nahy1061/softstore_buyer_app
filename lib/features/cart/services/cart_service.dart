import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/storage_keys.dart';
import '../models/cart_item.dart';

/// Client-side cart persistence backed by SharedPreferences.
/// No server-side cart exists — this is entirely local storage.
class CartService {
  static const String _storageKey = StorageKeys.cartItems;

  Future<List<CartItem>> getItems() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_storageKey);
    if (raw == null || raw.isEmpty) return [];
    return raw
        .map((e) => CartItem.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
  }

  Future<void> _saveItems(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = items.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_storageKey, raw);
  }

  /// Adds an item to the cart. If an item with the same productId + variantId
  /// already exists, merges the quantity instead of duplicating.
  Future<List<CartItem>> addItem(CartItem item) async {
    final items = await getItems();
    final existingIndex = items.indexWhere((i) =>
        i.productId == item.productId && i.variantId == item.variantId);

    List<CartItem> updated;
    if (existingIndex >= 0) {
      updated = List<CartItem>.from(items);
      final existing = updated[existingIndex];
      final newQty = existing.quantity + item.quantity;
      updated[existingIndex] = existing.copyWith(
        quantity: newQty,
        subtotalSnapshot: existing.unitPriceSnapshot * newQty,
      );
    } else {
      updated = [...items, item];
    }
    await _saveItems(updated);
    return updated;
  }

  /// Updates the quantity of an item by its cart id.
  Future<List<CartItem>> updateQuantity(String id, int quantity) async {
    final items = await getItems();
    final updated = items.map((i) {
      if (i.id != id) return i;
      return i.copyWith(
        quantity: quantity,
        subtotalSnapshot: i.unitPriceSnapshot * quantity,
      );
    }).toList();
    await _saveItems(updated);
    return updated;
  }

  /// Removes an item by its cart id.
  Future<List<CartItem>> removeItem(String id) async {
    final items = await getItems();
    final updated = items.where((i) => i.id != id).toList();
    await _saveItems(updated);
    return updated;
  }

  /// Clears the entire cart.
  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  /// Calculates the subtotal of all items in the cart.
  int getSubtotal(List<CartItem> items) {
    return items.fold(0, (sum, item) => sum + item.subtotalSnapshot);
  }
}
