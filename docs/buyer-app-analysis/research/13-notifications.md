# Phase 3: Notifications

## Overview

Push notifications keep buyers informed about order progress, returns, and promotions without opening the app. Firebase Cloud Messaging (FCM) is the delivery mechanism for both Android and iOS.

**Phase:** Notifications are Phase 2 for the MVP (the core purchase loop ships first), but the architecture is designed now so the backend team can build the server-side component in parallel.

---

## Notification Types

### Order Notifications

| Event | Title | Body Example | Data Payload | Navigation Target |
|-------|-------|-------------|-------------|-------------------|
| Order confirmed | "Order Confirmed" | "Your order MKT-772AB has been confirmed by the seller" | `{type: 'order_status', order_id: 123, status: 'confirmed'}` | `/orders/123` |
| Order processing | "Being Packed" | "Your order is being packed at the store" | `{type: 'order_status', order_id: 123, status: 'processing'}` | `/orders/123` |
| Order shipped | "Order Shipped" | "Your order has been handed to the courier" | `{type: 'order_status', order_id: 123, status: 'shipped'}` | `/orders/123` |
| Order delivered | "Order Delivered" | "Your package has been delivered!" | `{type: 'order_status', order_id: 123, status: 'delivered'}` | `/orders/123` |
| Order cancelled | "Order Cancelled" | "Your order MKT-772AB has been cancelled" | `{type: 'order_status', order_id: 123, status: 'cancelled'}` | `/orders/123` |
| Delivery failed | "Delivery Failed" | "Courier could not deliver. We'll retry." | `{type: 'order_status', order_id: 123, status: 'delivery_failed'}` | `/orders/123` |

### Return Notifications

| Event | Title | Body Example | Data Payload | Navigation Target |
|-------|-------|-------------|-------------|-------------------|
| Return approved | "Return Approved" | "Your return request has been approved. Refund processing." | `{type: 'return_update', return_id: 45, status: 'approved'}` | `/returns` |
| Return rejected | "Return Update" | "Your return request was not approved. Tap to see reason." | `{type: 'return_update', return_id: 45, status: 'rejected'}` | `/returns` |
| Refund completed | "Refund Issued" | "PKR 1,200 has been refunded for your return." | `{type: 'return_update', return_id: 45, status: 'completed'}` | `/returns` |

### Support Notifications

| Event | Title | Body Example | Data Payload | Navigation Target |
|-------|-------|-------------|-------------|-------------------|
| Agent replied | "Support Reply" | "Your support ticket has a new message" | `{type: 'support_reply', ticket_id: 78}` | `/support/78` |
| Ticket resolved | "Ticket Resolved" | "Your support ticket has been resolved" | `{type: 'support_reply', ticket_id: 78}` | `/support/78` |

### Promotional Notifications

| Event | Title | Body Example | Data Payload | Navigation Target |
|-------|-------|-------------|-------------|-------------------|
| Sale/deal | "Flash Sale!" | "Up to 50% off electronics — today only" | `{type: 'promotion', product_slug: 'wireless-earbuds'}` | `/product/wireless-earbuds` or `/` |
| New arrivals | "New Arrivals" | "Check out what's new this week" | `{type: 'promotion', category_slug: 'electronics'}` | `/category/electronics` |
| Coupon | "Exclusive Offer" | "Use code FIRST100 for Rs 100 off" | `{type: 'promotion', coupon_code: 'FIRST100'}` | `/` (pre-fill coupon at checkout) |
| Restock | "Back in Stock" | "An item from your wishlist is available again" | `{type: 'promotion', product_slug: 'some-product'}` | `/product/some-product` |

---

## Firebase Cloud Messaging (FCM) Architecture

### Setup

```
┌──────────────┐        ┌───────────────┐        ┌──────────────────┐
│  Flutter App  │        │  FCM Servers  │        │ Softstore Backend │
│              │        │  (Google)     │        │                  │
│ 1. Register  │───────►│              │        │                  │
│    get token │◄───────│ FCM Token    │        │                  │
│              │        │              │        │                  │
│ 2. Send token│────────┼──────────────┼───────►│ Store in DB      │
│    to backend│        │              │        │ (device_tokens)  │
│              │        │              │        │                  │
│              │        │ 3. Push msg  │◄───────│ On order status  │
│ 4. Receive   │◄───────│              │        │ change, send FCM │
│    display   │        │              │        │                  │
└──────────────┘        └───────────────┘        └──────────────────┘
```

### Token Registration

