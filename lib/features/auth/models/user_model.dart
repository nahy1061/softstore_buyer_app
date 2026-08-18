import 'package:equatable/equatable.dart';

/// Represents an authenticated SoftStore buyer.
class User extends Equatable {
  final String? id;
  final String firstName;
  final String lastName;
  final String email;
  final String? phone;

  const User({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone,
  });

  String get fullName => '$firstName $lastName'.trim();

  User copyWith({
    String? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
    );
  }

  @override
  List<Object?> get props => [id, firstName, lastName, email, phone];

  @override
  String toString() => 'User(email: $email, name: $fullName)';
}
