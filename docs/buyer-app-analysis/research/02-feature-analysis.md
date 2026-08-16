# Phase 2: Buyer App Feature Analysis

## Feature Inventory

### 1. Browsing & Discovery

| # | Feature | Website Support | Mobile Requirement | Priority | Backend Dependency | Dependencies | Mobile Improvements | Phase |
|---|---------|----------------|-------------------|----------|-------------------|--------------|--------------------|----|
| 1.1 | Store home / product grid | Yes | Required | High | GET /store | None | Pull-to-refresh, infinite scroll vs pagination | MVP |
| 1.2 | Category browsing | Yes (sidebar) | Required | High | GET /store?category= or /store/category/{slug} | 1.1 | Horizontal category chips, dedicated category screen | MVP |
| 1.3 | Text search | Yes | Required | High | GET /store?search= | 1.1 | Search bar in app bar, recent searches, suggestions | MVP |
| 1.4 | Sort products | Yes (4 options) | Required | Medium | Query param `sort` | 1.1 | Bottom sheet picker | MVP |
| 1.5 | Price range filter | Yes | Required | Medium | Query params `min_price`, `max_price` | 1.1 | Range slider | MVP |
| 1.6 | Free delivery filter | Yes | Required | Low | Query param `free_del` | 1.1 | Toggle chip | MVP |
| 1.7 | Active filter chips | Yes | Required | Medium | None (client-side) | 1.5, 1.6 | Dismissible chips row | MVP |
| 1.8 | Hero / featured products | Yes (top 5 by sales/reviews) | Optional | Low | Bundled in /store response | 1.1 | Carousel or banner at top | Phase 2 |
| 1.9 | Seller store pages | Yes (/store/{slug}) | Required | Medium | GET /store/{slug} | None | Dedicated seller profile screen | MVP |
| 1.10 | Sellers list | Yes (on store page) | Optional | Low | Bundled in /store response | 1.9 | Explore sellers section | Phase 2 |

### 2. Product Detail

| # | Feature | Website Support | Mobile Requirement | Priority | Backend Dependency | Dependencies | Mobile Improvements | Phase |
|---|---------|----------------|-------------------|----------|-------------------|--------------|--------------------|----|
| 2.1 | Product page | Yes | Required | High | GET /product/{slug} | None | Full-screen image viewer, share button | MVP |
| 2.2 | Image gallery | Yes (thumbnails, hover-zoom) | Required | High | Included in product response | 2.1 | Swipeable full-screen gallery with pinch-to-zoom | MVP |
| 2.3 | Pricing display | Yes (all-in, tax, discount) | Required | High | PricingService via product response | 2.1 | Clear price hierarchy | MVP |
| 2.4 | Variant selection | Yes (buttons) | Required | High | Included in product response | 2.1 | Chip-style selector, update price on select | MVP |
| 2.5 | Stock status | Yes | Required | High | `stock_quantity` in response | 2.1 | Badge/label | MVP |
| 2.6 | Add to cart | Yes | Required | High | Client-side (or server for mobile) | 2.1, 4.1 | Haptic feedback, animated badge | MVP |
| 2.7 | Buy now | Yes | Required | Medium | Cart + redirect | 2.6, 5.1 | Direct flow to checkout | MVP |
| 2.8 | Quantity selector | Yes (+/- with max) | Required | High | Client-side | 2.6 | Stepper control | MVP |
| 2.9 | Description tab | Yes | Required | Medium | In product response | 2.1 | Expandable section | MVP |
| 2.10 | Specifications tab | Yes | Required | Medium | In product response | 2.1 | Key-value list | MVP |
| 2.11 | Reviews tab | Yes | Required | Medium | In product response | 2.1 | Rating bars, review cards | MVP |
| 2.12 | Submit review | Yes (modal, verified purchase) | Required | Medium | POST /marketplace/account/reviews | 2.1, Auth | Star rating + text input | Phase 2 |
| 2.13 | Related products | Yes (up to 6) | Required | Medium | In product response | 2.1 | Horizontal scroll list | MVP |
| 2.14 | Seller info card | Yes | Required | Medium | In product response | 2.1, 1.9 | Tap to visit store | MVP |
| 2.15 | WhatsApp seller | Yes (conditional) | Required | Low | `whatsappUrl` in response | 2.1 | Deep link to WhatsApp | MVP |
| 2.16 | Share product | No (not in web) | Recommended | Medium | None (client-side) | 2.1 | Native share sheet | MVP |
| 2.17 | FBA badge | Yes | Required | Low | `fulfilment_channel` in response | 2.1 | Info badge | MVP |