```dart
// On app start (after login) or on token refresh
final fcmToken = await FirebaseMessaging.instance.getToken();
if (fcmToken != null) {
  await api.post('/api/buyer/notifications/register-device', {
    'fcm_token': fcmToken,
    'platform': Platform.isIOS ? 'ios' : 'android',
  });
  // Store locally to avoid re-registering same token
  await prefs.setString('fcm_token', fcmToken);
}

// Listen for token refresh
FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
  api.post('/api/buyer/notifications/register-device', {
    'fcm_token': newToken,
    'platform': Platform.isIOS ? 'ios' : 'android',
  });
  prefs.setString('fcm_token', newToken);
});
```

### Token Lifecycle

| Event | Action |
|-------|--------|
| Login | Register token with buyer ID |
| Logout | Unregister token (POST /api/buyer/notifications/unregister-device) |
| Token refresh | Re-register with backend |
| App install | Get new token on first login |
| App uninstall | FCM auto-expires token after ~2 months of inactivity |

---

## Foreground Behavior

When a notification arrives and the app is **in the foreground**:

```dart
FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  final type = message.data['type'];
  final notification = message.notification;

  // Show in-app banner (not system notification)
  showInAppNotification(
    title: notification?.title ?? '',
    body: notification?.body ?? '',
    onTap: () => _navigateFromNotification(message.data),
  );

  // Update relevant state
  switch (type) {
    case 'order_status':
      // Refresh order detail if user is viewing that order
      ordersCubit.refreshIfViewing(message.data['order_id']);
      break;
    case 'support_reply':
      // Refresh ticket messages if viewing that ticket
      supportCubit.refreshIfViewing(message.data['ticket_id']);
      break;
  }
});
```

### In-App Notification Banner

- Appears as a dismissible overlay at the top of the screen
- Shows for 4 seconds, then auto-hides
- Tappable → navigates to relevant screen
- Does NOT show if user is already on the target screen

---

## Background Behavior

When the app is **in the background** or **terminated**:

```dart
// Background message handler (must be top-level function)
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // System notification is shown automatically by FCM
  // No custom handling needed for display
  // Data is preserved for when user taps
}

// When user taps notification (app was in background)
FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
  _navigateFromNotification(message.data);
});

// When app was terminated and opened via notification tap
final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
if (initialMessage != null) {
  // Wait for router to initialize, then navigate
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _navigateFromNotification(initialMessage.data);
  });
}
```

### Background Notification Display

FCM handles system notification display automatically when:
- The message includes a `notification` field (title + body)
- The app is in background or terminated

No local notification plugin needed for basic display.

---

## Notification Navigation

```dart
void _navigateFromNotification(Map<String, dynamic> data) {
  final type = data['type'] as String?;

  switch (type) {
    case 'order_status':
      final orderId = data['order_id'];
      if (orderId != null) router.go('/orders/$orderId');
      break;

    case 'return_update':
      router.go('/returns');
      break;

    case 'promotion':
      final productSlug = data['product_slug'];
      if (productSlug != null) {
        router.go('/product/$productSlug');
      } else {
        router.go('/');
      }
      break;

    case 'support_reply':
      final ticketId = data['ticket_id'];
      if (ticketId != null) router.go('/support/$ticketId');
      break;

    default:
      router.go('/');
  }
}
```

### Navigation Edge Cases

| Scenario | Behavior |
|----------|---------|
| User not logged in + taps order notification | Navigate to `/login?next=/orders/{id}` |
| User on same screen as notification target | Refresh data, don't re-navigate |
| Notification references deleted order | Show error state on order detail |
| Multiple pending notifications | Only most recent tap is processed |

---

## Notification Preferences (Phase 2)

### User-Configurable Settings

| Category | Default | User Can Disable |
|----------|---------|-----------------|
| Order status changes | ON | No (critical) |
| Delivery updates | ON | No (critical) |
| Return updates | ON | No (critical) |
| Support replies | ON | No (critical) |
| Promotions & deals | ON | Yes |
| New arrivals | ON | Yes |
| Restock alerts | ON | Yes |

### Settings Screen UI

```
Notification Settings
├── Order & Delivery Updates .............. [Always on]
├── Return & Refund Updates .............. [Always on]
├── Support Messages ..................... [Always on]
├── Promotions & Deals ................... [Toggle: ON]
├── New Arrivals ......................... [Toggle: ON]
└── Wishlist Restocks .................... [Toggle: ON]
```

### Backend Topic Subscription

```dart
// Subscribe to promotional topics (can unsubscribe)
FirebaseMessaging.instance.subscribeToTopic('promotions');
FirebaseMessaging.instance.subscribeToTopic('new_arrivals');

// User disables promotions:
FirebaseMessaging.instance.unsubscribeFromTopic('promotions');
```

