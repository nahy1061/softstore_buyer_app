# State Management

## Decision: BLoC/Cubit (via `flutter_bloc`)

### Why Cubit — Based on Softstore's Actual Needs

Softstore is a **request-response** shopping app. The state flows are:
1. User opens screen → Cubit fetches data from repository → emits loaded state
2. User taps button → Cubit calls repository → emits new state
3. No WebSockets, no real-time updates, no complex event streams

Cubit maps perfectly to this: `emit(Loading)` → call API → `emit(Loaded(data))` or `emit(Error(message))`.

### Comparison Against Softstore Requirements

| Requirement | Riverpod | BLoC/Cubit | Provider | GetX |
|-------------|----------|-----------|----------|------|
| 4 devs working in parallel | Good (providers are isolated) | **Excellent** (strict cubit-per-feature, clear patterns) | Risky (no enforced structure) | Risky (global state spaghetti) |
| 38 screens with data fetching | Good | **Excellent** (each screen gets its own cubit) | Awkward (ChangeNotifiers proliferate) | Works but no lifecycle discipline |
| Session cookie auth (global) | Good | **Excellent** (global cubit, BlocListener for 401) | Works | Works |
| Cart persistence (global) | Good | **Excellent** (global cubit persists to SharedPreferences) | Works | Works |
| Testing cubits in isolation | Good | **Excellent** (`blocTest` utility, no widget tree needed) | Requires widget tree or manual notifier testing | Poor (global singletons hard to reset) |
| Checkout multi-step form | Good | **Excellent** (single cubit holds form state across steps) | Awkward (passing state between screens) | Works |
| Offline → online retry | Good | **Excellent** (BlocListener reacts to connectivity changes) | Manual wiring | Manual wiring |
| DevTools debugging | Good (Riverpod observer) | **Excellent** (bloc_observer logs all transitions, DevTools extension) | Limited | Limited |

### Why Cubit Instead of Full BLoC (Events)

Full BLoC pattern adds an Event class per action:
```dart
// BLoC: 3 classes per action
class LoadProductsEvent extends ProductEvent {}
class ProductBloc extends Bloc<ProductEvent, ProductState> {
  on<LoadProductsEvent>((event, emit) async { ... });
}

// Cubit: 1 method call
class ProductCubit extends Cubit<ProductState> {
  Future<void> loadProducts() async { ... }
}
```

Cubit eliminates the event boilerplate while keeping all the advantages (immutable states, DevTools, `blocTest`, `BlocProvider`/`BlocListener`). Full BLoC is warranted when:
- You need event debouncing/throttling (e.g., search input — but `RestartableTimer` in the cubit handles that)
- You need event-driven architecture (WebSockets, SSE) — Softstore has neither

We can upgrade any individual Cubit to a full Bloc later if requirements change (e.g., support chat with long-polling might benefit from events).

### Why Not Riverpod

Riverpod is technically excellent. The reasons it's not chosen:
1. **Code generation dependency** — Riverpod 2.x pushes `@riverpod` annotation + code-gen. This adds build_runner cost to every change.
2. **Less established in the Pakistani Flutter community** — the team is more likely to have BLoC experience from previous projects. Training cost is lower.
3. **No strict patterns** — Riverpod is flexible by design (providers can be anywhere). BLoC enforces "one cubit per concern" which helps team discipline.
4. **Migration path** — if team members have used BLoC before, no migration needed.

If the team is already strong with Riverpod, this recommendation can flip. The architecture works with either.

### Why Not Provider

Provider was the precursor to Riverpod. It's fine for small apps. Problems at Softstore's scale:
- No built-in lifecycle management (easy to leak `ChangeNotifier` instances)
- No built-in test utilities (no equivalent of `blocTest`)
- `ChangeNotifier` rebuilds all listeners on any property change (no granular state)
- Hard to enforce patterns across 4 developers

### Why Not GetX

GetX is popular for prototyping. Production problems:
- Global singletons (`Get.put()`) make testing difficult (state leaks between tests)
- Magic strings for routing (`Get.toNamed('/orders')`) — no compile-time safety
- Mixes concerns (state, routing, DI, HTTP all in one package with different conventions)
- Declining community confidence (maintainer responsiveness, no clear architecture guidance)

---

## State Categories

### Global State (Lives for Entire App Lifecycle)

These cubits are created once in `app.dart` and never disposed until the app exits.

| State | Cubit | What It Holds | Why Global | Persistence |
|-------|-------|---------------|-----------|-------------|
| Auth | `AuthCubit` | Current user, login status, session validity | Every feature checks auth; 401 handling is app-wide | Cookie jar (session), SecureStorage (user cache) |
| Cart | `CartCubit` | Items, quantities, subtotal, delivery fee, total | Cart icon badge visible everywhere; product detail adds to it; checkout reads it | SharedPreferences (JSON) |
| Connectivity | `ConnectivityCubit` | Online/offline boolean | Offline banner shown app-wide; checkout blocked when offline | None (reactive stream from `connectivity_plus`) |

**Provided at:**
```dart
// app.dart
MultiBlocProvider(
  providers: [
    BlocProvider(create: (_) => AuthCubit(authRepository)..checkSession()),
    BlocProvider(create: (_) => CartCubit(cartStorage)..load()),
    BlocProvider(create: (_) => ConnectivityCubit(connectivityService)),
  ],
  child: MaterialApp.router(...)
)
```

