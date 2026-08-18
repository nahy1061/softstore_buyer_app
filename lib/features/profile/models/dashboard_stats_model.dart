import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final int totalOrders;
  final double totalSpent;
  final int wishlistItems;

  const DashboardStats({
    this.totalOrders = 0,
    this.totalSpent = 0.0,
    this.wishlistItems = 0,
  });

  DashboardStats copyWith({
    int? totalOrders,
    double? totalSpent,
    int? wishlistItems,
  }) {
    return DashboardStats(
      totalOrders: totalOrders ?? this.totalOrders,
      totalSpent: totalSpent ?? this.totalSpent,
      wishlistItems: wishlistItems ?? this.wishlistItems,
    );
  }

  factory DashboardStats.fromJson(Map<String, dynamic> json) {
    return DashboardStats(
      totalOrders: json['total_orders'] as int? ?? 0,
      totalSpent: (json['total_spent'] as num?)?.toDouble() ?? 0.0,
      wishlistItems: json['wishlist_items'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'total_orders': totalOrders,
      'total_spent': totalSpent,
      'wishlist_items': wishlistItems,
    };
  }

  /// Parse stats from HTML dashboard page.
  factory DashboardStats.fromHtml(String html) {
    int extractInt(String pattern) {
      final regex = RegExp(pattern);
      final match = regex.firstMatch(html);
      if (match != null) {
        final numStr = match.group(1)?.replaceAll(',', '') ?? '0';
        return int.tryParse(numStr) ?? 0;
      }
      return 0;
    }

    double extractDouble(String pattern) {
      final regex = RegExp(pattern);
      final match = regex.firstMatch(html);
      if (match != null) {
        final numStr = match.group(1)?.replaceAll(',', '') ?? '0';
        return double.tryParse(numStr) ?? 0.0;
      }
      return 0.0;
    }

    return DashboardStats(
      totalOrders: extractInt(r'(\d+)\s*(?:orders?|total)'),
      totalSpent: extractDouble(r'Rs\.?\s*([\d,]+)'),
      wishlistItems: extractInt(r'(\d+)\s*(?:wishlist|saved)'),
    );
  }

  @override
  List<Object?> get props => [totalOrders, totalSpent, wishlistItems];
}
