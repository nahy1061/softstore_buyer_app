# Phase 4: Team Task Distribution

## Team Size Assumption

**3 Flutter developers** working full-time. Labeled as Dev A, Dev B, Dev C below.

---

## Collaborative Foundation (Week 1 — All Developers Together)

Before splitting into feature work, the entire team builds the shared foundation together to establish patterns and prevent architectural drift.

| Component | Owner | Collaborators | Deliverable |
|-----------|-------|---------------|-------------|
| Project scaffolding + folder structure | Dev A | All | Skeleton with all directories |
| GoRouter setup + bottom nav shell | Dev A | Dev B (review) | Working navigation with placeholders |
| Dio client + interceptors (cookie, auth, retry) | Dev B | Dev A (review) | API client with mock server test |
| Theme (colors, typography, spacing) | Dev C | All (review) | ThemeData applied to MaterialApp |
| Shared widgets (product card, skeleton, error, empty, price) | Dev C | All (review) | Widget library with samples |
| Data models (all @JsonSerializable classes) | Dev B | All (review) | Models with fromJson/toJson + tests |
| Constants + validators + formatters | Dev A | — | Utility layer complete |
| Linting + CI setup | Dev A | — | analysis_options + pre-commit hooks |

**End of Week 1:** All devs have the same baseline, patterns are established, merge conflicts on core files are resolved before parallel work begins.

---

## Feature Distribution (Weeks 2–12)

### Developer A — Browsing & Discovery Lead

| Week | Feature | Screens | Dependencies |
|------|---------|---------|--------------|
| 2 | Store home (grid, pagination, pull-to-refresh) | 1 | Foundation |
| 2 | Category chips + filter sheet + sort sheet | 2 (sheets) | Home screen |
| 3 | Search screen + suggestions + recent searches | 1 | Foundation |
| 3 | Seller store page | 1 | Home screen pattern |
| 4 | Deep linking (all product/store/category routes) | — | GoRouter |
| 8 | Public order tracking screen | 1 | Phase 5 models |
| 9 | FAQ + Contact + Terms/Privacy screens | 4 | Foundation |
| 10 | Onboarding slides | 1 | Foundation |
| 10–11 | Performance optimization + accessibility pass | — | All features |

**Dev A owns:** `features/home/`, `features/search/`, `features/seller/`, `features/support/` (info screens), deep linking config

### Developer B — Product Detail, Cart & Checkout Lead

| Week | Feature | Screens | Dependencies |
|------|---------|---------|--------------|
| 2–3 | Product detail screen (all sections) | 1 | Foundation + models |
| 3 | Image gallery (full-screen, zoom) | 1 | Product detail |
| 3 | Variant selector + quantity stepper | (widget) | Product detail |
| 4 | Cart screen + persistence | 1 | Product detail |
| 4 | Cart logic (add, remove, qty, delivery fee) | — | Models |
| 6 | Checkout delivery step | 1 | Cart, addresses |
| 6 | Checkout email OTP step | 1 | Auth patterns |
| 7 | Checkout review step + coupon + place order | 1 | Cart, API |
| 7 | Order confirmation screen | 1 | Checkout |
| 11 | Checkout edge cases + error handling polish | — | All checkout |

**Dev B owns:** `features/product_detail/`, `features/cart/`, `features/checkout/`

### Developer C — Authentication, Orders & Account Lead

| Week | Feature | Screens | Dependencies |
|------|---------|---------|--------------|
| 5 | Login screen + Google OAuth | 1 | API client |
| 5 | Register screen + OTP verification | 2 | API client |
| 5 | reCAPTCHA integration | — | Login/register |
| 5 | Auth Cubit (global) + route guards | — | GoRouter |
| 6 | Forgot/reset password + deep link | 2 | Auth |
| 6 | Profile hub + edit profile | 2 | Auth |
| 6 | Address book (list, add, edit, delete) | 2 | Auth |
| 8 | Order history + order detail | 2 | Auth |
| 8 | Status pipeline + timeline widgets | (widget) | Orders |
| 8 | Return request sheet | 1 (sheet) | Orders |
| 9 | Wishlist screen + toggle | 1 | Auth + product detail |
| 9 | Store follow/unfollow + rating | — | Seller page |
| 9 | Support ticket + chat | 2 | Auth |
| 10–11 | Push notifications (FCM) + notification list | 1 | Auth, all features |

