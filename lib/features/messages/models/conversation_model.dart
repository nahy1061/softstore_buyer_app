import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

@immutable
class ConversationThread extends Equatable {
  final String id;
  final String threadUrl;
  final String sellerName;
  final String? sellerAvatar;
  final int? sellerId;
  final int? productId;
  final String? productName;
  final String? productImage;
  final double? productPrice;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;
  final bool isUnread;

  const ConversationThread({
    required this.id,
    required this.threadUrl,
    required this.sellerName,
    this.sellerAvatar,
    this.sellerId,
    this.productId,
    this.productName,
    this.productImage,
    this.productPrice,
    required this.lastMessage,
    required this.lastMessageTime,
    this.unreadCount = 0,
    this.isUnread = false,
  });

  ConversationThread copyWith({
    String? id,
    String? threadUrl,
    String? sellerName,
    String? sellerAvatar,
    int? sellerId,
    int? productId,
    String? productName,
    String? productImage,
    double? productPrice,
    String? lastMessage,
    DateTime? lastMessageTime,
    int? unreadCount,
    bool? isUnread,
  }) {
    return ConversationThread(
      id: id ?? this.id,
      threadUrl: threadUrl ?? this.threadUrl,
      sellerName: sellerName ?? this.sellerName,
      sellerAvatar: sellerAvatar ?? this.sellerAvatar,
      sellerId: sellerId ?? this.sellerId,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      productPrice: productPrice ?? this.productPrice,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageTime: lastMessageTime ?? this.lastMessageTime,
      unreadCount: unreadCount ?? this.unreadCount,
      isUnread: isUnread ?? this.isUnread,
    );
  }

  factory ConversationThread.fromJson(Map<String, dynamic> json) {
    final rawDate = json['last_message_time'] ?? json['timestamp'] ?? json['lastMessageTime'];
    DateTime parsedDate = DateTime.now();
    if (rawDate is String && rawDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    }

    final dynamic rawPrice = json['product_price'] ?? json['productPrice'];
    double? parsedPrice;
    if (rawPrice is num) {
      parsedPrice = rawPrice.toDouble();
    } else if (rawPrice is String && rawPrice.isNotEmpty) {
      parsedPrice = double.tryParse(rawPrice.replaceAll(RegExp(r'[^0-9.]'), ''));
    }

    final unread = json['is_unread'] ?? json['unread'] ?? false;
    final unreadCountVal = json['unread_count'] ?? json['unreadCount'] ?? (unread == true ? 1 : 0);

    return ConversationThread(
      id: json['id']?.toString() ?? json['thread_url']?.toString() ?? '',
      threadUrl: json['thread_url'] as String? ?? json['threadUrl'] as String? ?? '',
      sellerName: json['seller_name'] as String? ?? json['sellerName'] as String? ?? 'Seller',
      sellerAvatar: json['seller_avatar'] as String? ?? json['sellerAvatar'] as String?,
      sellerId: json['seller_id'] is int
          ? json['seller_id'] as int
          : int.tryParse(json['seller_id']?.toString() ?? ''),
      productId: json['product_id'] is int
          ? json['product_id'] as int
          : int.tryParse(json['product_id']?.toString() ?? ''),
      productName: json['product_name'] as String? ?? json['productName'] as String?,
      productImage: json['product_image'] as String? ?? json['productImage'] as String?,
      productPrice: parsedPrice,
      lastMessage: json['last_message'] as String? ?? json['lastMessage'] as String? ?? '',
      lastMessageTime: parsedDate,
      unreadCount: unreadCountVal is int ? unreadCountVal : (int.tryParse(unreadCountVal.toString()) ?? 0),
      isUnread: unread == true || (unreadCountVal is int && unreadCountVal > 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'thread_url': threadUrl,
      'seller_name': sellerName,
      'seller_avatar': sellerAvatar,
      'seller_id': sellerId,
      'product_id': productId,
      'product_name': productName,
      'product_image': productImage,
      'product_price': productPrice,
      'last_message': lastMessage,
      'last_message_time': lastMessageTime.toIso8601String(),
      'unread_count': unreadCount,
      'is_unread': isUnread,
    };
  }

  @override
  List<Object?> get props => [
        id,
        threadUrl,
        sellerName,
        sellerAvatar,
        sellerId,
        productId,
        productName,
        productImage,
        productPrice,
        lastMessage,
        lastMessageTime,
        unreadCount,
        isUnread,
      ];
}
