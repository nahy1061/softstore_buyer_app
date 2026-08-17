import 'dart:developer' as developer;

import 'package:dio/dio.dart';
import 'package:html/parser.dart' as html_parser;

import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../models/ticket_model.dart';

class SupportRepository {
  static final SupportRepository _instance = SupportRepository._internal();
  final DioClient _dio;
  final List<Ticket> _cachedTickets = [];

  factory SupportRepository({DioClient? dioClient}) {
    return _instance;
  }

  SupportRepository._internal() : _dio = DioClient();

  List<Ticket> get cachedTickets => List.unmodifiable(_cachedTickets);

  /// Extract CSRF token from an HTML page.
  Future<String> _extractCsrfToken(String pageUrl) async {
    final response = await _dio.get(
      pageUrl,
      options: Options(responseType: ResponseType.plain),
    );
    final html = response.data as String;
    final doc = html_parser.parse(html);

    // Try hidden input first
    final input = doc.querySelector('input[name="_csrf_token"]');
    if (input != null) {
      return input.attributes['value'] ?? '';
    }

    // Try meta tag
    final meta = doc.querySelector('meta[name="csrf-token"]');
    if (meta != null) {
      return meta.attributes['content'] ?? '';
    }

    // Try JS variable
    final jsMatch = RegExp(r"var\s+csrfToken\s*=\s*'([^']+)'").firstMatch(html);
    if (jsMatch != null) {
      return jsMatch.group(1)!;
    }

    throw const ServerFailure('Could not extract CSRF token');
  }

