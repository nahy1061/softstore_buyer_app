import 'package:equatable/equatable.dart';

class User extends Equatable {
  final int? id;
  final String firstName;
  final String lastName;
  final String email;
  final String phone;
  final int wishlistCount;
  final int followedCount;

  const User({
    this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phone = '',
    this.wishlistCount = 0,
    this.followedCount = 0,
  });

  String get fullName => '$firstName $lastName'.trim();

  String get initial => firstName.isNotEmpty ? firstName[0].toUpperCase() : '?';

  User copyWith({
    int? id,
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    int? wishlistCount,
    int? followedCount,
  }) {
    return User(
      id: id ?? this.id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      wishlistCount: wishlistCount ?? this.wishlistCount,
      followedCount: followedCount ?? this.followedCount,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int?,
      firstName: json['first_name'] as String? ?? '',
      lastName: json['last_name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      wishlistCount: json['wishlist_count'] as int? ?? 0,
      followedCount: json['followed_count'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'first_name': firstName,
      'last_name': lastName,
      'phone': phone,
    };
  }

  /// Parse user from HTML profile page form inputs.
  factory User.fromHtml(String html) {
    String extractInput(String source, String fieldName) {
      final pattern = RegExp(
        '<input[^>]*name=["\']$fieldName["\'][^>]*value=["\']([^"\']*)["\']',
        caseSensitive: false,
      );
      final match = pattern.firstMatch(source);
      if (match != null) return match.group(1) ?? '';

      final reversePattern = RegExp(
        '<input[^>]*value=["\']([^"\']*)["\'][^>]*name=["\']$fieldName["\']',
        caseSensitive: false,
      );
      final reverseMatch = reversePattern.firstMatch(source);
      if (reverseMatch != null) return reverseMatch.group(1) ?? '';

      return '';
    }

    // Extract wishlist count from text like "0 Wishlist" or "5 items in wishlist"
    int extractCount(String pattern) {
      final regex = RegExp(pattern);
      final match = regex.firstMatch(html);
      if (match != null) {
        return int.tryParse(match.group(1) ?? '0') ?? 0;
      }
      return 0;
    }

    return User(
      firstName: extractInput(html, 'first_name'),
      lastName: extractInput(html, 'last_name'),
      email: extractInput(html, 'email'),
      phone: extractInput(html, 'phone'),
      wishlistCount: extractCount(r'(\d+)\s*(?:Wishlist|wishlist|saved)'),
      followedCount: extractCount(r'(\d+)\s*(?:Followed|following)'),
    );
  }

  @override
  List<Object?> get props => [
        id, firstName, lastName, email, phone,
        wishlistCount, followedCount,
      ];
}
