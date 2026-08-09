# Flutter Architecture & Project Structure

## Architecture Decision: Feature-First with Repository Pattern

### The Problem This Architecture Solves

Softstore has **38 screens** across **12 distinct feature areas** (auth, home, search, product detail, cart, checkout, orders, seller, profile, wishlist, notifications, support). Four developers will work simultaneously. The architecture must:

1. Let each dev work in isolation without merge conflicts
2. Keep related code together (a developer working on "orders" shouldn't hunt across 5 directories)
3. Enforce a clear API boundary (repositories) that's easy to mock in tests
4. Avoid over-abstraction — Softstore is a shopping app, not a framework

### Why Feature-First with Repository Pattern

**Recommendation:** Organize code by feature (each feature is a self-contained folder), with a **repository pattern** separating data access from UI logic.

**Why NOT full Clean Architecture (data/domain/presentation per feature):**

Clean Architecture adds a `domain/` layer with abstract repository interfaces, use cases, and entities separate from DTOs. For Softstore this is over-engineering because:
- The backend returns JSON → we parse it into models → we display it. There's rarely "business logic" that lives between the API and the UI. The pricing logic, stock validation, and commission calculation all happen server-side.
- Abstract repository interfaces add a file per repository that exists only to be mocked in tests. `mocktail` can mock concrete classes directly.
- Use case classes (e.g., `GetProductsUseCase` that just calls `repository.getProducts()`) add indirection without logic. They're justified when you compose multiple repositories — that's rare here.

**What we DO take from Clean Architecture:**
- **Repositories** as the boundary between "how we get data" and "what the UI does with it." Every API call or local storage read goes through a repository.
- **Unidirectional data flow:** UI → Cubit → Repository → API/Storage → Cubit → UI.
- **Models in the feature folder** — not in a global `models/` dump.

**Why NOT MVVM:**

MVVM maps well to two-way data binding (Android ViewModels, SwiftUI @Observable). Flutter's widget tree is already reactive — BLoC/Cubit provides the same separation with better tooling in Flutter. MVVM is viable but doesn't give us anything Cubit doesn't, while losing the Flutter-ecosystem advantages (DevTools BLoC inspector, `bloc_test`, established community patterns).

**Why NOT layer-first (all repositories in one folder, all screens in another):**

With 4 developers, layer-first means Dev A working on "orders" edits `lib/repositories/order_repository.dart` while Dev B edits `lib/repositories/product_repository.dart` — same directory, easy conflicts on barrel files. Feature-first: Dev A only touches `lib/features/orders/`, Dev B only touches `lib/features/products/`.

### Architecture Layers (Within Each Feature)

```
features/orders/
  ├── data/              ← HOW we get data (API calls, storage)
  │   └── order_repository.dart
  ├── models/            ← WHAT the data looks like (Dart classes)
  │   ├── order_model.dart
  │   └── order_item_model.dart
  └── presentation/      ← HOW we show data (screens, cubits, widgets)
      ├── order_history_screen.dart
      ├── order_detail_screen.dart
      ├── widgets/
      │   ├── status_pipeline.dart
      │   └── order_card.dart
      └── cubits/
          ├── order_history_cubit.dart
          └── order_detail_cubit.dart
```

**Rules:**
- `presentation/` depends on `models/` and calls into `data/` (via the repository instance provided through BlocProvider or dependency injection)
- `data/` depends on `models/` (it constructs them from JSON) and `core/network/` (the Dio client)
- `models/` depends on nothing (plain Dart classes with `fromJson`/`toJson`)
- **Cross-feature model access is allowed.** Cart needs `ProductModel`, Checkout needs `AddressModel`. Import from `features/products/models/` or `features/profile/models/`. This is fine — models are stable, small, and change rarely.
- **Cross-feature screen/cubit access is NOT allowed.** If checkout needs to display a product card, it imports the shared widget from `core/widgets/`, not from `features/products/presentation/`.

### Alternatives Considered

| Approach | Verdict | Why |
|----------|---------|-----|
| Feature-First + Repository | **CHOSEN** | Right scale for 38 screens, 4 devs, clear boundaries |
| Full Clean Architecture | Rejected | Too many layers for a CRUD shopping app with server-side logic |
| Layer-First (all repos together) | Rejected | Merge conflicts with 4 devs, hard to find related code |
| MVVM | Rejected | No advantage over Cubit in Flutter, less tooling support |
| No architecture (flat lib/) | Rejected | Unmaintainable past 10 screens |

---

## Project Structure

```
lib/
├── app/
│   ├── app.dart                        # MaterialApp.router, MultiBlocProvider for global cubits
│   ├── router.dart                     # GoRouter: all route definitions, guards, shell
│   └── theme.dart                      # ThemeData: colors, typography, component themes
│
├── core/
│   ├── constants/
│   │   ├── api_endpoints.dart          # All endpoint paths as static strings
│   │   ├── app_config.dart             # Delivery fee (199), free threshold (1500), etc.
│   │   ├── env_config.dart             # Environment config (from --dart-define)
│   │   ├── feature_flags.dart          # Compile-time feature toggles
│   │   └── storage_keys.dart           # SharedPreferences + SecureStorage key names
│   │
│   ├── errors/
│   │   └── failures.dart               # Typed failure classes (NetworkFailure, ServerFailure, etc.)
│   │
│   ├── extensions/
│   │   ├── context_extensions.dart     # BuildContext helpers (theme, mediaQuery, snackbar)
│   │   └── string_extensions.dart      # Capitalize, truncate, slug utilities
│   │
│   ├── network/
│   │   ├── api_client.dart             # Dio singleton factory with all interceptors
│   │   ├── auth_interceptor.dart       # Detects 401 → triggers session expired
│   │   ├── retry_interceptor.dart      # Auto-retry on timeout/5xx
│   │   └── connectivity_service.dart   # Stream<bool> for online/offline
│   │
│   ├── storage/
│   │   ├── secure_storage.dart         # flutter_secure_storage wrapper
│   │   └── local_storage.dart          # SharedPreferences wrapper
│   │
│   ├── theme/
│   │   ├── app_theme.dart              # ThemeData construction (light mode)
│   │   ├── app_colors.dart             # All color constants
│   │   ├── app_typography.dart         # TextStyle definitions
│   │   ├── app_spacing.dart            # EdgeInsets, gaps, padding constants
│   │   ├── app_dimensions.dart         # Border radius, elevation, sizes
│   │   └── app_durations.dart          # Animation durations
│   │
│   ├── utils/
│   │   ├── validators.dart             # Email, phone, password, name validators
│   │   └── formatters.dart             # PKR currency, Pakistani phone, date
│   │
│   └── widgets/
│       ├── product_card.dart           # Used in home, search, category, seller, wishlist
│       ├── loading_skeleton.dart       # Shimmer placeholder matching card layout
│       ├── error_state_widget.dart     # Message + retry button
│       ├── empty_state_widget.dart     # Illustration + message + CTA
│       ├── price_display.dart          # List price (strikethrough) + sale price + discount badge
│       ├── status_badge.dart           # Colored pill for order/return status
│       └── otp_input.dart              # 6-digit OTP boxes (used in register + checkout)
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart
│   │   ├── models/
│   │   │   └── user_model.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── login_screen.dart
│   │       │   ├── register_screen.dart
│   │       │   ├── forgot_password_screen.dart
│   │       │   └── otp_verification_screen.dart
│   │       └── cubits/
│   │           └── auth_cubit.dart         # Global — provided at app level
│   │
│   ├── home/
│   │   ├── data/
│   │   │   └── home_repository.dart        # Product list, categories
│   │   ├── models/
│   │   │   ├── product_model.dart          # Shared across features (list-level product)
│   │   │   └── category_model.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── home_screen.dart
│   │       ├── widgets/
│   │       │   ├── category_chips.dart
│   │       │   ├── product_grid.dart
│   │       │   └── filter_sort_sheet.dart
│   │       └── cubits/
│   │           └── home_cubit.dart
│   │
│   ├── search/
│   │   ├── data/
│   │   │   └── search_repository.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── search_screen.dart
│   │       └── cubits/
│   │           └── search_cubit.dart
│   │
│   ├── product_detail/
│   │   ├── data/
│   │   │   └── product_detail_repository.dart
│   │   ├── models/
│   │   │   ├── product_detail_model.dart   # Extended product (gallery, variants, reviews)
│   │   │   ├── variant_model.dart
│   │   │   ├── review_model.dart
│   │   │   └── pricing_model.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── product_detail_screen.dart
│   │       │   └── image_gallery_screen.dart
│   │       ├── widgets/
│   │       │   ├── variant_selector.dart
│   │       │   ├── reviews_section.dart
│   │       │   ├── seller_info_card.dart
│   │       │   └── related_products.dart
│   │       └── cubits/
│   │           └── product_detail_cubit.dart
│   │
│   ├── cart/
│   │   ├── data/
│   │   │   ├── cart_repository.dart        # Validation calls to server
│   │   │   └── cart_local_storage.dart     # SharedPreferences persistence
│   │   ├── models/
│   │   │   └── cart_item_model.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── cart_screen.dart
│   │       ├── widgets/
│   │       │   └── cart_item_tile.dart
│   │       └── cubits/
│   │           └── cart_cubit.dart         # Global — provided at app level
│   │
│   ├── checkout/
│   │   ├── data/
│   │   │   └── checkout_repository.dart    # OTP, coupon, place order
│   │   ├── models/
│   │   │   ├── checkout_state_model.dart   # Form data across steps
│   │   │   └── coupon_result_model.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── checkout_delivery_screen.dart
│   │       │   ├── checkout_verify_screen.dart
│   │       │   ├── checkout_review_screen.dart
│   │       │   └── order_confirmation_screen.dart
│   │       ├── widgets/
│   │       │   └── address_picker_sheet.dart
│   │       └── cubits/
│   │           └── checkout_cubit.dart
│   │
│   ├── orders/
│   │   ├── data/
│   │   │   └── order_repository.dart
│   │   ├── models/
│   │   │   ├── order_model.dart
│   │   │   ├── order_item_model.dart
│   │   │   ├── order_timeline_model.dart
│   │   │   └── return_model.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── order_history_screen.dart
│   │       │   ├── order_detail_screen.dart
│   │       │   ├── track_order_screen.dart
│   │       │   └── returns_list_screen.dart
│   │       ├── widgets/
│   │       │   ├── status_pipeline.dart
│   │       │   ├── order_timeline.dart
│   │       │   └── return_request_sheet.dart
│   │       └── cubits/
│   │           ├── order_history_cubit.dart
│   │           └── order_detail_cubit.dart
│   │
│   ├── seller/
│   │   ├── data/
│   │   │   └── seller_repository.dart
│   │   ├── models/
│   │   │   └── seller_model.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── seller_store_screen.dart
│   │       └── cubits/
│   │           └── seller_cubit.dart
│   │
│   ├── profile/
│   │   ├── data/
│   │   │   ├── profile_repository.dart
│   │   │   └── address_repository.dart
│   │   ├── models/
│   │   │   └── address_model.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   ├── profile_hub_screen.dart
│   │       │   ├── edit_profile_screen.dart
│   │       │   ├── address_book_screen.dart
│   │       │   ├── address_form_screen.dart
│   │       │   ├── change_password_screen.dart
│   │       │   └── settings_screen.dart
│   │       └── cubits/
│   │           ├── profile_cubit.dart
│   │           └── address_cubit.dart
│   │
│   ├── wishlist/
│   │   ├── data/
│   │   │   └── wishlist_repository.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── wishlist_screen.dart
│   │       └── cubits/
│   │           └── wishlist_cubit.dart
│   │
│   ├── notifications/
│   │   ├── data/
│   │   │   └── notification_repository.dart
│   │   ├── models/
│   │   │   └── notification_model.dart
│   │   └── presentation/
│   │       ├── screens/
│   │       │   └── notifications_screen.dart
│   │       └── cubits/
│   │           └── notifications_cubit.dart
│   │
│   └── support/
│       ├── data/
│       │   └── support_repository.dart
│       ├── models/
│       │   └── ticket_model.dart
│       └── presentation/
│           ├── screens/
│           │   ├── faq_screen.dart
│           │   ├── contact_screen.dart
│           │   ├── new_ticket_screen.dart
│           │   └── ticket_chat_screen.dart
│           └── cubits/
│               └── support_cubit.dart
│
└── main.dart                               # Entry point: runApp, Firebase init
```

---

## Placement Rules — Where Does This Go?

| Thing | Location | Reasoning |
|-------|----------|-----------|
| Screen (full page) | `features/{name}/presentation/screens/` | One screen = one file, named `{purpose}_screen.dart` |
| Feature-specific widget | `features/{name}/presentation/widgets/` | Only used within this feature |
| Shared widget (used in 2+ features) | `core/widgets/` | ProductCard is used in home, search, seller, wishlist |
| Model class | `features/{name}/models/` | Co-located with the feature that "owns" it |
| Model used across many features | Still in the owning feature's `models/` | Other features import it. ProductModel lives in `home/models/` |
| Repository (API calls) | `features/{name}/data/` | One repository per feature (sometimes two if logically distinct, e.g., profile + address) |
| Cubit (state) | `features/{name}/presentation/cubits/` | One cubit per screen or per logical concern |
| Global cubit (auth, cart) | Defined in feature folder, **provided** at `app.dart` level | AuthCubit is defined in `auth/`, but injected globally |
| Validators | `core/utils/validators.dart` | Shared across features (email, phone used everywhere) |
| Formatters | `core/utils/formatters.dart` | PKR, date, phone formatting is universal |
| API client (Dio) | `core/network/api_client.dart` | One instance, shared by all repositories |
| Route definitions | `app/router.dart` | Single file — all routes in one place for discoverability |
| Theme | `app/theme.dart` | One ThemeData, globally applied |
| Constants | `core/constants/` | Grouped by concern (API, config, storage keys) |
| Platform services | `core/network/`, `core/storage/` | Connectivity, secure storage, local storage |

### What Should NOT Go in `core/`

- Feature-specific widgets (a "seller info card" belongs in `product_detail/widgets/`, not `core/widgets/`)
- Feature-specific models (OrderModel belongs in `orders/models/`, not in a global `core/models/` dump)
- Feature-specific business logic
- Cubits (even global ones — they're defined in their feature folder)

`core/` is infrastructure: networking, storage, theming, formatting, and genuinely shared widgets (things used by 3+ features).

---

## Key Packages (Justified)

| Package | Purpose | Why We Need It | Alternative | Why Not Alternative |
|---------|---------|---------------|-------------|---------------------|
| `go_router` | Navigation | Deep linking, auth guards, StatefulShellRoute for bottom nav | auto_route | go_router is official Flutter team, simpler config, better deep link support |
| `flutter_bloc` | State management | Cubit pattern, excellent testability, DevTools | riverpod | BLoC more established in local community, strict patterns prevent misuse |
| `dio` | HTTP client | Interceptors (cookie, retry, auth), timeout config | http package | http has no interceptor chain, no cookie jar integration |
| `dio_cookie_manager` + `cookie_jar` | Cookie handling | Backend uses session cookies, must persist across restarts | — | No alternative; this is the only way to handle cookies with Dio |
| `flutter_secure_storage` | Sensitive storage | User profile cache, session metadata | — | Only option for encrypted key-value on both platforms |
| `shared_preferences` | Non-sensitive storage | Cart, preferences, recent searches | Hive | SharedPreferences is simpler for key-value; Hive adds complexity |
| `cached_network_image` | Image caching | Product images cached to disk, placeholder/error widgets | — | Standard choice, no viable alternative |
| `json_annotation` + `json_serializable` | Serialization | Type-safe fromJson/toJson with compile-time safety | freezed | freezed adds union types we don't need; json_serializable is lighter |
| `equatable` | Value equality | Cubit states need correct == for emit deduplication | — | Manual == override is error-prone |
| `connectivity_plus` | Network monitoring | Show offline banner, block checkout when offline | — | Standard choice |
| `google_sign_in` | OAuth | Backend supports Google login, native SDK required | — | Only option for native Google Sign-In |
| `url_launcher` | External links | WhatsApp deep links, email, browser | — | Standard choice |
| `share_plus` | Share sheet | Share product links (native sheet) | — | Standard choice |
| `firebase_messaging` | Push notifications | FCM for order updates (Phase 2) | — | Only option for cross-platform push |
| `firebase_core` | Firebase init | Required by firebase_messaging | — | — |
| `recaptcha_enterprise_flutter` | CAPTCHA | Backend requires reCAPTCHA on login/register | — | Only official package |

### Packages We Are NOT Using (and Why)

| Package | Why Not |
|---------|---------|
| `freezed` | Adds union type code generation. Our models are straightforward data classes. The build_runner time cost isn't justified. |
| `get_it` | Service locator. BlocProvider already handles DI for Cubits. Repositories are created in BlocProvider's `create:` callback. No global registry needed. |
| `injectable` | Code-gen for get_it. Same reason — we don't use get_it. |
| `dartz` (Either type) | Functional error handling. Adds learning curve. We use try/catch with typed failures — simpler for the team. |
| `retrofit` | Code-gen REST client. Our endpoints have varied response formats (some HTML fallback). Manual Dio calls in repositories give more control. |
| `hive` / `isar` | Local databases. Our only persistent data is cart (a JSON blob) and preferences (key-value). SharedPreferences suffices. |
| `auto_route` | Code-gen router. GoRouter is simpler, official, and handles our needs without code generation. |

---

## Development Conventions

| Rule | Rationale |
|------|-----------|
| One screen per file | Discoverability — `order_detail_screen.dart` is findable |
| One cubit per screen (usually) | Isolation — screen lifecycle matches cubit lifecycle |
| Repositories throw typed `Failure` subclasses | Cubits catch and emit error states without parsing DioExceptions |
| Models are immutable (`final` fields) | Prevents accidental mutation; Cubit states must be immutable |
| No business logic in screens | Screens call cubit methods; cubits call repositories |
| Screens never import Dio or SharedPreferences | All data access through repositories |
| File naming: `snake_case.dart` | Dart convention |
| Class naming: `PascalCase` | Dart convention |
| Cubit state classes: `sealed class {Feature}State` | Exhaustive pattern matching in UI |
