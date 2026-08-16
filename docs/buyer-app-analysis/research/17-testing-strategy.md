# Phase 4: Testing Strategy

## Test Pyramid

```
         ╱╲
        ╱  ╲         Integration Tests (5–10)
       ╱    ╲        End-to-end flows
      ╱──────╲
     ╱        ╲      Widget Tests (30–50)
    ╱          ╲     Individual screen/widget rendering
   ╱────────────╲
  ╱              ╲   Unit Tests (100+)
 ╱                ╲  Cubits, repositories, models, utils
╱──────────────────╲
```

**Target coverage:** 80%+ for `domain/` and `data/` layers, 60%+ for `presentation/` Cubits.

---

## Unit Tests

### What to Unit Test

| Layer | What | How |
|-------|------|-----|
| Models | `fromJson` / `toJson` for every model | Sample JSON fixtures |
| Models | `copyWith` correctness | Verify field updates |
| Cubits | All state transitions | `blocTest` from `bloc_test` |
| Cubits | Error handling | Mock repository to throw |
| Cubits | Edge cases (empty, max, null) | Boundary inputs |
| Repositories | API call → model mapping | Mock Dio responses |
| Repositories | Error mapping (DioException → Failure) | Mock error responses |
| Validators | Email, phone, password, name | Valid + invalid inputs |
| Formatters | PKR currency, date, phone display | Expected outputs |
| Cart logic | Add, remove, qty, totals, delivery fee | State transitions |

### Testing Packages

```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  bloc_test: ^9.0.0
  mocktail: ^1.0.0      # Mocking (simpler than mockito)
  fake_async: ^1.3.0    # Debounce/timer testing
```

### Example: Cart Cubit Unit Test

```dart
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CartCubit', () {
    late CartCubit cubit;
    late MockCartStorage mockStorage;

    setUp(() {
      mockStorage = MockCartStorage();
      cubit = CartCubit(mockStorage);
    });

    blocTest<CartCubit, CartState>(
      'addItem increases count and recalculates total',
      build: () => cubit,
      seed: () => CartEmpty(),
      act: (c) => c.addItem(CartItem(
        productId: 1, name: 'Test', price: 500,
        imageUrl: '', quantity: 1, sellerId: 1, sellerName: 'Store',
      )),
      expect: () => [
        isA<CartLoaded>()
          .having((s) => s.itemCount, 'count', 1)
          .having((s) => s.subtotal, 'subtotal', 500.0)
          .having((s) => s.deliveryFee, 'fee', 199.0)
          .having((s) => s.total, 'total', 699.0),
      ],
    );

    blocTest<CartCubit, CartState>(
      'free delivery when subtotal >= 1500',
      build: () => cubit,
      seed: () => CartEmpty(),
      act: (c) => c.addItem(CartItem(
        productId: 1, name: 'Test', price: 1500,
        imageUrl: '', quantity: 1, sellerId: 1, sellerName: 'Store',
      )),
      expect: () => [
        isA<CartLoaded>()
          .having((s) => s.deliveryFee, 'fee', 0.0)
          .having((s) => s.total, 'total', 1500.0),
      ],
    );
  });
}
```

### Example: Model Serialization Test

```dart
void main() {
  group('ProductModel', () {
    test('fromJson creates correct model', () {
      final json = {
        'id': 1,
        'name': 'Wireless Earbuds',
        'slug': 'wireless-earbuds',
        'price': 2500.0,
        'list_price': 3000.0,
        'has_discount': true,
        'discount_percent': 17,
        'image_url': '/media/tenants/1/products/earbuds.jpg',
        'seller_name': 'TechStore',
        'seller_id': 5,
        'in_stock': true,
        'stock_quantity': 12,
      };

      final product = ProductModel.fromJson(json);

      expect(product.name, 'Wireless Earbuds');
      expect(product.hasDiscount, true);
      expect(product.discountPercent, 17);
    });

    test('toJson produces valid map', () {
      final product = ProductModel(/* ... */);
      final json = product.toJson();
      expect(json['slug'], 'wireless-earbuds');
    });
  });
}
```

---

