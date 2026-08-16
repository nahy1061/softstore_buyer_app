# Navigation Architecture

## Decision: GoRouter

### Why GoRouter

| Requirement | GoRouter | Navigator 2.0 (raw) | auto_route |
|-------------|----------|---------------------|------------|
| Deep linking (open `/product/wireless-earbuds` from outside) | Built-in, path-based | Manual parsing of RouteInformation | Built-in |
| Auth guards (redirect unauthenticated users to login) | `redirect:` callback | Manual RouteGuard + RouterDelegate | `AutoRouteGuard` |
| Bottom nav with preserved state per tab | `StatefulShellRoute.indexedStack` | Manual IndexedStack + separate navigators | Requires custom wrapper |
| Type-safe route parameters | Path params + query params | Manual | Code-gen provides typed args |
| Learning curve | Low (declarative config) | Very high (4 classes to implement) | Medium (code-gen setup) |
| Official support | Flutter team maintains it | Flutter team (but complex) | Community (Felix Angelov) |
| Code generation required | No (optional) | No | Yes (build_runner) |

**GoRouter wins** because:
1. Deep linking is critical (product links shared via WhatsApp — the dominant messaging app in Pakistan)
2. Auth redirects are a first-class feature (not bolted on)
3. `StatefulShellRoute` gives us bottom nav with zero custom code
4. No code generation — one less build_runner target
5. Officially maintained by the Flutter team

**Why not auto_route:** Requires build_runner for route generation. With json_serializable already needing build_runner, adding another generator slows iteration. auto_route's typed arguments are nice but GoRouter's path/query params are sufficient for our use case (we only pass slugs and IDs).

**Why not raw Navigator 2.0:** Implementing `RouterDelegate`, `RouteInformationParser`, `RouteInformationProvider`, and `BackButtonDispatcher` from scratch is 200+ lines of boilerplate that GoRouter encapsulates.

---

## Bottom Navigation Shell

```dart
StatefulShellRoute.indexedStack(
  builder: (context, state, navigationShell) => ScaffoldWithBottomNav(
    navigationShell: navigationShell,
  ),
  branches: [
    // Tab 0: Home
    StatefulShellBranch(routes: [
      GoRoute(path: '/', builder: (_, __) => const HomeScreen()),
    ]),
    // Tab 1: Categories
    StatefulShellBranch(routes: [
      GoRoute(path: '/categories', builder: (_, __) => const CategoriesScreen()),
    ]),
    // Tab 2: Cart
    StatefulShellBranch(routes: [
      GoRoute(path: '/cart', builder: (_, __) => const CartScreen()),
    ]),
    // Tab 3: Orders
    StatefulShellBranch(routes: [
      GoRoute(path: '/orders', builder: (_, __) => const OrderHistoryScreen()),
    ]),
    // Tab 4: Profile
    StatefulShellBranch(routes: [
      GoRoute(path: '/profile', builder: (_, __) => const ProfileHubScreen()),
    ]),
  ],
)
```

`IndexedStack` keeps all tab screens alive in memory — switching tabs doesn't lose scroll position or loaded data. This matches user expectation in shopping apps.

---

## Complete Route Tree

```
/                                   ← Home (tab 0, product grid)
├── /categories                     ← Categories grid (tab 1)
│   └── /categories/:slug           ← Category products
├── /cart                           ← Cart (tab 2)
├── /orders                         ← Order history (tab 3, auth required)
│   ├── /orders/:id                 ← Order detail
│   └── /orders/:id/return          ← Return request form
├── /profile                        ← Profile hub (tab 4, auth required)
│   ├── /profile/edit               ← Edit profile
│   ├── /profile/addresses          ← Address book
│   │   ├── /profile/addresses/add  ← Add address form
│   │   └── /profile/addresses/:id  ← Edit address form
│   ├── /profile/wishlist           ← Wishlist
│   ├── /profile/settings           ← Settings
│   ├── /profile/change-password    ← Change password
│   └── /profile/returns            ← Returns list
│
├── /search                         ← Search (not a tab — pushed from any tab)
│   └── ?q=&category=&sort=&min_price=&max_price=
│
├── /product/:slug                  ← Product detail (pushed from any context)
├── /seller/:slug                   ← Seller store page
│
├── /checkout                       ← Checkout flow (not a tab)
│   ├── /checkout/delivery          ← Step 1: Delivery details
│   ├── /checkout/verify            ← Step 2: Email OTP
│   └── /checkout/review            ← Step 3: Review & place order
│
├── /order-confirmation/:ref        ← Post-checkout success
├── /track-order                    ← Public tracking (no auth)
├── /parcel/:token                  ← QR code parcel page
│
├── /login                          ← Login (?next= param)
├── /register                       ← Register (?next= param)
├── /forgot-password                ← Request reset
├── /reset-password/:token          ← Set new password (deep link)
├── /verify-email                   ← OTP verification (post-register)
│
├── /faq                            ← Static FAQ
├── /contact                        ← Contact form
├── /terms                          ← Terms of service
├── /privacy                        ← Privacy policy
│
├── /support/new                    ← New support ticket (auth required)
└── /support/:id                    ← Ticket chat (auth required)
```

---

## Authentication & Route Protection

### Protected Routes

These routes require `AuthCubit` state to be `Authenticated`:
```
/orders, /orders/:id, /orders/:id/return
/profile, /profile/*
/support/*
```

### Semi-Protected Actions (Prompt, Don't Block)

These screens are accessible to guests, but certain actions prompt login:
- Product detail → "Add to Wishlist" → login prompt
- Checkout → "Sign in for faster checkout" banner (non-blocking)
- Store → "Follow" → login prompt

