# Phase 2: User Journeys & Flows

## 1. Guest Buyer — Browse to Purchase

```
App Launch
  │
  ├─ [First time] → Onboarding (3 slides) → Store Home
  └─ [Returning] → Store Home
         │
         ├── Browse products (scroll grid)
         ├── Tap category chip → Filtered grid
         ├── Tap search → Search screen → Type query → Results
         └── Tap product card
                │
                ▼
         Product Detail
         ├── View images (swipe gallery)
         ├── Select variant (if available)
         ├── Set quantity
         └── Tap "Add to cart"
                │
                ▼
         Toast: "Added to cart" (badge updates)
         User continues browsing or taps cart icon
                │
                ▼
         Cart Screen
         ├── Review items, quantities, totals
         ├── See delivery fee (Rs 199 or FREE)
         └── Tap "Proceed to checkout"
                │
                ▼
         Sign-in prompt (optional)
         ├── [Skip] → Continue as guest
         ├── [Sign in] → Login screen → Return to checkout
         └── [Create account] → Register → Return to checkout
                │
                ▼
         Checkout Step 1: Delivery Details
         ├── Full name, phone, address, city, notes
         └── Tap "Continue"
                │
                ▼
         Checkout Step 2: Email Verification
         ├── Enter email → Tap "Send code"
         ├── Check email for 6-digit OTP
         ├── Enter OTP → Tap "Verify"
         └── [Already verified] → Skip (badge: Verified)
                │
                ▼
         Checkout Step 3: Review & Confirm
         ├── Order summary (items, coupon, delivery, total)
         ├── Payment: Cash on Delivery (info only)
         ├── [Optional] Enter coupon code → Apply
         └── Tap "Place order"
                │
                ▼
         [Loading: "Placing your order..."]
                │
                ├── [Success] → Order Confirmation Screen
                │     ├── Reference number (copy)
                │     ├── "What happens next" steps
                │     ├── Tap "View my orders" (if signed in)
                │     └── Tap "Keep shopping" → Store Home
                │
                └── [Failure] → Error message
                      └── Fix issue → Retry
```

## 2. Registered Buyer — Full Journey

```
App Launch
  │
  └── [Has stored token] → Auto-login → Store Home
         │
         ├── Bottom nav: Home | Categories | Cart | Orders | Profile
         │
         ├── Home tab → Product grid
         │     ├── Pull to refresh
         │     ├── Scroll / load more
         │     └── Tap product → Product Detail
         │
         ├── Search (persistent bar or icon)
         │     ├── Tap → Search screen
         │     ├── Recent searches shown
         │     ├── Type query → Results appear
         │     └── Tap product → Product Detail
         │
         ├── Product Detail
         │     ├── Add to cart (quantity, variant)
         │     ├── Add to wishlist (heart icon)
         │     ├── Buy now → Checkout
         │     ├── WhatsApp seller → External app
         │     ├── Share → Native share sheet
         │     └── Submit review (if purchased)
         │
         ├── Cart tab
         │     ├── Edit quantities / remove items
         │     ├── See totals and delivery status
         │     └── Checkout
         │           ├── Saved addresses → Select or add new
         │           ├── Email pre-verified (session)
         │           ├── Apply coupon
         │           └── Place order
         │                 │
         │                 ▼
         │           Order Confirmation
         │
         ├── Orders tab
         │     ├── Order history list (filterable by status)
         │     ├── Tap order → Order Detail
         │     │     ├── Status pipeline
         │     │     ├── Items, seller, amounts
         │     │     ├── Tracking timeline
         │     │     └── [Future] Cancel / Return actions
         │     └── Track order (public, no login needed)
         │
         └── Profile tab
               ├── Account info (name, email, phone)
               ├── Address book (add/edit/delete)
               ├── Wishlist
               ├── Settings
               └── Sign out
```

## 3. Registration Flow

