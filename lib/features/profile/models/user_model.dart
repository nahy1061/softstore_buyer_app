import 'package:equatable/equatable.dart';
import '../../../core/utils/html_parser_util.dart';

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
    final doc = HtmlParserUtil.parse(html);

    String inputVal(List<String> names) {
      for (final name in names) {
        final el = doc.querySelector('input[name="$name"], input#$name');
        if (el != null) {
          final val = el.attributes['value']?.trim() ?? '';
          if (val.isNotEmpty) return val;
        }
      }
      return '';
    }

    String firstName = inputVal(['first_name', 'firstName', 'user_first_name']);
    String lastName = inputVal(['last_name', 'lastName', 'user_last_name']);
    final email = inputVal(['email', 'user_email', 'email_address']);
    final phone = inputVal(['phone', 'phone_number', 'user_phone', 'mobile']);

    if (firstName.isEmpty && lastName.isEmpty) {
      final fullName = inputVal(['name', 'full_name', 'user_name']);
      if (fullName.isNotEmpty) {
        final parts = fullName.split(' ');
        firstName = parts.first;
        lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }
    }

    // Also check header display name if inputs were empty
    if (firstName.isEmpty) {
      final headingName = doc.querySelector('.profile-name, .user-name, h1, h2, h3, h4')?.text.trim() ?? '';
      if (headingName.isNotEmpty &&
          !headingName.toLowerCase().contains('profile') &&
          !headingName.toLowerCase().contains('account') &&
          !headingName.toLowerCase().contains('login') &&
          !headingName.toLowerCase().contains('softstore')) {
        final parts = headingName.split(' ');
        firstName = parts.first;
        lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      }
    }

    // Extract wishlist count from text like "0 Wishlist" or "5 items in wishlist"
    int extractCount(String pattern) {
      final regex = RegExp(pattern, caseSensitive: false);
      final match = regex.firstMatch(html);
      if (match != null) {
        return int.tryParse(match.group(1) ?? '0') ?? 0;
      }
      return 0;
    }

    return User(
      firstName: firstName,
      lastName: lastName,
      email: email,
      phone: phone,
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
