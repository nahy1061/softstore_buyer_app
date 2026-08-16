import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class CartItem extends Equatable {
  final String id;
  final String name;
  final int price;
  final int iconCodePoint;
  final int quantity;

  const CartItem({
    required this.id,
    required this.name,
    required this.price,
    required this.iconCodePoint,
    this.quantity = 1,
  });

  // ignore: non_const_argument_for_const_parameter
  IconData get icon => IconData(iconCodePoint, fontFamily: 'MaterialIcons');

  int get total => price * quantity;

  CartItem copyWith({int? quantity}) {
    return CartItem(
      id: id,
      name: name,
      price: price,
      iconCodePoint: iconCodePoint,
      quantity: quantity ?? this.quantity,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'price': price,
        'iconCodePoint': iconCodePoint,
        'quantity': quantity,
      };

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        id: json['id'] as String,
        name: json['name'] as String,
        price: json['price'] as int,
        iconCodePoint: json['iconCodePoint'] as int,
        quantity: json['quantity'] as int,
      );

  @override
  List<Object?> get props => [id, name, price, iconCodePoint, quantity];
}
