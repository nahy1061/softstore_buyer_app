import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/storage_keys.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/csrf_service.dart';
import '../../../core/utils/html_parser_util.dart';

// ─── Models ───────────────────────────────────────────────────────────────────

class ConversationPreview {
  final String threadUrl;
  final String sellerName;
  final String? productName;
  final String? productImage;
  final String? lastMessage;
  final String? timestamp;
  final bool unread;

  const ConversationPreview({
    required this.threadUrl,
    required this.sellerName,
    this.productName,
    this.productImage,
    this.lastMessage,
    this.timestamp,
    this.unread = false,
  });
}

class ChatMessage {
  final String id;
  final String sender; // 'buyer' or 'seller'
  final String text;
  final String? timestamp;

  const ChatMessage({
    required this.id,
    required this.sender,
    required this.text,
    this.timestamp,
  });
}

class ConversationDetail {
  final String threadUrl;
  final String sellerName;
  final String? productName;
  final String? productImage;
  final double? productPrice;
  final List<ChatMessage> messages;

  const ConversationDetail({
    required this.threadUrl,
    required this.sellerName,
    this.productName,
    this.productImage,
    this.productPrice,
    this.messages = const [],
  });
}

// ─── MessagingRepository ──────────────────────────────────────────────────────

/// Handles buyer↔seller messaging against the SoftStore backend.
///
/// Critical bug documented in API_MAPPING.md:
///   Using /store/messages/new for an EXISTING thread causes a login redirect.
///   Always check the conversation cache first and use the stored threadUrl.
class MessagingRepository {
  MessagingRepository._();
  static final MessagingRepository instance = MessagingRepository._();

  final DioClient _client = DioClient();
  final CsrfService _csrf = CsrfService.instance;

  // ─── Conversation Cache ────────────────────────────────────────────────────

