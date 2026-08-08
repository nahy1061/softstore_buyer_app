# Phase 3: State Management

## Recommendation: BLoC/Cubit (via `flutter_bloc`)

### Evaluation

| Criterion | Riverpod | BLoC/Cubit | Provider | GetX |
|-----------|----------|-----------|----------|------|
| Separation of concerns | Good | Excellent | Fair | Poor |
| Testability | Good | Excellent (built-in test utilities) | Fair | Poor |
| Learning curve | Moderate | Moderate | Low | Low |
| Boilerplate | Low | Medium (Cubit reduces it) | Low | Very low |
| Scalability | Good | Excellent | Limited | Limited |
| DevTools support | Good | Excellent (bloc_inspector) | Basic | Basic |
| Team development | Good | Excellent (strict patterns) | OK | Risky (global singletons) |
| Community/ecosystem | Growing | Mature, largest | Mature | Large but declining |
| Enforces architecture | Somewhat | Yes (clear state/event separation) | No | No |
| Suited for form-heavy apps | Good | Excellent | Fair | Fair |

### Why Cubit Over Full BLoC

- Softstore has no complex event-driven interactions (no WebSockets, no real-time collaboration)
- Cubit = BLoC without the event class boilerplate
- Same testability, same DevTools integration
- Can upgrade individual Cubits to full Blocs later if needed (e.g., support chat)
- `emit()` is simpler than `add(Event)` → `mapEventToState` for straightforward API calls

### Why Not Others

- **Riverpod:** Excellent but the team is more likely familiar with BLoC patterns in the Pakistani Flutter community. Riverpod's code-generation approach adds complexity.
- **Provider:** Too simple for 38 screens — no built-in state lifecycle, easy to leak state.
- **GetX:** Anti-pattern-prone (global singletons, no clear boundaries, magic strings). Not recommended for production apps of this scale.

---

## State Categories

### 1. Global State (App-Wide)

Managed by globally-provided Cubits that live for the entire app lifecycle.

| State | Cubit | What It Holds | Persistence |
|-------|-------|---------------|-------------|
| Authentication | `AuthCubit` | User session, login status, user profile | Secure storage (session cookie) |
| Cart | `CartCubit` | Cart items, quantities, totals | Local storage (SharedPreferences) |
| Connectivity | `ConnectivityCubit` | Online/offline status | None (reactive stream) |
| Theme | `ThemeCubit` | Dark/light mode (Phase 2) | SharedPreferences |

**Provided at:** `MultiBlocProvider` in `app.dart`, above `MaterialApp.router`.

### 2. Feature State (Screen-Level)

Created when navigating to a screen, disposed when leaving. Provided via `BlocProvider` in the route builder.

| Feature | Cubit | What It Holds |
|---------|-------|---------------|
| Home/Browse | `HomeCubit` | Product list, pagination, filters, sort |
| Search | `SearchCubit` | Query, results, suggestions, loading |
| Product Detail | `ProductDetailCubit` | Product data, selected variant, reviews |
| Checkout | `CheckoutCubit` | Delivery form, OTP state, coupon, order payload |
| Order History | `OrdersCubit` | Order list, pagination, filter status |
| Order Detail | `OrderDetailCubit` | Single order, timeline, return eligibility |
| Wishlist | `WishlistCubit` | Wishlist items, toggle state |
| Profile | `ProfileCubit` | User profile fields, edit state |
| Addresses | `AddressCubit` | Address list, form state |
| Seller Store | `SellerCubit` | Seller info, products |
| Support | `SupportCubit` | Tickets, messages |
| Notifications | `NotificationsCubit` | Notification list, unread count |

### 3. Local Widget State (Ephemeral)

Stays in `StatefulWidget` — no Cubit needed.

| Widget | Local State |
|--------|------------|
| Quantity stepper | Current count (int) |
| Password visibility toggle | Show/hide (bool) |
| Expandable section | Expanded/collapsed (bool) |
| Image gallery | Current page index |
| OTP input boxes | Focus node management |
| Pull-to-refresh | Refreshing indicator |
| Bottom sheet | Open/closed state |
| Form fields | TextEditingController values (until submit) |

---

## State Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│                    App Level                          │
│  AuthCubit    CartCubit    ConnectivityCubit         │
│  (always alive, provided at root)                    │
└──────────────────────┬──────────────────────────────┘
                       │
        ┌──────────────┼──────────────────┐
        │              │                  │
┌───────▼────┐  ┌──────▼──────┐  ┌───────▼──────┐
│  Home Tab  │  │  Cart Tab   │  │ Profile Tab  │
│ HomeCubit  │  │ (reads      │  │ ProfileCubit │
│            │  │  CartCubit) │  │              │
└──────┬─────┘  └─────────────┘  └──────┬───────┘
       │                                 │
┌──────▼──────────┐              ┌───────▼────────┐
│ ProductDetail   │              │ AddressCubit   │
│ Cubit           │              │ WishlistCubit  │
│ (reads CartCubit│              └────────────────┘
│  for add-to-cart)
└─────────────────┘
```

---

## Detailed State Definitions

### AuthCubit States

```dart
sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {}
class AuthLoading extends AuthState {}
class Authenticated extends AuthState {
  final UserModel user;
  final bool emailVerified;
}
class Unauthenticated extends AuthState {}
class AuthError extends AuthState {
  final String message;
  final AuthErrorType type; // invalidCredentials, networkError, rateLimited
}
```

**Responsibilities:**
- Check stored session on app start
- Login (email/password, Google OAuth)
- Register
- Logout (clear cookies + local state)
- Expose `isAuthenticated` for route guards
- Handle 401 responses (session expired → emit `Unauthenticated`)

### CartCubit States

```dart
sealed class CartState {
  const CartState();
}

