# Phase 2: Screen Inventory

## Screen Catalogue

### Navigation Structure

```
Bottom Navigation (5 tabs):
  ├── Home (Store)
  ├── Categories
  ├── Cart
  ├── Orders
  └── Profile
```

---

### 1. Onboarding & Launch

| # | Screen | Purpose | UI Elements | User Actions | Data Required | API Endpoint | Auth |
|---|--------|---------|-------------|-------------|---------------|--------------|------|
| 1.1 | Splash | Brand intro, auto-login check | Logo, loading indicator | None (auto-navigates) | Stored auth token | None | No |
| 1.2 | Onboarding | First-time introduction | 3 image slides, dot indicator, "Skip" button, "Get Started" CTA | Swipe, Skip, Get Started | None (local) | None | No |

---

### 2. Authentication

| # | Screen | Purpose | UI Elements | User Actions | Data Required | API Endpoint | Auth |
|---|--------|---------|-------------|-------------|---------------|--------------|------|
| 2.1 | Login | Sign in existing user | Email field, password field (show/hide), "Sign in" button, Google OAuth button, "Forgot password?" link, "Create account" link | Enter credentials, tap sign in, tap Google, navigate to register/forgot | email, password | POST /login | No |
| 2.2 | Register | Create new account | Full name field, email field, phone field (optional), password field (min 8), Google OAuth button, "Create account" button, terms link | Fill form, submit, tap Google | full_name, email, phone?, password | POST /register | No |
| 2.3 | Forgot Password | Request password reset | Email field, "Send reset link" button, "Back to login" link | Enter email, submit | email | POST /forgot-password | No |
| 2.4 | Reset Password | Set new password (deep link) | New password field, confirm password field, "Reset" button | Enter passwords, submit | token, password, confirm | POST /reset-password | No |
| 2.5 | OTP Verification | Verify email after registration | 6-digit input boxes, "Verify" button, "Resend code" link, countdown timer | Enter OTP, verify, resend | otp_code | POST /verify-otp, POST /resend-otp | No |

---

### 3. Home & Browsing

| # | Screen | Purpose | UI Elements | User Actions | Data Required | API Endpoint | Auth |
|---|--------|---------|-------------|-------------|---------------|--------------|------|
| 3.1 | Store Home | Main product marketplace | Search bar, category chips, product grid (image, name, price, seller), sort/filter buttons, pull-to-refresh, infinite scroll loader | Search, filter by category, sort, tap product, add to cart, pull refresh, scroll | products[], categories[], totalPages, currentPage | GET /store | No |
| 3.2 | Search Results | Display search matches | Search input (editable), result count, product grid, sort/filter, "No results" state | Edit query, tap product, clear search, apply filters | search query, results[], totalProducts | GET /store?search={q} | No |
| 3.3 | Category View | Browse category products | Category title, product grid, sub-category chips (if any), sort/filter | Tap product, change sort, filter | category slug, products[], totalProducts | GET /store?category={slug} | No |
| 3.4 | Filter/Sort Sheet | Apply sort and filters | Sort radio options (newest, price-low, price-high, relevance), price range slider, free delivery toggle, "Apply" button, "Reset" | Select sort, adjust range, toggle, apply, reset | Current filter state | None (client-side, modifies query) | No |
| 3.5 | Seller Store | View individual seller | Store banner/logo, store name, product grid, category filter within store, search within store | Browse seller products, search, filter | business info, products[], categories[] | GET /store/{slug} | No |

---

### 4. Product Detail

| # | Screen | Purpose | UI Elements | User Actions | Data Required | API Endpoint | Auth |
|---|--------|---------|-------------|-------------|---------------|--------------|------|
| 4.1 | Product Detail | Full product information | Image gallery (swipeable), price (list/sale/tax-inclusive), discount badge, variant chips, quantity stepper, "Add to cart" button, "Buy now" button, description section, specifications section, reviews section, related products carousel, seller info card, WhatsApp button, share button, wishlist heart, FBA badge, stock indicator | View images, select variant, set qty, add to cart, buy now, add to wishlist, share, tap seller, tap WhatsApp, read reviews, tap related product | product, pricing, gallery[], variants[], reviews[], ratingBreakdown, relatedProducts[], availableStock, whatsappUrl, isSignedInBuyer | GET /product/{slug} | No |
| 4.2 | Image Gallery (Full) | View product images large | Full-screen swipeable images, pinch-to-zoom, close button, image counter (e.g., "2/5") | Swipe, zoom, close | gallery[] (from 4.1) | None (local data) | No |
| 4.3 | Write Review (Modal) | Submit product review | Star rating (1-5), title field, comment text area, "Submit" button | Rate, write, submit | order_id, product_id, rating, title, comment | POST /marketplace/account/reviews | Yes |