### 3. Search

| # | Feature | Website Support | Mobile Requirement | Priority | Backend Dependency | Dependencies | Mobile Improvements | Phase |
|---|---------|----------------|-------------------|----------|-------------------|--------------|--------------------|----|
| 3.1 | Search input | Yes (in header) | Required | High | GET /store?search= | None | Persistent search bar, auto-focus | MVP |
| 3.2 | Search results | Yes (uses store grid) | Required | High | Same as store endpoint | 3.1, 1.1 | Dedicated results screen with count | MVP |
| 3.3 | Search + category filter | Yes (dropdown in search bar) | Optional | Medium | Query param combo | 3.1, 1.2 | Category pre-filter option | Phase 2 |
| 3.4 | Recent searches | No | Recommended | Medium | None (local storage) | 3.1 | Local history chips | Phase 2 |
| 3.5 | Search suggestions | No | Recommended | Low | New endpoint needed | 3.1 | Autocomplete dropdown | Future |

### 4. Cart

| # | Feature | Website Support | Mobile Requirement | Priority | Backend Dependency | Dependencies | Mobile Improvements | Phase |
|---|---------|----------------|-------------------|----------|-------------------|--------------|--------------------|----|
| 4.1 | Cart storage | localStorage (client) | Required | High | NEEDS CONFIRMATION: server-side for mobile? | None | Persistent across sessions | MVP |
| 4.2 | View cart | Yes | Required | High | None or GET cart endpoint | 4.1 | Dedicated cart screen | MVP |
| 4.3 | Cart badge count | Yes (SSCart.updateBadges) | Required | High | None (client-side) | 4.1 | Badge on bottom nav cart icon | MVP |
| 4.4 | Update quantity | Yes (+/-, manual input) | Required | High | Client or API | 4.1 | Stepper per item | MVP |
| 4.5 | Remove item | Yes | Required | High | Client or API | 4.1 | Swipe-to-delete or button | MVP |
| 4.6 | Order summary | Yes (subtotal, delivery, total) | Required | High | Client-side calculation | 4.1 | Summary card | MVP |
| 4.7 | Delivery fee display | Yes (Rs 199 / FREE) | Required | High | Business rule: >= Rs 1,500 | 4.6 | Free delivery progress indicator | MVP |
| 4.8 | Empty cart state | Yes | Required | Medium | None | 4.2 | Illustration + CTA | MVP |
| 4.9 | Continue shopping | Yes (link) | Required | Low | None | 4.2 | Back navigation | MVP |
| 4.10 | Proceed to checkout | Yes (button) | Required | High | None | 4.2, 5.1 | Prominent CTA button | MVP |

### 5. Checkout

