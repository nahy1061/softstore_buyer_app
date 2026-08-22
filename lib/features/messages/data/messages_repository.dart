import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
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
    final normalized = _normalizeThreadUrl(threadUrl);
    return List.unmodifiable(_cachedThreadMessages[normalized] ?? []);
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

  /// 1. Fetch Conversations List (GET /messages or GET /store/messages)
  Future<List<ConversationThread>> fetchConversations({bool forceRefresh = false}) async {
    await _initStorage();

    if (!forceRefresh && _cachedConversations.isNotEmpty) {
      return List.unmodifiable(_cachedConversations);
    }

    try {
      List<ConversationThread> parsedList = [];
      final endpointsToTry = ['/inbox', ApiEndpoints.messagesList, ApiEndpoints.storeMessages];

      for (final ep in endpointsToTry) {
        try {
          final res = await _dio.get<String>(
            ep,
            options: Options(responseType: ResponseType.plain),
          );
          final html = res.data ?? '';
          final list = parseConversationsHtml(html);
          if (list.isNotEmpty) {
            parsedList = list;
            break;
          }
        } catch (err) {
          developer.log('[MessagesRepository] fetchConversations error on $ep: $err', name: 'messages');
        }
      }

      if (parsedList.isNotEmpty) {
        _cachedConversations.clear();
        _cachedConversations.addAll(parsedList);

        // Update product map where productId is present
        for (final conv in parsedList) {
          if (conv.productId != null && conv.threadUrl.isNotEmpty) {
            _productThreadMap[conv.productId!] = conv.threadUrl;
          }
        }

        await _saveStorage();
      }

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

    final normalizedUrl = _normalizeThreadUrl(threadUrl);

    if (!forceRefresh && _cachedThreadMessages.containsKey(normalizedUrl)) {
      return List.unmodifiable(_cachedThreadMessages[normalizedUrl]!);
    }

    try {
      final response = await _dio.get<String>(
        normalizedUrl,
        options: Options(responseType: ResponseType.plain),
      );

      final htmlContent = response.data ?? '';
      final parsedMessages = parseThreadMessagesHtml(htmlContent, threadUrl: normalizedUrl);

      // Preserve any pending optimistic messages
      final existing = _cachedThreadMessages[normalizedUrl] ?? [];
      final pending = existing.where((m) => m.isSending || m.isFailed).toList();

      final combined = [...parsedMessages];
      for (final p in pending) {
        if (!combined.any((m) => m.text == p.text && m.isFromBuyer)) {
          combined.add(p);
        }
      }

      _cachedThreadMessages[normalizedUrl] = combined;
      await _saveStorage();
      return List.unmodifiable(_cachedThreadMessages[normalizedUrl]!);
    } on DioException catch (e) {
      developer.log('[MessagesRepository] getThreadMessages error: ${e.message}', name: 'messages');
      if (_cachedThreadMessages.containsKey(normalizedUrl)) {
        return List.unmodifiable(_cachedThreadMessages[normalizedUrl]!);
      }
      throw ServerFailure(e.message ?? 'Failed to load messages.');
    } catch (e) {
      developer.log('[MessagesRepository] getThreadMessages general error: $e', name: 'messages');
      if (_cachedThreadMessages.containsKey(normalizedUrl)) {
        return List.unmodifiable(_cachedThreadMessages[normalizedUrl]!);
      }
      throw ServerFailure(e.toString());
    }
  }

  /// 3. Start New Conversation: POST /messages/start
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
      // Thread already exists, reply directly to thread
      await sendMessage(threadUrl: existingThreadUrl, message: message);
      return existingThreadUrl;
    }

    try {
      // 1. Get CSRF token from the new inquiry form page
      final formPageUrl = '/messages/new?product_id=$productId';
      final csrf = await CsrfService.instance.refreshToken(formPageUrl) ??
          await CsrfService.instance.refreshToken(ApiEndpoints.messagesList) ??
          '';

      // 2. Post to /messages/start
      final subject = productName != null && productName.isNotEmpty
          ? 'Inquiry: $productName'
          : 'Product Inquiry';

      developer.log(
        '[MessagesRepository] Posting new inquiry to ${ApiEndpoints.startMessage} for productId $productId',
        name: 'messages',
      );

      final response = await _dio.post<dynamic>(
        ApiEndpoints.startMessage,
        data: {
          '_csrf_token': csrf,
          'csrf_token': csrf,
          'product_id': productId.toString(),
          'subject': subject,
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

      // Check for login redirect (session expired)
      if (newThreadUrl != null && newThreadUrl.contains('/login')) {
        throw const AuthFailure('Please log in to contact this seller.');
      }

      // Strip query parameters (e.g. /messages/14?opened=1 -> /messages/14)
      if (newThreadUrl != null && newThreadUrl.contains('?')) {
        newThreadUrl = newThreadUrl.split('?').first;
      }

      // If location header was relative or not returned directly
      if (newThreadUrl == null || newThreadUrl.isEmpty) {
        final refreshedList = await fetchConversations(forceRefresh: true);
        final match = refreshedList.firstWhere(
          (t) => t.productId == productId || (productName != null && t.productName == productName),
          orElse: () => refreshedList.isNotEmpty
              ? refreshedList.first
              : ConversationThread(
                  id: 'temp',
                  threadUrl: '/messages',
                  sellerName: sellerName ?? 'Seller',
                  lastMessage: message,
                  lastMessageTime: DateTime.now(),
                ),
        );
        newThreadUrl = match.threadUrl.isNotEmpty ? match.threadUrl : '/messages';
      }

      newThreadUrl = _normalizeThreadUrl(newThreadUrl);
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

  /// 4. Send Message (Reply) to existing Thread (POST /messages/{id}/reply with JSON + X-CSRF-TOKEN)
  Future<ChatMessage> sendMessage({
    required String threadUrl,
    required String message,
  }) async {
    await _initStorage();

    final normalizedUrl = _normalizeThreadUrl(threadUrl);

    final clientSideId = 'msg_${DateTime.now().millisecondsSinceEpoch}';
    final optimisticMsg = ChatMessage(
      id: DateTime.now().millisecondsSinceEpoch,
      threadUrl: normalizedUrl,
      sender: MessageSender.buyer,
      text: message,
      sentAt: DateTime.now(),
      status: MessageStatus.sending,
      clientSideId: clientSideId,
    );

    // Optimistically insert
    final currentMsgs = _cachedThreadMessages[normalizedUrl] ?? [];
    _cachedThreadMessages[normalizedUrl] = [...currentMsgs, optimisticMsg];

    try {
      final csrf = await CsrfService.instance.refreshToken(normalizedUrl) ??
          await CsrfService.instance.getToken(ApiEndpoints.messagesList) ??
          '';

      // SoftStore uses /messages/{id}/reply JSON endpoint
      final replyEndpoint = normalizedUrl.endsWith('/reply')
          ? normalizedUrl
          : '${normalizedUrl.split('?').first}/reply';

      developer.log('[MessagesRepository] Sending reply to $replyEndpoint with CSRF $csrf', name: 'messages');

      int? newMsgId;
      try {
        final response = await _dio.post<dynamic>(
          replyEndpoint,
          data: jsonEncode({'message': message}),
          options: Options(
            contentType: Headers.jsonContentType,
            headers: {
              'X-CSRF-TOKEN': csrf,
              'x-csrf-token': csrf,
              'Accept': 'application/json, text/plain, */*',
            },
            followRedirects: false,
            validateStatus: (status) => status != null && status < 500,
          ),
        );

        if (response.data is Map) {
          final map = response.data as Map<String, dynamic>;
          newMsgId = map['message_id'] as int?;
        }
      } catch (jsonErr) {
        developer.log('[MessagesRepository] JSON reply error, trying form POST fallback: $jsonErr', name: 'messages');
        // Fallback: standard Form POST to threadUrl
        await _dio.post<dynamic>(
          normalizedUrl,
          data: {
            '_csrf_token': csrf,
            'csrf_token': csrf,
            'message': message,
          },
          options: Options(
            contentType: Headers.formUrlEncodedContentType,
            followRedirects: false,
            validateStatus: (status) => status != null && (status < 400 || status == 302),
          ),
        );
      }

      final confirmedMsg = optimisticMsg.copyWith(
        id: newMsgId ?? optimisticMsg.id,
        status: MessageStatus.sent,
      );
      _updateMessageInCache(normalizedUrl, confirmedMsg);
      _updateConversationLastMessage(normalizedUrl, message);
      await _saveStorage();
      return confirmedMsg;
    } catch (e) {
      developer.log('[MessagesRepository] sendMessage error: $e', name: 'messages');
      final failedMsg = optimisticMsg.copyWith(status: MessageStatus.failed);
      _updateMessageInCache(normalizedUrl, failedMsg);
      await _saveStorage();
      throw ServerFailure(e.toString());
    }
  }

  void _updateMessageInCache(String threadUrl, ChatMessage updated) {
    final normalized = _normalizeThreadUrl(threadUrl);
    final list = _cachedThreadMessages[normalized] ?? [];
    final idx = list.indexWhere((m) =>
        (m.clientSideId != null && m.clientSideId == updated.clientSideId) || m.id == updated.id);
    if (idx != -1) {
      list[idx] = updated;
      _cachedThreadMessages[normalized] = List.from(list);
    }
  }

  void _updateConversationLastMessage(String threadUrl, String message) {
    final normalized = _normalizeThreadUrl(threadUrl);
    final idx = _cachedConversations.indexWhere((c) => _normalizeThreadUrl(c.threadUrl) == normalized);
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
    final normalized = _normalizeThreadUrl(threadUrl);
    final idx = _cachedConversations.indexWhere((c) => _normalizeThreadUrl(c.threadUrl) == normalized);
    if (idx != -1) {
      _cachedConversations[idx] = _cachedConversations[idx].copyWith(
        lastMessage: lastMessage,
        lastMessageTime: DateTime.now(),
      );
    } else {
      _cachedConversations.insert(
        0,
        ConversationThread(
          id: normalized.replaceAll(RegExp(r'[^0-9]'), '').isNotEmpty
              ? normalized.replaceAll(RegExp(r'[^0-9]'), '')
              : 'conv_${DateTime.now().millisecondsSinceEpoch}',
          threadUrl: normalized,
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

  /// Parses the `/messages` or `/inbox` conversations list HTML
  static List<ConversationThread> parseConversationsHtml(String html) {
    if (html.isEmpty) return [];

    // If redirected to login page, abort
    if (html.contains('action="/login"') || html.contains('name="password"')) {
      developer.log('[MessagesRepository] HTML is login page, user unauthenticated', name: 'messages');
      return [];
    }

    final document = html_parser.parse(html);
    final List<ConversationThread> results = [];

    // 1. Check for Buyer Dashboard Conversation Cards: <a href="/messages/{id}">
    final buyerCards = document.querySelectorAll('a[href*="/messages/"], a[href*="/inbox/"]');
    for (final card in buyerCards) {
      // Ignore action buttons inside table cells
      if (card.parent?.localName == 'td' || card.classes.contains('sx-btn')) continue;

      final href = card.attributes['href'] ?? '';
      final idMatch = RegExp(r'/(?:messages|inbox|store/messages)/(\d+)').firstMatch(href);
      if (idMatch == null) continue;

      final threadId = idMatch.group(1)!;
      final threadUrl = '/messages/$threadId';

      // Avoid duplicates
      if (results.any((t) => t.id == threadId)) continue;

      // Extract subject/topic from <strong> or heading
      final strongEl = card.querySelector('strong, .sx-head, h4, h5');
      final rawSubject = strongEl?.text.trim() ?? '';

      // Extract Store & Product line (e.g. "UZquettastore · Le Falconé Garcia...")
      String storeName = '';
      String productName = '';

      final allDivs = card.querySelectorAll('.sx-t-xs, div, p, span');
      for (final el in allDivs) {
        final text = el.text.trim();
        if (text.contains('·')) {
          final parts = text.split('·');
          if (parts.isNotEmpty) {
            storeName = parts[0].trim();
          }
          if (parts.length > 1) {
            productName = parts.sublist(1).join('·').trim();
          }
          break;
        }
      }

      if (storeName.isEmpty) {
        final sellerEl = card.querySelector('.seller-name, .store-name, .vendor-name');
        storeName = sellerEl?.text.trim() ?? '';
      }

      // Extract Status
      final badgeEl = card.querySelector('.sx-badge, .badge');
      final statusText = badgeEl?.text.trim() ?? 'Open';
      final isClosed = statusText.toLowerCase().contains('closed');
      final isUnread = !isClosed && (statusText.toLowerCase().contains('open') || card.classes.contains('unread'));

      // Extract Timestamp
      String timeText = '';
      for (final el in card.querySelectorAll('.sx-t-xs, small, span')) {
        final text = el.text.trim();
        if (RegExp(r'\d{1,2}\s+[A-Za-z]{3}\s+\d{4}|\d+:\d+\s*(?:AM|PM)|ago', caseSensitive: false).hasMatch(text)) {
          timeText = text;
          break;
        }
      }
      final parsedDate = _parseRelativeTime(timeText);

      // Clean subject display
      var cleanSubject = rawSubject;
      if (cleanSubject.toLowerCase().startsWith('inquiry:')) {
        cleanSubject = cleanSubject.substring(8).trim();
      }

      final effectiveSellerName = storeName.isNotEmpty
          ? storeName
          : (productName.isNotEmpty ? productName : 'SoftStore Seller');
      final effectiveProductName = productName.isNotEmpty
          ? productName
          : (cleanSubject.isNotEmpty ? cleanSubject : null);
      final effectiveLastMessage = rawSubject.isNotEmpty
          ? rawSubject
          : (effectiveProductName ?? 'Tap to view conversation');

      results.add(
        ConversationThread(
          id: threadId,
          threadUrl: threadUrl,
          sellerName: effectiveSellerName,
          productName: effectiveProductName,
          lastMessage: effectiveLastMessage,
          lastMessageTime: parsedDate,
          isUnread: isUnread,
          unreadCount: isUnread ? 1 : 0,
        ),
      );
    }

    if (results.isNotEmpty) {
      return results;
    }

    // 2. Fallback: Table view (.sx-table)
    final tableRows = document.querySelectorAll('.sx-table tbody tr, table.sx-table tr, table tbody tr');
    if (tableRows.isNotEmpty) {
      for (final tr in tableRows) {
        final tds = tr.querySelectorAll('td');
        if (tds.length >= 4) {
          final fromText = tds.isNotEmpty ? tds[0].text.trim() : '';
          final subjectText = tds.length > 1 ? tds[1].text.trim() : '';
          final productText = tds.length > 2 ? tds[2].text.trim() : '';
          final statusText = tds.length > 3 ? tds[3].text.trim() : '';
          final timeText = tds.length > 4 ? tds[4].text.trim() : '';
          final actionAnchor = tr.querySelector('a[href*="/inbox/"], a[href*="/messages/"], a.sx-btn, td a');
          final href = actionAnchor?.attributes['href'] ?? '';

          final idMatch = RegExp(r'/(?:messages|inbox|store/messages)/(\d+)').firstMatch(href);
          if (idMatch != null) {
            final threadId = idMatch.group(1)!;
            final threadUrl = '/messages/$threadId';
            final isClosed = statusText.toLowerCase().contains('closed');
            final isUnread = !isClosed && (statusText.toLowerCase().contains('open') || tr.classes.contains('unread'));
            final parsedDate = _parseRelativeTime(timeText);

            final displayName = productText.isNotEmpty
                ? productText
                : (fromText.isNotEmpty && fromText.toLowerCase() != 'naheed' ? fromText : (subjectText.isNotEmpty ? subjectText : 'SoftStore Seller'));

            results.add(
              ConversationThread(
                id: threadId,
                threadUrl: threadUrl,
                sellerName: displayName,
                productName: productText.isNotEmpty ? productText : (subjectText.isNotEmpty ? subjectText : null),
                lastMessage: subjectText.isNotEmpty ? subjectText : (productText.isNotEmpty ? productText : 'Tap to open conversation'),
                lastMessageTime: parsedDate,
                isUnread: isUnread,
                unreadCount: isUnread ? 1 : 0,
              ),
            );
          }
        }
      }

      if (results.isNotEmpty) {
        return results;
      }
    }

    // 3. Fallback: Generic container elements (.message-thread, .conversation-item, .bsm-thread-item)
    final threadContainers = document.querySelectorAll(
      '.bsm-thread-item, .message-thread, .conversation-item, .chat-thread, .msg-card',
    );

    for (final el in threadContainers) {
      String threadUrl = el.attributes['href'] ?? '';
      if (threadUrl.isEmpty) {
        final anchor = el.querySelector('a[href*="/messages/"], a[href*="/store/messages/"], a[href*="/inbox/"]');
        threadUrl = anchor?.attributes['href'] ?? '';
      }

      final idMatch = RegExp(r'/(?:messages|inbox|store/messages)/(\d+)').firstMatch(threadUrl);
      if (idMatch == null) continue;

      final threadId = idMatch.group(1)!;
      final normalizedUrl = '/messages/$threadId';

      final sellerEl = el.querySelector('.seller-name, .store-name, .vendor-name, h4, h5, strong');
      final rawSellerName = sellerEl?.text.trim();

      final productEl = el.querySelector('.product-name, .product-title, .item-title');
      final productName = productEl?.text.trim();

      final imgEl = el.querySelector('img');
      String? imgUrl = imgEl?.attributes['src'] ?? imgEl?.attributes['data-src'];
      imgUrl = _normalizeImageUrl(imgUrl);

      final msgEl = el.querySelector('.last-message, .preview-text, .msg-preview, .message-preview, p, span.text-muted');
      final lastMessage = msgEl?.text.trim() ?? '';

      final timeEl = el.querySelector('.timestamp, .time, .date, small, span.text-muted');
      final timeStr = timeEl?.text.trim();
      final parsedDate = _parseRelativeTime(timeStr);

      final unreadBadge = el.querySelector('.unread-badge, .unread, .badge, .badge-danger');
      final isUnread = el.classes.contains('unread') || unreadBadge != null;
      final unreadCount = isUnread ? (int.tryParse(unreadBadge?.text.trim() ?? '1') ?? 1) : 0;

      final sellerName = (rawSellerName != null && rawSellerName.isNotEmpty)
          ? rawSellerName
          : (productName != null && productName.isNotEmpty ? productName : 'Conversation #$threadId');

      results.add(
        ConversationThread(
          id: threadId,
          threadUrl: normalizedUrl,
          sellerName: sellerName,
          productName: productName,
          productImage: imgUrl,
          lastMessage: lastMessage.isNotEmpty ? lastMessage : 'Tap to view conversation',
          lastMessageTime: parsedDate,
          unreadCount: unreadCount,
          isUnread: isUnread,
        ),
      );
    }

    return results;
  }

  /// Parses individual conversation messages HTML (supports .bsm-msg and standard bubbles)
  static List<ChatMessage> parseThreadMessagesHtml(String html, {required String threadUrl}) {
    if (html.isEmpty) return [];

    final document = html_parser.parse(html);
    final List<ChatMessage> messages = [];

    final bubbleElements = document.querySelectorAll(
      '.bsm-msg, .message-bubble, .chat-bubble, .chat-message, .msg-item, .direct-chat-msg, .chat-row',
    );

    int fallbackId = 1;
    for (final el in bubbleElements) {
      final isBuyer = el.classes.contains('mine') ||
          el.classes.contains('buyer-message') ||
          el.classes.contains('right') ||
          el.classes.contains('sent') ||
          el.classes.contains('me') ||
          el.querySelector('.buyer, .me') != null;

      final isSeller = el.classes.contains('seller-message') ||
          el.classes.contains('left') ||
          el.classes.contains('received') ||
          el.classes.contains('store') ||
          (!isBuyer && el.classes.contains('bsm-msg'));

      final sender = isBuyer
          ? MessageSender.buyer
          : (isSeller ? MessageSender.seller : MessageSender.seller);

      final textEl = el.querySelector('.bsm-msg-bubble, .text, .message-content, .msg-text, .bubble-text, p');
      final text = textEl != null ? textEl.text.trim() : el.text.trim();

      if (text.isEmpty) continue;

      final timeEl = el.querySelector('.bsm-msg-meta, .time, .timestamp, .date, small, .msg-time');
      final timeStr = timeEl?.text.trim();
      final sentAt = _parseRelativeTime(timeStr);

      final idAttr = el.attributes['data-id'] ?? el.attributes['id'];
      final id = int.tryParse(idAttr?.replaceAll(RegExp(r'[^0-9]'), '') ?? '') ?? fallbackId++;

      messages.add(
        ChatMessage(
          id: id,
          threadUrl: _normalizeThreadUrl(threadUrl),
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

  static String _normalizeThreadUrl(String url) {
    var clean = url.trim();
    if (clean.isEmpty) return ApiEndpoints.messagesList;
    if (clean.startsWith('http://') || clean.startsWith('https://')) {
      final uri = Uri.tryParse(clean);
      if (uri != null) {
        clean = uri.path;
      }
    }
    if (clean.startsWith('//')) clean = clean.substring(1);
    if (!clean.startsWith('/')) clean = '/$clean';

    // SoftStore conversation thread view is /messages/{id}
    clean = clean.replaceAll(RegExp(r'^/inbox/'), '/messages/');
    clean = clean.replaceAll(RegExp(r'^/store/messages/'), '/messages/');
    return clean;
  }

  static const Map<String, int> _monthMap = {
    'jan': 1, 'january': 1,
    'feb': 2, 'february': 2,
    'mar': 3, 'march': 3,
    'apr': 4, 'april': 4,
    'may': 5,
    'jun': 6, 'june': 6,
    'jul': 7, 'july': 7,
    'aug': 8, 'august': 8,
    'sep': 9, 'september': 9,
    'oct': 10, 'october': 10,
    'nov': 11, 'november': 11,
    'dec': 12, 'december': 12,
  };

  /// Parses diverse timestamp formats from HTML meta tags, including:
  /// - "Naheed · 21 Aug 2026, 02:52 PM"
  /// - "21 Aug 2026, 05:03 PM"
  /// - "21 Aug, 04:54 PM"
  /// - "21 Aug 2026 14:30"
  /// - "02:52 PM" / "14:52"
  /// - "5 mins ago", "2 hours ago", "yesterday at 3:00 PM"
  /// - ISO 8601 strings
  static DateTime parseTimestamp(String? text) {
    if (text == null || text.trim().isEmpty) return DateTime.now();

    var raw = text.trim();
    // Strip sender prefix if present (e.g. "Naheed · 21 Aug 2026, 02:52 PM")
    if (raw.contains('·')) {
      final parts = raw.split('·');
      raw = parts.last.trim();
    } else if (raw.contains(' - ') && !RegExp(r'^\d{4}-\d{2}-\d{2}').hasMatch(raw)) {
      final parts = raw.split(' - ');
      raw = parts.last.trim();
    }

    final lower = raw.toLowerCase().trim();

    // 1. Relative time keywords
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

    final dayMatch = RegExp(r'(\d+)\s*(?:day|d)\b').firstMatch(lower);
    if (dayMatch != null) {
      final days = int.tryParse(dayMatch.group(1)!) ?? 0;
      return DateTime.now().subtract(Duration(days: days));
    }

    if (lower.contains('yesterday')) {
      final base = DateTime.now().subtract(const Duration(days: 1));
      final timeMatch = RegExp(r'(\d{1,2}):(\d{2})(?:\s*(am|pm))?').firstMatch(lower);
      if (timeMatch != null) {
        int hour = int.tryParse(timeMatch.group(1)!) ?? 12;
        final min = int.tryParse(timeMatch.group(2)!) ?? 0;
        final ampm = timeMatch.group(3);
        if (ampm == 'pm' && hour < 12) hour += 12;
        if (ampm == 'am' && hour == 12) hour = 0;
        return DateTime(base.year, base.month, base.day, hour, min);
      }
      return base;
    }

    // 2. Standard ISO DateTime (e.g. 2026-08-21 17:03:00 or 2026-08-21T17:03:00)
    final isoParsed = DateTime.tryParse(raw);
    if (isoParsed != null) return isoParsed;

    // 3. Match Date + Time with textual month:
    // e.g. "21 Aug 2026, 02:52 PM", "21 August 2026 14:30", "21 Aug, 04:54 PM"
    final dateTextMonthRegex = RegExp(
      r'(\d{1,2})\s+([A-Za-z]+)(?:\s+(\d{4}))?,?\s*(?:at\s+)?(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM|am|pm)?',
      caseSensitive: false,
    );
    final textMonthMatch = dateTextMonthRegex.firstMatch(raw);
    if (textMonthMatch != null) {
      final day = int.tryParse(textMonthMatch.group(1)!) ?? 1;
      final monthStr = textMonthMatch.group(2)!.toLowerCase();
      final month = _monthMap[monthStr] ?? 1;
      final year = int.tryParse(textMonthMatch.group(3) ?? '') ?? DateTime.now().year;
      int hour = int.tryParse(textMonthMatch.group(4)!) ?? 0;
      final minute = int.tryParse(textMonthMatch.group(5)!) ?? 0;
      final ampm = textMonthMatch.group(7)?.toUpperCase();

      if (ampm == 'PM' && hour < 12) hour += 12;
      if (ampm == 'AM' && hour == 12) hour = 0;

      return DateTime(year, month, day, hour, minute);
    }

    // 4. Match Date without time: "21 Aug 2026" or "21 August"
    final dateOnlyRegex = RegExp(
      r'(\d{1,2})\s+([A-Za-z]+)(?:\s+(\d{4}))?',
      caseSensitive: false,
    );
    final dateOnlyMatch = dateOnlyRegex.firstMatch(raw);
    if (dateOnlyMatch != null) {
      final day = int.tryParse(dateOnlyMatch.group(1)!) ?? 1;
      final monthStr = dateOnlyMatch.group(2)!.toLowerCase();
      if (_monthMap.containsKey(monthStr)) {
        final month = _monthMap[monthStr]!;
        final year = int.tryParse(dateOnlyMatch.group(3) ?? '') ?? DateTime.now().year;
        return DateTime(year, month, day, 12, 0);
      }
    }

    // 5. Match Time only: "02:52 PM" or "14:52"
    final timeOnlyRegex = RegExp(
      r'\b(\d{1,2}):(\d{2})(?::(\d{2}))?\s*(AM|PM|am|pm)?\b',
    );
    final timeOnlyMatch = timeOnlyRegex.firstMatch(raw);
    if (timeOnlyMatch != null) {
      final now = DateTime.now();
      int hour = int.tryParse(timeOnlyMatch.group(1)!) ?? 0;
      final minute = int.tryParse(timeOnlyMatch.group(2)!) ?? 0;
      final ampm = timeOnlyMatch.group(4)?.toUpperCase();

      if (ampm == 'PM' && hour < 12) hour += 12;
      if (ampm == 'AM' && hour == 12) hour = 0;

      return DateTime(now.year, now.month, now.day, hour, minute);
    }

    return DateTime.now();
  }

  static DateTime _parseRelativeTime(String? text) => parseTimestamp(text);
}