---

### 5. Cart

| # | Screen | Purpose | UI Elements | User Actions | Data Required | API Endpoint | Auth |
|---|--------|---------|-------------|-------------|---------------|--------------|------|
| 5.1 | Cart | View and manage cart items | Item list (image, name, variant, price, qty stepper, remove button), subtotal, delivery fee line (Rs 199 or FREE), free delivery progress bar, total, "Proceed to checkout" button, "Continue shopping" link | Update qty, remove item, proceed to checkout, continue shopping | Cart items[], subtotal, deliveryFee, total | GET cart (or local) | No |
| 5.2 | Empty Cart | Empty state | Illustration, "Your cart is empty" message, "Browse the marketplace" button | Tap CTA | None | None | No |

---

### 6. Checkout

| # | Screen | Purpose | UI Elements | User Actions | Data Required | API Endpoint | Auth |
|---|--------|---------|-------------|-------------|---------------|--------------|------|
| 6.1 | Checkout - Delivery | Enter shipping details | Step indicator (1/3), saved address picker (if signed in), form: name, phone, address, city, notes, "Continue" button, sign-in prompt banner (if guest) | Select saved address, fill form, validate, continue | Saved addresses (if auth), form fields | None (form only) | No |
| 6.2 | Checkout - Verify Email | OTP verification | Step indicator (2/3), email input, "Send code" button, OTP 6-digit input, "Verify" button, "Resend" link, "Verified" badge (if already done) | Enter email, send code, enter OTP, verify, resend | email, otp code | POST /store/checkout/send-code, POST /store/checkout/verify-code | No |
| 6.3 | Checkout - Review | Final review and place order | Step indicator (3/3), order summary (items list), coupon input + "Apply" button, subtotal, discount (if coupon), delivery fee, total (bold), payment info card (COD), "Place order" button | Apply coupon, review items, place order | items[], coupon validation result, totals | POST /api/store/validate-coupon, POST /store/checkout | No |
| 6.4 | Address Picker (Sheet) | Select saved address | Bottom sheet with address list, each showing label/name/address, "Add new" option, close handle | Select address, add new, dismiss | addresses[] | GET addresses endpoint | Yes |

---

### 7. Order Confirmation & Tracking

| # | Screen | Purpose | UI Elements | User Actions | Data Required | API Endpoint | Auth |
|---|--------|---------|-------------|-------------|---------------|--------------|------|
| 7.1 | Order Confirmation | Post-purchase success | Success animation/icon, order reference (copyable), "What happens next" steps (3), sub-order breakdown (per seller: items, subtotal, tax, delivery, total), "View my orders" button, "Keep shopping" button | Copy reference, view orders, keep shopping | orderRef, subOrders[] (each with items[]) | GET /store/order-confirmation?ref={ref} | No |
| 7.2 | Track Order (Public) | Track without login | Invoice number input, phone number input, "Track" button, status pipeline (5 steps), status description box, seller info card, shipping address card, timeline history (status changes + notes), items table | Enter invoice/phone, submit, view details | invoice, phone → order, history[], items[] | GET /track-order?invoice={inv}&phone={ph} | No |

---

### 8. Orders (Authenticated)

