# Parallel Development Plan

## Visual Timeline (7 Weeks)

```
Week 1 ─── FOUNDATION (All 4 developers)
           ┌─────────────────────────────────────────────────┐
           │ Naheed: Project + Theme + Router + Shared Widgets│
           │ Arwah:  API Client + Auth System                 │
           │ Munaza: Models + Home (mock data)                │
           │ Nimra:  Shared Widgets + Cart + Formatters        │
           └─────────────────────────────────────────────────┘
                              │
Week 2 ───────────────────────┼───────────────────────────────
           ┌─────────┐  ┌─────────┐  ┌──────────┐  ┌─────────┐
           │ Naheed  │  │ Arwah   │  │ Munaza   │  │ Nimra   │
           │         │  │         │  │          │  │         │
           │ Search  │  │ Auth    │  │ Product  │  │ Cart    │
           │ screen  │  │ polish  │  │ Detail   │  │ validate│
           │         │  │ reCAPTCHA│  │ (full)   │  │         │
           │         │  │ Profile │  │          │  │ Wishlist│
           └─────────┘  └─────────┘  └──────────┘  └─────────┘
                              │
Week 3 ───────────────────────┼───────────────────────────────
           ┌─────────┐  ┌─────────┐  ┌──────────┐  ┌─────────┐
           │ Naheed  │  │ Arwah   │  │ Munaza   │  │ Nimra   │
           │         │  │         │  │          │  │         │
           │ Seller  │  │ Address │  │ Checkout │  │ Orders  │
           │ store   │  │ CRUD    │  │ delivery │  │ history │
           │         │  │ Change  │  │ + OTP    │  │ + detail│
           │ Deep    │  │ password│  │ Coupon   │  │         │
           │ links   │  │ Settings│  │          │  │ Tracking│
           └─────────┘  └─────────┘  └──────────┘  └─────────┘
                              │
Week 4 ───────────────────────┼───────────────────────────────
           ┌─────────┐  ┌─────────┐  ┌──────────┐  ┌─────────┐
           │ Naheed  │  │ Arwah   │  │ Munaza   │  │ Nimra   │
           │         │  │         │  │          │  │         │
           │ Support │  │ FCM +   │  │ Checkout │  │ Returns │
           │ tickets │  │ Push    │  │ review + │  │ (submit │
           │ + chat  │  │ notifs  │  │ Place    │  │ + list) │
           │         │  │         │  │ Order +  │  │         │
           │ Parcel  │  │ Notif   │  │ Confirm  │  │ Cancel  │
           │ track   │  │ screen  │  │          │  │ order   │
           └─────────┘  └─────────┘  └──────────┘  └─────────┘
                              │
Week 5 ───────────────────────┼───────────────────────────────
           ┌─────────┐  ┌─────────┐  ┌──────────┐  ┌─────────┐
           │ Naheed  │  │ Arwah   │  │ Munaza   │  │ Nimra   │
           │         │  │         │  │          │  │         │
           │ Static  │  │ Session │  │ Checkout │  │ Cart    │
           │ pages   │  │ edge    │  │ edge     │  │ edge    │
           │ (FAQ,   │  │ cases   │  │ cases    │  │ cases   │
           │ Terms)  │  │         │  │          │  │         │
           │         │  │ 401     │  │ Stock    │  │ Return  │
           │ Polish  │  │ flows   │  │ drift    │  │ window  │
           └─────────┘  └─────────┘  └──────────┘  └─────────┘
                              │
Week 6 ─── INTEGRATION (All 4 developers)
           ┌─────────────────────────────────────────────────┐
           │ Cross-feature testing                            │
           │ End-to-end user journeys                         │
           │ Multi-device testing                             │
           │ Performance profiling                            │
           │ Integration bug fixes                            │
           └─────────────────────────────────────────────────┘
                              │
Week 7 ─── TESTING + RELEASE (All 4 developers)
           ┌─────────────────────────────────────────────────┐
           │ Unit tests (cubits, models, repos)               │
           │ Widget tests (shared components)                  │
           │ Integration tests (critical journeys)            │
           │ Security audit                                   │
           │ Release build + configuration                    │
           └─────────────────────────────────────────────────┘
```

---

## Blocking Dependencies

| Task | Blocks | Must Be Done By |
|------|--------|-----------------|
| Naheed: Project setup (Day 1) | Everyone | Day 1 of Week 1 |
| Naheed: Theme + Router | All UI work | Day 3 of Week 1 |
| Arwah: API Client | All API features | Day 2 of Week 1 |
| Arwah: AuthCubit | Wishlist, Orders, Profile, Checkout, Support | End of Week 1 |
| Munaza: ProductModel | ProductCard widget, Home, Search, Seller, Wishlist | Day 2 of Week 1 |
| Nimra: CartCubit | Checkout | End of Week 1 |
| Nimra: Shared widgets | Everyone's UI | Day 3 of Week 1 |
| Arwah: Addresses | Checkout delivery | End of Week 3 |

