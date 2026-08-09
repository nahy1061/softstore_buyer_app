# Phase 2: MVP Scope & Prioritization

## MVP Definition

The MVP delivers the complete purchase loop: a buyer can discover a product, add it to cart, check out (with or without an account), and track their order. Every feature in the MVP must be functional end-to-end — no half-implemented flows.

---

## Prioritization Framework

Each feature is scored on three axes:

| Axis | Weight | 1 (Low) | 2 (Medium) | 3 (High) |
|------|--------|---------|------------|-----------|
| **Value** | 40% | Nice to have | Improves conversion/retention | Blocks purchase or core loop |
| **Complexity** | 35% | Simple UI, no backend | Moderate logic or new endpoint | Complex flow, new infra, or unknowns |
| **Risk** | 25% | Well-understood, no blockers | Some unknowns, manageable | Depends on unconfirmed backend, third-party, or new protocol |

**Priority score** = (Value × 0.4) + ((4 - Complexity) × 0.35) + ((4 - Risk) × 0.25)

Higher score = do first. Features scoring below 2.0 are deferred to Phase 2.

---

## MVP Feature Set (Ordered by Implementation Priority)

### Tier 1: Core Purchase Loop (Must ship first)

These features form the critical path. Without any one of them, the app cannot complete a purchase.

| # | Feature | Value | Complexity | Risk | Score | Notes |
|---|---------|-------|-----------|------|-------|-------|
| 1 | Store home / product grid | 3 | 1 | 1 | 3.05 | Foundation screen; everything depends on this |
| 2 | Product detail page | 3 | 2 | 1 | 2.70 | Gateway to purchase intent |
| 3 | Add to cart | 3 | 1 | 2 | 2.80 | Risk: cart storage strategy (local vs server) |
| 4 | Cart screen | 3 | 1 | 1 | 3.05 | View and edit before checkout |
| 5 | Checkout - delivery form | 3 | 2 | 1 | 2.70 | Collect shipping info |
| 6 | Checkout - email OTP | 3 | 2 | 2 | 2.45 | Required before order placement |
| 7 | Checkout - place order | 3 | 2 | 2 | 2.45 | The revenue event |
| 8 | Order confirmation | 3 | 1 | 1 | 3.05 | Must show after successful order |
| 9 | Pricing display (tax-inclusive) | 3 | 1 | 1 | 3.05 | PricingService already handles this |
| 10 | Delivery fee logic | 3 | 1 | 1 | 3.05 | Rs 199 / free above Rs 1,500 |

### Tier 2: Authentication & Identity

Required for order history, wishlist, and faster repeat purchases.

| # | Feature | Value | Complexity | Risk | Score | Notes |
|---|---------|-------|-----------|------|-------|-------|
| 11 | Email/password login | 3 | 2 | 2 | 2.45 | Need to confirm: JWT or session token for mobile? |
| 12 | Registration | 3 | 2 | 1 | 2.70 | Simple form, known fields |
| 13 | Google OAuth | 3 | 2 | 2 | 2.45 | Reduces friction; needs Google Sign-In SDK |
| 14 | Logout | 2 | 1 | 1 | 2.25 | Simple POST + clear local state |
| 15 | Session management (token) | 3 | 2 | 3 | 2.20 | HIGH RISK: backend must support mobile tokens |
| 16 | Forgot password | 2 | 2 | 2 | 2.00 | Needs backend confirmation on flow |

### Tier 3: Discovery & Search

Enables users to find products beyond the home grid.

| # | Feature | Value | Complexity | Risk | Score | Notes |
|---|---------|-------|-----------|------|-------|-------|
| 17 | Text search | 3 | 1 | 1 | 3.05 | Uses existing /store?search= endpoint |
| 18 | Category browsing | 3 | 1 | 1 | 3.05 | Filter param on same endpoint |
| 19 | Sort (4 options) | 2 | 1 | 1 | 2.25 | Client triggers server sort param |
| 20 | Price range filter | 2 | 1 | 1 | 2.25 | Query params min_price, max_price |
| 21 | Free delivery filter | 2 | 1 | 1 | 2.25 | Query param free_del |
| 22 | Seller store page | 2 | 2 | 1 | 1.90 | Reuses product grid with store context |
| 23 | Active filter chips | 2 | 1 | 1 | 2.25 | Client-side UI only |

### Tier 4: Product Detail Completeness

Makes the product page fully functional and conversion-ready.

