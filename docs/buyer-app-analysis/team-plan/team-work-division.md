# Team Work Division

## Team: Four Developers

| Developer | GitHub Handle | Role |
|-----------|--------------|------|
| Naheed | `nahy1061` | Project Lead + Foundation + Design System |
| Arwah | `arwahimran` | Auth + Networking + Profile |
| Munaza | `munazamanzoorofficial-beep` | Products + Checkout |
| Nimra | `nimraqureshi-ai` | Cart + Orders + Shared Widgets |

---

## Division Rationale

### Why this split?

| Developer | Primary Area | Complexity | Screens | API Endpoints | Justification |
|-----------|-------------|-----------|---------|---------------|---------------|
| Naheed | Foundation + Search + Seller + Support | High (infra) + Medium (features) | 8 | ~8 | Owns architecture decisions, best positioned to set patterns that others follow. Feature work is medium-complexity. |
| Arwah | Auth + Profile + Notifications | High (auth is critical path) + Medium | 12 | ~18 | Auth is the most technically complex feature (OAuth, reCAPTCHA, session, interceptors). Profile is auth-adjacent. |
| Munaza | Home + Categories + Product Detail + Checkout | High (checkout) + Medium (browsing) | 10 | ~15 | Product browsing and checkout are the core buyer journey. Single owner avoids handoff in the critical path. |
| Nimra | Cart + Wishlist + Orders + Returns | Medium-High | 9 | ~14 | Cart→Checkout→Orders is a dependency chain. Nimra owns Cart and Orders (bookends), Munaza owns Checkout (middle). Clear handoff point. |

### Balance Check

| Developer | Total Screens | Estimated Complexity (1-10) | Foundation Load |
|-----------|--------------|---------------------------|-----------------|
| Naheed | 8 | 7 (infra-heavy early, lighter features later) | Heavy (Week 1) |
| Arwah | 12 | 8 (auth + profile + address + notifications) | Heavy (Week 1: API client + auth) |
| Munaza | 10 | 8 (checkout multi-step is complex) | Medium (Week 1: models) |
| Nimra | 9 | 7 (cart is straightforward, orders is medium) | Medium (Week 1: shared widgets + cart) |

---

## Detailed Ownership Table

| Developer | Primary Ownership | Secondary / Review | Shared Responsibilities |
|-----------|-------------------|-------------------|------------------------|
| **Naheed** | Foundation, Theme, Router, Search, Seller Store, Support (FAQ, Contact, Tickets) | Reviews: Munaza's Checkout, all shared component changes | Architecture decisions, `pubspec.yaml` changes, design system, environment config |
| **Arwah** | API Client, Auth (all screens), Profile (hub, edit, settings, change password), Addresses, Notifications | Reviews: Nimra's Orders, all networking/interceptor changes | Validators, API client maintenance, session handling |
| **Munaza** | Home screen, Categories, Product Detail, Checkout (delivery, OTP, review, confirmation) | Reviews: Naheed's Search/Seller, all model changes | Product/Category/Pricing models, product-related shared logic |
| **Nimra** | Cart (local + validation), Wishlist, Orders (history, detail, tracking), Returns | Reviews: Arwah's Auth/Profile, all shared widget changes | Shared widgets (product-facing), formatters, storage wrappers |

---

## Feature-to-Developer Assignment

