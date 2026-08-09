# Softstore Buyer App — Team Development Plan

**Read this before writing any code.**

This is the single source of truth for how the four-person team will build the Softstore Buyer App.

---

## 1. Team Structure

| Developer | GitHub | Role | Primary Area |
|-----------|--------|------|-------------|
| **Naheed** | `nahy1061` | Project Lead + Architecture | Foundation, Search, Seller, Support |
| **Arwah** | `arwahimran` | Auth + Networking Lead | Auth, Profile, Addresses, Notifications |
| **Munaza** | `munazamanzoorofficial-beep` | Product + Checkout Lead | Home, Categories, Product Detail, Checkout |
| **Nimra** | `nimraqureshi-ai` | Cart + Orders Lead | Cart, Wishlist, Orders, Returns |

**Naheed** makes final decisions on architecture questions. **Arwah** owns the networking layer. Each developer has exclusive ownership over their feature folders — no one else edits your folder without your PR review.

---

## 2. Feature Ownership

| Feature | Owner | Reviewer | Folder |
|---------|-------|----------|--------|
| Auth (login, register, OAuth, OTP, forgot pwd) | Arwah | Nimra | `features/auth/` |
| Home (product grid, filters, sort) | Munaza | Naheed | `features/home/` |
| Categories | Munaza | Naheed | `features/home/` (shared) |
| Product Detail (gallery, variants, reviews) | Munaza | Nimra | `features/product_detail/` |
| Search (suggestions, results, filters) | Naheed | Munaza | `features/search/` |
| Seller Store (info, products, follow) | Naheed | Munaza | `features/seller/` |
| Cart (local storage, validation, totals) | Nimra | Munaza | `features/cart/` |
| Wishlist (toggle, list) | Nimra | Arwah | `features/wishlist/` |
| Checkout (delivery, OTP, review, place order) | Munaza | Arwah | `features/checkout/` |
| Orders (history, detail, tracking) | Nimra | Arwah | `features/orders/` |
| Returns (request, list, evidence) | Nimra | Arwah | `features/orders/` (subfolder) |
| Profile (hub, edit, settings) | Arwah | Naheed | `features/profile/` |
| Addresses (CRUD, picker) | Arwah | Munaza | `features/profile/` |
| Notifications (list, FCM, tap) | Arwah | Nimra | `features/notifications/` |
| Support (FAQ, contact, tickets, chat) | Naheed | Arwah | `features/support/` |

---

## 3. Shared Foundation

| Component | Owner | Others Need Approval? |
|-----------|-------|-----------------------|
| `pubspec.yaml` | Naheed | YES — request in chat |
| `app/app.dart` | Naheed | YES |
| `app/router.dart` | Naheed (structure) | NO — add your routes in YOUR section |
| `core/theme/*` | Naheed | YES |
| `core/network/*` | Arwah | YES |
| `core/errors/*` | Arwah | YES |
| `core/widgets/*` | Naheed + Nimra | Bug fix: No. New prop: Discuss first. |
| `core/constants/*` | Naheed | NO — append your entries only |
| `core/utils/*` | Arwah (validators), Nimra (formatters) | NO for additions |
| `core/storage/*` | Nimra | YES |

**Rule:** If a file is marked "YES" above, you must get the owner's approval before modifying it.

---

## 4. Development Phases (7 Weeks)

| Phase | Week | What |
|-------|------|------|
| **0: Foundation** | 1 | Project setup, theme, router, API client, auth, shared widgets, models, cart |
| **1: Core Features** | 2 | Search, product detail, cart validation, wishlist, profile, auth polish |
| **2: Mid Features** | 3 | Seller, addresses, checkout (delivery + OTP), orders, deep links |
| **3: Complete Features** | 4 | Checkout (review + place order), returns, notifications, support |
| **4: Polish** | 5 | Edge cases, error states, accessibility, session handling |
| **5: Integration** | 6 | Cross-feature testing, performance, multi-device, bug fixes |
| **6: Release** | 7 | Tests, security audit, release build |

See [`development-roadmap.md`](team-plan/development-roadmap.md) for full details per phase.

---

## 5. Task Breakdown

~168 tasks divided across 4 developers (~40-45 each).

Tasks are specific and actionable:
- Bad: "Build Cart feature"
- Good: "Create CartItem model + JSON serialization"

See [`development-task-breakdown.md`](team-plan/development-task-breakdown.md) for the complete list.

---

## 6. Dependencies

```
Foundation (Week 1) → Everything else
Auth → Wishlist, Orders, Profile, Checkout, Support
Product Models → ProductCard, Home, Search, Seller, Cart
Cart → Checkout
Addresses → Checkout delivery
Checkout → Order confirmation
Orders → Returns
```

