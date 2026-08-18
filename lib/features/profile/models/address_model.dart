import 'package:equatable/equatable.dart';

class Address extends Equatable {
  final int? id;
  final String label;
  final String name;
  final String phone;
  final String address;
  final String city;
  final bool isDefault;

  const Address({
    this.id,
    required this.label,
    required this.name,
    required this.phone,
    required this.address,
    this.city = '',
    this.isDefault = false,
  });

  Address copyWith({
    int? id,
    String? label,
    String? name,
    String? phone,
    String? address,
    String? city,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      label: label ?? this.label,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      city: city ?? this.city,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  factory Address.fromJson(Map<String, dynamic> json) {
    return Address(
      id: json['id'] as int?,
      label: json['label'] as String? ?? '',
      name: json['name'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      address: json['address'] as String? ?? '',
      city: json['city'] as String? ?? '',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'label': label,
      'name': name,
      'phone': phone,
      'address': address,
      'city': city,
      'set_default': isDefault,
    };
  }

  /// Parse addresses from HTML page.
  /// Each address card contains label, name, phone, address info.
  factory Address.fromHtml(String html, {int? id}) {
    return Address(
      id: id,
      label: '',
      name: '',
      phone: '',
      address: html,
    );
  }

  @override
  List<Object?> get props => [id, label, name, phone, address, city, isDefault];
}
