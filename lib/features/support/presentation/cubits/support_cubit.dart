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

  /// Start background polling for new replies.
  void startPolling(
    int ticketId, {
    Duration interval = const Duration(seconds: 5),
  }) {
    stopPolling();
    _pollTimer = Timer.periodic(interval, (_) async {
      if (isClosed) return;
      try {
        final messages = await _repository.getMessages(ticketId);
        if (!isClosed) {
          emit(MessagesLoaded(messages: messages));
        }
      } catch (_) {}
    });
  }

  void stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  /// Detect status change messages and update the ticket accordingly.
  /// Returns the updated ticket if a status change was detected, null otherwise.
  Ticket? detectStatusChange(List<TicketMessage> messages, Ticket currentTicket) {
    // Look for the LAST status change message from agent
    TicketStatus? detectedStatus;

    for (final msg in messages) {
      if (msg.sender != MessageSender.agent) continue;

      final text = msg.text.trim();

      // Exact patterns the backend uses for status changes
      // These are system-generated messages, not human-written
      if (text.toLowerCase().startsWith('status changed to ') ||
          text.toLowerCase().startsWith('status updated to ') ||
          text.toLowerCase() == 'ticket is now pending' ||
          text.toLowerCase() == 'ticket is now resolved' ||
          text.toLowerCase() == 'ticket is now closed' ||
          text.toLowerCase() == 'ticket is now open') {
        if (text.toLowerCase().contains('resolved')) {
          detectedStatus = TicketStatus.resolved;
        } else if (text.toLowerCase().contains('closed')) {
          detectedStatus = TicketStatus.closed;
        } else if (text.toLowerCase().contains('pending') ||
            text.toLowerCase().contains('in progress')) {
          detectedStatus = TicketStatus.inProgress;
        } else if (text.toLowerCase().contains('open')) {
          detectedStatus = TicketStatus.open;
        }
      }
    }

    if (detectedStatus != null && detectedStatus != currentTicket.status) {
      final updated = currentTicket.copyWith(
        status: detectedStatus,
        lastUpdatedAt: DateTime.now(),
      );
      return updated;
    }

    return null;
  }

  /// Check if a message is a system status change message (should not be displayed as chat bubble)
  static bool isStatusChangeMessage(TicketMessage msg) {
    if (msg.sender != MessageSender.agent) return false;
    final text = msg.text.trim().toLowerCase();
    return text.startsWith('status changed to ') ||
        text.startsWith('status updated to ') ||
        text == 'ticket is now pending' ||
        text == 'ticket is now resolved' ||
        text == 'ticket is now closed' ||
        text == 'ticket is now open';
  }

  @override
  Future<void> close() {
    stopPolling();
    return super.close();
  }
}
