# Development Dependencies

## Dependency Graph

```
┌─────────────────────────────────────────────────────────────────┐
│                     FOUNDATION (Week 1)                          │
│  Project setup, folder structure, theme, design system,          │
│  API client, routing shell, error handling, shared widgets,      │
│  environment config                                              │
└────────────────────────────┬────────────────────────────────────┘
                             │
              ┌──────────────┼──────────────┐
              ▼              ▼              ▼
┌─────────────────┐  ┌─────────────┐  ┌──────────────────┐
│ AUTHENTICATION  │  │  PRODUCTS   │  │    PROFILE       │
│ (Week 2)        │  │  (Week 2-3) │  │    (Week 3)      │
│                 │  │             │  │                  │
│ Login           │  │ Home screen │  │ Profile hub      │
│ Register        │  │ Product list│  │ Edit profile     │
│ Google OAuth    │  │ Categories  │  │ Addresses        │
│ Session mgmt    │  │ Search      │  │ Change password  │
│ Forgot password │  │ Seller page │  │ Settings         │
│ OTP verify      │  │ Product det.│  │                  │
└────────┬────────┘  └──────┬──────┘  └────────┬─────────┘
         │                   │                   │
         │         ┌─────────┴────────┐          │
         │         ▼                  ▼          │
         │  ┌─────────────┐   ┌───────────┐     │
         │  │   WISHLIST  │   │   CART    │     │
         │  │  (Week 3)   │   │ (Week 2-3)│     │
         │  │             │   │           │     │
         │  │ Requires:   │   │ Local     │     │
         │  │  Auth       │   │ storage   │     │
         │  │  Products   │   │ No auth   │     │
         │  └──────┬──────┘   └─────┬─────┘     │
         │         │                │            │
         │         └────────┬───────┘            │
         │                  ▼                    │
         │         ┌────────────────┐            │
         │         │   CHECKOUT    │            │
         │         │   (Week 4)    │            │
         │         │               │            │
         │         │ Requires:     │            │
         │         │  Auth         │            │
         │         │  Cart         │◄───────────┘ (Addresses)
         │         │  Addresses    │
         │         └───────┬───────┘
         │                 │
         │                 ▼
         │        ┌────────────────┐
         │        │    ORDERS     │
         │        │   (Week 4-5)  │
         │        │               │
         └───────►│ Requires:     │
                  │  Auth         │
                  │  Checkout     │
                  │  (for context)│
                  └───────┬───────┘
                          │
              ┌───────────┼───────────┐
              ▼                       ▼
    ┌──────────────────┐    ┌────────────────┐
    │   RETURNS        │    │ NOTIFICATIONS  │
    │   (Week 5)       │    │ (Week 5)       │
    │                  │    │                │
    │ Requires: Orders │    │ Requires: Auth │
    └──────────────────┘    │ + FCM setup    │
                            └────────────────┘
                                    │
                                    ▼
                          ┌────────────────┐
                          │   SUPPORT      │
                          │   (Week 5-6)   │
                          │                │
                          │ Requires: Auth │
                          └────────────────┘
                                    │
                                    ▼
                          ┌────────────────┐
                          │  INTEGRATION   │
                          │  & TESTING     │
                          │  (Week 6-7)    │
                          └────────────────┘
```

---

## Blocking Tasks (Must Be Done First)

These block all other work:

| Task | Blocks | Why |
|------|--------|-----|
| Flutter project setup + folder structure | Everything | No code can be written without it |
| `pubspec.yaml` with all dependencies | Everything | No imports work without it |
| `app_theme.dart` + design system files | All UI work | Devs need tokens to build screens |
| `app/router.dart` shell (routes without screens) | All navigation | Screens need routes to exist |
| `core/network/api_client.dart` (Dio + interceptors) | All API features | No feature can call the backend |
| `core/errors/failures.dart` | All repositories | Repos need Failure types to throw |
| `AuthCubit` + session management | Orders, Wishlist, Profile, Support, Checkout | Protected routes redirect without it |
| `ProductModel` + `CategoryModel` | Home, Search, Seller, Cart, Wishlist | Shared model used everywhere |
| `CartCubit` (global) | Checkout | Checkout reads cart state |