## Widget Tests

### What to Widget Test

| Widget | What to Verify |
|--------|---------------|
| ProductCard | Renders name, price, image; taps fire callback |
| PriceDisplay | Shows sale price, strikethrough, discount badge correctly |
| CategoryChips | Scrollable, tap selects, active chip highlighted |
| CartItemTile | Shows qty stepper, swipe reveals delete |
| OtpInput | 6 boxes, auto-advance on digit, backspace goes back |
| StatusPipeline | Highlights correct steps based on status |
| EmptyState | Shows illustration, message, CTA; CTA tap fires callback |
| ErrorState | Shows message, retry button; tap fires callback |
| FilterSheet | Sliders move, toggles work, Apply fires callback with values |
| AddressCard | Shows all fields, default badge, tap fires callback |

### Example: ProductCard Widget Test

```dart
void main() {
  testWidgets('ProductCard shows name and price', (tester) async {
    final product = ProductModel(
      id: 1, name: 'Test Product', slug: 'test', price: 500,
      imageUrl: 'https://example.com/img.jpg', sellerName: 'Shop',
      sellerId: 1, hasDiscount: false, inStock: true,
      reviewCount: 0, freeDelivery: false, fulfilmentChannel: 'seller',
    );

    bool tapped = false;

    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ProductCard(
        product: product,
        onTap: () => tapped = true,
      )),
    ));

    expect(find.text('Test Product'), findsOneWidget);
    expect(find.text('Rs 500'), findsOneWidget);

    await tester.tap(find.byType(ProductCard));
    expect(tapped, true);
  });
}
```

---

## Integration Tests

### Critical User Journeys to Test End-to-End

| # | Journey | Steps |
|---|---------|-------|
| 1 | Guest purchase | Home → tap product → add to cart → checkout → delivery → OTP → place order → confirmation |
| 2 | Auth purchase | Login → home → search → product → cart → checkout (saved address) → place order |
| 3 | Registration | Register → OTP → dashboard |
| 4 | Order tracking | Orders tab → tap order → see detail + timeline |
| 5 | Wishlist toggle | Product detail → tap heart → wishlist screen → verify → remove |
| 6 | Cart management | Add multiple → update qty → remove one → verify totals |
| 7 | Deep link | Cold start from product deep link → see product detail |

### Integration Test Setup

```dart
// Uses integration_test package
// Runs on real device/emulator with mock or staging API

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Guest purchase flow', (tester) async {
    app.main(); // Start the app
    await tester.pumpAndSettle();

    // Home screen
    expect(find.byType(ProductGrid), findsOneWidget);

    // Tap first product
    await tester.tap(find.byType(ProductCard).first);
    await tester.pumpAndSettle();

    // Product detail
    expect(find.text('Add to cart'), findsOneWidget);
    await tester.tap(find.text('Add to cart'));
    await tester.pumpAndSettle();

    // Navigate to cart
    await tester.tap(find.byIcon(Icons.shopping_cart));
    await tester.pumpAndSettle();

    // Verify cart has item
    expect(find.byType(CartItemTile), findsOneWidget);

    // Proceed to checkout...
    await tester.tap(find.text('Proceed to checkout'));
    await tester.pumpAndSettle();

    // Continue with checkout steps...
  });
}
```

---

## API Testing

### Strategy: Mock API Responses in Unit/Widget Tests

Do NOT call real API in unit tests. Use `mocktail` to mock the Dio client or repository layer.

```dart
class MockProductRepository extends Mock implements ProductRepository {}

// In test
when(() => mockRepo.getProducts(page: 1))
    .thenAnswer((_) async => [testProduct1, testProduct2]);
```

### Contract Testing (Optional but Recommended)

Maintain JSON fixtures that match the expected API response format:

```
test/fixtures/
├── products_list.json
├── product_detail.json
├── login_success.json
├── login_error.json
├── checkout_success.json
├── order_history.json
└── ...
```

If the backend changes their response format, fixture tests break immediately.

---

## Authentication Testing

