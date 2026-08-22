import 'package:flutter_test/flutter_test.dart';
import 'package:softstore_buyer_app/features/profile/models/notification_settings_model.dart';

void main() {
  group('NotificationSettings Model', () {
    test('Default values are correct', () {
      const settings = NotificationSettings();
      expect(settings.orderUpdates, isTrue);
      expect(settings.promotions, isFalse);
      expect(settings.emailNotifications, isTrue);
    });

    test('toJson and fromJson work correctly', () {
      const settings = NotificationSettings(
        orderUpdates: false,
        promotions: true,
        emailNotifications: false,
      );

      final json = settings.toJson();
      expect(json['order_updates'], isFalse);
      expect(json['promotions'], isTrue);
      expect(json['email_notifications'], isFalse);

      final fromJson = NotificationSettings.fromJson(json);
      expect(fromJson, equals(settings));
    });

    test('fromJson handles string booleans and numbers correctly', () {
      final settings = NotificationSettings.fromJson({
        'order_updates': '1',
        'promotions': 'true',
        'email_notifications': 0,
      });

      expect(settings.orderUpdates, isTrue);
      expect(settings.promotions, isTrue);
      expect(settings.emailNotifications, isFalse);
    });

    test('toFormData outputs standard form parameters', () {
      const settings = NotificationSettings(
        orderUpdates: true,
        promotions: false,
        emailNotifications: true,
      );

      final formData = settings.toFormData();
      expect(formData['order_updates'], '1');
      expect(formData['promotions'], '0');
      expect(formData['email_notifications'], '1');
      expect(formData['order_notifications'], '1');
      expect(formData['promotional_notifications'], '0');
    });

    test('copyWith updates specific fields properly', () {
      const original = NotificationSettings(
        orderUpdates: true,
        promotions: false,
        emailNotifications: true,
      );

      final updated = original.copyWith(promotions: true);
      expect(updated.orderUpdates, isTrue);
      expect(updated.promotions, isTrue);
      expect(updated.emailNotifications, isTrue);
    });
  });
}
