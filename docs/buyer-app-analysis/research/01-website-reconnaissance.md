# Phase 1: Website & Source-Code Reconnaissance

## 1. Repository Structure

```
buyer side source code of site/
├── marketplace/
│   ├── account/
│   │   ├── _sidebar.php          # Shared account sidebar navigation
│   │   ├── addresses.php         # Address book management
│   │   ├── dashboard.php         # Account overview (stats, recent orders)
│   │   ├── order_detail.php      # Individual order detail view
│   │   ├── orders.php            # Order history list
│   │   ├── profile.php           # Profile settings
│   │   ├── returns.php           # Return requests
│   │   └── wishlist.php          # Saved products
│   └── account.zip
├── marketplace_review/
│   ├── index.php                 # Reviews listing
│   └── show.php                  # Single review display
└── public/
    ├── about.php
    ├── cart.php                   # Shopping cart (client-side, localStorage)
    ├── checkout.php              # Checkout with email verification + order placement
    ├── contact.php
    ├── cookies.php
    ├── disclaimer.php
    ├── faq.php
    ├── features.php
    ├── home.php                  # Main landing page
    ├── index.php                 # Alias → home.php
    ├── industries.php
    ├── marketplace_account.php   # Account layout wrapper
    ├── marketplace_login.php     # Buyer sign-in
    ├── marketplace_register.php  # Buyer registration
    ├── order_confirmation.php    # Post-checkout confirmation page
    ├── pricing.php               # SaaS pricing (seller-facing)
    ├── privacy.php
    ├── product_detail.php        # Full product page
    ├── register.php              # Seller registration (not buyer)
    ├── seller_central.php        # Seller info page
    ├── store.php                 # Main marketplace store/grid
    ├── store_detail.php          # Individual seller store page
    ├── terms.php
    ├── track_order.php           # Public order tracking (no auth required)
    └── verify_otp.php            # OTP verification
```

## 2. Technology Stack

| Layer | Technology | Confidence |
|-------|-----------|------------|
| **Framework** | PHP (custom MVC, Laravel-like) | CONFIRMED FROM SOURCE |
| **Language** | PHP 8.x | CONFIRMED FROM SOURCE (match expressions, typed properties) |
| **Frontend** | Server-rendered PHP + vanilla JavaScript | CONFIRMED FROM SOURCE |
| **CSS** | Custom CSS (no Tailwind/Bootstrap for marketplace pages), Bootstrap grid for layout | CONFIRMED FROM SOURCE |
| **State (cart)** | localStorage (`ss_cart` key) via `SSCart` module | CONFIRMED FROM SOURCE |
| **Fonts** | Inter, Google Sans, Roboto Mono | CONFIRMED FROM SOURCE |
| **Icons** | Inline SVG (no icon library) | CONFIRMED FROM SOURCE |
| **Session** | `App\Core\Session` (server-side) | CONFIRMED FROM SOURCE |
| **CSRF** | `App\Core\Csrf` (token per request) | CONFIRMED FROM SOURCE |
| **Settings** | `App\Core\Setting` (database-backed key-value) | CONFIRMED FROM SOURCE |
| **Auth** | Session-based (`marketplace_customer_id`, `marketplace_customer_name`, `marketplace_customer_email`) | CONFIRMED FROM SOURCE |
| **API Style** | JSON REST (POST with CSRF token header) | CONFIRMED FROM SOURCE |

## 3. Buyer Functionality Map

### 3.1 Store / Marketplace (No Auth Required)

**Route:** `/store`  
**Controller:** `PublicController::store()`

