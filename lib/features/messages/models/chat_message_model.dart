import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

enum MessageSender {
  buyer,
  seller,
  system;

  static MessageSender fromString(String? value) {
    if (value == null) return MessageSender.buyer;
    final lower = value.toLowerCase().trim();
    if (lower == 'seller' || lower == 'store' || lower == 'vendor') {
      return MessageSender.seller;
    }
    if (lower == 'system') {
      return MessageSender.system;
    }
    return MessageSender.buyer;
  }
}

enum MessageStatus {
  sending,
  sent,
  failed;

  static MessageStatus fromString(String? value) {
    if (value == null) return MessageStatus.sent;
    final lower = value.toLowerCase().trim();
    if (lower == 'sending') return MessageStatus.sending;
    if (lower == 'failed' || lower == 'error') return MessageStatus.failed;
    return MessageStatus.sent;
  }
}

@immutable
class ChatMessage extends Equatable {
  final int id;
  final String? threadUrl;
  final MessageSender sender;
  final String text;
  final DateTime sentAt;
  final MessageStatus status;
  final String? clientSideId;

  const ChatMessage({
    required this.id,
    this.threadUrl,
    required this.sender,
    required this.text,
    required this.sentAt,
    this.status = MessageStatus.sent,
    this.clientSideId,
  });

  bool get isFromBuyer => sender == MessageSender.buyer;
  bool get isFromSeller => sender == MessageSender.seller;
  bool get isSending => status == MessageStatus.sending;
  bool get isFailed => status == MessageStatus.failed;

  ChatMessage copyWith({
    int? id,
    String? threadUrl,
    MessageSender? sender,
    String? text,
    DateTime? sentAt,
    MessageStatus? status,
    String? clientSideId,
  }) {
    return ChatMessage(
      id: id ?? this.id,
      threadUrl: threadUrl ?? this.threadUrl,
      sender: sender ?? this.sender,
      text: text ?? this.text,
      sentAt: sentAt ?? this.sentAt,
      status: status ?? this.status,
      clientSideId: clientSideId ?? this.clientSideId,
    );
  }

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    final rawDate = json['sent_at'] ?? json['sentAt'] ?? json['timestamp'];
    DateTime parsedDate = DateTime.now();
    if (rawDate is String && rawDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else if (rawDate is int) {
      parsedDate = DateTime.fromMillisecondsSinceEpoch(rawDate);
    }

    return ChatMessage(
      id: json['id'] is int
          ? json['id'] as int
          : int.tryParse(json['id']?.toString() ?? '') ?? DateTime.now().millisecondsSinceEpoch,
      threadUrl: json['thread_url'] as String? ?? json['threadUrl'] as String?,
      sender: json['sender'] is MessageSender
          ? json['sender'] as MessageSender
          : MessageSender.fromString(json['sender']?.toString()),
      text: json['text'] as String? ?? json['message'] as String? ?? '',
      sentAt: parsedDate,
      status: json['status'] is MessageStatus
          ? json['status'] as MessageStatus
          : MessageStatus.fromString(json['status']?.toString()),
      clientSideId: json['client_side_id'] as String? ?? json['clientSideId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'thread_url': threadUrl,
      'sender': sender.name,
      'text': text,
      'sent_at': sentAt.toIso8601String(),
      'status': status.name,
      'client_side_id': clientSideId,
    };
  }

  @override
  List<Object?> get props => [id, threadUrl, sender, text, sentAt, status, clientSideId];
}
