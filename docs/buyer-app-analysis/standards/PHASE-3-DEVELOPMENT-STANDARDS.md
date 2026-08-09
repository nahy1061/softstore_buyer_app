# Phase 3: Development Standards — Summary

This document summarizes all decisions made in Phase 3. A developer joining the project should read this first to understand how code should be written and how the UI should be built.

---

## 1. Visual Identity

Softstore uses an **orange/amber on Material greys** palette. No blue.

| Role | Hex | Usage |
|------|-----|-------|
| Primary | `#FF6F00` | Buttons, prices, active states |
| Primary Dark | `#E65100` | Pressed states, warnings |
| Secondary | `#FFB300` | Stars, badges, highlights |
| Background | `#F8F9FA` | Screen bg |
| Surface | `#FFFFFF` | Cards, sheets |
| Text | `#202124` / `#5F6368` | Primary / secondary |
| Error | `#B71C1C` | Errors, cancelled |
| Success | `#1B5E20` | Delivered, confirmations |

Fonts: **Inter** (body), **Google Sans** (headings/buttons), **Roboto Mono** (prices/numbers).

Full details: [`ui-design-system.md`](ui-design-system.md) → Task 1

---

## 2. Design System

All visual tokens are centralized in `lib/core/theme/`:

```
app_colors.dart      → Every color as a static const
app_typography.dart  → Every TextStyle
app_spacing.dart     → All padding/margin/gap values
app_dimensions.dart  → Border radius, elevation, sizes
app_durations.dart   → Animation timings
```

**Rule:** Never use `Color(0xFF...)`, `fontSize: 14`, `EdgeInsets.all(16)`, or `BorderRadius.circular(14)` directly. Always use the design system constants.

Full details: [`ui-design-system.md`](ui-design-system.md) → Task 2

---

## 3. Theme

- **Light theme only for MVP.** Dark mode planned for Phase 2 post-launch.
- `ThemeData` with Material 3, custom `ColorScheme`, themed components (buttons, inputs, cards, sheets, dialogs, snackbar, bottom nav, app bar).
- Access via `Theme.of(context)` for adaptive colors; `AppColors` directly for fixed brand colors.

Full details: [`ui-design-system.md`](ui-design-system.md) → Task 3

---

## 4. Shared Components

15 reusable widgets in `lib/core/widgets/`:

| Component | Purpose |
|-----------|---------|
| `AppButton` | Primary/secondary/text button with loading state |
| `AppTextField` | Styled input with label, error, keyboard type |
| `ProductCard` | Grid/list product display |
| `PriceDisplay` | Sale price + strikethrough + discount badge |
| `RatingDisplay` | Stars + review count |
| `QuantitySelector` | +/- stepper with stock limit |
| `AppImage` | Cached image with shimmer + error fallback |
| `LoadingSkeleton` | Shimmer placeholders (grid, list, card, text variants) |
| `ErrorStateWidget` | Error icon + message + retry button |
| `EmptyStateWidget` | Icon + title + subtitle + CTA |
| `StatusBadge` | Colored pill for order/return status |
| `OtpInput` | 6-digit boxes with auto-advance |
| `ConfirmationDialog` | Confirm/cancel for destructive actions |
| `AppSnackbar` | Static methods: `.success()`, `.error()`, `.info()` |
| `AppSearchBar` | Search input (read-only mode for home, active for search) |

A widget goes in `core/widgets/` only if used by **3+ features**.

Full details: [`shared-components.md`](shared-components.md)

---

## 5. UI States

Every data screen must handle:

| State | What User Sees |
|-------|---------------|
| Loading (initial) | Skeleton shimmer matching content layout |
| Loading (pagination) | Small spinner below existing content |
| Loading (button) | Spinner in button, button disabled |
| Error (initial) | Full-screen: icon + message + retry |
| Error (refresh) | Snackbar over existing content |
| Error (form) | Inline red text below invalid fields |
| Empty | Icon + message + CTA button |

Priority: Loading > Error > Empty > Content.

Full details: [`ui-states.md`](ui-states.md)

---

## 6. Responsive & Accessibility

- **Phone-only** layout (no tablet optimization in MVP)
- **Portrait locked** (no landscape)
- **2-column product grid** always
- Min touch target: **48×48dp**
- Text scaling: respect system up to **130%**
- WCAG AA contrast on all text/bg combinations
- Semantic labels on all interactive elements
- Respect `disableAnimations` system setting

Full details: [`ui-design-system.md`](ui-design-system.md) → Task 6

---

## 7. Animation Guidelines

| When | What | Duration |
|------|------|----------|
| Page push/pop | Slide left/right | 300ms |
| Bottom sheet | Slide up/down | 300ms/200ms |
| Add to cart | Cart icon bounce | 200ms |
| Wishlist toggle | Heart fill | 200ms |
| Skeleton loading | Shimmer sweep | 1500ms loop |
| Success (order placed) | Checkmark draw | 450ms |

**Rules:**
- No animation without purpose
- Nothing over 450ms (except shimmer loops)
- No staggered item animations on data load
- Respect reduce-motion system setting

Full details: [`ui-design-system.md`](ui-design-system.md) → Task 7

---

## 8. Dart & Flutter Conventions

