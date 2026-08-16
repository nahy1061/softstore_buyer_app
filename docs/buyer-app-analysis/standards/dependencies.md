# Dependencies

## Production Dependencies

| Package | Purpose | Why We Need It | Alternatives Considered | Why Not Alternative |
|---------|---------|---------------|------------------------|---------------------|
| `flutter_bloc` ^8.1 | State management | Cubit pattern for all feature state + global auth/cart state. Provides BlocProvider (DI), BlocBuilder (reactive UI), BlocListener (side effects), bloc_observer (debugging). | Riverpod, Provider, GetX | See `07-state-management.md` — BLoC has strictest patterns, best team discipline |
| `go_router` ^14.0 | Navigation | Declarative routing with deep linking, auth guards via `redirect:`, `StatefulShellRoute` for bottom nav with state preservation per tab. | auto_route, raw Navigator 2.0 | auto_route requires code-gen; raw Navigator 2.0 is 200+ lines of boilerplate |
| `dio` ^5.4 | HTTP client | Interceptor chain for: cookie management, 401 detection, retry on timeout/5xx, request logging. `BaseOptions` for timeouts. | `http` package | `http` has no interceptor architecture, no cookie jar integration, no retry mechanism |
| `dio_cookie_manager` ^3.1 | Cookie interceptor | Attaches/reads cookies on every request. Required because Softstore backend uses session cookies, not bearer tokens. | — | Only option for Dio cookie integration |
| `cookie_jar` ^4.0 | Cookie persistence | `PersistCookieJar` saves cookies to disk. Session survives app restarts without re-login (within 8h expiry). | — | Required by dio_cookie_manager |
| `flutter_secure_storage` ^9.0 | Encrypted storage | Stores cached user profile (PII: name, email). Uses Keychain (iOS) / EncryptedSharedPreferences (Android). | — | Only cross-platform encrypted key-value store |
| `shared_preferences` ^2.2 | Key-value storage | Cart (JSON string), recent searches, onboarding flag, theme preference, FCM token. Non-sensitive data. | Hive, Isar | Hive/Isar are databases — overkill for simple key-value. SharedPreferences is simpler, zero setup. |
| `cached_network_image` ^3.3 | Image caching | Product images cached to disk (200MB limit, LRU eviction). Shows shimmer placeholder while loading, error widget on failure. | — | Standard choice, no viable alternative for Flutter |
| `json_annotation` ^4.8 | Model annotations | `@JsonSerializable()`, `@JsonKey()` on model classes. Enables compile-time-safe fromJson/toJson generation. | freezed | freezed adds union types + immutable copyWith we don't need (our models are already simple final-field classes) |
| `json_serializable` ^6.7 | Code generation | Generates `_$ModelFromJson()` and `_$ModelToJson()` at build time. Eliminates manual JSON parsing errors. | Manual parsing | Manual parsing is error-prone for 17 model classes with 5–19 fields each |
| `equatable` ^2.0 | Value equality | Cubit states need correct `==` to prevent redundant rebuilds. Without equatable, every `emit()` triggers a rebuild even if the state hasn't changed. | Manual == override | Manual override on 20+ state classes is tedious and error-prone |
| `connectivity_plus` ^6.0 | Network monitoring | Stream of connectivity changes. Drives the "You're offline" banner and blocks checkout when no network. | — | Standard choice, maintained by Flutter Community |
| `google_sign_in` ^6.2 | OAuth | Native Google Sign-In flow. Returns ID token that backend verifies. Required because backend supports Google OAuth for buyers. | — | Only option for native Google Sign-In on Flutter |
| `firebase_core` ^3.0 | Firebase base | Required initialization before any Firebase service (messaging). | — | Required |
| `firebase_messaging` ^15.0 | Push notifications | FCM token registration, foreground/background message handling, notification tap navigation. Phase 2 but configured early. | OneSignal | FCM is free, standard, and backend will integrate with Firebase Admin SDK |
| `recaptcha_enterprise_flutter` ^18.0 | CAPTCHA | Invisible reCAPTCHA widget generates token for login/register. Backend validates with Google. Required — backend enforces captcha. | — | Only official Flutter package for reCAPTCHA Enterprise |
| `url_launcher` ^6.2 | External links | Opens WhatsApp (`wa.me/{number}`), email, browser. Product detail has "WhatsApp seller" button. | — | Standard choice |
| `share_plus` ^9.0 | Share sheet | Native share dialog for product links. Users share products via WhatsApp/SMS. | — | Standard choice |

## Dev Dependencies

| Package | Purpose | Why We Need It |
|---------|---------|---------------|
| `build_runner` ^2.4 | Code generation | Runs json_serializable generator. Command: `dart run build_runner build` |
| `bloc_test` ^9.0 | Cubit testing | `blocTest()` utility — tests state transitions without widget tree |
| `mocktail` ^1.0 | Mocking | Mock repositories in cubit tests. Simpler API than mockito (no code-gen). |
| `flutter_test` (SDK) | Widget testing | Widget tests for shared components |
| `integration_test` (SDK) | E2E testing | Full-flow tests on device/emulator |
| `flutter_lints` ^4.0 | Linting | Enforces Dart style, catches common errors |

## Packages We Are NOT Using

| Package | Why Not |
|---------|---------|
| `freezed` | Adds union types and immutable `copyWith`. Our models are straightforward `@JsonSerializable` classes with final fields. The build_runner time cost for freezed's code-gen isn't justified when json_serializable already handles serialization. |
| `get_it` | Service locator for DI. We don't need it — `BlocProvider` handles cubit injection, and repositories are created inline in `BlocProvider.create()`. Adding get_it adds a global registry that's harder to reason about. |
| `injectable` | Code-gen for get_it. Same reason — we don't use get_it. |
| `dartz` | Functional programming (Either, Option). Adds a learning curve for the team. We use try/catch with typed `Failure` classes — same safety, more familiar pattern. |
| `retrofit` | Generates REST client from annotations. Our API has varied response shapes and some endpoints may return HTML (session expired). Manual Dio calls in repositories give more control for error handling. |
| `hive` | NoSQL local database. Our persistent data is just cart (one JSON blob) and preferences (10 key-value pairs). SharedPreferences handles both without the overhead of a database engine. |
| `isar` | Same as Hive — database-level storage not needed. |
| `sqflite` | SQLite database. Same reasoning. No relational queries needed locally. |
| `auto_route` | Code-gen router. Requires build_runner and generates route files. GoRouter achieves the same without code-gen. |
| `provider` | Superseded by BLoC for our use case. Would still need a state management layer on top. |
| `getx` | See state management doc — global singletons, poor testability, declining confidence. |
| `flutter_hooks` | React-style hooks for widgets. Adds a new paradigm the team must learn. Standard StatefulWidget + Cubit covers all our needs. |
| `riverpod` | Excellent but code-gen heavy and less familiar to the team. See state management doc. |

## Version Pinning Strategy

- Use caret syntax (`^X.Y.Z`) for all packages — allows patch updates
- Run `flutter pub upgrade --major-versions` monthly to stay current
- Lock `pubspec.lock` in git — all developers use identical versions
- Test after every upgrade before merging
