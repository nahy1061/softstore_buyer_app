import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class CartItem extends Equatable {
  final String id;
  final String productId;
  final String productName;
  final String? variantId;
  final String? variantLabel;
  final int quantity;
  final int unitPriceSnapshot;
  final int subtotalSnapshot;
  final String? imageUrl;
  final int? iconCodePoint;

  const CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    this.variantId,
    this.variantLabel,
    required this.quantity,
    required this.unitPriceSnapshot,
    required this.subtotalSnapshot,
    this.imageUrl,
    this.iconCodePoint,
  });

  int get price => unitPriceSnapshot;
  int get total => subtotalSnapshot;
  String get name => productName;

  IconData get icon => IconData(
        iconCodePoint ?? 0xe59c,
        fontFamily: 'MaterialIcons',
      );

  CartItem copyWith({
    int? quantity,
    int? subtotalSnapshot,
  }) {
    return CartItem(
      id: id,
      productId: productId,
      productName: productName,
      variantId: variantId,
      variantLabel: variantLabel,
      quantity: quantity ?? this.quantity,
      unitPriceSnapshot: unitPriceSnapshot,
      subtotalSnapshot: subtotalSnapshot ?? this.subtotalSnapshot,
      imageUrl: imageUrl,
      iconCodePoint: iconCodePoint,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'productId': productId,
        'productName': productName,
        'variantId': variantId,
        'variantLabel': variantLabel,
        'quantity': quantity,
        'unitPriceSnapshot': unitPriceSnapshot,
        'subtotalSnapshot': subtotalSnapshot,
        'imageUrl': imageUrl,
        'iconCodePoint': iconCodePoint,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id'] as String,
        productId: json['productId'] as String,
        productName: json['productName'] as String,
        variantId: json['variantId'] as String?,
        variantLabel: json['variantLabel'] as String?,
        quantity: json['quantity'] as int,
        unitPriceSnapshot: json['unitPriceSnapshot'] as int,
        subtotalSnapshot: json['subtotalSnapshot'] as int,
        imageUrl: json['imageUrl'] as String?,
        iconCodePoint: json['iconCodePoint'] as int?,
      );

  /// Build the API body shape: { id, qty, variant_id? }
  Map<String, dynamic> toApiItem() {
    final map = <String, dynamic>{
      'id': productId,
      'qty': quantity,
    };
    if (variantId != null) map['variant_id'] = variantId;
    return map;
  }

  @override
  List<Object?> get props => [
        id,
        productId,
        productName,
        variantId,
        variantLabel,
        quantity,
        unitPriceSnapshot,
        subtotalSnapshot,
        imageUrl,
        iconCodePoint,
      ];
}
