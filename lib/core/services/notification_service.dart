import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../app/router.dart';
import '../config/env_config.dart';

/// Push Notification and Announcement payload model.
class PushNotificationData {
  final String? notificationId;
  final String title;
  final String body;
  final Map<String, dynamic> additionalData;
  final String? type; // 'order', 'announcement', 'deal', 'product', 'general'
  final String? targetId;
  final String? targetUrl;
  final DateTime receivedAt;

  const PushNotificationData({
    this.notificationId,
    required this.title,
    required this.body,
    this.additionalData = const {},
    this.type,
    this.targetId,
    this.targetUrl,
    required this.receivedAt,
  });

  factory PushNotificationData.fromOSNotification(OSNotification notification) {
    final data = notification.additionalData ?? {};
    return PushNotificationData(
      notificationId: notification.notificationId,
      title: notification.title ?? 'SoftStore Announcement',
      body: notification.body ?? '',
      additionalData: Map<String, dynamic>.from(data),
      type: data['type']?.toString(),
      targetId: data['order_id']?.toString() ??
          data['id']?.toString() ??
          data['slug']?.toString() ??
          data['target_id']?.toString(),
      targetUrl: data['url']?.toString() ?? data['link']?.toString(),
      receivedAt: DateTime.now(),
    );
  }
}

