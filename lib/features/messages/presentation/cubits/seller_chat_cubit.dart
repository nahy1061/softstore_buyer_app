import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/messages_repository.dart';
import '../../models/chat_message_model.dart';
import '../../models/conversation_model.dart';
import 'seller_chat_state.dart';

class SellerChatCubit extends Cubit<SellerChatState> {
  final MessagesRepository _repository;
  Timer? _pollingTimer;

  SellerChatCubit({MessagesRepository? repository})
      : _repository = repository ?? MessagesRepository(),
        super(const SellerChatInitial());

  /// Load existing thread messages
  Future<void> loadThread(
    String threadUrl, {
    ConversationThread? threadInfo,
    int? productId,
    String? productName,
    String? productImage,
    String? sellerName,
  }) async {
    // Show cached messages immediately if available
    final cached = _repository.getCachedMessages(threadUrl);
    if (cached.isNotEmpty) {
      emit(SellerChatLoaded(
        threadUrl: threadUrl,
        messages: cached,
        threadInfo: threadInfo,
        productId: productId ?? threadInfo?.productId,
        productName: productName ?? threadInfo?.productName,
        productImage: productImage ?? threadInfo?.productImage,
        sellerName: sellerName ?? threadInfo?.sellerName,
      ));
    } else {
      emit(const SellerChatLoading());
    }

    try {
      final messages = await _repository.getThreadMessages(threadUrl, forceRefresh: true);
      emit(SellerChatLoaded(
        threadUrl: threadUrl,
        messages: messages,
        threadInfo: threadInfo,
        productId: productId ?? threadInfo?.productId,
        productName: productName ?? threadInfo?.productName,
        productImage: productImage ?? threadInfo?.productImage,
        sellerName: sellerName ?? threadInfo?.sellerName,
      ));
    } catch (e) {
      final cachedFallback = _repository.getCachedMessages(threadUrl);
      if (cachedFallback.isNotEmpty) {
        emit(SellerChatLoaded(
          threadUrl: threadUrl,
          messages: cachedFallback,
          threadInfo: threadInfo,
          productId: productId ?? threadInfo?.productId,
          productName: productName ?? threadInfo?.productName,
          productImage: productImage ?? threadInfo?.productImage,
          sellerName: sellerName ?? threadInfo?.sellerName,
        ));
      } else {
        emit(SellerChatError(e.toString().replaceAll('Exception:', '').trim()));
      }
    }
  }

  /// Start chat with a seller about a product
  Future<void> startChatWithProduct({
    required int productId,
    required String initialMessage,
    String? productName,
    String? productImage,
    String? sellerName,
  }) async {
    // Check if we already have a cached threadUrl for this product
    final existingThreadUrl = _repository.getCachedThreadUrlForProduct(productId);
    if (existingThreadUrl != null && existingThreadUrl.isNotEmpty) {
      await loadThread(
        existingThreadUrl,
        productId: productId,
        productName: productName,
        productImage: productImage,
        sellerName: sellerName,
      );
      if (initialMessage.trim().isNotEmpty) {
        await sendMessage(initialMessage.trim());
      }
      return;
    }

    emit(const SellerChatLoading());

    try {
      final threadUrl = await _repository.startConversation(
        productId: productId,
        message: initialMessage,
        productName: productName,
        productImage: productImage,
        sellerName: sellerName,
      );

      final messages = _repository.getCachedMessages(threadUrl);
      emit(SellerChatLoaded(
        threadUrl: threadUrl,
        messages: messages,
        productId: productId,
        productName: productName,
        productImage: productImage,
        sellerName: sellerName,
      ));
    } catch (e) {
      emit(SellerChatError(e.toString().replaceAll('Exception:', '').trim()));
    }
  }

  /// Send message to current active thread
  Future<void> sendMessage(String text) async {
    if (state is! SellerChatLoaded) return;
    final currentState = state as SellerChatLoaded;
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final clientSideId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      threadUrl: currentState.threadUrl,
      sender: MessageSender.buyer,
      text: cleanText,
      sentAt: DateTime.now(),
      status: MessageStatus.sending,
      clientSideId: clientSideId,
    );

    // Optimistically update UI
    final updatedMessages = [...currentState.messages, optimisticMsg];
    emit(currentState.copyWith(
      messages: updatedMessages,
      isSending: true,
      errorMessage: null,
    ));

    try {
      final confirmed = await _repository.sendMessage(
        threadUrl: currentState.threadUrl,
        message: cleanText,
      );

      // Update state with confirmed message
      if (state is SellerChatLoaded) {
        final current = state as SellerChatLoaded;
        final list = current.messages.map((m) {
          if (m.clientSideId == clientSideId || m.id == optimisticMsg.id) {
            return confirmed;
          }
          return m;
        }).toList();

        emit(current.copyWith(
          messages: list,
          isSending: false,
          errorMessage: null,
        ));
      }
    } catch (e) {
      developer.log('[SellerChatCubit] sendMessage failed: $e', name: 'messages');
      if (state is SellerChatLoaded) {
        final current = state as SellerChatLoaded;
        final list = current.messages.map((m) {
          if (m.clientSideId == clientSideId || m.id == optimisticMsg.id) {
            return m.copyWith(status: MessageStatus.failed);
          }
          return m;
        }).toList();

        emit(current.copyWith(
          messages: list,
          isSending: false,
          errorMessage: 'Failed to send message. Tap to retry.',
        ));
      }
    }
  }

  /// Retry sending a failed message
  Future<void> retryMessage(ChatMessage failedMessage) async {
    if (state is! SellerChatLoaded) return;
    final currentState = state as SellerChatLoaded;

    // Remove the failed message and call sendMessage
    final filtered = currentState.messages.where((m) => m.id != failedMessage.id && m.clientSideId != failedMessage.clientSideId).toList();
    emit(currentState.copyWith(messages: filtered));

    await sendMessage(failedMessage.text);
  }

  /// Start background polling for new incoming seller messages
  void startPolling({Duration interval = const Duration(seconds: 5)}) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) async {
      if (state is SellerChatLoaded) {
        final current = state as SellerChatLoaded;
        try {
          final freshMessages = await _repository.getThreadMessages(current.threadUrl, forceRefresh: true);
          if (state is SellerChatLoaded) {
            final latest = state as SellerChatLoaded;
            // Merge while preserving any local pending/sending items
            final pending = latest.messages.where((m) => m.isSending || m.isFailed).toList();
            final merged = [...freshMessages];
            for (final p in pending) {
              if (!merged.any((m) => m.text == p.text && m.isFromBuyer)) {
                merged.add(p);
              }
            }

            if (merged.length != latest.messages.length ||
                (merged.isNotEmpty && latest.messages.isNotEmpty && merged.last.id != latest.messages.last.id)) {
              emit(latest.copyWith(messages: merged));
            }
          }
        } catch (_) {
          // Polling silent failure
        }
      }
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  @override
  Future<void> close() {
    stopPolling();
    return super.close();
  }
}