  /// Create a new support ticket via HTML form submission.
  Future<Ticket> createTicket({
    required String subject,
    required String message,
    required String category,
    int? orderId,
    String? email,
    String? guestName,
  }) async {
    try {
      // Step 1: GET the support page to extract CSRF token
      final csrfToken = await _extractCsrfToken('/support');

      // Step 2: Build form data (no category field on actual form)
      final formData = {
        '_csrf_token': csrfToken,
        'subject': subject,
        'message': message,
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

      // Step 3: POST form data - don't follow redirect, capture Location header
      final response = await _dio.post(
        '/support',
        data: FormData.fromMap(formData),
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          followRedirects: false,
          validateStatus: (status) => status != null && status < 500,
        ),
      );

      // Check for redirect (302) = success
      if (response.statusCode == 302 || response.statusCode == 301) {
        final location = response.headers.value('location') ?? '';
        // Extract ticket ID from redirect URL like /support/tickets/123
        final idMatch = RegExp(r'/support(?:/tickets)?/(\d+)').firstMatch(location);
        final ticketId = idMatch != null ? int.parse(idMatch.group(1)!) : 0;

        final ticket = Ticket(
          id: ticketId,
          subject: subject,
          category: category,
          status: TicketStatus.open,
          createdAt: DateTime.now(),
          lastUpdatedAt: DateTime.now(),
          lastMessage: message,
        );
        _cachedTickets.insert(0, ticket);
        return ticket;
      }

      // Check for error in HTML response
      if (response.statusCode == 200) {
        final html = response.data as String;
        final doc = html_parser.parse(html);

        // Look for error alerts
        final errorEl = doc.querySelector('.sx-alert-err, .alert-danger, .invalid-feedback');
        if (errorEl != null) {
          throw ServerFailure(errorEl.text.trim());
        }

        // If we got 200 but no redirect, ticket may have been created
        // Try to find ticket info in the page
        final ticketLink = doc.querySelector('a[href*="/support/tickets/"]');
        if (ticketLink != null) {
          final href = ticketLink.attributes['href'] ?? '';
          final idMatch = RegExp(r'/support(?:/tickets)?/(\d+)').firstMatch(href);
          if (idMatch != null) {
            final ticket = Ticket(
              id: int.parse(idMatch.group(1)!),
              subject: subject,
              category: category,
              status: TicketStatus.open,
              createdAt: DateTime.now(),
              lastUpdatedAt: DateTime.now(),
              lastMessage: message,
            );
            if (!_cachedTickets.any((t) => t.id == ticket.id)) {
              _cachedTickets.insert(0, ticket);
            }
            return ticket;
          }
        }
      }

      throw ServerFailure('Failed to create ticket (HTTP ${response.statusCode})');
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is Failure) rethrow;
      developer.log('[SupportRepository] createTicket error: $e', name: 'support');
      throw UnknownFailure('Failed to create ticket: $e');
    }
  }

  /// Fetch all support tickets for the current user from HTML page.
  Future<List<Ticket>> getTickets() async {
    try {
      final response = await _dio.get(
        '/support',
        options: Options(responseType: ResponseType.plain),
      );
      final html = response.data as String;
      final doc = html_parser.parse(html);
      final tickets = <Ticket>[];

      developer.log('[SupportRepository] getTickets HTML length: ${html.length}', name: 'support');

      // Look for ticket rows/links in the page
      // The authenticated view shows tickets in a table or list
      final ticketLinks = doc.querySelectorAll('a[href*="/support/tickets/"]');
      developer.log('[SupportRepository] Found ${ticketLinks.length} ticket links', name: 'support');

      for (final link in ticketLinks) {
        final href = link.attributes['href'] ?? '';
        final idMatch = RegExp(r'/support(?:/tickets)?/(\d+)').firstMatch(href);
        if (idMatch == null) continue;

        final ticketId = int.parse(idMatch.group(1)!);
        final row = link.parent;
        final cells = row?.querySelectorAll('td') ?? [];

        String subject = link.text.trim();
        String statusText = 'open';
        DateTime lastUpdated = DateTime.now();
        String lastMessage = '';

        // Try to extract from table cells
        if (cells.length >= 3) {
          subject = cells[0].text.trim().isNotEmpty ? cells[0].text.trim() : subject;
          statusText = cells[1].text.trim().toLowerCase();
          final dateText = cells[2].text.trim();
          lastMessage = cells.length > 3 ? cells[3].text.trim() : '';
          lastUpdated = _parseRelativeDate(dateText);
        }

        // Check for status badge in the row
        final badge = row?.querySelector('.sx-badge, .badge');
        if (badge != null) {
          statusText = badge.text.trim().toLowerCase();
        }

        tickets.add(Ticket(
          id: ticketId,
          subject: subject,
          category: '',
          status: _parseStatus(statusText),
          createdAt: lastUpdated,
          lastUpdatedAt: lastUpdated,
          lastMessage: lastMessage,
        ));
      }

      // Merge with cached tickets, dedup by id
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
      return merged;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is Failure) rethrow;
      developer.log('[SupportRepository] getTickets error: $e', name: 'support');
      throw UnknownFailure('Failed to load tickets: $e');
    }
  }

  /// Fetch messages for a specific ticket from HTML page.
  Future<List<TicketMessage>> getMessages(int ticketId, {DateTime? since}) async {
    try {
      final response = await _dio.get(
        '/support/tickets/$ticketId',
        options: Options(responseType: ResponseType.plain),
      );
      final html = response.data as String;
      final doc = html_parser.parse(html);
      final messages = <TicketMessage>[];

      // Look for message bubbles/elements in the chat
      // Common patterns: .message, .chat-message, .sx-card with message content
      final messageElements = doc.querySelectorAll(
        '.message, .chat-message, [class*="msg"], [class*="message"]',
      );

      int msgId = 1;
      for (final el in messageElements) {
        final text = el.text.trim();
        if (text.isEmpty) continue;

        // Determine sender from classes
        final classes = el.className.toLowerCase();
        final isAgent = classes.contains('agent') ||
            classes.contains('support') ||
            classes.contains('staff') ||
            classes.contains('reply');
        final sender = isAgent ? MessageSender.agent : MessageSender.buyer;

        // Try to extract timestamp
        final timeEl = el.querySelector('time, .time, .timestamp, [class*="time"], [class*="date"]');
        DateTime sentAt = DateTime.now();
        if (timeEl != null) {
          final datetime = timeEl.attributes['datetime'];
          if (datetime != null) {
            sentAt = DateTime.tryParse(datetime) ?? DateTime.now();
          }
        }

        messages.add(TicketMessage(
          id: msgId++,
          text: text,
          sender: sender,
          sentAt: sentAt,
        ));
      }

      // Filter by since parameter if provided
      if (since != null) {
        return messages.where((m) => m.sentAt.isAfter(since)).toList();
      }

      return messages;
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is Failure) rethrow;
      developer.log('[SupportRepository] getMessages error: $e', name: 'support');
      throw UnknownFailure('Failed to load messages: $e');
    }
  }

  /// Send a message reply to a ticket via HTML form.
  Future<void> sendMessage(int ticketId, String body) async {
    try {
      // Step 1: GET the ticket page to extract CSRF token
      final csrfToken = await _extractCsrfToken('/support/tickets/$ticketId');

      // Step 2: POST reply
      final formData = {
        '_csrf_token': csrfToken,
        'message': body,
      };

      await _dio.post(
        '/support/tickets/$ticketId',
        data: FormData.fromMap(formData),
        options: Options(
          contentType: 'application/x-www-form-urlencoded',
          followRedirects: true,
        ),
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    } catch (e) {
      if (e is Failure) rethrow;
      developer.log('[SupportRepository] sendMessage error: $e', name: 'support');
      throw UnknownFailure('Failed to send message: $e');
    }
  }

  TicketStatus _parseStatus(String text) {
    if (text.contains('open') || text.contains('new')) return TicketStatus.open;
    if (text.contains('progress') || text.contains('pending') || text.contains('waiting')) {
      return TicketStatus.inProgress;
    }
    if (text.contains('resolved') || text.contains('closed') || text.contains('done')) {
      return text.contains('closed') ? TicketStatus.closed : TicketStatus.resolved;
    }
    return TicketStatus.open;
  }

  DateTime _parseRelativeDate(String text) {
    // Try parsing relative dates like "2 hours ago", "yesterday", etc.
    final now = DateTime.now();
    if (text.contains('ago') || text.contains('just now')) return now;
    if (text.contains('yesterday')) return now.subtract(const Duration(days: 1));

    // Try standard date parsing
    return DateTime.tryParse(text) ?? now;
  }

  Failure _handleDioError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return TimeoutFailure('Connection timed out. Please try again.');
      case DioExceptionType.connectionError:
        return NetworkFailure('No internet connection. Please check your network.');
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        if (statusCode == 401) {
          return AuthFailure('Session expired. Please login again.');
        }
        if (statusCode == 404) {
          return NotFoundFailure('Resource not found.');
        }
        if (statusCode != null && statusCode >= 500) {
          return ServerFailure('Server error. Please try again later.', statusCode: statusCode);
        }
        return ServerFailure('Request failed.', statusCode: statusCode);
      default:
        return NetworkFailure('Network error. Please try again.');
    }
  }
}
