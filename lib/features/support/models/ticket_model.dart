enum TicketStatus { open, inProgress, resolved, closed }

class Ticket {
  final String id;
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
}

final List<Ticket> kMockTickets = [
  Ticket(
    id: 'SS-20260810-003',
    subject: 'Order not delivered after 7 days',
    category: 'Delivery problem',
    status: TicketStatus.inProgress,
    createdAt: DateTime(2026, 8, 10, 14, 30),
    lastUpdatedAt: DateTime(2026, 8, 11, 9, 15),
    lastMessage: 'We are checking with the courier. Will update you shortly.',
  ),
  Ticket(
    id: 'SS-20260809-007',
    subject: 'Wrong item received',
    category: 'Return & refund',
    status: TicketStatus.open,
    createdAt: DateTime(2026, 8, 9, 11, 0),
    lastUpdatedAt: DateTime(2026, 8, 9, 11, 0),
    lastMessage: 'I received a blue shirt instead of the red one I ordered.',
  ),
  Ticket(
    id: 'SS-20260805-012',
    subject: 'Payment deducted but order failed',
    category: 'Payment issue',
    status: TicketStatus.resolved,
    createdAt: DateTime(2026, 8, 5, 16, 45),
    lastUpdatedAt: DateTime(2026, 8, 7, 10, 0),
    lastMessage: 'Refund of PKR 2,500 has been processed to your account.',
  ),
  Ticket(
    id: 'SS-20260801-001',
    subject: 'How to change my delivery address',
    category: 'Order issue',
    status: TicketStatus.closed,
    createdAt: DateTime(2026, 8, 1, 9, 20),
    lastUpdatedAt: DateTime(2026, 8, 2, 14, 30),
    lastMessage: 'Glad we could help! Ticket closed.',
  ),
];
