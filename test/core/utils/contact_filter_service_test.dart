import 'package:flutter_test/flutter_test.dart';
import 'package:softstore_buyer_app/core/utils/contact_filter_service.dart';

void main() {
  group('ContactFilterService Tests', () {
    final filter = ContactFilterService.instance;

    test('clean messages pass without violation', () {
      final res1 = filter.analyze('Hello, is this item available in Black color?');
      expect(res1.hasViolation, isFalse);
      expect(res1.sanitizedText, 'Hello, is this item available in Black color?');
      expect(res1.warningMessage, isNull);

      final res2 = filter.analyze('What are the delivery charges for Lahore?');
      expect(res2.hasViolation, isFalse);
    });

    test('detects and redacts standard Pakistani mobile numbers', () {
      final res1 = filter.analyze('Call me on 03001234567 for quick deal');
      expect(res1.hasViolation, isTrue);
      expect(res1.detectedTypes, contains('Phone Number'));
      expect(res1.sanitizedText, contains('[Phone Number Hidden]'));
      expect(res1.sanitizedText, isNot(contains('03001234567')));

      final res2 = filter.analyze('My number is 0345-9876543');
      expect(res2.hasViolation, isTrue);
      expect(res2.sanitizedText, contains('[Phone Number Hidden]'));

      final res3 = filter.analyze('Contact: +92 321 4567890');
      expect(res3.hasViolation, isTrue);
      expect(res3.sanitizedText, contains('[Phone Number Hidden]'));
    });

    test('detects spaced phone numbers and evasion attempts', () {
      final res = filter.analyze('Reach me at 0 3 0 0 1 2 3 4 5 6 7');
      expect(res.hasViolation, isTrue);
      expect(res.sanitizedText, contains('[Phone Number Hidden]'));
      expect(res.sanitizedText, isNot(contains('0 3 0 0')));
    });

    test('detects and redacts email addresses', () {
      final res = filter.analyze('Send pictures to buyer.test@gmail.com please');
      expect(res.hasViolation, isTrue);
      expect(res.detectedTypes, contains('Email Address'));
      expect(res.sanitizedText, contains('[Email Address Hidden]'));
      expect(res.sanitizedText, isNot(contains('buyer.test@gmail.com')));
    });

    test('detects WhatsApp links and keywords', () {
      final res1 = filter.analyze('Chat here: https://wa.me/923001234567');
      expect(res1.hasViolation, isTrue);
      expect(res1.detectedTypes, contains('WhatsApp Contact'));
      expect(res1.sanitizedText, contains('[WhatsApp Link Hidden]'));

      final res2 = filter.analyze('Contact me on whatsapp 03009998877');
      expect(res2.hasViolation, isTrue);
      expect(res2.sanitizedText, contains('[WhatsApp Info Hidden]'));
    });

    test('detects social media links', () {
      final res = filter.analyze('Check my page: instagram.com/pak_store');
      expect(res.hasViolation, isTrue);
      expect(res.detectedTypes, contains('Social Media Profile'));
      expect(res.sanitizedText, contains('[Social Link Hidden]'));
    });

    test('detects direct payment account details', () {
      final res = filter.analyze('Send money to EasyPaisa: 03123456789');
      expect(res.hasViolation, isTrue);
      expect(res.detectedTypes, contains('Direct Payment Account'));
      expect(res.sanitizedText, contains('[Payment Details Hidden]'));
    });

    test('redact() returns safe text for incoming seller messages', () {
      final text = 'Please call 0300-1122334 or email support@shop.pk';
      final safeText = filter.redact(text);
      expect(safeText, isNot(contains('0300-1122334')));
      expect(safeText, isNot(contains('support@shop.pk')));
      expect(safeText, contains('[Phone Number Hidden]'));
      expect(safeText, contains('[Email Address Hidden]'));
    });
  });
}
