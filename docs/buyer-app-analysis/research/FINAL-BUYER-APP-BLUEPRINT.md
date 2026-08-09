# FINAL BUYER APP BLUEPRINT — Softstore

**Version:** 1.0  
**Date:** 8 August 2026  
**Status:** Ready for implementation  
**Scope:** Flutter mobile app for Softstore.pk buyer marketplace

---

## 1. Executive Summary

The Softstore Buyer App is a Flutter mobile application for the Pakistani e-commerce marketplace at softstore.pk. It enables buyers to browse products from multiple sellers, purchase via Cash on Delivery, and track orders — replicating and enhancing the existing mobile-responsive website experience.

**Key facts:**
- 38 screens, 56 MVP features, 12 feature modules
- Session-based auth (cookie), not JWT
- Cart stored locally (SharedPreferences)
- COD only — no payment gateway
- Feature-first Clean Architecture with BLoC/Cubit
- GoRouter for navigation with deep linking
- ~11 weeks development with 3 Flutter developers

---

## 2. Website Analysis Summary

**Source:** `01-website-reconnaissance.md`

The existing buyer website at softstore.pk is a PHP 8.x custom MVC application. Key characteristics:
- Multi-seller marketplace (products from verified sellers)
- All-inclusive pricing via PricingService (tax baked in, no surprises)
- Session-based auth with `SOFTSTORE_SESSID` cookie
- Cart stored in PHP session (`ss_cart` key)
- Email OTP required at checkout (not registration)
- 5-step order pipeline: pending → confirmed → processing → shipped → delivered
- 7-day return window from delivery date
- WhatsApp seller contact, store follow/rating, product reviews
- Invoice format: `MKT-{alphanumeric}`

---

## 3. Buyer Requirements

**Source:** `02-feature-analysis.md`

The app must support:
- Guest browsing (no account needed to browse/add to cart)
- Guest checkout (email OTP verification, no login required)
- Registered user features (order history, wishlist, saved addresses)
- Multi-seller order display (items grouped by seller)
- Full product discovery (search, categories, filters, sort)
- Post-purchase order tracking (authenticated and public)
- Returns (7-day window, requires seller approval)

---

## 4. Feature List

**Source:** `02-feature-analysis.md`

**62 MVP features** across 11 categories:

| Category | MVP Features | Phase 2 | Future |
|----------|-------------|---------|--------|
| Browsing & Discovery | 9 | 2 | 0 |
| Product Detail | 17 | 1 | 0 |
| Search | 3 | 2 | 1 |
| Cart | 10 | 0 | 0 |
| Checkout | 9 | 0 | 1 |
| Orders & Tracking | 8 | 2 | 0 |
| Authentication | 7 | 1 | 0 |
| Profile & Account | 5 | 1 | 0 |
| Notifications | 0 | 3 | 0 |
| Support & Info | 4 | 1 | 0 |
| Mobile-Only | 3 | 1 | 1 |

---

## 5. MVP Scope

**Source:** `18-mvp-prioritization.md`

### In MVP
- Complete purchase loop (browse → cart → checkout → confirmation)
- Authentication (login, register, Google OAuth, password reset)
- Product discovery (search, categories, filters, sort, seller stores)
- Cart (local storage, delivery fee logic, age gate)
- Checkout (3-step: delivery → OTP → review, coupon support, guest + auth)
- Orders (history, detail, status pipeline, timeline, public tracking)
- Account (profile, addresses, wishlist)
- Support (FAQ, contact, terms)
- Deep linking, onboarding, force update

### Excluded from MVP
- Push notifications (Phase 2 — FCM requires backend work)
- Biometric auth (Phase 2)
- Submit review (Phase 2 — reading reviews is MVP)
- Reorder, order cancellation (Phase 2)
- Dark mode, offline mode, barcode scanner (Phase 2/Future)

---

## 6. User Journeys

**Source:** `03-user-flows.md`

