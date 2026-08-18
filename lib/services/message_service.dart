import '../core/networking/web_session_client.dart';
import '../core/networking/api_error.dart';

// ---------------------------------------------------------------------------
// Data classes
// ---------------------------------------------------------------------------

class ConversationThread {
  final String conversationPath;
  final String storeName;
  final String lastMessage;
  final String date;
  final bool hasUnread;

  const ConversationThread({
    required this.conversationPath,
    required this.storeName,
    required this.lastMessage,
    required this.date,
    this.hasUnread = false,
  });

  String get conversationId {
    final m = RegExp(r'/messages/(\d+)').firstMatch(conversationPath);
    return m?.group(1) ?? '';
  }
}

class ChatMessage {
  /// 'buyer' or 'seller'
  final String senderType;
  final String senderName;
  final String body;
  final String createdAt;

  const ChatMessage({
    required this.senderType,
    required this.senderName,
    required this.body,
    required this.createdAt,
  });
}

class SupportTicket {
  final String id;
  final String subject;
  final String status;
  final String? lastMessage;
  final String? updatedAt;

  const SupportTicket({
    required this.id,
    required this.subject,
    required this.status,
    this.lastMessage,
    this.updatedAt,
  });
}

// ---------------------------------------------------------------------------
// Service
// ---------------------------------------------------------------------------

class MessageService {
  final _web = WebSessionClient.shared;

  // ─── Store conversations ─────────────────────────────────────────────────

  /// Fetch the buyer's conversation inbox from /messages.
  Future<List<ConversationThread>> fetchInbox() async {
    final html = await _web.fetchHtml('/messages');
    return _parseInbox(html);
  }

  /// Fetch messages in a specific conversation thread.
  Future<List<ChatMessage>> fetchThread(String conversationPath) async {
    final html = await _web.fetchHtml(conversationPath);
    return _parseThread(html);
  }

  /// Post a reply to an existing conversation.
  Future<void> reply(String conversationId, String message) async {
    final pageHtml = await _web.fetchHtml('/messages/$conversationId');
    final csrf = _web.scrapeCSRF(pageHtml);
    if (csrf == null) throw ApiError('Could not read security token.');
    await _web.postJson<Map<String, dynamic>>(
      '/messages/$conversationId/reply',
      {'message': message, '_csrf_token': csrf},
      (j) => j,
      csrfToken: csrf,
    );
  }

  /// Start a new conversation from a product page or return the path of an
  /// existing conversation for that product.
  Future<String> startConversation(int productId) async {
    final (:html, :finalUrl) = await _web.fetchHtmlWithFinalUrl(
        '/messages/new?product_id=$productId');
    final uri = Uri.parse(finalUrl);
    if (uri.path.startsWith('/messages/') && uri.path != '/messages/new') {
      return uri.path;
    }
    final m = RegExp(r'href="(/messages/\d+)"').firstMatch(html);
    if (m != null) return m.group(1)!;
    throw ApiError('Could not start conversation. Please try again.');
  }

  // ─── Support tickets ─────────────────────────────────────────────────────

  /// Fetch support ticket list from /marketplace/account/support.
  Future<List<SupportTicket>> tickets() async {
    final html = await _web.fetchHtml('/marketplace/account/support');
    return _parseTickets(html);
  }

  /// Fetch messages in a support ticket.
  Future<List<ChatMessage>> ticketMessages(String ticketId) async {
    final html = await _web.fetchHtml('/marketplace/account/support/$ticketId');
    return _parseThread(html);
  }

  /// Create a new support ticket.
  Future<SupportTicket> createTicket(String subject, String message) async {
    final csrf = await _web.fetchCsrf('/marketplace/account/support/new');
    final (:html, :finalUrl) = await _web.postForm(
      '/marketplace/account/support',
      {'_csrf_token': csrf, 'subject': subject, 'message': message},
    );
    final err = _scrapeError(html);
    if (err != null) throw ApiError(err);
    // Extract the newly created ticket id from the redirect URL or HTML
    final ticketIdM = RegExp(r'/support/(\d+)').firstMatch(finalUrl)
        ?? RegExp(r'/support/(\d+)').firstMatch(html);
    return SupportTicket(
      id: ticketIdM?.group(1) ?? '0',
      subject: subject,
      status: 'open',
    );
  }

  /// Reply to a support ticket.
  Future<void> ticketReply(String ticketId, String message) async {
    final csrf =
        await _web.fetchCsrf('/marketplace/account/support/$ticketId');
    final (:html, :finalUrl) = await _web.postForm(
      '/marketplace/account/support/$ticketId/reply',
      {'_csrf_token': csrf, 'message': message},
    );
    final err = _scrapeError(html);
    if (err != null) throw ApiError(err);
  }

  // ─── HTML parsers ─────────────────────────────────────────────────────────

  List<ConversationThread> _parseInbox(String html) {
    final results = <ConversationThread>[];
    final seen = <String>{};

    for (final m in RegExp(
      r'href="(/messages/(\d+))"([^>]*>[\s\S]{0,1500}?)'
      r'(?=href="/messages/\d+"|</ul>|</div>|<footer|$)',
      dotAll: true,
    ).allMatches(html)) {
      final path = m.group(1)!;
      if (seen.contains(path)) continue;
      seen.add(path);

      final card = m.group(3) ?? '';
      final hasUnread =
          card.contains('unread') || card.contains('fw-bold') || card.contains('badge');

      final storeName = _extractText(
            card,
            [
              r'(?:fw-bold|fw-semibold|store-name)[^>]*>\s*([^<]{2,80})<',
              r'<strong[^>]*>([^<]{2,60})<',
            ],
          ) ??
          'Store';

      final lastMsg = _extractText(
            card,
            [
              r'text-muted[^>]*>\s*([^<]{3,200})',
              r'<p[^>]*>\s*([^<]{3,200})',
            ],
          ) ??
          '';

      final date = RegExp(
                  r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}|\d+\s*(?:hour|min|day|week)s?\s*ago)',
                )
                .firstMatch(card)
                ?.group(1) ??
            '';