| # | Feature | Website Support | Mobile Requirement | Priority | Backend Dependency | Dependencies | Mobile Improvements | Phase |
|---|---------|----------------|-------------------|----------|-------------------|--------------|--------------------|----|
| 5.1 | Checkout screen | Yes | Required | High | GET /store/checkout | 4.1, Auth (optional) | Step-by-step flow | MVP |
| 5.2 | Delivery form | Yes (name, phone, address, city, notes) | Required | High | None (form fields) | 5.1 | Auto-fill from saved addresses | MVP |
| 5.3 | Email verification (OTP) | Yes (send code → verify 6-digit) | Required | High | POST /store/checkout/send-code, /verify-code | 5.1 | OTP input with auto-read | MVP |
| 5.4 | Saved address selection | No (web fills from session) | Recommended | High | GET addresses endpoint | 5.2, Auth | Address picker bottom sheet | MVP |
| 5.5 | Coupon code | Yes | Required | Medium | POST /api/store/validate-coupon | 5.1 | Input + Apply with feedback | MVP |
| 5.6 | Payment method display | Yes (COD only, non-selectable) | Required | High | None | 5.1 | Info card showing COD | MVP |
| 5.7 | Order summary | Yes (items, subtotal, discount, delivery, total) | Required | High | Client-side | 5.1, 4.1 | Collapsible item list | MVP |
| 5.8 | Place order | Yes (POST /store/checkout) | Required | High | POST /store/checkout | 5.2, 5.3, 5.6 | Confirm button with loading | MVP |
| 5.9 | AI recommendations | Yes (optional, fire-and-forget) | Optional | Low | POST /api/store/checkout/recommendations | 5.1 | Card above summary | Future |
| 5.10 | Guest checkout | Yes | Required | High | No auth needed (email OTP instead) | 5.1 | Sign-in prompt but not mandatory | MVP |

### 6. Orders & Tracking

| # | Feature | Website Support | Mobile Requirement | Priority | Backend Dependency | Dependencies | Mobile Improvements | Phase |
|---|---------|----------------|-------------------|----------|-------------------|--------------|--------------------|----|
| 6.1 | Order confirmation | Yes | Required | High | GET /store/order-confirmation?ref= | 5.8 | Success screen with animation | MVP |
| 6.2 | Order history list | Yes (/marketplace/account/orders) | Required | High | GET /marketplace/account/orders | Auth | Pull-to-refresh, filters by status | MVP |
| 6.3 | Order detail | Yes (/marketplace/account/orders/{id}) | Required | High | GET /marketplace/account/orders/{id} | 6.2 | Full breakdown with timeline | MVP |
| 6.4 | Public order tracking | Yes (/track-order?invoice=&phone=) | Required | Medium | GET /track-order | None | Track without login | MVP |
| 6.5 | Status pipeline | Yes (5-step progress) | Required | High | In order response | 6.3 | Visual stepper | MVP |
| 6.6 | Tracking history/timeline | Yes (status changes + notes) | Required | Medium | In order response | 6.3 | Timeline cards | MVP |
| 6.7 | Order items display | Yes | Required | High | In order response | 6.3 | Product images + details | MVP |
| 6.8 | Copy order reference | Yes | Required | Low | None (client-side) | 6.1, 6.3 | Tap-to-copy | MVP |
| 6.9 | Reorder | No | Recommended | Low | Add all items to cart | 6.3, 4.1 | "Order again" button | Phase 2 |
| 6.10 | Order cancellation | Unknown | Recommended | Medium | NEEDS BACKEND CONFIRMATION | 6.3 | Cancel button for pending orders | Phase 2 |

### 7. Authentication

| # | Feature | Website Support | Mobile Requirement | Priority | Backend Dependency | Dependencies | Mobile Improvements | Phase |
|---|---------|----------------|-------------------|----------|-------------------|--------------|--------------------|----|
| 7.1 | Email/password login | Yes (POST /login) | Required | High | POST /login (or token endpoint) | None | Biometric unlock after first login | MVP |
| 7.2 | Registration | Yes (POST /register) | Required | High | POST /register | None | Minimal fields, progressive profiling | MVP |
| 7.3 | Google OAuth | Yes | Required | High | OAuth flow | None | Native Google Sign-In SDK | MVP |
| 7.4 | Forgot password | Yes (link to /forgot-password) | Required | High | NEEDS BACKEND CONFIRMATION | 7.1 | OTP-based reset | MVP |
| 7.5 | Logout | Yes (POST /logout) | Required | High | POST /logout | Auth | Confirm dialog | MVP |
| 7.6 | Session management | PHP sessions (web) | Required | High | NEEDS CONFIRMATION: JWT for mobile | None | Token refresh, auto-logout | MVP |
| 7.7 | Biometric auth | No | Recommended | Medium | None (local) | 7.1 | Fingerprint/Face ID for returning users | Phase 2 |
| 7.8 | OTP verification (registration) | Yes (verify_otp.php) | Required | Medium | OTP endpoint | 7.2 | Auto-read SMS OTP | MVP |

