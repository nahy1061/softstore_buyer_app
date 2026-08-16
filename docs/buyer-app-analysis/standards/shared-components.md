# Shared UI Components

## Location

All shared components live in:
```
lib/core/widgets/
```

A widget goes here ONLY if it's used by 3+ features. Feature-specific widgets stay in their own `features/{name}/presentation/widgets/` folder.

---

## Component Catalog

### 1. AppButton

**Purpose:** Primary, secondary, and text buttons with loading state.

**Where it lives:** `core/widgets/app_button.dart`

**Used by:** Auth, Checkout, Cart, Profile, Orders, Support — every feature with a CTA.

**Configuration:**
| Prop | Type | Default | Notes |
|------|------|---------|-------|
| `label` | `String` | required | Button text |
| `onPressed` | `VoidCallback?` | required | `null` = disabled state |
| `variant` | `AppButtonVariant` | `.primary` | `.primary`, `.secondary`, `.text` |
| `isLoading` | `bool` | `false` | Shows spinner, disables tap |
| `isFullWidth` | `bool` | `true` | Stretches to fill width |
| `icon` | `IconData?` | `null` | Leading icon |

**Responsibilities:**
- Render correct theme variant (filled orange, outlined, text-only)
- Show loading spinner when `isLoading = true` (disables tap automatically)
- Apply disabled styling when `onPressed` is null
- Enforce minimum 48dp touch target

**What stays feature-specific:** Button text content, onPressed callbacks, when to show loading.

---

### 2. AppTextField

**Purpose:** Styled text input with label, hint, error, prefix/suffix support.

**Where it lives:** `core/widgets/app_text_field.dart`

**Used by:** Auth (login, register, forgot password), Checkout (delivery form), Profile (edit), Support (new ticket), Search.

**Configuration:**
| Prop | Type | Default | Notes |
|------|------|---------|-------|
| `label` | `String?` | `null` | Floating label |
| `hint` | `String?` | `null` | Placeholder text |
| `errorText` | `String?` | `null` | Shows error below field |
| `controller` | `TextEditingController?` | `null` | External control |
| `keyboardType` | `TextInputType` | `.text` | email, phone, number |
| `obscureText` | `bool` | `false` | Password field |
| `prefixIcon` | `IconData?` | `null` | Leading icon |
| `suffixIcon` | `Widget?` | `null` | Trailing widget (toggle eye) |
| `maxLines` | `int` | `1` | Multi-line for descriptions |
| `onChanged` | `ValueChanged<String>?` | `null` | Real-time callback |
| `validator` | `FormFieldValidator<String>?` | `null` | For Form integration |
| `textInputAction` | `TextInputAction` | `.next` | Keyboard action |

**Responsibilities:**
- Apply `InputDecorationTheme` from app theme
- Handle obscure text toggle (password fields)
- Show error state from validation
- Set correct keyboard type

**What stays feature-specific:** Validation logic, controllers, specific keyboard actions.

---

### 3. ProductCard

**Purpose:** Product display in grids and lists across multiple features.

**Where it lives:** `core/widgets/product_card.dart`

**Used by:** Home (grid), Search (results), Categories, Seller store, Wishlist, Related products.

**Configuration:**
| Prop | Type | Default | Notes |
|------|------|---------|-------|
| `product` | `ProductModel` | required | Product data |
| `onTap` | `VoidCallback` | required | Navigate to detail |
| `variant` | `ProductCardVariant` | `.grid` | `.grid` or `.list` |
| `showAddButton` | `bool` | `true` | Quick "Add" button |
| `onAddToCart` | `VoidCallback?` | `null` | Add to cart action |
| `trailing` | `Widget?` | `null` | Custom trailing (e.g., remove from wishlist) |

**Responsibilities:**
- Render product image with `AppImage` (cached, placeholder, error)
- Display name (ellipsis), price (with strikethrough if discount), seller name
- Show badges: discount %, "FREE DELIVERY", "LOW STOCK", "NEW", "FBA"
- Grid mode: vertical card. List mode: horizontal row.

**What stays feature-specific:** Navigation destination, add-to-cart logic, wishlist toggle logic.

---

### 4. PriceDisplay

**Purpose:** Consistent price rendering with sale/list price and discount badge.

**Where it lives:** `core/widgets/price_display.dart`

**Used by:** ProductCard, Product detail, Cart, Checkout review, Order items.

