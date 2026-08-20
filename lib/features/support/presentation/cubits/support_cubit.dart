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
    Duration interval = const Duration(seconds: 5),
  }) {
    stopPolling();
    _pollTimer = Timer.periodic(interval, (_) async {
      if (isClosed) return;
      try {
        // Poll messages
        final messages = await _repository.getMessages(ticketId);
        if (!isClosed) {
          emit(MessagesLoaded(messages: messages));
        }
      } catch (_) {}
      try {
        // Also refresh ticket status from backend
        final updated = await loadTicketStatus(ticketId);
        if (!isClosed && updated != null && state is TicketsLoaded) {
          final currentTickets = (state as TicketsLoaded).tickets;
          final refreshed = currentTickets.map((t) => t.id == ticketId ? updated : t).toList();
          emit(TicketsLoaded(tickets: refreshed));
        }
      } catch (_) {}
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Fetch updated ticket status from backend.
  /// Returns the ticket with current status, or null if not found.
  Future<Ticket?> loadTicketStatus(int ticketId) async {
    try {
      final tickets = await _repository.getTickets();
      for (final t in tickets) {
        if (t.id == ticketId) return t;
      }
    } catch (_) {}
    return null;
  }

  /// Check if a message is a system status change message (should not be displayed as chat bubble)
  static bool isStatusChangeMessage(TicketMessage msg) {
    if (msg.sender != MessageSender.agent) return false;
    final text = msg.text.trim().toLowerCase();
    // System status messages are typically short and start with status-related keywords
    if (text.length > 80) return false; // Real agent replies are usually longer
    return text.startsWith('status changed') ||
        text.startsWith('status updated') ||
        text.startsWith('ticket is now') ||
        text.startsWith('ticket status') ||
        (text.contains('status') && text.contains('to') && text.length < 50);
  }

  @override
  Future<void> close() {
    stopPolling();
    return super.close();
  }
}
