# Development Task Breakdown

Tasks are organized by feature area. Each task is specific enough to be a Trello card / GitHub Issue.

Format: `[Owner] Task Name` — Description — Dependencies — Definition of Done

---

## Foundation

| # | Task | Owner | Dependencies | Definition of Done |
|---|------|-------|-------------|-------------------|
| F1 | Create Flutter project + folder structure | Naheed | None | `flutter run` launches default app with all feature folders created |
| F2 | Configure `pubspec.yaml` with all dependencies | Naheed | F1 | All packages from `dependencies.md` added, `flutter pub get` succeeds |
| F3 | Create `app_colors.dart` | Naheed | F1 | All colors from design system defined as static const |
| F4 | Create `app_typography.dart` | Naheed | F1 | All text styles defined, fonts configured in pubspec |
| F5 | Create `app_spacing.dart` | Naheed | F1 | All spacing constants defined |
| F6 | Create `app_dimensions.dart` | Naheed | F1 | Border radius, elevation, sizes defined |
| F7 | Create `app_durations.dart` | Naheed | F1 | All animation duration constants |
| F8 | Create `app_theme.dart` (light ThemeData) | Naheed | F3-F6 | MaterialApp uses theme, all component themes configured |
| F9 | Create `app.dart` with MultiBlocProvider | Naheed | F8 | App launches with global providers (Auth, Cart, Connectivity) |
| F10 | Create `router.dart` with all routes (placeholder screens) | Naheed | F9 | All routes navigable, bottom nav works, auth guards redirect |
| F11 | Create `api_endpoints.dart` | Naheed | F1 | All endpoint paths as static strings |
| F12 | Create `app_config.dart` | Naheed | F1 | Delivery fee, free threshold, OTP length, etc. |
| F13 | Create `storage_keys.dart` | Naheed | F1 | All SharedPreferences and SecureStorage key names |
| F14 | Create `env_config.dart` + `feature_flags.dart` | Naheed | F1 | Environment reads from `--dart-define` |
| F15 | Create `.gitignore` + `analysis_options.yaml` | Naheed | F1 | Secrets excluded, lint rules configured |
| F16 | Create `api_client.dart` (Dio + BaseOptions) | Arwah | F1, F11 | Dio configured with base URL, timeouts, JSON headers |
| F17 | Create `auth_interceptor.dart` | Arwah | F16 | 401 detection triggers session expired |
| F18 | Create `retry_interceptor.dart` | Arwah | F16 | Retries timeout/5xx 2x with backoff |
| F19 | Create cookie jar setup (PersistCookieJar) | Arwah | F16 | Cookies persist to disk, attached to all requests |
| F20 | Create `failures.dart` (all Failure types) | Arwah | F1 | NetworkFailure, TimeoutFailure, ServerFailure, ValidationFailure, AuthFailure, RateLimitFailure, NotFoundFailure |
| F21 | Create `validators.dart` | Arwah | F1 | Email, phone (Pakistani), password (8+), name (3+), address, OTP validators |
| F22 | Create `formatters.dart` | Nimra | F1 | PKR currency formatting, Pakistani phone, date formatting |
| F23 | Create `secure_storage.dart` wrapper | Nimra | F1 | Read/write/delete methods for encrypted storage |
| F24 | Create `local_storage.dart` wrapper | Nimra | F1 | Read/write/delete for SharedPreferences |
| F25 | Create `connectivity_service.dart` | Arwah | F1 | Stream<bool> for online/offline state |

---

## Shared Widgets

| # | Task | Owner | Dependencies | Definition of Done |
|---|------|-------|-------------|-------------------|
| W1 | Create AppButton (primary, secondary, text, loading) | Naheed | F8 | Renders all variants, loading spinner works, disabled state |
| W2 | Create AppTextField (label, error, keyboard, obscure) | Naheed | F8 | All input types render, error shows below, focus works |
| W3 | Create LoadingSkeleton (+ composed variants) | Naheed | F3, F6 | Shimmer animates, .productGrid(), .orderCard(), .text() work |
| W4 | Create ErrorStateWidget | Naheed | F8, W1 | Shows icon + message + retry button, centers in space |
| W5 | Create EmptyStateWidget | Naheed | F8, W1 | Shows icon + title + subtitle + optional CTA |
| W6 | Create ConfirmationDialog | Naheed | F8, W1 | Title, message, confirm/cancel, destructive variant (red) |
| W7 | Create AppSnackbar (static .success/.error/.info) | Naheed | F8 | Shows styled snackbar, auto-dismisses |
| W8 | Create ProductCard (grid + list variants) | Nimra | F8, models | Renders image, name, price, badges, tap fires callback |
| W9 | Create PriceDisplay (sale, list, discount badge) | Nimra | F3, F4 | PKR formatted, strikethrough, -X% badge |
| W10 | Create RatingDisplay (stars + count) | Nimra | F3 | Renders 0-5 stars (half-star), optional review count |
| W11 | Create QuantitySelector (+/- with min/max) | Nimra | F8 | Increment/decrement, respects stock limit |
| W12 | Create AppImage (cached + shimmer + error) | Nimra | F3, W3 | CachedNetworkImage with placeholder and error widget |
| W13 | Create StatusBadge (order/return status) | Nimra | F3 | Colored pill, maps enum to color automatically |
| W14 | Create OtpInput (6-digit, auto-advance) | Nimra | F8 | 6 boxes, auto-advance, backspace, paste support |
| W15 | Create AppSearchBar (read-only + active modes) | Nimra | F8 | Tap mode for home, editable for search screen |