- Files: `snake_case.dart`
- Classes: `PascalCase`
- One public class per file
- Cubits: `{Feature}Cubit`, States: sealed `{Feature}State`
- Models: `{Name}Model`, Repositories: `{Feature}Repository`
- Screens: `{Feature}{Purpose}Screen`
- Prefer `StatelessWidget` (use Stateful only for local controllers/animation)
- Extract widgets when `build()` exceeds ~80 lines

Full details: [`development-principles.md`](development-principles.md) → Task 8

---

## 9. Code Organization

- File: < 300 lines → split
- Class: < 200 lines → extract
- `build()`: < 80 lines → extract widget
- One public class per file
- Imports: Dart SDK → Flutter → Packages → Project
- Relative imports within same feature; absolute for cross-feature

**Dependency direction:** UI → Cubit → Repository → Network/Storage. Never backwards.

Full details: [`development-principles.md`](development-principles.md) → Task 9

---

## 10. Error Handling

```
DioException → Repository catches → throws typed Failure → Cubit catches → emits error state → UI shows message
```

- User never sees: `SocketException`, `DioException`, stack traces, HTTP status codes
- User sees: "No internet connection", "Something went wrong. Try again.", field-specific errors

6 Failure types: Network, Timeout, Server, Validation, Auth, RateLimit.

Full details: [`development-principles.md`](development-principles.md) → Task 10

---

## 11. Logging

- **Dev:** Dio LogInterceptor + BlocObserver (auto-logs state transitions)
- **Prod:** No logging. No `print()`. Future: Firebase Crashlytics.
- **Never log:** PII, cookies, tokens, passwords

Full details: [`development-principles.md`](development-principles.md) → Task 10

---

## 12. Documentation & Comments

- Default: **no comments**
- Comment only: non-obvious business rules, backend quirks, workarounds with references
- Never comment: what the code does (name it well instead), task/ticket references
- Shared components in `core/widgets/`: one-line doc comment explaining purpose
- TODOs must have owner: `// TODO(naheed): description`

Full details: [`development-principles.md`](development-principles.md) → Task 11

---

## 13. Environment Configuration

- `--dart-define` at build time (no `.env` packages)
- `EnvConfig` class reads compile-time values
- 3 environments: dev, staging, prod
- Firebase: separate project per environment, configs in flavor dirs
- Secrets: never in git. Shared via password manager. CI uses GitHub Actions secrets.
- Feature flags: compile-time booleans in `feature_flags.dart` (MVP). Remote Config post-launch.

Full details: [`environment-configuration.md`](environment-configuration.md)

---

## 14. Development Principles (DO / DON'T)

### DO
- Follow architecture layers
- Use design system for all visual values
- Reuse shared components
- Handle loading + error + empty states
- Keep features isolated
- Test cubit logic
- Use typed models and enums

### DON'T
- Hardcode colors, URLs, or magic numbers
- Put API calls or logic in widgets
- Duplicate existing components
- Create files over 300 lines
- Use `print()`, `dynamic`, or suppress lint warnings without comment
- Modify another dev's feature without coordination
- Add packages without team agreement

Full details: [`development-principles.md`](development-principles.md) → Task 13

---

## 15. Developer Checklist

Before marking any task complete, verify:
- Architecture (correct folder, correct layer, no dependency violations)
- Design system (no hardcoded values)
- States (loading, error, empty all handled)
- API (through repository, errors mapped, no double-submit)
- Security (no secrets, no PII in logs)
- Code quality (naming, file size, no duplication, linter clean)
- Tests (cubit + model coverage)
- Git (focused commit, clean PR)

Full details: [`developer-checklist.md`](developer-checklist.md)

---

## Consistency Notes (Task 15)

Phase 3 does NOT contradict Phase 1 or Phase 2. Clarifications:

| Topic | Phase 2 Said | Phase 3 Adds |
|-------|-------------|-------------|
| Theme files | Listed `app/theme.dart` in project structure | Expanded to `core/theme/` with 5 files (colors, typography, spacing, dimensions, durations). Updated `06-flutter-architecture.md` project structure. |
| Shared widgets | Listed 7 in `core/widgets/` | Expanded to 15 with full specs. All previously listed ones are retained. |
| Packages | `dependencies.md` listed packages | Phase 3 doesn't add new packages. Design system uses only Flutter SDK + existing deps. |
| Dark mode | Not mentioned in Phase 2 | Explicitly decided: NOT in MVP. Architecture supports adding later. |
| File structure | `core/` had `network/`, `storage/`, `utils/`, `widgets/`, `constants/`, `errors/`, `extensions/` | Added `core/theme/` subfolder. Everything else unchanged. |

No conflicting recommendations exist across phases.

---

## Documents Created/Updated in Phase 3

| Document | Status |
|----------|--------|
| `ui-design-system.md` | **NEW** — Tasks 1, 2, 3, 6, 7 |
| `shared-components.md` | **NEW** — Task 4 |
| `ui-states.md` | **NEW** — Task 5 |
| `development-principles.md` | **NEW** — Tasks 8, 9, 10, 11, 13 |
| `environment-configuration.md` | **NEW** — Task 12 |
| `developer-checklist.md` | **NEW** — Task 14 |
| `PHASE-3-DEVELOPMENT-STANDARDS.md` | **NEW** — This file |

---

## What Comes Next

**Phase 4** will divide the complete development work among the 4 team members and establish:
- Task assignment per developer
- Git workflow (branches, PRs, reviews)
- Dependency order (what must be built first)
- Review and merge process
- Communication and coordination rules
