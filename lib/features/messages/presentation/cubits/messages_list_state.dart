import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

import '../../models/conversation_model.dart';

@immutable
abstract class MessagesListState extends Equatable {
  const MessagesListState();

  @override
  List<Object?> get props => [];
}

class MessagesListInitial extends MessagesListState {
  const MessagesListInitial();
}

class MessagesListLoading extends MessagesListState {
  const MessagesListLoading();
}

class MessagesListLoaded extends MessagesListState {
  final List<ConversationThread> conversations;
  final String searchQuery;
  final List<ConversationThread> filteredConversations;

  const MessagesListLoaded({
    required this.conversations,
    this.searchQuery = '',
    List<ConversationThread>? filteredConversations,
  }) : filteredConversations = filteredConversations ?? conversations;

  int get totalUnreadCount => conversations.fold(0, (sum, c) => sum + c.unreadCount);

  MessagesListLoaded copyWith({
    List<ConversationThread>? conversations,
    String? searchQuery,
    List<ConversationThread>? filteredConversations,
  }) {
    return MessagesListLoaded(
      conversations: conversations ?? this.conversations,
      searchQuery: searchQuery ?? this.searchQuery,
      filteredConversations: filteredConversations ?? this.filteredConversations,
    );
  }

  @override
  List<Object?> get props => [conversations, searchQuery, filteredConversations];
}

class MessagesListEmpty extends MessagesListState {
  const MessagesListEmpty();
}

class MessagesListError extends MessagesListState {
  final String message;

  const MessagesListError(this.message);

  @override
  List<Object?> get props => [message];
}

class MessagesListUnauthenticated extends MessagesListState {
  const MessagesListUnauthenticated();
}
