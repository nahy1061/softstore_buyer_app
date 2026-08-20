import 'package:equatable/equatable.dart';
import '../models/cart_models.dart';

class CartState extends Equatable {
  final List<CartItem> items;
  final Set<String> selectedIds;
  final double deliveryFee;
  final bool freeDelivery;
  final bool quoteLoading;
  final String? quoteError;

  const CartState({
    this.items = const [],
    this.selectedIds = const {},
    this.deliveryFee = 0,
    this.freeDelivery = false,
    this.quoteLoading = false,
    this.quoteError,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);
  double get subtotal => items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get totalPrice => subtotal;

  double get total {
    final fee = freeDelivery ? 0 : deliveryFee;
    return subtotal + fee;
  }

  bool get allSelected =>
      items.isNotEmpty && items.every((i) => selectedIds.contains(i.id));
  bool get hasSelection => selectedIds.isNotEmpty;
  bool get isPartiallySelected => selectedIds.isNotEmpty && !allSelected;

  List<CartItem> get selectedItems => selectedIds.isEmpty
      ? const []
      : items.where((i) => selectedIds.contains(i.id)).toList();

  int get selectedItemCount =>
      selectedItems.fold(0, (sum, item) => sum + item.quantity);

  double get selectedSubtotal =>
      selectedItems.fold(0.0, (sum, item) => sum + item.subtotal);

  double get selectedTotal {
    final fee = freeDelivery ? 0 : deliveryFee;
    return selectedSubtotal + fee;
  }

  bool containsItem(String id) => items.any((i) => i.id == id);

  CartState copyWith({
    List<CartItem>? items,
    Set<String>? selectedIds,
    double? deliveryFee,
    bool? freeDelivery,
    bool? quoteLoading,
    String? quoteError,
    bool clearQuoteError = false,
    bool clearSelectedIds = false,
  }) {
    return CartState(
      items: items ?? this.items,
      selectedIds: clearSelectedIds
          ? const {}
          : (selectedIds ?? this.selectedIds),
      deliveryFee: deliveryFee ?? this.deliveryFee,
      freeDelivery: freeDelivery ?? this.freeDelivery,
      quoteLoading: quoteLoading ?? this.quoteLoading,
      quoteError: clearQuoteError ? null : (quoteError ?? this.quoteError),
    );
  }

  @override
  List<Object?> get props => [
        items,
        selectedIds,
        deliveryFee,
        freeDelivery,
        quoteLoading,
        quoteError,
      ];
}