### 8. Profile & Account

| # | Feature | Website Support | Mobile Requirement | Priority | Backend Dependency | Dependencies | Mobile Improvements | Phase |
|---|---------|----------------|-------------------|----------|-------------------|--------------|--------------------|----|
| 8.1 | Account dashboard | Yes | Required | Medium | GET /marketplace/account | Auth | Stats cards | MVP |
| 8.2 | Profile view/edit | Yes | Required | High | GET/POST /marketplace/account/profile | Auth | Editable form | MVP |
| 8.3 | Address book | Yes | Required | High | NEEDS BACKEND CONFIRMATION: CRUD endpoints | Auth | Add/edit/delete/set default | MVP |
| 8.4 | Wishlist | Yes | Required | Medium | GET wishlist, POST toggle | Auth | Grid with remove action | MVP |
| 8.5 | Returns | Yes | Required | Medium | NEEDS BACKEND CONFIRMATION | Auth, 6.3 | Return request form | Phase 2 |
| 8.6 | Change password | Likely | Required | Medium | NEEDS BACKEND CONFIRMATION | Auth | Current + new password form | MVP |

### 9. Notifications

| # | Feature | Website Support | Mobile Requirement | Priority | Backend Dependency | Dependencies | Mobile Improvements | Phase |
|---|---------|----------------|-------------------|----------|-------------------|--------------|--------------------|----|
| 9.1 | Push notifications | No (email only) | Recommended | High | NEEDS NEW BACKEND: FCM integration | Auth | Order status, promotions | Phase 2 |
| 9.2 | In-app notifications | No | Recommended | Medium | NEEDS NEW ENDPOINT | Auth | Notification bell + list | Phase 2 |
| 9.3 | Email notifications | Yes (order confirmation, status) | Maintained | Low | Existing (no app change) | None | N/A (backend handles) | N/A |

### 10. Support & Info

| # | Feature | Website Support | Mobile Requirement | Priority | Backend Dependency | Dependencies | Mobile Improvements | Phase |
|---|---------|----------------|-------------------|----------|-------------------|--------------|--------------------|----|
| 10.1 | FAQ | Yes (/faq) | Required | Low | Static or API | None | Expandable accordion | MVP |
| 10.2 | Contact | Yes (/contact) | Required | Low | Form submission | None | In-app form or link | MVP |
| 10.3 | Terms/Privacy | Yes | Required | Low | Static content | None | WebView or rendered text | MVP |
| 10.4 | About | Yes | Optional | Low | Static content | None | App info screen | MVP |
| 10.5 | WhatsApp support | No | Recommended | Low | None | None | Direct WhatsApp link | Phase 2 |

### 11. Mobile-Only Features

| # | Feature | Website Support | Mobile Requirement | Priority | Backend Dependency | Dependencies | Mobile Improvements | Phase |
|---|---------|----------------|-------------------|----------|-------------------|--------------|--------------------|----|
| 11.1 | Onboarding | No | Recommended | Medium | None | None | 3-slide intro on first launch | MVP |
| 11.2 | Deep linking | No | Required | High | None (routing) | All screens | Handle /product/{slug} links | MVP |
| 11.3 | App updates | No | Required | Medium | None (store) | None | Force update for breaking changes | MVP |
| 11.4 | Offline mode (cached) | No | Recommended | Low | None (local cache) | 1.1 | Show cached products when offline | Phase 2 |
| 11.5 | Barcode/QR scanner | No | Optional | Low | None | 2.1 | Scan product barcode to find it | Future |

## Feature Count Summary

| Phase | Count | Description |
|-------|-------|-------------|
| **MVP** | 62 | Core shopping, checkout, auth, orders, account |
| **Phase 2** | 14 | Notifications, reorder, returns, biometric, search history |
| **Future** | 4 | AI advisor, search suggestions, barcode scanner, offline |
| **Not Required** | 0 | All website buyer features are relevant to mobile |
