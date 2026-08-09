# Development Principles & Coding Conventions

## Task 8 — Dart & Flutter Coding Conventions

### Naming Conventions

| Thing | Convention | Example |
|-------|-----------|---------|
| Files | `snake_case.dart` | `product_detail_screen.dart` |
| Classes | `PascalCase` | `ProductDetailCubit` |
| Variables | `camelCase` | `selectedVariant` |
| Private variables | `_camelCase` | `_isLoading` |
| Functions/methods | `camelCase` | `loadProducts()` |
| Constants | `camelCase` (Dart convention) | `static const deliveryFee = 199.0` |
| Enums | `PascalCase` name, `camelCase` values | `OrderStatus.deliveryFailed` |
| Cubits | `{Feature}Cubit` | `CartCubit`, `HomeCubit` |
| States | `{Feature}{Status}` (sealed) | `HomeLoading`, `HomeLoaded`, `HomeError` |
| Models | `{Name}Model` | `ProductModel`, `OrderModel` |
| Repositories | `{Feature}Repository` | `ProductRepository`, `AuthRepository` |
| Widgets (screen) | `{Feature}{Purpose}Screen` | `OrderDetailScreen` |
| Widgets (component) | `{Purpose}` or `{Feature}{Purpose}` | `ProductCard`, `StatusBadge` |

### Widget Conventions

#### Stateless vs Stateful

| Use | When |
|-----|------|
| `StatelessWidget` | Widget has no mutable local state (most screens using BLoC) |
| `StatefulWidget` | Widget has ephemeral UI state: text controllers, animation controllers, focus nodes, toggle booleans, page controllers |

**Rule:** A screen that uses only `BlocBuilder`/`BlocListener` with no local controllers should be `StatelessWidget`.

#### Widget Extraction

Extract a widget into its own class when:
- The `build()` method exceeds ~80 lines
- A chunk of UI is repeated 2+ times in the same file
- A chunk needs its own `StatefulWidget` lifecycle (controllers, listeners)

Do NOT extract:
- Every 10-line chunk into a method (makes reading harder, not easier)
- Widgets used only once that have no state (just leave them inline)

**Naming extracted widgets:**
```dart
// Private class in the same file (used only in this screen)
class _ProductImageGallery extends StatefulWidget { ... }

// Public class in widgets/ folder (used by multiple screens in the feature)
class VariantSelector extends StatelessWidget { ... }
```

#### Build Method Complexity

- A single `build()` should be understandable in one read (no scrolling past the screen)
- If you need more than 2 levels of nesting beyond `Scaffold`, extract
- Use `switch` expressions for state handling (not nested `if` chains)

### Architecture Conventions (Dependency Direction)

```
UI (Screens, Widgets)
  │ reads state via BlocBuilder
  │ triggers actions via cubit.method()
  ▼
State Management (Cubits)
  │ calls repository methods
  │ emits new states
  ▼
Repository (Data layer)
  │ calls Dio for API
  │ calls LocalStorage for cache
  │ maps raw JSON → models
  │ maps DioException → typed Failure
  ▼
Network / Storage (Infrastructure)
  │ Dio HTTP client
  │ SharedPreferences
  │ SecureStorage
  ▼
External (Backend API, Device)
```