---

## Parallel Streams (Zero Overlap)

After Foundation (Week 1), these streams run independently:

### Stream A — Naheed
```
Search → Seller → Support → Static pages → Deep links → Integration lead
```
No dependency on any other dev's feature work (only foundation).

### Stream B — Arwah
```
Auth polish → Profile → Addresses → Notifications → Session edge cases → Security
```
Self-contained. Only dependency: FCM backend endpoint for notifications.

### Stream C — Munaza
```
Product Detail → Checkout Delivery → Checkout OTP → Checkout Review → Place Order → Confirmation
```
Dependencies: Auth (Week 1), Cart (Week 1), Addresses (Week 3 — from Arwah).

### Stream D — Nimra
```
Cart validation → Wishlist → Orders → Returns → Cart edge cases
```
Dependencies: Auth (Week 1), Product models (Week 1).

---

## Integration Points (Where Streams Cross)

| Integration Point | Streams | When | How |
|-------------------|---------|------|-----|
| "Add to Cart" from product detail | Munaza (product detail) + Nimra (CartCubit) | Week 2 | Munaza calls `context.read<CartCubit>().addItem()` — CartCubit is global, no import needed |
| "Add to Wishlist" from product card | Nimra (wishlist) + Munaza (product card widget owned by Nimra) | Week 2 | Nimra adds wishlist toggle to ProductCard |
| Address picker in checkout | Munaza (checkout) + Arwah (AddressCubit) | Week 3 | Munaza uses Arwah's AddressCubit via context.read |
| Cart → Checkout navigation | Nimra (cart screen) + Munaza (checkout) | Week 3 | Nimra's "Proceed" button does `context.go('/checkout')` — route exists |
| Place order clears cart | Munaza (checkout) + Nimra (CartCubit) | Week 4 | Munaza calls `cartCubit.clear()` after order success |
| Notification tap → Order detail | Arwah (notifications) + Nimra (orders) | Week 4 | Arwah uses router: `context.go('/orders/$id')` — no direct import |

**Key insight:** All integration points use global cubits (accessed via `context.read`) or GoRouter navigation (path-based). No direct cross-feature imports needed. This is by design — the architecture prevents coupling.

---

## Risk: Backend API Delays

If backend APIs are not ready by the scheduled week:

| Week | What We Do Without APIs |
|------|------------------------|
| Week 1 | Build with mock repositories. UI/state/tests all work with fake data. |
| Week 2 | Continue with mocks. Full feature development proceeds. |
| Week 3 | If still no APIs: integration testing with mocks. Flag risk to project lead. |
| Week 4+ | Swap mock repos for real repos (one-file change per feature). Regression test. |

**Mock repositories** are not throwaway work — they become our test fixtures. The architecture (repository pattern) makes this swap trivial:

```dart
// Development: mock
BlocProvider(create: (_) => HomeCubit(MockHomeRepository()))

// Production: real
BlocProvider(create: (_) => HomeCubit(HomeRepository(apiClient)))
```

---

## Week-by-Week Developer Load

| Week | Naheed | Arwah | Munaza | Nimra |
|------|--------|-------|--------|-------|
| 1 | Heavy (project setup + theme + router + widgets) | Heavy (API client + full auth) | Medium (models + home shell) | Medium (widgets + cart + formatters) |
| 2 | Medium (search + seller) | Medium (auth polish + profile) | Heavy (product detail - 13 tasks) | Medium (cart validate + wishlist) |
| 3 | Medium (seller finish + deep links + static) | Medium (addresses + settings) | Heavy (checkout 3 screens) | Medium (orders 4 screens) |
| 4 | Medium (support tickets + chat) | Medium (FCM + notifications) | Medium (place order + confirmation) | Medium (returns + cancel) |
| 5 | Light (polish + edge cases) | Medium (session edge cases + 401 flows) | Medium (checkout edge cases) | Medium (cart/order edge cases) |
| 6 | Medium (integration lead + performance) | Medium (security audit) | Medium (checkout e2e testing) | Medium (order lifecycle testing) |
| 7 | Medium (integration tests + release) | Medium (auth tests + security) | Medium (product/checkout tests) | Medium (cart/order tests) |

No developer is idle at any point. No developer is overloaded beyond capacity.