| Feature | Details | Source |
|---------|---------|--------|
| Product grid | Paginated, auto-fill responsive grid | CONFIRMED FROM SOURCE |
| Categories | Sidebar list with product counts, SEO slugs `/store/category/{slug}` | CONFIRMED FROM SOURCE |
| Search | Text input with category dropdown, query param `?search=` | CONFIRMED FROM SOURCE |
| Sorting | Newest, Price low→high, Price high→low, Relevance (search only) | CONFIRMED FROM SOURCE |
| Price filter | Min/Max range inputs (PKR) | CONFIRMED FROM SOURCE |
| Free delivery filter | Checkbox, items >= Rs 1,500 | CONFIRMED FROM SOURCE |
| Filter chips | Removable active-filter indicators | CONFIRMED FROM SOURCE |
| Pagination | Numbered pages with ellipsis | CONFIRMED FROM SOURCE |
| Hero section | Top products ranked by sales (or reviews) | CONFIRMED FROM SOURCE |
| Seller list | Cards with business name, city, link to `/store/{slug}` | CONFIRMED FROM SOURCE |
| Add to cart | Client-side via `SSCart.addItem()`, toast notification | CONFIRMED FROM SOURCE |
| Product cards show | Name, image, seller, rating/reviews, price, discount badge, stock status, "NEW" badge | CONFIRMED FROM SOURCE |
| FBA badge | "Fulfilled by SoftStore" indicator | CONFIRMED FROM SOURCE |
| Promotional banner | Superadmin-configurable via Settings | CONFIRMED FROM SOURCE |
| SEO | JSON-LD `ItemList` structured data | CONFIRMED FROM SOURCE |
| Mobile | Off-canvas filter drawer, responsive grid | CONFIRMED FROM SOURCE |

### 3.2 Product Detail (No Auth Required)

**Route:** `/product/{slug}` (canonical), `/product/{id}` (fallback)  
**Controller:** `PublicController::productDetail()`

| Feature | Details | Source |
|---------|---------|--------|
| Image gallery | Multiple images, thumbnails, hover-to-zoom | CONFIRMED FROM SOURCE |
| Pricing | All-in price (includes tax), discount badge, "You save" line | CONFIRMED FROM SOURCE |
| Deal pricing | Campaign/deal prices via PricingService | CONFIRMED FROM SOURCE |
| Variants | Size/colour picker, dynamic price update | CONFIRMED FROM SOURCE |
| Stock status | In stock / Low stock (<=5) / Out of stock | CONFIRMED FROM SOURCE |
| Quantity selector | +/- buttons, max = available stock | CONFIRMED FROM SOURCE |
| Add to cart | Via SSCart, toast notification | CONFIRMED FROM SOURCE |
| Buy now | Adds to cart + redirects to `/store/checkout` | CONFIRMED FROM SOURCE |
| WhatsApp seller | Optional link to WhatsApp | CONFIRMED FROM SOURCE |
| Seller card | Name, avatar, city, verification badge, link to store | CONFIRMED FROM SOURCE |
| FBA info | "Fulfilled by SoftStore" box if applicable | CONFIRMED FROM SOURCE |
| Tabs: Description | Product description (markdown/text) | CONFIRMED FROM SOURCE |
| Tabs: Specifications | SKU, barcode, category, unit, seller, city, availability | CONFIRMED FROM SOURCE |
| Tabs: Reviews | Rating summary, breakdown bars, individual reviews | CONFIRMED FROM SOURCE |
| Review form | Modal (POST `/marketplace/account/reviews`), requires verified purchase | CONFIRMED FROM SOURCE |
| Related products | "More from this store" grid (up to 6) | CONFIRMED FROM SOURCE |
| Breadcrumb | Marketplace > Category > Product | CONFIRMED FROM SOURCE |
| Mobile sticky bar | Fixed bottom bar with price + "Add to cart" button | CONFIRMED FROM SOURCE |
| SEO | JSON-LD `Product` + `BreadcrumbList`, aggregateRating (real only) | CONFIRMED FROM SOURCE |
| Assurances | Cash on delivery, invoice-matched returns, order tracking, registered seller | CONFIRMED FROM SOURCE |
| Tax display | "Includes Rs X tax (Y%)" or "No tax applies" | CONFIRMED FROM SOURCE |
| Return policy | 7-day window (from `ReturnService::RETURN_WINDOW_DAYS`) | CONFIRMED FROM SOURCE |

### 3.3 Cart (No Auth Required)

**Route:** `/store/cart`  
**Storage:** Client-side localStorage (`ss_cart`)

