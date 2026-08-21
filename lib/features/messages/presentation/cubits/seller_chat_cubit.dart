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

  String? _currentThreadUrl;
  int? _productId;
  String? _productName;
  String? _productImage;
  String? _sellerName;
  ConversationThread? _threadInfo;

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
    _currentThreadUrl = threadUrl;
    _threadInfo = threadInfo ?? _threadInfo;
    _productId = productId ?? threadInfo?.productId ?? _productId;
    _productName = productName ?? threadInfo?.productName ?? _productName;
    _productImage = productImage ?? threadInfo?.productImage ?? _productImage;
    _sellerName = sellerName ?? threadInfo?.sellerName ?? _sellerName;

    // Show cached messages immediately if available
    final cached = _repository.getCachedMessages(threadUrl);
    if (cached.isNotEmpty) {
      emit(SellerChatLoaded(
        threadUrl: threadUrl,
        messages: cached,
        threadInfo: _threadInfo,
        productId: _productId,
        productName: _productName,
        productImage: _productImage,
        sellerName: _sellerName,
      ));
    } else {
      emit(const SellerChatLoading());
    }

    try {
      final messages = await _repository.getThreadMessages(threadUrl, forceRefresh: true);
      emit(SellerChatLoaded(
        threadUrl: threadUrl,
        messages: messages,
        threadInfo: _threadInfo,
        productId: _productId,
        productName: _productName,
        productImage: _productImage,
        sellerName: _sellerName,
      ));
    } catch (e) {
      final cachedFallback = _repository.getCachedMessages(threadUrl);
      if (cachedFallback.isNotEmpty) {
        emit(SellerChatLoaded(
          threadUrl: threadUrl,
          messages: cachedFallback,
          threadInfo: _threadInfo,
          productId: _productId,
          productName: _productName,
          productImage: _productImage,
          sellerName: _sellerName,
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
    _productId = productId;
    _productName = productName ?? _productName;
    _productImage = productImage ?? _productImage;
    _sellerName = sellerName ?? _sellerName;

    // Check if we already have a cached threadUrl for this product
    final existingThreadUrl = _repository.getCachedThreadUrlForProduct(productId);
    if (existingThreadUrl != null && existingThreadUrl.isNotEmpty) {
      _currentThreadUrl = existingThreadUrl;
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

    if (initialMessage.trim().isEmpty) {
      // Just initialize empty screen for new product inquiry without making network call yet
      _currentThreadUrl = '';
      emit(SellerChatLoaded(
        threadUrl: '',
        messages: const [],
        productId: productId,
        productName: productName,
        productImage: productImage,
        sellerName: sellerName,
      ));
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

      _currentThreadUrl = threadUrl;
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

  /// Send message to current active thread (or create thread if new)
  Future<void> sendMessage(String text) async {
    final cleanText = text.trim();
    if (cleanText.isEmpty) return;

    final String activeThreadUrl = (state is SellerChatLoaded)
        ? (state as SellerChatLoaded).threadUrl
        : (_currentThreadUrl ?? '');

    final List<ChatMessage> currentMessages = (state is SellerChatLoaded)
        ? (state as SellerChatLoaded).messages
        : const [];

    final clientSideId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      threadUrl: activeThreadUrl,
      sender: MessageSender.buyer,
      text: cleanText,
      sentAt: DateTime.now(),
      status: MessageStatus.sending,
      clientSideId: clientSideId,
    );

    // Optimistically update UI
    final updatedMessages = [...currentMessages, optimisticMsg];
    emit(SellerChatLoaded(
      threadUrl: activeThreadUrl,
      messages: updatedMessages,
      isSending: true,
      errorMessage: null,
      threadInfo: _threadInfo,
      productId: _productId,
      productName: _productName,
      productImage: _productImage,
      sellerName: _sellerName,
    ));

    try {
      if (activeThreadUrl.isEmpty && _productId != null) {
        // Start brand new thread on server
        developer.log('[SellerChatCubit] Starting new conversation for productId: $_productId', name: 'messages');
        final newThreadUrl = await _repository.startConversation(
          productId: _productId!,
          message: cleanText,
          productName: _productName,
          productImage: _productImage,
          sellerName: _sellerName,
        );

        _currentThreadUrl = newThreadUrl;

        final confirmed = optimisticMsg.copyWith(
          threadUrl: newThreadUrl,
          status: MessageStatus.sent,
        );
        final list = updatedMessages.map((m) {
          if (m.clientSideId == clientSideId || m.id == optimisticMsg.id) {
            return confirmed;
          }
          return m;
        }).toList();

        emit(SellerChatLoaded(
          threadUrl: newThreadUrl,
          messages: list,
          isSending: false,
          errorMessage: null,
          threadInfo: _threadInfo,
          productId: _productId,
          productName: _productName,
          productImage: _productImage,
          sellerName: _sellerName,
        ));
      } else {
        developer.log('[SellerChatCubit] Sending message to thread: $activeThreadUrl', name: 'messages');
        final confirmed = await _repository.sendMessage(
          threadUrl: activeThreadUrl,
          message: cleanText,
        );

        final list = updatedMessages.map((m) {
          if (m.clientSideId == clientSideId || m.id == optimisticMsg.id) {
            return confirmed;
          }
          return m;
        }).toList();

        emit(SellerChatLoaded(
          threadUrl: activeThreadUrl,
          messages: list,
          isSending: false,
          errorMessage: null,
          threadInfo: _threadInfo,
          productId: _productId,
          productName: _productName,
          productImage: _productImage,
          sellerName: _sellerName,
        ));
      }
    } catch (e) {
      developer.log('[SellerChatCubit] sendMessage failed: $e', name: 'messages');
      final list = updatedMessages.map((m) {
        if (m.clientSideId == clientSideId || m.id == optimisticMsg.id) {
          return m.copyWith(status: MessageStatus.failed);
        }
        return m;
      }).toList();

      emit(SellerChatLoaded(
        threadUrl: _currentThreadUrl ?? '',
        messages: list,
        isSending: false,
        errorMessage: 'Failed to send message. Tap refresh icon on bubble to retry.',
        threadInfo: _threadInfo,
        productId: _productId,
        productName: _productName,
        productImage: _productImage,
        sellerName: _sellerName,
      ));
    }
  }

  /// Retry sending a failed message
  Future<void> retryMessage(ChatMessage failedMessage) async {
    if (state is! SellerChatLoaded) return;
    final currentState = state as SellerChatLoaded;

    // Remove the failed message and call sendMessage
    final filtered = currentState.messages
        .where((m) => m.id != failedMessage.id && m.clientSideId != failedMessage.clientSideId)
        .toList();
    emit(currentState.copyWith(messages: filtered));

    await sendMessage(failedMessage.text);
  }

  /// Start background polling for new incoming seller messages
  void startPolling({Duration interval = const Duration(seconds: 5)}) {
    _pollingTimer?.cancel();
    _pollingTimer = Timer.periodic(interval, (_) async {
      final activeUrl = _currentThreadUrl;
      if (activeUrl != null && activeUrl.isNotEmpty) {
        try {
          final freshMessages = await _repository.getThreadMessages(activeUrl, forceRefresh: true);
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