### Primary Journeys
1. **Guest purchase:** Browse → Product → Cart → Checkout (email OTP) → Confirmation
2. **Registered purchase:** Login → Browse → Cart → Checkout (saved address, pre-verified) → Confirmation
3. **Registration:** Form → Email OTP → Dashboard
4. **Order tracking:** Orders tab → Detail → Timeline (or public: invoice + phone)

### Edge Cases Covered
- Out-of-stock handling (disabled buttons, checkout validation)
- Network failure (retry buttons, offline banner)
- Session expiry (401 → re-login → resume)
- Empty states (cart, wishlist, orders, addresses, search)
- Age-restricted products (confirmation modal)

---

## 7. User Flows

**Source:** `03-user-flows.md`

15 detailed flows documented:
- Guest buyer (full purchase)
- Registered buyer (full journey)
- Registration, Login/Logout, Password reset
- Wishlist, Cart management, Checkout (detailed 3-step)
- Address management, Order cancellation
- Out-of-stock, Network failure, Session expiration
- Empty states, Error states

---

## 8. Screen Inventory

**Source:** `04-screen-inventory.md`

**38 total screens** across 10 sections:

| Section | Screens |
|---------|---------|
| Onboarding & Launch | 2 |
| Authentication | 5 |
| Home & Browsing | 5 |
| Product Detail | 3 |
| Cart | 2 |
| Checkout | 4 |
| Order Confirmation & Tracking | 2 |
| Orders (Authenticated) | 4 |
| Profile & Account | 7 |
| Support & Info | 4 |

**13 shared components:** Bottom nav, app bar, product card, loading skeleton, error state, empty state, toast, bottom sheet, confirmation dialog, OTP input, step indicator, status badge, price display.

---

## 9. Navigation

**Source:** `05-navigation.md`