**Blocking chain:** Foundation → Auth → Checkout → Orders → Returns

**Parallel streams:** Search | Seller | Profile | Notifications | Support (all independent after Foundation)

See [`development-dependencies.md`](team-plan/development-dependencies.md) for the full graph.

---

## 7. Parallel Development

After Foundation Week, 4 developers work in **completely independent folder zones**:

| Developer | Works In | Never Touches |
|-----------|----------|---------------|
| Naheed | `features/search/`, `features/seller/`, `features/support/` | auth, cart, orders, checkout |
| Arwah | `features/auth/`, `features/profile/`, `features/notifications/` | home, cart, orders, checkout |
| Munaza | `features/home/`, `features/product_detail/`, `features/checkout/` | auth, cart, orders, support |
| Nimra | `features/cart/`, `features/wishlist/`, `features/orders/` | auth, home, checkout, support |

This eliminates merge conflicts on feature code.

See [`parallel-development-plan.md`](team-plan/parallel-development-plan.md) for the visual timeline.

---

## 8. Git Workflow

```
main ← develop ← feature/area-description
```

| Rule | Value |
|------|-------|
| Long-lived branches | `main` (releases), `develop` (integration) |
| Feature branches | From `develop`, named `feature/{area}-{desc}` |
| Commit format | `feat(scope): description` |
| Merge strategy | Squash merge to develop |
| Review required | Yes — assigned reviewer must approve |
| Force push | NEVER on develop or main |
| Pull develop | Daily (or before opening PR) |

See [`team-collaboration-rules.md`](team-plan/team-collaboration-rules.md) for full details.

---

## 9. Task Management

**Columns:** Backlog → Ready → In Progress → Code Review → Testing → Done

**Labels:** `foundation`, `feature`, `ui`, `api`, `bug`, `testing`, `blocked`, `urgent`, `shared`

**Priority:** P1 (blocks others) → P2 (core journey) → P3 (standard) → P4 (polish)

**Rules:**
- One assignee per task
- Max 2 tasks In Progress per person
- Blocked tasks go to Blocked column + immediate communication
- PR review within 24 hours

See [`task-management-workflow.md`](team-plan/task-management-workflow.md) for card format and workflow rules.

---

## 10. Coding Rules

Every developer must follow:

| Document | What It Covers |
|----------|---------------|
| [`development-principles.md`](standards/development-principles.md) | DO/DON'T list, naming, architecture direction, error handling, logging, comments |
| [`ui-design-system.md`](standards/ui-design-system.md) | Colors, typography, spacing, theme, responsive rules, animations |
| [`shared-components.md`](standards/shared-components.md) | 15 reusable widgets and when to use them |
| [`ui-states.md`](standards/ui-states.md) | Loading, error, empty state patterns |
| [`environment-configuration.md`](standards/environment-configuration.md) | Env vars, secrets, Firebase, feature flags |

**Three cardinal rules:**
1. No hardcoded values (colors, spacing, URLs, numbers) — use the design system
2. Every screen handles loading + error + empty
3. Business logic in cubits, data access in repositories, display in widgets

---

## 11. Definition of Done

A task is **not done** until:

- [ ] Acceptance criteria met
- [ ] Architecture followed (correct folder + layer)
- [ ] Design system used (no hardcoded values)
- [ ] Loading / error / empty states handled
- [ ] `flutter analyze` clean
- [ ] PR reviewed and approved
- [ ] Merged to develop
- [ ] Tested on device

See [`developer-checklist.md`](standards/developer-checklist.md) for the full checklist.

---

## 12. Communication

| Event | Action |
|-------|--------|
| Starting a task | Move card to In Progress |
| Need a package | Message team chat → Naheed adds |
| Need a shared component | Message Naheed |
| Blocked | Message immediately + move card to Blocked |
| Architecture question | Team chat → Naheed decides |
| Breaking change to shared code | Chat + all-acknowledge before merge |
| Found bug in someone's code | Open Issue, assign owner |
| PR ready | Tag reviewer in chat |

**Daily async standup (2-3 lines each):**
```
What I did yesterday → What I'm doing today → Blockers
```

See [`team-collaboration-rules.md`](team-plan/team-collaboration-rules.md) for full rules.

---

## 13. Backend Coordination

**All 50 API endpoints are PROPOSED** — they don't exist yet. The backend team must build them.

**Mobile team's strategy:**
1. Build with mock repositories first (hardcoded data)
2. Full UI + state + tests work without real API
3. When backend delivers an endpoint → swap mock for real (one-file change)
4. No idle time regardless of backend timeline

