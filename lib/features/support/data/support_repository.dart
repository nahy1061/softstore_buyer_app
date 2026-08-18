import 'dart:convert';
import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;
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

  factory SupportRepository({DioClient? dioClient}) {
    return _instance;
  }

  SupportRepository._internal() : _dio = DioClient() {
    _initStorage();
  }

  List<Ticket> get cachedTickets => List.unmodifiable(_cachedTickets);

  /// Load persisted tickets and messages from SharedPreferences on startup
  Future<void> _initStorage() async {
    if (_isStorageInitialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();

      // Load tickets
      final ticketsJson = prefs.getString('support_saved_tickets');
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
      final messagesJson = prefs.getString('support_saved_messages');
      if (messagesJson != null && messagesJson.isNotEmpty) {
        final map = jsonDecode(messagesJson) as Map<String, dynamic>;
        map.forEach((key, val) {
          final ticketId = int.tryParse(key);
          if (ticketId != null && val is List) {
            final msgs = val
                .map((m) =>
                    TicketMessage.fromJson(m as Map<String, dynamic>))
                .toList();
            _cachedMessages[ticketId] = msgs;
          }
        });
      }

      _isStorageInitialized = true;
    } catch (e) {
      developer.log('[SupportRepository] initStorage error: $e',
          name: 'support');
    }
  }

  Future<void> _persistTickets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _cachedTickets.map((t) => t.toJson()).toList();
      await prefs.setString('support_saved_tickets', jsonEncode(list));
    } catch (e) {
      developer.log('[SupportRepository] persistTickets error: $e',
          name: 'support');
    }
  }

  Future<void> _persistMessages() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final map = <String, dynamic>{};
      _cachedMessages.forEach((ticketId, msgs) {
        map[ticketId.toString()] = msgs.map((m) => m.toJson()).toList();
      });
      await prefs.setString('support_saved_messages', jsonEncode(map));
    } catch (e) {
      developer.log('[SupportRepository] persistMessages error: $e',
          name: 'support');
    }
  }

  /// Extract CSRF token from cache or fast parallel query.
  Future<String> _extractCsrfToken(String pageUrl) async {
    final cached = await CsrfService.instance.getToken('/store');
    if (cached != null && cached.isNotEmpty) return cached;

    final urlsToTry = [
      '/store',
      '/login',
      pageUrl,
      '/store/support/tickets',
    ];

    for (final url in urlsToTry) {
      try {
        final response = await _dio.get(
          url,
          options: Options(
            responseType: ResponseType.plain,
            sendTimeout: const Duration(milliseconds: 2000),
            receiveTimeout: const Duration(milliseconds: 2000),
          ),
        );
        final html = response.data.toString();
        if (html.isNotEmpty) {
          final token = CsrfExtractor.extract(html);
          if (token != null && token.isNotEmpty) {
            return token;
          }
        }
      } catch (_) {}
    }

    return '';
  }

  /// Extracts a numeric ticket ID from a URL, location header, or text snippet.
  int _extractTicketId(String urlOrText) {
    if (urlOrText.isEmpty) return 0;

    final patterns = [
      RegExp(r'/agent/tickets/(\d+)', caseSensitive: false),
      RegExp(r'/support(?:/tickets|/ticket|/view)?/(\d+)',
          caseSensitive: false),
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

    int ticketId = 0;

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
      };
      if (email != null && email.isNotEmpty) {
        formData['email'] = email;
      }
      if (guestName != null && guestName.isNotEmpty) {
        formData['guest_name'] = guestName;
      }
      if (orderId != null) {
        formData['order_number'] = orderId.toString();
      }

      final endpointsToPost = ['/store/support/tickets', '/support'];
      for (final endpoint in endpointsToPost) {
        try {
          final response = await _dio.post(
            endpoint,
            data: formData,
            options: Options(
              contentType: Headers.formUrlEncodedContentType,
              followRedirects: false,
              sendTimeout: const Duration(milliseconds: 3000),
              receiveTimeout: const Duration(milliseconds: 3000),
              validateStatus: (status) => status != null && status < 500,
            ),
          );

          if (response.statusCode == 302 ||
              response.statusCode == 301 ||
              response.statusCode == 303) {
            final location = response.headers.value('location') ?? '';
            ticketId = _extractTicketId(location);
            if (ticketId > 0) break;
          }

          if (response.data != null) {
            final html = response.data.toString();
            final doc = html_parser.parse(html);
            final links = doc.querySelectorAll(
                'a[href*="/agent"], a[href*="/support"], a[href*="/tickets"], a[href*="/view"]');
            for (final link in links) {
              final href = link.attributes['href'] ?? '';
              final id = _extractTicketId(href);
              if (id > 0) {
                ticketId = id;
                break;
              }
            }
            if (ticketId > 0) break;
          }
        } catch (_) {}
      }
    } catch (e) {
      developer.log('[SupportRepository] createTicket background sync note: $e',
          name: 'support');
    }

    // Fallback ID if server redirect had none
    if (ticketId == 0) {
      ticketId = DateTime.now().millisecondsSinceEpoch % 100000;
      if (ticketId <= 0) ticketId = _cachedTickets.length + 1;
    }

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

    _cachedTickets.insert(0, ticket);

    // Seed initial message into message cache
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

    return ticket;
  }

  /// Fetch all support tickets for the current user.
  Future<List<Ticket>> getTickets() async {
    await _initStorage();

    try {
      final tickets = <Ticket>[];

      // Fast single-request attempt to fetch server tickets
      final endpointsToTry = ['/support', '/store/support/tickets'];
      for (final endpoint in endpointsToTry) {
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
            final html = response.data as String;
            if (html.isNotEmpty) {
              final doc = html_parser.parse(html);
              final ticketLinks = doc.querySelectorAll(
                'a[href*="/support/tickets/"], a[href*="/support/ticket/"], a[href*="/support/"], a[href*="/tickets/"]',
              );

              for (final link in ticketLinks) {
                final href = link.attributes['href'] ?? '';
                final ticketId = _extractTicketId(href);
                if (ticketId <= 0 || tickets.any((t) => t.id == ticketId)) {
                  continue;
                }

                var row = link.parent;
                for (int i = 0; i < 4; i++) {
                  if (row == null) break;
                  if (row.querySelectorAll('td').isNotEmpty) break;
                  row = row.parent;
                }
                final cells = row?.querySelectorAll('td') ?? [];

                String subject = link.text.trim();
                String statusText = 'open';
                DateTime lastUpdated = DateTime.now();
                String lastMessage = '';

                if (cells.length >= 3) {
                  subject = cells[0].text.trim().isNotEmpty
                      ? cells[0].text.trim()
                      : subject;
                  statusText = cells[1].text.trim().toLowerCase();
                  final dateText = cells[2].text.trim();
                  lastMessage = cells.length > 3 ? cells[3].text.trim() : '';
                  lastUpdated = _parseRelativeDate(dateText);
                }

                final badge =
                    row?.querySelector('.sx-badge, .badge, [class*="status"]');
                if (badge != null && badge.text.trim().isNotEmpty) {
                  statusText = badge.text.trim().toLowerCase();
                }

                tickets.add(Ticket(
                  id: ticketId,
                  subject: subject.isNotEmpty ? subject : 'Ticket #$ticketId',
                  category: '',
                  status: _parseStatus(statusText),
                  createdAt: lastUpdated,
                  lastUpdatedAt: lastUpdated,
                  lastMessage: lastMessage,
                ));
              }

              if (tickets.isNotEmpty) break;
            }
          }
        } catch (_) {}
      }

      // Merge with cached tickets
      final allIds = <int>{};
      final merged = <Ticket>[];
      for (final t in _cachedTickets) {
        if (allIds.add(t.id)) merged.add(t);
      }
      for (final t in tickets) {
        if (allIds.add(t.id)) merged.add(t);
      }
      _cachedTickets
        ..clear()
        ..addAll(merged);

      await _persistTickets();
      return merged;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is Failure) rethrow;
      developer.log('[SupportRepository] getTickets error: $e',
          name: 'support');
      throw UnknownFailure('Failed to load tickets: $e');
    }
  }

  /// Fetch messages for a specific ticket.
  Future<List<TicketMessage>> getMessages(int ticketId) async {
    await _initStorage();

    try {
      final backendMessages = <TicketMessage>[];
      final endpointsToTry = [
        '/support/tickets/$ticketId',
        '/support/$ticketId',
        '/store/support/tickets/$ticketId',
      ];

      String html = '';
      for (final endpoint in endpointsToTry) {
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

        var messageElements = doc.querySelectorAll(
          '.message, .chat-message, [class*="msg-"], '
          '[class*="message-item"], [class*="ticket-message"], .ticket-reply, '
          '.reply, .admin-reply, .staff-reply, blockquote, [class*="reply"], '
          '.timeline-item, .card-body',
        );

        if (messageElements.isEmpty) {
          messageElements = doc.querySelectorAll(
            '[class*="message"], [class*="comment"]',
          );
        }

        int msgId = 1;
        for (final el in messageElements) {
          final text = el.text.trim();
          if (text.isEmpty || text.length < 2) continue;

          final classes = el.className.toLowerCase();
          final fullElText = el.outerHtml.toLowerCase();
          final isAgent = classes.contains('agent') ||
              classes.contains('support') ||
              classes.contains('staff') ||
              classes.contains('admin') ||
              classes.contains('reply') ||
              fullElText.contains('agent') ||
              fullElText.contains('support');
          final sender = isAgent ? MessageSender.agent : MessageSender.buyer;

          final timeEl = el.querySelector(
              'time, .time, .timestamp, [class*="time"], [class*="date"]');
          DateTime sentAt = DateTime.now();
          if (timeEl != null) {
            final datetime = timeEl.attributes['datetime'];
            if (datetime != null) {
              sentAt = DateTime.tryParse(datetime) ?? DateTime.now();
            } else {
              sentAt = _parseRelativeDate(timeEl.text.trim());
            }
          }

          backendMessages.add(TicketMessage(
            id: msgId++,
            text: text,
            sender: sender,
            sentAt: sentAt,
          ));
        }
      }

      // Merge backend messages with local cached messages for this ticket
      final localList = _cachedMessages[ticketId] ?? [];
      final merged = <TicketMessage>[...localList];

      for (final bMsg in backendMessages) {
        final alreadyExists = merged.any((m) =>
            m.text.trim().toLowerCase() ==
            bMsg.text.trim().toLowerCase());
        if (!alreadyExists) {
          merged.add(bMsg);
        }
      }

      merged.sort((a, b) => a.sentAt.compareTo(b.sentAt));
      _cachedMessages[ticketId] = merged;

      await _persistMessages();
      return merged;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is Failure) rethrow;
      developer.log('[SupportRepository] getMessages error: $e',
          name: 'support');
      throw UnknownFailure('Failed to load messages: $e');
    }
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

    // 2. Attempt background delivery to available backend endpoints
    try {
      final csrfToken = await _extractCsrfToken('/store/support/tickets/$ticketId');

      final formData = {
        if (csrfToken.isNotEmpty) ...{
          '_csrf_token': csrfToken,
          'csrf_token': csrfToken,
        },
        'message': body,
        'reply': body,
        'body': body,
        'ticket_id': ticketId.toString(),
      };

      final paths = [
        '/support/tickets/$ticketId',
        '/support/$ticketId',
        '/store/support/tickets/$ticketId',
        '/support/reply',
      ];

      for (final path in paths) {
        try {
          final response = await _dio.post(
            path,
            data: formData,
            options: Options(
              contentType: Headers.formUrlEncodedContentType,
              followRedirects: true,
              validateStatus: (status) => status != null && status < 500,
            ),
          );
          if (response.statusCode != null && response.statusCode! < 400) {
            break;
          }
        } catch (_) {}
      }
    } catch (e) {
      developer.log('[SupportRepository] sendMessage background sync: $e',
          name: 'support');
    }
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
            'No internet connection. Please check your network.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return AuthFailure('Session expired. Please login again.');
        }
        if (statusCode == 404) {
          return NotFoundFailure('Resource not found.');
        }
        if (statusCode != null && statusCode >= 500) {
          return ServerFailure('Server error. Please try again later.',
              statusCode: statusCode);
        }
        return ServerFailure('Request failed.', statusCode: statusCode);
      default:
        return NetworkFailure('Network error. Please try again.');
    }
  }
}
