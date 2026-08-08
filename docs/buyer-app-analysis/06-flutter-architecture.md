# Phase 3: Flutter Architecture

## Architecture Choice: Feature-First Clean Architecture

**Decision:** Hybrid of **Feature-First** organization with **Clean Architecture** layers within each feature.

### Why This Combination

| Criterion | Feature-First + Clean | Pure Clean (layer-first) | MVVM | Repository-only |
|-----------|----------------------|--------------------------|------|-----------------|
| Team development | Each dev owns a feature folder | Devs touch all layer folders | Good | Good |
| Scalability | Add features without touching existing | Layer folders grow huge | Good | Limited |
| Maintainability | Related code is co-located | Hunt across 4 directories | Good | Scatters logic |
| Testability | Mock at repository boundary | Same | Same | No clear boundary |
| Separation of concerns | 3 layers enforced per feature | Same | 2 layers | 1 layer |
| Learning curve | Moderate | High (over-abstracted for small teams) | Low | Low |
| Fits Softstore scale | 38 screens, 11 feature areas | Overkill folder depth | Viable | Too flat |

### Architecture Layers (Per Feature)

```
feature/
  ├── data/           ← Repositories, API calls, local storage, DTOs
  ├── domain/         ← Models (entities), business logic (if any)
  └── presentation/   ← Screens, widgets, state (Cubits/providers)
```

**Rules:**
- `presentation` depends on `domain` (never directly on `data`)
- `data` implements interfaces defined in `domain` (repository contracts)
- `domain` has zero dependencies on Flutter or external packages
- Cross-feature communication goes through shared services (auth, cart)

---

## Folder Structure

```
lib/
├── app/
│   ├── app.dart                    # MaterialApp.router setup
│   ├── router.dart                 # GoRouter configuration
│   └── theme.dart                  # ThemeData (orange/amber palette)
│
├── core/
│   ├── constants/
│   │   ├── api_constants.dart      # Base URL, endpoints
│   │   ├── app_constants.dart      # Delivery fee, free threshold, etc.
│   │   └── storage_keys.dart       # SharedPreferences / secure storage keys
│   ├── errors/
│   │   ├── failures.dart           # Failure classes (network, server, auth)
│   │   └── exceptions.dart         # Exception types
│   ├── network/
│   │   ├── api_client.dart         # Dio instance, interceptors
│   │   ├── csrf_interceptor.dart   # CSRF token fetch + inject
│   │   └── auth_interceptor.dart   # Session cookie handling, 401 redirect
│   ├── utils/
│   │   ├── validators.dart         # Form validation helpers
│   │   ├── formatters.dart         # PKR currency, date, phone formatting
│   │   └── extensions.dart         # String, context extensions
│   └── widgets/
│       ├── product_card.dart       # Reusable product grid card
│       ├── loading_skeleton.dart   # Shimmer placeholder
│       ├── error_state.dart        # Error + retry widget
│       ├── empty_state.dart        # Empty + CTA widget
│       └── price_display.dart      # List/sale price with discount badge
│
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── auth_repository.dart
│   │   │   └── auth_local_storage.dart
│   │   ├── domain/
│   │   │   ├── user_model.dart
│   │   │   └── auth_repository_interface.dart
│   │   └── presentation/
│   │       ├── login_screen.dart
│   │       ├── register_screen.dart
│   │       ├── forgot_password_screen.dart
│   │       ├── otp_verification_screen.dart
│   │       └── auth_cubit.dart
│   │
│   ├── home/
│   │   ├── data/
│   │   │   └── product_repository.dart
│   │   ├── domain/
│   │   │   ├── product_model.dart
│   │   │   └── category_model.dart
│   │   └── presentation/
│   │       ├── home_screen.dart
│   │       ├── widgets/
│   │       │   ├── product_grid.dart
│   │       │   └── category_chips.dart
│   │       └── home_cubit.dart
│   │
│   ├── search/
│   │   ├── data/
│   │   │   └── search_repository.dart
│   │   ├── domain/
│   │   │   └── search_model.dart
│   │   └── presentation/
│   │       ├── search_screen.dart
│   │       └── search_cubit.dart
│   │
│   ├── product_detail/
│   │   ├── data/
│   │   │   └── product_detail_repository.dart
│   │   ├── domain/
│   │   │   ├── product_detail_model.dart
│   │   │   ├── variant_model.dart
│   │   │   └── review_model.dart
│   │   └── presentation/
│   │       ├── product_detail_screen.dart
│   │       ├── widgets/
│   │       │   ├── image_gallery.dart
│   │       │   ├── variant_selector.dart
│   │       │   ├── reviews_section.dart
│   │       │   └── seller_card.dart
│   │       └── product_detail_cubit.dart
│   │
│   ├── cart/
│   │   ├── data/
│   │   │   ├── cart_repository.dart
│   │   │   └── cart_local_storage.dart
│   │   ├── domain/
│   │   │   ├── cart_model.dart
│   │   │   └── cart_item_model.dart
│   │   └── presentation/
│   │       ├── cart_screen.dart
│   │       ├── widgets/
│   │       │   └── cart_item_tile.dart
│   │       └── cart_cubit.dart
│   │
│   ├── checkout/
│   │   ├── data/
│   │   │   └── checkout_repository.dart
│   │   ├── domain/
│   │   │   └── checkout_model.dart
│   │   └── presentation/
│   │       ├── checkout_delivery_screen.dart
│   │       ├── checkout_verify_screen.dart
│   │       ├── checkout_review_screen.dart
│   │       ├── order_confirmation_screen.dart
│   │       └── checkout_cubit.dart
│   │
│   ├── orders/
│   │   ├── data/
│   │   │   └── order_repository.dart
│   │   ├── domain/
│   │   │   ├── order_model.dart
│   │   │   └── order_item_model.dart
│   │   └── presentation/
│   │       ├── order_history_screen.dart
│   │       ├── order_detail_screen.dart
│   │       ├── track_order_screen.dart
│   │       ├── return_request_sheet.dart
│   │       └── orders_cubit.dart
│   │
│   ├── seller/
│   │   ├── data/
│   │   │   └── seller_repository.dart
│   │   ├── domain/
│   │   │   └── seller_model.dart
│   │   └── presentation/
│   │       ├── seller_store_screen.dart
│   │       └── seller_cubit.dart
│   │
│   ├── profile/
│   │   ├── data/
│   │   │   ├── profile_repository.dart
│   │   │   └── address_repository.dart
│   │   ├── domain/
│   │   │   ├── address_model.dart
│   │   │   └── profile_model.dart
│   │   └── presentation/
│   │       ├── profile_hub_screen.dart
│   │       ├── edit_profile_screen.dart
│   │       ├── address_book_screen.dart
│   │       ├── address_form_screen.dart
│   │       ├── change_password_screen.dart
│   │       ├── settings_screen.dart
│   │       └── profile_cubit.dart
│   │
│   ├── wishlist/
│   │   ├── data/
│   │   │   └── wishlist_repository.dart
│   │   ├── domain/
│   │   │   └── wishlist_item_model.dart
│   │   └── presentation/
│   │       ├── wishlist_screen.dart
│   │       └── wishlist_cubit.dart
│   │
│   ├── notifications/
│   │   ├── data/
│   │   │   └── notification_repository.dart
│   │   ├── domain/
│   │   │   └── notification_model.dart
│   │   └── presentation/
│   │       ├── notifications_screen.dart
│   │       └── notifications_cubit.dart
│   │
│   └── support/
│       ├── data/
│       │   └── support_repository.dart
│       ├── domain/
│       │   └── ticket_model.dart
│       └── presentation/
│           ├── new_ticket_screen.dart
│           ├── ticket_chat_screen.dart
│           └── support_cubit.dart
│
├── shared/
│   ├── services/
│   │   ├── session_service.dart        # Cookie jar, session state
│   │   ├── csrf_service.dart           # CSRF token management
│   │   ├── connectivity_service.dart   # Network status monitoring
│   │   └── analytics_service.dart      # Event tracking
│   └── providers/
│       └── service_providers.dart      # DI registration
│
└── main.dart                           # Entry point, provider setup
```