### Redirect Logic

```dart
GoRouter(
  refreshListenable: authCubit,  // Router re-evaluates on auth state change
  redirect: (context, state) {
    final auth = context.read<AuthCubit>().state;
    final isAuthenticated = auth is Authenticated;
    final currentPath = state.matchedLocation;

    // Protected route + not logged in → send to login
    if (_isProtected(currentPath) && !isAuthenticated) {
      return '/login?next=${Uri.encodeComponent(state.uri.toString())}';
    }

    // On login/register page + already logged in → redirect away
    if (_isAuthPage(currentPath) && isAuthenticated) {
      final next = state.uri.queryParameters['next'];
      return next != null ? Uri.decodeComponent(next) : '/';
    }

    return null;  // No redirect
  },
)

bool _isProtected(String path) {
  const protectedPrefixes = ['/orders', '/profile', '/support'];
  return protectedPrefixes.any((p) => path.startsWith(p));
}

bool _isAuthPage(String path) {
  return path.startsWith('/login') || path.startsWith('/register');
}
```

### Post-Login Navigation

1. User tries to access `/profile/wishlist` while not logged in
2. Router redirects to `/login?next=%2Fprofile%2Fwishlist`
3. User logs in → `AuthCubit` emits `Authenticated`
4. `refreshListenable` triggers router re-evaluation
5. Router sees `isAuthenticated && isAuthPage` → redirect to decoded `?next` → `/profile/wishlist`

---

## Deep Linking

### Why Deep Linking Matters for Softstore

Pakistani buyers share product links via WhatsApp constantly. A link like `https://softstore.pk/product/wireless-earbuds` tapped on a phone with the app installed should open the product detail directly — not the browser.

### Supported Deep Links

| Link | App Route | Parameters |
|------|-----------|-----------|
| `https://softstore.pk/product/{slug}` | `/product/:slug` | Product slug |
| `https://softstore.pk/store/{slug}` | `/seller/:slug` | Seller slug |
| `https://softstore.pk/store/category/{slug}` | `/categories/:slug` | Category slug |
| `https://softstore.pk/track-order?invoice=X&phone=Y` | `/track-order` | Query params |
| `https://softstore.pk/parcel/{token}` | `/parcel/:token` | Parcel token |
| `https://softstore.pk/reset-password/{token}` | `/reset-password/:token` | Reset token |
| `softstore://product/{slug}` | `/product/:slug` | Custom scheme fallback |

### Configuration

GoRouter handles deep links automatically — the path definitions double as deep link handlers. Platform config (AndroidManifest, Info.plist) registers the URL patterns.

### Cold Start from Deep Link

When the app is not running and a deep link opens it:
1. `GoRouter` receives the initial route from platform
2. `redirect:` fires — checks auth state (which may still be loading)
3. If the route is public (product, track-order, parcel) → navigate directly
4. If the route is protected → depends on session cookie validity:
   - Cookie valid → `AuthCubit` resolves `Authenticated` → navigate to route
   - Cookie expired → redirect to `/login?next={deeplink}`

---

## Checkout Flow Navigation

Checkout is a linear 3-step flow that should NOT be in the bottom nav. It's a separate route group.

```dart
GoRoute(
  path: '/checkout',
  redirect: (_, state) {
    // If someone navigates to /checkout directly, start at delivery
    if (state.matchedLocation == '/checkout') return '/checkout/delivery';
    return null;
  },
  routes: [
    GoRoute(path: 'delivery', builder: (_, __) => const CheckoutDeliveryScreen()),
    GoRoute(path: 'verify', builder: (_, __) => const CheckoutVerifyScreen()),
    GoRoute(path: 'review', builder: (_, __) => const CheckoutReviewScreen()),
  ],
)
```

**Back navigation in checkout:**
- Delivery → back → Cart
- Verify → back → Delivery
- Review → back → Verify

**Post-order:**
```dart
// After successful order placement
context.go('/order-confirmation/$ref');
// go() replaces the route stack — user can't "back" into checkout
```

**From confirmation:**
- "View my orders" → `context.go('/orders')` (replace)
- "Keep shopping" → `context.go('/')` (replace)

---

## Notification Navigation

When a push notification is tapped:

```dart
void handleNotificationTap(Map<String, dynamic> data) {
  final type = data['type'];
  switch (type) {
    case 'order_status':
      router.go('/orders/${data['order_id']}');
    case 'return_update':
      router.go('/profile/returns');
    case 'promotion':
      final slug = data['product_slug'];
      router.go(slug != null ? '/product/$slug' : '/');
    case 'support_reply':
      router.go('/support/${data['ticket_id']}');
  }
}
```

If the route is protected and user isn't authenticated → login redirect with `?next` handles it automatically.

---

## Back Navigation Behavior

| Situation | Back Button Does |
|-----------|-----------------|
| At tab root (Home, Cart, etc.) | Android: exit app. iOS: nothing. |
| Nested within a tab | Pop to previous screen within that tab |
| Product detail (opened from Home tab) | Back to Home (stays in tab 0) |
| Product detail (opened from Search) | Back to Search results |
| Checkout step 1 (Delivery) | Back to Cart |
| Order confirmation | Back goes to Home (go() replaced stack) |
| Login (from protected route redirect) | Back to previous non-auth screen |
| Deep link cold start → no back stack | Back goes to Home |

### Implementation Note

For "deep link cold start has no history" — when the app opens cold to `/product/xyz`, there's no Home in the back stack. Pressing back would exit the app. This is acceptable behavior (matches how links work in other apps). If we want "back goes to home," we'd need to push Home onto the stack first — but this adds complexity for an edge case.