**Dev C owns:** `features/auth/`, `features/orders/`, `features/profile/`, `features/wishlist/`, `features/notifications/`, `features/support/` (tickets)

---

## Responsibility Matrix

| Module / Area | Dev A | Dev B | Dev C |
|---------------|-------|-------|-------|
| `core/network/` | Review | **Own** | Review |
| `core/widgets/` | Contribute | Contribute | **Own** |
| `core/constants/` | **Own** | — | — |
| `core/utils/` | **Own** | — | — |
| `app/router.dart` | **Own** | Contribute (checkout routes) | Contribute (auth guards) |
| `app/theme.dart` | — | — | **Own** |
| `features/home/` | **Own** | — | — |
| `features/search/` | **Own** | — | — |
| `features/seller/` | **Own** | — | Contribute (follow/rate) |
| `features/product_detail/` | — | **Own** | — |
| `features/cart/` | — | **Own** | — |
| `features/checkout/` | — | **Own** | — |
| `features/auth/` | — | — | **Own** |
| `features/orders/` | Contribute (tracking) | — | **Own** |
| `features/profile/` | — | — | **Own** |
| `features/wishlist/` | — | — | **Own** |
| `features/notifications/` | — | — | **Own** |
| `features/support/` | Contribute (FAQ/contact) | — | **Own** (tickets) |
| `shared/services/` | — | Contribute | **Own** |

---

## Conflict Prevention Rules

### File Ownership
- Each feature folder has ONE owner. Only the owner pushes directly to that feature branch.
- `core/` changes require PR review from at least one other dev.
- `app/router.dart` — Dev A owns the file but others contribute routes via PR.
- `app/theme.dart` — Dev C owns; others request changes via issue.

### Shared Models Strategy
- Models are defined in Phase 0 by Dev B and are considered frozen.
- If a new field is needed, the requesting dev opens a PR to the model file with tests.
- Model changes require review from the model owner (Dev B).

### Import Rules
- Features may import another feature's `domain/` models only.
- Never import another feature's `data/` or `presentation/`.
- Cross-feature communication only through global Cubits (auth, cart).

### Merge Cadence
- Feature branches merge to `develop` at least every 2 days.
- No long-lived branches (>1 week without merging).
- Rebase onto `develop` daily before work starts.

---

## Parallel Work Visualization

```
Week:  1    2    3    4    5    6    7    8    9    10   11   12
       ├────┼────┼────┼────┼────┼────┼────┼────┼────┼────┼────┤
Dev A: [Foundation] [Home/Search/Category] [Seller] [Deep] [Track] [FAQ  ] [Onboard] [Polish]
Dev B: [Foundation] [Product Detail      ] [Cart ] [   Checkout Flow   ] [  Edge cases  ]
Dev C: [Foundation]                [Auth + Profile + Addresses] [Orders] [Wish+Sup] [Notif ]
```

### Sync Points (All devs align)

| Week | Sync Event | Purpose |
|------|-----------|---------|
| End of 1 | Foundation demo | Verify shared patterns work |
| End of 3 | Browsing demo | Home + detail + search working together |
| End of 4 | Cart integration | Verify add-to-cart from detail works with cart |
| End of 6 | Auth integration | Verify route guards, profile, addresses |
| End of 7 | Checkout demo | Full purchase flow end-to-end |
| End of 9 | Feature complete | All screens implemented |
| End of 11 | Polish complete | Ready for QA |

---

## Code Review Rotation

| PR Author | Primary Reviewer | Secondary Reviewer |
|-----------|-----------------|-------------------|
| Dev A | Dev B | Dev C |
| Dev B | Dev C | Dev A |
| Dev C | Dev A | Dev B |

Every PR requires 1 approval. Core infrastructure PRs require 2 approvals.
