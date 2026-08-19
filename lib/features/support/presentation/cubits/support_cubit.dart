import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/support_repository.dart';
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

  @override
  Future<void> close() {
    stopPolling();
    return super.close();
  }
}