Order/return/support notifications are sent directly to the device token (not topics), so they cannot be unsubscribed client-side.

---

## Notification Badge & In-App List

### Unread Count Badge

```dart
// Bottom nav "Profile" tab or dedicated bell icon
Badge(
  isLabelVisible: unreadCount > 0,
  label: Text('$unreadCount'),
  child: Icon(Icons.notifications_outlined),
)
```

### In-App Notification List

| Field | Display |
|-------|---------|
| Icon | Based on type (order=box, return=↩, promo=tag, support=chat) |
| Title | Notification title |
| Body | Notification body (1-2 lines) |
| Time | Relative ("2h ago", "Yesterday") |
| Read state | Unread = bold title + accent dot |

### Mark as Read

- Tap notification → mark read + navigate
- "Mark all as read" button at top
- Opening notifications list marks visible ones as read after 2s

---

## iOS-Specific Configuration

### Permissions

```dart
// Request permission on first relevant action (not on app start)
final settings = await FirebaseMessaging.instance.requestPermission(
  alert: true,
  badge: true,
  sound: true,
  provisional: false, // Ask explicitly
);

if (settings.authorizationStatus == AuthorizationStatus.authorized) {
  // Proceed with token registration
} else if (settings.authorizationStatus == AuthorizationStatus.denied) {
  // Don't ask again; show in-app prompt if user tries to enable later
}
```

### When to Ask

- NOT on first app launch (user hasn't seen value yet)
- After first order is placed: "Want to know when your order ships?"
- After first wishlist add: "We'll notify you when items go on sale"

### APNs Setup

- Upload APNs auth key to Firebase Console
- Add `GoogleService-Info.plist` to iOS project
- Enable "Push Notifications" capability in Xcode

---

## Android-Specific Configuration

### Notification Channel

```dart
const AndroidNotificationChannel orderChannel = AndroidNotificationChannel(
  'order_updates',
  'Order Updates',
  description: 'Notifications about your order status',
  importance: Importance.high,
);

const AndroidNotificationChannel promoChannel = AndroidNotificationChannel(
  'promotions',
  'Promotions',
  description: 'Deals, offers, and new arrivals',
  importance: Importance.defaultImportance,
);
```

### Android 13+ Permission

```dart
// Android 13 requires runtime permission for notifications
if (Platform.isAndroid) {
  final status = await Permission.notification.request();
  // Handle status
}
```

---

## Backend Requirements for Notifications

The backend team needs to build:

| Component | Description |
|-----------|-------------|
| `device_tokens` table | `{id, buyer_id, fcm_token, platform, created_at, updated_at}` |
| Register endpoint | `POST /api/buyer/notifications/register-device` |
| Unregister endpoint | `POST /api/buyer/notifications/unregister-device` |
| Notification sender service | Called when order status changes, returns update, etc. |
| `notifications` table | `{id, buyer_id, type, title, body, data (JSON), read, created_at}` |
| List endpoint | `GET /api/buyer/notifications?page=` |
| Mark read endpoint | `POST /api/buyer/notifications/{id}/read` |
| Mark all read endpoint | `POST /api/buyer/notifications/read-all` |
| FCM server SDK integration | `firebase-admin` or HTTP v1 API for sending |

### When Backend Sends Notifications

| Trigger | Service Hook |
|---------|-------------|
| Seller confirms order | `OrderService::confirm()` → `NotificationService::send(buyer, 'order_confirmed', ...)` |
| Order status changes | `OrderService::updateStatus()` → notify buyer |
| Return approved/rejected | `ReturnService::approve/reject()` → notify buyer |
| Support agent replies | `SupportService::reply()` → notify buyer |
| Promotional (batch) | Admin panel trigger → topic message to 'promotions' |
| Wishlist restock | Product stock update → check wishlisters → notify |

---

## Testing Notifications

### Development Testing

- Use Firebase Console → Cloud Messaging → "Send test message"
- Target specific FCM token (logged during development)
- Test all three states: foreground, background, terminated

### Checklist Before Launch

- [ ] Token registration works on fresh install
- [ ] Token refreshes are sent to backend
- [ ] Foreground shows in-app banner (not system notification)
- [ ] Background shows system notification with correct icon
- [ ] Tapping notification navigates to correct screen
- [ ] Cold-start from notification works
- [ ] Logout unregisters token
- [ ] iOS permission prompt appears at the right time
- [ ] Android channels show in system settings
- [ ] Unread badge updates correctly
