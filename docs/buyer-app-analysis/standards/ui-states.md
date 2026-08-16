# UI States

## Purpose

This document defines consistent patterns for loading, error, and empty states across the app so all 4 developers produce the same user experience regardless of which feature they own.

---

## Loading States

### 1. Initial Screen Load (Skeleton)

**When:** Screen opens and data is being fetched for the first time.

**Pattern:** Show skeleton placeholders matching the content layout.

```dart
// In BlocBuilder
switch (state) {
  case FeatureInitial():
  case FeatureLoading():
    return LoadingSkeleton.productGrid(); // or appropriate skeleton variant
  case FeatureLoaded(:final data):
    return _buildContent(data);
  case FeatureError(:final message):
    return ErrorStateWidget(message: message, onRetry: cubit.load);
}
```

**Rules:**
- Skeleton shape must match the real content shape (cards → card skeletons, list → row skeletons)
- Skeleton uses shimmer animation (gradient sweep) from `AppColors.shimmerBase` to `AppColors.shimmerHighlight`
- Duration: shimmer loops until data arrives
- Never show a blank white screen while loading

**Pre-built skeletons:**
| Skeleton | Used On |
|----------|---------|
| `LoadingSkeleton.productGrid()` | Home, category, search results, seller store |
| `LoadingSkeleton.productList()` | Wishlist, related products |
| `LoadingSkeleton.orderCard()` | Order history |
| `LoadingSkeleton.productDetail()` | Product detail screen |
| `LoadingSkeleton.text(lines: N)` | Profile, address, any text content |

---

### 2. Pagination Loading (Load More)

**When:** User scrolls to bottom of list and next page is being fetched.

**Pattern:** Show a small loading indicator at the bottom of the list, below existing content.

```dart
// At bottom of list
if (state.isLoadingMore) {
  return Padding(
    padding: EdgeInsets.all(AppSpacing.lg),
    child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
  );
}
```

**Rules:**
- Existing content stays visible and scrollable
- Small circular indicator (24dp) centered below content
- Triggered automatically when user scrolls within 200px of bottom
- No full-screen overlay or blocking

---

### 3. Button Loading

**When:** User taps a CTA (login, place order, add to cart) and action is in progress.

**Pattern:** Button shows spinner, text hidden, button disabled.

```dart
AppButton(
  label: 'Place Order',
  onPressed: state is! CheckoutSubmitting ? cubit.placeOrder : null,
  isLoading: state is CheckoutSubmitting,
)
```

**Rules:**
- Spinner replaces button text (same button size maintained)
- Button becomes non-tappable during loading
- Color stays the same (no dimming)
- If action fails, button re-enables with original text

---

### 4. Image Loading

**When:** Network image is loading.

**Pattern:** Shimmer placeholder → image fades in.

```dart
AppImage(
  url: product.imageUrl,
  width: double.infinity,
  height: 200,
  borderRadius: AppDimensions.radiusMd,
)
```

**Rules:**
- Use `AppImage` widget (wraps `CachedNetworkImage`)
- Placeholder: shimmer box matching exact dimensions
- Error: broken image icon centered in the same space
- No layout shift when image loads (dimensions are known upfront)

---

### 5. Pull-to-Refresh

**When:** User pulls down on a scrollable data screen.

**Pattern:** Material `RefreshIndicator` with primary color.

```dart
RefreshIndicator(
  color: AppColors.primary,
  onRefresh: cubit.refresh,
  child: listContent,
)
```

**Rules:**
- Available on: Home, Orders, Wishlist, Notifications, Seller store
- NOT available on: Cart (local data), Checkout, static screens (FAQ, Terms)
- Refreshes full screen content (resets pagination)
- Skeleton NOT shown during refresh (existing content stays visible)

---

## Error States

### Error Classification → UI Response

| Error Type | User Sees | UI Component | Action |
|------------|-----------|-------------|--------|
| Network (no connection) | "No internet connection" | `ErrorStateWidget` with wifi-off icon | Retry button |
| Timeout | "Connection timed out" | `ErrorStateWidget` with timer icon | Retry button |
| Server (500) | "Something went wrong. Try again." | `ErrorStateWidget` with error icon | Retry button |
| Not Found (404) | "This item is no longer available" | `ErrorStateWidget` with not-found icon | Back button |
| Validation (400/422) | Field-level error messages | Inline below each field | Fix and resubmit |
| Auth (401) | "Session expired. Please sign in." | Auto-redirect to login | — |
| Rate Limited (429) | "Too many attempts. Wait Xs." | Inline message + disabled button | Auto re-enable after countdown |
| Unknown | "Something went wrong. Try again." | `ErrorStateWidget` | Retry button |

### Full-Screen Error (Initial Load Failed)

Used when the screen has NO cached data and the first load fails.

```dart
ErrorStateWidget(
  message: 'No internet connection',
  icon: Icons.wifi_off,
  onRetry: () => cubit.load(),
)
```

- Centered in available space
- Icon (48dp) + message + retry button
- Retry button uses `AppButton(variant: .secondary)`

