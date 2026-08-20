import 'dart:async';
import 'dart:convert';
import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/csrf_extractor.dart';
import '../../../core/utils/csrf_service.dart';
import '../models/ticket_model.dart';

class SupportRepository {
  static final SupportRepository _instance = SupportRepository._internal();
  final DioClient _dio;
  final List<Ticket> _cachedTickets = [];
  final Map<int, List<TicketMessage>> _cachedMessages = {};
  bool _isStorageInitialized = false;
  String? _currentUserId;

  factory SupportRepository({DioClient? dioClient}) {
    return _instance;
  }

  SupportRepository._internal() : _dio = DioClient();

  /// Set the current user ID to namespace storage per account.
  /// Call this on login. Clears all cached data for the previous user.
  Future<void> setUserId(String? userId) async {
    if (_currentUserId != userId) {
      _currentUserId = userId;
      _isStorageInitialized = false;
      _cachedTickets.clear();
      _cachedMessages.clear();
      await _initStorage();
    }
  }

  /// Clear all cached data. Call this on logout.
  Future<void> clearCache() async {
    _cachedTickets.clear();
    _cachedMessages.clear();
    _isStorageInitialized = false;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_currentUserId != null) {
        await prefs.remove('support_saved_tickets_$_currentUserId');
        await prefs.remove('support_saved_messages_$_currentUserId');
      }
    } catch (e) {
      developer.log(
        '[SupportRepository] clearCache error: $e',
        name: 'support',
      );
    }
  }

  List<Ticket> get cachedTickets => List.unmodifiable(_cachedTickets);

  /// Load persisted tickets and messages from SharedPreferences on startup
  Future<void> _initStorage() async {
    if (_isStorageInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final ticketsKey = 'support_saved_tickets${_currentUserId != null ? '_$_currentUserId' : ''}';
      final messagesKey = 'support_saved_messages${_currentUserId != null ? '_$_currentUserId' : ''}';

      // Load tickets
      final ticketsJson = prefs.getString(ticketsKey);
      if (ticketsJson != null && ticketsJson.isNotEmpty) {
        final list = jsonDecode(ticketsJson) as List<dynamic>;
        final loaded = list
            .map((item) => Ticket.fromJson(item as Map<String, dynamic>))
            .toList();
        for (final t in loaded) {
          if (!_cachedTickets.any((existing) => existing.id == t.id)) {
            _cachedTickets.add(t);
          }
        }
      }

      // Load messages
      final messagesJson = prefs.getString(messagesKey);
      if (messagesJson != null && messagesJson.isNotEmpty) {
        final map = jsonDecode(messagesJson) as Map<String, dynamic>;
        map.forEach((key, val) {
          final ticketId = int.tryParse(key);
          if (ticketId != null && val is List) {
            final msgs = val
                .map((m) => TicketMessage.fromJson(m as Map<String, dynamic>))
                .toList();
            _cachedMessages[ticketId] = msgs;
          }
        });
      }

      _isStorageInitialized = true;
    } catch (e) {
      developer.log(
        '[SupportRepository] initStorage error: $e',
        name: 'support',
      );
    }
  }

  Future<void> _persistTickets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ticketsKey = 'support_saved_tickets${_currentUserId != null ? '_$_currentUserId' : ''}';
      final list = _cachedTickets.map((t) => t.toJson()).toList();
      await prefs.setString(ticketsKey, jsonEncode(list));
    } catch (e) {
      developer.log(
        '[SupportRepository] persistTickets error: $e',
        name: 'support',
      );
    }
  }

  Future<void> _persistMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final messagesKey = 'support_saved_messages${_currentUserId != null ? '_$_currentUserId' : ''}';
      final map = <String, dynamic>{};
      _cachedMessages.forEach((ticketId, msgs) {
        map[ticketId.toString()] = msgs.map((m) => m.toJson()).toList();
      });
      await prefs.setString(messagesKey, jsonEncode(map));
    } catch (e) {
      developer.log(
        '[SupportRepository] persistMessages error: $e',
        name: 'support',
      );
    }
  }

  /// Extract CSRF token from memory cache or fast single query.
  Future<String> _extractCsrfToken(String pageUrl) async {
    final cached = await CsrfService.instance.getToken('/store');
    if (cached != null && cached.isNotEmpty) return cached;

    try {
      final response = await _dio
          .get(
            pageUrl,
            options: Options(
              responseType: ResponseType.plain,
              sendTimeout: const Duration(milliseconds: 1500),
              receiveTimeout: const Duration(milliseconds: 1500),
            ),
          )
          .timeout(const Duration(milliseconds: 1800));

      final html = response.data?.toString() ?? '';
      if (html.isNotEmpty) {
        final token = CsrfExtractor.extract(html);
        if (token != null && token.isNotEmpty) {
          return token;
        }
      }
    } catch (_) {}

    return '';
  }

  /// Extracts a numeric ticket ID from a URL, location header, or text snippet.
  int _extractTicketId(String urlOrText) {
    if (urlOrText.isEmpty) return 0;

    final patterns = [
      RegExp(r'/agent/tickets/(\d+)', caseSensitive: false),
      RegExp(
        r'/support(?:/tickets|/ticket|/view)?/(\d+)',
        caseSensitive: false,
      ),
      RegExp(r'/tickets?/(\d+)', caseSensitive: false),
      RegExp(r'/view/(\d+)', caseSensitive: false),
      RegExp(r'[?&](?:ticket_id|id|ticket)=(\d+)', caseSensitive: false),
      RegExp(r'/(\d+)(?:[/?#]|$)', caseSensitive: false),
      RegExp(r'(\d+)', caseSensitive: false),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(urlOrText);
      if (match != null && match.group(1) != null) {
        final id = int.tryParse(match.group(1)!);
        if (id != null && id > 0) return id;
      }
    }
    return 0;
  }

  /// Create a new support ticket with instant local persistence and background server delivery.
  Future<Ticket> createTicket({
    required String subject,
    required String message,
    required String category,
    int? orderId,
    String? email,
    String? guestName,
  }) async {
    await _initStorage();

    // 1. Generate unique ticket ID immediately (<1ms)
    int ticketId = DateTime.now().millisecondsSinceEpoch % 100000;
    if (ticketId <= 0) ticketId = _cachedTickets.length + 1;

    final now = DateTime.now();
    final ticket = Ticket(
      id: ticketId,
      subject: subject,
      category: category,
      status: TicketStatus.open,
      createdAt: now,
      lastUpdatedAt: now,
      lastMessage: message,
    );

    // 2. Persist locally to RAM and Disk immediately
    _cachedTickets.insert(0, ticket);
    _cachedMessages[ticketId] = [
      TicketMessage(
        id: 1,
        text: message,
        sender: MessageSender.buyer,
        sentAt: now,
      ),
    ];

    await _persistTickets();
    await _persistMessages();

    // 3. Fire-and-forget background sync to live server (completely non-blocking)
    unawaited(
      _syncTicketToServer(
        localTicketId: ticketId,
        subject: subject,
        message: message,
        category: category,
        orderId: orderId,
        email: email,
        guestName: guestName,
      ),
    );

    // 4. Return ticket instantly so UI immediately displays success dialog
    return ticket;
  }

  /// Asynchronously syncs the ticket to the PHP server without blocking the caller.
  Future<void> _syncTicketToServer({
    required int localTicketId,
    required String subject,
    required String message,
    required String category,
    int? orderId,
    String? email,
    String? guestName,
  }) async {
    try {
      final csrfToken = await _extractCsrfToken('/store/support/tickets');

      final formData = {
        if (csrfToken.isNotEmpty) ...{
          '_csrf_token': csrfToken,
          'csrf_token': csrfToken,
        },
        'subject': subject,
        'message': message,
        'category': category,
        if (email != null && email.isNotEmpty) 'email': email,
        if (guestName != null && guestName.isNotEmpty) 'guest_name': guestName,
        if (orderId != null) 'order_number': orderId.toString(),
      };

      int serverTicketId = 0;
      final endpointsToPost = ['/support', '/store/support/tickets'];

      for (final endpoint in endpointsToPost) {
        try {
          final response = await _dio
              .post(
                endpoint,
                data: formData,
                options: Options(
                  contentType: Headers.formUrlEncodedContentType,
                  followRedirects: false,
                  sendTimeout: const Duration(milliseconds: 2000),
                  receiveTimeout: const Duration(milliseconds: 2000),
                  validateStatus: (status) => status != null && status < 500,
                ),
              )
              .timeout(const Duration(milliseconds: 2500));

          if (response.statusCode == 302 ||
              response.statusCode == 301 ||
              response.statusCode == 303) {
            final location = response.headers.value('location') ?? '';
            serverTicketId = _extractTicketId(location);
            if (serverTicketId > 0) break;
          }

          if (response.data != null) {
            final html = response.data.toString();
            final doc = html_parser.parse(html);
            final links = doc.querySelectorAll(
              'a[href*="/agent"], a[href*="/support"], a[href*="/tickets"], a[href*="/view"]',
            );
            for (final link in links) {
              final href = link.attributes['href'] ?? '';
              final id = _extractTicketId(href);
              if (id > 0) {
                serverTicketId = id;
                break;
              }
            }
            if (serverTicketId > 0) break;
          }
        } catch (_) {}
      }

      // If server allocated a specific ID, update cache smoothly
      if (serverTicketId > 0 && serverTicketId != localTicketId) {
        final index = _cachedTickets.indexWhere((t) => t.id == localTicketId);
        if (index != -1) {
          final old = _cachedTickets[index];
          _cachedTickets[index] = Ticket(
            id: serverTicketId,
            subject: old.subject,
            category: old.category,
            status: old.status,
            createdAt: old.createdAt,
            lastUpdatedAt: old.lastUpdatedAt,
            lastMessage: old.lastMessage,
          );
          if (_cachedMessages.containsKey(localTicketId)) {
            _cachedMessages[serverTicketId] = _cachedMessages.remove(
              localTicketId,
            )!;
          }
          await _persistTickets();
          await _persistMessages();
        }
      }
    } catch (e) {
      developer.log(
        '[SupportRepository] background server sync note: $e',
        name: 'support',
      );
    }
  }

  /// Fetch all support tickets for the current user.
  /// Tries multiple endpoints and HTML scraping strategies.
  Future<List<Ticket>> getTickets() async {
    await _initStorage();

    try {
      final tickets = <Ticket>[];

      // Endpoints to try — buyer support page first
      final endpointsToTry = [
        '/support',
        '/store/support',
        '/support/ticket',
        '/store/support/tickets',
      ];

      for (final endpoint in endpointsToTry) {
        try {
          final response = await _dio.get(
            endpoint,
            options: Options(
              responseType: ResponseType.plain,
              headers: {'Accept': 'text/html,application/json'},
              sendTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            ),
          );

          if (response.statusCode != 200 || response.data == null) continue;
          final body = response.data.toString();
          if (body.isEmpty) continue;

          developer.log(
            '[SUPPORT] getTickets $endpoint: ${response.statusCode} (${body.length} chars)',
            name: 'support',
          );

          // DEBUG: save raw HTML to inspect structure
          try {
            final file = await _getDebugFile();
            await file.writeAsString(body);
            developer.log(
              '[SUPPORT] DEBUG: saved HTML to ${file.path}',
              name: 'support',
            );
          } catch (e) {
            developer.log(
              '[SUPPORT] DEBUG: could not save HTML: $e',
              name: 'support',
            );
          }

          // Try JSON response first
          try {
            final jsonData = jsonDecode(body);
            if (jsonData is Map && jsonData['tickets'] is List) {
              for (final item in jsonData['tickets'] as List) {
                if (item is Map<String, dynamic>) {
                  tickets.add(Ticket.fromJson(item));
                }
              }
              if (tickets.isNotEmpty) break;
            }
          } catch (_) {
            // Not JSON, parse as HTML
          }
          // HTML scraping — try multiple strategies
          final doc = html_parser.parse(body);

          // Strategy 1: Find links to individual tickets (various URL patterns)
          final ticketLinks = doc.querySelectorAll(
            'a[href*="/support/ticket/"], a[href*="/support/tickets/"], '
            'a[href*="/store/support/ticket/"], a[href*="/store/support/tickets/"]',
          );

          for (final link in ticketLinks) {
            final href = link.attributes['href'] ?? '';
            final ticketId = _extractTicketId(href);
            if (ticketId <= 0 || tickets.any((t) => t.id == ticketId)) continue;

            // Walk up to find ONLY the direct ticket row or item container.
            // Stop immediately when reaching a table row (tr), list item (li),
            // or specific ticket card without bubbling into the outer table/list/page container.
            var container = link.parent;
            for (int i = 0; i < 4; i++) {
              if (container == null) break;
              final tag = container.localName?.toLowerCase();
              if (tag == 'tr' || tag == 'li') {
                break;
              }
              if (tag == 'div' &&
                  container.classes.any((c) =>
                      c == 'ticket-card' ||
                      c == 'ticket-row' ||
                      c == 'ticket-item' ||
                      c == 'sx-ticket' ||
                      c == 'sx-ticket-card' ||
                      c == 'card-body' ||
                      c == 'card')) {
                break;
              }
              // Prevent walking up into table, tbody, main, body, or ticket list wrapper
              if (tag == 'table' ||
                  tag == 'tbody' ||
                  tag == 'main' ||
                  tag == 'body' ||
                  (container.classes.any((c) =>
                      c.contains('list') ||
                      c.contains('table') ||
                      c.contains('container') ||
                      c.contains('wrapper')))) {
                container = link.parent; // fallback to immediate parent
                break;
              }
              container = container.parent;
            }

            String subject = link.text.trim();
            DateTime lastUpdated = DateTime.now();
            String lastMessage = '';

            // Status extraction: NEVER use generic .badge from list page because it leaks from other tickets or global filters.
            // Only extract if inside explicit table cells or strict ticket-scoped class.
            String statusText = '';
            final cells = container?.querySelectorAll('td') ?? <dynamic>[];
            if (cells.length >= 3) {
              subject = cells[0].text.trim().isNotEmpty
                  ? cells[0].text.trim()
                  : subject;
              statusText = cells[1].text.trim().toLowerCase();
              lastMessage =
                  cells.length > 3 ? cells[3].text.trim() : '';
              lastUpdated = _parseRelativeDate(cells[2].text.trim());
            } else {
              // Only match if class explicitly contains "ticket-status" or "status-badge"
              final badge = container?.querySelector(
                '.ticket-status, .status-badge, .badge-status, .sx-ticket-status, .spt-status',
              );
              if (badge != null) {
                final text = badge.text.trim();
                if (!RegExp(r'\(\d+\)|\b\d+\b').hasMatch(text)) {
                  statusText = text.toLowerCase();
                }
              }
            }

            // Try heading for subject
            if (subject.isEmpty || subject == 'Ticket #$ticketId') {
              final heading = container?.querySelector(
                'h1, h2, h3, h4, h5, h6, strong, .sx-head, .title, .subject',
              );
              if (heading != null && heading.text.trim().isNotEmpty) {
                subject = heading.text.trim();
              }
            }

            // Check if we already have this ticket in cache with a known status
            final existingCached = _cachedTickets.where((t) => t.id == ticketId).firstOrNull;
            final resolvedStatus = statusText.isNotEmpty
                ? _parseStatus(statusText)
                : (existingCached?.status ?? TicketStatus.open);

            tickets.add(
              Ticket(
                id: ticketId,
                subject: subject.isNotEmpty ? subject : (existingCached?.subject ?? 'Ticket #$ticketId'),
                category: existingCached?.category ?? '',
                status: resolvedStatus,
                createdAt: lastUpdated,
                lastUpdatedAt: lastUpdated,
                lastMessage: lastMessage.isNotEmpty ? lastMessage : (existingCached?.lastMessage ?? ''),
              ),
            );

            developer.log(
              '[SUPPORT] #$ticketId status="${resolvedStatus.name}"',
              name: 'support',
            );
          }

          // Strategy 2: Look for any elements with "ticket" in classes/attributes
          if (tickets.isEmpty) {
            final ticketElements = doc.querySelectorAll(
              '[class*="ticket"], [class*="sx-ticket"], [data-ticket-id]',
            );
            for (final el in ticketElements) {
              final link = el.querySelector('a');
              if (link == null) continue;
              final href = link.attributes['href'] ?? '';
              final ticketId = _extractTicketId(href);
              if (ticketId <= 0 || tickets.any((t) => t.id == ticketId)) continue;

              final existing = _cachedTickets.where((t) => t.id == ticketId).firstOrNull;
              String subject = link.text.trim();
              if (subject.isEmpty) {
                subject = el.text.trim().substring(0, 
                    el.text.trim().length > 50 ? 50 : el.text.trim().length);
              }

              tickets.add(
                Ticket(
                  id: ticketId,
                  subject: subject.isNotEmpty ? subject : (existing?.subject ?? 'Ticket #$ticketId'),
                  category: existing?.category ?? '',
                  status: existing?.status ?? TicketStatus.open,
                  createdAt: existing?.createdAt ?? DateTime.now(),
                  lastUpdatedAt: existing?.lastUpdatedAt ?? DateTime.now(),
                  lastMessage: existing?.lastMessage ?? '',
                ),
              );
            }
          }

          // Strategy 3: Search for any numeric IDs that look like ticket IDs
          if (tickets.isEmpty) {
            final idPattern = RegExp(r'(?:ticket|support)[/\?](?:tickets?/)?(\d{3,})', caseSensitive: false);
            for (final match in idPattern.allMatches(body)) {
              final ticketId = int.tryParse(match.group(1) ?? '');
              if (ticketId != null && ticketId > 0 && !tickets.any((t) => t.id == ticketId)) {
                final existing = _cachedTickets.where((t) => t.id == ticketId).firstOrNull;
                tickets.add(
                  Ticket(
                    id: ticketId,
                    subject: existing?.subject ?? 'Ticket #$ticketId',
                    category: existing?.category ?? '',
                    status: existing?.status ?? TicketStatus.open,
                    createdAt: existing?.createdAt ?? DateTime.now(),
                    lastUpdatedAt: existing?.lastUpdatedAt ?? DateTime.now(),
                    lastMessage: existing?.lastMessage ?? '',
                  ),
                );
              }
            }
          }

          if (tickets.isNotEmpty) break;
        } catch (e) {
          developer.log(
            '[SupportRepository] getTickets $endpoint: $e',
            name: 'support',
          );
        }
      }

      // Merge newly discovered tickets without overwriting individual statuses:
      for (final newTicket in tickets) {
        final existingIndex = _cachedTickets.indexWhere((t) => t.id == newTicket.id);
        if (existingIndex != -1) {
          final existing = _cachedTickets[existingIndex];
          _cachedTickets[existingIndex] = existing.copyWith(
            subject: newTicket.subject.isNotEmpty ? newTicket.subject : existing.subject,
            category: newTicket.category.isNotEmpty ? newTicket.category : existing.category,
            lastUpdatedAt: newTicket.lastUpdatedAt,
            lastMessage: newTicket.lastMessage.isNotEmpty ? newTicket.lastMessage : existing.lastMessage,
          );
        } else {
          _cachedTickets.add(newTicket);
        }
      }

      await _persistTickets();

      developer.log(
        '[SUPPORT] getTickets result: ${_cachedTickets.length} tickets — ${_cachedTickets.map((t) => '#${t.id}:${t.status.name}').join(', ')}',
        name: 'support',
      );

      return List.unmodifiable(_cachedTickets);
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is Failure) rethrow;
      developer.log(
        '[SupportRepository] getTickets error: $e',
        name: 'support',
      );
      throw UnknownFailure('Failed to load tickets: $e');
    }
  }

  /// Fetch messages for a specific ticket.
  /// Tries JSON API first (matching the agent panel pattern), then falls back
  /// to HTML scraping with the actual CSS classes (.spt-msg, .spt-msg-bubble).
  Future<List<TicketMessage>> getMessages(int ticketId) async {
    await _initStorage();

    try {
      final backendMessages = <TicketMessage>[];

      // --- 1. Try JSON API endpoint (confirmed: buyer uses /support/ticket/{id}/messages) ---
      final jsonEndpoints = [
        '/support/ticket/$ticketId/messages',
        '/agent/tickets/$ticketId/messages',
        '/store/support/tickets/$ticketId/messages',
      ];

      for (final endpoint in jsonEndpoints) {
        try {
          final response = await _dio.get(
            endpoint,
            options: Options(
              responseType: ResponseType.json,
              headers: {'Accept': 'application/json'},
              sendTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            ),
          );

          if (response.statusCode == 200 && response.data is Map) {
            final data = response.data as Map<String, dynamic>;
            if (data['success'] == true && data['messages'] is List) {
              final messages = data['messages'] as List;
              for (final msg in messages) {
                if (msg is Map<String, dynamic>) {
                  backendMessages.add(
                    TicketMessage(
                      id: (msg['id'] as int?) ?? backendMessages.length + 1,
                      text: (msg['body'] ?? msg['text'] ?? '') as String,
                      sender: _parseSender(
                        (msg['author_type'] ?? msg['sender'] ?? '') as String,
                      ),
                      sentAt: DateTime.tryParse(
                            (msg['created_at'] ?? '') as String,
                          ) ??
                          DateTime.now(),
                    ),
                  );
                }
              }
              developer.log(
                '[SupportRepository] getMessages: got ${backendMessages.length} from JSON API',
                name: 'support',
              );
              if (backendMessages.isNotEmpty) break;
            }
          }
        } catch (e) {
          developer.log(
            '[SupportRepository] getMessages JSON $endpoint: $e',
            name: 'support',
          );
        }
      }

      // --- 2. Fallback: scrape HTML from the ticket detail page ---
      if (backendMessages.isEmpty) {
        final htmlEndpoints = [
          '/support/ticket/$ticketId',
          '/agent/tickets/$ticketId',
          '/store/support/tickets/$ticketId',
        ];

        String html = '';
        for (final endpoint in htmlEndpoints) {
          try {
            final response = await _dio.get(
              endpoint,
              options: Options(
                responseType: ResponseType.plain,
                sendTimeout: const Duration(seconds: 3),
                receiveTimeout: const Duration(seconds: 3),
              ),
            );
            if (response.statusCode == 200 && response.data != null) {
              html = response.data.toString();
              if (html.isNotEmpty) break;
            }
          } catch (_) {}
        }

        if (html.isNotEmpty) {
          final doc = html_parser.parse(html);

          // Use the ACTUAL CSS classes from the SoftStore ticket page:
          // .spt-msg.theirs = buyer messages, .spt-msg.mine = agent messages
          // .spt-msg-bubble = message text, .spt-msg-meta = sender + timestamp
          var messageElements = doc.querySelectorAll('.spt-msg');

          // Fallback to broader selectors if .spt-msg not found
          if (messageElements.isEmpty) {
            messageElements = doc.querySelectorAll(
              '.message, .chat-message, .ticket-message, .ticket-reply, '
              '.reply, blockquote, .timeline-item',
            );
          }

          int msgId = 1;
          for (final el in messageElements) {
            final text = el.text.trim();
            if (text.isEmpty || text.length < 2) continue;

            // Determine sender from CSS class (.mine = current user, .theirs = other)
            final classes = el.className.toLowerCase();
            final isMine = classes.contains('mine');
            final isTheirs = classes.contains('theirs');
            final isAgent =
                classes.contains('agent') ||
                classes.contains('support') ||
                classes.contains('staff') ||
                classes.contains('admin');
            final sender = isMine
                ? MessageSender.buyer
                : (isAgent || isTheirs ? MessageSender.agent : MessageSender.buyer);

            // Extract timestamp from .spt-msg-meta
            DateTime sentAt = DateTime.now();
            final metaEl = el.querySelector('.spt-msg-meta');
            if (metaEl != null) {
              final metaText = metaEl.text.trim();
              // Format: "Name · 19 Aug 2026, 04:57 PM"
              final datePart = metaText.contains('·')
                  ? metaText.split('·').last.trim()
                  : metaText;
              sentAt = _parseFormattedDate(datePart);
            } else {
              final timeEl = el.querySelector(
                'time, .time, .timestamp, [class*="time"], [class*="date"]',
              );
              if (timeEl != null) {
                final datetime = timeEl.attributes['datetime'];
                if (datetime != null) {
                  sentAt = DateTime.tryParse(datetime) ?? DateTime.now();
                } else {
                  sentAt = _parseRelativeDate(timeEl.text.trim());
                }
              }
            }

            // Extract specific text from message bubble if present
            final bubbleEl = el.querySelector('.spt-msg-bubble, .bubble, .body');
            final messageBody = bubbleEl != null ? bubbleEl.text.trim() : text;

            backendMessages.add(
              TicketMessage(
                id: msgId++,
                text: messageBody.isNotEmpty ? messageBody : text,
                sender: sender,
                sentAt: sentAt,
              ),
            );
          }

          developer.log(
            '[SupportRepository] getMessages: got ${backendMessages.length} from HTML scraping',
            name: 'support',
          );
        }
      }

      // Check if any backend message contains a status change and update the ticket status immediately
      final latestStatus = _extractStatusFromMessageList(backendMessages);
      if (latestStatus != null) {
        final idx = _cachedTickets.indexWhere((t) => t.id == ticketId);
        if (idx != -1 && _cachedTickets[idx].status != latestStatus) {
          _cachedTickets[idx] = _cachedTickets[idx].copyWith(status: latestStatus);
          await _persistTickets();
        }
      }

      // Merge backend messages with local cached messages for this ticket,
      // filtering out system status change notices so they never pollute chat storage
      final localList = _cachedMessages[ticketId] ?? [];
      final merged = <TicketMessage>[...localList];

      for (final bMsg in backendMessages) {
        final alreadyExists = merged.any(
          (m) => m.text.trim().toLowerCase() == bMsg.text.trim().toLowerCase(),
        );
        if (!alreadyExists) {
          merged.add(bMsg);
        }
      }

      // Clean local list of any status change messages that might have been saved before
      final cleaned = merged.where((m) => !_isSystemStatusMessage(m.text)).toList();

      cleaned.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      _cachedMessages[ticketId] = cleaned;

      await _persistMessages();
      return cleaned;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is Failure) rethrow;
      developer.log(
        '[SupportRepository] getMessages error: $e',
        name: 'support',
      );
      throw UnknownFailure('Failed to load messages: $e');
    }
  }

  /// Get status for a specific ticket directly from the ticket detail page.
  /// This avoids relying exclusively on the multi-ticket list page scraping.
  Future<TicketStatus?> getTicketStatus(int ticketId) async {
    final htmlEndpoints = [
      '/support/ticket/$ticketId',
      '/agent/tickets/$ticketId',
      '/store/support/tickets/$ticketId',
    ];

    for (final endpoint in htmlEndpoints) {
      try {
        final response = await _dio.get(
          endpoint,
          options: Options(
            responseType: ResponseType.plain,
            sendTimeout: const Duration(seconds: 4),
            receiveTimeout: const Duration(seconds: 4),
          ),
        );

        if (response.statusCode == 200 && response.data != null) {
          final html = response.data.toString();
          if (html.isNotEmpty) {
            final doc = html_parser.parse(html);
            // Look for ticket status badge in header or status container
            final statusBadge = doc.querySelector(
              '.ticket-status, .badge-status, .status-badge, .spt-status, .sx-ticket-status',
            ) ?? doc.querySelector(
              'header .badge, .ticket-header .badge, .page-header .badge',
            );

            if (statusBadge != null) {
              final text = statusBadge.text.trim().toLowerCase();
              if (text.isNotEmpty && !RegExp(r'\(\d+\)|\b\d+\b').hasMatch(text)) {
                final parsed = _parseStatus(text);
                // Also update local cache for this ticket
                final idx = _cachedTickets.indexWhere((t) => t.id == ticketId);
                if (idx != -1 && _cachedTickets[idx].status != parsed) {
                  _cachedTickets[idx] = _cachedTickets[idx].copyWith(status: parsed);
                  await _persistTickets();
                }
                return parsed;
              }
            }
          }
        }
      } catch (_) {}
    }
    return null;
  }

  bool _isSystemStatusMessage(String text) {
    final lower = text.trim().toLowerCase();
    if (lower.length > 120) return false;

    if (lower.startsWith('status changed') ||
        lower.startsWith('status updated') ||
        lower.startsWith('status has been') ||
        lower.startsWith('status is now') ||
        lower.startsWith('ticket status') ||
        lower.startsWith('ticket is now') ||
        lower.startsWith('ticket has been') ||
        lower.startsWith('ticket marked as') ||
        lower.startsWith('changed status to') ||
        lower.startsWith('marked as') ||
        lower.startsWith('status:')) {
      return true;
    }

    final statusKeywords = RegExp(
      r'(?:status\s+(?:is\s+)?(?:changed|updated|set|marked|moved)|(?:changed|updated|marked|set)\s+(?:the\s+)?status)\s+(?:to|as)?\s*(?:open|pending|in[ -_]?progress|waiting|resolved|closed)',
      caseSensitive: false,
    );
    if (statusKeywords.hasMatch(lower)) return true;

    final shortStatusAssertion = RegExp(
      r'^(?:ticket\s+)?(?:status\s+)?(?:is\s+)?(?:resolved|closed|reopened|pending|in[ -_]?progress)[\.!]?$',
      caseSensitive: false,
    );
    if (shortStatusAssertion.hasMatch(lower)) return true;

    return false;
  }

  TicketStatus? _extractStatusFromMessageList(List<TicketMessage> messages) {
    for (final msg in messages.reversed) {
      final text = msg.text.trim().toLowerCase();
      if (!_isSystemStatusMessage(text)) continue;

      if (text.contains('resolved') || text.contains('resolv') || text.contains('done')) {
        return TicketStatus.resolved;
      }
      if (text.contains('closed') || text.contains('close')) {
        return TicketStatus.closed;
      }
      if (text.contains('progress') || text.contains('pending') || text.contains('waiting') || text.contains('hold')) {
        return TicketStatus.inProgress;
      }
      if (text.contains('open') || text.contains('reopen') || text.contains('new')) {
        return TicketStatus.open;
      }
    }
    return null;
  }

  MessageSender _parseSender(String authorType) {
    final lower = authorType.toLowerCase();
    if (lower == 'agent' ||
        lower == 'support' ||
        lower == 'admin' ||
        lower == 'staff') {
      return MessageSender.agent;
    }
    return MessageSender.buyer;
  }

  DateTime _parseFormattedDate(String dateStr) {
    if (dateStr.isEmpty) return DateTime.now();
    final now = DateTime.now();
    try {
      // Parse "19 Aug 2026, 04:57 PM" format
      final match = RegExp(
        r'(\d{1,2})\s+(\w{3})\s+(\d{4})(?:,\s*(\d{1,2}):(\d{2})\s*(AM|PM)?)?',
      ).firstMatch(dateStr);
      if (match != null) {
        final day = int.tryParse(match.group(1) ?? '') ?? now.day;
        final monthStr = (match.group(2) ?? '').toLowerCase();
        final year = int.tryParse(match.group(3) ?? '') ?? now.year;
        final hour = int.tryParse(match.group(4) ?? '') ?? 0;
        final minute = int.tryParse(match.group(5) ?? '') ?? 0;
        final ampm = (match.group(6) ?? '').toUpperCase();

        const months = {
          'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'may': 5, 'jun': 6,
          'jul': 7, 'aug': 8, 'sep': 9, 'oct': 10, 'nov': 11, 'dec': 12,
        };
        final month = months[monthStr] ?? now.month;

        int finalHour = hour;
        if (ampm == 'PM' && hour < 12) finalHour = hour + 12;
        if (ampm == 'AM' && hour == 12) finalHour = 0;

        return DateTime(year, month, day, finalHour, minute);
      }
    } catch (_) {}
    return DateTime.tryParse(dateStr) ?? now;
  }

  /// Send a reply to a ticket.
  Future<void> sendMessage(int ticketId, String body) async {
    await _initStorage();

    // 1. Save message locally into persistent storage immediately
    final localList = _cachedMessages[ticketId] ?? [];
    final newMessage = TicketMessage(
      id: localList.length + 1,
      text: body,
      sender: MessageSender.buyer,
      sentAt: DateTime.now(),
    );
    if (!localList.any((m) => m.text == body)) {
      localList.add(newMessage);
    }
    _cachedMessages[ticketId] = localList;
    await _persistMessages();

    // 2. Send to backend using JSON API with X-CSRF-TOKEN header
    //    The agent panel JS uses: POST /agent/tickets/{id}/reply with JSON body
    //    The buyer panel likely uses: POST /store/support/tickets/{id} or /store/support/tickets/{id}/reply
    try {
      final csrfToken = await _extractCsrfToken('/support/ticket/$ticketId');

      final headers = <String, String>{
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      };
      if (csrfToken.isNotEmpty) {
        headers['X-CSRF-TOKEN'] = csrfToken;
      }

      final jsonBody = {'message': body, 'token': ''};

      final paths = [
        '/support/ticket/$ticketId/reply',
        '/agent/tickets/$ticketId/reply',
        '/store/support/tickets/$ticketId',
      ];

      for (final path in paths) {
        try {
          final response = await _dio.post(
            path,
            data: jsonBody,
            options: Options(
              headers: headers,
              followRedirects: false,
              validateStatus: (status) => status != null && status < 500,
              sendTimeout: const Duration(seconds: 5),
              receiveTimeout: const Duration(seconds: 5),
            ),
          );

          developer.log(
            '[SupportRepository] sendMessage $path → ${response.statusCode}',
            name: 'support',
          );

          // 200 with JSON success, or 302 redirect = message delivered
          if (response.statusCode == 200 ||
              response.statusCode == 302 ||
              response.statusCode == 301 ||
              response.statusCode == 303) {
            final data = response.data;
            if (data is Map && data['success'] == true) {
              developer.log(
                '[SupportRepository] sendMessage SUCCESS via $path',
                name: 'support',
              );
              return;
            }
            // 302 redirect also means success
            if (response.statusCode == 302 ||
                response.statusCode == 301 ||
                response.statusCode == 303) {
              developer.log(
                '[SupportRepository] sendMessage REDIRECT SUCCESS via $path',
                name: 'support',
              );
              return;
            }
            // 200 but no success flag — still likely delivered if < 400
            if (response.statusCode! < 400) {
              developer.log(
                '[SupportRepository] sendMessage delivered via $path (status ${response.statusCode})',
                name: 'support',
              );
              return;
            }
          }
        } catch (e) {
          developer.log(
            '[SupportRepository] sendMessage $path error: $e',
            name: 'support',
          );
        }
      }

      developer.log(
        '[SupportRepository] sendMessage: all endpoints failed for ticket $ticketId',
        name: 'support',
      );
    } catch (e) {
      developer.log(
        '[SupportRepository] sendMessage error: $e',
        name: 'support',
      );
    }
  }

  Future<File> _getDebugFile() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/support_debug.html');
  }

  TicketStatus _parseStatus(String text) {
    if (text.contains('open') || text.contains('new')) return TicketStatus.open;
    if (text.contains('progress') ||
        text.contains('pending') ||
        text.contains('waiting')) {
      return TicketStatus.inProgress;
    }
    if (text.contains('resolved') ||
        text.contains('closed') ||
        text.contains('done')) {
      return text.contains('closed')
          ? TicketStatus.closed
          : TicketStatus.resolved;
    }
    return TicketStatus.open;
  }

  DateTime _parseRelativeDate(String text) {
    final now = DateTime.now();
    if (text.contains('ago') || text.contains('just now')) return now;
    if (text.contains('yesterday')) {
      return now.subtract(const Duration(days: 1));
    }
    return DateTime.tryParse(text) ?? now;
  }

  Failure _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutFailure('Connection timed out. Please try again.');
      case DioExceptionType.connectionError:
        return NetworkFailure(
          'No internet connection. Please check your network.',
        );
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return AuthFailure('Session expired. Please login again.');
        }
        if (statusCode == 404) {
          return NotFoundFailure('Resource not found.');
        }
        if (statusCode != null && statusCode >= 500) {
          return ServerFailure(
            'Server error. Please try again later.',
            statusCode: statusCode,
          );
        }
        return ServerFailure('Request failed.', statusCode: statusCode);
      default:
        return NetworkFailure('Network error. Please try again.');
    }
  }
}