**Configuration:**
| Prop | Type | Default | Notes |
|------|------|---------|-------|
| `price` | `double` | required | Current sale price |
| `listPrice` | `double?` | `null` | Original price (strikethrough) |
| `discountPercent` | `int?` | `null` | Shows "-X%" badge |
| `size` | `PriceSize` | `.medium` | `.small`, `.medium`, `.large` |

**Responsibilities:**
- Format price as "Rs {amount}" with Pakistani formatting (no decimals for whole numbers)
- Show list price with strikethrough decoration
- Show discount badge pill
- Use Roboto Mono for number alignment

---

### 5. RatingDisplay

**Purpose:** Star rating with optional count.

**Where it lives:** `core/widgets/rating_display.dart`

**Used by:** Product card, Product detail, Seller store, Reviews section.

**Configuration:**
| Prop | Type | Default | Notes |
|------|------|---------|-------|
| `rating` | `double` | required | 0.0–5.0 |
| `reviewCount` | `int?` | `null` | Shows "(X reviews)" next to stars |
| `size` | `double` | `16` | Star icon size |

---

### 6. QuantitySelector

**Purpose:** Increment/decrement stepper for quantity.

**Where it lives:** `core/widgets/quantity_selector.dart`

**Used by:** Product detail (before add to cart), Cart (per item).

**Configuration:**
| Prop | Type | Default | Notes |
|------|------|---------|-------|
| `value` | `int` | required | Current quantity |
| `min` | `int` | `1` | Minimum value |
| `max` | `int` | required | Stock limit |
| `onChanged` | `ValueChanged<int>` | required | New value callback |

---

### 7. AppImage

**Purpose:** Cached network image with shimmer placeholder and error fallback.

**Where it lives:** `core/widgets/app_image.dart`

**Used by:** Every feature that displays images (products, seller logos, gallery).

**Configuration:**
| Prop | Type | Default | Notes |
|------|------|---------|-------|
| `url` | `String` | required | Image URL |
| `width` | `double?` | `null` | Constrained width |
| `height` | `double?` | `null` | Constrained height |
| `fit` | `BoxFit` | `.cover` | Image fit |
| `borderRadius` | `BorderRadius?` | `null` | Clip corners |

**Responsibilities:**
- Use `CachedNetworkImage` internally
- Show shimmer placeholder while loading
- Show broken image icon on error
- Apply border radius clipping

---

### 8. LoadingSkeleton

**Purpose:** Shimmer placeholder matching content layout.

**Where it lives:** `core/widgets/loading_skeleton.dart`

**Used by:** Home, Search, Orders, Product detail, Wishlist — any screen with data loading.

**Configuration:**
| Prop | Type | Default | Notes |
|------|------|---------|-------|
| `width` | `double?` | `double.infinity` | Skeleton width |
| `height` | `double` | required | Skeleton height |
| `borderRadius` | `BorderRadius` | `AppDimensions.radiusSm` | Shape |

Also provide composed skeletons:
- `LoadingSkeleton.productGrid()` — 2×3 grid of card skeletons
- `LoadingSkeleton.productList()` — 4 horizontal row skeletons
- `LoadingSkeleton.orderCard()` — Single order card skeleton
- `LoadingSkeleton.text({lines: 3})` — Paragraph skeleton

---

### 9. ErrorStateWidget

**Purpose:** Full-screen or inline error with message and retry button.

**Where it lives:** `core/widgets/error_state_widget.dart`

**Used by:** Every feature that loads data from API.

**Configuration:**
| Prop | Type | Default | Notes |
|------|------|---------|-------|
| `message` | `String` | required | User-facing error message |
| `onRetry` | `VoidCallback?` | `null` | Retry button (hidden if null) |
| `icon` | `IconData` | `Icons.error_outline` | Leading icon |
| `fullScreen` | `bool` | `true` | Center in available space vs inline |

---

### 10. EmptyStateWidget

**Purpose:** Illustration + message when content is empty.

**Where it lives:** `core/widgets/empty_state_widget.dart`

**Used by:** Cart (empty), Wishlist (empty), Orders (no orders), Search (no results), Notifications (none), Addresses (none).