### Feature State (Created When Screen Opens, Disposed When It Closes)

Each screen (or logical group of screens) gets its own cubit, provided via `BlocProvider` in the route builder.

| Feature | Cubit(s) | Lifecycle | What It Holds |
|---------|----------|-----------|---------------|
| Home | `HomeCubit` | Home tab active | Products, page, filters, sort, categories |
| Search | `SearchCubit` | Search screen visible | Query, results, suggestions |
| Product Detail | `ProductDetailCubit` | Detail screen visible | Product data, selected variant, qty, reviews |
| Checkout | `CheckoutCubit` | Checkout flow active | Delivery form, OTP state, coupon, order payload |
| Order History | `OrderHistoryCubit` | Orders tab active | Order list, page, status filter |
| Order Detail | `OrderDetailCubit` | Detail screen visible | Single order, timeline, return eligibility |
| Seller | `SellerCubit` | Seller page visible | Seller info, products, follow state |
| Profile | `ProfileCubit` | Profile section active | User info, edit state |
| Addresses | `AddressCubit` | Address screens visible | Address list, form state |
| Wishlist | `WishlistCubit` | Wishlist screen visible | Wishlist items |
| Notifications | `NotificationsCubit` | Notifications screen visible | Notification list, unread count |
| Support | `SupportCubit` | Support screens visible | Tickets, messages |

**Provided at route level:**
```dart
GoRoute(
  path: '/product/:slug',
  builder: (context, state) => BlocProvider(
    create: (_) => ProductDetailCubit(productDetailRepository)
      ..loadProduct(state.pathParameters['slug']!),
    child: const ProductDetailScreen(),
  ),
)
```

### Local UI State (StatefulWidget, No Cubit Needed)

Things that don't involve API calls or business logic stay in the widget:

| State | Location | Example |
|-------|----------|---------|
| Password visibility toggle | `StatefulWidget` | `bool _obscurePassword = true` |
| Image gallery current page | `PageController` | `controller.page` |
| Accordion expanded/collapsed | `StatefulWidget` | `bool _expanded = false` |
| OTP input focus management | `FocusNode` list | Auto-advance on digit entry |
| Bottom sheet open/closed | Modal route | `showModalBottomSheet()` |
| Quantity stepper value | `StatefulWidget` | Until "Add to Cart" is tapped, then it goes to CartCubit |
| Pull-to-refresh indicator | `RefreshIndicator` | Built into the widget |
| Form field controllers | `TextEditingController` | Until form is submitted |
| Tab selection (within a screen) | `TabController` | Specs/Reviews tabs on product detail |

**Rule of thumb:** If the state disappears when the user navigates away and doesn't need to be restored, it's local. If it persists, crosses screens, or triggers API calls, it's in a Cubit.

---

## Cross-Cubit Communication

| Trigger | How It Works |
|---------|-------------|
| "Add to Cart" on product detail | `ProductDetailScreen` reads `CartCubit` from context and calls `cartCubit.addItem(...)` |
| "Place Order" success | `CheckoutCubit` calls `cartCubit.clear()` directly (it receives CartCubit via constructor) |
| 401 from any API call | `AuthInterceptor` calls `authCubit.onSessionExpired()` → emits `Unauthenticated` → router guard redirects to login |
| Login success | Router redirect fires (GoRouter watches auth state), fetches wishlist if needed |
| Logout | `AuthCubit.logout()` clears cookie jar + emits `Unauthenticated`. Cart is NOT cleared (local-only). |
| Network restored | `ConnectivityCubit` emits `online: true` → `BlocListener` in active screen can trigger retry |

**Pattern:** Global cubits are accessed via `context.read<CartCubit>()`. Feature cubits are never accessed cross-feature — if they need to communicate, it goes through a global cubit or a shared repository.

---

## State Class Pattern

```dart
// Sealed class for exhaustive pattern matching
sealed class OrderHistoryState {}

class OrderHistoryInitial extends OrderHistoryState {}

class OrderHistoryLoading extends OrderHistoryState {}

class OrderHistoryLoaded extends OrderHistoryState with EquatableMixin {
  final List<OrderModel> orders;
  final int currentPage;
  final int totalPages;
  final OrderStatus? statusFilter;
  final bool isLoadingMore;

  OrderHistoryLoaded({
    required this.orders,
    required this.currentPage,
    required this.totalPages,
    this.statusFilter,
    this.isLoadingMore = false,
  });

  @override
  List<Object?> get props => [orders, currentPage, totalPages, statusFilter, isLoadingMore];
}

class OrderHistoryError extends OrderHistoryState {
  final String message;
  OrderHistoryError(this.message);
}
```

**Why sealed:** The compiler enforces exhaustive `switch` in the UI — you can't accidentally forget to handle the error state.

---

## Testing Strategy for State

```dart
blocTest<CartCubit, CartState>(
  'addItem to empty cart emits loaded with 1 item and Rs 199 delivery',
  build: () => CartCubit(FakeCartStorage()),
  seed: () => const CartEmpty(),
  act: (cubit) => cubit.addItem(testCartItem),
  expect: () => [
    isA<CartLoaded>()
      .having((s) => s.itemCount, 'count', 1)
      .having((s) => s.deliveryFee, 'delivery', 199.0),
  ],
);
```

Every cubit is testable without a widget tree, without a real API, without SharedPreferences. Mock the repository, test the state transitions.
