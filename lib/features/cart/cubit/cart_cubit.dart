import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../core/storage/hive_service.dart';
import '../models/cart_models.dart';
import '../repository/cart_repository.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState()) {
    _currentUserId = 'guest';
    _loadFromStorage();
  }

  final CartRepository _repo = CartRepository.instance;
  String _currentUserId = 'guest';

  Future<void> _loadFromStorage() async {
    final items = await _repo.getCart();
    emit(state.copyWith(items: items));
  }

  /// Reloads the cart for a different user.
  ///
  /// Switches the underlying Hive box to the user-specific box,
  /// migrates any items added while browsing as guest to the user account,
  /// and updates in-memory state with selection preserved.
  Future<void> reloadForUser(String? userId) async {
    final sanitized = HiveService.sanitizeUserId(userId);
    if (sanitized == _currentUserId) return;

    final wasGuest = _currentUserId == 'guest';
    final previousItems = state.items;
    final previousSelection = state.selectedIds;

    _currentUserId = sanitized;

    developer.log(
        '[CartCubit] Reloading cart for user: $sanitized (wasGuest: $wasGuest, items: ${previousItems.length})',
        name: 'cart');

    await HiveService.setCartUser(userId);
    final userItems = await _repo.getCart();

    if (wasGuest && previousItems.isNotEmpty) {
      final merged = List<CartItem>.from(userItems);
      for (final gItem in previousItems) {
        final idx = merged.indexWhere((i) =>
            i.productId == gItem.productId && i.variantId == gItem.variantId);
        if (idx >= 0) {
          merged[idx] =
              merged[idx].copyWith(quantity: merged[idx].quantity + gItem.quantity);
        } else {
          merged.add(gItem);
        }
      }
      await _repo.saveCart(merged);
      await HiveService.clearItemsForUser('guest');

      emit(state.copyWith(
        items: merged,
        selectedIds: previousSelection.isNotEmpty ? previousSelection : null,
      ));
    } else {
      emit(CartState(
        items: userItems,
        selectedIds: previousSelection
            .intersection(userItems.map((i) => i.id).toSet()),
      ));
    }
  }

  /// Syncs the current local cart to the server session.
  ///
  /// Called after login or session restore so the backend session cart
  /// reflects the local Hive cart. Non-blocking — errors are logged only.
  Future<void> syncToServer() async {
    try {
      await _repo.syncCartToServer(state.items);
    } catch (e) {
      developer.log('[CartCubit] syncToServer notice: $e', name: 'cart');
    }
  }

  Future<void> addItem(CartItem item) async {
    final items = await _repo.getCart();
    final existingIndex = items.indexWhere(
        (i) => i.productId == item.productId && i.variantId == item.variantId);

    List<CartItem> updated;
    if (existingIndex >= 0) {
      updated = List<CartItem>.from(items);
      final existing = updated[existingIndex];
      final newQty = existing.quantity + item.quantity;
      updated[existingIndex] = existing.copyWith(quantity: newQty);
    } else {
      updated = [...items, item];
    }
    await _repo.saveCart(updated);
    emit(state.copyWith(items: updated));
  }

  Future<void> removeItem(String id) async {
    final items = await _repo.getCart();
    final updated = items.where((i) => i.id != id).toList();
    await _repo.saveCart(updated);
    final cleanedSelection = Set<String>.from(state.selectedIds)..remove(id);
    emit(state.copyWith(
      items: updated,
      selectedIds: cleanedSelection,
    ));
  }

  Future<void> removeItems(Set<String> ids) async {
    final items = await _repo.getCart();
    final updated = items.where((i) => !ids.contains(i.id)).toList();
    await _repo.saveCart(updated);
    final cleanedSelection = state.selectedIds.difference(ids);
    emit(state.copyWith(
      items: updated,
      selectedIds: cleanedSelection,
    ));
  }

  Future<void> updateQuantity(String id, int quantity) async {
    if (quantity <= 0) {
      removeItem(id);
      return;
    }
    final items = await _repo.getCart();
    final updated = items.map((i) {
      if (i.id != id) return i;
      return i.copyWith(quantity: quantity);
    }).toList();
    await _repo.saveCart(updated);
    emit(state.copyWith(items: updated));
  }

  void toggleSelection(String id) {
    final current = Set<String>.from(state.selectedIds);
    if (current.contains(id)) {
      current.remove(id);
    } else {
      current.add(id);
    }
    emit(state.copyWith(selectedIds: current));
  }

  void selectAll() {
    final ids = state.items.map((i) => i.id).toSet();
    emit(state.copyWith(selectedIds: ids));
  }

  void clearSelection() {
    emit(state.copyWith(clearSelectedIds: true));
  }

  Future<void> removeSelected() async {
    if (state.selectedIds.isEmpty) return;
    await removeItems(state.selectedIds);
  }

  Future<void> clearCart() async {
    await _repo.clearCart();
    emit(const CartState());
  }
}
