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
      expect(first.threadUrl, '/messages/101');
      expect(first.sellerName, 'Gadget Hub');
      expect(first.productName, 'Smart Watch Pro');
      expect(first.productImage, 'https://softstore.pk/media/smartwatch.jpg');
      expect(first.lastMessage, 'Your order has been dispatched.');
      expect(first.isUnread, isTrue);
      expect(first.unreadCount, 2);

      final second = results[1];
      expect(second.threadUrl, '/messages/102');
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

    test('parseThreadMessagesHtml extracts .bsm-msg structure from live SoftStore chat', () {
      const liveChatHtml = '''
      <div class="sx-card">
        <div class="bsm-thread" id="bsmThread">
          <div class="bsm-msg mine">
            <div class="bsm-msg-meta">Naheed · 21 Aug 2026, 02:52 PM</div>
            <div class="bsm-msg-bubble">testing 123</div>
          </div>
          <div class="bsm-msg">
            <div class="bsm-msg-meta">Store Seller · 21 Aug 2026, 02:54 PM</div>
            <div class="bsm-msg-bubble">Hello Naheed! How can we help you?</div>
          </div>
        </div>
      </div>
      ''';

      final messages = MessagesRepository.parseThreadMessagesHtml(
        liveChatHtml,
        threadUrl: '/messages/14',
      );

      expect(messages.length, 2);

      expect(messages[0].isFromBuyer, isTrue);
      expect(messages[0].text, 'testing 123');

      expect(messages[1].isFromSeller, isTrue);
      expect(messages[1].text, 'Hello Naheed! How can we help you?');
    });

    test('parseConversationsHtml extracts threads from live .sx-table HTML', () {
      const liveTableHtml = '''
      <div class="sx-card">
        <table class="sx-table">
          <thead>
            <tr><th>From</th><th>Subject</th><th>Product</th><th>Status</th><th>Last activity</th><th></th></tr>
          </thead>
          <tbody>
            <tr>
              <td>Naheed</td>
              <td>delivery charges?</td>
              <td class="sx-t-xs">Cococola</td>
              <td><span class="sx-badge sx-badge-accent">Open</span></td>
              <td class="sx-t-xs">21 Aug 2026, 03:07 PM</td>
              <td><a href="/inbox/13" class="sx-btn sx-btn-ghost sx-btn-sm">Open</a></td>
            </tr>
            <tr>
              <td>Naheed</td>
              <td>inquiry about product</td>
              <td class="sx-t-xs">Mac book</td>
              <td><span class="sx-badge sx-badge-accent">Open</span></td>
              <td class="sx-t-xs">21 Aug 2026, 03:05 PM</td>
              <td><a href="/inbox/12" class="sx-btn sx-btn-ghost sx-btn-sm">Open</a></td>
            </tr>
            <tr>
              <td>Usman Zahoor</td>
              <td>is this original</td>
              <td class="sx-t-xs">Iphone 15 Pro Cover</td>
              <td><span class="sx-badge sx-badge-accent">Open</span></td>
              <td class="sx-t-xs">20 Aug 2026, 03:33 PM</td>
              <td><a href="/inbox/7" class="sx-btn sx-btn-ghost sx-btn-sm">Open</a></td>
            </tr>
          </tbody>
        </table>
      </div>
      ''';

      final results = MessagesRepository.parseConversationsHtml(liveTableHtml);

      expect(results.length, 3);

      expect(results[0].threadUrl, '/messages/13');
      expect(results[0].sellerName, 'Cococola');
      expect(results[0].productName, 'Cococola');
      expect(results[0].lastMessage, 'delivery charges?');
      expect(results[0].isUnread, isTrue);

      expect(results[1].threadUrl, '/messages/12');
      expect(results[1].sellerName, 'Mac book');
      expect(results[1].productName, 'Mac book');
      expect(results[1].lastMessage, 'inquiry about product');

      expect(results[2].threadUrl, '/messages/7');
      expect(results[2].sellerName, 'Iphone 15 Pro Cover');
      expect(results[2].lastMessage, 'is this original');
    });

    test('parseConversationsHtml extracts buyer dashboard cards with seller and product accurately', () {
      const buyerDashboardHtml = '''
      <div class="sx-card">
        <div class="sx-card-hd">
          <strong class="sx-head">Conversations</strong>
          <span class="sx-t-xs">2 total</span>
        </div>
        <div>
          <a href="/messages/19" style="display:block;padding:.9rem 1.25rem;">
            <div>
              <strong>Inquiry: Le Falconé Garcia Pour Homme Perfumed Body Spray-200ml</strong>
            </div>
            <div class="sx-t-xs">
              UZquettastore · Le Falconé Garcia Pour Homme Perfumed Body Spray-200ml
            </div>
            <div>
              <span class="sx-badge sx-badge-accent">Open</span>
              <span class="sx-t-xs">21 Aug 2026, 05:03 PM</span>
            </div>
          </a>
          <a href="/messages/13" style="display:block;padding:.9rem 1.25rem;">
            <div>
              <strong>delivery charges?</strong>
            </div>
            <div class="sx-t-xs">
              Uzquetta · Cococola
            </div>
            <div>
              <span class="sx-badge sx-badge-accent">Open</span>
              <span class="sx-t-xs">21 Aug 2026, 04:54 PM</span>
            </div>
          </a>
        </div>
      </div>
      ''';

      final results = MessagesRepository.parseConversationsHtml(buyerDashboardHtml);

      expect(results.length, 2);

      expect(results[0].id, '19');
      expect(results[0].threadUrl, '/messages/19');
      expect(results[0].sellerName, 'UZquettastore');
      expect(results[0].productName, 'Le Falconé Garcia Pour Homme Perfumed Body Spray-200ml');
      expect(results[0].lastMessage, 'Inquiry: Le Falconé Garcia Pour Homme Perfumed Body Spray-200ml');
      expect(results[0].isUnread, isTrue);

      expect(results[1].id, '13');
      expect(results[1].threadUrl, '/messages/13');
      expect(results[1].sellerName, 'Uzquetta');
      expect(results[1].productName, 'Cococola');
      expect(results[1].lastMessage, 'delivery charges?');
      expect(results[1].isUnread, isTrue);
    });

    test('parseTimestamp parses diverse dates correctly and does not default to current time', () {
      final t1 = MessagesRepository.parseTimestamp('Naheed · 21 Aug 2026, 02:52 PM');
      expect(t1.year, 2026);
      expect(t1.month, 8);
      expect(t1.day, 21);
      expect(t1.hour, 14);
      expect(t1.minute, 52);

      final t2 = MessagesRepository.parseTimestamp('Store Seller · 21 Aug 2026, 02:54 PM');
      expect(t2.hour, 14);
      expect(t2.minute, 54);

      final t3 = MessagesRepository.parseTimestamp('20 Aug 2026, 03:33 PM');
      expect(t3.year, 2026);
      expect(t3.month, 8);
      expect(t3.day, 20);
      expect(t3.hour, 15);
      expect(t3.minute, 33);

      final t4 = MessagesRepository.parseTimestamp('21 Aug, 05:03 AM');
      expect(t4.month, 8);
      expect(t4.day, 21);
      expect(t4.hour, 5);
      expect(t4.minute, 3);
    });
  });
}
