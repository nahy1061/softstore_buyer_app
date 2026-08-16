import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cart_item.dart';
import '../constants/app_constants.dart';

class CartStore extends ChangeNotifier {
  static final CartStore instance = CartStore._();
  CartStore._();

  List<CartItem> _items = [];
  List<CartItem> _savedItems = [];

  List<CartItem> get items => List.unmodifiable(_items);
  List<CartItem> get savedItems => List.unmodifiable(_savedItems);

  int get count => _items.fold(0, (sum, i) => sum + i.quantity);
  double get subtotal => _items.fold(0.0, (sum, i) => sum + i.lineTotal);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final cartJson = prefs.getString(AppConstants.cartKey);
    final savedJson = prefs.getString(AppConstants.savedForLaterKey);
    if (cartJson != null) {
      try {
        final list = jsonDecode(cartJson) as List;
        _items = list.map((j) => CartItem.fromJson(j as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    if (savedJson != null) {
      try {
        final list = jsonDecode(savedJson) as List;
        _savedItems = list.map((j) => CartItem.fromJson(j as Map<String, dynamic>)).toList();
      } catch (_) {}
    }
    notifyListeners();
  }

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.cartKey, jsonEncode(_items.map((i) => i.toJson()).toList()));
    await prefs.setString(AppConstants.savedForLaterKey, jsonEncode(_savedItems.map((i) => i.toJson()).toList()));
  }

  void addItem(CartItem item) {
    final idx = _items.indexWhere((i) => i.id == item.id);
    if (idx >= 0) {
      _items[idx].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
    _persist();
  }

  void removeItem(String id) {
    _items.removeWhere((i) => i.id == id);
    notifyListeners();
    _persist();
  }

  void updateQuantity(String id, int quantity) {
    if (quantity <= 0) {
      removeItem(id);
      return;
    }
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      _items[idx].quantity = quantity;
      notifyListeners();
      _persist();
    }
  }

  void saveForLater(String id) {
    final idx = _items.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      final item = _items.removeAt(idx);
      _savedItems.add(item);
      notifyListeners();
      _persist();
    }
  }

  void moveToCart(String id) {
    final idx = _savedItems.indexWhere((i) => i.id == id);
    if (idx >= 0) {
      final item = _savedItems.removeAt(idx);
      addItem(item);
    }
  }

  void clear() {
    _items.clear();
    notifyListeners();
    _persist();
  }
}
