import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cart_models.dart';
import '../repository/cart_repository.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState()) {
    _loadFromStorage();
  }

  final CartRepository _repo = CartRepository.instance;

  Future<void> _loadFromStorage() async {
    final items = await _repo.getCart();
    emit(state.copyWith(items: items));
  }

  void addItem(CartItem item) async {
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

  void removeItem(String id) async {
    final items = await _repo.getCart();
    final updated = items.where((i) => i.id != id).toList();
    await _repo.saveCart(updated);
    emit(state.copyWith(items: updated));
  }

  void updateQuantity(String id, int quantity) async {
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

  void clearCart() async {
    await _repo.clearCart();
    emit(const CartState());
  }
}