      results.add(ConversationThread(
        conversationPath: path,
        storeName: storeName.trim(),
        lastMessage: lastMsg.trim(),
        date: date,
        hasUnread: hasUnread,
      ));
    }
    return results;
  }

  List<ChatMessage> _parseThread(String html) {
    final results = <ChatMessage>[];

    // Try structured message bubbles
    final blockPattern = RegExp(
      r'<(?:div|li)[^>]*class="[^"]*(?:message|chat-bubble|bubble)[^"]*"[^>]*>'
      r'([\s\S]{0,1200}?)</(?:div|li)>',
      dotAll: true,
    );

    for (final m in blockPattern.allMatches(html)) {
      final block = m.group(1) ?? '';
      if (block.trim().isEmpty) continue;

      final lower = block.toLowerCase();
      final isBuyer = lower.contains('ms-auto') ||
          lower.contains('justify-content-end') ||
          lower.contains(' sent') ||
          lower.contains('buyer') ||
          lower.contains(' right');

      final senderType = isBuyer ? 'buyer' : 'seller';
      final senderName = _extractText(
            block,
            [
              r'(?:fw-bold|sender-name)[^>]*>\s*([^<]{2,60})<',
              r'<strong[^>]*>([^<]{2,60})<',
            ],
          ) ??
          (isBuyer ? 'You' : 'Store');

      final body = _extractText(
            block,
            [
              r'(?:message-body|message-text)[^>]*>\s*([^<]{1,500})',
              r'<p[^>]*>\s*([^<]{1,500})<',
            ],
          ) ??
          block.stripHtmlTags().trim();

      final createdAt =
          RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4}[^<]{0,10}|\d{1,2}:\d{2})')
              .firstMatch(block)
              ?.group(1) ??
          '';

      if (body.length >= 1) {
        results.add(ChatMessage(
          senderType: senderType,
          senderName: senderName.trim(),
          body: body.trim(),
          createdAt: createdAt,
        ));
      }
    }

    // Fallback: look for any paragraph content
    if (results.isEmpty) {
      for (final m in RegExp(
              r'<(?:p|div)[^>]*class="[^"]*(?:msg|message|text)[^"]*"[^>]*>'
              r'\s*([^<]{3,500}?)\s*<',
              dotAll: true)
          .allMatches(html)) {
        final body = (m.group(1) ?? '').trim();
        if (body.isNotEmpty) {
          results.add(ChatMessage(
            senderType: 'seller',
            senderName: 'Store',
            body: body,
            createdAt: '',
          ));
        }
      }
    }

    return results;
  }

  List<SupportTicket> _parseTickets(String html) {
    final tickets = <SupportTicket>[];
    final seen = <String>{};

    for (final m in RegExp(
      r'href="/marketplace/account/support/(\d+)"([^>]*>[\s\S]{0,800}?)'
      r'(?=href="/marketplace/account/support/\d+"|</ul>|</table>|$)',
      dotAll: true,
    ).allMatches(html)) {
      final id = m.group(1) ?? '';
      if (id.isEmpty || seen.contains(id)) continue;
      seen.add(id);

      final card = m.group(2) ?? '';
      final subject = _extractText(
            card,
            [
              r'fw-bold[^>]*>\s*([^<]{2,120})<',
              r'<strong[^>]*>([^<]{2,120})<',
              r'<td[^>]*>([^<]{2,120})<',
            ],
          ) ??
          'Ticket #$id';

      final status = RegExp(r'badge[^>]*>\s*([A-Za-z]+)\s*<')
              .firstMatch(card)
              ?.group(1)
              ?.toLowerCase() ??
          'open';
      final lastMsg =
          RegExp(r'text-muted[^>]*>\s*([^<]{3,200})').firstMatch(card)?.group(1);
      final updatedAt =
          RegExp(r'(\d{1,2}[/-]\d{1,2}[/-]\d{2,4})').firstMatch(card)?.group(1);

      tickets.add(SupportTicket(
        id: id,
        subject: subject.trim(),
        status: status,
        lastMessage: lastMsg?.trim(),
        updatedAt: updatedAt,
      ));
    }
    return tickets;
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String? _extractText(String html, List<String> patterns) {
    for (final pattern in patterns) {
      final m = RegExp(pattern, dotAll: true).firstMatch(html);
      if (m != null) {
        final text = m.group(1)?.stripHtmlTags().decodeHtmlEntities().trim();
        if (text != null && text.isNotEmpty) return text;
      }
    }
    return null;
  }

  String? _scrapeError(String html) =>
      RegExp(r'alert[^>]*danger[^>]*>.*?<span>([^<]{5,200})</span>',
              dotAll: true)
          .firstMatch(html)
          ?.group(1) ??
      RegExp(r'alert-danger[^>]*>\s*([^<]{5,200}?)\s*<').firstMatch(html)?.group(1);
}

extension _StrExt on String {
  String stripHtmlTags() => replaceAll(RegExp(r'<[^>]+>'), '');
  String decodeHtmlEntities() => replaceAll('&amp;', '&')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&quot;', '"')
      .replaceAll('&#39;', "'")
      .replaceAll('&nbsp;', ' ');
}
