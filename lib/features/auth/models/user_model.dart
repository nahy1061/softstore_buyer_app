import 'package:equatable/equatable.dart';

/// Represents an authenticated SoftStore buyer.
class User extends Equatable {
  final String? id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;
  final bool isEmailVerified;

  const User({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
    this.isEmailVerified = false,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    final name = json['name']?.toString() ?? '';
    final nameParts = name.trim().split(RegExp(r'\s+'));
    final first = json['first_name']?.toString() ??
        (nameParts.isNotEmpty ? nameParts.first : '');
    final last = json['last_name']?.toString() ??
        (nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '');

    final dynamic ev = json['email_verified'] ??
        json['is_email_verified'] ??
        json['is_verified'];
    final bool verified = ev == true ||
        ev == 1 ||
        ev == '1' ||
        ev == 'true' ||
        json['email_verified_at'] != null;

    return User(
      id: json['id']?.toString(),
      firstName: first,
      lastName: last,
      email: json['email']?.toString() ?? '',
      phone: json['phone']?.toString(),
      isEmailVerified: verified,
    );
  }

  /// Alias for [isEmailVerified] for domain consistency.
  bool get emailVerified => isEmailVerified;

  String get fullName => '$firstName $lastName'.trim();

  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    bool? isEmailVerified,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }

  @override
  List<Object?> get props =>
      [id, firstName, lastName, email, phone, isEmailVerified];

  @override
  String toString() =>
      'User(email: $email, name: $fullName, verified: $isEmailVerified)';
}