| # | Feature | Value | Complexity | Risk | Score | Notes |
|---|---------|-------|-----------|------|-------|-------|
| 24 | Image gallery (swipeable) | 3 | 2 | 1 | 2.70 | Standard Flutter pattern |
| 25 | Variant selection | 3 | 2 | 1 | 2.70 | Price updates on variant pick |
| 26 | Quantity selector | 2 | 1 | 1 | 2.25 | Stepper capped at stock |
| 27 | Stock status display | 2 | 1 | 1 | 2.25 | Badge from availableStock |
| 28 | Buy now (direct checkout) | 2 | 1 | 1 | 2.25 | Add to cart + navigate |
| 29 | Description/specs sections | 2 | 1 | 1 | 2.25 | Render HTML or plain text |
| 30 | Reviews display | 2 | 2 | 1 | 1.90 | Rating bars + review cards |
| 31 | Related products | 2 | 1 | 1 | 2.25 | Horizontal carousel |
| 32 | Seller info card | 2 | 1 | 1 | 2.25 | Name + link to store |
| 33 | WhatsApp seller | 2 | 1 | 1 | 2.25 | External deep link |
| 34 | Share product | 2 | 1 | 1 | 2.25 | Native share sheet |
| 35 | FBA badge | 1 | 1 | 1 | 1.45 | Simple conditional badge |
| 36 | Discount badge | 2 | 1 | 1 | 2.25 | Shows % off from PricingService |

### Tier 5: Order Management

Post-purchase experience for returning users.

| # | Feature | Value | Complexity | Risk | Score | Notes |
|---|---------|-------|-----------|------|-------|-------|
| 37 | Order history list | 3 | 2 | 1 | 2.70 | Paginated list with status |
| 38 | Order detail | 3 | 2 | 1 | 2.70 | Items, amounts, timeline |
| 39 | Status pipeline | 2 | 2 | 1 | 1.90 | 5-step visual stepper |
| 40 | Tracking timeline | 2 | 2 | 1 | 1.90 | History entries with notes |
| 41 | Public order tracking | 2 | 2 | 1 | 1.90 | Invoice + phone form |
| 42 | Copy order reference | 1 | 1 | 1 | 1.45 | Clipboard write |

### Tier 6: Account Management

Supports repeat usage and faster checkouts.

| # | Feature | Value | Complexity | Risk | Score | Notes |
|---|---------|-------|-----------|------|-------|-------|
| 43 | Profile view/edit | 2 | 1 | 1 | 2.25 | Simple form |
| 44 | Address book (CRUD) | 3 | 2 | 2 | 2.45 | Needs backend confirmation on endpoints |
| 45 | Saved address at checkout | 3 | 2 | 2 | 2.45 | Depends on address book API |
| 46 | Wishlist (view + toggle) | 2 | 2 | 1 | 1.90 | Grid + toggle API confirmed |
| 47 | Account dashboard (stats) | 1 | 1 | 1 | 1.45 | Nice to have overview |

### Tier 7: Checkout Enhancements

| # | Feature | Value | Complexity | Risk | Score | Notes |
|---|---------|-------|-----------|------|-------|-------|
| 48 | Coupon code validation | 2 | 2 | 1 | 1.90 | API confirmed |
| 49 | Guest checkout (no login) | 3 | 1 | 1 | 3.05 | Already supported by OTP flow |
| 50 | Sign-in prompt at checkout | 2 | 1 | 1 | 2.25 | Non-blocking banner |

### Tier 8: Support & Utility

| # | Feature | Value | Complexity | Risk | Score | Notes |
|---|---------|-------|-----------|------|-------|-------|
| 51 | Deep linking (/product/{slug}) | 2 | 2 | 2 | 1.65 | Requires URL scheme config |
| 52 | FAQ | 1 | 1 | 1 | 1.45 | Static content |
| 53 | Contact form | 1 | 1 | 1 | 1.45 | Simple POST |
| 54 | Terms/Privacy | 1 | 1 | 1 | 1.45 | WebView |
| 55 | App onboarding | 1 | 1 | 1 | 1.45 | 3 intro slides |
| 56 | Force update check | 2 | 2 | 1 | 1.90 | Version check on launch |

---

## MVP Exclusions (Phase 2 and Beyond)

| Feature | Reason for Deferral | Phase |
|---------|-------------------|-------|
| Push notifications (FCM) | Requires new backend infrastructure (FCM tokens, notification service) | Phase 2 |
| In-app notifications list | No existing endpoint; needs new backend work | Phase 2 |
| Biometric auth | Enhancement, not blocking; first login still needed | Phase 2 |
| Submit review | Read reviews is MVP; writing them is secondary | Phase 2 |
| Reorder (add all to cart) | Convenience; manual re-add works for MVP | Phase 2 |
| Order cancellation | Backend confirmation needed; unclear if API exists | Phase 2 |
| Return requests | Complex form + backend API needs confirmation | Phase 2 |
| Search suggestions/autocomplete | No existing endpoint | Future |
| Recent search history | Nice to have; can use local storage | Phase 2 |
| AI checkout recommendations | Fire-and-forget; low priority | Future |
| Barcode scanner | No use case established yet | Future |
| Offline mode (full) | Complex sync logic; connectivity is improving | Phase 2 |
| Dark mode | Cosmetic; no business impact | Phase 2 |
| Multi-language (Urdu) | RTL layout requires significant work | Future |
| Hero/featured section | Low engagement vs. immediate product browsing | Phase 2 |

---

## Implementation Order (Suggested Sprints)

### Sprint 1: Foundation (2 weeks)
- Project setup (Flutter, state management, HTTP client, routing)
- Store home screen (product grid, infinite scroll)
- Product detail screen (gallery, pricing, variants)
- Add to cart (local storage for now)
- Cart screen (edit qty, remove, totals)
- API integration layer (base HTTP client, error handling)