| Scenario | Test Type | Verification |
|----------|-----------|-------------|
| Login success | Unit (AuthCubit) | Emits Authenticated state |
| Login invalid credentials | Unit (AuthCubit) | Emits AuthError(invalidCredentials) |
| Login rate limited | Unit (AuthCubit) | Emits AuthError(rateLimited) |
| Registration success | Unit (AuthCubit) | Emits Authenticated + otpRequired |
| Session expiry (401) | Unit (AuthInterceptor) | Triggers onSessionExpired |
| Auto-login on restart | Unit (AuthCubit) | Checks cookie jar, emits Authenticated |
| Google OAuth success | Unit (AuthCubit) | Emits Authenticated from ID token |
| Route protection | Widget (GoRouter) | Redirects to /login when unauthenticated |
| Post-login redirect | Integration | Login → navigates to ?next URL |

---

## Cart Testing

| Scenario | Test Type | Verification |
|----------|-----------|-------------|
| Add item (new) | Unit (CartCubit) | Item appears, count = 1 |
| Add item (duplicate) | Unit (CartCubit) | Quantity increments |
| Add with variant | Unit (CartCubit) | Variant stored, price correct |
| Remove item | Unit (CartCubit) | Item gone, totals recalculate |
| Update quantity | Unit (CartCubit) | New qty, new total |
| Max quantity (stock cap) | Unit (CartCubit) | Cannot exceed stock |
| Free delivery at 1500 | Unit (CartCubit) | Fee = 0 when subtotal >= 1500 |
| Delivery fee below 1500 | Unit (CartCubit) | Fee = 199 |
| Persistence (save) | Unit (CartCubit) | Calls storage.save on every mutation |
| Persistence (load) | Unit (CartCubit) | Restores from storage on init |
| Empty cart | Unit (CartCubit) | Emits CartEmpty state |
| Clear cart (post-checkout) | Unit (CartCubit) | All items removed, storage cleared |

---

## Checkout Testing

| Scenario | Test Type | Verification |
|----------|-----------|-------------|
| Delivery form valid | Unit (CheckoutCubit) | Advances to OTP step |
| Delivery form invalid | Unit (CheckoutCubit) | Shows field errors |
| OTP send success | Unit (CheckoutCubit) | Status = sent |
| OTP verify success | Unit (CheckoutCubit) | Status = verified, advances |
| OTP verify wrong code | Unit (CheckoutCubit) | Error message shown |
| Coupon valid | Unit (CheckoutCubit) | Discount applied to total |
| Coupon invalid | Unit (CheckoutCubit) | Error message, no discount |
| Place order success | Unit (CheckoutCubit) | Emits CheckoutSuccess |
| Place order stock error | Unit (CheckoutCubit) | Emits error with stock message |
| Place order network error | Unit (CheckoutCubit) | Emits error, button re-enables |
| Guest checkout (no login) | Integration | Full flow without auth |
| Saved address selection | Widget | Bottom sheet shows addresses |

---

## Order Testing

| Scenario | Test Type | Verification |
|----------|-----------|-------------|
| Order history loads | Unit (OrdersCubit) | List of orders emitted |
| Order history paginated | Unit (OrdersCubit) | Page 2 appends to list |
| Order detail loads | Unit (OrderDetailCubit) | Full order with items/timeline |
| Status pipeline rendering | Widget | Correct steps highlighted |
| Timeline rendering | Widget | Entries show in chronological order |
| Public tracking success | Unit | Order data returned for invoice+phone |
| Public tracking not found | Unit | Error message emitted |
| Return eligible (within 7 days) | Unit | returnEligible = true |
| Return not eligible (>7 days) | Unit | returnEligible = false |

---

## Network Failure Testing

| Scenario | Test Type | Verification |
|----------|-----------|-------------|
| Timeout → retry | Unit (RetryInterceptor) | Retries 2 times then fails |
| 500 → retry | Unit (RetryInterceptor) | Retries with backoff |
| No connection | Unit (Repository) | Returns NetworkFailure |
| 401 → logout | Unit (AuthInterceptor) | Triggers session expired |
| 429 → rate limit error | Unit (Repository) | Returns RateLimitFailure with seconds |
| Offline → cached data | Unit (Cubit) | Emits loaded state from cache |
| Offline → no cache | Unit (Cubit) | Emits error state |
| Connection restored | Unit (ConnectivityCubit) | Emits online, triggers refresh |