---

## Authentication

| # | Task | Owner | Dependencies | Definition of Done |
|---|------|-------|-------------|-------------------|
| A1 | Create UserModel + JSON serialization | Arwah | F1 | fromJson/toJson, all fields from `09-data-models.md` |
| A2 | Create AuthRepository | Arwah | F16, F19, F20 | login, register, googleAuth, logout, checkSession, verifyOtp, resendOtp, forgotPassword, resetPassword |
| A3 | Create AuthCubit + states | Arwah | A2 | States: Initial, Loading, Authenticated, Unauthenticated, Error. Methods: login, register, logout, checkSession |
| A4 | Build Login screen | Arwah | A3, W1, W2 | Email + password fields, validation, login button, Google button, forgot password link, loading state |
| A5 | Build Register screen | Arwah | A3, W1, W2 | Name, email, phone, password fields, validation, register button, Google button |
| A6 | Implement Google OAuth flow | Arwah | A3 | Native Google Sign-In → ID token → backend verify → session |
| A7 | Build OTP verification screen | Arwah | A3, W14 | 6-digit input, resend button with countdown, verify button |
| A8 | Build Forgot password screen | Arwah | A3, W1, W2 | Email input, submit, success message |
| A9 | Integrate reCAPTCHA (invisible) | Arwah | A4, A5 | Token generated before login/register submit |
| A10 | Implement session keep-alive (app resume check) | Arwah | A3, F17 | After 30min background, ping /me. 401 → redirect |

---

## Home & Categories

| # | Task | Owner | Dependencies | Definition of Done |
|---|------|-------|-------------|-------------------|
| H1 | Create ProductModel + JSON serialization | Munaza | F1 | All fields from `09-data-models.md`, fromJson/toJson tested |
| H2 | Create CategoryModel + JSON serialization | Munaza | F1 | id, name, slug, productCount |
| H3 | Create PricingModel + JSON serialization | Munaza | F1 | displayPrice, displayList, hasDiscount, discountPercent, taxRate |
| H4 | Create HomeRepository | Munaza | F16 | getProducts(page, category, sort, filters), getCategories() |
| H5 | Create HomeCubit + states | Munaza | H4 | Load products, pagination, filter, sort, category filter |
| H6 | Build Home screen (product grid) | Munaza | H5, W8, W3 | 2-column grid, infinite scroll, pull-to-refresh, category chips |
| H7 | Implement pagination (load more on scroll) | Munaza | H6 | Next page loads at scroll bottom, spinner shows |
| H8 | Build filter/sort bottom sheet | Munaza | H6 | Price range, free delivery toggle, sort options |
| H9 | Build Categories screen (grid of categories) | Munaza | H2, H5 | Category grid, tap navigates to filtered product list |
| H10 | Create category products screen (filtered home) | Munaza | H9 | Product grid filtered by category, same UX as home |

---

## Product Detail