| Feature | Details | Source |
|---------|---------|--------|
| Cart items | Image, name, variant label, seller, unit price, line total | CONFIRMED FROM SOURCE |
| Quantity control | +/- buttons, manual input (1-99) | CONFIRMED FROM SOURCE |
| Remove item | Per-item remove button | CONFIRMED FROM SOURCE |
| Order summary | Subtotal, delivery fee, total | CONFIRMED FROM SOURCE |
| Delivery fee | Flat Rs 199, free if subtotal >= Rs 1,500 | CONFIRMED FROM SOURCE |
| Proceed to checkout | Button → `/store/checkout` | CONFIRMED FROM SOURCE |
| Empty state | Illustrated empty state with "Browse marketplace" link | CONFIRMED FROM SOURCE |
| Step indicator | Cart (active) → Delivery → Confirm | CONFIRMED FROM SOURCE |

### 3.4 Checkout (Auth Optional but Encouraged)

**Route:** `/store/checkout`  
**Controller:** `PublicController::checkoutPage()` (GET) / `PublicController::placeOrder()` (POST)

| Feature | Details | Source |
|---------|---------|--------|
| Guest checkout | Allowed (sign-in encouraged via banner) | CONFIRMED FROM SOURCE |
| Delivery form | Full name, mobile, street address, city, delivery note (optional) | CONFIRMED FROM SOURCE |
| Email verification | Send OTP → verify 6-digit code before placing order | CONFIRMED FROM SOURCE |
| Pre-verified state | Returning signed-in buyers skip OTP | CONFIRMED FROM SOURCE |
| Payment method | Cash on delivery ONLY | CONFIRMED FROM SOURCE |
| Coupon code | Input + Apply button, validated via API | CONFIRMED FROM SOURCE |
| Order summary | Items list, subtotal, discount, delivery, total | CONFIRMED FROM SOURCE |
| AI advisor | "Before you order" panel (optional, fire-and-forget) | CONFIRMED FROM SOURCE |
| Place order | Button disabled until email verified | CONFIRMED FROM SOURCE |
| Success flow | Clears cart → redirect to `/store/order-confirmation?ref=X` | CONFIRMED FROM SOURCE |
| Validation | Client-side (name >= 3 chars, phone >= 10 digits, address >= 8, city >= 2) | CONFIRMED FROM SOURCE |

### 3.5 Order Confirmation (No Auth for Basic View)

**Route:** `/store/order-confirmation?ref={master_ref}`  
**Controller:** `PublicController::orderConfirmation()`

| Feature | Details | Source |
|---------|---------|--------|
| Success hero | Animated tick, personalized greeting | CONFIRMED FROM SOURCE |
| Order reference | Displayed with copy button | CONFIRMED FROM SOURCE |
| Multi-seller split | Cart items split into separate parcels per seller | CONFIRMED FROM SOURCE |
| Per-parcel details | Seller name, status badge, items, subtotal, tax, discount, delivery, total | CONFIRMED FROM SOURCE |
| "What happens next" | 3-step timeline (seller confirms → packed/shipped → pay rider) | CONFIRMED FROM SOURCE |
| Order summary sidebar | Reference, parcel count, payment method, total | CONFIRMED FROM SOURCE |
| Delivery address | Customer name, address, phone displayed | CONFIRMED FROM SOURCE |
| Actions | "View my orders" + "Keep shopping" buttons | CONFIRMED FROM SOURCE |
| Status types | pending, confirmed, processing, shipped, delivered, cancelled, returned | CONFIRMED FROM SOURCE |

### 3.6 Order Tracking (No Auth Required)

**Route:** `/track-order` (GET with `?invoice=&phone=`)  
**Controller:** `PublicController::trackOrder()`

| Feature | Details | Source |
|---------|---------|--------|
| Search form | Invoice number + phone number (both required) | CONFIRMED FROM SOURCE |
| Phone verification | Required to prevent leaking order details to strangers | CONFIRMED FROM SOURCE |
| Progress pipeline | 5 steps: Received → Confirmed → Packing → Shipped → Delivered | CONFIRMED FROM SOURCE |
| Status detail | Colored description box per status | CONFIRMED FROM SOURCE |
| Seller info | Store name, location, contact | CONFIRMED FROM SOURCE |
| Shipping address | Customer name, address, payment method/status | CONFIRMED FROM SOURCE |
| Timeline history | Status changes with timestamps and seller notes | CONFIRMED FROM SOURCE |
| Order items table | Product name, SKU, quantity, subtotal | CONFIRMED FROM SOURCE |