---

## Independent Tasks (Can Run in Parallel After Foundation)

| Task | Depends On | Independent Of |
|------|-----------|---------------|
| Home screen + product grid | Foundation, ProductModel | Auth, Orders, Profile |
| Categories screen | Foundation, CategoryModel | Auth, Cart, Orders |
| Search screen | Foundation, ProductModel | Auth, Orders |
| Cart (local storage) | Foundation, CartItem model | Auth (cart works for guests) |
| Profile screens | Foundation, Auth | Products, Cart |
| Address CRUD | Foundation, Auth | Products, Cart, Orders |
| Product detail screen | Foundation, ProductModel | Cart (can add later) |
| Seller store screen | Foundation, SellerModel | Auth (follow needs it, but page loads without) |

---

## Shared Foundation Tasks (Everyone Benefits, Built Once)

| Task | Affects | Should Be Done By |
|------|---------|-------------------|
| Shared widgets (15 components in `core/widgets/`) | Every feature | Foundation owner, with team input |
| Theme + design tokens | Every screen | Foundation owner |
| Router setup | Every screen | Foundation owner |
| API client + interceptors | Every feature with API calls | Foundation owner |
| Error handling pattern | Every repository | Foundation owner |
| Validators | Auth, Checkout, Profile | Foundation owner |
| Formatters (PKR, phone, date) | Products, Cart, Orders | Foundation owner |

---

## Backend-Dependent Tasks

| Feature | Backend API Needed | Exists Today? | Blocking? |
|---------|-------------------|---------------|-----------|
| Login / Register | `/api/buyer/login`, `/api/buyer/register` | PROPOSED (not built) | YES — blocks auth |
| Google OAuth | `/api/buyer/auth/google` | PROPOSED | YES — blocks OAuth |
| Product list | `/api/store/products` | PROPOSED (web serves HTML) | YES — blocks product browsing |
| Product detail | `/api/store/products/{slug}` | PROPOSED | YES — blocks detail screen |
| Search suggest | `/api/store/search-suggest` | EXISTS | No |
| Cart validate | `/api/store/cart/validate-item` | PROPOSED (variant of existing) | Partial — cart works locally |
| Wishlist | `/api/buyer/wishlist` | PROPOSED | YES — blocks wishlist |
| Checkout OTP | `/api/store/checkout/send-code` | PROPOSED (variant exists) | YES — blocks checkout |
| Place order | `/api/store/checkout` | PROPOSED | YES — blocks order placement |
| Order history | `/api/buyer/orders` | PROPOSED | YES — blocks orders |
| Addresses | `/api/buyer/addresses` | PROPOSED | YES — blocks address mgmt |
| Profile | `/api/buyer/profile` | PROPOSED | YES — blocks profile |
| Support tickets | `/api/buyer/support/tickets` | PROPOSED | YES — blocks support |
| Notifications | `/api/buyer/notifications` | PROPOSED | YES — blocks notifications |
| CSRF token | `/api/csrf-token` | PROPOSED | Only if backend requires CSRF on API |

**Key insight:** ALL buyer-specific JSON APIs are PROPOSED. The backend currently serves HTML. The backend team must build these API routes before mobile can integrate. However, we can build screens with mock data / hardcoded responses and integrate real APIs when ready.

---

## Tasks That Can Run in Full Parallel (After Foundation + Auth)

```
Developer A: Search + Seller store
Developer B: Cart (local) + Wishlist
Developer C: Orders + Returns
Developer D: Profile + Addresses + Notifications + Support
```

These 4 streams have ZERO code overlap if the foundation (shared models, API client, auth) is done first.