class CartLoaded extends CartState {
  final List<CartItem> items;
  final double subtotal;
  final double deliveryFee;     // 199 or 0
  final double total;
  final double freeDeliveryProgress; // 0.0 to 1.0
  final int itemCount;
}

class CartEmpty extends CartState {}
```

**Responsibilities:**
- Load from local storage on app start
- Add item (product, variant, qty)
- Update quantity
- Remove item
- Clear cart (post-checkout)
- Recalculate totals on every change
- Persist to SharedPreferences on every change
- Expose `itemCount` for badge

**Business rules baked in:**
```dart
static const deliveryFee = 199.0;
static const freeDeliveryThreshold = 1500.0;

double get calculatedDeliveryFee =>
    subtotal >= freeDeliveryThreshold ? 0 : deliveryFee;
```

### HomeCubit States

```dart
sealed class HomeState {
  const HomeState();
}

class HomeLoading extends HomeState {}
class HomeLoaded extends HomeState {
  final List<ProductModel> products;
  final List<CategoryModel> categories;
  final int currentPage;
  final int totalPages;
  final bool isLoadingMore;
  final String? activeCategory;
  final String? searchQuery;
  final SortOption sort;
  final double? minPrice;
  final double? maxPrice;
  final bool freeDeliveryOnly;
}
class HomeError extends HomeState {
  final String message;
}
```

### CheckoutCubit States

```dart
sealed class CheckoutState {
  const CheckoutState();
}

class CheckoutDelivery extends CheckoutState {
  final DeliveryForm form;
  final List<AddressModel>? savedAddresses;
  final bool isSubmitting;
  final Map<String, String> fieldErrors;
}

class CheckoutVerification extends CheckoutState {
  final String email;
  final OtpStatus status; // idle, sending, sent, verifying, verified, error
  final String? errorMessage;
}

class CheckoutReview extends CheckoutState {
  final List<CartItem> items;
  final DeliveryForm delivery;
  final CouponResult? coupon;
  final double subtotal;
  final double discount;
  final double deliveryFee;
  final double total;
  final bool isPlacingOrder;
}

class CheckoutSuccess extends CheckoutState {
  final String orderRef;
}

class CheckoutError extends CheckoutState {
  final String message;
  final CheckoutErrorType type; // stockError, couponInvalid, networkError
}
```

### ProductDetailCubit States

```dart
sealed class ProductDetailState {
  const ProductDetailState();
}

class ProductDetailLoading extends ProductDetailState {}
class ProductDetailLoaded extends ProductDetailState {
  final ProductDetailModel product;
  final List<VariantModel> variants;
  final VariantModel? selectedVariant;
  final int quantity;
  final double currentPrice;
  final List<ReviewModel> reviews;
  final RatingBreakdown ratingBreakdown;
  final List<ProductModel> relatedProducts;
  final int availableStock;
  final bool isInWishlist;
}
class ProductDetailError extends ProductDetailState {
  final String message;
}
```

---

## State Interactions (Cross-Cubit Communication)

| Trigger | Source Cubit | Target Cubit | Mechanism |
|---------|-------------|-------------|-----------|
| Add to cart | ProductDetailCubit | CartCubit | Direct call: `cartCubit.addItem(...)` |
| Buy now | ProductDetailCubit | CartCubit + Router | Add to cart, then `router.go('/checkout')` |
| Place order success | CheckoutCubit | CartCubit | `cartCubit.clear()` |
| Login success | AuthCubit | WishlistCubit, OrdersCubit | Cubits fetch data on auth state change |
| Logout | AuthCubit | CartCubit | Cart preserved locally (not cleared) |
| Session expired (401) | ApiClient interceptor | AuthCubit | `authCubit.onSessionExpired()` |
| Network restored | ConnectivityCubit | All active cubits | Listeners retry pending operations |

### Cross-Cubit Access Pattern

```dart
// In ProductDetailScreen — reading CartCubit from context
final cartCubit = context.read<CartCubit>();

// In the ProductDetailCubit method:
void addToCart(ProductModel product, VariantModel? variant, int qty) {
  cartCubit.addItem(CartItem(
    productId: product.id,
    name: product.name,
    price: variant?.price ?? product.price,
    imageUrl: product.imageUrl,
    quantity: qty,
    variantId: variant?.id,
    variantLabel: variant?.label,
    sellerId: product.sellerId,
    sellerName: product.sellerName,
  ));
}
```

---

## Persistence Strategy

| State | Storage | When |
|-------|---------|------|
| Auth session (cookie) | `flutter_secure_storage` | On login, cleared on logout |
| Cart items | `SharedPreferences` (JSON string) | On every cart mutation |
| Recent searches | `SharedPreferences` (list) | On search submit |
| Onboarding completed | `SharedPreferences` (bool) | After onboarding |
| Theme preference | `SharedPreferences` (string) | On change |
| FCM token | `SharedPreferences` | On token refresh |
| Last viewed products | `SharedPreferences` (list, max 20) | On product view |

---

## Testing Strategy

```dart
// Cubit tests use blocTest from bloc_test package
blocTest<CartCubit, CartState>(
  'adding item updates total and count',
  build: () => CartCubit(mockStorage),
  seed: () => CartLoaded(items: [], subtotal: 0, ...),
  act: (cubit) => cubit.addItem(testCartItem),
  expect: () => [
    isA<CartLoaded>()
      .having((s) => s.itemCount, 'count', 1)
      .having((s) => s.subtotal, 'subtotal', 500.0),
  ],
);
```

Each Cubit is unit-testable in isolation by mocking its repository dependency.
