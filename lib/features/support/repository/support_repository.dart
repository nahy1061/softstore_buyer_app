import 'dart:developer' as developer;

import 'package:dio/dio.dart';

import '../../../core/constants/api_endpoints.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/utils/csrf_service.dart';
import '../../../core/utils/html_parser_util.dart';

import '../models/ticket_model.dart';

// ─── SupportRepository ────────────────────────────────────────────────────────

class SupportRepository {
  SupportRepository._();
  static final SupportRepository instance = SupportRepository._();

  final DioClient _client = DioClient();
  final CsrfService _csrf = CsrfService.instance;

  // ─── Tickets List ──────────────────────────────────────────────────────────

  /// Returns an empty list gracefully if the endpoint returns 404.
  Future<List<Ticket>> getTickets() async {
    try {
      final response = await _client.get<String>(
        ApiEndpoints.ticketsList,
        options: Options(
          responseType: ResponseType.plain,
          validateStatus: (s) => s != null && s < 500,
        ),
      );
      if (response.statusCode == 404) return [];
      return _parseTicketsList(response.data ?? '');
    } catch (e) {
      developer.log('[Support] getTickets error: $e', name: 'support');
      return [];
    }
  }

  List<Ticket> _parseTicketsList(String html) {
    final doc = HtmlParserUtil.parse(html);
    final rows = doc.querySelectorAll('.ticket-row, .ticket-item, tr[data-id]');
    final tickets = <Ticket>[];

    for (final row in rows) {
      final linkEl = row.querySelector('a[href*="/tickets/"]');
      final href = linkEl?.attributes['href'] ?? '';
      final idMatch = RegExp(r'/tickets/(\d+)').firstMatch(href);
      final id = idMatch?.group(1) ?? '';
      if (id.isEmpty) continue;

      final statusStr = row.querySelector('.status, .badge')?.text.trim().toLowerCase() ?? 'open';
      TicketStatus status = TicketStatus.open;
      if (statusStr.contains('progress')) status = TicketStatus.inProgress;
      if (statusStr.contains('resolve')) status = TicketStatus.resolved;
      if (statusStr.contains('close')) status = TicketStatus.closed;

      tickets.add(Ticket(
        id: id,
        subject: row.querySelector('.subject, td:nth-child(2)')?.text.trim() ?? '',
        category: row.querySelector('.category')?.text.trim() ?? 'General',
        status: status,
        createdAt: DateTime.now(),
        lastUpdatedAt: DateTime.now(),
        lastMessage: row.querySelector('.last-reply, .updated-at')?.text.trim() ?? '',
      ));
    }

    return tickets;
  }

  // ─── Create Ticket ─────────────────────────────────────────────────────────

  Future<void> createTicket({
    required String subject,
    required String category,
    required String message,
    String priority = 'medium',
  }) async {
    try {
      final csrfToken = await _csrf.fetchToken(ApiEndpoints.ticketsList);

      await _client.post<String>(
        ApiEndpoints.ticketsList,
        data: {
          if (csrfToken != null) '_csrf_token': csrfToken,
          'subject': subject.trim(),
          'category': category,
          'message': message.trim(),
          'priority': priority,
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

  // ─── Ticket Detail ─────────────────────────────────────────────────────────

  Future<TicketDetail> getTicketDetail(String id) async {
    try {
      final response = await _client.get<String>(
        '${ApiEndpoints.ticketDetail}$id',
        options: Options(responseType: ResponseType.plain),
      );
      return _parseTicketDetail(response.data ?? '', id);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  TicketDetail _parseTicketDetail(String html, String id) {
    final doc = HtmlParserUtil.parse(html);
    final subject =
        doc.querySelector('h1, h2, .ticket-subject')?.text.trim() ?? '';
    final status =
        doc.querySelector('.ticket-status, .badge')?.text.trim().toLowerCase() ?? 'open';

    final messageBubbles = doc.querySelectorAll(
        '.ticket-message, .message-item, .reply');
    final messages = <TicketMessage>[];

    for (final bubble in messageBubbles) {
      final isAgent = bubble.classes.contains('agent-message') ||
          bubble.classes.contains('support-message');
      final text = bubble.querySelector('p, .content, .text')?.text.trim() ??
          bubble.text.trim();
      final timestamp = bubble.querySelector('.timestamp, time')?.text.trim();

      if (text.isNotEmpty) {
        messages.add(TicketMessage(
          id: '${messages.length}',
          text: text,
          sender: isAgent ? MessageSender.agent : MessageSender.buyer,
          sentAt: DateTime.now(),
          timestamp: timestamp,
        ));
      }
    }

    return TicketDetail(
        id: id, subject: subject, status: status, messages: messages);
  }

  // ─── Reply to Ticket ───────────────────────────────────────────────────────

  Future<void> replyToTicket({
    required String id,
    required String message,
  }) async {
    try {
      final ticketPath = '${ApiEndpoints.ticketDetail}$id';
      final csrfToken = await _csrf.fetchToken(ticketPath);

      await _client.post<String>(
        ticketPath,
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
    developer.log('[Support] DioException: ${e.message}', name: 'support');
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkFailure('No internet connection.');
    }
    return ServerFailure(e.message ?? 'Server error',
        statusCode: e.response?.statusCode);
  }
}
