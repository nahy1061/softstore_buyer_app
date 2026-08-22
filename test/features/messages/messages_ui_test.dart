import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:softstore_buyer_app/features/messages/models/chat_message_model.dart';
import 'package:softstore_buyer_app/features/messages/models/conversation_model.dart';
import 'package:softstore_buyer_app/features/messages/presentation/widgets/chat_bubble.dart';
import 'package:softstore_buyer_app/features/messages/presentation/widgets/chat_product_header.dart';
import 'package:softstore_buyer_app/features/messages/presentation/widgets/conversation_card.dart';

void main() {
  group('ConversationCard Widget Tests', () {
    final thread = ConversationThread(
      id: '202',
      threadUrl: '/store/messages/202',
      sellerName: 'Karachi Traders',
      productName: 'Gaming Mouse',
      lastMessage: 'Ready for shipping today.',
      lastMessageTime: DateTime.now().subtract(const Duration(minutes: 5)),
      unreadCount: 3,
      isUnread: true,
    );

    testWidgets('renders seller name, product name, last message, and unread badge',
        (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ConversationCard(
              conversation: thread,
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Karachi Traders'), findsOneWidget);
      expect(find.text('Gaming Mouse'), findsOneWidget);
      expect(find.text('Ready for shipping today.'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.byType(ConversationCard));
      expect(tapped, isTrue);
    });
  });

  group('ChatBubble Widget Tests', () {
    testWidgets('renders buyer message with primary brand styling', (tester) async {
      final msg = ChatMessage(
        id: 1,
        sender: MessageSender.buyer,
        text: 'Do you have warranty for this item?',
        sentAt: DateTime(2026, 8, 21, 14, 30),
        status: MessageStatus.sent,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBubble(message: msg),
          ),
        ),
      );

      expect(find.text('Do you have warranty for this item?'), findsOneWidget);
      expect(find.byIcon(Icons.done_all_rounded), findsOneWidget);
    });

    testWidgets('renders seller message with seller icon indicator', (tester) async {
      final msg = ChatMessage(
        id: 2,
        sender: MessageSender.seller,
        text: 'Yes, 1 year official local warranty included.',
        sentAt: DateTime(2026, 8, 21, 14, 32),
        status: MessageStatus.sent,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBubble(message: msg),
          ),
        ),
      );

      expect(find.text('Yes, 1 year official local warranty included.'), findsOneWidget);
      expect(find.byIcon(Icons.store_rounded), findsOneWidget);
    });

    testWidgets('redacts sensitive contact info and displays safety warning chip', (tester) async {
      final msg = ChatMessage(
        id: 3,
        sender: MessageSender.seller,
        text: 'Contact me on 03001234567 or email me at shop@gmail.com',
        sentAt: DateTime(2026, 8, 21, 14, 35),
        status: MessageStatus.sent,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatBubble(message: msg),
          ),
        ),
      );

      expect(find.textContaining('03001234567'), findsNothing);
      expect(find.textContaining('shop@gmail.com'), findsNothing);
      expect(find.textContaining('[Phone Number Hidden]'), findsOneWidget);
      expect(find.textContaining('[Email Address Hidden]'), findsOneWidget);
      expect(find.text('Contact details hidden for safety'), findsOneWidget);
    });
  });

  group('ChatProductHeader Widget Tests', () {
    testWidgets('renders product name, price, and inquiry button', (tester) async {
      bool inquiryTapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ChatProductHeader(
              productId: 789,
              productName: 'Mechanical Keyboard RGB',
              productPrice: 4999.0,
              onSendInquiry: () => inquiryTapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Mechanical Keyboard RGB'), findsOneWidget);
      expect(find.text('PKR 4999'), findsOneWidget);
      expect(find.text('Ask Seller'), findsOneWidget);

      await tester.tap(find.text('Ask Seller'));
      expect(inquiryTapped, isTrue);
    });
  });
}
