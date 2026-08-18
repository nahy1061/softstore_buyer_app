import 'support_category.dart';

/// Payload shape for POST /api/buyer/support/tickets.
class SupportTicketSubmitData {
  final String subject;
  final String message;
  final String categoryApiValue;
  final int? orderId;

  const SupportTicketSubmitData({
    required this.subject,
    required this.message,
    required this.categoryApiValue,
    this.orderId,
  });

  factory SupportTicketSubmitData.fromForm({
    required String subject,
    required String message,
    String? categoryLabel,
    int? orderId,
  }) {
    final apiCategory = (categoryLabel != null ? supportCategoryApiValue(categoryLabel) : null) ??
        (orderId != null ? 'order' : 'general');
    return SupportTicketSubmitData(
      subject: subject.trim(),
      message: message.trim(),
      categoryApiValue: apiCategory,
      orderId: orderId,
    );
  }

  Map<String, dynamic> toApiJson() => {
        'subject': subject,
        'message': message,
        'category': categoryApiValue,
        if (orderId != null) 'order_id': orderId,
      };
}

/// Validates optional order reference input (invoice format or numeric id).
String? validateOrderReference(String? value) {
  if (value == null || value.trim().isEmpty) return null;

  final trimmed = value.trim().toUpperCase();
  if (RegExp(r'^\d+$').hasMatch(trimmed)) return null;
  if (RegExp(r'^SS-\d{8}-\d+$').hasMatch(trimmed)) return null;

  return 'Enter a valid order number (e.g. SS-20240801-0042)';
}

/// Parses a numeric order id from user input when provided as digits only.
int? parseNumericOrderId(String? raw) {
  if (raw == null || raw.trim().isEmpty) return null;
  final value = raw.trim();
  if (!RegExp(r'^\d+$').hasMatch(value)) return null;
  return int.tryParse(value);
}

String formatTicketDisplayId(int ticketId) => '#$ticketId';
