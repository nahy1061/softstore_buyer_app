import 'package:flutter_test/flutter_test.dart';
import 'package:softstore_buyer_app/features/support/models/faq_model.dart';
import 'package:softstore_buyer_app/features/support/models/support_category.dart';
import 'package:softstore_buyer_app/features/support/models/support_ticket_form.dart';
import 'package:softstore_buyer_app/features/support/models/ticket_model.dart';
import 'package:softstore_buyer_app/features/support/presentation/cubits/support_cubit.dart';
import 'package:softstore_buyer_app/features/support/presentation/cubits/support_state.dart';
import 'package:softstore_buyer_app/features/support/presentation/widgets/ticket_status_badge.dart';

void main() {
  group('FAQ Model Tests', () {
    test('kFaqData contains categories and items', () {
      expect(kFaqData.isNotEmpty, isTrue);
      expect(kFaqData.first.title, 'Orders & Delivery');
      expect(kFaqData.first.items.isNotEmpty, isTrue);
      expect(kFaqData.first.items.first.question.isNotEmpty, isTrue);
    });
  });

  group('Support Category Tests', () {
    test('supportCategoryApiValue maps labels to api values', () {
      expect(supportCategoryApiValue('Order issue'), 'order');
      expect(supportCategoryApiValue('Account problem'), 'general');
      expect(supportCategoryApiValue('Unknown Label'), isNull);
      expect(supportCategoryApiValue(null), isNull);
    });

    test(
      'getSupportCategoryIcon returns an icon for known and unknown categories',
      () {
        expect(getSupportCategoryIcon('Order issue'), isNotNull);
        expect(getSupportCategoryIcon('Nonexistent'), isNotNull);
      },
    );
  });

  group('Support Ticket Form & Validation Tests', () {
    test('validateOrderReference validates correctly', () {
      expect(validateOrderReference(null), isNull);
      expect(validateOrderReference(''), isNull);
      expect(validateOrderReference('   '), isNull);
      expect(validateOrderReference('12345'), isNull);
      expect(validateOrderReference('SS-20240801-0042'), isNull);
      expect(validateOrderReference('invalid-order-format'), isNotNull);
    });

    test('parseNumericOrderId parses numeric strings only', () {
      expect(parseNumericOrderId('12345'), 12345);
      expect(parseNumericOrderId('SS-20240801-0042'), isNull);
      expect(parseNumericOrderId(null), isNull);
      expect(parseNumericOrderId(''), isNull);
    });

    test('SupportTicketSubmitData creates valid payload', () {
      final data = SupportTicketSubmitData.fromForm(
        subject: ' Broken item ',
        message: ' The item arrived broken. ',
        categoryLabel: 'Order issue',
        orderId: 101,
      );

      expect(data.subject, 'Broken item');
      expect(data.message, 'The item arrived broken.');
      expect(data.categoryApiValue, 'order');
      expect(data.orderId, 101);

      final json = data.toApiJson();
      expect(json['subject'], 'Broken item');
      expect(json['message'], 'The item arrived broken.');
      expect(json['category'], 'order');
      expect(json['order_id'], 101);
    });
  });

  group('Ticket Model & Status Tests', () {
    test('ticketStatusFromString parses all expected status values', () {
      expect(ticketStatusFromString('open'), TicketStatus.open);
      expect(ticketStatusFromString('in_progress'), TicketStatus.inProgress);
      expect(ticketStatusFromString('waiting'), TicketStatus.inProgress);
      expect(ticketStatusFromString('resolved'), TicketStatus.resolved);
      expect(ticketStatusFromString('closed'), TicketStatus.closed);
      expect(ticketStatusFromString('other'), TicketStatus.open);
    });

    test('messageSenderFromString parses senders', () {
      expect(messageSenderFromString('agent'), MessageSender.agent);
      expect(messageSenderFromString('admin'), MessageSender.agent);
      expect(messageSenderFromString('buyer'), MessageSender.buyer);
      expect(messageSenderFromString('user'), MessageSender.buyer);
    });

    test('TicketStatusBadge helper labels and colors', () {
      expect(TicketStatusBadge.statusLabel(TicketStatus.open), 'Open');
      expect(
        TicketStatusBadge.statusLabel(TicketStatus.inProgress),
        'In Progress',
      );
      expect(TicketStatusBadge.statusLabel(TicketStatus.resolved), 'Resolved');
      expect(TicketStatusBadge.statusLabel(TicketStatus.closed), 'Closed');
    });
  });

  group('Support Cubit Tests', () {
    test('Initial state is SupportInitial', () {
      final cubit = SupportCubit();
      expect(cubit.state, isA<SupportInitial>());
      cubit.close();
    });
  });
}