| Feature | Owner | Reviewer | Dependencies | Backend Dependency | Shared Components Used |
|---------|-------|----------|-------------|-------------------|----------------------|
| Project Setup | Naheed | — | None | None | — |
| Theme / Design System | Naheed | All (visual review) | None | None | — |
| Router Shell | Naheed | Arwah | None | None | — |
| API Client | Arwah | Naheed | Project setup | None | — |
| Shared Widgets (generic) | Naheed | Nimra | Theme | None | — |
| Shared Widgets (product) | Nimra | Munaza | Theme, models | None | — |
| Auth - Login | Arwah | Nimra | API client | `/api/buyer/login` | AppButton, AppTextField, AppSnackbar |
| Auth - Register | Arwah | Nimra | API client | `/api/buyer/register` | AppButton, AppTextField, OtpInput |
| Auth - Google OAuth | Arwah | Naheed | API client | `/api/buyer/auth/google` | AppButton |
| Auth - Forgot Password | Arwah | Nimra | API client | `/api/buyer/forgot-password` | AppButton, AppTextField |
| Auth - OTP Verify | Arwah | Nimra | API client | `/api/buyer/verify-email` | OtpInput, AppButton |
| Home Screen | Munaza | Naheed | Foundation, models | `/api/store/products` | ProductCard, LoadingSkeleton, ErrorStateWidget |
| Categories | Munaza | Naheed | Foundation, models | `/api/store/categories` | ProductCard, LoadingSkeleton |
| Product Detail | Munaza | Nimra | Foundation, models | `/api/store/products/{slug}` | PriceDisplay, RatingDisplay, QuantitySelector, AppImage |
| Search | Naheed | Munaza | Foundation, models | `/api/store/search-suggest` | ProductCard, AppSearchBar, LoadingSkeleton |
| Seller Store | Naheed | Munaza | Foundation, models | `/api/store/sellers/{slug}` | ProductCard, RatingDisplay |
| Cart | Nimra | Munaza | Foundation, CartItem model | `/api/store/cart/validate-item` | PriceDisplay, QuantitySelector, EmptyStateWidget |
| Wishlist | Nimra | Arwah | Auth, ProductModel | `/api/buyer/wishlist` | ProductCard, EmptyStateWidget |
| Checkout - Delivery | Munaza | Arwah | Auth, Cart, Addresses | `/api/store/checkout/send-code` | AppButton, AppTextField |
| Checkout - OTP | Munaza | Arwah | Checkout delivery | `/api/store/checkout/verify-code` | OtpInput |
| Checkout - Review | Munaza | Nimra | Checkout OTP | `/api/store/checkout` | PriceDisplay, AppButton |
| Order Confirmation | Munaza | Nimra | Checkout review | `/api/store/order-confirmation/{ref}` | StatusBadge |
| Order History | Nimra | Arwah | Auth | `/api/buyer/orders` | StatusBadge, LoadingSkeleton, EmptyStateWidget |
| Order Detail | Nimra | Arwah | Order history | `/api/buyer/orders/{id}` | StatusBadge, PriceDisplay |
| Order Tracking (public) | Nimra | Naheed | Foundation | `/api/store/track-order` | StatusBadge |
| Returns | Nimra | Arwah | Orders | `/api/buyer/orders/{id}/return` | StatusBadge, AppButton |
| Profile Hub | Arwah | Naheed | Auth | `/api/buyer/profile` | — |
| Edit Profile | Arwah | Naheed | Profile hub | `PUT /api/buyer/profile` | AppButton, AppTextField |
| Change Password | Arwah | Naheed | Auth | `/api/buyer/change-password` | AppButton, AppTextField |
| Settings | Arwah | Naheed | Auth | None (local) | — |
| Addresses | Arwah | Munaza | Auth | `/api/buyer/addresses` | AppButton, AppTextField, EmptyStateWidget |
| Notifications | Arwah | Nimra | Auth, FCM | `/api/buyer/notifications` | EmptyStateWidget |
| Support - FAQ | Naheed | Arwah | Foundation | None (static) | — |
| Support - Contact | Naheed | Arwah | Foundation | None (static) | AppButton, AppTextField |
| Support - Tickets | Naheed | Arwah | Auth | `/api/buyer/support/tickets` | EmptyStateWidget, AppButton |
| Support - Chat | Naheed | Arwah | Support tickets | `/api/buyer/support/tickets/{id}/messages` | — |

---

## Conflict-Free Zones

Each developer works exclusively in these folders during feature development:

| Developer | Exclusive Folders |
|-----------|------------------|
| Naheed | `features/search/`, `features/seller/` (new), `features/support/` |
| Arwah | `features/auth/`, `features/profile/`, `features/notifications/` |
| Munaza | `features/home/`, `features/product_detail/`, `features/checkout/` |
| Nimra | `features/cart/`, `features/wishlist/`, `features/orders/` |

No two developers ever edit the same feature folder simultaneously → **zero merge conflicts on feature code**.