**Backend deadlines:**
- Week 1: Auth + Products endpoints
- Week 2: Wishlist, Profile, Addresses, Seller
- Week 3: Checkout, Orders, Password
- Week 4: Returns, Notifications, Support

See [`backend-team-requirements.md`](team-plan/backend-team-requirements.md) for the full 50-endpoint list.

---

## 14. Integration Strategy

### How Work Comes Together

1. **Foundation Week:** All 4 devs build infrastructure → merge to develop → everyone pulls
2. **Feature Weeks:** Each dev works in isolation → merges to develop via PR → others pull daily
3. **Integration Points** are handled via:
   - **Global cubits** (CartCubit, AuthCubit) — accessed via `context.read<>()`, no imports
   - **GoRouter** — navigation is path-based (`context.go('/orders/$id')`), no screen imports
   - **Shared models** — imported cross-feature (ProductModel lives in `home/models/`, Cart imports it)
4. **Integration Week (6):** All 4 devs test complete journeys end-to-end, fix cross-feature bugs
5. **Release Week (7):** Final tests, security audit, release build

### Critical Integration Tests

| Journey | Involves | Tested By |
|---------|----------|-----------|
| Guest purchase | Home → Product → Cart → Checkout → Confirm | Naheed (lead) + Munaza |
| Auth purchase | Login → Home → Cart → Checkout (saved address) → Confirm | Arwah + Munaza |
| Wishlist flow | Product → Add to wishlist → Wishlist screen → Remove | Nimra |
| Order + Return | Orders → Detail → Submit return → Returns list | Nimra |
| Notification → Order | Push tap → Order detail | Arwah + Nimra |
| Deep link | External URL → Product detail (cold start) | Naheed |
| Session expiry | Mid-checkout → 401 → Login → Resume | Arwah + Munaza |

---

## Quick Start for Each Developer

### Naheed
```
1. Create Flutter project (Day 1, push to develop)
2. Build theme + router + shared widgets (Days 2-5)
3. After Week 1: Search → Seller → Support → Deep links → Integration lead
```

### Arwah
```
1. Pull Naheed's project setup
2. Build API client + interceptors + auth system (Week 1)
3. After Week 1: Profile → Addresses → Notifications → Session edge cases → Security
```

### Munaza
```
1. Pull Naheed's project setup
2. Build all product models + basic Home screen (Week 1)
3. After Week 1: Product Detail → Checkout (3 screens) → Place Order → Edge cases
```

### Nimra
```
1. Pull Naheed's project setup
2. Build product-facing shared widgets + Cart (Week 1)
3. After Week 1: Wishlist → Orders → Returns → Cart validation → Edge cases
```

---

## Reference Documents

### Team Plan (`team-plan/`)
| Document | Purpose |
|----------|---------|
| [`development-dependencies.md`](team-plan/development-dependencies.md) | What blocks what |
| [`shared-foundation-ownership.md`](team-plan/shared-foundation-ownership.md) | Who owns shared code |
| [`team-work-division.md`](team-plan/team-work-division.md) | Feature-to-developer assignment |
| [`development-roadmap.md`](team-plan/development-roadmap.md) | Week-by-week plan |
| [`development-task-breakdown.md`](team-plan/development-task-breakdown.md) | All ~168 tasks |
| [`task-management-workflow.md`](team-plan/task-management-workflow.md) | Trello board structure |
| [`team-collaboration-rules.md`](team-plan/team-collaboration-rules.md) | Git + communication rules |
| [`parallel-development-plan.md`](team-plan/parallel-development-plan.md) | Visual parallel timeline |
| [`backend-team-requirements.md`](team-plan/backend-team-requirements.md) | All 50 API endpoints needed |
| [`developer-workflow.md`](team-plan/developer-workflow.md) | Daily dev process |

### Standards (`standards/`)
| Document | Purpose |
|----------|---------|
| [`developer-checklist.md`](standards/developer-checklist.md) | Pre-completion checklist + Definition of Done |
| [`development-principles.md`](standards/development-principles.md) | Coding conventions |
| [`ui-design-system.md`](standards/ui-design-system.md) | Visual design system |
| [`shared-components.md`](standards/shared-components.md) | Reusable widgets |
| [`ui-states.md`](standards/ui-states.md) | Loading/error/empty patterns |
| [`environment-configuration.md`](standards/environment-configuration.md) | Env vars + secrets |
| [`dependencies.md`](standards/dependencies.md) | Package justifications |

### Research (`research/`)
| Document | Purpose |
|----------|---------|
| [`FINAL-BUYER-APP-BLUEPRINT.md`](research/FINAL-BUYER-APP-BLUEPRINT.md) | Phase 1-2 master summary |
| `01` through `19` numbered files | Analysis research (reference only) |
