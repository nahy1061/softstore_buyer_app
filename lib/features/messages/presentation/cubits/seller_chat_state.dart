import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../models/chat_message_model.dart';
import '../../models/conversation_model.dart';

@immutable
abstract class SellerChatState extends Equatable {
  const SellerChatState();

  @override
  List<Object?> get props => [];
}

class SellerChatInitial extends SellerChatState {
  const SellerChatInitial();
}

class SellerChatLoading extends SellerChatState {
  const SellerChatLoading();
}

class SellerChatLoaded extends SellerChatState {
  final String threadUrl;
  final List<ChatMessage> messages;
  final bool isSending;
  final String? errorMessage;
  final ConversationThread? threadInfo;
  final int? productId;
  final String? productName;
  final String? productImage;
  final String? sellerName;

  const SellerChatLoaded({
    required this.threadUrl,
    required this.messages,
    this.isSending = false,
    this.errorMessage,
    this.threadInfo,
    this.productId,
    this.productName,
    this.productImage,
    this.sellerName,
  });

  SellerChatLoaded copyWith({
    String? threadUrl,
    List<ChatMessage>? messages,
    bool? isSending,
    String? errorMessage,
    ConversationThread? threadInfo,
    int? productId,
    String? productName,
    String? productImage,
    String? sellerName,
  }) {
    return SellerChatLoaded(
      threadUrl: threadUrl ?? this.threadUrl,
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      errorMessage: errorMessage,
      threadInfo: threadInfo ?? this.threadInfo,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      productImage: productImage ?? this.productImage,
      sellerName: sellerName ?? this.sellerName,
    );
  }

  @override
  List<Object?> get props => [
        threadUrl,
        messages,
        isSending,
        errorMessage,
        threadInfo,
        productId,
        productName,
        productImage,
        sellerName,
      ];
}

class SellerChatError extends SellerChatState {
  final String message;

  const SellerChatError(this.message);

  @override
  List<Object?> get props => [message];
}