| # | Screen | Purpose | UI Elements | User Actions | Data Required | API Endpoint | Auth |
|---|--------|---------|-------------|-------------|---------------|--------------|------|
| 8.1 | Order History | List all orders | Order cards (order #, date, item count, store name, amount, status badge), pagination or infinite scroll, status filter tabs | Tap order for detail, filter by status, scroll | orders[], totalPages, page | GET /marketplace/account/orders | Yes |
| 8.2 | Order Detail | View single order | Status pipeline (5 steps), order info (invoice, date, seller), items list (image, name, sku, qty, price), price breakdown (subtotal, tax, discount, delivery, total), timeline history, return button (if eligible), cancel button (if pending) | View timeline, initiate return, cancel, copy invoice | order (with items[], history[]), returnEligibility | GET /marketplace/account/orders/{id} | Yes |
| 8.3 | Return Request (Sheet) | Submit return | Bottom sheet: product selection (checkboxes), quantity per item, reason dropdown, return type (refund/exchange), "Submit" button | Select products, set qty, choose reason, submit | order_id, eligible items | POST /marketplace/account/orders/{id}/return | Yes |
| 8.4 | Returns List | View return history | Return cards (return number, original invoice, seller, amount, status, rejection reason if any) | Tap for detail (links to order) | returns[] | GET /marketplace/account/returns | Yes |

---

### 9. Profile & Account

| # | Screen | Purpose | UI Elements | User Actions | Data Required | API Endpoint | Auth |
|---|--------|---------|-------------|-------------|---------------|--------------|------|
| 9.1 | Profile Hub | Account overview | User name/email/avatar, stats cards (total orders, total spent, wishlist count), quick links (Orders, Wishlist, Addresses, Settings), recent orders preview | Navigate to sub-sections | stats, recentOrders[] | GET /marketplace/account | Yes |
| 9.2 | Edit Profile | Update account info | First name, last name, phone (editable), email (read-only, greyed), "Save" button | Edit fields, save | customer object | GET/POST /marketplace/account/profile | Yes |
| 9.3 | Address Book | Manage saved addresses | Address cards (label, name, address, phone, default badge), "Add new" FAB, swipe-to-delete | Add, edit, delete, set default | addresses[] | GET /marketplace/account/addresses | Yes |
| 9.4 | Add/Edit Address | Address form | Label, recipient name, phone, address line 1, address line 2, city, state, postal code, "Set as default" toggle, "Save" button | Fill form, save | Form fields | POST /marketplace/account/addresses | Yes |
| 9.5 | Wishlist | Saved products | Product grid (image, name, price), remove button per item, empty state | Tap product, remove item | wishlist[] (product_id, name, price, image) | GET /marketplace/account/wishlist | Yes |
| 9.6 | Settings | App preferences | Change password link, notification preferences (Phase 2), language (Phase 2), dark mode (Phase 2), app version, sign out button | Navigate, toggle, sign out | None | None | Yes |
| 9.7 | Change Password | Update password | Current password, new password, confirm password, "Update" button | Fill, submit | current_password, new_password | POST (needs confirmation) | Yes |

---

### 10. Support & Info

| # | Screen | Purpose | UI Elements | User Actions | Data Required | API Endpoint | Auth |
|---|--------|---------|-------------|-------------|---------------|--------------|------|
| 10.1 | FAQ | Common questions | Expandable accordion (4 sections, ~18 Q&As), search/filter (Phase 2), support email link | Expand/collapse, tap email | Static content or API | GET /faq (or embedded) | No |
| 10.2 | Contact | Send inquiry | Type selector (radio: sales, demo, hardware, support), name, email, phone (optional), subject, message, "Send" button | Fill form, submit | Form fields | POST /contact | No |
| 10.3 | Terms of Service | Legal terms | Scrollable text content (WebView or rendered) | Read, scroll | Static content | WebView or bundled | No |
| 10.4 | Privacy Policy | Data policy | Scrollable text content (WebView or rendered) | Read, scroll | Static content | WebView or bundled | No |

---

## Screen Count Summary

| Section | Screens | MVP | Phase 2 |
|---------|---------|-----|---------|
| Onboarding & Launch | 2 | 2 | 0 |
| Authentication | 5 | 5 | 0 |
| Home & Browsing | 5 | 5 | 0 |
| Product Detail | 3 | 3 | 0 |
| Cart | 2 | 2 | 0 |
| Checkout | 4 | 4 | 0 |
| Order Confirmation & Tracking | 2 | 2 | 0 |
| Orders (Authenticated) | 4 | 3 | 1 (Returns List) |
| Profile & Account | 7 | 6 | 1 (Settings toggles) |
| Support & Info | 4 | 4 | 0 |
| **Total** | **38** | **36** | **2** |

---

## Shared Components (Cross-Screen)

| Component | Used In | Description |
|-----------|---------|-------------|
| Bottom Navigation Bar | All main screens (3.1, 5.1, 8.1, 9.1) | 5 tabs: Home, Categories, Cart (badge), Orders, Profile |
| App Bar | All screens | Title, back arrow, optional actions (search, cart icon with badge) |
| Product Card | 3.1, 3.2, 3.3, 3.5, 9.5 | Image, product name, price, seller name, "Add to cart" button |
| Loading Skeleton | All data screens | Shimmer placeholder matching screen layout |
| Error State | All data screens | Icon, message, retry button |
| Empty State | 5.2, 8.1, 9.3, 9.5, 8.4 | Illustration, message, CTA button |
| Toast/Snackbar | Cart add, wishlist, errors | Brief message at bottom, auto-dismiss |
| Bottom Sheet | 3.4, 6.4, 8.3 | Draggable sheet for filters, address picker, return form |
| Confirmation Dialog | Logout, delete, cancel order | Title, message, cancel/confirm buttons |
| OTP Input | 2.5, 6.2 | 6 individual digit boxes with auto-focus advance |
| Step Indicator | 6.1, 6.2, 6.3 | 3-step progress (Delivery → Verify → Confirm) |
| Status Badge | 8.1, 8.2, 8.4, 7.2 | Colored pill with order/return status text |
| Price Display | 4.1, 5.1, product cards | List price (strikethrough), sale price, discount % badge |