**Configuration:**
| Prop | Type | Default | Notes |
|------|------|---------|-------|
| `icon` | `IconData` | required | Large centered icon |
| `title` | `String` | required | Primary message |
| `subtitle` | `String?` | `null` | Secondary explanation |
| `actionLabel` | `String?` | `null` | CTA button text |
| `onAction` | `VoidCallback?` | `null` | CTA callback |

---

### 11. StatusBadge

**Purpose:** Colored pill badge for order/return status.

**Where it lives:** `core/widgets/status_badge.dart`

**Used by:** Orders (list + detail), Returns, Order confirmation.

**Configuration:**
| Prop | Type | Default | Notes |
|------|------|---------|-------|
| `status` | `OrderStatus` or `ReturnStatus` | required | Determines color + text |

**Responsibilities:**
- Map status enum to color from `AppColors.status*`
- Render pill-shaped container with bold white text

---

### 12. OtpInput

**Purpose:** 6-digit OTP input with auto-advance.

**Where it lives:** `core/widgets/otp_input.dart`

**Used by:** Register (email verification), Checkout (email OTP).

**Configuration:**
| Prop | Type | Default | Notes |
|------|------|---------|-------|
| `length` | `int` | `6` | Number of digits |
| `onCompleted` | `ValueChanged<String>` | required | Fires when all digits entered |
| `errorText` | `String?` | `null` | Shows error below |

**Responsibilities:**
- 6 separate box inputs in a row
- Auto-advance cursor on digit entry
- Backspace moves to previous box
- Paste support (auto-fill all boxes from clipboard)

---

### 13. ConfirmationDialog

**Purpose:** Standard confirm/cancel dialog for destructive actions.

**Where it lives:** `core/widgets/confirmation_dialog.dart`

**Used by:** Cart (remove item), Orders (cancel order), Profile (logout), Addresses (delete).

**Configuration:**
| Prop | Type | Default | Notes |
|------|------|---------|-------|
| `title` | `String` | required | Dialog heading |
| `message` | `String` | required | Explanation text |
| `confirmLabel` | `String` | `'Confirm'` | Primary action text |
| `cancelLabel` | `String` | `'Cancel'` | Secondary action text |
| `isDestructive` | `bool` | `false` | Makes confirm button red |
| `onConfirm` | `VoidCallback` | required | Confirm callback |

---

### 14. AppSnackbar

**Purpose:** Helper to show styled snackbars consistently.

**Where it lives:** `core/widgets/app_snackbar.dart`

**Used by:** Everywhere (cart add, wishlist toggle, errors, success messages).

**Usage pattern (static methods, not a widget):**
```dart
AppSnackbar.success(context, 'Added to cart');
AppSnackbar.error(context, 'Failed to place order');
AppSnackbar.info(context, 'Coupon applied: Rs 200 off');
```

**Configuration:**
| Method | Icon | Background |
|--------|------|-----------|
| `.success()` | checkmark | dark with green accent |
| `.error()` | error | dark with red accent |
| `.info()` | info | dark (default) |

---

### 15. SearchBar (AppSearchBar)

**Purpose:** Styled search input with clear button and suggestions trigger.

**Where it lives:** `core/widgets/app_search_bar.dart`

**Used by:** Home (tap to navigate to search), Search screen (active input).

**Configuration:**
| Prop | Type | Default | Notes |
|------|------|---------|-------|
| `onTap` | `VoidCallback?` | `null` | For non-editable (home screen) |
| `onChanged` | `ValueChanged<String>?` | `null` | For active search |
| `onSubmitted` | `ValueChanged<String>?` | `null` | Submit search |
| `controller` | `TextEditingController?` | `null` | External control |
| `readOnly` | `bool` | `false` | Tap-only mode (home) |

---

## What Should NOT Be a Shared Component

| Widget | Why Not Shared |
|--------|---------------|
| Seller info card (product detail) | Only used on product detail screen |
| Checkout step indicator | Only used in checkout flow |
| Order timeline | Only used on order detail |
| Review card | Only used on product detail reviews section |
| Address form | Only used in profile/checkout — complex form logic is feature-specific |
| Cart item tile | Only used on cart screen (swipe-to-delete, qty stepper specific to cart) |
| Filter/sort bottom sheet | Only used in product browsing — filter options are screen-specific |
| Return request form | Only used on order detail |

**Rule of thumb:** If extracting a widget requires passing 5+ callbacks or feature-specific data models, it's not truly "shared" — it's feature-specific with a generic appearance.