```
Tap "Create account" (from login or checkout prompt)
  │
  ▼
Registration Screen
├── Full name (required)
├── Email (required)
├── Phone (optional)
├── Password (required, min 8)
├── [OR] "Continue with Google" → Google Sign-In SDK
└── Tap "Create account"
       │
       ├── [Validation error] → Show field errors inline
       │
       ├── [Email exists] → "Email already registered. Sign in instead?"
       │
       └── [Success] → OTP Verification Screen (if applicable)
              │
              ├── Enter 6-digit code from email
              ├── "Resend code" option
              └── [Verified] → Redirect to Store Home (or checkout if ?next)
```

## 4. Login / Logout Flow

```
── LOGIN ──

Login Screen
├── Email field
├── Password field (show/hide toggle)
├── "Forgot password?" link
├── [OR] "Continue with Google"
└── Tap "Sign in"
       │
       ├── [Invalid credentials] → Error: "Incorrect email or password"
       ├── [Account locked] → Error + "Try again later"
       └── [Success] → Store token → Navigate to Home (or ?next URL)

── LOGOUT ──

Profile screen → Tap "Sign out"
  │
  ▼
Confirmation dialog: "Sign out of your account?"
  │
  ├── [Cancel] → Stay
  └── [Confirm] → POST /logout → Clear token → Login screen
```

## 5. Password Reset Flow

```
Tap "Forgot password?" (from Login)
  │
  ▼
Forgot Password Screen
├── Email field
└── Tap "Send reset link"
       │
       ├── [Email not found] → NEEDS BACKEND CONFIRMATION: error or silent success?
       └── [Sent] → "Check your email for a reset link"
              │
              ▼
       User opens email → Taps link → Opens in app (deep link) or browser
              │
              ▼
       Reset Password Screen (NEEDS BACKEND CONFIRMATION)
       ├── New password
       ├── Confirm password
       └── Tap "Reset password"
              │
              └── [Success] → "Password updated. Sign in."
```

## 6. Wishlist Flow

```
── ADD TO WISHLIST ──

Product Detail → Tap heart icon (not filled)
  │
  ├── [Not logged in] → Prompt: "Sign in to save to wishlist"
  │     └── Login → Return → Item added
  │
  └── [Logged in] → POST /api/marketplace/wishlist/toggle
        ├── [Success] → Heart fills, toast: "Saved to wishlist"
        └── [Error] → Toast: "Could not save. Try again."

── VIEW WISHLIST ──

Profile → Wishlist (or direct nav link)
  │
  ▼
Wishlist Screen
├── Grid of saved products (image, name, price)
├── Tap product → Product Detail
├── Tap remove → Confirm → Remove from list
└── [Empty] → "Your wishlist is empty" + "Browse products" CTA

── REMOVE FROM WISHLIST ──

Swipe item or tap remove icon
  │
  └── POST /api/marketplace/wishlist/toggle → Item removed → Update grid
```

## 7. Cart Management Flow

```
── ADD ITEM ──

From Product Detail or Product Card "Add to cart" button
  │
  ├── [In stock] → Item added, quantity = 1 (or selected qty)
  │     ├── Badge count updates
  │     └── Toast: "Added to cart" with product name
  │
  └── [Out of stock] → Button disabled: "Unavailable"

── UPDATE QUANTITY ──

Cart Screen → Stepper (+/-)
  │
  ├── Min = 1
  ├── Max = available stock (99 cap)
  └── Totals recalculate immediately

── REMOVE ITEM ──

Cart Screen → Swipe left or tap remove button
  │
  └── Item removed → Totals recalculate
        └── [Last item removed] → Empty cart state

── CART PERSISTENCE ──

Mobile (recommended): Server-side cart synced via API
  │
  ├── Login → Cart merges with any server-side items
  ├── Logout → Cart preserved locally, synced on next login
  └── Cross-device → Same cart on any device (signed-in users)
```

## 8. Checkout Flow (Detailed)