**Rules:**
- UI never imports Dio, SharedPreferences, or any infrastructure directly
- Cubits never import Flutter widgets (no `BuildContext` in cubits)
- Repositories throw `Failure` subclasses, never raw `DioException`
- Models never import infrastructure (they're plain Dart classes)
- Cross-feature imports: only models (e.g., Cart imports `ProductModel`). Never import another feature's cubit or screen.

---

## Task 9 — Code Organization Rules

### Size Limits

| Thing | Guideline | If Exceeded |
|-------|-----------|-------------|
| File | < 300 lines | Split into multiple files in same folder |
| Class | < 200 lines | Extract helper classes or mixins |
| `build()` method | < 80 lines | Extract widget classes |
| Cubit | < 150 lines | Split into multiple cubits (one per screen) |
| Repository | < 200 lines | Split by concern (e.g., `profile_repository` + `address_repository`) |

These are guidelines, not hard rules. A 310-line file is fine if it's readable. A 50-line file with 10 dependencies is worse than a 300-line self-contained one.

### When to Split Files

- A file has 2+ public classes → split (Dart convention: one public class per file)
- A widget file has the screen + 3 extracted widgets → move extracted widgets to `widgets/` subfolder
- A cubit grows to handle 2 unrelated screens → two cubits

### When to Create a Shared Component

Create in `core/widgets/` when:
- Used in **3+ different features** (not just 3 places in one feature)
- Has a stable, simple interface (< 6 required props)
- Behavior is generic (not tied to one model or one business rule)

### When NOT to Create a Shared Component

- Used in only 1–2 features → keep it in the feature's `widgets/` folder
- Requires passing 5+ callbacks → it's feature-specific UI, not a generic component
- The "shared" version would need a big `switch` on feature type → wrong abstraction

### Import Organization

Order (enforced by linter):

```dart
// 1. Dart SDK
import 'dart:async';

// 2. Flutter SDK
import 'package:flutter/material.dart';

// 3. Third-party packages
import 'package:flutter_bloc/flutter_bloc.dart';

// 4. Project imports (relative)
import '../../../core/theme/app_colors.dart';
import '../cubits/home_cubit.dart';
import '../widgets/product_grid.dart';
```

**Rule:** Use relative imports within the same feature. Use package imports for cross-feature references:
```dart
// Within features/home/
import '../cubits/home_cubit.dart';  // relative

// From features/cart/ importing a model from features/home/
import 'package:softstore_buyer_app/features/home/models/product_model.dart';  // absolute
```

### Where Things Go

| Thing | Location | NOT Here |
|-------|----------|----------|
| Business logic (pricing, validation rules) | Cubit or Repository | NOT in `build()`, NOT in widget callbacks |
| Input validation (email format, phone format) | `core/utils/validators.dart` | NOT inline in form widgets |
| API calls | Repository | NOT in cubits, NOT in screens |
| Number/date/currency formatting | `core/utils/formatters.dart` | NOT inline where displayed |
| UI-only logic (show/hide, animation triggers) | Widget state (`StatefulWidget`) | NOT in cubit (cubit doesn't know about UI layout) |
| Constants (delivery fee, free threshold) | `core/constants/app_config.dart` | NOT scattered across files |
| Route paths | `app/router.dart` | NOT as strings in feature code |
| Storage keys | `core/constants/storage_keys.dart` | NOT as strings in repositories |

---

## Task 10 — Error Handling & Logging

### Exception Flow

```
API returns error
  → Dio throws DioException
    → Repository catches DioException
      → Repository throws typed Failure (NetworkFailure, ServerFailure, etc.)
        → Cubit catches Failure
          → Cubit emits error state with user-friendly message
            → UI renders ErrorStateWidget or shows snackbar
```

**Never let raw exceptions reach the UI.** Every repository method wraps its API call in try/catch.

### Failure Classes (defined in `core/errors/failures.dart`)

```dart
sealed class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure { ... }
class TimeoutFailure extends Failure { ... }
class ServerFailure extends Failure { ... }
class ValidationFailure extends Failure { ... }
class AuthFailure extends Failure { ... }
class RateLimitFailure extends Failure { ... }
class NotFoundFailure extends Failure { ... }
```

### User-Facing Messages

| Error Type | User Sees | They Do NOT See |
|------------|-----------|-----------------|
| Network | "No internet connection" | `SocketException: OS Error` |
| Timeout | "Connection timed out. Try again." | `DioException [CONNECT_TIMEOUT]` |
| Server 500 | "Something went wrong. Try again." | Stack trace, SQL error |
| Validation | "Enter a valid email address" | `422 Unprocessable Entity` |
| 401 | (silent redirect to login) | "Unauthenticated" |
| 429 | "Too many attempts. Please wait." | `429 Too Many Requests` |
| Unknown | "Something went wrong. Try again." | Exception class name |

### Logging

#### Debug Mode (development)

```dart
// Dio LogInterceptor (already in interceptor stack)
// Logs: request URL, headers, body, response status, response body
// Only active when kDebugMode == true
LogInterceptor(
  requestBody: kDebugMode,
  responseBody: kDebugMode,
  logPrint: (msg) => debugPrint(msg.toString()),
)
```

```dart
// BlocObserver (already in app setup)
class AppBlocObserver extends BlocObserver {
  @override
  void onChange(BlocBase bloc, Change change) {
    debugPrint('${bloc.runtimeType}: ${change.currentState.runtimeType} → ${change.nextState.runtimeType}');
  }
  @override
  void onError(BlocBase bloc, Object error, StackTrace stackTrace) {
    debugPrint('${bloc.runtimeType} ERROR: $error');
  }
}
```

#### Production Mode

- **No** `print()` or `debugPrint()` in production code
- **No** sensitive data in any log (no passwords, no email content, no cookie values)
- **No** Dio response body logging in release
- Future: Firebase Crashlytics for unhandled exceptions (Phase 2)

#### Rules

1. Never use `print()` — use `debugPrint()` (and only in debug mode)
2. Never log PII (emails, phone numbers, addresses)
3. Never log authentication tokens or cookies
4. Cubit state transitions are logged by BlocObserver automatically — no manual logging needed
5. If you need temporary debugging, use `debugPrint` + remove before PR

---

## Task 11 — Comments & Documentation

### When to Write Comments

Write a comment ONLY when:

| Situation | Example |
|-----------|---------|
| Non-obvious business rule | `// Free delivery threshold: server uses >= 1500, not > 1500` |
| Backend quirk | `// Backend returns HTML on session expiry, not JSON — check content-type` |
| Why something is intentionally different | `// Using 15s timeout here because this endpoint triggers an email send` |
| Workaround with ticket reference | `// Workaround for B2: session cart lost on expiry — we use local cart instead` |
| Complex regex/algorithm | `// Matches Pakistani phone: 03XX-XXXXXXX (11 digits starting with 03)` |

### When NOT to Write Comments

| Don't | Why |
|-------|-----|
| `// Get products from API` above `getProducts()` | Method name already says this |
| `// Navigate to product detail` above `context.go('/product/$slug')` | Code is self-explanatory |
| `// This cubit manages home state` | File is named `home_cubit.dart` |
| `// Added for checkout flow` | Belongs in commit message, not code |
| `// TODO: refactor later` without a ticket | Creates permanent debt nobody tracks |

### Documentation for Shared Components

Shared components in `core/widgets/` should have a brief doc comment explaining usage:

```dart
/// Cached network image with shimmer loading and error fallback.
///
/// Use instead of raw Image.network or CachedNetworkImage.
class AppImage extends StatelessWidget { ... }
```

One or two lines. Not a paragraph. Not a usage example (that's in `shared-components.md`).

### TODOs

If you must leave a TODO:
```dart
// TODO(naheed): Handle partial returns when B4 is fixed — see 19-risks-open-questions.md
```

Format: `TODO(owner): description + reference`. A TODO without an owner is never resolved.

---

## Task 13 — Development Principles

### DO

1. **Follow the architecture.** Cubit → Repository → API. No shortcuts.
2. **Use the design system.** `AppColors.primary`, not `Color(0xFFFF6F00)`.
3. **Use shared components.** Check `core/widgets/` before building a new button/card/dialog.
4. **Handle all 3 states.** Every data screen must have loading, error, and empty states. No exceptions.
5. **Keep features isolated.** Your cubit never imports another feature's cubit.
6. **Format prices consistently.** Use `AppFormatters.currency(amount)`, not string interpolation.
7. **Validate at the boundary.** Repository validates API response shape. Form validates before submit.
8. **Test cubit logic.** Every cubit gets `blocTest` coverage for success, error, and edge cases.
9. **Keep commits focused.** One commit = one logical change. Not "fixed stuff" or "updates".
10. **Use constants.** Delivery fee, free threshold, OTP length — all from `app_config.dart`.
11. **Lock orientation.** Portrait only. Set in `main.dart`, never override per-screen.
12. **Respect the type system.** Use `OrderStatus` enum, not string comparisons.

### DON'T

1. **Don't hardcode colors.** No `Color(...)` or `Colors.orange` in feature code.
2. **Don't hardcode API URLs.** No `/api/store/products` strings in repositories — use `ApiEndpoints.products`.
3. **Don't put API calls in widgets.** No Dio in `build()` or `onPressed`.
4. **Don't duplicate components.** If a button exists in `core/widgets/`, use it. Don't make a new one.
5. **Don't put logic in `build()`.** Compute in cubit, display in widget.
6. **Don't create giant files.** If a file passes 300 lines, it needs splitting.
7. **Don't add packages without discussion.** New dependencies need team agreement.
8. **Don't modify another dev's feature without telling them.** Cross-feature changes need a heads-up.
9. **Don't ignore error states.** "It works when the API responds" is not done.
10. **Don't use `print()`.** Use `debugPrint()` in development, nothing in production.
11. **Don't store secrets in code.** API keys, site keys → environment config, not source.
12. **Don't use magic numbers.** `if (items.length >= 5)` → `if (items.length >= AppConfig.lowStockThreshold)`.
13. **Don't skip the linter.** Fix warnings before committing. Don't suppress without a comment explaining why.
14. **Don't use `dynamic`.** Type everything. If the API shape is unknown, define the model.
15. **Don't nest BlocBuilders 3+ deep.** Use `MultiBlocListener` or split the widget.