### Sprint 2: Purchase Flow (2 weeks)
- Checkout step 1 (delivery form with validation)
- Checkout step 2 (email OTP send/verify)
- Checkout step 3 (review, coupon, place order)
- Order confirmation screen
- Delivery fee logic
- Error/loading states for checkout

### Sprint 3: Authentication (1.5 weeks)
- Login screen (email/password)
- Registration screen
- Google OAuth integration
- Token storage and auto-login
- Session expiry handling (401 intercept)
- Forgot password screen

### Sprint 4: Discovery (1 week)
- Search (query submission, results display)
- Category browsing (chips, filtered grid)
- Sort bottom sheet
- Price range filter
- Filter chips

### Sprint 5: Orders & Account (2 weeks)
- Order history list (paginated)
- Order detail (items, timeline, status pipeline)
- Public order tracking
- Profile view/edit
- Address book (list, add, edit, delete)
- Saved address at checkout

### Sprint 6: Polish & Remaining (1.5 weeks)
- Wishlist (view, add/remove toggle)
- Deep linking setup
- Onboarding slides
- FAQ, Contact, Terms screens
- Seller store page
- App update check
- Bug fixes, edge cases, loading states

**Total estimated: ~10 weeks** (1 developer, full time)

---

## MVP Success Criteria

| Metric | Target | Measurement |
|--------|--------|-------------|
| Complete purchase possible | 100% | End-to-end test: browse → cart → checkout → confirmation |
| Guest checkout works | 100% | No account required for first purchase |
| Order tracking accessible | 100% | Both authenticated (order history) and public (invoice+phone) |
| App launch to product detail | < 3 taps | Home → tap product |
| Checkout completion | < 5 minutes | From cart to confirmation on average |
| Crash-free sessions | > 99% | No crash on happy path |
| Works on Android 8+ / iOS 14+ | 100% | Test on minimum supported versions |
| Works on 3G/slow connection | Functional | Timeout handling, loading states, retry |

---

## Critical Dependencies & Blockers

### Must Resolve Before Development

| # | Question | Impact | Who to Ask |
|---|----------|--------|-----------|
| 1 | **Mobile authentication mechanism?** JWT tokens? OAuth2 with refresh? How long do they live? | Blocks: all authenticated features (orders, profile, wishlist, saved addresses) | Backend team |
| 2 | **Server-side cart API?** Does one exist or does mobile use localStorage approach? | Blocks: cross-device cart sync; affects checkout payload | Backend team |
| 3 | **Address CRUD endpoints confirmed?** GET list, POST create, PUT update, DELETE? | Blocks: address book, saved addresses at checkout | Backend team |
| 4 | **Password reset flow for mobile?** OTP-based or magic link? Deep link handling? | Blocks: forgot password feature | Backend team |
| 5 | **Order cancellation API?** Does buyer have cancel endpoint? Which statuses allow it? | Determines: if cancel goes in MVP or Phase 2 | Backend team |
| 6 | **Return submission endpoint format?** Is it exactly as found in source (POST /marketplace/account/orders/{id}/return)? | Determines: if returns go in MVP or Phase 2 | Backend team |
| 7 | **API response format?** Are existing web endpoints JSON-capable or do we need new mobile API routes? | Blocks: entire API integration layer | Backend team |
| 8 | **CORS / API gateway?** Will mobile hit same domain or dedicated API subdomain? | Affects: base URL config, auth headers | Backend team |
| 9 | **Push notification infrastructure?** FCM project setup, token storage endpoint? | Phase 2 planning | Backend team |
| 10 | **Image CDN / resizing?** Can we request different image sizes (thumbnail vs full)? | Performance on slow networks | Backend team |

### Can Proceed With Assumptions

| Assumption | Fallback if Wrong |
|-----------|------------------|
| Existing web endpoints return JSON when Accept: application/json | Build adapter layer to parse HTML (unlikely needed) |
| Cart checkout payload is same for mobile | Adjust payload format |
| Google OAuth audience='buyer' redirect works for mobile | Implement custom OAuth flow |
| OTP at checkout works identically for mobile sessions | Add mobile session identifier to OTP call |

---

## Risk Register

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|-----------|
| Backend has no JWT/token auth for mobile | Medium | High — blocks all auth | Start with guest-only MVP; add auth in parallel sprint |
| Cart is truly client-only (no server API) | High | Medium — no cross-device sync | Keep local cart for MVP; build cart API for Phase 2 |
| Web endpoints don't return JSON | Low | High — need API rewrite | Verify early in Sprint 1; if true, prioritize API layer |
| Google OAuth flow differs for mobile | Low | Medium — delays auth sprint | Start with email/password; add Google after |
| Order cancellation not supported | Medium | Low — not in MVP anyway | Defer to Phase 2 with backend confirmation |
| Slow API responses on Pakistani networks | Medium | Medium — poor UX | Aggressive caching, optimistic UI, skeleton loading |
