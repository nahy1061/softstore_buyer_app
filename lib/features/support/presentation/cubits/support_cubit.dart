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
    try {
      final tickets = await _repository.getTickets();
      emit(TicketsLoaded(tickets: tickets));
    } catch (e) {
      // If API fails, still show cached tickets
      final cached = _repository.cachedTickets;
      if (cached.isNotEmpty) {
        emit(TicketsLoaded(tickets: cached));
      } else {
        emit(SupportError(message: e.toString().replaceFirst('Exception: ', '')));
      }
    }
  }

  Future<void> loadMessages(int ticketId, {DateTime? since}) async {
    try {
      final messages = await _repository.getMessages(ticketId, since: since);
      emit(MessagesLoaded(messages: messages));
    } catch (e) {
      emit(SupportError(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  Future<void> sendMessage(int ticketId, String body) async {
    try {
      await _repository.sendMessage(ticketId, body);
      emit(const MessageSent());
    } catch (e) {
      emit(SupportError(message: e.toString().replaceFirst('Exception: ', '')));
    }
  }

  void startPolling(int ticketId, {Duration interval = const Duration(seconds: 10)}) {
    stopPolling();
    DateTime? lastMessageTime;
    final current = state;
    if (current is MessagesLoaded && current.messages.isNotEmpty) {
      lastMessageTime = current.messages.last.sentAt;
    }
    _pollTimer = Timer.periodic(interval, (_) async {
      await loadMessages(ticketId, since: lastMessageTime);
      final updated = state;
      if (updated is MessagesLoaded && updated.messages.isNotEmpty) {
        lastMessageTime = updated.messages.last.sentAt;
      }
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
