# Development Roadmap

## Timeline Overview

| Phase | Weeks | Focus | Developers Active |
|-------|-------|-------|-------------------|
| 0 | Week 1 | Foundation | All 4 |
| 1 | Week 2 | Auth + Product Browsing | All 4 |
| 2 | Week 3 | Shopping Features | All 4 |
| 3 | Week 4 | Checkout + Orders | All 4 |
| 4 | Week 5 | Returns + Notifications + Support | All 4 |
| 5 | Week 6 | Integration + Polish | All 4 |
| 6 | Week 7 | Testing + Release | All 4 |

Total: **7 weeks** (assuming backend APIs are available on time).

---

## Phase 0 — Foundation (Week 1)

### Objective
Set up the entire project infrastructure so all 4 developers can start feature work independently from Week 2.

### Tasks by Developer

**Naheed (Project Lead):**
- Day 1: Create Flutter project, folder structure, `pubspec.yaml`, push to `develop`
- Days 2–3: Theme files (`app_colors.dart`, `app_typography.dart`, `app_spacing.dart`, `app_dimensions.dart`, `app_durations.dart`, `app_theme.dart`)
- Days 3–4: Router shell (all routes with placeholder screens), `app.dart` (MultiBlocProvider)
- Days 4–5: Shared widgets (AppButton, AppTextField, LoadingSkeleton, ErrorStateWidget, EmptyStateWidget, ConfirmationDialog, AppSnackbar)
- Day 5: Constants (`api_endpoints.dart`, `app_config.dart`, `storage_keys.dart`, `env_config.dart`, `feature_flags.dart`), `.gitignore`, `analysis_options.yaml`

**Arwah (Auth + Networking):**
- Days 1–2: `api_client.dart` (Dio + BaseOptions + interceptor stack), `auth_interceptor.dart`, `retry_interceptor.dart`, cookie jar setup
- Day 2: `failures.dart` (all Failure types), `validators.dart`
- Days 3–4: `AuthRepository`, `AuthCubit`, Login screen, Register screen
- Day 5: Google OAuth flow, OTP verification screen, Forgot password screen

**Munaza (Products):**
- Days 1–2: `ProductModel`, `ProductDetailModel`, `PricingModel`, `VariantModel`, `CategoryModel`, `SellerModel`, `ReviewModel`, `RatingBreakdown` — all with `@JsonSerializable` + `.g.dart` generation
- Days 3–4: `HomeRepository` (mock data for now), `HomeCubit`, Home screen with product grid
- Day 5: Categories screen, category filter integration

**Nimra (Cart + Shared Widgets):**
- Days 1–3: Shared widgets (ProductCard, PriceDisplay, RatingDisplay, QuantitySelector, AppImage, StatusBadge, OtpInput, AppSearchBar)
- Day 2: `formatters.dart` (PKR currency, phone, date), storage wrappers
- Days 3–5: `CartItem` model, `CartCubit` (global, local persistence), Cart screen (add/remove/update qty/totals/delivery fee logic)

### Exit Criteria
- [ ] `flutter run` launches the app with working navigation shell
- [ ] Login + Register screens functional (with mock API or real if backend ready)
- [ ] Home screen shows product grid (mock data OK)
- [ ] Cart works end-to-end locally (add, remove, qty, totals, persistence)
- [ ] All 15 shared widgets exist and render correctly
- [ ] Theme applied across all existing screens
- [ ] No lint warnings, `flutter analyze` clean

---

## Phase 1 — Auth + Product Browsing (Week 2)

### Objective
Complete authentication and core product discovery features.

### Tasks

**Naheed:**
- Search screen (suggestions, results, filters)
- Seller store screen (seller info + products)
- Integrate search with `SearchCubit` + `SearchRepository`

**Arwah:**
- Polish auth: rate limiting UI, reCAPTCHA integration, session keep-alive
- ConnectivityCubit + offline banner
- Profile hub screen + profile edit screen