### 3.7 Authentication

#### Login

**Route:** `/login` (GET + POST)  
**Controller:** `MarketplaceAccountController`

| Feature | Details | Source |
|---------|---------|--------|
| Fields | Email + password | CONFIRMED FROM SOURCE |
| Forgot password | Link to `/forgot-password` | CONFIRMED FROM SOURCE |
| Show/hide password | Toggle button | CONFIRMED FROM SOURCE |
| CAPTCHA | Included (`partials/captcha_field.php`) | CONFIRMED FROM SOURCE |
| Google auth | OAuth button (`partials/google_auth_button.php`, audience=buyer) | CONFIRMED FROM SOURCE |
| Redirect after login | `?next=` parameter support | CONFIRMED FROM SOURCE |
| Seller separation | "Selling? Sign in to Seller Central" link | CONFIRMED FROM SOURCE |

#### Registration

**Route:** `/register` (GET + POST)  
**Controller:** `MarketplaceAccountController`

| Feature | Details | Source |
|---------|---------|--------|
| Fields | Full name*, email*, mobile (optional), delivery address (optional), password* (min 8) | CONFIRMED FROM SOURCE |
| Validation | Server-side with field-level errors, repopulation | CONFIRMED FROM SOURCE |
| CAPTCHA | Included | CONFIRMED FROM SOURCE |
| Google auth | OAuth button | CONFIRMED FROM SOURCE |
| Terms acceptance | Implicit ("by creating an account you agree...") | CONFIRMED FROM SOURCE |
| Redirect after register | `?next=` parameter support | CONFIRMED FROM SOURCE |

### 3.8 Buyer Account (Auth Required)

**Route prefix:** `/marketplace/account`

#### Dashboard
- Stats: Total orders, total spent (PKR), wishlist items count
- Recent orders table (link to detail)
- Navigation sidebar: Dashboard, My Orders, Wishlist, Address Book, Profile Settings, Sign Out

#### Orders List (`/marketplace/account/orders`)
- Table: Order #, date, items count, store name, amount, status, actions
- Status badges: pending (yellow), confirmed/processing (orange), shipped (dark orange), delivered (green), cancelled (red)
- Pagination support
- Link to individual order detail

#### Order Detail (`/marketplace/account/orders/{id}`)
- Full order breakdown (items, prices, status)
- **NEEDS BACKEND CONFIRMATION:** Exact fields and actions available

#### Wishlist (`/marketplace/account/wishlist`)
- Grid of saved products (image, name, price)
- Remove via API: `POST /api/marketplace/wishlist/toggle` with `product_id`
- Link to product detail
- Empty state with "Browse products" CTA

#### Addresses (`/marketplace/account/addresses`)
- **NEEDS BACKEND CONFIRMATION:** Exact CRUD operations and fields

#### Profile (`/marketplace/account/profile`)
- **NEEDS BACKEND CONFIRMATION:** Editable fields, password change

#### Returns (`/marketplace/account/returns`)
- **NEEDS BACKEND CONFIRMATION:** Return request flow, eligible orders

### 3.9 Seller Store Page

**Route:** `/store/{seller_slug}`  
**Source:** `store_detail.php`  
**NEEDS BACKEND CONFIRMATION:** Exact layout and data displayed

## 4. API Endpoints Discovered

### Confirmed from Source Code

