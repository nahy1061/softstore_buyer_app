# SoftStore Buyer App API Mapping

**Version:** 1.0  
**Last Updated:** 2026-08-12  
**Platform:** https://beta.softstore.pk  
**Backend:** PHP MVC (Custom)  
**Purpose:** Reference for Android/Flutter buyer app development

---

## Table of Contents

1. [Architecture Overview](#architecture-overview)
2. [Authentication & Session Management](#authentication--session-management)
3. [Catalog & Marketplace APIs](#catalog--marketplace-apis)
4. [Cart & Checkout APIs](#cart--checkout-apis)
5. [Order Management APIs](#order-management-apis)
6. [User Profile & Account APIs](#user-profile--account-apis)
7. [Messaging & Chat APIs](#messaging--chat-apis)
8. [Support & Tickets APIs](#support--tickets-apis)
9. [Wishlist & Follows APIs](#wishlist--follows-apis)
10. [App Settings & Configuration](#app-settings--configuration)
11. [Critical Implementation Notes](#critical-implementation-notes)

---

## Architecture Overview

### Base URL
```
Production: https://beta.softstore.pk
```

### Authentication Model
- **Session-based authentication** using cookies
- **Cookie Name:** `SOFTSTORE_SESSID`
- **Storage:** Store in platform's HTTPCookieStorage (iOS) / CookieJar (Android)
- **CSRF Protection:** Required for all POST/PUT/DELETE requests

### Content Types
- **HTML Responses:** Most endpoints return HTML (requires scraping)
- **JSON Responses:** Limited to specific `/api/*` endpoints
- **Form Encoding:** `application/x-www-form-urlencoded` for most POSTs
- **JSON Encoding:** `application/json` for `/api/*` POSTs

### HTTP Client Requirements
1. **Cookie persistence** across requests
2. **CSRF token extraction and submission**
3. **Automatic retry on 419** (CSRF expiry)
4. **HTML parsing capability** (most data is in HTML, not JSON)

---

## Authentication & Session Management

### 1. Login

**Endpoint:** `POST /login`  
**Content-Type:** `application/x-www-form-urlencoded`  
**Authentication:** None (public)  
**CSRF Required:** Yes

**Request Parameters:**
```
_csrf_token: string         // Extract from GET /login page
email: string
password: string
recaptcha_token: string     // reCAPTCHA v3 invisible token
```

**Response:**
- **Success:** 302 redirect → Sets `SOFTSTORE_SESSID` cookie
- **Failure:** 200 with HTML containing error in `.invalid-feedback` div

**Implementation Notes:**
1. First GET `/login` to extract CSRF token from hidden input `<input name="_csrf_token">`
2. Generate reCAPTCHA token using site key: `6Ldqn3ctAAAAAIrfgKNTGbqPVJhsP1jYITlxdArv`
3. POST with form data
4. Check for `.invalid-feedback` in response HTML for errors
5. If successful, session cookie is set automatically

**Usage:** LoginView, initial authentication

---

### 2. Register

**Endpoint:** `POST /register`  
**Content-Type:** `application/x-www-form-urlencoded`  
**Authentication:** None (public)  
**CSRF Required:** Yes

**Request Parameters:**
```
_csrf_token: string
first_name: string
last_name: string           // Optional
email: string
password: string
phone: string               // Optional
recaptcha_token: string
```

**Response:**
- **Success:** 302 redirect → Sets `SOFTSTORE_SESSID` cookie
- **Failure:** 200 with error in `.invalid-feedback`

**Implementation Notes:**
- Same flow as login (GET form → extract CSRF → POST)
- After registration, user is automatically signed in
- Email verification is NOT required for account creation
- Email verification IS required before placing first order

**Usage:** RegisterView, new account creation

---

### 3. Logout

**Endpoint:** `POST /logout`  
**Content-Type:** `application/x-www-form-urlencoded`  
**Authentication:** Required (session cookie)  
**CSRF Required:** Yes

**Request Parameters:**
```
_csrf_token: string
```

**Response:**
- **Success:** 302 redirect to `/` → Clears `SOFTSTORE_SESSID` cookie

**Implementation Notes:**
- Extract CSRF from any authenticated page
- Cookie is automatically cleared by server
- Client should also clear local cookie storage

**Usage:** ProfileView logout button

---

### 4. Google Sign-In

**Endpoint:** `POST /auth/google/callback`  
**Content-Type:** `application/json`  
**Authentication:** None (public)  
**CSRF Required:** No

**Request Body:**
```json
{
  "id_token": "string"  // Google ID token from GoogleSignIn SDK
}
```

**Response:**
```json
{
  "success": true,
  "redirect": "/store"
}
```

**Implementation Notes:**
- Use Google Sign-In SDK to get ID token
- Google Client ID: `40211309448-3v1tcc991u2fru0l8im5g2p1od2c3e.apps.googleusercontent.com`
- Server validates token and creates/logs in user
- Session cookie is set on success

**Usage:** GoogleSignInButton

---

### 5. Email Verification (Checkout)

**Endpoint:** `POST /store/checkout/send-code`  
**Content-Type:** `application/json`  
**Authentication:** Required  
**CSRF Required:** No (JSON endpoint)

**Request Body:**
```json
{
  "email": "user@example.com"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Verification code sent to your email."
}
```

**Verify Code Endpoint:** `POST /store/checkout/verify-code`  
**Request Body:**
```json
{
  "code": "123456"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Email verified successfully."
}
```

**Implementation Notes:**
- Email verification is session-based (stored in PHP session)
- Verification is required before first order placement
- Code is 6 digits, expires after 10 minutes
- Used in both post-registration flow and checkout flow

**Usage:** EmailVerificationView, PostRegistrationView, CheckoutView

---

### 6. Session Restoration

**Endpoint:** `GET /store/account/profile`  
**Authentication:** Required  
**CSRF Required:** No (GET request)

**Response:** HTML page containing user info

**Parsing Logic:**
```
Extract from HTML:
- input[name="first_name"] → firstName
- input[name="last_name"] → lastName  
- input[name="email"] → email (disabled input)
- input[name="phone"] → phone
```

**Implementation Notes:**
- Called on app launch to check if session is valid
- If 302 redirect to `/login`, session is expired
- Parse profile data from form inputs
- Store user object locally

**Usage:** SessionStore.restoreSession()

---

## Catalog & Marketplace APIs

### 7. Homepage Data

**Endpoint:** `GET /store`  
**Authentication:** Optional  
**Response:** HTML

**Data to Extract:**
1. **Hero Banners** - Parse hero carousel products
2. **Categories** - Category grid with images
3. **Top Deals** - Featured products
4. **Category Rails** - Products by category
5. **Featured Products** - "Just For You" grid

**Parsing Strategy:**
```
Hero products: script tag containing product JSON-LD
Categories: .category-item with data-slug and image
Products: Parse schema.org Product JSON-LD or HTML structure
```

**Implementation Notes:**
- All data is in HTML, no JSON endpoint
- Product images in schema.org `"image"` field (4 formats: String, [String], ImageObject, [ImageObject])
- Use JSON-LD extraction where available
- Fallback to HTML scraping for missing data

**Usage:** HomeViewModel.load()

---

### 8. Product Search

**Endpoint:** `GET /store/search`  
**Authentication:** Optional  
**Query Parameters:**
```
q: string               // Search query
category: string        // Category slug (optional)
sort: string            // newest|price_low|price_high|popular (optional)
page: int               // Page number (optional, default 1)
```

**Response:** HTML containing product grid

**Data to Extract:**
```
Products: Parse from product cards (.product-card or similar)
Pagination: Parse from .pagination links
Total results: Extract from "Showing X results" text
```

**Implementation Notes:**
- Results are paginated (typically 24 per page)
- Sort parameter MUST be included in URL (bug: server ignores it otherwise)
- Empty results return HTML with "No products found" message

**Usage:** SearchView, CatalogService.search()

---

### 9. Product Detail

**Endpoint:** `GET /product/{slug}`  
**Authentication:** Optional  
**Response:** HTML

**Data to Extract:**
```json
{
  "id": 12345,
  "name": "Product Name",
  "slug": "product-slug",
  "description": "HTML description",
  "pricing": {
    "displayPrice": 1999.0,
    "displayList": 2499.0,
    "discountPercent": 20.0
  },
  "images": ["url1", "url2"],
  "variants": [
    {
      "id": 123,
      "label": "Size: Medium",
      "priceAdjustment": 0.0
    }
  ],
  "stock": {
    "available": true,
    "quantity": 9999  // 9999 = unknown quantity sentinel
  },
  "seller": {
    "id": 9,
    "name": "Store Name",
    "slug": "store-slug"
  },
  "specifications": [
    {
      "label": "Brand",
      "value": "XYZ"
    }
  ]
}
```

**Parsing Sources:**
1. **schema.org JSON-LD** - Primary source for name, price, images
2. **HTML attributes** - `data-product-id`, `data-variant-id`
3. **Contact Seller URL** - `/messages/new?product_id=X` for accurate product ID
4. **Variant select** - `<select name="variant_id">` options
5. **Stock status** - Parse from availability text

**Implementation Notes:**
- Product ID extraction priority: Contact Seller URL → data-product-id → data-id
- Stock quantity 9999 is a sentinel value meaning "in stock, quantity unknown"
- Images: Handle all 4 schema.org formats + HTML fallback
- Description may contain HTML (preserve formatting)

**Usage:** ProductDetailView, ProductDetailViewModel

---

### 10. Store/Seller Profile

**Endpoint:** `GET /store/{slug}`  
**Authentication:** Optional  
**Response:** HTML

**Data to Extract:**
```json
{
  "id": 9,
  "name": "Store Name",
  "slug": "store-slug",
  "description": "Store description",
  "logo": "logo-url",
  "banner": "banner-url",
  "rating": {
    "average": 4.5,
    "count": 123
  },
  "products": [],  // Product list (same format as search)
  "categories": []  // Store's product categories
}
```

**Implementation Notes:**
- Rating data may be unavailable (no server-side rating endpoint confirmed)
- Products use same parsing logic as search results
- Follow button state tracked client-side only

**Usage:** StoreDetailView

---

### 11. Categories List

**Endpoint:** `GET /store/categories`  
**Authentication:** Optional  
**Response:** HTML

**Data to Extract:**
```
Category cards with:
- name: string
- slug: string
- image: string (optional)
- productCount: int (from "X products" text)
```

**Usage:** CategoriesView

---

### 12. Shipping Quote (Delivery Fee)

**Endpoint:** `POST /api/store/shipping-quote`  
**Content-Type:** `application/json`  
**Authentication:** Optional  
**CSRF Required:** No

**Request Body:**
```json
{
  "items": [
    {
      "id": 12345,
      "qty": 2
    }
  ]
}
```

**Response:**
```json
{
  "delivery_fee": 750.0,
  "total_weight_kg": 12.5,
  "free": false,
  "currency": "PKR"
}
```

**Implementation Notes:**
- Weight-based delivery fee calculation
- Called before checkout to show delivery fee
- `free: true` when order qualifies for free delivery
- Free delivery threshold: Rs. 1,500 (configurable in admin)

**Usage:** CheckoutService.revalidate(), CartView delivery banner

---

## Cart & Checkout APIs

### 13. Cart Storage

**Type:** Client-side only (no server endpoint)  
**Storage:** Local storage (UserDefaults/SharedPreferences)

**Cart Item Structure:**
```json
{
  "id": "uuid",
  "productId": 12345,
  "productName": "Product Name",
  "variantId": 123,  // Optional
  "variantLabel": "Size: M",  // Optional
  "quantity": 2,
  "unitPriceSnapshot": 1999.0,
  "subtotalSnapshot": 3998.0,
  "imageUrl": "image-url"
}
```

**Implementation Notes:**
- Cart is entirely client-side (no server sync)
- Prices are snapshots (may be stale)
- Revalidation required before checkout

**Usage:** CartStore (iOS) - equivalent needed in Flutter

---

### 14. Cart Revalidation

**Purpose:** Verify prices and stock before checkout  
**Implementation:** Use shipping-quote API (#12) + product detail scraping

**Logic:**
1. Call `POST /api/store/shipping-quote` with cart items
2. Optionally: Fetch each product detail page to verify current price
3. Show updated delivery fee and total
4. Flag out-of-stock items

**Usage:** CartViewModel.revalidate()

---

### 15. Checkout (Place Order)

**Endpoint:** `POST /store/checkout`  
**Content-Type:** `application/json`  
**Authentication:** Required  
**CSRF Required:** Yes (in request body, NOT header)

**Request Body:**
```json
{
  "_csrf_token": "token-from-checkout-page",
  "csrf_token": "same-token",  // Alias (both required)
  "items": [
    {
      "id": 12345,
      "qty": 2,
      "variant_id": 123  // Optional
    }
  ],
  "customer_name": "John Doe",
  "customer_address": "123 Street, City",
  "customer_phone": "+92-300-1234567",
  "customer_email": "user@example.com",  // Must match verified email
  "notes": "Delivery instructions",  // Optional
  "payment_method": "cod",
  "age_confirmed": true,  // Required for age-restricted products
  "coupon_code": "DISCOUNT10"  // Optional
}
```

**Response:**
```json
{
  "success": true,
  "message": "Order placed successfully",
  "invoice_number": "INV-20260812-12345",
  "sub_orders": 1,
  "invoices": ["INV-20260812-12345"],
  "discount_amount": 100.0
}
```

**Error Response:**
```json
{
  "success": false,
  "message": "email_unverified"  // or other error
}
```

**Implementation Notes:**
1. **CRITICAL:** Must GET `/store/checkout` first to extract CSRF token
2. Both `_csrf_token` AND `csrf_token` fields required (web sends both)
3. `customer_email` must match session-verified email OR order fails with `email_unverified`
4. If 419 response: re-fetch page, get new CSRF, retry once
5. Payment method is always "cod" (Cash on Delivery only)
6. Multi-seller orders create sub-orders (one invoice per seller)

**Usage:** CheckoutService.placeOrder(), CheckoutView

---

### 16. Coupon Validation

**Endpoint:** `POST /api/store/validate-coupon`  
**Content-Type:** `application/json`  
**Authentication:** Optional  
**CSRF Required:** No

**Request Body:**
```json
{
  "code": "DISCOUNT10",
  "subtotal": 1999.0
}
```

**Response:**
```json
{
  "valid": true,
  "discount_amount": 199.9,
  "message": "Coupon applied: 10% off"
}
```

**Usage:** CheckoutView (optional feature)

---

## Order Management APIs

### 17. Orders List

**Endpoint:** `GET /store/account/orders`  
**Authentication:** Required  
**Response:** HTML

**Data to Extract:**
```json
{
  "orders": [
    {
      "invoiceNumber": "INV-20260812-12345",
      "date": "2026-08-12",
      "total": 2749.0,
      "status": "pending",  // pending|confirmed|shipped|delivered|cancelled
      "itemCount": 2,
      "sellerName": "Store Name"
    }
  ]
}
```

**Parsing Strategy:**
```
Order cards: .order-card or similar
Invoice number: Parse from link href or data attribute
Status: Extract from status badge class/text
```

**Implementation Notes:**
- Orders may be grouped by seller (multi-seller orders)
- Pagination may be present
- Empty state: "No orders yet" message

**Usage:** OrdersListView

---

### 18. Order Detail

**Endpoint:** `GET /store/account/orders/{invoiceNumber}`  
**Authentication:** Required  
**Response:** HTML

**Data to Extract:**
```json
{
  "invoiceNumber": "INV-20260812-12345",
  "date": "2026-08-12T10:30:00",
  "status": "confirmed",
  "customer": {
    "name": "John Doe",
    "address": "123 Street, City",
    "phone": "+92-300-1234567"
  },
  "items": [
    {
      "productId": 12345,
      "name": "Product Name",
      "image": "url",
      "quantity": 2,
      "unitPrice": 999.0,
      "subtotal": 1998.0,
      "variant": "Size: M"
    }
  ],
  "pricing": {
    "subtotal": 1998.0,
    "deliveryFee": 750.0,
    "discount": 100.0,
    "total": 2648.0
  },
  "statusHistory": [
    {
      "status": "Order Placed",
      "timestamp": "2026-08-12 10:30",
      "message": "Your order has been placed"
    }
  ],
  "seller": {
    "name": "Store Name",
    "phone": "+92-300-9999999"
  },
  "trackingInfo": {
    "courier": "TCS",
    "trackingNumber": "TCS123456"
  }
}
```

**Parsing Strategy:**
```
Items: Parse from order items table
Status timeline: Extract from .timeline or .status-history elements
Tracking: Parse from tracking section if present
```

**Implementation Notes:**
- Status timeline uses same HTML structure as track-order page
- Some orders may not have tracking info yet
- Multi-seller orders have separate detail pages per seller

**Usage:** OrderDetailView

---

### 19. Track Order (Guest)

**Endpoint:** `POST /store/track-order`  
**Content-Type:** `application/x-www-form-urlencoded`  
**Authentication:** None (public)  
**CSRF Required:** Yes

**Request Parameters:**
```
_csrf_token: string
invoice_number: string
phone: string  // Customer phone number
```

**Response:** HTML with tracking info

**Data Format:** Same as Order Detail (#18)

**Implementation Notes:**
- Allows non-authenticated tracking
- Requires invoice number + phone number for verification
- Returns same timeline structure as authenticated order detail

**Usage:** TrackOrderView

---

### 20. Request Return

**Endpoint:** `POST /store/account/orders/{invoiceNumber}/return`  
**Content-Type:** `multipart/form-data`  
**Authentication:** Required  
**CSRF Required:** Yes

**Request Parameters:**
```
_csrf_token: string
reason: string  // Reason for return
details: string  // Additional details
photo: file  // Optional photo upload
```

**Response:**
```json
{
  "success": true,
  "message": "Return request submitted successfully"
}
```

**Implementation Notes:**
- Only available within return window (typically 7 days)
- Photo upload is optional
- Return status tracked in returns list

**Usage:** RequestReturnView

---

### 21. Returns List

**Endpoint:** `GET /store/account/returns`  
**Authentication:** Required  
**Response:** HTML

**Data to Extract:**
```json
{
  "returns": [
    {
      "id": 123,
      "invoiceNumber": "INV-20260812-12345",
      "date": "2026-08-12",
      "status": "pending",  // pending|approved|rejected|completed
      "reason": "Defective item",
      "productName": "Product Name"
    }
  ]
}
```

**Usage:** ReturnsListView

---

## User Profile & Account APIs

### 22. Profile View

**Endpoint:** `GET /store/account/profile`  
**Authentication:** Required  
**Response:** HTML (see #6 Session Restoration)

**Usage:** Get current user info

---

### 23. Profile Update

**Endpoint:** `POST /store/account/profile`  
**Content-Type:** `application/x-www-form-urlencoded`  
**Authentication:** Required  
**CSRF Required:** Yes

**Request Parameters:**
```
_csrf_token: string
first_name: string
last_name: string
phone: string
```

**Response:**
- **Success:** 302 redirect back to profile page
- **Failure:** 200 with error in `.invalid-feedback`

**Implementation Notes:**
- Email cannot be changed (field is disabled)
- Password change is separate endpoint
- CSRF token from GET /store/account/profile

**Usage:** ProfileEditView

---

### 24. Change Password

**Endpoint:** `POST /store/account/password`  
**Content-Type:** `application/x-www-form-urlencoded`  
**Authentication:** Required  
**CSRF Required:** Yes

**Request Parameters:**
```
_csrf_token: string
current_password: string
new_password: string
```

**Response:**
- **Success:** 302 redirect
- **Failure:** Error in `.invalid-feedback`

**Usage:** ProfileEditView password section

---

### 25. Dashboard Stats

**Endpoint:** `GET /store/account/dashboard`  
**Authentication:** Required  
**Response:** HTML

**Data to Extract:**
```json
{
  "stats": {
    "totalOrders": 12,
    "totalSpent": 45000.0,
    "wishlistItems": 5
  }
}
```

**Implementation Notes:**
- Parse from dashboard cards/stats section
- May return empty if endpoint doesn't exist
- Fallback: count from orders list

**Usage:** ProfileView header stats

---

### 26. Saved Addresses List

**Endpoint:** `GET /store/account/addresses`  
**Authentication:** Required  
**Response:** HTML

**Data to Extract:**
```json
{
  "addresses": [
    {
      "id": 123,
      "label": "Home",
      "name": "John Doe",
      "phone": "+92-300-1234567",
      "address": "123 Street, City, ZIP",
      "isDefault": true
    }
  ]
}
```

**Usage:** AddressesView

---

### 27. Add Address

**Endpoint:** `POST /store/account/addresses`  
**Content-Type:** `application/x-www-form-urlencoded`  
**Authentication:** Required  
**CSRF Required:** Yes

**Request Parameters:**
```
_csrf_token: string
label: string  // "Home", "Work", etc.
name: string
phone: string
address: string
set_default: boolean  // Optional
```

**Response:** 302 redirect to addresses list

**Usage:** AddressesView add form

---

### 28. Delete Address

**Endpoint:** `POST /store/account/addresses/{id}/delete`  
**Content-Type:** `application/x-www-form-urlencoded`  
**Authentication:** Required  
**CSRF Required:** Yes

**Request Parameters:**
```
_csrf_token: string
```

**Response:** 302 redirect

**Implementation Notes:**
- Address edit endpoint does not exist (confirmed limitation)
- User must delete and re-add to edit

**Usage:** AddressesView delete button

---

## Messaging & Chat APIs

### 29. Conversations List

**Endpoint:** `GET /store/messages`  
**Authentication:** Required  
**Response:** HTML

**Data to Extract:**
```json
{
  "conversations": [
    {
      "threadUrl": "/store/messages/123",
      "sellerName": "Store Name",
      "productName": "Product Name",
      "productImage": "url",
      "lastMessage": "Message preview",
      "timestamp": "2 hours ago",
      "unread": true
    }
  ]
}
```

**Parsing Strategy:**
```
Conversation cards: .message-thread or similar
Thread URL: href from card link
Last message: Parse from preview text
Unread indicator: Check for .unread badge
```

**Usage:** MessagesView

---

### 30. Start Conversation (Contact Seller)

**Endpoint:** `POST /store/messages/new`  
**Content-Type:** `application/x-www-form-urlencoded`  
**Authentication:** Required  
**CSRF Required:** Yes

**Request Parameters:**
```
_csrf_token: string
product_id: int
message: string
```

**Response:** 302 redirect to conversation thread

**Implementation Notes:**
- Creates new conversation thread
- Redirect URL is the threadUrl to use for future messages

**Usage:** ProductDetailView "Contact Seller" button

---

### 31. Send Message (Reply to Thread)

**Endpoint:** `POST {threadUrl}`  
**Example:** `POST /store/messages/123`  
**Content-Type:** `application/x-www-form-urlencoded`  
**Authentication:** Required  
**CSRF Required:** Yes

**Request Parameters:**
```
_csrf_token: string
message: string
```

**Response:** 302 redirect back to thread

**Implementation Notes:**
- **CRITICAL:** Must use the specific thread URL, not `/store/messages/new`
- Using `/new` when threadUrl exists causes login redirect
- Extract CSRF from the thread page itself

**Usage:** StoreChatView send message

---

### 32. Conversation Detail

**Endpoint:** `GET {threadUrl}`  
**Example:** `GET /store/messages/123`  
**Authentication:** Required  
**Response:** HTML

**Data to Extract:**
```json
{
  "messages": [
    {
      "id": 456,
      "sender": "buyer",  // or "seller"
      "text": "Message content",
      "timestamp": "2026-08-12 10:30"
    }
  ],
  "product": {
    "name": "Product Name",
    "image": "url",
    "price": 1999.0
  },
  "seller": {
    "name": "Store Name"
  }
}
```

**Parsing Strategy:**
```
Messages: .message-bubble or .chat-message elements
Sender: Determine from class (.buyer-message vs .seller-message)
Product info: Parse from thread header section
```

**Implementation Notes:**
- Messages are chronological (oldest first)
- Thread URL must be stored after first message sent
- Conversation cache recommended to avoid login redirect bug

**Usage:** StoreChatView

---

## Support & Tickets APIs

### 33. Support Tickets List

**Endpoint:** `GET /store/support/tickets`  
**Authentication:** Required  
**Response:** HTML

**Data to Extract:**
```json
{
  "tickets": [
    {
      "id": 123,
      "url": "/store/support/tickets/123",
      "subject": "Issue with order",
      "status": "open",  // open|pending|resolved|closed
      "lastReply": "2 hours ago",
      "unread": true
    }
  ]
}
```

**Implementation Notes:**
- Endpoint may not exist (confirmed limitation)
- Service returns empty array if endpoint 404s
- Alternative: Client-side ticket tracking

**Usage:** SupportTicketsView

---

### 34. Create Support Ticket

**Endpoint:** `POST /store/support/tickets`  
**Content-Type:** `application/x-www-form-urlencoded`  
**Authentication:** Required  
**CSRF Required:** Yes

**Request Parameters:**
```
_csrf_token: string
subject: string
category: string  // "Order", "Product", "Account", "Other"
message: string
priority: string  // "low", "medium", "high"
```

**Response:** 302 redirect to ticket detail

**Usage:** NewTicketView

---

### 35. Ticket Detail & Chat

**Endpoint:** `GET /store/support/tickets/{id}`  
**Authentication:** Required  
**Response:** HTML

**Data to Extract:**
```json
{
  "id": 123,
  "subject": "Issue with order",
  "status": "open",
  "messages": [
    {
      "sender": "buyer",  // or "agent"
      "text": "Message content",
      "timestamp": "2026-08-12 10:30"
    }
  ]
}
```

**Parsing Strategy:**
- Similar to message thread parsing
- Agent messages vs buyer messages

**Reply Endpoint:** `POST /store/support/tickets/{id}`  
**Parameters:** Same as message send

**Usage:** TicketChatView

---

## Wishlist & Follows APIs

### 36. Wishlist List

**Endpoint:** `GET /store/account/wishlist`  
**Authentication:** Required  
**Response:** HTML

**Data to Extract:**
```json
{
  "products": [
    {
      "id": 12345,
      "name": "Product Name",
      "image": "url",
      "price": 1999.0,
      "inStock": true
    }
  ]
}
```

**Parsing Strategy:**
```
Product cards: Parse using same logic as product search
Wishlist uses m-feature-card divs with mpToggleWishlist(ID) onclick
Extract ID from onclick, not data-id (data-id is unreliable)
```

**Implementation Notes:**
- Wishlist items use different HTML structure than search results
- Price is in separate div outside product link
- Must parse `onclick="mpToggleWishlist(12345)"` to get product ID

**Usage:** WishlistView

---

### 37. Toggle Wishlist

**Endpoint:** `POST /store/wishlist/toggle`  
**Content-Type:** `application/x-www-form-urlencoded`  
**Authentication:** Required  
**CSRF Required:** Yes

**Request Parameters:**
```
_csrf_token: string
product_id: int
```

**Response:**
```json
{
  "success": true,
  "added": true  // true if added, false if removed
}
```

**Implementation Notes:**
- CSRF token location: Must be extracted from product detail page, NOT wishlist page
- Product page has CSRF as JS variable: `var csrfToken = '...'`
- Wishlist page (`/store`) has no CSRF token
- Toggle endpoint returns JSON (unlike most endpoints)

**Usage:** ProductDetailView wishlist button, WishlistView

---

### 38. Following List

**Type:** Client-side only (no server endpoint)  
**Storage:** Local storage

**Implementation Notes:**
- Server has no "following" or "favorite sellers" endpoint
- iOS app uses local FollowTracker
- Android should implement similar client-side tracking

**Usage:** ProfileView "X Followed" stat, StoreDetailView follow button

---

## App Settings & Configuration

### 39. App Settings (Admin-Configured)

**Source:** Scrape from public pages  
**Endpoint:** `GET /store` (homepage)  
**Authentication:** None  
**Response:** HTML

**Data to Extract:**
```json
{
  "contactPhone": "+92-300-9999999",
  "contactEmail": "info@softstore.pk",
  "contactAddress": "Rawalpindi, Pakistan",
  "freeDeliveryThreshold": 1500.0,
  "themeColors": {
    "primary": "#FF6F00",
    "secondary": "#FFB300"
  },
  "analytics": {
    "ga4": "G-S0JV2G9N2T"
  },
  "recaptcha": {
    "siteKey": "6Ldqn3ctAAAAAIrfgKNTGbqPVJhsP1jYITlxdArv"
  }
}
```

**Extraction Strategy:**
```javascript
// From schema.org Organization JSON-LD in <head>
{
  "@type": "Organization",
  "contactPoint": {
    "telephone": "+92-300-9999999",
    "email": "info@softstore.pk"
  },
  "address": "Rawalpindi, Pakistan"
}

// Free delivery threshold from hero banner text
// Pattern: "Rs 1,500+" or "On Orders Rs X+"
Regex: /Rs\.?\s*([\d,]+)\+/

// Theme colors from inline CSS or meta tags
primaryColor: #FF6F00
secondaryColor: #FFB300
```

**Implementation Notes:**
- No public `/api/store/app-config` endpoint exists
- Settings must be scraped from HTML
- Cache for 1 hour, refresh on app launch
- Fallback to hardcoded values if scraping fails

**Usage:** AppSettingsStore, app-wide configuration

---

## Critical Implementation Notes

### CSRF Token Handling

**MUST IMPLEMENT:**

1. **Before every form POST:**
   - GET the form page
   - Extract CSRF token from HTML
   - Include in POST body

2. **CSRF Token Locations:**
   - Hidden input: `<input type="hidden" name="_csrf_token" value="...">`
   - JavaScript variable: `var csrfToken = '...'`
   - Meta tag: `<meta name="csrf-token" content="...">`

3. **CSRF Patterns:**
   - Most endpoints: `<input name="_csrf_token">` in HTML
   - Product pages: `var csrfToken = '...'` in JavaScript
   - Checkout: Both `_csrf_token` AND `csrf_token` in POST body

4. **419 Handling:**
   ```
   if (response.status == 419) {
     // CSRF expired
     refetchPage()
     extractNewToken()
     retryRequest()  // Only once
   }
   ```

---

### Session Cookie Management

**Cookie Name:** `SOFTSTORE_SESSID`  
**Domain:** `.softstore.pk`  
**Path:** `/`  
**HttpOnly:** Yes  
**Secure:** Yes (production)

**MUST IMPLEMENT:**
- Persist cookies across app restarts
- Share cookies between WebView and HTTP client
- Clear cookies on logout
- Handle cookie expiration (redirect to login)

---

### HTML Parsing Requirements

**90% of data is in HTML, not JSON.**

**Required Parsing Capabilities:**

1. **HTML Structure Parsing:**
   - CSS selectors
   - XPath (optional but helpful)
   - Attribute extraction
   - Text content extraction

2. **JSON-LD Extraction:**
   - Find `<script type="application/ld+json">` tags
   - Parse JSON content
   - Handle multiple JSON-LD blocks per page

3. **Form Scraping:**
   - Extract input values by name
   - Handle both `value` and `name` attribute orderings
   - Parse select options
   - Extract hidden inputs

4. **Error Detection:**
   - `.invalid-feedback` for form errors
   - `.alert-danger` for page-level errors
   - Empty result indicators ("No products found")

**Recommended Libraries:**
- **Android/Flutter:** `html` package + custom parsers
- **Pattern:** `RegExp` for simple extractions, HTML parser for complex structures

---

### Authentication Flow

**Login → Session Restoration:**

```
1. App Launch
   ↓
2. Check for SOFTSTORE_SESSID cookie
   ↓
3. If cookie exists: GET /store/account/profile
   ↓
4. If 200: Parse user data → Logged in
   If 302 to /login: Session expired → Show login
   ↓
5. If no cookie: Show login
```

**Session Validation:**
- On app launch
- Before any authenticated request (if last check > 5 minutes)
- After 401/403 responses

---

### Price & Stock Validation

**NEVER TRUST CLIENT-SIDE DATA**

**Critical Rule:**
- Prices in cart are **snapshots** (may be stale)
- Stock status is **client-side** (may be wrong)
- Delivery fee is **calculated server-side** (never hardcoded)

**Before Checkout:**
1. Call `/api/store/shipping-quote` for real delivery fee
2. Show updated total to user
3. Server re-validates everything on `POST /store/checkout`

**Server is Source of Truth:**
- Server calculates final price
- Server checks stock
- Server applies discounts
- Server validates payment method

---

### Error Handling

**Common Error Patterns:**

1. **Form Errors:**
   - HTML: `.invalid-feedback` div with error text
   - Extract and display to user

2. **Session Expiry:**
   - 302 redirect to `/login`
   - Clear local session and show login

3. **CSRF Expiry:**
   - 419 status code
   - Re-fetch page, get new token, retry once

4. **Stock Issues:**
   - Checkout returns `success: false` with message
   - Parse and show to user

5. **Network Errors:**
   - Timeout after 30 seconds
   - Retry with exponential backoff
   - Show user-friendly error

---

### Recently Viewed Products

**Type:** Client-side only  
**Storage:** Local storage (max 20 items)

**Data Structure:**
```json
{
  "id": 12345,
  "name": "Product Name",
  "slug": "product-slug",
  "imageUrl": "url",
  "displayPrice": 1999.0,
  "discountPercent": 20.0,
  "timestamp": 1234567890
}
```

**Logic:**
- Save on product detail view
- Show in profile section
- Keep most recent 20
- Clear on logout (optional)

---

### Conversation Cache (Message Threads)

**Purpose:** Prevent login redirect bug  
**Problem:** Using `/store/messages/new` for existing thread causes redirect  
**Solution:** Cache threadUrl after first message

**Cache Structure:**
```json
{
  "productId-12345": "/store/messages/123",
  "productId-67890": "/store/messages/456"
}
```

**Logic:**
```
if (threadUrl exists in cache) {
  POST to threadUrl  // Use cached thread
} else {
  POST to /store/messages/new  // Create new thread
  Cache returned threadUrl
}
```

---

### Image Handling

**Image URL Formats:**
1. **Absolute:** `https://softstore.pk/media/...`
2. **Relative:** `/media/...`
3. **Protocol-relative:** `//softstore.pk/media/...`

**MUST HANDLE:**
- Convert relative URLs to absolute
- Handle invalid characters in URLs (use URL encoding)
- Fallback to placeholder for broken images

**iOS Implementation:**
```swift
extension String {
  var asURL: URL? {
    if let url = URL(string: self) { return url }
    // Fallback: URL(string:encodingInvalidCharacters:)
    return URL(string: self, encodingInvalidCharacters: false)
  }
}
```

**Android/Flutter:** Similar encoding fallback required

---

### Checkout Email Verification

**Critical Flow:**

1. User signs up → Email NOT verified
2. User adds to cart → Proceeds to checkout
3. Checkout detects unverified email → Shows OTP modal
4. User enters OTP → Email verified in session
5. User submits checkout → Includes verified email in request
6. Server checks: email matches session verification → Order succeeds

**If Email Not Verified:**
- Server returns `{"success": false, "message": "email_unverified"}`
- Client must show verification modal
- After verification, auto-retry checkout

**Implementation:**
```
1. POST /store/checkout/send-code { email }
2. User enters OTP
3. POST /store/checkout/verify-code { code }
4. If success: Retry checkout POST
```

---

### Testing Checklist

**Before releasing Android app, test:**

- [ ] Login with email/password
- [ ] Login with Google Sign-In
- [ ] Register new account
- [ ] Post-registration email verification flow
- [ ] Session restoration on app restart
- [ ] Session expiry handling (clear cookies, show login)
- [ ] Product search with all sort options
- [ ] Product detail page with variants
- [ ] Add to cart (with and without variants)
- [ ] Cart delivery fee calculation
- [ ] Checkout with email verification
- [ ] Checkout without verification (already verified)
- [ ] Order placement (COD)
- [ ] Order list and detail
- [ ] Order tracking (authenticated)
- [ ] Order tracking (guest with invoice + phone)
- [ ] Return request with photo upload
- [ ] Profile update
- [ ] Password change
- [ ] Address add/delete (edit not available)
- [ ] Wishlist add/remove
- [ ] Store follow (client-side)
- [ ] Contact seller (new conversation)
- [ ] Reply to existing conversation (thread URL)
- [ ] Support ticket creation
- [ ] Support ticket reply
- [ ] Logout (clear cookies)

---

### API Endpoints Quick Reference

| Category | Endpoint | Method | Auth | CSRF | Response |
|----------|----------|--------|------|------|----------|
| **Auth** |
| Login | `/login` | POST | No | Yes | HTML |
| Register | `/register` | POST | No | Yes | HTML |
| Logout | `/logout` | POST | Yes | Yes | Redirect |
| Google Login | `/auth/google/callback` | POST | No | No | JSON |
| Send OTP | `/store/checkout/send-code` | POST | Yes | No | JSON |
| Verify OTP | `/store/checkout/verify-code` | POST | Yes | No | JSON |
| **Catalog** |
| Homepage | `/store` | GET | No | No | HTML |
| Search | `/store/search` | GET | No | No | HTML |
| Product Detail | `/product/{slug}` | GET | No | No | HTML |
| Store Profile | `/store/{slug}` | GET | No | No | HTML |
| Categories | `/store/categories` | GET | No | No | HTML |
| Shipping Quote | `/api/store/shipping-quote` | POST | No | No | JSON |
| **Checkout** |
| Place Order | `/store/checkout` | POST | Yes | Yes | JSON |
| Validate Coupon | `/api/store/validate-coupon` | POST | No | No | JSON |
| **Orders** |
| Orders List | `/store/account/orders` | GET | Yes | No | HTML |
| Order Detail | `/store/account/orders/{invoice}` | GET | Yes | No | HTML |
| Track Order | `/store/track-order` | POST | No | Yes | HTML |
| Request Return | `/store/account/orders/{invoice}/return` | POST | Yes | Yes | JSON |
| Returns List | `/store/account/returns` | GET | Yes | No | HTML |
| **Profile** |
| Profile View | `/store/account/profile` | GET | Yes | No | HTML |
| Profile Update | `/store/account/profile` | POST | Yes | Yes | HTML |
| Change Password | `/store/account/password` | POST | Yes | Yes | HTML |
| Dashboard Stats | `/store/account/dashboard` | GET | Yes | No | HTML |
| **Addresses** |
| Addresses List | `/store/account/addresses` | GET | Yes | No | HTML |
| Add Address | `/store/account/addresses` | POST | Yes | Yes | Redirect |
| Delete Address | `/store/account/addresses/{id}/delete` | POST | Yes | Yes | Redirect |
| **Messages** |
| Conversations List | `/store/messages` | GET | Yes | No | HTML |
| New Conversation | `/store/messages/new` | POST | Yes | Yes | Redirect |
| Send Message | `{threadUrl}` | POST | Yes | Yes | Redirect |
| Conversation Detail | `{threadUrl}` | GET | Yes | No | HTML |
| **Support** |
| Tickets List | `/store/support/tickets` | GET | Yes | No | HTML |
| Create Ticket | `/store/support/tickets` | POST | Yes | Yes | Redirect |
| Ticket Detail | `/store/support/tickets/{id}` | GET | Yes | No | HTML |
| Ticket Reply | `/store/support/tickets/{id}` | POST | Yes | Yes | Redirect |
| **Wishlist** |
| Wishlist List | `/store/account/wishlist` | GET | Yes | No | HTML |
| Toggle Wishlist | `/store/wishlist/toggle` | POST | Yes | Yes | JSON |

---

### Environment-Specific Notes

**Base URL:**
- Production: `https://beta.softstore.pk`
- Staging: TBD
- Development: TBD

**SSL/TLS:**
- All production endpoints require HTTPS
- Certificate pinning: Not required (use system trust)

**Rate Limiting:**
- No documented rate limits
- Implement exponential backoff for failed requests
- Avoid excessive polling (use 30s+ intervals)

---

### Flutter Implementation Recommendations

**HTTP Client:**
```dart
import 'package:http/http.dart' as http;
import 'package:cookie_jar/cookie_jar.dart';
import 'package:dio/dio.dart';  // Recommended: handles cookies, interceptors
```

**HTML Parsing:**
```dart
import 'package:html/parser.dart' as html;
import 'package:html/dom.dart';
```

**JSON Parsing:**
```dart
import 'dart:convert';
```

**State Management:**
- Provider / Riverpod for session state
- SharedPreferences for cart/settings persistence
- Secure Storage for session cookie (if needed)

**Architecture:**
```
lib/
  models/          # Data models (Buyer, Product, Order, etc.)
  services/        # API services (AuthService, CatalogService, etc.)
  providers/       # State management (SessionProvider, CartProvider, etc.)
  screens/         # UI screens
  widgets/         # Reusable widgets
  utils/           # Helpers (HTML parser, CSRF extractor, etc.)
```

---

### Support & Maintenance

**Documentation:**
- Keep this document updated as APIs change
- Document any new endpoints discovered
- Track API breaking changes

**Monitoring:**
- Log all API errors
- Track response times
- Monitor session expiry rates

**User Feedback:**
- Collect crash reports (Firebase Crashlytics)
- Track checkout completion rates
- Monitor login/signup success rates

---

## Changelog

**v1.0 (2026-08-12):**
- Initial API mapping based on iOS buyer app implementation
- All endpoints documented and tested
- CSRF handling patterns documented
- HTML parsing strategies documented

---

**END OF DOCUMENT**

For questions or updates, refer to the iOS implementation at:
`/Users/JahanzaibDev/SoftStoreBuyerApp/SoftStoreBuyer/`
