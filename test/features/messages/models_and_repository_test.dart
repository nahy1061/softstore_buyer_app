import 'package:flutter_test/flutter_test.dart';
import 'package:softstore_buyer_app/features/messages/data/messages_repository.dart';
import 'package:softstore_buyer_app/features/messages/models/chat_message_model.dart';
import 'package:softstore_buyer_app/features/messages/models/conversation_model.dart';

void main() {
  group('ChatMessage Model Tests', () {
    test('serializes to and from JSON correctly', () {
      final now = DateTime.now();
      final msg = ChatMessage(
        id: 101,
        threadUrl: '/store/messages/45',
        sender: MessageSender.buyer,
        text: 'Is this product still in stock?',
        sentAt: now,
        status: MessageStatus.sent,
        clientSideId: 'client_101',
      );

      final json = msg.toJson();
      final fromJson = ChatMessage.fromJson(json);

      expect(fromJson.id, 101);
      expect(fromJson.threadUrl, '/store/messages/45');
      expect(fromJson.sender, MessageSender.buyer);
      expect(fromJson.isFromBuyer, isTrue);
      expect(fromJson.isFromSeller, isFalse);
      expect(fromJson.text, 'Is this product still in stock?');
      expect(fromJson.status, MessageStatus.sent);
      expect(fromJson.clientSideId, 'client_101');
    });

    test('MessageSender.fromString parses variations correctly', () {
      expect(MessageSender.fromString('seller'), MessageSender.seller);
      expect(MessageSender.fromString('store'), MessageSender.seller);
      expect(MessageSender.fromString('vendor'), MessageSender.seller);
      expect(MessageSender.fromString('buyer'), MessageSender.buyer);
      expect(MessageSender.fromString(null), MessageSender.buyer);
    });

    test('copyWith updates specified fields', () {
      final msg = ChatMessage(
        id: 1,
        sender: MessageSender.buyer,
        text: 'Hello',
        sentAt: DateTime.now(),
        status: MessageStatus.sending,
      );

      final updated = msg.copyWith(status: MessageStatus.sent, text: 'Hello confirmed');
      expect(updated.status, MessageStatus.sent);
      expect(updated.text, 'Hello confirmed');
      expect(updated.sender, MessageSender.buyer);
    });
  });

  group('ConversationThread Model Tests', () {
    test('serializes to and from JSON correctly', () {
      final now = DateTime.now();
      final thread = ConversationThread(
        id: '123',
        threadUrl: '/store/messages/123',
        sellerName: 'Karachi Electronics',
        sellerAvatar: 'https://softstore.pk/media/avatar.png',
        productId: 456,
        productName: 'Wireless Headphones',
        productImage: 'https://softstore.pk/media/headphone.jpg',
        productPrice: 2499.0,
        lastMessage: 'Yes, we ship nationwide.',
        lastMessageTime: now,
        unreadCount: 2,
        isUnread: true,
      );

      final json = thread.toJson();
      final fromJson = ConversationThread.fromJson(json);

      expect(fromJson.id, '123');
      expect(fromJson.threadUrl, '/store/messages/123');
      expect(fromJson.sellerName, 'Karachi Electronics');
      expect(fromJson.productId, 456);
      expect(fromJson.productName, 'Wireless Headphones');
      expect(fromJson.productPrice, 2499.0);
      expect(fromJson.unreadCount, 2);
      expect(fromJson.isUnread, isTrue);
    });
  });

  group('MessagesRepository HTML Parsing Tests', () {
    test('parseConversationsHtml extracts threads accurately', () {
      const htmlFixture = '''
      <div class="messages-container">
        <div class="message-thread unread" href="/store/messages/101">
          <div class="seller-name">Gadget Hub</div>
          <div class="product-name">Smart Watch Pro</div>
          <img src="/media/smartwatch.jpg" />
          <div class="last-message">Your order has been dispatched.</div>
          <div class="timestamp">10 minutes ago</div>
          <span class="unread-badge">2</span>
        </div>
        <div class="message-thread" href="/store/messages/102">
          <div class="seller-name">Fashion World</div>
          <div class="product-name">Denim Jacket</div>
          <img src="https://softstore.pk/media/jacket.jpg" />
          <div class="last-message">Available in size L and XL.</div>
          <div class="timestamp">2 hours ago</div>
        </div>
      </div>
      ''';

      final results = MessagesRepository.parseConversationsHtml(htmlFixture);

      expect(results.length, 2);
      
      final first = results[0];
      expect(first.threadUrl, '/store/messages/101');
      expect(first.sellerName, 'Gadget Hub');
      expect(first.productName, 'Smart Watch Pro');
      expect(first.productImage, 'https://softstore.pk/media/smartwatch.jpg');
      expect(first.lastMessage, 'Your order has been dispatched.');
      expect(first.isUnread, isTrue);
      expect(first.unreadCount, 2);

      final second = results[1];
      expect(second.threadUrl, '/store/messages/102');
      expect(second.sellerName, 'Fashion World');
      expect(second.productName, 'Denim Jacket');
      expect(second.productImage, 'https://softstore.pk/media/jacket.jpg');
      expect(second.isUnread, isFalse);
    });

    test('parseThreadMessagesHtml extracts message bubbles accurately', () {
      const threadHtml = '''
      <div class="chat-container">
        <div class="message-bubble buyer-message" data-id="1">
          <p class="text">Hi, do you offer cash on delivery for Lahore?</p>
          <small class="time">1 hour ago</small>
        </div>
        <div class="message-bubble seller-message" data-id="2">
          <p class="text">Yes, cash on delivery is available throughout Lahore!</p>
          <small class="time">30 minutes ago</small>
        </div>
      </div>
      ''';

      final messages = MessagesRepository.parseThreadMessagesHtml(
        threadHtml,
        threadUrl: '/store/messages/101',
      );

      expect(messages.length, 2);

      expect(messages[0].id, 1);
      expect(messages[0].isFromBuyer, isTrue);
      expect(messages[0].text, 'Hi, do you offer cash on delivery for Lahore?');

      expect(messages[1].id, 2);
      expect(messages[1].isFromSeller, isTrue);
      expect(messages[1].text, 'Yes, cash on delivery is available throughout Lahore!');
    });
  });
}
