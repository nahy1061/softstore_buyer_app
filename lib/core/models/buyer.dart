class Buyer {
  final int id;
  final String? firstName;
  final String? lastName;
  final String email;
  final String? phone;
  final bool emailVerified;

  const Buyer({
    required this.id,
    this.firstName,
    this.lastName,
    required this.email,
    this.phone,
    this.emailVerified = false,
  });

  String get fullName {
    final parts = [firstName, lastName].where((p) => p != null && p.isNotEmpty);
    return parts.join(' ').trim().isEmpty ? email.split('@').first : parts.join(' ');
  }

  String get initials {
    final n = fullName;
    final parts = n.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  factory Buyer.fromJson(Map<String, dynamic> j) => Buyer(
        id: j['id'] as int? ?? 0,
        firstName: j['first_name'] as String?,
        lastName: j['last_name'] as String?,
        email: j['email'] as String? ?? '',
        phone: j['phone'] as String?,
        emailVerified: j['email_verified'] == true || j['email_verified'] == 1,
      );
}

class BuyerDashboardStats {
  final int totalOrders;
  final double totalSpent;
  final int wishlistItems;

  const BuyerDashboardStats({
    this.totalOrders = 0,
    this.totalSpent = 0,
    this.wishlistItems = 0,
  });
}

class WishlistItem {
  final int id;
  final int productId;
  final String productName;
  final double sellingPrice;
  final String? imageUrl;

  const WishlistItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.sellingPrice,
    this.imageUrl,
  });
}