| # | Task | Owner | Dependencies | Definition of Done |
|---|------|-------|-------------|-------------------|
| P1 | Create ProductDetailModel + JSON serialization | Munaza | H1 | All extended fields (gallery, variants, reviews, etc.) |
| P2 | Create VariantModel + JSON serialization | Munaza | F1 | id, option, label, price |
| P3 | Create ReviewModel + RatingBreakdown | Munaza | F1 | All fields, serialization |
| P4 | Create ProductDetailRepository | Munaza | F16, P1 | getProductDetail(slug), getReviews(slug, page) |
| P5 | Create ProductDetailCubit + states | Munaza | P4 | Load product, select variant, update qty |
| P6 | Build product detail screen (info section) | Munaza | P5, W9, W10 | Name, price, rating, seller card, description |
| P7 | Build image gallery (swipeable + full-screen) | Munaza | P6, W12 | PageView with dots, tap opens full-screen, pinch-to-zoom |
| P8 | Build variant selector | Munaza | P6 | Chip-based selection, price updates on select |
| P9 | Build reviews section | Munaza | P6, W10 | Rating breakdown bars, review cards, pagination |
| P10 | Build related products carousel | Munaza | P6, W8 | Horizontal scroll, tap navigates to detail |
| P11 | Implement Add to Cart from product detail | Munaza | P5, Cart | Calls CartCubit.addItem, shows success snackbar |
| P12 | Implement age restriction gate | Munaza | P6 | Confirmation dialog before add-to-cart for restricted items |
| P13 | Build sticky bottom bar (Add to Cart + Buy Now) | Munaza | P6, W1 | Always visible at bottom, qty selector, two buttons |

---

## Search

| # | Task | Owner | Dependencies | Definition of Done |
|---|------|-------|-------------|-------------------|
| S1 | Create SearchRepository | Naheed | F16 | getSuggestions(query), searchProducts(query, filters) |
| S2 | Create SearchCubit + states | Naheed | S1 | Debounced suggestions, search results, filter/sort |
| S3 | Build search screen | Naheed | S2, W15, W8 | Search bar auto-focus, suggestions dropdown, result grid |
| S4 | Implement debounced suggestions (300ms) | Naheed | S3 | Typing triggers suggestions after 300ms pause |
| S5 | Implement recent searches (local storage) | Naheed | S3, F24 | Last 10 searches stored, shown before typing |
| S6 | Implement search filter/sort | Naheed | S3, H8 | Reuse filter bottom sheet pattern from home |

---

## Seller

| # | Task | Owner | Dependencies | Definition of Done |
|---|------|-------|-------------|-------------------|
| SL1 | Create SellerModel + JSON serialization | Munaza | F1 | Already in Phase 0 models |
| SL2 | Create SellerRepository | Naheed | F16 | getSellerStore(slug, page, category, sort) |
| SL3 | Create SellerCubit + states | Naheed | SL2 | Load seller info + products, follow/unfollow |
| SL4 | Build seller store screen | Naheed | SL3, W8, W10 | Seller header (logo, name, rating, follow), product grid |
| SL5 | Implement follow/unfollow toggle | Naheed | SL4, Auth | Follow button, auth required prompt for guests |

---

## Cart

| # | Task | Owner | Dependencies | Definition of Done |
|---|------|-------|-------------|-------------------|
| C1 | Create CartItem model + JSON serialization | Nimra | F1 | productId, name, price, imageUrl, quantity, variantId, sellerId |
| C2 | Create CartLocalStorage (SharedPreferences) | Nimra | F24, C1 | save/load/clear cart as JSON |
| C3 | Create CartCubit (global) + states | Nimra | C2 | addItem, removeItem, updateQty, clear. Calculates subtotal, delivery fee, total. |
| C4 | Build Cart screen | Nimra | C3, W9, W11 | Cart items list, qty stepper, remove (swipe), totals, empty state |
| C5 | Implement delivery fee logic | Nimra | C3 | Rs 199 if subtotal < 1500, free if >= 1500 |
| C6 | Implement free delivery progress bar | Nimra | C4 | "Add Rs X more for free delivery" bar |
| C7 | Create CartRepository (server validation) | Nimra | F16, C1 | validateItem(productId, variantId, qty) → price/stock check |
| C8 | Implement pre-checkout cart validation | Nimra | C7 | Validate all items before proceeding to checkout. Show repriced/unavailable items. |
| C9 | Implement cart persistence across app restarts | Nimra | C2 | Cart loads on app start, saves on every mutation |

---

## Wishlist

| # | Task | Owner | Dependencies | Definition of Done |
|---|------|-------|-------------|-------------------|
| WL1 | Create WishlistRepository | Nimra | F16, Auth | getWishlist(), toggle(productId), checkWishlisted(ids) |
| WL2 | Create WishlistCubit + states | Nimra | WL1 | Load wishlist, toggle optimistic update |
| WL3 | Build Wishlist screen | Nimra | WL2, W8, W4, W5 | Product list, remove button, empty state, loading |
| WL4 | Implement wishlist toggle from product card/detail | Nimra | WL2 | Heart icon, auth check, optimistic toggle |

---

## Checkout