| Method | Endpoint | Purpose | Auth Required |
|--------|----------|---------|---------------|
| POST | `/store/checkout` | Place order | No (email verification required) |
| POST | `/store/checkout/send-code` | Send OTP email for checkout verification | No |
| POST | `/store/checkout/verify-code` | Verify OTP code | No |
| POST | `/api/store/validate-coupon` | Validate coupon code against cart items | No |
| POST | `/api/store/checkout/recommendations` | AI advisor recommendations | No |
| POST | `/marketplace/account/reviews` | Submit product review | Yes |
| POST | `/api/marketplace/wishlist/toggle` | Add/remove wishlist item | Yes |
| POST | `/login` | Authenticate buyer | No |
| POST | `/register` | Create buyer account | No |
| POST | `/logout` | Sign out | Yes |
| GET | `/store` | Marketplace store page | No |
| GET | `/store/category/{slug}` | Category-filtered store | No |
| GET | `/product/{slug}` | Product detail page | No |
| GET | `/store/cart` | Cart page | No |
| GET | `/store/checkout` | Checkout page | No |
| GET | `/store/order-confirmation?ref=X` | Order confirmation | No (visibility gated) |
| GET | `/track-order?invoice=&phone=` | Public order tracking | No |
| GET | `/marketplace/account` | Account dashboard | Yes |
| GET | `/marketplace/account/orders` | Orders list | Yes |
| GET | `/marketplace/account/orders/{id}` | Order detail | Yes |
| GET | `/marketplace/account/wishlist` | Wishlist | Yes |
| GET | `/marketplace/account/addresses` | Address book | Yes |
| GET | `/marketplace/account/profile` | Profile settings | Yes |
| GET | `/marketplace/account/returns` | Returns | Yes |
| GET | `/forgot-password` | Password reset flow | No |

### Likely Endpoints (Not Directly Observed in Views)

| Method | Endpoint | Purpose | Confidence |
|--------|----------|---------|------------|
| POST | `/marketplace/account/profile` | Update profile | LIKELY |
| POST/PUT | `/marketplace/account/addresses` | Add/update address | LIKELY |
| DELETE | `/marketplace/account/addresses/{id}` | Delete address | LIKELY |
| POST | `/forgot-password` | Submit password reset | LIKELY |
| GET/POST | `/verify-otp` | OTP verification (registration?) | LIKELY |
| GET | `/api/auth/google` | Google OAuth redirect | LIKELY |

## 5. Data Models (Inferred from Source)

### Product
```
id, slug, product_name, description, marketplace_description,
selling_price, marketplace_price, image_url,
category_id, category_name, category_slug,
sku, barcode, unit, stock_quantity,
avg_rating, review_count,
seller_name, seller_slug, seller_city,
marketplace_verified, fulfilment_channel (seller|fba),
[gallery images via product_images table]
```

### Product Variant
```
id, attributes (key-value pairs like size/colour),
effective_price/selling_price
```

### Cart Item (localStorage)
```
id, name, price, qty, img, seller, slug,
variantId (nullable), variantLabel (nullable)
```

### Order (Sale)
```
id, invoice_number, master_ref,
customer_name, customer_phone, customer_address, customer_email,
sale_status (pending|confirmed|processing|shipped|delivered|cancelled|returned),
payment_method (cod), payment_status,
subtotal, tax_amount, discount_amount, delivery_fee, grand_total,
seller_name, seller_city, seller_phone,
created_at
```

### Sale Item
```
product_name, sku, image_url, quantity, total_amount/subtotal
```

### Review
```
reviewer_name, rating, title, review_text,
is_verified_purchase, seller_response, created_at
```

### Category
```
id, slug, category_name, prod_count
```

### Checkout Payload (to POST /store/checkout)
```json
{
  "_csrf_token": "...",
  "csrf_token": "...",
  "customer_name": "Muhammad Ali",
  "customer_phone": "03001234567",
  "customer_address": "House 1, Street 2, Area, Lahore",
  "customer_email": "verified@email.com",
  "payment_method": "cod",
  "notes": "call before arriving",
  "coupon_code": "NEW26",
  "items": [
    { "id": 1, "qty": 2, "variant_id": null },
    { "id": 5, "qty": 1, "variant_id": 12 }
  ]
}
```

### Checkout Response
```json
{
  "success": true,
  "invoice_number": "MKT-772ABDCD",
  "master_ref": "MKT-772ABDCD"
}
```

## 6. Client-Side Cart System (`SSCart`)

**File:** `/assets/js/cart.js` (not in provided source, referenced by all marketplace pages)  
**Storage:** `localStorage` key `ss_cart`

### Known API:
```javascript
window.SSCart.getCart()      // Returns array of cart items
window.SSCart.setCart(cart)  // Saves and returns cart
window.SSCart.addItem(item) // Adds item, returns updated cart
window.SSCart.clearCart()   // Empties cart
window.SSCart.updateBadges() // Updates header cart badge count
```