### Inline Error (Action Failed)

Used when user has data visible but an action failed (e.g., toggle wishlist, apply coupon).

```dart
AppSnackbar.error(context, 'Could not update wishlist. Try again.');
```

- Snackbar at bottom
- Does NOT replace visible content
- Auto-dismisses after 3s

### Form Validation Error

Used when form fields have invalid input.

```dart
AppTextField(
  label: 'Email',
  controller: emailController,
  errorText: state.fieldErrors['email'],  // null = no error shown
)
```

- Error text appears below the field in red (12sp)
- Field border turns red
- Error clears when user starts typing again
- Multiple fields can show errors simultaneously

### Network Error with Cached Data

When a refresh fails but cached data is available:

```dart
// Show cached data + info snackbar
AppSnackbar.info(context, 'Showing cached data. Pull to refresh.');
```

- Cached content stays visible
- Brief snackbar informs user
- No blocking error screen

---

## Empty States

### Pattern

Every empty state uses `EmptyStateWidget` with:
1. A relevant icon (large, centered, muted color)
2. A title (what's empty)
3. A subtitle (why or what to do)
4. An optional CTA button (primary action)

### Per-Screen Empty States

| Screen | Icon | Title | Subtitle | CTA |
|--------|------|-------|----------|-----|
| Cart | `Icons.shopping_cart_outlined` | "Your cart is empty" | "Browse products and add items to your cart" | "Start Shopping" → Home |
| Wishlist | `Icons.favorite_border` | "Your wishlist is empty" | "Save products you love for later" | "Browse Products" → Home |
| Search (no results) | `Icons.search_off` | "No results found" | "Try different keywords or check spelling" | — (search bar is still active) |
| Orders | `Icons.receipt_long_outlined` | "No orders yet" | "Your order history will appear here" | "Start Shopping" → Home |
| Notifications | `Icons.notifications_none` | "No notifications" | "You'll receive updates about your orders here" | — |
| Addresses | `Icons.location_off_outlined` | "No saved addresses" | "Add an address for faster checkout" | "Add Address" → Address form |
| Returns | `Icons.assignment_return_outlined` | "No returns" | "Your return requests will appear here" | — |
| Support tickets | `Icons.support_agent_outlined` | "No tickets" | "Need help? Create a support ticket" | "New Ticket" → New ticket form |
| Seller products (0) | `Icons.storefront_outlined` | "No products yet" | "This seller hasn't listed any products" | — |

### Rules

1. Empty state should NEVER look like a broken screen. It's intentional content.
2. Always provide a CTA if there's an obvious next action.
3. Icon color: `AppColors.textSecondary` at 0.5 opacity, size 64dp.
4. Title: `AppTypography.sectionHeading`, centered.
5. Subtitle: `AppTypography.bodyMedium`, `AppColors.textSecondary`, centered.
6. If a screen can be both empty AND loading, loading takes priority (show skeleton, not empty state).

---

## State Priority Order

When multiple states are possible, render in this priority:

```
1. Loading (initial)     → Show skeleton
2. Error (initial load)  → Show full-screen error
3. Empty (no data)       → Show empty state
4. Loaded (has data)     → Show content
5. Loading (pagination)  → Show content + bottom spinner
6. Error (refresh)       → Show content + error snackbar
```

---

## Implementation Pattern in Cubits

```dart
// Standard state class pattern
sealed class FeatureState {}
class FeatureInitial extends FeatureState {}
class FeatureLoading extends FeatureState {}
class FeatureLoaded extends FeatureState with EquatableMixin {
  final List<ItemModel> items;
  final bool isLoadingMore;
  final int currentPage;
  final int totalPages;

  bool get isEmpty => items.isEmpty;
  bool get hasMore => currentPage < totalPages;

  @override
  List<Object?> get props => [items, isLoadingMore, currentPage, totalPages];
}
class FeatureError extends FeatureState {
  final String message;
  FeatureError(this.message);
}
```

```dart
// Standard UI pattern
BlocBuilder<FeatureCubit, FeatureState>(
  builder: (context, state) => switch (state) {
    FeatureInitial() || FeatureLoading() => LoadingSkeleton.appropriate(),
    FeatureError(:final message) => ErrorStateWidget(
      message: message,
      onRetry: context.read<FeatureCubit>().load,
    ),
    FeatureLoaded(:final items, :final isEmpty) when isEmpty =>
      EmptyStateWidget(icon: Icons.x, title: 'Empty', subtitle: '...'),
    FeatureLoaded() => _buildList(state),
  },
)
```

---

## Loading Overlay (Blocking Operations)

For operations where the user must wait and should NOT interact with the screen (placing order, submitting return):

```dart
// Do NOT use a full-screen overlay.
// Instead: disable the submit button and show button loading.
// This prevents accidental double-submission while keeping UI responsive.
```

**We do NOT use:** Full-screen semi-transparent loading overlays. They feel slow and janky. The button loading pattern is sufficient.

**Exception:** Age-restricted product confirmation modal blocks interaction intentionally (not a loading state).