/// Central Push Notification Service managing OneSignal setup,
/// buyer order tracking alerts, promotional announcements, and deep-linking.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  bool _initialized = false;
  final _notificationStreamController =
      StreamController<PushNotificationData>.broadcast();

  /// Stream of incoming push notifications for in-app reaction/badges.
  Stream<PushNotificationData> get onNotificationReceived =>
      _notificationStreamController.stream;

  /// Initializes the OneSignal SDK.
  /// Safe to call on web, desktop, and mobile.
  Future<void> init({String? appId}) async {
    if (_initialized) return;

    final String resolvedAppId = appId ?? EnvConfig.oneSignalAppId;

    if (resolvedAppId.isEmpty || resolvedAppId == 'YOUR_ONESIGNAL_APP_ID') {
      developer.log(
        '[NotificationService] OneSignal App ID is not configured. Skipping initialization.',
        name: 'notifications',
      );
      return;
    }

    try {
      if (kDebugMode) {
        OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
        OneSignal.Debug.setAlertLevel(OSLogLevel.none);
      }

      // 1. Initialize OneSignal
      OneSignal.initialize(resolvedAppId);
      developer.log('[NotificationService] OneSignal initialized with App ID: $resolvedAppId', name: 'notifications');

      // 2. Request Notification Permission
      await OneSignal.Notifications.requestPermission(true);

      // 3. Setup Foreground Notification Listener
      OneSignal.Notifications.addForegroundWillDisplayListener((event) {
        final notification = event.notification;
        final pushData = PushNotificationData.fromOSNotification(notification);
        developer.log('[NotificationService] Foreground notification received: ${pushData.title}', name: 'notifications');

        _notificationStreamController.add(pushData);

        // Keep notification visible in system tray/heads-up banner
        event.notification.display();
      });

      // 4. Setup Click / Deep Link Handler
      OneSignal.Notifications.addClickListener((event) {
        final notification = event.notification;
        final pushData = PushNotificationData.fromOSNotification(notification);
        developer.log('[NotificationService] Notification clicked: ${pushData.title}', name: 'notifications');

        _handleNotificationClick(pushData);
      });

      // 5. Default Segment Tagging for Buyer App
      await OneSignal.User.addTags({
        'app_type': 'buyer',
        'platform': defaultTargetPlatform.name,
        'announcements_enabled': 'true',
        'order_updates_enabled': 'true',
      });

      _initialized = true;
    } catch (e, stack) {
      developer.log('[NotificationService] Failed to initialize OneSignal: $e\n$stack', name: 'notifications');
    }
  }

  /// Deep linking and route navigation when a push notification is opened.
  void _handleNotificationClick(PushNotificationData data) {
    try {
      final type = data.type?.toLowerCase();
      final targetId = data.targetId;
      final rawUrl = data.targetUrl;

      // 1. External Web URL Link (e.g. Announcement / Promo link)
      if (rawUrl != null && (rawUrl.startsWith('http://') || rawUrl.startsWith('https://'))) {
        final uri = Uri.parse(rawUrl);
        launchUrl(uri, mode: LaunchMode.externalApplication);
        return;
      }

      // 2. Custom explicit route e.g. "/deals", "/track-order"
      final explicitRoute = data.additionalData['route']?.toString();
      if (explicitRoute != null && explicitRoute.isNotEmpty) {
        goRouter.push(explicitRoute);
        return;
      }

      // 3. Order Tracking Updates (e.g. Dispatched, Delivered, Return Status)
      if (type == 'order' || type == 'order_tracking' || type == 'order_status') {
        if (targetId != null && targetId.isNotEmpty) {
          goRouter.push('/orders/$targetId');
        } else {
          goRouter.push(AppRoutes.orders);
        }
        return;
      }

      // 4. Announcements & Flash Deals
      if (type == 'announcement' || type == 'deal' || type == 'promo') {
        if (targetId != null && targetId.isNotEmpty) {
          goRouter.push('/product/$targetId');
        } else {
          goRouter.push(AppRoutes.deals);
        }
        return;
      }

      // 5. Product Detail
      if (type == 'product' && targetId != null && targetId.isNotEmpty) {
        goRouter.push('/product/$targetId');
        return;
      }

      // 6. Messages / Support
      if (type == 'support' || type == 'ticket') {
        if (targetId != null && targetId.isNotEmpty) {
          goRouter.push('/support/tickets/$targetId');
        } else {
          goRouter.push(AppRoutes.supportTickets);
        }
        return;
      }

      // Default: Go to Deals / Home
      goRouter.push(AppRoutes.home);
    } catch (e) {
      developer.log('[NotificationService] Error handling notification navigation: $e', name: 'notifications');
    }
  }

  // ─── Buyer & Order Tagging ─────────────────────────────────────────────────

  /// Binds the authenticated buyer with OneSignal for personalized push alerts.
  Future<void> setBuyerUser({
    required String email,
    String? userId,
    String? phone,
    String? firstName,
  }) async {
    try {
      final externalId = userId ?? email;
      await OneSignal.login(externalId);

      await OneSignal.User.addTags({
        'user_type': 'buyer',
        'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (firstName != null && firstName.isNotEmpty) 'first_name': firstName,
        'is_authenticated': 'true',
      });
      developer.log('[NotificationService] Buyer user tagged: $externalId', name: 'notifications');
    } catch (e) {
      developer.log('[NotificationService] Failed to tag buyer user: $e', name: 'notifications');
    }
  }

  /// Attaches recent order tracking tags so order dispatch/delivery notifications
  /// can target this user directly.
  Future<void> tagOrderTracking({
    required String orderId,
    required String referenceNumber,
    String? status,
  }) async {
    try {
      await OneSignal.User.addTags({
        'last_order_id': orderId,
        'tracking_reference': referenceNumber,
        if (status != null) 'last_order_status': status,
        'has_active_order': 'true',
      });
      developer.log('[NotificationService] Order tracking tagged: $referenceNumber', name: 'notifications');
    } catch (e) {
      developer.log('[NotificationService] Failed to tag order tracking: $e', name: 'notifications');
    }
  }

  /// Updates buyer notification channel preferences and segment tags in OneSignal.
  Future<void> updateNotificationPreferences({
    required bool orderUpdates,
    required bool promotions,
    required bool emailNotifications,
  }) async {
    try {
      await OneSignal.User.addTags({
        'order_updates_enabled': orderUpdates ? 'true' : 'false',
        'promotions_enabled': promotions ? 'true' : 'false',
        'announcements_enabled': promotions ? 'true' : 'false',
        'email_notifications_enabled': emailNotifications ? 'true' : 'false',
      });
      developer.log(
        '[NotificationService] Notification preferences updated in OneSignal: '
        'orderUpdates=$orderUpdates, promotions=$promotions, email=$emailNotifications',
        name: 'notifications',
      );
    } catch (e) {
      developer.log(
        '[NotificationService] Failed to update notification preferences: $e',
        name: 'notifications',
      );
    }
  }

  /// Toggles general broadcast announcements channel.
  Future<void> setAnnouncementsEnabled(bool enabled) async {
    try {
      await OneSignal.User.addTags({
        'announcements_enabled': enabled ? 'true' : 'false',
        'promotions_enabled': enabled ? 'true' : 'false',
      });
    } catch (_) {}
  }

  /// Clears user identification on logout.
  Future<void> clearUserOnLogout() async {
    try {
      await OneSignal.logout();
      await OneSignal.User.removeTags([
        'email',
        'phone',
        'first_name',
        'is_authenticated',
        'last_order_id',
        'tracking_reference',
        'has_active_order',
      ]);
      developer.log('[NotificationService] OneSignal user session cleared', name: 'notifications');
    } catch (e) {
      developer.log('[NotificationService] Error clearing user session: $e', name: 'notifications');
    }
  }

  /// Returns current push token / subscription ID if registered.
  String? get subscriptionId => OneSignal.User.pushSubscription.id;
  String? get pushToken => OneSignal.User.pushSubscription.token;
  bool get isSubscribed => OneSignal.User.pushSubscription.optedIn ?? false;
}