### Cart Item Shape:
```javascript
{
  id: Number,          // Product ID
  name: String,        // Product name
  price: Number,       // Unit price (all-in, with tax)
  qty: Number,         // Quantity (1-99)
  img: String,         // Image URL
  seller: String,      // Seller name
  slug: String,        // Product slug (for linking)
  variantId: Number|null,
  variantLabel: String
}
```

### Business Rules:
- Delivery fee: Rs 199 flat
- Free delivery threshold: Rs 1,500 subtotal
- Max quantity per item: 99
- Cart is purely client-side until checkout POST

## 7. Authentication & Session

| Session Key | Purpose | Source |
|-------------|---------|--------|
| `marketplace_customer_id` | Buyer identity | CONFIRMED FROM SOURCE |
| `marketplace_customer_name` | Display name | CONFIRMED FROM SOURCE |
| `marketplace_customer_email` | Email (for pre-fill) | CONFIRMED FROM SOURCE |

### Auth Flow:
1. Login via email/password or Google OAuth
2. Session created server-side
3. CSRF token required for all POST requests (via hidden field + `X-CSRF-TOKEN` header)
4. Checkout email verification is separate from account auth (OTP per session)

### Google OAuth:
- Available for both login and registration
- Audience parameter: `buyer`
- Implementation in `partials/google_auth_button.php`
- **NEEDS BACKEND CONFIRMATION:** Exact OAuth provider/flow

## 8. Buyer vs. Seller vs. Admin Separation

### Buyer-Specific (for the Flutter app)
- Store browsing, search, filtering, categories
- Product detail viewing
- Cart management (client-side)
- Checkout with email verification
- Order placement (COD only)
- Order tracking (public + authenticated)
- Account: dashboard, orders, wishlist, addresses, profile, returns
- Reviews (verified purchase only)
- Authentication (login, register, forgot password, Google OAuth)

### Seller-Specific (NOT for Buyer App)
- `/seller/*` routes
- `/seller/login`, `/seller/register`
- Seller Central dashboard
- Product listing management
- Order fulfillment (confirm, pack, ship)
- Status updates with notes
- Seller response to reviews

### Admin-Specific (NOT for Buyer App)
- Store promo configuration (Settings)
- Hero category management
- System settings

### Shared
- Product data (read by buyer, managed by seller)
- Order data (created by buyer, fulfilled by seller)
- Review data (written by buyer, responded to by seller)
- Category taxonomy
- Pricing (PricingService used by both display and checkout)

## 9. Key Business Rules

| Rule | Details | Source |
|------|---------|--------|
| Payment | Cash on delivery ONLY | CONFIRMED FROM SOURCE |
| Delivery fee | Rs 199 flat, free >= Rs 1,500 | CONFIRMED FROM SOURCE |
| Returns | 7-day window (`ReturnService::RETURN_WINDOW_DAYS`) | CONFIRMED FROM SOURCE |
| Pricing | All-in (includes tax), via PricingService | CONFIRMED FROM SOURCE |
| Discounts | Real only (marketplace_price < selling_price) | CONFIRMED FROM SOURCE |
| Ratings | Real only (no synthetic/fake stars) | CONFIRMED FROM SOURCE |
| Reviews | Verified purchase required | CONFIRMED FROM SOURCE |
| Stock | Real inventory count, "Only X left" at <=5 | CONFIRMED FROM SOURCE |
| Multi-seller orders | Split into separate parcels per seller | CONFIRMED FROM SOURCE |
| Order reference | Format: `MKT-XXXXXXXX` | CONFIRMED FROM SOURCE |
| Phone validation | Pakistani mobile format (03xxxxxxxxx), >= 10 digits | CONFIRMED FROM SOURCE |
| Email verification | 6-digit OTP at checkout, required before placing order | CONFIRMED FROM SOURCE |
| Currency | PKR (Pakistani Rupees) | CONFIRMED FROM SOURCE |
| Coupon system | Code-based, validated against cart items | CONFIRMED FROM SOURCE |
| Fulfilment | Seller-fulfilled or FBA (Fulfilled by SoftStore) | CONFIRMED FROM SOURCE |
| Tracking | Invoice# + phone# for public lookup | CONFIRMED FROM SOURCE |

