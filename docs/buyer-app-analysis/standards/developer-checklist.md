# Developer Checklist

Use this checklist before marking any feature or task as complete.

---

## Architecture

- [ ] Code is in the correct feature folder (`features/{name}/`)
- [ ] Code is in the correct layer (`data/`, `models/`, `presentation/`)
- [ ] No dependency violations (UI doesn't import Dio; Cubit doesn't import Flutter widgets)
- [ ] Cross-feature imports are models only (no importing another feature's cubit or screen)
- [ ] Repository handles all API calls (no Dio in cubits or screens)
- [ ] Cubit handles all business logic (no logic in `build()` methods)

## Design System & UI

- [ ] Uses `AppColors` — no hardcoded `Color(...)` or `Colors.x`
- [ ] Uses `AppTypography` — no hardcoded `TextStyle(fontSize: ...)`
- [ ] Uses `AppSpacing` — no hardcoded `EdgeInsets.all(16)` (use constants)
- [ ] Uses `AppDimensions` — no hardcoded `BorderRadius.circular(...)`
- [ ] Uses shared components from `core/widgets/` where applicable
- [ ] Loading state handled (skeleton or spinner)
- [ ] Error state handled (ErrorStateWidget or snackbar)
- [ ] Empty state handled (EmptyStateWidget with icon, message, CTA)
- [ ] Touch targets are minimum 48×48dp
- [ ] Text uses design system fonts (Inter, Google Sans, Roboto Mono)

## State Management

- [ ] Screen has its own Cubit (not reusing another feature's)
- [ ] State class is sealed with exhaustive cases (Initial, Loading, Loaded, Error)
- [ ] State uses `EquatableMixin` on Loaded states
- [ ] `BlocProvider` is at route level (disposed when screen closes)
- [ ] No unnecessary `BlocBuilder` nesting (use `MultiBlocListener` if needed)
- [ ] Global state (auth, cart, connectivity) accessed via `context.read<>()`, not created per-screen

## Backend & API

- [ ] API calls go through repository → Dio (not direct)
- [ ] Endpoint path uses `ApiEndpoints` constant (no inline strings)
- [ ] Response is parsed into typed model (no raw `Map<String, dynamic>` in UI)
- [ ] `DioException` is caught and mapped to typed `Failure` in repository
- [ ] 401 is handled by `AuthInterceptor` (no manual 401 checks in features)
- [ ] Loading button state prevents double-submission
- [ ] Mutations (POST/PUT/DELETE) are not auto-retried

## Error Handling

- [ ] User never sees raw exceptions (`DioException`, `SocketException`, etc.)
- [ ] Error messages are human-readable ("No internet connection", not "ConnectionError")
- [ ] Validation errors show per-field (not a single generic message)
- [ ] Rate limit (429) shows countdown, disables button
- [ ] Network errors show retry button
- [ ] Errors don't crash the app (try/catch in repository)

## Security

- [ ] No secrets committed (API keys, tokens, passwords)
- [ ] No `print()` statements (use `debugPrint()` only in dev)
- [ ] No PII in logs (no emails, phones, addresses in debug output)
- [ ] Sensitive data in `flutter_secure_storage` (not SharedPreferences)
- [ ] Non-sensitive data in `SharedPreferences`
- [ ] HTTPS only (no http:// URLs anywhere)

## Code Quality

- [ ] File naming follows `snake_case.dart` convention
- [ ] Class naming follows `PascalCase` convention
- [ ] No file exceeds ~300 lines (split if needed)
- [ ] No unnecessary duplication (checked existing components first)
- [ ] No debug code left (no `debugPrint`, no `TODO` without owner)
- [ ] No commented-out code (delete it; git has history)
- [ ] No `dynamic` types (everything is typed)
- [ ] No magic numbers (use constants from `app_config.dart`)
- [ ] Imports organized (Dart SDK → Flutter → packages → project)
- [ ] Linter passes with zero warnings

## Testing

- [ ] Cubit has `blocTest` for: success path, error path, edge cases
- [ ] Model has `fromJson` / `toJson` test with fixture
- [ ] Repository has test verifying error mapping (DioException → Failure)
- [ ] Shared widgets have basic widget test (renders, responds to tap)

## Git

- [ ] Commit message describes the "why" (not just "updated file.dart")
- [ ] Branch is based on latest `develop`
- [ ] No unrelated changes in the PR
- [ ] PR description explains what changed and how to test

---

## Definition of Done (Task 11)

A task moves to **Done** ONLY when ALL of these are satisfied:

### Must Have (Every Task)

- [ ] Requirement implemented as described in acceptance criteria
- [ ] Architecture followed (correct feature folder, correct layer, correct dependency direction)
- [ ] UI follows design system (AppColors, AppTypography, AppSpacing — no hardcoded values)
- [ ] Loading state handled (skeleton or button spinner)
- [ ] Error state handled (ErrorStateWidget for full-screen, snackbar for inline)
- [ ] Empty state handled (EmptyStateWidget with icon, message, CTA)
- [ ] API errors mapped to typed Failures (no raw DioException visible to UI)
- [ ] Authentication handled (protected actions redirect to login if needed)
- [ ] Form validation implemented (client-side with proper keyboard types)
- [ ] No `print()` statements or debug code
- [ ] No hardcoded secrets, API URLs, or magic numbers
- [ ] Code formatted (`dart format .`)
- [ ] Analyzer clean (`flutter analyze` — zero warnings)
- [ ] PR opened with proper description
- [ ] PR reviewed and approved by assigned reviewer
- [ ] Merged to `develop` via squash merge
- [ ] Tested on at least one physical/emulator device
- [ ] No regressions introduced in existing features

### Should Have (Where Applicable)

- [ ] Cubit has `blocTest` (success + error paths at minimum)
- [ ] Model has `fromJson`/`toJson` test
- [ ] Accessibility: semantic labels on interactive elements
- [ ] Touch targets meet 48×48dp minimum
- [ ] Pull-to-refresh on data screens
- [ ] Back navigation works correctly (matches `05-navigation.md`)

### Edge Cases Verified

- [ ] Works offline (shows cached data or appropriate error)
- [ ] Session expiry mid-flow handled (redirect to login, no crash)
- [ ] Empty data from API (shows empty state, not crash)
- [ ] Network timeout (shows retry, not infinite loading)
- [ ] Rapid taps don't cause double-submission

---

## Quick Reference: Where Things Go

| I need to... | Put it in... |
|-------------|-------------|
| Add a new screen | `features/{name}/presentation/screens/` |
| Add screen-specific widget | `features/{name}/presentation/widgets/` |
| Add a widget used by 3+ features | `core/widgets/` |
| Add an API call | `features/{name}/data/{name}_repository.dart` |
| Add a data model | `features/{name}/models/` |
| Add a cubit | `features/{name}/presentation/cubits/` |
| Add a validator | `core/utils/validators.dart` |
| Add a formatter | `core/utils/formatters.dart` |
| Add a constant | `core/constants/app_config.dart` or appropriate file |
| Add an endpoint path | `core/constants/api_endpoints.dart` |
| Add a storage key | `core/constants/storage_keys.dart` |