**Munaza:**
- Product detail screen (gallery, variants, pricing, reviews section, related products)
- Age-restricted product gate
- Product detail → Add to Cart integration (calls Nimra's CartCubit)

**Nimra:**
- Cart validation against server (`/api/store/cart/validate-item`)
- Wishlist feature (repository, cubit, screen, toggle from product card)
- Free delivery progress indicator in cart

### Dependencies
- Nimra's wishlist needs Arwah's auth complete
- Munaza's "Add to Cart" calls Nimra's CartCubit (must be merged)
- Search and Seller use Munaza's ProductModel (already merged in Phase 0)

### Exit Criteria
- [ ] User can register, login, logout, recover password
- [ ] Product browsing: home grid, search, categories, seller store all functional
- [ ] Product detail: gallery swipe, variant selection, add to cart working
- [ ] Cart: add from product detail, update qty, remove, delivery fee calculation
- [ ] Wishlist: toggle from product detail, view wishlist screen
- [ ] Offline banner appears when connection lost

---

## Phase 2 — Profile + Addresses (Week 3)

### Objective
Complete profile management and address system (required for checkout).

### Tasks

**Naheed:**
- Refine search: debounced suggestions, filter/sort bottom sheet
- Deep linking setup (Android manifest, iOS Info.plist, GoRouter universal links)
- Static screens: FAQ, Contact, Terms, Privacy

**Arwah:**
- Address CRUD (list, add, edit, delete, set default)
- Change password screen
- Settings screen (theme preference placeholder, notification toggle)
- Notification repository + cubit + screen (basic list)

**Munaza:**
- Checkout delivery screen (address picker from Arwah's work, delivery form)
- Checkout OTP screen (send + verify email code)
- Coupon validation

**Nimra:**
- Order history screen (list with status badges, pagination)
- Order detail screen (items, timeline, totals)
- Public order tracking screen (invoice + phone lookup)

### Dependencies
- Munaza's checkout delivery needs Arwah's address system complete
- Nimra's orders need auth (already done)
- Naheed's deep linking needs router (already done)

### Exit Criteria
- [ ] User can manage addresses (CRUD + default)
- [ ] Checkout delivery step works with saved address or manual entry
- [ ] Checkout OTP sends and verifies
- [ ] Order history displays with pagination
- [ ] Order detail shows full information with timeline
- [ ] Deep links open correct screens from external URLs

---

## Phase 3 — Checkout + Orders (Week 4)

### Objective
Complete the purchase flow end-to-end and order management.

### Tasks

**Naheed:**
- Support ticket creation screen
- Support ticket chat screen (messages, send)
- Parcel tracking (QR code screen)

**Arwah:**
- FCM token registration with backend
- Push notification handling (foreground, background, tap navigation)
- Notification mark-as-read

**Munaza:**
- Checkout review screen (order summary, confirm placement)
- Order confirmation screen (success animation, sub-order display)
- Place order API integration
- Cart clear after successful order

**Nimra:**
- Return request flow (eligibility check, form, evidence upload)
- Returns list screen
- Order cancellation (if status allows)

### Dependencies
- Munaza's order placement clears Nimra's cart (CartCubit)
- Nimra's returns need orders to exist
- Arwah's notifications need FCM backend endpoint

### Exit Criteria
- [ ] Complete purchase flow: Cart → Delivery → OTP → Review → Place Order → Confirmation
- [ ] Cart clears after successful order
- [ ] Returns can be submitted with reason + evidence
- [ ] Push notifications received and open correct screen on tap
- [ ] Support tickets can be created and have working chat

---

## Phase 4 — Polish + Edge Cases (Week 5)

### Objective
Handle all edge cases, error states, and polish the UX.

### Tasks

**All developers (own features):**
- Verify all loading/error/empty states are implemented per `ui-states.md`
- Handle edge cases: empty cart checkout attempt, expired session mid-checkout, stock changed during checkout
- Verify accessibility (semantic labels, contrast, touch targets)
- Verify animation guidelines followed
- Handle keyboard interactions on all form screens
- Pull-to-refresh on all data screens
- Verify back navigation behavior matches `05-navigation.md`

**Naheed:**
- Integration testing: deep link flows, notification navigation
- Performance check: product grid scroll at 60fps
- Final router verification: all guards, redirects, edge cases

**Arwah:**
- Session expiry edge cases (mid-checkout, mid-form)
- 401 handling in all features (verify redirect works from any screen)
- Rate limiting UI on all auth endpoints

**Munaza:**
- Checkout edge cases: stock drift (item unavailable after cart), price change detection
- Product detail: low stock badge, out-of-stock disable, age gate
- Image gallery: pinch-to-zoom, full-screen mode

**Nimra:**
- Cart persistence edge cases: model migration if cart schema changes
- Order status real-time (if long-poll), or manual refresh
- Return window calculation (7 days from delivery date)

### Exit Criteria
- [ ] Every screen handles loading, error, empty states
- [ ] No raw exceptions visible to user
- [ ] All form validations work with proper keyboard types
- [ ] App survives: airplane mode, session expiry, back button spam, rotation attempt
- [ ] Developer checklist passes for ALL features

---

## Phase 5 — Integration + Cross-Feature Testing (Week 6)

### Objective
Verify all features work together. Fix integration issues.

### Tasks

**All developers:**
- Run complete user journeys end-to-end (guest purchase, auth purchase, returns)
- Cross-feature testing: add to cart from search, from wishlist, from seller page
- Verify navigation state preservation (tab switch doesn't lose scroll)
- Test on multiple devices: budget Android (360dp), iPhone SE, iPhone 15 Pro Max
- Fix all integration bugs found

**Naheed:**
- Final deep link testing (cold start, warm start)
- Performance profiling with Flutter DevTools
- APK size analysis

**Arwah:**
- Security audit: no secrets in code, no PII in logs, HTTPS enforced
- Auth flow testing: all paths (login, register, OAuth, forgot, session expiry)

**Munaza:**
- Full checkout flow testing with real/staging API
- Product browsing performance (large category, many results)

**Nimra:**
- Cart→Checkout→Order full flow validation
- Order lifecycle testing (all statuses render correctly)

### Exit Criteria
- [ ] All 7 critical user journeys pass (from `17-testing-strategy.md`)
- [ ] No crashes on any tested device
- [ ] APK size < 30MB
- [ ] Cold start < 3s
- [ ] Product grid scrolls at 60fps

---

## Phase 6 — Testing + Release Prep (Week 7)

### Objective
Write remaining tests, prepare for release.

### Tasks

**All developers (own features):**
- Write `blocTest` for every cubit (success, error, edge cases)
- Write `fromJson`/`toJson` tests for all models
- Write widget tests for shared components used by their features
- Fix any bugs from Phase 5

**Naheed:**
- Integration test: guest purchase flow
- Integration test: deep link cold start
- Prepare release build configuration
- Play Store listing preparation (if applicable)

**Arwah:**
- Integration test: auth flow (register → verify → login → logout)
- Security checklist final pass
- ProGuard/R8 rules verification

**Munaza:**
- Integration test: product discovery → purchase
- Checkout with coupon test
- Verify all product edge cases (no variants, out of stock, age restricted)

**Nimra:**
- Integration test: cart management (add, qty, remove, persist)
- Cart validation test (price changed, out of stock)
- Returns submission test

### Exit Criteria
- [ ] 80%+ test coverage on cubits and repositories
- [ ] All model serialization tests pass
- [ ] Integration tests pass on device
- [ ] Release APK builds successfully
- [ ] No lint warnings
- [ ] `flutter analyze` clean
- [ ] Ready for internal testing / beta distribution

---

## Risk Buffer

The 7-week timeline assumes:
- Backend APIs are available by Week 2 (if delayed, use mock data and integrate later)
- No major scope changes
- 4 developers working full-time

**If backend is delayed:** Developers build with mock repositories that return hardcoded data. Real API integration becomes a parallel task when APIs are ready. This doesn't block UI/UX development.
