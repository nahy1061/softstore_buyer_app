# Rule: Flutter Architecture & Code Organization

This rule defines the architectural standards for the SoftStore Buyer App codebase.

## 1. Feature Slice Structure

Every feature slice in `lib/features/<feature>/` must strictly adhere to the following file layout:

```
lib/features/<feature_name>/
├── cubit/
│   ├── <feature>_cubit.dart
│   └── <feature>_state.dart
├── models/
│   └── <feature>_models.dart
├── repository/
│   └── <feature>_repository.dart
├── screens/
│   └── <feature>_screen.dart
├── services/                 # Optional: Direct API endpoint mapping if not in repository
│   └── <feature>_service.dart
└── widgets/                  # Feature-private reusable UI components
    └── <feature>_<widget_name>.dart
```

## 2. Layer Responsibilities & Rules

1. **Models (`models/`)**:
   * Must be immutable with `final` fields.
   * Provide `factory <Model>.fromJson(Map<String, dynamic> json)` and `Map<String, dynamic> toJson()`.
   * Implement value equality using `Equatable` or custom `operator ==` / `hashCode`.
   * Provide `copyWith()` methods for updating model instances cleanly.

2. **Repository (`repository/`)**:
   * Encapsulates all data access logic (calling `DioClient`, `SoftStoreApiClient`, `HiveService`, or `SecureStorage`).
   * Catches low-level exceptions and transforms them into domain `Failure` objects (e.g. `ServerFailure`, `NetworkFailure`, `CacheFailure` from `lib/core/errors/failures.dart`).
   * Returns domain models or `Result`/`Either`-style responses, never raw Dio `Response` or JSON maps.

3. **State Management (`cubit/`)**:
   * Extend `Cubit<<Feature>State>`.
   * Cubit methods trigger state transitions via `emit(state.copyWith(...))`.
   * Cubit must NOT contain UI code or Flutter `BuildContext`.
   * States must represent UI statuses cleanly: `initial`, `loading`, `success`, `failure`, `empty`.

4. **Screens & UI (`screens/` & `widgets/`)**:
   * Must be declarative and reactive using `BlocBuilder`, `BlocListener`, or `BlocConsumer`.
   * Must NOT instantiate repositories directly; retrieve them via constructor or dependency injection.
   * UI components must remain thin, delegating all user interactions to Cubit methods.