## 10. UI/UX Patterns

### Design System Tokens (from source CSS)
```
Accent: #FF6F00 (orange)
Accent dark: #E65100
Amber: #FFB300
Surface: #FFFFFF
Surface-2: #FAFAFA
Surface-3: #F5F6F7
Ink: #17181A
Ink-2: #3C4043
Ink-3: #5F6368
Line: #E6E8EB
Border radius: 10px (sm), 14px (md), 20px (lg)
Fonts: Inter (body), Google Sans (headings/buttons), Roboto Mono (numbers)
```

### Interaction Patterns
- Toast notifications for cart actions
- Skeleton loading for AI advisor
- Animated success tick on order confirmation
- Hover-to-zoom on product images
- Sticky mobile buy bar on product detail
- Off-canvas filter drawer on mobile
- Step indicators (Cart → Delivery → Confirm)
- Form validation with inline error messages
- Loading spinners on buttons during API calls

## 11. Important Unknowns / Questions for Backend Team

### Must Confirm Before Flutter Development

1. **Base API URL** — Is there a dedicated API prefix (e.g., `/api/v1/`) or do all endpoints use the current web routes?
2. **Authentication for mobile** — Will the app use token-based auth (JWT/Bearer) or session cookies? The web uses PHP sessions.
3. **Cart persistence** — Should mobile cart be server-side (since localStorage won't transfer between devices)?
4. **Push notifications** — Any existing notification system? The web relies on email.
5. **Image CDN/URLs** — Are product images served from a CDN? What's the base URL pattern?
6. **Pagination params** — What's the page size? Is cursor-based pagination available?
7. **Search API** — Is there a dedicated search endpoint or does it go through the same `/store` route with params?
8. **Wishlist API** — Is there a GET endpoint to fetch wishlist, or only the toggle?
9. **Address CRUD** — Exact endpoints and payload for address management?
10. **Profile update** — What fields are editable? Is phone number change verified?
11. **Password reset flow** — What are the exact steps (email → OTP → new password)?
12. **Google OAuth for mobile** — Will mobile use the same OAuth configuration?
13. **Order cancellation** — Can a buyer cancel a pending order? What's the endpoint?
14. **Return request** — What's the flow for initiating a return?
15. **Product availability** — Is stock checked in real-time at checkout, or only when order is placed?
16. **Delivery estimation** — Source explicitly says "nothing in this system produces a delivery-time estimate." Is this planned?
17. **Rate limiting** — Any rate limits on the coupon validation or OTP endpoints?
18. **Error response format** — Consistent JSON error shape across all endpoints?
19. **App-specific endpoints** — Will the backend expose mobile-optimized endpoints or should we use existing web endpoints?
20. **Deep linking** — Product URLs use slugs; how should the app resolve `/product/{slug}`?

### Nice to Know

21. **Categories hierarchy** — Are categories flat or nested?
22. **Coupon types** — Fixed amount only, or percentage-based too? Free shipping coupons confirmed.
23. **Order status webhooks** — Any WebSocket/SSE for real-time status updates?
24. **Multiple addresses** — Can a buyer save multiple addresses and select at checkout?
25. **Seller store page** — What additional data is shown (full product list? about section? reviews?)?

## 12. Summary of Findings

The Softstore buyer website is a **PHP-based server-rendered application** with a clean marketplace model:

- **Browsing** is fully public (no auth), with rich filtering, sorting, and search
- **Cart** is entirely client-side (localStorage), synced to server only at checkout
- **Checkout** requires email verification via OTP but does NOT require an account
- **Payment** is exclusively Cash on Delivery (COD)
- **Orders** are split per-seller into separate parcels when cart has items from multiple stores
- **Tracking** is public (invoice + phone verification)
- **Accounts** provide order history, wishlist, addresses, and profile management
- **Reviews** are purchase-verified only
- **Pricing** is controlled by a central PricingService ensuring consistency between display and billing

The Flutter Buyer App should replicate all public and authenticated buyer functionality, adapting the client-side cart to a more appropriate mobile pattern (likely server-side persistence for cross-device sync), and implementing the existing API contracts discovered in this analysis.