| # | Task | Owner | Dependencies | Definition of Done |
|---|------|-------|-------------|-------------------|
| CK1 | Create CheckoutRepository | Munaza | F16 | sendOtp, verifyOtp, validateCoupon, placeOrder, getRecommendations |
| CK2 | Create CheckoutCubit + states | Munaza | CK1, Cart, Auth | Multi-step state: delivery form → OTP → review. Holds form data across steps. |
| CK3 | Build checkout delivery screen | Munaza | CK2, W1, W2, Addresses | Address picker (saved), manual entry form, name/phone/email fields |
| CK4 | Build checkout OTP screen | Munaza | CK2, W14 | Send code, enter 6 digits, verify, resend with countdown |
| CK5 | Implement coupon validation | Munaza | CK2 | Coupon input, Apply button, show discount or error |
| CK6 | Build checkout review screen | Munaza | CK2, W9, W1 | Order summary, items, totals, delivery fee, coupon discount, Place Order button |
| CK7 | Implement place order | Munaza | CK6, Cart | API call, loading on button, success → clear cart → navigate to confirmation |
| CK8 | Build order confirmation screen | Munaza | CK7 | Success animation, invoice number, sub-orders, "View Orders" / "Keep Shopping" buttons |
| CK9 | Implement checkout recommendations | Munaza | CK3 | "You might also like" section on delivery screen |

---

## Orders

| # | Task | Owner | Dependencies | Definition of Done |
|---|------|-------|-------------|-------------------|
| O1 | Create OrderModel + OrderItem + OrderTimelineEntry | Nimra | F1 | All fields from `09-data-models.md`, serialization |
| O2 | Create OrderRepository | Nimra | F16, O1 | getOrders(page, status), getOrderDetail(id), trackOrder(invoice, phone), cancelOrder(id) |
| O3 | Create OrderHistoryCubit + states | Nimra | O2 | Load orders, pagination, status filter |
| O4 | Build order history screen | Nimra | O3, W13, W3, W5 | Order cards, status badges, pagination, filter tabs, empty state |
| O5 | Create OrderDetailCubit + states | Nimra | O2 | Load single order detail |
| O6 | Build order detail screen | Nimra | O5, W13, W9 | Items, timeline, totals, delivery info, return eligibility, cancel button |
| O7 | Build order timeline widget | Nimra | O6 | Vertical stepper showing status history |
| O8 | Build public order tracking screen | Nimra | O2, W1, W2 | Invoice + phone input, search, show result |
| O9 | Implement order cancellation | Nimra | O6 | Confirmation dialog, API call, status update |

---

## Returns

| # | Task | Owner | Dependencies | Definition of Done |
|---|------|-------|-------------|-------------------|
| R1 | Create ReturnModel + JSON serialization | Nimra | F1 | All fields from `09-data-models.md` |
| R2 | Create ReturnRepository | Nimra | F16, R1 | getReturns(), submitReturn(orderId, items, reason, evidence), uploadEvidence(file) |
| R3 | Build returns list screen | Nimra | R2, W13, W5 | Return cards with status, empty state |
| R4 | Build return request form (bottom sheet or screen) | Nimra | R2, W1 | Select items, reason, description, evidence upload, submit |
| R5 | Implement evidence upload (image picker + upload) | Nimra | R4 | Camera/gallery pick, upload to server, show preview |
| R6 | Implement return eligibility check | Nimra | O6 | Show return button only if within 7-day window |

---

## Profile

| # | Task | Owner | Dependencies | Definition of Done |
|---|------|-------|-------------|-------------------|
| PR1 | Create ProfileRepository | Arwah | F16 | getProfile(), updateProfile(data), changePassword(current, new) |
| PR2 | Create ProfileCubit + states | Arwah | PR1 | Load profile, edit mode, save |
| PR3 | Build profile hub screen | Arwah | PR2, Auth | Dashboard with action grid (orders, wishlist, addresses, settings, logout) |
| PR4 | Build edit profile screen | Arwah | PR2, W1, W2 | Name, phone fields, save button, validation |
| PR5 | Build change password screen | Arwah | PR1, W1, W2 | Current password, new password, confirm, submit |
| PR6 | Build settings screen | Arwah | F14 | Theme preference (placeholder), notification toggle, app version |

---

## Addresses

| # | Task | Owner | Dependencies | Definition of Done |
|---|------|-------|-------------|-------------------|
| AD1 | Create AddressModel + JSON serialization | Arwah | F1 | All fields from `09-data-models.md` |
| AD2 | Create AddressRepository | Arwah | F16, AD1 | list(), add(data), update(id, data), delete(id), setDefault(id) |
| AD3 | Create AddressCubit + states | Arwah | AD2 | Load list, CRUD operations, set default |
| AD4 | Build address book screen | Arwah | AD3, W4, W5 | Address cards, default indicator, add button, empty state |
| AD5 | Build address form screen (add/edit) | Arwah | AD3, W1, W2 | All fields, validation, save |
| AD6 | Implement address picker for checkout | Arwah | AD3 | Bottom sheet showing saved addresses, select or add new |

