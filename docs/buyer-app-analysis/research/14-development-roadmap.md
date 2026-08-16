# Phase 4: Development Roadmap

## Overview

The development is organized into 7 phases, ordered by dependency chain. Each phase produces a working increment — no phase depends on future work.

**Total estimated duration:** 10–12 weeks (2–3 Flutter developers)

---

## Phase 0: Foundation Setup (Week 1)

### Features
- Flutter project scaffolding
- Architecture skeleton (folder structure from `06-flutter-architecture.md`)
- Core packages installation and configuration
- Dio HTTP client with interceptors (cookie jar, auth, retry)
- GoRouter setup with bottom navigation shell
- Theme (orange/amber palette, typography, spacing)
- Shared widgets (product card, loading skeleton, error state, empty state, price display)
- Data models (all `@JsonSerializable` classes from `09-data-models.md`)
- Constants (API URLs, delivery fee, thresholds, storage keys)

### Dependencies
- None (greenfield)

### Deliverables
- Running app with 5-tab bottom navigation (placeholder screens)
- API client that can make authenticated requests with cookie persistence
- All data models with serialization
- Theme applied globally
- Linting and analysis configured

### Definition of Done
- [ ] `flutter run` succeeds on Android and iOS
- [ ] Bottom navigation switches between 5 placeholder tabs
- [ ] Dio interceptor logs requests in debug mode
- [ ] Cookie jar persists across app restarts (verified manually)
- [ ] All models serialize/deserialize from sample JSON fixtures
- [ ] Theme colors match brand palette (#FF6F00 primary)
- [ ] analysis_options.yaml enforces project lint rules
- [ ] Folder structure matches architecture doc

### Testing Requirements
- Unit tests for all model `fromJson`/`toJson`
- Unit tests for formatters (PKR currency, phone, date)
- Unit tests for validators (email, phone, password, name)
- Widget test for bottom navigation (tab switching)

---

## Phase 1: Product Browsing (Weeks 2–3)

### Features
- Store home screen (product grid, infinite scroll, pull-to-refresh)
- Category chips (horizontal scroll)
- Product card widget (image, name, price, seller, discount badge)
- Sort bottom sheet (newest, price-low, price-high)
- Filter bottom sheet (price range slider, free delivery toggle)
- Active filter chips (dismissible)
- Search screen (query input, results, recent searches)
- Search suggestions (`GET /api/store/search-suggest`)
- Category view (pre-filtered grid)
- Product detail screen (gallery, pricing, variants, description, specs, reviews, related, seller card)
- Image gallery (full-screen swipeable, pinch-to-zoom)
- Variant selector (chip-style, price update)
- Seller store page (banner, product grid)
- Deep linking for `/product/{slug}` and `/store/{slug}`

### Dependencies
- Phase 0 (API client, models, theme, shared widgets)
- Backend: `GET /api/store/products`, `GET /api/store/products/{slug}`, `GET /api/store/categories`, `GET /api/store/search-suggest`, `GET /api/store/sellers/{slug}`

### Deliverables
- Fully browsable marketplace
- Product detail with all sections
- Search with suggestions
- Category and seller browsing
- Deep links open correct product/store

### Definition of Done
- [ ] Home loads product grid from API with pagination
- [ ] Infinite scroll loads next page at scroll threshold
- [ ] Pull-to-refresh reloads page 1
- [ ] Category chips filter products
- [ ] Sort changes product order
- [ ] Price filter narrows results
- [ ] Search returns results with debounced suggestions
- [ ] Product detail displays all data sections
- [ ] Image gallery supports swipe and pinch-to-zoom
- [ ] Variant selection updates displayed price
- [ ] Related products carousel scrolls horizontally
- [ ] Seller store page loads with their products
- [ ] Deep link `softstore://product/test-product` opens detail
- [ ] Loading skeletons shown during fetch
- [ ] Error state shown with retry on failure
- [ ] Empty state shown when no results

### Testing Requirements
- Unit tests: HomeCubit (load, paginate, filter, sort, error states)
- Unit tests: SearchCubit (query, suggestions, debounce)
- Unit tests: ProductDetailCubit (load, variant select, price update)
- Widget tests: ProductCard, CategoryChips, FilterSheet, PriceDisplay
- Integration test: browse home → tap product → see detail

---

## Phase 2: Cart & Local Storage (Week 4)

### Features
- Add to cart (from product detail and product card)
- Cart screen (item list, quantity stepper, remove, totals)
- Cart badge on bottom nav
- Delivery fee calculation (Rs 199 / free above Rs 1,500)
- Free delivery progress indicator
- Cart persistence (SharedPreferences)
- Empty cart state
- Age restriction check (modal before adding restricted products)
- Buy Now (add to cart + navigate to checkout)

### Dependencies
- Phase 1 (product detail with add-to-cart button)
- Backend: `POST /api/store/cart/validate-item`, `POST /api/store/cart/age-check`

### Deliverables
- Fully functional local cart
- Persists across app restarts
- Validates stock on add
- Shows correct totals and delivery fee

### Definition of Done
- [ ] Add to cart from product detail works (with variant)
- [ ] Add to cart from product card works (default variant)
- [ ] Cart screen shows all items with images, names, prices
- [ ] Quantity stepper increments/decrements (min 1, max stock)
- [ ] Swipe-to-delete removes item
- [ ] Subtotal, delivery fee, and total calculate correctly
- [ ] Free delivery threshold shows progress bar
- [ ] Cart badge shows item count
- [ ] Cart persists after app kill + relaunch
- [ ] Empty cart shows illustration + "Browse marketplace" CTA
- [ ] Age restriction modal appears for restricted products
- [ ] Buy Now adds to cart then navigates to checkout
- [ ] Toast confirms "Added to cart"

### Testing Requirements
- Unit tests: CartCubit (add, remove, update qty, clear, persistence, delivery fee logic)
- Unit tests: Cart model serialization to/from JSON
- Widget tests: CartItemTile, quantity stepper, empty state
- Integration test: add product → open cart → verify item present → update qty → total changes

---

## Phase 3: Authentication (Weeks 5–6)

### Features
- Login screen (email/password + Google OAuth)
- Register screen (full_name, email, phone, password)
- OTP verification screen (6-digit, auto-advance, resend)
- Forgot password screen (email entry)
- Reset password screen (new password, deep link from email)
- reCAPTCHA invisible widget integration
- Session cookie management
- Auth state (global Cubit)
- Route protection (redirect to login for protected routes)
- Post-login navigation (?next parameter)
- Session expiry handling (401 → logout → login)
- Profile hub screen
- Edit profile screen
- Change password screen
- Address book (list, add, edit, delete, set default)
- Logout with confirmation

### Dependencies
- Phase 0 (API client with cookie jar)
- Backend: All `/api/buyer/*` auth endpoints, `/api/buyer/addresses`, `/api/buyer/profile`

### Deliverables
- Complete auth flow (login, register, OAuth, password reset)
- Protected route enforcement
- Profile management
- Address CRUD

### Definition of Done
- [ ] Login with email/password sets session cookie
- [ ] Login with Google OAuth works end-to-end
- [ ] Registration creates account and sends OTP
- [ ] OTP screen verifies email
- [ ] Forgot password sends reset link
- [ ] Reset password (via deep link) updates password
- [ ] reCAPTCHA token included in login/register requests
- [ ] Protected routes redirect to `/login?next=` when unauthenticated
- [ ] After login, navigates to ?next target or home
- [ ] 401 response triggers logout + login redirect
- [ ] App restarts with valid session → auto-authenticated
- [ ] Profile shows and edits user info
- [ ] Address book CRUD works (add, edit, delete, default)
- [ ] Logout clears session, preserves cart
- [ ] reCAPTCHA widget invisible during normal flow

### Testing Requirements
- Unit tests: AuthCubit (login, register, logout, session check, expiry)
- Unit tests: AuthRepository (cookie handling, token verification)
- Unit tests: ProfileCubit, AddressCubit (CRUD operations)
- Widget tests: Login form validation, OTP input auto-advance
- Integration test: register → verify OTP → land on home → logout → login → land on home

---

## Phase 4: Checkout & Order Placement (Weeks 6–7)

### Features
- Checkout delivery step (form, saved address picker)
- Checkout email verification step (send OTP, verify)
- Checkout review step (order summary, coupon, totals, place order)
- Coupon validation
- Order confirmation screen (success animation, reference, sub-orders)
- Cart validation before checkout (stock/price check)
- Post-checkout navigation (clear cart, can't go back)
- Guest checkout (no login required, email OTP is the gate)
- Sign-in prompt banner (non-blocking)

### Dependencies
- Phase 2 (cart with items to checkout)
- Phase 3 (auth for saved addresses, but guest checkout works without)
- Backend: `/api/store/checkout/*`, `/api/store/validate-coupon`, `/api/store/cart/validate`

### Deliverables
- Complete checkout flow (3 steps)
- Order placement with server-side validation
- Coupon support
- Guest and authenticated checkout

### Definition of Done
- [ ] Delivery form validates all fields client-side
- [ ] Saved addresses appear for logged-in users
- [ ] Address picker bottom sheet allows selection
- [ ] Email OTP sends and verifies
- [ ] Already-verified email skips OTP step
- [ ] Coupon code validates and shows discount
- [ ] Invalid coupon shows error inline
- [ ] Order summary shows correct items, totals, delivery fee
- [ ] "Place order" submits to API with full payload
- [ ] Out-of-stock items caught before submission
- [ ] Success → order confirmation with reference number
- [ ] Cart cleared after successful order
- [ ] Back navigation from confirmation goes to home (not checkout)
- [ ] Guest checkout works end-to-end without login
- [ ] Network error during checkout shows retry

### Testing Requirements
- Unit tests: CheckoutCubit (form validation, OTP states, coupon, place order, errors)
- Unit tests: Checkout payload construction
- Widget tests: OTP input, coupon field, address picker
- Integration test: cart → checkout → fill delivery → verify email → place order → confirmation

---

## Phase 5: Orders & Tracking (Week 8)

### Features
- Order history screen (paginated list, status badges)
- Order detail screen (items, status pipeline, timeline, amounts)
- Public order tracking (invoice + phone form)
- Track order screen (pipeline, timeline, seller info)
- Status badge component (colored by status)
- Copy invoice number
- Return request (Phase 2 scope — bottom sheet form)
- Returns list screen

### Dependencies
- Phase 3 (auth required for order history)
- Phase 4 (orders exist after checkout)
- Backend: `/api/buyer/orders`, `/api/buyer/orders/{id}`, `/api/store/track-order`, `/api/buyer/orders/{id}/return`, `/api/buyer/returns`

### Deliverables
- Full order management post-purchase
- Public tracking for guests
- Return request filing

### Definition of Done
- [ ] Order history loads with pagination
- [ ] Status filter tabs work
- [ ] Order detail shows all sections
- [ ] Status pipeline highlights current step
- [ ] Timeline shows history entries with seller notes
- [ ] Copy invoice number works (clipboard)
- [ ] Public tracking form validates and shows results
- [ ] Return request (if eligible) opens form sheet
- [ ] Return submitted successfully with confirmation
- [ ] Returns list shows all return requests
- [ ] Parcel QR deep link (`/parcel/{token}`) shows order info

### Testing Requirements
- Unit tests: OrdersCubit (load, paginate, filter)
- Unit tests: OrderDetailCubit (load, return eligibility)
- Widget tests: Status pipeline, timeline, order card
- Integration test: place order → view in history → see detail → track via public form

---

## Phase 6: Wishlist, Seller Features & Support (Week 9)

### Features
- Wishlist screen (product grid with remove)
- Wishlist toggle (heart icon on product detail and cards)
- Store follow/unfollow
- Store rating (delivered buyers only)
- Support ticket creation
- Support ticket chat (messages, long-poll refresh)
- FAQ screen (expandable accordion)
- Contact form
- Terms/Privacy (WebView)

### Dependencies
- Phase 3 (auth for wishlist, support)
- Phase 1 (product detail for wishlist toggle)
- Backend: `/api/buyer/wishlist/*`, `/api/store/sellers/{slug}/follow`, `/api/store/sellers/{slug}/rate`, `/api/buyer/support/*`

### Deliverables
- Complete wishlist functionality
- Seller engagement features
- Support system
- Info screens

### Definition of Done
- [ ] Wishlist toggle works from product detail (heart fills/unfills)
- [ ] Wishlist toggle prompts login if not authenticated
- [ ] Wishlist screen shows all items, remove works
- [ ] Follow/unfollow store works
- [ ] Store rating works (only for eligible buyers)
- [ ] Support ticket creation form submits
- [ ] Support chat shows messages and allows replies
- [ ] FAQ accordion expands/collapses sections
- [ ] Contact form submits successfully
- [ ] Terms/Privacy open in WebView

### Testing Requirements
- Unit tests: WishlistCubit (toggle, load, optimistic update)
- Unit tests: SupportCubit (create ticket, load messages, send)
- Widget tests: Heart toggle, FAQ accordion
- Integration test: add to wishlist → view wishlist → remove

---

## Phase 7: Polish, Notifications & Launch Prep (Weeks 10–12)

### Features
- Push notifications (FCM setup, token registration, navigation)
- In-app notification banner (foreground)
- Notification list screen
- App onboarding (3 slides, first-launch only)
- Force update check
- Connectivity monitoring (offline banner)
- Performance optimization (image caching, lazy loading)
- Error boundary (crash recovery)
- Analytics events (basic)
- App icon, splash screen
- Android/iOS store metadata preparation
- Final deep linking verification
- Accessibility pass (screen reader labels, contrast, touch targets)

### Dependencies
- All previous phases
- Backend: `/api/buyer/notifications/*`, FCM server setup

### Deliverables
- Production-ready app
- Push notifications working
- Polished UX (loading, errors, empty states, animations)
- Store-ready builds

### Definition of Done
- [ ] FCM token registered on login
- [ ] Push notifications received in background and foreground
- [ ] Notification tap navigates to correct screen
- [ ] Onboarding shows on first launch only
- [ ] Force update blocks app if version is too old
- [ ] Offline banner shows when connectivity lost
- [ ] All loading states use skeleton shimmer
- [ ] All error states show retry button
- [ ] All empty states show illustration + CTA
- [ ] App icon and splash correct on both platforms
- [ ] No crashes on happy path (monkey-tested)
- [ ] Accessibility: all interactive elements have labels
- [ ] Performance: product list scrolls at 60fps
- [ ] Deep links verified for all supported paths

### Testing Requirements
- Integration tests: full purchase flow end-to-end
- Integration tests: notification tap → navigation
- Performance testing: list scroll jank measurement
- Manual testing: all screens on low-end device
- Manual testing: all screens on slow network (3G throttle)
- Security testing: no sensitive data in logs or screenshots

---

## Phase Summary

| Phase | Duration | Features | Screens |
|-------|----------|----------|---------|
| 0: Foundation | 1 week | Architecture, theme, models, API client | 0 (placeholders) |
| 1: Browsing | 2 weeks | Home, search, product detail, seller | 8 |
| 2: Cart | 1 week | Cart, add-to-cart, delivery logic | 2 |
| 3: Auth | 2 weeks | Login, register, profile, addresses | 10 |
| 4: Checkout | 1.5 weeks | 3-step checkout, confirmation | 5 |
| 5: Orders | 1 week | Order history, detail, tracking, returns | 5 |
| 6: Extras | 1 week | Wishlist, support, FAQ, seller features | 6 |
| 7: Polish | 2 weeks | Notifications, onboarding, performance | 2 |
| **Total** | **~11 weeks** | **56 features** | **38 screens** |
