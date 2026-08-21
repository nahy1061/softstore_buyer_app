import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/messages_repository.dart';
import '../../models/conversation_model.dart';
import 'messages_list_state.dart';

class MessagesListCubit extends Cubit<MessagesListState> {
  final MessagesRepository _repository;

  MessagesListCubit({MessagesRepository? repository})
      : _repository = repository ?? MessagesRepository(),
        super(const MessagesListInitial());

  Future<void> loadConversations({bool forceRefresh = false, bool isAuthenticated = true}) async {
    if (!isAuthenticated) {
      emit(const MessagesListUnauthenticated());
      return;
    }

    if (state is! MessagesListLoaded) {
      emit(const MessagesListLoading());
    }

    try {
      final conversations = await _repository.fetchConversations(forceRefresh: forceRefresh);
      if (conversations.isEmpty) {
        emit(const MessagesListEmpty());
      } else {
        emit(MessagesListLoaded(conversations: conversations));
      }
    } catch (e) {
      if (_repository.cachedConversations.isNotEmpty) {
        emit(MessagesListLoaded(conversations: _repository.cachedConversations));
      } else {
        emit(MessagesListError(e.toString().replaceAll('Exception:', '').trim()));
      }
    }
  }

  void searchConversations(String query) {
    if (state is MessagesListLoaded) {
      final loaded = state as MessagesListLoaded;
      final trimmed = query.trim().toLowerCase();

      if (trimmed.isEmpty) {
        emit(loaded.copyWith(searchQuery: '', filteredConversations: loaded.conversations));
        return;
      }

      final filtered = loaded.conversations.where((c) {
        final sellerMatch = c.sellerName.toLowerCase().contains(trimmed);
        final productMatch = (c.productName ?? '').toLowerCase().contains(trimmed);
        final msgMatch = c.lastMessage.toLowerCase().contains(trimmed);
        return sellerMatch || productMatch || msgMatch;
      }).toList();

      emit(loaded.copyWith(
        searchQuery: query,
        filteredConversations: filtered,
      ));
    }
  }

  void markAsRead(String threadUrl) {
    if (state is MessagesListLoaded) {
      final loaded = state as MessagesListLoaded;
      final updated = loaded.conversations.map((c) {
        if (c.threadUrl == threadUrl) {
          return c.copyWith(isUnread: false, unreadCount: 0);
        }
        return c;
      }).toList();

      emit(loaded.copyWith(
        conversations: updated,
        filteredConversations: loaded.searchQuery.isEmpty
            ? updated
            : updated.where((c) {
                final trimmed = loaded.searchQuery.trim().toLowerCase();
                return c.sellerName.toLowerCase().contains(trimmed) ||
                    (c.productName ?? '').toLowerCase().contains(trimmed) ||
                    c.lastMessage.toLowerCase().contains(trimmed);
              }).toList(),
      ));
    }
  }

  Future<void> refresh({bool isAuthenticated = true}) async {
    await loadConversations(forceRefresh: true, isAuthenticated: isAuthenticated);
  }
}