---

## Notifications

| # | Task | Owner | Dependencies | Definition of Done |
|---|------|-------|-------------|-------------------|
| N1 | Create NotificationModel + JSON serialization | Arwah | F1 | All fields from `09-data-models.md` |
| N2 | Create NotificationRepository | Arwah | F16, N1 | getNotifications(page), markRead(id), markAllRead(), registerDevice(token) |
| N3 | Create NotificationsCubit + states | Arwah | N2 | Load list, mark read, unread count |
| N4 | Build notifications screen | Arwah | N3, W3, W5 | Notification list, read/unread styling, empty state |
| N5 | Implement FCM setup (token registration) | Arwah | N2, Firebase | Get FCM token, register with backend on login |
| N6 | Implement notification tap navigation | Arwah | N5, Router | Parse notification data → navigate to correct screen |
| N7 | Implement foreground notification display | Arwah | N5 | Show local notification or in-app banner |

---

## Support

| # | Task | Owner | Dependencies | Definition of Done |
|---|------|-------|-------------|-------------------|
| SP1 | Create TicketModel + TicketMessage + JSON | Naheed | F1 | All fields from `09-data-models.md` |
| SP2 | Create SupportRepository | Naheed | F16, SP1 | createTicket, getTickets, getMessages(ticketId, since), sendMessage |
| SP3 | Create SupportCubit + states | Naheed | SP2 | Load tickets, load messages, send message |
| SP4 | Build FAQ screen (static) | Naheed | F10 | Expandable accordion with Q&A |
| SP5 | Build contact screen (static) | Naheed | F10, W1, W2 | Contact info display, email/phone/WhatsApp links |
| SP6 | Build new ticket screen | Naheed | SP3, W1, W2, Auth | Subject, category, message, optional order link, submit |
| SP7 | Build ticket chat screen | Naheed | SP3 | Message list (buyer/agent), input bar, send, poll for new |
| SP8 | Build parcel tracking screen | Naheed | F16 | Token from QR/deep link → show parcel info |

---

## Integration & Testing

| # | Task | Owner | Dependencies | Definition of Done |
|---|------|-------|-------------|-------------------|
| T1 | Write unit tests for all models (fromJson/toJson) | All (own models) | All models | Every model has passing serialization test |
| T2 | Write blocTest for all cubits | All (own cubits) | All cubits | Success, error, edge cases covered |
| T3 | Write widget tests for shared components | Nimra + Naheed | All shared widgets | Render correctly, respond to interaction |
| T4 | Integration test: guest purchase flow | Naheed | All features | End-to-end on device |
| T5 | Integration test: auth flow | Arwah | Auth features | Register → verify → login → logout |
| T6 | Integration test: cart management | Nimra | Cart feature | Add, qty, remove, persist, clear |
| T7 | Integration test: deep link | Naheed | Router, deep linking | Cold start from URL opens correct screen |
| T8 | Performance profiling | Naheed | All features | 60fps scroll, <3s start, <30MB APK |
| T9 | Security audit | Arwah | All features | No secrets, no PII in logs, HTTPS |
| T10 | Device testing (3+ devices) | All | All features | No crashes, layouts intact |

---

## Total Task Count

| Area | Tasks | Owner Distribution |
|------|-------|-------------------|
| Foundation | 25 | Naheed: 15, Arwah: 6, Nimra: 4 |
| Shared Widgets | 15 | Naheed: 7, Nimra: 8 |
| Authentication | 10 | Arwah: 10 |
| Home & Categories | 10 | Munaza: 10 |
| Product Detail | 13 | Munaza: 13 |
| Search | 6 | Naheed: 6 |
| Seller | 5 | Naheed: 5 |
| Cart | 9 | Nimra: 9 |
| Wishlist | 4 | Nimra: 4 |
| Checkout | 9 | Munaza: 9 |
| Orders | 9 | Nimra: 9 |
| Returns | 6 | Nimra: 6 |
| Profile | 6 | Arwah: 6 |
| Addresses | 6 | Arwah: 6 |
| Notifications | 7 | Arwah: 7 |
| Support | 8 | Naheed: 8 |
| Testing | 10 | Distributed |

**Per-developer totals (approximate):**
- Naheed: ~41 tasks
- Arwah: ~45 tasks
- Munaza: ~42 tasks
- Nimra: ~40 tasks
