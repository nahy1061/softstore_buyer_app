# Phase 3: Navigation Architecture

## Routing Solution: GoRouter

**Choice:** `go_router` (maintained by the Flutter team)

**Reasons:**
- Declarative routing with path-based URLs (required for deep linking)
- Built-in redirect guards (authentication protection)
- Nested navigation via `StatefulShellRoute` (bottom nav with preserved state)
- Type-safe route parameters via `go_router_builder` (optional)
- Supports `pushReplacement` for post-checkout flow
- Well-documented, actively maintained, officially recommended

---

## Bottom Navigation Structure

```dart
StatefulShellRoute.indexedStack(
  branches: [
    // Tab 0: Home
    StatefulShellBranch(routes: [homeRoutes]),
    // Tab 1: Categories
    StatefulShellBranch(routes: [categoryRoutes]),
    // Tab 2: Cart
    StatefulShellBranch(routes: [cartRoutes]),
    // Tab 3: Orders
    StatefulShellBranch(routes: [orderRoutes]),
    // Tab 4: Profile
    StatefulShellBranch(routes: [profileRoutes]),
  ],
)
```

Each branch maintains its own navigation stack. Switching tabs preserves scroll position and nested pages.

---

## Route Table

### Public Routes (No Auth Required)

| Path | Screen | Parameters | Notes |
|------|--------|-----------|-------|
| `/` | Store Home | — | Default landing, tab 0 |
| `/search` | Search Results | `?q=&category=&sort=&min_price=&max_price=` | Query params |
| `/category/:slug` | Category View | `slug` | Pre-filtered grid |
| `/product/:slug` | Product Detail | `slug` | Deep linkable |
| `/seller/:slug` | Seller Store | `slug` | Individual store |
| `/cart` | Cart | — | Tab 2 |
| `/checkout` | Checkout Flow | — | Multi-step |
| `/checkout/delivery` | Delivery Step | — | Sub-route |
| `/checkout/verify` | Email OTP Step | — | Sub-route |
| `/checkout/review` | Review & Place | — | Sub-route |
| `/order-confirmation/:ref` | Confirmation | `ref` | Post-checkout |
| `/track-order` | Public Tracking | `?invoice=&phone=` | No login |
| `/parcel/:token` | Parcel QR Page | `token` | Deep link from QR |
| `/login` | Login | `?next=` | Redirect param |
| `/register` | Register | `?next=` | Redirect param |
| `/forgot-password` | Password Reset | — | Email entry |
| `/reset-password/:token` | New Password | `token` | Deep link from email |
| `/faq` | FAQ | — | Static |
| `/contact` | Contact | — | Form |
| `/terms` | Terms | — | WebView |
| `/privacy` | Privacy | — | WebView |

### Protected Routes (Auth Required)

| Path | Screen | Parameters | Notes |
|------|--------|-----------|-------|
| `/orders` | Order History | — | Tab 3 |
| `/orders/:id` | Order Detail | `id` | From history list |
| `/orders/:id/return` | Return Request | `id` | Sheet/page |
| `/returns` | Returns List | — | From profile |
| `/profile` | Profile Hub | — | Tab 4 |
| `/profile/edit` | Edit Profile | — | Nested |
| `/profile/addresses` | Address Book | — | List |
| `/profile/addresses/add` | Add Address | — | Form |
| `/profile/addresses/:id/edit` | Edit Address | `id` | Form |
| `/profile/wishlist` | Wishlist | — | Grid |
| `/profile/settings` | Settings | — | Preferences |
| `/profile/change-password` | Change Password | — | Form |
| `/support/new` | New Ticket | — | Form |
| `/support/:id` | Ticket Chat | `id` | Messages |

---

## Authentication Flow & Route Protection

```dart
GoRouter(
  redirect: (context, state) {
    final isLoggedIn = authNotifier.isAuthenticated;
    final isAuthRoute = state.matchedLocation.startsWith('/login') ||
                        state.matchedLocation.startsWith('/register');
    final isProtected = _protectedPaths.any(
      (p) => state.matchedLocation.startsWith(p),
    );

    // Not logged in + trying protected route → login with ?next=
    if (!isLoggedIn && isProtected) {
      return '/login?next=${Uri.encodeComponent(state.uri.toString())}';
    }

    // Already logged in + on auth page → go home (or ?next)
    if (isLoggedIn && isAuthRoute) {
      final next = state.uri.queryParameters['next'];
      return next != null ? Uri.decodeComponent(next) : '/';
    }

    return null; // No redirect
  },
)
```

**Protected path prefixes:**
```
/orders, /returns, /profile, /support
```