  Future<Map<String, String>> _loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(StorageKeys.conversationCache);
    if (raw == null) return {};
    try {
      return Map<String, String>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> _saveCache(Map<String, String> cache) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.conversationCache, jsonEncode(cache));
  }

  Future<String?> _getCachedThread(int productId) async {
    final cache = await _loadCache();
    return cache['productId-$productId'];
  }

  Future<void> _cacheThread(int productId, String threadUrl) async {
    final cache = await _loadCache();
    cache['productId-$productId'] = threadUrl;
    await _saveCache(cache);
  }

  // ─── Conversations List ────────────────────────────────────────────────────

  Future<List<ConversationPreview>> getConversations() async {
    try {
      final response = await _client.get<String>(
        ApiEndpoints.messagesList,
        options: Options(responseType: ResponseType.plain),
      );
      return _parseConversationsList(response.data ?? '');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  List<ConversationPreview> _parseConversationsList(String html) {
    final doc = HtmlParserUtil.parse(html);
    final threads = doc.querySelectorAll(
        '.message-thread, .conversation-item, .chat-item');
    final result = <ConversationPreview>[];

    for (final thread in threads) {
      final linkEl = thread.querySelector('a[href*="/messages/"]');
      final threadUrl = linkEl?.attributes['href'] ?? '';
      if (threadUrl.isEmpty) continue;

      final sellerName =
          thread.querySelector('.seller-name, .store-name')?.text.trim() ?? '';
      final productName =
          thread.querySelector('.product-name, .item-name')?.text.trim();
      final imgEl = thread.querySelector('img');
      final productImage = imgEl != null
          ? HtmlParserUtil.toAbsoluteUrl(
              imgEl.attributes['src'] ?? imgEl.attributes['data-src'] ?? '')
          : null;
      final lastMessage =
          thread.querySelector('.message-preview, .last-message, p')?.text.trim();
      final timestamp =
          thread.querySelector('.timestamp, time')?.text.trim();
      final unread = thread.classes.contains('unread') ||
          thread.querySelector('.unread-badge') != null;

      result.add(ConversationPreview(
        threadUrl: threadUrl,
        sellerName: sellerName,
        productName: productName,
        productImage: productImage,
        lastMessage: lastMessage,
        timestamp: timestamp,
        unread: unread,
      ));
    }

    return result;
  }

  // ─── Get Conversation Detail ───────────────────────────────────────────────

  Future<ConversationDetail> getConversation(String threadUrl) async {
    try {
      final response = await _client.get<String>(
        threadUrl,
        options: Options(responseType: ResponseType.plain),
      );
      return _parseConversation(response.data ?? '', threadUrl);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  ConversationDetail _parseConversation(String html, String threadUrl) {
    final doc = HtmlParserUtil.parse(html);

    final sellerName =
        doc.querySelector('.seller-name, .store-name, h2, h3')?.text.trim() ?? '';
    final productName =
        doc.querySelector('.product-name, .chat-product-name')?.text.trim();
    final imgEl = doc.querySelector('.chat-product-image img, .product-image img');
    final productImage = imgEl != null
        ? HtmlParserUtil.toAbsoluteUrl(
            imgEl.attributes['src'] ?? imgEl.attributes['data-src'] ?? '')
        : null;

    // Messages
    final messageBubbles = doc.querySelectorAll(
        '.message-bubble, .chat-message, .message');
    final messages = <ChatMessage>[];

    for (int i = 0; i < messageBubbles.length; i++) {
      final bubble = messageBubbles[i];
      final isBuyer = bubble.classes.contains('buyer-message') ||
          bubble.classes.contains('outgoing') ||
          bubble.classes.contains('sent');
      final text = bubble.querySelector('.text, .content, p')?.text.trim() ??
          bubble.text.trim();
      final timestamp = bubble.querySelector('.timestamp, time')?.text.trim();

      if (text.isNotEmpty) {
        messages.add(ChatMessage(
          id: '$i',
          sender: isBuyer ? 'buyer' : 'seller',
          text: text,
          timestamp: timestamp,
        ));
      }
    }

    return ConversationDetail(
      threadUrl: threadUrl,
      sellerName: sellerName,
      productName: productName,
      productImage: productImage,
      messages: messages,
    );
  }

  // ─── Start Conversation (Contact Seller) ───────────────────────────────────

  /// Opens a new thread or reuses an existing cached thread.
  /// Returns the threadUrl for future messages.
  Future<String> startOrGetConversation({
    required int productId,
    required String initialMessage,
  }) async {
    // Check cache first (avoid the login-redirect bug for existing threads)
    final cached = await _getCachedThread(productId);
    if (cached != null) {
      await sendMessage(threadUrl: cached, message: initialMessage);
      return cached;
    }

    try {
      final csrfToken = await _csrf.fetchToken(ApiEndpoints.newMessage);

      final response = await _client.post<String>(
        ApiEndpoints.newMessage,
        data: {
          if (csrfToken != null) '_csrf_token': csrfToken,
          'product_id': productId,
          'message': initialMessage.trim(),
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          responseType: ResponseType.plain,
          followRedirects: false,
          validateStatus: (s) => s != null && s < 500,
        ),
      );

      // Server redirects to the thread URL
      final location = response.headers.value('location') ?? '';
      if (location.isNotEmpty) {
        await _cacheThread(productId, location);
        return location;
      }

      throw const ServerFailure('Failed to start conversation.');
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  // ─── Send Message ──────────────────────────────────────────────────────────

  Future<void> sendMessage({
    required String threadUrl,
    required String message,
  }) async {
    try {
      final csrfToken = await _csrf.fetchToken(threadUrl);

      await _client.post<String>(
        threadUrl,
        data: {
          if (csrfToken != null) '_csrf_token': csrfToken,
          'message': message.trim(),
        },
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          responseType: ResponseType.plain,
          followRedirects: false,
          validateStatus: (s) => s != null && s < 500,
        ),
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Failure _mapError(DioException e) {
    developer.log('[Messaging] DioException: ${e.message}', name: 'messaging');
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkFailure('No internet connection.');
    }
    return ServerFailure(e.message ?? 'Server error',
        statusCode: e.response?.statusCode);
  }
}
