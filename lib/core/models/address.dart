class Address {
  final int id;
  final int? customerId;
  final String? label;
  final String recipientName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String? state;
  final String? postalCode;
  final String country;
  final bool isDefault;

  const Address({
    required this.id,
    this.customerId,
    this.label,
    required this.recipientName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    this.state,
    this.postalCode,
    this.country = 'PK',
    this.isDefault = false,
  });

  String get formatted {
    final parts = [addressLine1, addressLine2, city, state, postalCode]
        .where((p) => p != null && p.isNotEmpty)
        .join(', ');
    return parts;
  }

  factory Address.fromJson(Map<String, dynamic> j) => Address(
        id: j['id'] as int? ?? 0,
        customerId: j['customer_id'] as int?,
        label: j['label'] as String?,
        recipientName: j['recipient_name'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        addressLine1: j['address_line1'] as String? ?? '',
        addressLine2: j['address_line2'] as String?,
        city: j['city'] as String? ?? '',
        state: j['state'] as String?,
        postalCode: j['postal_code'] as String?,
        country: j['country'] as String? ?? 'PK',
        isDefault: j['is_default'] == true || j['is_default'] == 1,
      );
}
