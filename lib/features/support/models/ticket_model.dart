enum TicketStatus { open, inProgress, resolved, closed }

enum MessageSender { buyer, agent }

class TicketMessage {
  final int id;
  final String text;
  final MessageSender sender;
  final DateTime sentAt;

  const TicketMessage({
    required this.id,
    required this.text,
    required this.sender,
    required this.sentAt,
  });

  factory TicketMessage.fromJson(Map<String, dynamic> json) {
    return TicketMessage(
      id: json['id'] as int,
      text: (json['body'] ?? json['text'] ?? '') as String,
      sender: messageSenderFromString(json['sender'] as String? ?? 'buyer'),
      sentAt: DateTime.parse(json['created_at'] as String? ?? json['sent_at'] as String? ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'body': text,
        'sender': sender.name,
        'created_at': sentAt.toIso8601String(),
      };
}

final Map<int, List<TicketMessage>> kMockMessages = {
  1003: [
    TicketMessage(
      id: 1,
      text: 'Hi, my order SS-20260810-003 was supposed to arrive 3 days ago but I still haven\'t received it.',
      sender: MessageSender.buyer,
      sentAt: DateTime(2026, 8, 10, 14, 30),
    ),
    TicketMessage(
      id: 2,
      text: 'Hello! Thank you for reaching out. We apologize for the delay. Could you please confirm your delivery address?',
      sender: MessageSender.agent,
      sentAt: DateTime(2026, 8, 10, 15, 5),
    ),
    TicketMessage(
      id: 3,
      text: 'Yes, it\'s House 12, Street 4, Rawalpindi.',
      sender: MessageSender.buyer,
      sentAt: DateTime(2026, 8, 10, 15, 20),
    ),
    TicketMessage(
      id: 4,
      text: 'We are checking with the courier. Will update you shortly.',
      sender: MessageSender.agent,
      sentAt: DateTime(2026, 8, 11, 9, 15),
    ),
  ],
  1007: [
    TicketMessage(
      id: 1,
      text: 'I received a blue shirt instead of the red one I ordered. Order #SS-20260809-007.',
      sender: MessageSender.buyer,
      sentAt: DateTime(2026, 8, 9, 11, 0),
    ),
  ],
  1012: [
    TicketMessage(
      id: 1,
      text: 'My payment of PKR 2,500 was deducted but my order shows as failed.',
      sender: MessageSender.buyer,
      sentAt: DateTime(2026, 8, 5, 16, 45),
    ),
    TicketMessage(
      id: 2,
      text: 'We have verified the transaction. A refund has been initiated to your account.',
      sender: MessageSender.agent,
      sentAt: DateTime(2026, 8, 6, 10, 0),
    ),
    TicketMessage(
      id: 3,
      text: 'Refund of PKR 2,500 has been processed to your account.',
      sender: MessageSender.agent,
      sentAt: DateTime(2026, 8, 7, 10, 0),
    ),
  ],
  1001: [
    TicketMessage(
      id: 1,
      text: 'How can I change my delivery address after placing an order?',
      sender: MessageSender.buyer,
      sentAt: DateTime(2026, 8, 1, 9, 20),
    ),
    TicketMessage(
      id: 2,
      text: 'You can update your delivery address from Profile → Addresses before the order is shipped.',
      sender: MessageSender.agent,
      sentAt: DateTime(2026, 8, 2, 9, 0),
    ),
    TicketMessage(
      id: 3,
      text: 'Perfect, thank you!',
      sender: MessageSender.buyer,
      sentAt: DateTime(2026, 8, 2, 14, 0),
    ),
    TicketMessage(
      id: 4,
      text: 'Glad we could help! Ticket closed.',
      sender: MessageSender.agent,
      sentAt: DateTime(2026, 8, 2, 14, 30),
    ),
  ],
};

class Ticket {
  final int id;
  final String subject;
  final String category;
  final TicketStatus status;
  final DateTime createdAt;
  final DateTime lastUpdatedAt;
  final String lastMessage;

  const Ticket({
    required this.id,
    required this.subject,
    required this.category,
    required this.status,
    required this.createdAt,
    required this.lastUpdatedAt,
    required this.lastMessage,
  });

  String get displayId => '#$id';

  factory Ticket.fromJson(Map<String, dynamic> json) {
    return Ticket(
      id: json['id'] as int,
      subject: json['subject'] as String? ?? '',
      category: json['category'] as String? ?? 'general',
      status: ticketStatusFromString(json['status'] as String? ?? 'open'),
      createdAt: DateTime.parse(json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      lastUpdatedAt: DateTime.parse(json['last_message_at'] as String? ?? json['created_at'] as String? ?? DateTime.now().toIso8601String()),
      lastMessage: json['last_message'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subject': subject,
        'category': category,
        'status': status.name,
        'created_at': createdAt.toIso8601String(),
        'last_message_at': lastUpdatedAt.toIso8601String(),
        'last_message': lastMessage,
      };
}

final List<Ticket> kMockTickets = [
  Ticket(
    id: 1003,
    subject: 'Order not delivered after 7 days',
    category: 'Delivery problem',
    status: TicketStatus.inProgress,
    createdAt: DateTime(2026, 8, 10, 14, 30),
    lastUpdatedAt: DateTime(2026, 8, 11, 9, 15),
    lastMessage: 'We are checking with the courier. Will update you shortly.',
  ),
  Ticket(
    id: 1007,
    subject: 'Wrong item received',
    category: 'Return & refund',
    status: TicketStatus.open,
    createdAt: DateTime(2026, 8, 9, 11, 0),
    lastUpdatedAt: DateTime(2026, 8, 9, 11, 0),
    lastMessage: 'I received a blue shirt instead of the red one I ordered.',
  ),
  Ticket(
    id: 1012,
    subject: 'Payment deducted but order failed',
    category: 'Payment issue',
    status: TicketStatus.resolved,
    createdAt: DateTime(2026, 8, 5, 16, 45),
    lastUpdatedAt: DateTime(2026, 8, 7, 10, 0),
    lastMessage: 'Refund of PKR 2,500 has been processed to your account.',
  ),
  Ticket(
    id: 1001,
    subject: 'How to change my delivery address',
    category: 'Order issue',
    status: TicketStatus.closed,
    createdAt: DateTime(2026, 8, 1, 9, 20),
    lastUpdatedAt: DateTime(2026, 8, 2, 14, 30),
    lastMessage: 'Glad we could help! Ticket closed.',
  ),
];

TicketStatus ticketStatusFromString(String value) {
  switch (value) {
    case 'open':
      return TicketStatus.open;
    case 'waiting':
    case 'in_progress':
    case 'in-progress':
      return TicketStatus.inProgress;
    case 'resolved':
      return TicketStatus.resolved;
    case 'closed':
      return TicketStatus.closed;
    default:
      return TicketStatus.open;
  }
}

MessageSender messageSenderFromString(String value) {
  switch (value) {
    case 'agent':
    case 'support':
    case 'admin':
      return MessageSender.agent;
    case 'buyer':
    case 'user':
    default:
      return MessageSender.buyer;
  }
}
