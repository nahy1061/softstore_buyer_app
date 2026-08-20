import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/support_repository.dart';
import '../../models/ticket_model.dart';
import 'support_state.dart';

class SupportCubit extends Cubit<SupportState> {
  final SupportRepository _repository;
  Timer? _pollTimer;

  SupportCubit({SupportRepository? repository})
    : _repository = repository ?? SupportRepository(),
      super(const SupportInitial());

  Future<void> createTicket({
    required String subject,
    required String message,
    required String category,
    int? orderId,
    String? email,
    String? guestName,
  }) async {
    emit(const SupportLoading());
    try {
      final ticket = await _repository.createTicket(
        subject: subject,
        message: message,
        category: category,
        orderId: orderId,
        email: email,
        guestName: guestName,
      );
      emit(TicketCreated(ticket: ticket));
    } catch (e) {
      emit(SupportError(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> loadTickets() async {
    // 1. Cache-first: if we have cached tickets, emit immediately for instant 0ms load
    final cached = _repository.cachedTickets;
    if (cached.isNotEmpty) {
      emit(TicketsLoaded(tickets: cached));
    } else {
      emit(const SupportLoading());
    }

    // 2. Refresh from backend in the background
    try {
      final tickets = await _repository.getTickets();
      if (!isClosed) {
        emit(TicketsLoaded(tickets: tickets));
      }
    } catch (e) {
      if (!isClosed && state is! TicketsLoaded) {
        final fallback = _repository.cachedTickets;
        if (fallback.isNotEmpty) {
          emit(TicketsLoaded(tickets: fallback));
        } else {
          emit(
            SupportError(message: e.toString().replaceFirst('Exception: ', '')),
          );
        }
      }
    }
  }

  Future<void> loadMessages(int ticketId) async {
    try {
      final messages = await _repository.getMessages(ticketId);
      if (!isClosed) {
        emit(MessagesLoaded(messages: messages));

        // Immediately sync ticket status with the latest verified status from backend
        final statusFromMsg = extractStatusFromMessages(messages);
        final currentCached = _repository.cachedTickets;
        final match = currentCached.where((t) => t.id == ticketId).firstOrNull;
        if (statusFromMsg != null && match != null && match.status != statusFromMsg) {
          final updated = match.copyWith(status: statusFromMsg);
          emit(TicketStatusUpdated(ticket: updated));
        } else if (match != null) {
          emit(TicketStatusUpdated(ticket: match));
        }
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          SupportError(message: e.toString().replaceFirst('Exception: ', '')),
        );
      }
    }
  }

  Future<void> sendMessage(int ticketId, String body) async {
    try {
      await _repository.sendMessage(ticketId, body);
      if (!isClosed) {
        emit(const MessageSent());
      }
    } catch (e) {
      if (!isClosed) {
        emit(
          SupportError(message: e.toString().replaceFirst('Exception: ', '')),
        );
      }
    }
  }

  /// Start background polling for new replies and status changes.
  void startPolling(
    int ticketId, {
    Duration interval = const Duration(seconds: 3),
  }) {
    stopPolling();
    _pollTimer = Timer.periodic(interval, (_) async {
      if (isClosed) return;
      try {
        // Poll messages and sync status immediately
        final messages = await _repository.getMessages(ticketId);
        if (!isClosed) {
          emit(MessagesLoaded(messages: messages));

          final statusFromMsg = extractStatusFromMessages(messages);
          final currentCached = _repository.cachedTickets;
          final match = currentCached.where((t) => t.id == ticketId).firstOrNull;
          if (statusFromMsg != null && match != null && match.status != statusFromMsg) {
            final updatedTicket = match.copyWith(status: statusFromMsg);
            emit(TicketStatusUpdated(ticket: updatedTicket));
          } else if (match != null) {
            emit(TicketStatusUpdated(ticket: match));
          }
        }
      } catch (_) {}

      try {
        // Check ticket detail status directly
        final updated = await loadTicketStatus(ticketId);
        if (!isClosed && updated != null) {
          emit(TicketStatusUpdated(ticket: updated));
        }
      } catch (_) {}
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Fetch updated ticket status from backend.
  /// First checks the ticket detail page directly, then falls back to ticket list.
  Future<Ticket?> loadTicketStatus(int ticketId) async {
    try {
      // 1. Direct ticket status check from ticket detail page
      final directStatus = await _repository.getTicketStatus(ticketId);
      if (directStatus != null) {
        final cached = _repository.cachedTickets.where((t) => t.id == ticketId).firstOrNull;
        if (cached != null) {
          return cached.copyWith(status: directStatus);
        }
      }

      // 2. Ticket list check
      final tickets = await _repository.getTickets();
      for (final t in tickets) {
        if (t.id == ticketId) return t;
      }
    } catch (_) {}
    return null;
  }

  /// Check if any message in the list indicates a status change.
  /// Looks through latest messages in reverse order to find the latest valid status.
  static TicketStatus? extractStatusFromMessages(List<TicketMessage> messages) {
    for (final msg in messages.reversed) {
      if (msg.sender != MessageSender.agent) continue;
      final text = msg.text.trim().toLowerCase();
      if (!isStatusChangeMessage(msg)) continue;

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

  /// Check if a message is a system status change message (should not be displayed as regular chat bubble)
  static bool isStatusChangeMessage(TicketMessage msg) {
    if (msg.sender != MessageSender.agent) return false;
    final text = msg.text.trim().toLowerCase();
    
    // Status change notices are concise system messages
    if (text.length > 120) return false;

    // Direct startsWith checks
    if (text.startsWith('status changed') ||
        text.startsWith('status updated') ||
        text.startsWith('status has been') ||
        text.startsWith('status is now') ||
        text.startsWith('ticket status') ||
        text.startsWith('ticket is now') ||
        text.startsWith('ticket has been') ||
        text.startsWith('ticket marked as') ||
        text.startsWith('changed status to') ||
        text.startsWith('marked as') ||
        text.startsWith('status:')) {
      return true;
    }

    // Keyword & Regex matching for dynamic backend system strings
    final statusKeywords = RegExp(
      r'(?:status\s+(?:is\s+)?(?:changed|updated|set|marked|moved)|(?:changed|updated|marked|set)\s+(?:the\s+)?status)\s+(?:to|as)?\s*(?:open|pending|in[ -_]?progress|waiting|resolved|closed)',
      caseSensitive: false,
    );
    if (statusKeywords.hasMatch(text)) return true;

    // Short status assertions like "Ticket resolved" or "Ticket closed"
    final shortStatusAssertion = RegExp(
      r'^(?:ticket\s+)?(?:status\s+)?(?:is\s+)?(?:resolved|closed|reopened|pending|in[ -_]?progress)[\.!]?$',
      caseSensitive: false,
    );
    if (shortStatusAssertion.hasMatch(text)) return true;

    return false;
  }

  @override
  Future<void> close() {
    stopPolling();
    return super.close();
  }
}