```
Cart → Tap "Proceed to checkout"
  │
  ├── [Cart empty] → Redirect to cart with empty state
  │
  ├── [Not signed in] → Show info banner:
  │     "Sign in to save address and track in purchase history"
  │     (checkout still proceeds without login)
  │
  ▼
STEP 1: Delivery Details
├── [Signed in + has saved address] → Pre-select default address
│     └── "Change" link → Address picker bottom sheet
├── [No saved address] → Fill form manually
│     ├── Full name (required, min 3 chars)
│     ├── Mobile number (required, Pakistani format, min 10 digits)
│     ├── Street address (required, min 8 chars)
│     ├── City (required, min 2 chars)
│     └── Delivery note (optional)
└── Tap "Continue" → Validate → Next step

STEP 2: Email Verification
├── [Already verified this session] → Auto-skip, show "Verified" badge
├── [Not verified] →
│     ├── Enter email → Tap "Send code"
│     │     └── POST /store/checkout/send-code
│     ├── 6-digit OTP arrives via email
│     ├── Enter OTP → Tap "Verify"
│     │     └── POST /store/checkout/verify-code
│     ├── [Correct] → "Verified" badge, proceed enabled
│     ├── [Incorrect] → Error: "That code is not correct"
│     └── "Resend" option available
└── Proceed enabled only after verification

STEP 3: Review & Place Order
├── Order summary (items, quantities, prices)
├── Coupon field → Type code → "Apply"
│     └── POST /api/store/validate-coupon
│           ├── [Valid] → Show discount, update total
│           └── [Invalid] → Error message under field
├── Delivery fee: Rs 199 (or FREE if subtotal >= 1,500)
├── Total due (bold, prominent)
├── Payment method: "Cash on delivery" (info card, not selectable)
└── Tap "Place order"
       │
       ├── POST /store/checkout (JSON payload)
       │
       ├── [Success] → Clear cart → Order Confirmation
       │
       ├── [Item out of stock] → Error: "Check item availability"
       │     └── Return to cart to remove unavailable items
       │
       ├── [Coupon invalid at final validation] → Error + remove coupon
       │
       └── [Network error] → Error: "Network problem. Try again."
             └── Button re-enables, user can retry
```

## 9. Address Management Flow

```
── VIEW ADDRESSES ──

Profile → Address Book
  │
  ▼
Address List Screen
├── List of saved addresses (with default indicator)
├── Tap address → Edit screen
├── Tap "Add new address" → Add screen
└── [Empty] → "No saved addresses" + "Add address" CTA

── ADD ADDRESS ──

Tap "Add new address"
  │
  ▼
Address Form
├── Label (e.g., "Home", "Office") — optional
├── Full name
├── Phone
├── Street address
├── City
├── Set as default (toggle)
└── Tap "Save"
       │
       ├── [Validation error] → Inline errors
       └── [Success] → Back to list, new address shown

── EDIT ADDRESS ──

Tap existing address → Pre-filled form → Edit → Save

── DELETE ADDRESS ──

Swipe or tap delete icon → Confirm dialog → Delete

── SELECT AT CHECKOUT ──

Checkout → "Change address" → Bottom sheet with saved addresses
  │
  └── Tap address → Auto-fills checkout form
```

## 10. Order Cancellation Flow

**Status: NEEDS BACKEND CONFIRMATION**

```
Order Detail (status = "pending")
  │
  ├── Tap "Cancel order" button (if available)
  │
  ▼
Confirmation bottom sheet:
  "Are you sure you want to cancel this order?"
  │
  ├── [Cancel] → Dismiss
  └── [Confirm] → POST cancel endpoint
        │
        ├── [Success] → Status updates to "Cancelled"
        │     └── Toast: "Order cancelled"
        │
        └── [Too late] → Error: "Order already being processed"
              └── Suggest: "Contact seller for help"
```

## 11. Out-of-Stock Handling

