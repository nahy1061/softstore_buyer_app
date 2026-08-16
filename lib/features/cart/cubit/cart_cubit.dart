
import 'dart:convert';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/storage_keys.dart';
import '../models/cart_item.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState()) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(StorageKeys.cartItems);
    if (raw == null || raw.isEmpty) return;
    final items = raw
        .map((e) => CartItem.fromJson(jsonDecode(e) as Map<String, dynamic>))
        .toList();
    emit(CartState(items: items));
  }

  Future<void> _saveToStorage(List<CartItem> items) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = items.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(StorageKeys.cartItems, raw);
  }

  void addItem(CartItem item) {
    final index = state.items.indexWhere((i) => i.id == item.id);
    List<CartItem> updated;
    if (index >= 0) {
      updated = List<CartItem>.from(state.items);
      updated[index] = updated[index].copyWith(
        quantity: updated[index].quantity + 1,
      );
    } else {
      updated = [...state.items, item];
    }
    emit(state.copyWith(items: updated));
    _saveToStorage(updated);
  }

  void removeItem(String id) {
    final updated = state.items.where((i) => i.id != id).toList();
    emit(state.copyWith(items: updated));
    _saveToStorage(updated);
  }

  void updateQuantity(String id, int quantity) {
    if (quantity <= 0) {
      removeItem(id);
      return;
    }
    final updated = state.items
        .map((i) => i.id == id ? i.copyWith(quantity: quantity) : i)
        .toList();
    emit(state.copyWith(items: updated));
    _saveToStorage(updated);
  }

  void clearCart() {
    emit(const CartState());
    _saveToStorage([]);
  }
}