**Semi-protected (prompt but don't block):**
- `/checkout` — shows "sign in for faster checkout" banner but allows guest flow
- Wishlist toggle — prompts login, then returns to product page

---

## Deep Linking Configuration

### URI Scheme
```
softstore://
```

### Universal Links / App Links
```
https://softstore.pk/product/{slug}
https://softstore.pk/store/{slug}
https://softstore.pk/track-order?invoice={inv}
https://softstore.pk/parcel/{token}
https://softstore.pk/reset-password/{token}
https://softstore.pk/store/category/{slug}
```

### GoRouter Deep Link Mapping
GoRouter handles deep links automatically when paths match. The `routeInformationProvider` listens for incoming platform URIs.

### Android Configuration (`AndroidManifest.xml`)
```xml
<intent-filter android:autoVerify="true">
  <action android:name="android.intent.action.VIEW" />
  <category android:name="android.intent.category.DEFAULT" />
  <category android:name="android.intent.category.BROWSABLE" />
  <data android:scheme="https" android:host="softstore.pk" />
  <data android:scheme="softstore" />
</intent-filter>
```

### iOS Configuration (`Info.plist`)
```xml
<key>CFBundleURLTypes</key>
<array>
  <dict>
    <key>CFBundleURLSchemes</key>
    <array><string>softstore</string></array>
  </dict>
</array>
<key>com.apple.developer.associated-domains</key>
<array><string>applinks:softstore.pk</string></array>
```

---

## Back Navigation Behavior

| Context | Back Button Behavior |
|---------|---------------------|
| Tab root screen (Home, Cart, etc.) | Exits app (Android) or no-op (iOS) |
| Nested screen within tab | Pops to parent within same tab |
| Product detail (from any source) | Pops to previous screen (search, category, home, seller) |
| Checkout steps | Back goes to previous step; first step goes to cart |
| Login/Register (from ?next) | Back goes to previous screen (not ?next target) |
| Order Confirmation | Back goes to Home (cart is cleared, checkout is invalid) |
| Deep link opened cold | Back goes to Home (no history stack) |

### Implementation
```dart
// Checkout: custom back that navigates steps
GoRoute(
  path: '/checkout/verify',
  pageBuilder: (context, state) => NoTransitionPage(
    child: CheckoutVerifyScreen(
      onBack: () => context.go('/checkout/delivery'),
    ),
  ),
)

// Order confirmation: replace entire stack
context.goNamed('order-confirmation', pathParameters: {'ref': ref});
// Back from confirmation goes to home since go() replaces
```

---

## Post-Login Navigation

```
User taps protected action (e.g., wishlist, view orders)
  │
  ├── Redirect to /login?next=/profile/wishlist
  │
  ├── User logs in successfully
  │
  └── Router redirect reads ?next → navigates to /profile/wishlist
```

If `?next` is absent, default post-login destination is `/` (home).

For login triggered from checkout prompt:
```
/checkout → tap "Sign in" → /login?next=/checkout/delivery
```

---

## Post-Checkout Navigation

```
Place order success
  │
  ├── Clear cart (local storage)
  ├── context.go('/order-confirmation/$ref')  // replaces stack
  │
  └── From confirmation:
        ├── "View my orders" → context.go('/orders')
        └── "Keep shopping" → context.go('/')
```

Using `context.go()` (not `push`) ensures the checkout screens are removed from the back stack. The user cannot accidentally navigate back to a stale checkout.

---

## Notification Navigation

When a push notification is tapped:

| Notification Type | Navigate To | Parameters |
|-------------------|-------------|-----------|
| Order status change | `/orders/:id` | order ID from payload |
| Delivery update | `/orders/:id` | order ID |
| Return approved/rejected | `/returns` | — |
| Promotional | `/product/:slug` or `/` | product slug if specific |
| Support reply | `/support/:id` | ticket ID |

### Implementation
```dart
// In notification handler (FCM onMessageOpenedApp)
void handleNotificationNavigation(RemoteMessage message) {
  final data = message.data;
  final type = data['type'];
  final targetId = data['target_id'];

  switch (type) {
    case 'order_status':
      router.go('/orders/$targetId');
    case 'return_update':
      router.go('/returns');
    case 'promotion':
      final slug = data['product_slug'];
      router.go(slug != null ? '/product/$slug' : '/');
    case 'support_reply':
      router.go('/support/$targetId');
  }
}
```

### Cold Start (App Not Running)
FCM's `getInitialMessage()` returns the notification that launched the app. Process it after the router is initialized and auth state is resolved.

---

## Navigation State Preservation

| State | Preserved Across |
|-------|-----------------|
| Tab selection | App lifecycle (in memory) |
| Scroll position per tab | Tab switches (IndexedStack) |
| Product detail back stack | Within tab branch |
| Search query | Within search session |
| Checkout progress | Within checkout flow (lost on app kill) |
| Filter/sort selections | Within browsing session |

---

## Route Transition Animations

| Transition | Used For |
|-----------|---------|
| Platform default (slide right on iOS, fade on Android) | Normal push navigation |
| No transition | Tab switches (IndexedStack handles this) |
| Bottom-to-top slide | Bottom sheets (filter, address picker) |
| Fade | Tab content changes |
| None (instant) | Post-login redirect, post-checkout redirect |
