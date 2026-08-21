import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/csrf_extractor.dart';
import '../../../core/utils/csrf_service.dart';
import '../models/chat_message_model.dart';
import '../models/conversation_model.dart';

class MessagesRepository {
  static final MessagesRepository _instance = MessagesRepository._internal();
  final DioClient _dio;
  final List<ConversationThread> _cachedConversations = [];
  final Map<String, List<ChatMessage>> _cachedThreadMessages = {};
  final Map<int, String> _productThreadMap = {};
  bool _isStorageInitialized = false;
  String? _currentUserId;

  factory MessagesRepository({DioClient? dioClient}) {
    return _instance;
  }

  MessagesRepository._internal() : _dio = DioClient();

  /// Set the current user ID to namespace local storage per account.
  Future<void> setUserId(String? userId) async {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      _isStorageInitialized = false;
      _cachedConversations.clear();
      _cachedThreadMessages.clear();
      _productThreadMap.clear();
      await _initStorage();
    }
  }

  /// Clear all cached data on logout.
  Future<void> clearCache() async {
    _cachedConversations.clear();
    _cachedThreadMessages.clear();
    _productThreadMap.clear();
    _isStorageInitialized = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentUserId != null) {
        await prefs.remove('messages_threads_$_currentUserId');
        await prefs.remove('messages_history_$_currentUserId');
        await prefs.remove('messages_product_map_$_currentUserId');
      }
    } catch (e) {
      developer.log('[MessagesRepository] clearCache error: $e', name: 'messages');
    }
  }

  List<ConversationThread> get cachedConversations => List.unmodifiable(_cachedConversations);

  List<ChatMessage> getCachedMessages(String threadUrl) {
    return List.unmodifiable(_cachedThreadMessages[threadUrl] ?? []);
  }

  String? getCachedThreadUrlForProduct(int productId) {
    return _productThreadMap[productId];
  }

  /// Load persisted conversations and mappings from SharedPreferences
  Future<void> _initStorage() async {
    if (_isStorageInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final userSuffix = _currentUserId != null ? '_$_currentUserId' : '';
      final threadsKey = 'messages_threads$userSuffix';
      final historyKey = 'messages_history$userSuffix';
      final mapKey = 'messages_product_map$userSuffix';

      // Load conversations
      final threadsJson = prefs.getString(threadsKey);
      if (threadsJson != null && threadsJson.isNotEmpty) {
        final list = jsonDecode(threadsJson) as List<dynamic>;
        final loaded = list
            .map((item) => ConversationThread.fromJson(item as Map<String, dynamic>))
            .toList();
        for (final t in loaded) {
          if (!_cachedConversations.any((existing) => existing.threadUrl == t.threadUrl)) {
            _cachedConversations.add(t);
          }
        }
      }

      // Load message history
      final historyJson = prefs.getString(historyKey);
      if (historyJson != null && historyJson.isNotEmpty) {
        final map = jsonDecode(historyJson) as Map<String, dynamic>;
        map.forEach((threadUrl, val) {
          if (val is List) {
            final msgs = val
                .map((m) => ChatMessage.fromJson(m as Map<String, dynamic>))
                .toList();
            _cachedThreadMessages[threadUrl] = msgs;
          }
        });
      }

      // Load product to thread mapping
      final productMapJson = prefs.getString(mapKey);
      if (productMapJson != null && productMapJson.isNotEmpty) {
        final map = jsonDecode(productMapJson) as Map<String, dynamic>;
        map.forEach((pIdStr, threadUrl) {
          final pId = int.tryParse(pIdStr);
          if (pId != null && threadUrl is String) {
            _productThreadMap[pId] = threadUrl;
          }
        });
      }

      _isStorageInitialized = true;
    } catch (e) {
      developer.log('[MessagesRepository] Storage initialization error: $e', name: 'messages');
    }
  }

  Future<void> _saveStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userSuffix = _currentUserId != null ? '_$_currentUserId' : '';

      final threadsJson = jsonEncode(_cachedConversations.map((t) => t.toJson()).toList());
      await prefs.setString('messages_threads$userSuffix', threadsJson);

      final Map<String, dynamic> historyMap = {};
      _cachedThreadMessages.forEach((threadUrl, msgs) {
        historyMap[threadUrl] = msgs.map((m) => m.toJson()).toList();
      });
      await prefs.setString('messages_history$userSuffix', jsonEncode(historyMap));

      final Map<String, dynamic> productMap = {};
      _productThreadMap.forEach((pId, threadUrl) {
        productMap[pId.toString()] = threadUrl;
      });
      await prefs.setString('messages_product_map$userSuffix', jsonEncode(productMap));
    } catch (e) {
      developer.log('[MessagesRepository] Save storage error: $e', name: 'messages');
    }
  }

  /// 1. Fetch Conversations List (GET /store/messages)
  Future<List<ConversationThread>> fetchConversations({bool forceRefresh = false}) async {
    await _initStorage();

    if (!forceRefresh && _cachedConversations.isNotEmpty) {
      return List.unmodifiable(_cachedConversations);
    }

    try {
      final response = await _dio.get<String>(
        ApiEndpoints.messagesList,
        options: Options(responseType: ResponseType.plain),
      );

      final htmlContent = response.data ?? '';
      final parsedList = parseConversationsHtml(htmlContent);

      _cachedConversations.clear();
      _cachedConversations.addAll(parsedList);

      // Update product map where productId is present
      for (final conv in parsedList) {
        if (conv.productId != null && conv.threadUrl.isNotEmpty) {
          _productThreadMap[conv.productId!] = conv.threadUrl;
        }
      }

      await _saveStorage();
      return List.unmodifiable(_cachedConversations);
    } on DioException catch (e) {
      developer.log('[MessagesRepository] fetchConversations DioException: ${e.message}', name: 'messages');
      if (_cachedConversations.isNotEmpty) {
        return List.unmodifiable(_cachedConversations);
      }
      throw ServerFailure(e.message ?? 'Failed to load conversations.');
    } catch (e) {
      developer.log('[MessagesRepository] fetchConversations general error: $e', name: 'messages');
      if (_cachedConversations.isNotEmpty) {
        return List.unmodifiable(_cachedConversations);
      }
      throw ServerFailure(e.toString());
    }
  }

  /// 2. Fetch Thread Messages & Details (GET {threadUrl})
  Future<List<ChatMessage>> getThreadMessages(String threadUrl, {bool forceRefresh = true}) async {
    await _initStorage();

    if (!forceRefresh && _cachedThreadMessages.containsKey(threadUrl)) {
      return List.unmodifiable(_cachedThreadMessages[threadUrl]!);
    }

    try {
      final response = await _dio.get<String>(
        threadUrl,
        options: Options(responseType: ResponseType.plain),
      );

      final htmlContent = response.data ?? '';
      final parsedMessages = parseThreadMessagesHtml(htmlContent, threadUrl: threadUrl);

      // Preserve any pending optimistic messages
      final existing = _cachedThreadMessages[threadUrl] ?? [];
      final pending = existing.where((m) => m.isSending || m.isFailed).toList();

      final combined = [...parsedMessages];
      for (final p in pending) {
        if (!combined.any((m) => m.text == p.text && m.isFromBuyer)) {
          combined.add(p);
        }
      }

      _cachedThreadMessages[threadUrl] = combined;
      await _saveStorage();
      return List.unmodifiable(_cachedThreadMessages[threadUrl]!);
    } on DioException catch (e) {
      developer.log('[MessagesRepository] getThreadMessages error: ${e.message}', name: 'messages');
      if (_cachedThreadMessages.containsKey(threadUrl)) {
        return List.unmodifiable(_cachedThreadMessages[threadUrl]!);
      }
      throw ServerFailure(e.message ?? 'Failed to load messages.');
    } catch (e) {
      developer.log('[MessagesRepository] getThreadMessages general error: $e', name: 'messages');
      if (_cachedThreadMessages.containsKey(threadUrl)) {
        return List.unmodifiable(_cachedThreadMessages[threadUrl]!);
      }
      throw ServerFailure(e.toString());
    }
  }

  /// 3. Start New Conversation or reuse existing thread
  Future<String> startConversation({
    required int productId,
    required String message,
    String? productName,
    String? productImage,
    String? sellerName,
  }) async {
    await _initStorage();

    final existingThreadUrl = _productThreadMap[productId];
    if (existingThreadUrl != null && existingThreadUrl.isNotEmpty) {
      // Thread exists, reply directly to thread
      await sendMessage(threadUrl: existingThreadUrl, message: message);
      return existingThreadUrl;
    }

    try {
      // 1. Get CSRF token
      final csrf = await CsrfService.instance.refreshToken(ApiEndpoints.messagesList) ?? '';

      // 2. Post to /store/messages/new
      final response = await _dio.post<dynamic>(
        ApiEndpoints.newMessage,
        data: {
          '_csrf_token': csrf,
          'product_id': productId,
          'message': message,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
          validateStatus: (status) => status != null && (status < 400 || status == 302),
        ),
      );

      String? newThreadUrl;
      if (response.statusCode == 302) {
        final location = response.headers.value('location');
        if (location != null && location.isNotEmpty) {
          newThreadUrl = location;
        }
      }

      // If location header was relative or not returned directly
      if (newThreadUrl == null || newThreadUrl.isEmpty) {
        // Fetch conversations list to discover newly created thread
        final refreshedList = await fetchConversations(forceRefresh: true);
        final match = refreshedList.firstWhere(
          (t) => t.productId == productId || (productName != null && t.productName == productName),
          orElse: () => refreshedList.isNotEmpty
              ? refreshedList.first
              : ConversationThread(
                  id: 'temp',
                  threadUrl: '/store/messages',
                  sellerName: 'Seller',
                  lastMessage: '',
                  lastMessageTime: DateTime.fromMillisecondsSinceEpoch(0),
                ),
        );
        newThreadUrl = match.threadUrl.isNotEmpty ? match.threadUrl : ApiEndpoints.messagesList;
      }

      // Normalize threadUrl path
      if (!newThreadUrl.startsWith('http') && !newThreadUrl.startsWith('/')) {
        newThreadUrl = '/$newThreadUrl';
      }

      _productThreadMap[productId] = newThreadUrl;

      // Optimistically add message to cache
      final newMsg = ChatMessage(
        id: DateTime.now().millisecondsSinceEpoch,
        threadUrl: newThreadUrl,
        sender: MessageSender.buyer,
        text: message,
        sentAt: DateTime.now(),
        status: MessageStatus.sent,
      );
      final list = _cachedThreadMessages[newThreadUrl] ?? [];
      _cachedThreadMessages[newThreadUrl] = [...list, newMsg];

      // Update conversation in list
      _updateConversationInCache(
        threadUrl: newThreadUrl,
        productId: productId,
        productName: productName,
        productImage: productImage,
        sellerName: sellerName,
        lastMessage: message,
      );

      await _saveStorage();
      return newThreadUrl;
    } on DioException catch (e) {
      developer.log('[MessagesRepository] startConversation DioException: ${e.message}', name: 'messages');
      throw ServerFailure(e.message ?? 'Failed to start conversation.');
    } catch (e) {
      developer.log('[MessagesRepository] startConversation general error: $e', name: 'messages');
      throw ServerFailure(e.toString());
    }
  }

  /// 4. Send Message to existing Thread (POST {threadUrl})
  Future<ChatMessage> sendMessage({
    required String threadUrl,
    required String message,
  }) async {
    await _initStorage();

    final clientSideId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      threadUrl: threadUrl,
      sender: MessageSender.buyer,
      text: message,
      sentAt: DateTime.now(),
      status: MessageStatus.sending,
      clientSideId: clientSideId,
    );

    // Optimistically insert
    final currentMsgs = _cachedThreadMessages[threadUrl] ?? [];
    _cachedThreadMessages[threadUrl] = [...currentMsgs, optimisticMsg];

    try {
      final csrf = await CsrfService.instance.refreshToken(threadUrl) ?? '';

      final response = await _dio.post<dynamic>(
        threadUrl,
        data: {
          '_csrf_token': csrf,
          'message': message,
        },
        options: Options(
          contentType: Headers.formUrlEncodedContentType,
          followRedirects: false,
          validateStatus: (status) => status != null && (status < 400 || status == 302),
        ),
      );

      if (response.statusCode == 302 || response.statusCode == 200) {
        final confirmedMsg = optimisticMsg.copyWith(status: MessageStatus.sent);
        _updateMessageInCache(threadUrl, confirmedMsg);
        _updateConversationLastMessage(threadUrl, message);
        await _saveStorage();
        return confirmedMsg;
      } else {
        throw ServerFailure('Server returned status ${response.statusCode}');
      }
    } catch (e) {
      developer.log('[MessagesRepository] sendMessage error: $e', name: 'messages');
      final failedMsg = optimisticMsg.copyWith(status: MessageStatus.failed);
      _updateMessageInCache(threadUrl, failedMsg);
      await _saveStorage();
      throw ServerFailure(e.toString());
    }
  }

  void _updateMessageInCache(String threadUrl, ChatMessage updated) {
    final list = _cachedThreadMessages[threadUrl] ?? [];
    final idx = list.indexWhere((m) =>
        (m.clientSideId != null && m.clientSideId == updated.clientSideId) || m.id == updated.id);
    if (idx != -1) {
      list[idx] = updated;
      _cachedThreadMessages[threadUrl] = List.from(list);
    }
  }

  void _updateConversationLastMessage(String threadUrl, String message) {
    final idx = _cachedConversations.indexWhere((c) => c.threadUrl == threadUrl);
    if (idx != -1) {
      _cachedConversations[idx] = _cachedConversations[idx].copyWith(
        lastMessage: message,
        lastMessageTime: DateTime.now(),
      );
    }
  }

  void _updateConversationInCache({
    required String threadUrl,
    int? productId,
    String? productName,
    String? productImage,
    String? sellerName,
    required String lastMessage,
  }) {
    final idx = _cachedConversations.indexWhere((c) => c.threadUrl == threadUrl);
    if (idx != -1) {
      _cachedConversations[idx] = _cachedConversations[idx].copyWith(
        lastMessage: lastMessage,
        lastMessageTime: DateTime.now(),
      );
    } else {
      _cachedConversations.insert(
        0,
        ConversationThread(
          id: threadUrl.replaceAll(RegExp(r'[^0-9]'), '').isNotEmpty
              ? threadUrl.replaceAll(RegExp(r'[^0-9]'), '')
              : 'conv_${DateTime.now().millisecondsSinceEpoch}',
          threadUrl: threadUrl,
          sellerName: sellerName ?? 'Store Seller',
          productId: productId,
          productName: productName,
          productImage: productImage,
          lastMessage: lastMessage,
          lastMessageTime: DateTime.now(),
          unreadCount: 0,
          isUnread: false,
        ),
      );
    }
  }

  // ─── HTML Parsing Helpers ──────────────────────────────────────────────────

  /// Parses the `/store/messages` conversations list HTML
  static List<ConversationThread> parseConversationsHtml(String html) {
    if (html.isEmpty) return [];

    final document = html_parser.parse(html);
    final List<ConversationThread> results = [];

    // Find conversation container elements
    final threadElements = document.querySelectorAll(
      '.message-thread, .conversation-item, .chat-thread, .msg-card, a[href*="/store/messages/"]',
    );

    if (threadElements.isEmpty) {
      // Fallback: look for table rows or generic cards containing message links
      final genericLinks = document.querySelectorAll('a[href*="/store/messages/"]');
      for (final link in genericLinks) {
        final threadUrl = link.attributes['href'] ?? '';
        if (threadUrl.isEmpty || threadUrl == ApiEndpoints.messagesList) continue;

        final sellerEl = link.querySelector('.seller-name, .store-name, h4, h5, strong');
        final sellerName = sellerEl?.text.trim() ?? 'Store Seller';

        final msgEl = link.querySelector('.message-preview, .last-message, p, span.text-muted');
        final lastMessage = msgEl?.text.trim() ?? '';

        final imgEl = link.querySelector('img');
        String? imgUrl = imgEl?.attributes['src'] ?? imgEl?.attributes['data-src'];
        imgUrl = _normalizeImageUrl(imgUrl);

        final unreadEl = link.querySelector('.unread, .badge-danger, .badge-primary');
        final isUnread = unreadEl != null || link.classes.contains('unread');

        final id = threadUrl.replaceAll(RegExp(r'[^0-9]'), '');

        results.add(
          ConversationThread(
            id: id.isNotEmpty ? id : threadUrl,
            threadUrl: threadUrl,
            sellerName: sellerName,
            productImage: imgUrl,
            lastMessage: lastMessage,
            lastMessageTime: DateTime.now(),
            isUnread: isUnread,
            unreadCount: isUnread ? 1 : 0,
          ),
        );
      }
      return results;
    }

    for (final el in threadElements) {
      String threadUrl = el.attributes['href'] ?? '';
      if (threadUrl.isEmpty) {
        final anchor = el.querySelector('a[href*="/store/messages/"]');
        threadUrl = anchor?.attributes['href'] ?? '';
      }

      if (threadUrl.isEmpty || threadUrl == ApiEndpoints.messagesList) continue;

      final sellerEl = el.querySelector('.seller-name, .store-name, .vendor-name, h4, h5');
      final sellerName = sellerEl?.text.trim() ?? 'Store Seller';

      final productEl = el.querySelector('.product-name, .product-title, .item-title');
      final productName = productEl?.text.trim();

      final imgEl = el.querySelector('img');
      String? imgUrl = imgEl?.attributes['src'] ?? imgEl?.attributes['data-src'];
      imgUrl = _normalizeImageUrl(imgUrl);

      final msgEl = el.querySelector('.last-message, .preview-text, .msg-preview, p');
      final lastMessage = msgEl?.text.trim() ?? '';

      final timeEl = el.querySelector('.timestamp, .time, .date, small, span.text-muted');
      final timeStr = timeEl?.text.trim();
      final parsedDate = _parseRelativeTime(timeStr);

      final unreadBadge = el.querySelector('.unread-badge, .unread, .badge');
      final isUnread = el.classes.contains('unread') || unreadBadge != null;
      final unreadCount = isUnread ? (int.tryParse(unreadBadge?.text.trim() ?? '1') ?? 1) : 0;

      final id = threadUrl.replaceAll(RegExp(r'[^0-9]'), '');

      results.add(
        ConversationThread(
          id: id.isNotEmpty ? id : threadUrl,
          threadUrl: threadUrl,
          sellerName: sellerName,
          productName: productName,
          productImage: imgUrl,
          lastMessage: lastMessage,
          lastMessageTime: parsedDate,
          unreadCount: unreadCount,
          isUnread: isUnread,
        ),
      );
    }

    return results;
  }

  /// Parses individual conversation messages HTML
  static List<ChatMessage> parseThreadMessagesHtml(String html, {required String threadUrl}) {
    if (html.isEmpty) return [];

    final document = html_parser.parse(html);
    final List<ChatMessage> messages = [];

    final bubbleElements = document.querySelectorAll(
      '.message-bubble, .chat-bubble, .chat-message, .msg-item, .direct-chat-msg, .chat-row',
    );

    int fallbackId = 1;
    for (final el in bubbleElements) {
      final isBuyer = el.classes.contains('buyer-message') ||
          el.classes.contains('right') ||
          el.classes.contains('sent') ||
          el.classes.contains('me') ||
          el.querySelector('.buyer, .me') != null;

      final isSeller = el.classes.contains('seller-message') ||
          el.classes.contains('left') ||
          el.classes.contains('received') ||
          el.classes.contains('store') ||
          el.querySelector('.seller, .store') != null;

      final sender = isBuyer
          ? MessageSender.buyer
          : (isSeller ? MessageSender.seller : MessageSender.seller);

      final textEl = el.querySelector('.text, .message-content, .msg-text, .bubble-text, p');
      final text = textEl != null ? textEl.text.trim() : el.text.trim();

      if (text.isEmpty) continue;

      final timeEl = el.querySelector('.time, .timestamp, .date, small, .msg-time');
      final timeStr = timeEl?.text.trim();
      final sentAt = _parseRelativeTime(timeStr);

      final idAttr = el.attributes['data-id'] ?? el.attributes['id'];
      final id = int.tryParse(idAttr?.replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? fallbackId++;

      messages.add(
        ChatMessage(
          id: id,
          threadUrl: threadUrl,
          sender: sender,
          text: text,
          sentAt: sentAt,
          status: MessageStatus.sent,
        ),
      );
    }

    return messages;
  }

  /// Normalizes relative URLs (e.g. `/media/...` -> `https://softstore.pk/media/...`)
  static String? _normalizeImageUrl(String? url) {
    if (url == null || url.isEmpty) return null;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('//')) return 'https:$url';
    if (url.startsWith('/')) return 'https://softstore.pk$url';
    return 'https://softstore.pk/$url';
  }

  static DateTime _parseRelativeTime(String? text) {
    if (text == null || text.isEmpty) return DateTime.now();

    final lower = text.toLowerCase().trim();
    if (lower.contains('just now') || lower.contains('moments ago')) {
      return DateTime.now();
    }

    final minMatch = RegExp(r'(\d+)\s*(?:min|minute)').firstMatch(lower);
    if (minMatch != null) {
      final mins = int.tryParse(minMatch.group(1)!) ?? 0;
      return DateTime.now().subtract(Duration(minutes: mins));
    }

    final hourMatch = RegExp(r'(\d+)\s*(?:hour|hr)').firstMatch(lower);
    if (hourMatch != null) {
      final hrs = int.tryParse(hourMatch.group(1)!) ?? 0;
      return DateTime.now().subtract(Duration(hours: hrs));
    }

    final dayMatch = RegExp(r'(\d+)\s*(?:day|d)').firstMatch(lower);
    if (dayMatch != null) {
      final days = int.tryParse(dayMatch.group(1)!) ?? 0;
      return DateTime.now().subtract(Duration(days: days));
    }

    return DateTime.tryParse(text) ?? DateTime.now();
  }
}
