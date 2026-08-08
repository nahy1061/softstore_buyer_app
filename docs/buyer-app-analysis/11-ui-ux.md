# Phase 2: Mobile UX Recommendations

## 1. What to Retain from the Website

These patterns work well and should be preserved in the mobile app:

| Pattern | Why It Works | Mobile Adaptation |
|---------|-------------|-------------------|
| **Orange/amber brand palette** (#FF6F00 primary, #FFB300 accent) | Strong brand identity, high contrast CTAs | Keep exact hex values; ensure WCAG AA on mobile |
| **All-inclusive pricing** (tax baked in) | No surprise at checkout; builds trust | Display same way — no hidden fees |
| **3-step checkout** (Delivery → Verify → Confirm) | Clear progress, reduces cognitive load | Map to stepper at top of checkout screens |
| **Guest checkout with email OTP** | Low friction — no forced registration | Keep; add "sign in for faster checkout" prompt |
| **Free delivery threshold** (Rs 1,500) | Encourages larger baskets | Add progress indicator showing how close user is |
| **Public order tracking** (invoice + phone) | No login needed for tracking | Dedicated "Track Order" entry point in app |
| **Cash on Delivery only** | Matches Pakistani market expectations | Display as info card, not a selector |
| **Full name field** (not first/last split) | Matches local naming conventions | Single name field throughout |
| **Product variant chips** | Visual, easy to scan | Same chip-style selection |
| **Status pipeline visualization** | Clear order progress | Adapt as vertical stepper on mobile |
| **Seller info on product detail** | Transparency about multi-seller marketplace | Keep seller card with "Visit store" action |
| **Review stars + breakdown bars** | Social proof at a glance | Same layout, adapted to mobile width |

---

## 2. What to Change for Mobile

### 2.1 Navigation

| Website Pattern | Problem on Mobile | Mobile Recommendation |
|----------------|-------------------|----------------------|
| Top nav bar with links | Too many items, hamburger menus fail | **Bottom navigation** (5 tabs: Home, Categories, Cart, Orders, Profile) |
| Category sidebar (left) | Takes horizontal space on small screens | **Horizontal scrolling chips** above the product grid |
| Cart in header dropdown | Too small for touch, no visual weight | **Dedicated cart tab** in bottom nav with badge count |
| Login/register in header | Easy to miss | **Profile tab** with auth state check; sign-in prompt when needed |
| Breadcrumbs | Not a mobile pattern | **Back arrow** + screen title in app bar |

### 2.2 Product Browsing

| Website Pattern | Problem on Mobile | Mobile Recommendation |
|----------------|-------------------|----------------------|
| Multi-column product grid | Cards too small at 3+ columns | **2-column grid** (default), option for list view |
| Hover-to-zoom on images | No hover on touch devices | **Pinch-to-zoom** + full-screen gallery on tap |
| Pagination (page 1, 2, 3...) | Interrupts flow, extra taps | **Infinite scroll** with "load more" at bottom |
| Sidebar filters | Overlays content awkwardly | **Bottom sheet** for filter/sort (swipe up to reveal) |
| Sort dropdown in header | Small touch target | **Bottom sheet picker** triggered by sort button |

### 2.3 Product Detail

| Website Pattern | Problem on Mobile | Mobile Recommendation |
|----------------|-------------------|----------------------|
| Thumbnail gallery (hover) | Thumbnails too small for fingers | **Swipeable full-width gallery** with dot indicator |
| Tabbed content (Description/Specs/Reviews) | Tabs work but can be hidden below fold | **Stacked expandable sections** — all visible, tap to expand |
| Add to Cart + Buy Now side by side | Both critical, need prominence | **Sticky bottom bar** with both buttons always visible |
| Related products row (6 items) | Wraps awkwardly at small widths | **Horizontal scroll carousel** (peek next card) |
| WhatsApp link | Text link is easy to miss | **FAB or icon button** with WhatsApp branding |
| Share (not on website) | New for mobile | **Share button in app bar** → native share sheet |

### 2.4 Cart & Checkout

| Website Pattern | Problem on Mobile | Mobile Recommendation |
|----------------|-------------------|----------------------|
| Cart page with large table | Table layout doesn't fit mobile | **Card-based item list** (image + details stacked) |
| localStorage cart | No cross-device sync | **Server-side cart** for signed-in users, local fallback for guests |
| Multi-step checkout on one page | Scroll-heavy, overwhelming | **One step per screen** with back navigation |
| Coupon text input | Keyboard covers screen | **Expandable coupon section** (collapsed by default) |
| Long address form | Tedious on mobile | **Saved address picker** first, manual entry second |
| OTP via email only | Must switch apps to check email | **Auto-read from notification** (if possible), or prominent paste hint |

### 2.5 Orders & Account

| Website Pattern | Problem on Mobile | Mobile Recommendation |
|----------------|-------------------|----------------------|
| Order table with columns | Too many columns for mobile width | **Order cards** (stacked layout: status badge, seller, date, amount) |
| Sidebar navigation in account | Desktop pattern | **Profile hub** with grid of action cards (or list) |
| Address management in separate page | Fine, but add new should be faster | **Inline "add address" at checkout** + full management in profile |

---

## 3. What to Improve (Mobile-Only Opportunities)

### 3.1 Performance & Loading

| Improvement | Details |
|-------------|---------|
| **Skeleton loading** | Show shimmer placeholders matching card/list layout during data fetch |
| **Image optimization** | Request smaller thumbnail sizes for grids; full-res only on detail |
| **Cached browsing** | Store last-viewed products locally; show stale-then-refresh |
| **Lazy-load images** | Load product images as they scroll into viewport |
| **Prefetch next page** | When user nears bottom of list, pre-load next batch |

### 3.2 Input & Interaction

| Improvement | Details |
|-------------|---------|
| **Haptic feedback** | Light vibration on add-to-cart, place order, wishlist toggle |
| **Swipe gestures** | Swipe-to-delete in cart, swipe left on address/wishlist items |
| **Pull-to-refresh** | On all data screens (store, orders, wishlist) |
| **Keyboard types** | `emailAddress` for email fields, `phone` for phone, `number` for OTP |
| **Auto-focus** | Focus first empty field on screen load (login → email, OTP → first box) |
| **Password visibility toggle** | Eye icon on all password fields |
| **Form validation** | Real-time inline validation as user types (not just on submit) |
| **Auto-advance OTP** | Cursor moves to next box automatically after each digit |

### 3.3 Mobile-Native Features

| Feature | Details | Priority |
|---------|---------|----------|
| **Push notifications** | Order status changes, delivery updates, promotions | Phase 2 |
| **Biometric auth** | Fingerprint/Face ID for returning users (after first login) | Phase 2 |
| **Deep linking** | Handle /product/{slug} URLs from shared links, marketing emails | MVP |
| **Native share** | Share product via WhatsApp, SMS, other apps | MVP |
| **Camera access** | Photo upload for return requests | Phase 2 |
| **Clipboard detection** | Detect copied OTP code, offer to paste | MVP |
| **App badge** | Show unread notification count on app icon | Phase 2 |

### 3.4 Trust & Confidence Signals

| Signal | Details |
|--------|---------|
| **Secure checkout indicator** | Lock icon + "Secure checkout" text at top of checkout |
| **Seller verification badge** | If seller is verified by Softstore |
| **FBA badge** | "Fulfilled by SoftStore" badge on eligible products |
| **Free delivery progress** | "Add Rs X more for free delivery" bar in cart |
| **Stock urgency** | "Only 3 left" badge when stock is low (≤5) |
| **Verified purchase** on reviews | Badge next to reviews from actual buyers |
| **Order guarantee** | "7-day easy returns" mention on product page |

---

## 4. Information Architecture Recommendations

### 4.1 Bottom Navigation Priority

```
[Home]   [Categories]   [Cart🔴]   [Orders]   [Profile]
  │           │             │          │           │
  │           │             │          │           ├── Dashboard
  │           │             │          │           ├── Wishlist
  │           │             │          │          ├── Addresses
  │           │             │          │           ├── Settings
  │           │             │          │           └── Sign Out
  │           │             │          │
  │           │             │          ├── Order History
  │           │             │          ├── Track Order (public)
  │           │             │          └── Returns
  │           │             │
  │           │             └── Cart Items → Checkout Flow
  │           │
  │           └── Category Grid → Category Products
  │
  └── Store Home (grid) + Search
```

### 4.2 Information Density

- **Product cards (grid):** Image (60% height), name (1 line ellipsis), price, seller name, "Add" button
- **Product cards (list view):** Horizontal: image left (80px), name + price + seller right
- **Order cards:** Status badge top-right, seller name, date, item count, total amount
- **Address cards:** Label bold, full address below, phone, default indicator

### 4.3 Screen Depth (Max Taps to Reach)

| Screen | Taps from Launch | Path |
|--------|-----------------|------|
| Store Home | 0 | Launch → Home |
| Product Detail | 1 | Home → Tap product |
| Cart | 1 | Bottom nav → Cart tab |
| Checkout | 2 | Cart → Proceed |
| Order Confirmation | 3 | Cart → Proceed → Place order |
| Order Detail | 2 | Orders tab → Tap order |
| Wishlist | 2 | Profile → Wishlist |
| Track Order | 2 | Orders → Track Order |
| Search Results | 1 | Tap search bar → type → submit |

---

## 5. Typography & Spacing Guidelines

| Element | Size | Weight | Notes |
|---------|------|--------|-------|
| Screen title | 20sp | Bold | In app bar |
| Section heading | 16sp | SemiBold | Within screen content |
| Product name (card) | 14sp | Medium | 1-2 lines max, ellipsis overflow |
| Product name (detail) | 18sp | Bold | Full text visible |
| Price (primary) | 18sp | Bold | Orange (#FF6F00) |
| Price (strikethrough) | 14sp | Regular | Grey, line-through |
| Body text | 14sp | Regular | Default content |
| Caption/label | 12sp | Medium | Grey (#5F6368), field labels |
| Button text | 14sp | SemiBold | All uppercase for primary CTAs |
| Badge/chip | 12sp | Bold | Pill-shaped containers |

**Spacing:** 16dp horizontal padding on all screens. 8dp between cards in grid. 12dp between list items. 24dp section separation.

**Touch targets:** Minimum 48x48dp for all tappable elements (Material Design guideline).

---

## 6. Color Palette (From Source Code)

| Role | Hex | Usage |
|------|-----|-------|
| Primary | #FF6F00 | CTAs, active states, links, app bar accent |
| Primary variant | #E65100 | Pressed state, status "pending" |
| Secondary | #FFB300 | Highlights, badges, free delivery indicator |
| Surface | #FFFFFF | Card backgrounds, bottom sheets |
| Background | #F8F9FA | Screen backgrounds |
| On-surface (text) | #202124 | Primary text |
| Secondary text | #5F6368 | Captions, labels, descriptions |
| Divider | #E5E7EB | Card borders, list separators |
| Error | #B71C1C | Error states, cancelled status |
| Success | #1B5E20 | Delivered status, success confirmations |
| Warning | #E65100 | Low stock, pending status |

**Design rule from source:** No blue allowed in the design system (orange/amber on Material greys).

---

## 7. Accessibility Requirements

| Requirement | Implementation |
|-------------|----------------|
| Color contrast | All text meets WCAG AA (4.5:1 for normal, 3:1 for large) |
| Touch targets | Minimum 48x48dp, 8dp spacing between targets |
| Screen reader | Semantic labels on all interactive elements |
| Font scaling | Support system font size (up to 2x) without layout breaks |
| RTL support | Not required (English + Urdu not RTL-dominant for this market) |
| Motion | Respect "reduce motion" system setting |
| Focus indicators | Visible focus ring for keyboard/switch navigation |
| Alt text | All product images have descriptive labels |
| Error messaging | Errors announced to screen reader, not just visual |

---

## 8. Pakistani Market UX Considerations

| Consideration | Impact on UX |
|---------------|-------------|
| **Urdu language** | Phase 2 consideration; RTL layout needed if Urdu UI added |
| **Slow/intermittent networks** | Aggressive caching, small image payloads, offline cart access |
| **Budget devices** | Keep animations minimal, avoid heavy assets, test on low-RAM phones |
| **WhatsApp dominance** | WhatsApp as primary share/support channel; deep links to seller |
| **COD expectation** | No payment form needed; clear "pay rider in cash" messaging |
| **Phone number formats** | Pakistani mobile: 03XX-XXXXXXX (11 digits); validate accordingly |
| **City names** | Free text (no country/state dropdowns for now — Pakistan only) |
| **PKR currency** | Always display as "Rs" or "PKR" with comma-separated thousands |
| **Trust deficit in e-commerce** | Show seller info prominently, emphasize returns policy, WhatsApp access |
| **Data costs** | Minimize unnecessary API calls; compress images; avoid autoplay video |