```
── ON PRODUCT CARD (Store grid) ──
  ├── "Unavailable" button (disabled, greyed)
  ├── Red badge: "Out of stock"
  └── Card still tappable for detail view

── ON PRODUCT DETAIL ──
  ├── Stock status: "Out of stock" (red label)
  ├── "Add to cart" disabled
  ├── "Buy now" disabled
  ├── Quantity selector disabled
  └── Sticky bottom bar: "Unavailable"

── AT CHECKOUT (race condition) ──
  ├── Server validates stock on placeOrder
  ├── [Item unavailable] → Error returned
  └── User must return to cart, remove item, try again

── LOW STOCK ──
  ├── Badge: "Only X left" (stock <= 5)
  ├── Quantity max limited to available stock
  └── Creates urgency signal for buyer
```

## 12. Network Failure Handling

```
── API CALL FAILS ──

Any screen making a network request:
  │
  ├── [Timeout / no connection] →
  │     ├── Show error state with retry button
  │     ├── "No internet connection. Check your connection and try again."
  │     └── Tap "Retry" → Re-attempt request
  │
  ├── [Server error 5xx] →
  │     ├── "Something went wrong. Please try again."
  │     └── Retry button
  │
  └── [Client error 4xx] →
        ├── Show specific message from API response
        └── Guide user to fix (e.g., "Item no longer available")

── LOADING STATES ──

All data-fetching screens:
  ├── Initial load → Skeleton shimmer (product cards, text lines)
  ├── Pull-to-refresh → Refresh indicator at top
  ├── Load more → Loading indicator at bottom of list
  └── Button actions → Button shows spinner, disabled during request

── OFFLINE MODE (Phase 2) ──

No connection detected:
  ├── Show cached products if available
  ├── Banner: "You're offline. Some features may not work."
  ├── Cart accessible (local data)
  ├── Checkout blocked → "Connect to the internet to place your order"
  └── Reconnect → Auto-retry pending operations
```

## 13. Session Expiration Handling

```
API returns 401 Unauthorized
  │
  ▼
Intercept in HTTP client layer
  │
  ├── [Has refresh token] → Attempt token refresh
  │     ├── [Refresh success] → Retry original request transparently
  │     └── [Refresh failed] → Force logout
  │
  └── [No refresh / expired] → Force logout
        │
        ▼
  Clear local auth state
  Navigate to Login screen
  Show message: "Your session has expired. Please sign in again."
  │
  ├── [Was in checkout] → Save cart state, resume after login
  └── [Was browsing] → After login, return to previous screen
```

## 14. Empty States

| Screen | Empty State | CTA |
|--------|-------------|-----|
| Store Home (no products) | "No products available yet. Check back soon." | Pull to refresh |
| Search results (no match) | "No products match your search." | "Clear filters" or "Try a different search" |
| Category (empty) | "No products in this category yet." | "Browse all products" |
| Cart | Shopping bag illustration + "Your cart is empty" | "Browse the marketplace" |
| Wishlist | Heart illustration + "Your wishlist is empty" | "Browse products" |
| Orders | Box illustration + "No orders yet" | "Start shopping" |
| Addresses | Pin illustration + "No saved addresses" | "Add an address" |
| Returns | "No return requests" | N/A |
| Notifications | Bell illustration + "No notifications yet" | N/A |

## 15. Error States

| Scenario | Message | Action |
|----------|---------|--------|
| Network timeout | "Connection timed out" | Retry button |
| No internet | "No internet connection" | Retry button + check connection hint |
| Server error (500) | "Something went wrong on our end" | Retry button |
| Product not found (404) | "This product is no longer available" | "Browse marketplace" button |
| Invalid credentials | "Incorrect email or password" | Clear password field, refocus |
| Email already registered | "This email is already registered" | "Sign in instead" link |
| Checkout stock error | "One or more items are no longer available" | "Return to cart" button |
| OTP expired | "Code expired. Send a new one." | "Resend code" button |
| OTP incorrect | "That code is not correct" | Clear OTP field, refocus |
| Coupon invalid | "That coupon is not valid" | Clear coupon field |
| Order not found (tracking) | "No order found with this invoice number" | Check input hint |
| Permission denied | "Please sign in to continue" | "Sign in" button |
