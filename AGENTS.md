# SoftStore Buyer App — AI Agent Instructions & Workspace Rules

Welcome to the **SoftStore Buyer App** repository. All AI agents operating in this workspace must adhere strictly to the guidelines and constraints outlined in this document.

---

## 1. Project Overview & Tech Stack

* **Application**: Flutter e-commerce mobile application for SoftStore Marketplace (Pakistan).
* **SDK / Language**: Dart ^3.11 / Flutter 3.x (Material 3).
* **State Management**: `flutter_bloc` / `bloc` (Cubit preferred for feature state, Bloc for complex event flows).
* **Routing / Navigation**: `go_router` (declarative routes in `lib/app/router.dart`).
* **Networking**: `dio` with cookie jar, custom interceptors (Auth, Logging, Retry), and CSRF token management.
* **Storage**: `hive_flutter` for caching / persistent data, `flutter_secure_storage` for sensitive tokens / credentials, `shared_preferences` for basic settings.
* **Testing**: `flutter_test`, `bloc_test`, `mocktail`.

---

## 2. Codebase Architecture & Structure

The codebase uses a **Feature-First Architecture** with a shared core:

```
lib/
├── app/                  # Application root widget, app lifecycle, routing (GoRouter)
├── core/                 # Shared foundation across all features
│   ├── config/           # Environment configuration & feature flags
│   ├── constants/        # API endpoints, storage keys, global app constants
│   ├── errors/           # Failure & Exception domain models
│   ├── network/          # Dio client, SoftStoreApiClient, interceptors
│   ├── storage/          # LocalStorage, SecureStorage, HiveService
│   ├── theme/            # Design tokens: AppColors, AppSpacing, AppTypography, AppDimensions, AppDurations, AppTheme
│   ├── utils/            # CSRF, HTML parsing, formatters, validators
│   └── widgets/          # 15+ shared reusable core UI widgets
└── features/             # Feature slices (auth, cart, catalog, checkout, home, orders, product, etc.)
    └── <feature_name>/
        ├── cubit/        # State management (Cubit + State with Equatable)
        ├── models/       # Data classes (JSON serialization, immutability)
        ├── repository/   # Data layer abstraction (API & Storage calls)
        ├── screens/      # Full-page view widgets
        ├── services/     # (Optional) Feature-specific API/network service
        └── widgets/      # Feature-specific sub-widgets
```

---

## 3. Mandatory Development Rules

### A. State Management & Logic
1. **Use Cubit/Bloc**: Do NOT introduce `Provider`, `Riverpod`, `GetX`, or raw `setState` for business logic across screens.
2. **Immutable States**: All state classes must extend `Equatable` with `@immutable` and implement `props`.
3. **Layer Separation**: Screens must never make direct API/Dio calls or Hive calls. UI -> Cubit -> Repository -> Service/Client.

### B. UI & Design System (Strict Invariants)
1. **Never Hardcode Visual Tokens**:
   * **Colors**: Use `AppColors.<color>` (or `Theme.of(context).colorScheme`). Never write `Color(0xFF...)`.
   * **Spacing / Padding**: Use `AppSpacing.<token>` or `AppSpacing.padding...`. Never write raw `EdgeInsets.all(16)`.
   * **Typography**: Use `AppTypography.<style>` (or `Theme.of(context).textTheme`). Never write inline `TextStyle(...)` with arbitrary font sizes.
   * **Dimensions & Radius**: Use `AppDimensions.<radius/size>`. Never write `BorderRadius.circular(14)`.
   * **Durations**: Use `AppDurations.<duration>` for animations.
2. **Reuse Core Widgets**: Check `lib/core/widgets/` before building custom buttons, loading spinners, input fields, error states, or empty states.

### C. Routing & Navigation
1. Use `context.go(...)` or `context.pushNamed(...)` via `GoRouter`.
2. Do NOT use legacy `Navigator.push(MaterialPageRoute(...))` unless handling an isolated modal sheet/dialog outside the router scope.

---

## 4. Git & Safety Guardrails

To protect against accidental code loss and merge conflicts across parallel developer branches:

1. **NO Destructive Git Commands**: Agents must NEVER run `git push`, `git push --force`, `git reset --hard`, `git clean -fd`, or switch/delete branches unless explicitly instructed by the user.
2. **Conventional Commits**: When asked to commit, use the standard format:
   ```
   <type>(<scope>): <short summary in imperative mood>

   [optional body explaining WHY]
   ```
   * Types: `feat`, `fix`, `refactor`, `style`, `docs`, `test`, `chore`.
   * Example: `feat(catalog): add filter by category and price range`
3. **Preserve Comments & Unrelated Code**: Do not delete existing comments, docstrings, or code outside the scope of your current task.
4. **Verification**: Always run `flutter analyze` or check for compilation/lint errors before concluding code changes.

---

## 5. Documentation References

For deep background and full specifications, reference the following repository docs:
* **Phase 3 Development Standards**: [`docs/buyer-app-analysis/standards/PHASE-3-DEVELOPMENT-STANDARDS.md`](file:///docs/buyer-app-analysis/standards/PHASE-3-DEVELOPMENT-STANDARDS.md)
* **UI Design System**: [`docs/buyer-app-analysis/standards/ui-design-system.md`](file:///docs/buyer-app-analysis/standards/ui-design-system.md)
* **API Endpoints Mapping**: [`docs/API_MAPPING.md`](file:///docs/API_MAPPING.md)
* **Git Workflow & Branching**: [`docs/buyer-app-analysis/research/16-git-workflow.md`](file:///docs/buyer-app-analysis/research/16-git-workflow.md)
* **Modular Agent Rules**: Located in `.agents/rules/`
