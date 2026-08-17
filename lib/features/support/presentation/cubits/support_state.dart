import 'package:equatable/equatable.dart';

import '../../models/ticket_model.dart';

abstract class SupportState extends Equatable {
  const SupportState();

  @override
  List<Object?> get props => [];
}

class SupportInitial extends SupportState {
  const SupportInitial();
}

class SupportLoading extends SupportState {
  const SupportLoading();
}

class TicketCreated extends SupportState {
  final Ticket ticket;

  const TicketCreated({required this.ticket});

  @override
  List<Object?> get props => [ticket];
}

class TicketsLoaded extends SupportState {
  final List<Ticket> tickets;

  const TicketsLoaded({required this.tickets});

  @override
  List<Object?> get props => [tickets];
}

class MessagesLoaded extends SupportState {
  final List<TicketMessage> messages;

  const MessagesLoaded({required this.messages});

  @override
  List<Object?> get props => [messages];
}

class MessageSent extends SupportState {
  const MessageSent();
}

class SupportError extends SupportState {
  final String message;

  const SupportError({required this.message});

  @override
  List<Object?> get props => [message];
}