---

## Security Testing

| Test | Method | Pass Criteria |
|------|--------|--------------|
| No secrets in source | `git grep -i "password\|secret\|api_key"` | Zero matches (except test fixtures) |
| No print() in production | `grep -r "print(" lib/` | Zero matches |
| Sensitive screens FLAG_SECURE | Manual | App switcher shows blank on login/checkout |
| Session cookie not logged | Code review | Cookie value never in debug output |
| HTTPS enforced | Network config | cleartext blocked on Android, ATS on iOS |
| Input sanitization | Unit tests | XSS payloads in name/address don't break UI |
| Rate limit respected | Unit (AuthCubit) | App disables button on 429 |

---

## Performance Testing

| Metric | Target | How to Measure |
|--------|--------|---------------|
| Product grid scroll | 60fps (no jank) | Flutter DevTools → Performance overlay |
| App cold start | < 3s to first frame | `adb shell am start -W` |
| Product list load | < 2s (4G) | Network tab in DevTools |
| Image load (thumbnail) | < 1s (cached after first) | cached_network_image metrics |
| Memory usage | < 200MB peak | Flutter DevTools → Memory |
| APK size | < 30MB | `flutter build apk --analyze-size` |
| Cart operations | Instant (<50ms) | Local storage, no network |

### Performance Test Automation

```dart
// Measure frame rendering
testWidgets('product grid scrolls at 60fps', (tester) async {
  await tester.pumpWidget(app);
  await tester.pumpAndSettle();

  final timeline = await tester.traceAction(() async {
    await tester.fling(find.byType(ListView), Offset(0, -500), 1000);
    await tester.pumpAndSettle();
  });

  // Check for janky frames
  final summary = TimelineSummary.summarize(timeline);
  expect(summary.computeMissedFrameBudgetCount(), lessThan(5));
});
```

---

## Test File Organization

```
test/
├── fixtures/                       # JSON response fixtures
│   ├── products_list.json
│   ├── product_detail.json
│   └── ...
├── helpers/                        # Shared test utilities
│   ├── mocks.dart                  # All mocktail mocks
│   ├── pump_app.dart               # Test widget wrapper with providers
│   └── test_data.dart              # Factory methods for test models
├── core/
│   ├── network/
│   │   ├── api_client_test.dart
│   │   ├── auth_interceptor_test.dart
│   │   └── retry_interceptor_test.dart
│   └── utils/
│       ├── validators_test.dart
│       └── formatters_test.dart
├── features/
│   ├── auth/
│   │   ├── data/auth_repository_test.dart
│   │   └── presentation/auth_cubit_test.dart
│   ├── cart/
│   │   ├── data/cart_repository_test.dart
│   │   └── presentation/cart_cubit_test.dart
│   ├── checkout/
│   │   └── presentation/checkout_cubit_test.dart
│   ├── home/
│   │   └── presentation/home_cubit_test.dart
│   └── ...
└── widget/
    ├── product_card_test.dart
    ├── otp_input_test.dart
    └── status_pipeline_test.dart

integration_test/
├── guest_purchase_test.dart
├── auth_flow_test.dart
└── cart_management_test.dart
```

---

## CI Test Execution

```yaml
# Runs on every PR
test:
  steps:
    - flutter test --coverage
    - lcov --remove coverage/lcov.info 'lib/**.g.dart' -o coverage/clean.info
    - genhtml coverage/clean.info --output-directory coverage/html
    # Fail if coverage drops below threshold
    - check_coverage --min-coverage 70
```

### Test Run Frequency

| Test Type | When | Duration |
|-----------|------|----------|
| Unit tests | Every PR (CI) | < 2 min |
| Widget tests | Every PR (CI) | < 3 min |
| Integration tests | Before release (manual or nightly) | 10–15 min |
| Performance tests | Before release (manual) | 5 min |
| Security audit | Before release (manual) | 30 min |
