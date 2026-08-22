import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

/// Notification preferences model for SoftStore Buyer.
@immutable
class NotificationSettings extends Equatable {
  final bool orderUpdates;
  final bool promotions;
  final bool emailNotifications;

  const NotificationSettings({
    this.orderUpdates = true,
    this.promotions = false,
    this.emailNotifications = true,
  });

  NotificationSettings copyWith({
    bool? orderUpdates,
    bool? promotions,
    bool? emailNotifications,
  }) {
    return NotificationSettings(
      orderUpdates: orderUpdates ?? this.orderUpdates,
      promotions: promotions ?? this.promotions,
      emailNotifications: emailNotifications ?? this.emailNotifications,
    );
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    bool parseBool(dynamic val, bool fallback) {
      if (val == null) return fallback;
      if (val is bool) return val;
      if (val is num) return val == 1;
      if (val is String) {
        final s = val.toLowerCase().trim();
        return s == 'true' || s == '1' || s == 'yes' || s == 'on';
      }
      return fallback;
    }

    return NotificationSettings(
      orderUpdates: parseBool(
        json['order_updates'] ?? json['order_notifications'] ?? json['orders'],
        true,
      ),
      promotions: parseBool(
        json['promotions'] ??
            json['promotional_notifications'] ??
            json['promos'] ??
            json['offers'],
        false,
      ),
      emailNotifications: parseBool(
        json['email_notifications'] ?? json['email_updates'] ?? json['email'],
        true,
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'order_updates': orderUpdates,
      'promotions': promotions,
      'email_notifications': emailNotifications,
    };
  }

  Map<String, String> toFormData() {
    return {
      'order_updates': orderUpdates ? '1' : '0',
      'promotions': promotions ? '1' : '0',
      'email_notifications': emailNotifications ? '1' : '0',
      'order_notifications': orderUpdates ? '1' : '0',
      'promotional_notifications': promotions ? '1' : '0',
      'email_updates': emailNotifications ? '1' : '0',
    };
  }

  @override
  List<Object?> get props => [orderUpdates, promotions, emailNotifications];
}