- **Solution:** GoRouter with `StatefulShellRoute.indexedStack`
- **Bottom tabs:** Home | Categories | Cart | Orders | Profile
- **Deep linking:** `softstore://` scheme + `https://softstore.pk` universal links
- **Auth guards:** Redirect to `/login?next=` for protected routes
- **Post-checkout:** `context.go()` replaces stack (can't navigate back to checkout)
- **Notification tap:** Routes to relevant screen based on payload type

---

## 10. Flutter Architecture

**Source:** `06-flutter-architecture.md`

- **Pattern:** Feature-First + Clean Architecture (3 layers per feature)
- **Layers:** `data/` (repositories, API) → `domain/` (models, interfaces) → `presentation/` (screens, Cubits)
- **Cross-feature:** Only via `domain/` model imports or global Cubits
- **12 feature modules:** auth, home, search, product_detail, cart, checkout, orders, seller, profile, wishlist, notifications, support

---

## 11. State Management

**Source:** `07-state-management.md`

- **Solution:** BLoC/Cubit (via `flutter_bloc`)
- **Global Cubits (4):** AuthCubit, CartCubit, ConnectivityCubit, ThemeCubit
- **Feature Cubits:** One per screen, created/disposed with route lifecycle
- **Local state:** StatefulWidget for ephemeral UI (toggles, focus, animation)
- **Persistence:** Cart → SharedPreferences, Auth → Secure Storage, Images → disk cache

---

## 12. Folder Structure

**Source:** `06-flutter-architecture.md`

```
lib/
├── app/           (app.dart, router.dart, theme.dart)
├── core/          (constants, errors, network, utils, widgets)
├── features/      (12 feature folders, each with data/domain/presentation)
├── shared/        (services, providers)
└── main.dart
```

---

## 13. API Requirements

**Source:** `08-api-requirements.md`

~50 endpoints proposed under `/api/` prefix. Key groups:

| Group | Endpoints | Status |
|-------|-----------|--------|
| Auth | 10 | **PROPOSED** (new JSON routes needed) |
| Products/Browse | 5 | Mix (search-suggest exists; others proposed) |
| Sellers | 4 | **PROPOSED** |
| Cart validation | 3 | 1 exists (`/api/store/cart/add`); 2 proposed |
| Wishlist | 3 | 1 exists (toggle); 2 proposed |
| Addresses | 5 | **PROPOSED** |
| Checkout | 5 | 3 exist (OTP, coupon, place order); 2 proposed |
| Orders | 5 | **PROPOSED** |
| Returns | 3 | **PROPOSED** |
| Reviews | 2 | 1 exists; 1 proposed |
| Profile | 4 | **PROPOSED** |
| Notifications | 5 | **PROPOSED** (new infrastructure) |
| Support | 4 | 1 exists (messages); 3 proposed |
| Parcel | 1 | **PROPOSED** |

**NEEDS CONFIRMATION:** Backend team must confirm they will build the proposed JSON endpoints. See `19-risks-open-questions.md` Q1.

---

## 14. Data Models

**Source:** `09-data-models.md`

17 model classes defined with full field specifications:

| Model | Fields | Backend Table |
|-------|--------|---------------|
| UserModel | 8 | `marketplace_customers` |
| ProductModel (list) | 16 | `products` (joined) |
| ProductDetailModel | 15 | `products` + relations |
| PricingModel | 7 | Computed by PricingService |
| VariantModel | 4 | Inline in product |
| CategoryModel | 4 | `categories` |
| SellerModel | 10 | `businesses` |
| CartItem | 9 | Local storage (no table) |
| AddressModel | 10 | `marketplace_addresses` |
| OrderModel | 19 | `sales` |
| OrderItem | 9 | `sale_items` |
| OrderTimelineEntry | 3 | `order_status_history` |
| ReviewModel | 7 | Reviews table |
| RatingBreakdown | 3 | Computed |
| ReturnModel | 12 | `returns` + `return_items` |
| NotificationModel | 7 | New table (proposed) |
| TicketModel + Message | 7 + 4 | `support_tickets` |
| CouponResult | 5 | Computed |

---

## 15. Authentication

**Source:** `10-authentication-security.md`

- **Mechanism:** Session cookie (`SOFTSTORE_SESSID`) via persistent cookie jar
- **Login:** Email/password + Google OAuth (both with reCAPTCHA)
- **Registration:** full_name, email, phone (optional), password → email OTP
- **Password reset:** Email link → deep link → new password form
- **Session lifetime:** 8 hours of inactivity (extends on activity)
- **Expiry handling:** 401 → clear auth → redirect to login with ?next
- **reCAPTCHA:** Invisible widget (`recaptcha_enterprise_flutter`) on login/register

---

## 16. Security

**Source:** `10-authentication-security.md`

| Layer | Implementation |
|-------|----------------|
| Transport | HTTPS only, no cleartext allowed |
| Auth | Session cookie, never exposed in logs |
| Storage | Sensitive data in flutter_secure_storage |
| Input | Client-side validation (UX) + server-side enforcement (trust) |
| Pricing | Server calculates all prices — client cannot set price |
| Stock | Server validates at checkout — client display is informational |
| CSRF | Either exempt API routes (recommended) or X-CSRF-TOKEN header |
| Rate limiting | 429 handled with countdown UI |
| Screenshots | FLAG_SECURE on checkout/login (app switcher protection) |

---

## 17. UI/UX Requirements

**Source:** `11-ui-ux.md`

### Design System
- Primary: #FF6F00 (orange), Secondary: #FFB300 (amber)
- No blue allowed in design system
- Google Sans headings, system font body
- 48dp minimum touch targets
- WCAG AA contrast compliance

### Key Mobile Adaptations
- Bottom nav (not top nav)
- Horizontal category chips (not sidebar)
- 2-column product grid with infinite scroll
- Bottom sheets for filter/sort (not sidebar)
- Swipeable full-width image gallery (not thumbnails)
- Sticky bottom bar on product detail (Add to Cart + Buy Now)
- Card-based layouts (not tables)

### Pakistani Market Considerations
- WhatsApp as primary communication channel
- COD expectation (no payment form confusion)
- Pakistani phone format (03XX-XXXXXXX)
- PKR with comma separators
- Aggressive caching for slow/intermittent networks
- Budget device optimization (minimal animations, small images)

---

## 18. Network & Caching

**Source:** `12-network-caching.md`

- **HTTP client:** Dio with cookie jar + auth + retry interceptors
- **Timeouts:** 10s connect, 15s receive (30s for checkout)
- **Retry:** 2 attempts with backoff for timeout/5xx (never for mutations)
- **Caching:** Stale-while-revalidate for product lists; write-through for cart
- **Offline:** Show cached data with "offline" banner; block checkout
- **Image cache:** 200MB disk limit, LRU eviction, 7-day TTL

---

## 19. Notifications

**Source:** `13-notifications.md`

- **Platform:** Firebase Cloud Messaging (FCM)
- **Phase:** Phase 2 (architecture designed now, implementation after MVP)
- **Types:** Order status, return updates, support replies, promotions
- **Foreground:** In-app banner (not system notification)
- **Background:** System notification, tap navigates to relevant screen
- **iOS permission:** Ask after first meaningful action (not on first launch)
- **Backend needed:** `device_tokens` table, notification sender service, FCM SDK

---

## 20. Development Roadmap

**Source:** `14-development-roadmap.md`

| Phase | Duration | Key Deliverable |
|-------|----------|----------------|
| 0: Foundation | Week 1 | Architecture skeleton, API client, models, theme |
| 1: Browsing | Weeks 2–3 | Product grid, search, detail, seller pages |
| 2: Cart | Week 4 | Local cart, delivery fee, persistence |
| 3: Auth | Weeks 5–6 | Login, register, OAuth, profile, addresses |
| 4: Checkout | Weeks 6–7 | 3-step checkout, order placement |
| 5: Orders | Week 8 | History, detail, tracking, returns |
| 6: Extras | Week 9 | Wishlist, support, FAQ, seller features |
| 7: Polish | Weeks 10–12 | Notifications, onboarding, performance, launch |

---

## 21. Team Responsibilities

**Source:** `15-team-task-distribution.md`

| Developer | Primary Ownership | Weeks |
|-----------|------------------|-------|
| **Dev A** | Home, Search, Categories, Seller, Deep linking, Info screens, Performance | 2–11 |
| **Dev B** | Product Detail, Cart, Checkout, API client, Models | 2–11 |
| **Dev C** | Auth, Orders, Profile, Wishlist, Notifications, Support | 5–12 |
| **All** | Foundation (Week 1), Code reviews, Integration testing | 1, ongoing |

---

## 22. Git Workflow

**Source:** `16-git-workflow.md`

- **Strategy:** GitHub Flow (main → develop → feature branches)
- **Branch naming:** `feature/{name}`, `bugfix/{name}`, `hotfix/{name}`
- **Commits:** Conventional Commits (`feat(scope): subject`)
- **Merge:** Squash merge to develop, merge commit to main
- **PRs:** 1 approval required, CI must pass, max 400 lines
- **Conflict prevention:** Feature folders isolate work, daily rebase, small PRs

---

## 23. Testing

**Source:** `17-testing-strategy.md`

| Level | Count Target | Coverage |
|-------|-------------|----------|
| Unit tests | 100+ | 80% on domain + data layers |
| Widget tests | 30–50 | Key shared components |
| Integration tests | 5–10 | Critical user journeys |

**Key test areas:** Cart logic (delivery fee, quantities), auth states (login, logout, expiry), checkout flow (validation, OTP, placement), network failures (retry, offline, 401).

---

## 24. Risks

**Source:** `19-risks-open-questions.md`

### Top 3 Risks

1. **Backend JSON API not ready on time** (HIGH likelihood, HIGH impact) — Must agree API contract in Week 1
2. **Session cookie approach fragile on mobile** (MEDIUM, HIGH) — Validate in Phase 0 spike on both platforms
3. **Image loading slow on Pakistani networks** (HIGH, MEDIUM) — Thumbnail endpoints + aggressive caching

---

## 25. Open Questions

**Source:** `19-risks-open-questions.md`

### Must Answer Before Development Starts

| # | Question | Ask |
|---|----------|-----|
| 1 | Will backend create `/api/buyer/*` JSON endpoints? API contract needed Week 1. | Backend |
| 2 | CSRF on API routes — exempt or required? | Backend |
| 3 | Cookie domain — same origin or subdomain? | Backend |
| 4 | Cart validation endpoint — confirm request/response format | Backend |
| 5 | Address CRUD endpoints — confirm routes | Backend |
| 6 | Search suggest — confirm returns JSON | Backend |

### Can Proceed With Assumptions (Confirm Later)

| # | Assumption | Fallback |
|---|-----------|----------|
| 1 | API routes exempt from CSRF | Add CsrfInterceptor |
| 2 | Same-origin cookies (`softstore.pk/api/`) | Set cookie domain |
| 3 | Google OAuth redirect works for mobile | Custom OAuth flow |
| 4 | Image resizing available | Client-side resize before display |
| 5 | Password reset ready before launch | Hide button, show "Contact support" |

---

## 26. Dependencies (Package List)

| Package | Version (approx) | Purpose |
|---------|----------|---------|
| `go_router` | ^14.0 | Navigation, deep linking |
| `flutter_bloc` | ^8.1 | State management (Cubit) |
| `dio` | ^5.4 | HTTP client |
| `dio_cookie_manager` | ^3.1 | Cookie persistence |
| `cookie_jar` / `persist_cookie_jar` | ^4.0 | Cookie storage |
| `flutter_secure_storage` | ^9.0 | Sensitive data storage |
| `shared_preferences` | ^2.2 | Local key-value storage |
| `cached_network_image` | ^3.3 | Image caching |
| `json_annotation` | ^4.8 | Model annotations |
| `json_serializable` | ^6.7 | Code generation |
| `build_runner` | ^2.4 | Code gen runner |
| `equatable` | ^2.0 | Value equality for states |
| `google_sign_in` | ^6.2 | Google OAuth |
| `firebase_messaging` | ^15.0 | Push notifications (Phase 2) |
| `firebase_core` | ^3.0 | Firebase initialization |
| `recaptcha_enterprise_flutter` | ^18.0 | Invisible reCAPTCHA |
| `url_launcher` | ^6.2 | External links (WhatsApp, email) |
| `share_plus` | ^9.0 | Native share sheet |
| `connectivity_plus` | ^6.0 | Network monitoring |
| `bloc_test` | ^9.0 | Testing Cubits |
| `mocktail` | ^1.0 | Mocking |

---

## 27. Recommended Implementation Order

This is the exact sequence in which code should be written:

```
Week 1:
  1. Create Flutter project with folder structure
  2. Add all packages to pubspec.yaml
  3. Configure analysis_options.yaml
  4. Create ThemeData (colors, typography)
  5. Create all data models (17 classes) with json_serializable
  6. Run build_runner, verify all models compile
  7. Create Dio client + cookie jar + interceptors
  8. Create GoRouter with bottom nav shell + placeholder screens
  9. Create shared widgets (product card, skeleton, error, empty, price)
  10. Create constants, validators, formatters

Week 2:
  11. HomeCubit + ProductRepository → real API call
  12. Home screen with product grid (infinite scroll)
  13. Category chips (filter)
  14. Sort/filter bottom sheets
  15. Search screen + SearchCubit

Week 3:
  16. ProductDetailCubit + ProductDetailRepository
  17. Product detail screen (all sections)
  18. Image gallery (full-screen)
  19. Variant selector
  20. Seller store screen + SellerCubit

Week 4:
  21. CartCubit + cart local storage
  22. Cart screen (items, qty, remove, totals)
  23. Add-to-cart from product detail + product card
  24. Cart badge on bottom nav
  25. Delivery fee logic + free delivery progress

Week 5:
  26. AuthCubit + AuthRepository
  27. Login screen (email/password)
  28. Google OAuth integration
  29. Register screen + OTP verification
  30. Route guards (redirect to login)

Week 6:
  31. Forgot/reset password screens
  32. reCAPTCHA invisible widget
  33. Profile hub + edit profile
  34. Address book (CRUD)
  35. Session expiry handling (401 interceptor)

Week 7:
  36. CheckoutCubit + CheckoutRepository
  37. Checkout delivery step (form + address picker)
  38. Checkout email OTP step
  39. Checkout review step (coupon, summary, place order)
  40. Order confirmation screen
  41. Post-checkout navigation (clear cart, can't go back)

Week 8:
  42. OrdersCubit + OrderRepository
  43. Order history screen (paginated)
  44. Order detail screen (pipeline, timeline, items)
  45. Public order tracking screen
  46. Return request sheet
  47. Returns list screen

Week 9:
  48. WishlistCubit + toggle logic
  49. Wishlist screen
  50. Store follow/unfollow
  51. Store rating
  52. Support ticket + chat
  53. FAQ, Contact, Terms/Privacy

Weeks 10–12:
  54. FCM setup + notification handling
  55. Notification list screen
  56. Onboarding slides
  57. Force update check
  58. Deep linking verification (all paths)
  59. Connectivity monitoring + offline banner
  60. Performance optimization
  61. Accessibility pass
  62. Final QA + bug fixes
  63. Store assets (icon, screenshots, metadata)
  64. Release build + submission
```

---

## Document Index

| # | File | Content |
|---|------|---------|
| 01 | `01-website-reconnaissance.md` | Phase 1: Full website and source code analysis |
| 02 | `02-feature-analysis.md` | Phase 2: Feature inventory (62 MVP + 14 Phase 2 + 4 Future) |
| 03 | `03-user-flows.md` | Phase 2: 15 user journeys with edge cases |
| 04 | `04-screen-inventory.md` | Phase 2: 38 screens with full specifications |
| 05 | `05-navigation.md` | Phase 3: GoRouter architecture + deep linking |
| 06 | `06-flutter-architecture.md` | Phase 3: Feature-first Clean Architecture |
| 07 | `07-state-management.md` | Phase 3: BLoC/Cubit state design |
| 08 | `08-api-requirements.md` | Phase 3: ~50 API endpoints (existing + proposed) |
| 09 | `09-data-models.md` | Phase 3: 17 Dart model classes |
| 10 | `10-authentication-security.md` | Phase 3: Session auth + security measures |
| 11 | `11-ui-ux.md` | Phase 2: Mobile UX recommendations |
| 12 | `12-network-caching.md` | Phase 3: Dio, retry, offline, caching |
| 13 | `13-notifications.md` | Phase 3: FCM architecture |
| 14 | `14-development-roadmap.md` | Phase 4: 7-phase development plan |
| 15 | `15-team-task-distribution.md` | Phase 4: 3-dev work allocation |
| 16 | `16-git-workflow.md` | Phase 4: Git strategy + PR process |
| 17 | `17-testing-strategy.md` | Phase 4: Test pyramid + coverage targets |
| 18 | `18-mvp-prioritization.md` | Phase 2: MVP scope + sprint plan |
| 19 | `19-risks-open-questions.md` | Phase 4: Risks + questions by team |

---

*This blueprint is the single source of truth for the Softstore Buyer App implementation. Items marked **NEEDS CONFIRMATION** must be resolved with the relevant team before implementation begins.*