---

## Dependency Rules

```
┌─────────────────────────────────────────┐
│            presentation                  │
│  (screens, widgets, cubits)             │
│         depends on ↓                     │
├─────────────────────────────────────────┤
│              domain                      │
│  (models, repository interfaces)        │
│         depends on ↓                     │
├─────────────────────────────────────────┤
│               data                       │
│  (repository impl, API, local storage)  │
│         depends on ↓                     │
├─────────────────────────────────────────┤
│               core                       │
│  (network, errors, constants, utils)    │
└─────────────────────────────────────────┘
```

**Cross-feature access:** Features may import another feature's `domain/` models (e.g., `cart` imports `product_detail/domain/product_model.dart`). Features NEVER import another feature's `data/` or `presentation/`.

---

## Key Packages

| Package | Purpose | Justification |
|---------|---------|---------------|
| `go_router` | Navigation | Deep linking, guards, shell routes |
| `flutter_bloc` | State management | Cubits for feature state |
| `dio` | HTTP client | Interceptors for cookies, CSRF, timeouts |
| `dio_cookie_manager` + `cookie_jar` | Cookie persistence | Session-based auth requires persistent cookies |
| `flutter_secure_storage` | Secure token/session storage | Stores sensitive session data |
| `shared_preferences` | Non-sensitive local storage | Cart, recent searches, preferences |
| `cached_network_image` | Image caching | Product images, avoid re-downloads |
| `json_annotation` + `json_serializable` | JSON serialization | Type-safe model parsing |
| `equatable` | Value equality | For Cubit state comparison |
| `firebase_messaging` | Push notifications | FCM integration |
| `google_sign_in` | Google OAuth | Native sign-in flow |
| `recaptcha_enterprise_flutter` | reCAPTCHA | Invisible widget for login/register |
| `url_launcher` | External links | WhatsApp, email, browser |
| `share_plus` | Native share | Share product links |
| `connectivity_plus` | Network monitoring | Offline detection |

---

## Development Conventions

| Convention | Rule |
|-----------|------|
| File naming | `snake_case.dart` |
| Class naming | `PascalCase` |
| Feature boundary | Each feature folder is self-contained |
| State class | One Cubit per screen (or per complex widget) |
| Model immutability | All models use `final` fields + `copyWith` |
| Error handling | Repository returns `Either<Failure, T>` or throws typed exceptions caught by Cubit |
| Testing | Unit tests in `test/features/{name}/`, widget tests alongside |
| Linting | `flutter_lints` + custom rules in `analysis_options.yaml` |
