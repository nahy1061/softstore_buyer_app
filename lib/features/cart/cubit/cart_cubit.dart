import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/cart_item.dart';
import '../services/cart_service.dart';
import '../services/checkout_service.dart';
import 'cart_state.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit() : super(const CartState()) {
    _loadFromStorage();
  }

  final CartService _cartService = CartService();
  final CheckoutService _checkoutService = CheckoutService();

  Future<void> _loadFromStorage() async {
    final items = await _cartService.getItems();
    emit(state.copyWith(items: items));
    if (items.isNotEmpty) _refreshShippingQuote();
  }

  void addItem(CartItem item) async {
    final updated = await _cartService.addItem(item);
    emit(state.copyWith(items: updated));
    _refreshShippingQuote();
  }

  void removeItem(String id) async {
    final updated = await _cartService.removeItem(id);
    emit(state.copyWith(items: updated));
    _refreshShippingQuote();
  }

  void updateQuantity(String id, int quantity) async {
    if (quantity <= 0) {
      removeItem(id);
      return;
    }
    final updated = await _cartService.updateQuantity(id, quantity);
    emit(state.copyWith(items: updated));
    _refreshShippingQuote();
  }

  void clearCart() async {
    await _cartService.clear();
    emit(const CartState());
  }

  /// Fetches a live shipping quote from the server whenever cart items change.
  Future<void> _refreshShippingQuote() async {
    if (state.items.isEmpty) {
      emit(state.copyWith(deliveryFee: 0, freeDelivery: false, clearQuoteError: true));
      return;
    }

    emit(state.copyWith(quoteLoading: true, clearQuoteError: true));
    try {
      final quote = await _checkoutService.getShippingQuote(state.items);
      emit(state.copyWith(
        deliveryFee: quote.deliveryFee,
        freeDelivery: quote.free,
        quoteLoading: false,
      ));
    } catch (e) {
      emit(state.copyWith(
        quoteLoading: false,
        quoteError: e.toString(),
      ));
    }
  }

  /// Manually trigger a shipping quote refresh.
  Future<void> refreshShippingQuote() async => _refreshShippingQuote();
}
