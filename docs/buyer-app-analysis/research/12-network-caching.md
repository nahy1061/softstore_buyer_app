# Phase 3: Network & Caching

## HTTP Client Setup

**Package:** `dio` with interceptors

```dart
final dio = Dio(BaseOptions(
  baseUrl: 'https://softstore.pk',
  connectTimeout: Duration(seconds: 10),
  receiveTimeout: Duration(seconds: 15),
  sendTimeout: Duration(seconds: 10),
  headers: {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  },
));

// Interceptor stack (order matters)
dio.interceptors.addAll([
  CookieManager(persistCookieJar),    // Session cookie
  AuthInterceptor(authCubit),          // 401 detection
  CsrfInterceptor(),                   // CSRF if required
  RetryInterceptor(),                   // Auto-retry on timeout/5xx
  LogInterceptor(requestBody: kDebugMode, responseBody: kDebugMode),
]);
```

---

## API Error Handling

### Error Classification

| HTTP Status | Classification | User Message | Action |
|-------------|---------------|-------------|--------|
| 200-299 | Success | — | Process response |
| 400 | Validation error | Show field errors | Highlight invalid fields |
| 401 | Session expired | "Session expired. Please sign in." | Clear auth → login screen |
| 403 | Forbidden | "You don't have access to this" | Navigate back |
| 404 | Not found | "This item is no longer available" | Show not-found state |
| 409 | Conflict (stock) | "Item is no longer available" | Update cart |
| 422 | Unprocessable | Show error message from response | Fix and retry |
| 429 | Rate limited | "Too many attempts. Wait {n}s." | Disable button, show countdown |
| 500-599 | Server error | "Something went wrong. Try again." | Show retry button |
| Timeout | Network timeout | "Connection timed out" | Show retry button |
| No connection | Offline | "No internet connection" | Show offline state |

### Typed Failure Classes

```dart
sealed class Failure {
  final String message;
  const Failure(this.message);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'Connection timed out']);
}

class ServerFailure extends Failure {
  final int? statusCode;
  const ServerFailure(super.message, {this.statusCode});
}

class ValidationFailure extends Failure {
  final Map<String, List<String>> fieldErrors;
  const ValidationFailure(super.message, {this.fieldErrors = const {}});
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Session expired']);
}

class RateLimitFailure extends Failure {
  final int retryAfterSeconds;
  const RateLimitFailure(this.retryAfterSeconds,
    [super.message = 'Too many attempts']);
}
```

### Repository Error Handling Pattern

```dart
class ProductRepository {
  Future<List<ProductModel>> getProducts({int page = 1}) async {
    try {
      final response = await dio.get('/api/store/products', queryParameters: {'page': page});
      return (response.data['products'] as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    } on DioException catch (e) {
      throw _mapDioError(e);
    }
  }

  Failure _mapDioError(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return const TimeoutFailure();
    }
    if (e.type == DioExceptionType.connectionError) {
      return const NetworkFailure();
    }
    final status = e.response?.statusCode;
    final body = e.response?.data;
    if (status == 401) return const AuthFailure();
    if (status == 429) return RateLimitFailure(body?['retry_after'] ?? 60);
    if (status == 400 || status == 422) {
      return ValidationFailure(
        body?['message'] ?? 'Invalid request',
        fieldErrors: Map<String, List<String>>.from(body?['errors'] ?? {}),
      );
    }
    return ServerFailure(body?['message'] ?? 'Server error', statusCode: status);
  }
}
```

---

## Timeout Configuration

| Operation | Connect | Receive | Rationale |
|-----------|---------|---------|-----------|
| Default | 10s | 15s | Pakistani network conditions |
| Login/Register | 10s | 20s | May trigger email send |
| Place order | 10s | 30s | DB transaction, email, stock check |
| Image upload (returns) | 15s | 60s | Large file upload |
| Search suggest | 5s | 5s | Should be fast or skip |
| Product list | 10s | 15s | Standard |

Override per-request:
```dart
dio.get('/api/store/products', options: Options(
  receiveTimeout: Duration(seconds: 20),
));
```

---

## Retry Strategy

### Auto-Retry (RetryInterceptor)

| Condition | Retries | Backoff | Notes |
|-----------|---------|---------|-------|
| Timeout | 2 | 1s, 3s | Network glitch recovery |
| 500-503 | 2 | 2s, 5s | Server transient error |
| Connection error | 2 | 1s, 3s | Brief connectivity loss |
| 429 (rate limit) | 0 | — | Show error, don't retry |
| 400/401/403/404 | 0 | — | Client error, don't retry |
| POST that mutates (place order) | 0 | — | Never auto-retry mutations |

### Manual Retry (User-Initiated)

Every screen with data loading shows a "Retry" button on failure:

```dart
// In Cubit
void retry() => loadData(); // Re-calls the same fetch

// In UI
ErrorState(
  message: state.error,
  onRetry: () => context.read<HomeCubit>().retry(),
)
```

---

## Offline Behavior

### Connectivity Monitoring

```dart
class ConnectivityService {
  final _connectivity = Connectivity();
  Stream<bool> get onlineStream => _connectivity.onConnectivityChanged
      .map((result) => result != ConnectivityResult.none);
}
```

### Offline Rules by Feature

| Feature | Offline Behavior |
|---------|-----------------|
| Store browsing | Show cached products (if any); banner: "You're offline" |
| Product detail | Show cached if recently viewed; otherwise error state |
| Search | Disabled — show message: "Search requires internet" |
| Cart | Fully functional (local storage) |
| Checkout | Blocked — "Connect to place your order" |
| Orders list | Show cached list (may be stale); badge: "Last updated: {time}" |
| Wishlist | Show cached; toggle queues and syncs on reconnect |
| Profile | Show cached; edits blocked |
| Login/Register | Blocked — requires network |
| Track order | Blocked — requires network |

### Offline Detection UI

```dart
// Global banner shown when offline
StreamBuilder<bool>(
  stream: connectivityService.onlineStream,
  builder: (context, snapshot) {
    if (snapshot.data == false) {
      return MaterialBanner(
        content: Text("You're offline. Some features may not work."),
        actions: [TextButton(onPressed: () {}, child: Text('DISMISS'))],
      );
    }
    return SizedBox.shrink();
  },
)
```

---

## Caching Strategy

### Cache Layers

```
┌───────────────────────────────────────┐
│  Layer 1: In-Memory (Cubit state)     │ ← Fastest, lost on app kill
├───────────────────────────────────────┤
│  Layer 2: Disk Cache (SharedPrefs)    │ ← Survives app restart
├───────────────────────────────────────┤
│  Layer 3: Image Cache (cached_network)│ ← Separate, size-limited
├───────────────────────────────────────┤
│  Layer 4: Network (fresh from API)    │ ← Source of truth
└───────────────────────────────────────┘
```

### Cache Policy Per Data Type

| Data | Cache Location | TTL | Invalidation | Strategy |
|------|---------------|-----|-------------|----------|
| Product list (home) | Memory | 5 min | Pull-to-refresh | Stale-while-revalidate |
| Product detail | Memory + Disk | 30 min | Navigate away + return | Cache-first, background refresh |
| Categories | Disk | 24 hours | App start | Cache-first |
| Search results | Memory only | Session | New search | No cache (always fresh) |
| Cart | Disk (SharedPrefs) | Permanent | User action | Write-through |
| Order history | Memory | 2 min | Pull-to-refresh, order placed | Stale-while-revalidate |
| User profile | Secure storage | Until logout | Profile edit | Write-through |
| Addresses | Memory | 5 min | CRUD actions | Invalidate on mutation |
| Wishlist | Memory | 5 min | Toggle action | Optimistic update |
| Product images | Disk (image cache) | 7 days, 200MB max | LRU eviction | cached_network_image |
| Search suggestions | Memory | 1 min | New keystroke | Debounced, no disk |

### Stale-While-Revalidate Pattern

```dart
// Show cached data immediately, then refresh in background
Future<void> loadProducts() async {
  // 1. Emit cached data immediately (if available)
  final cached = _cache.getProducts();
  if (cached != null) {
    emit(HomeLoaded(products: cached));
  } else {
    emit(HomeLoading());
  }

  // 2. Fetch fresh data
  try {
    final fresh = await repository.getProducts(page: 1);
    _cache.setProducts(fresh);
    emit(HomeLoaded(products: fresh));
  } on Failure catch (e) {
    if (cached == null) emit(HomeError(e.message));
    // If cached was shown, silently fail (user has data)
  }
}
```

### Optimistic Updates

Used for: wishlist toggle, cart changes, address default

```dart
void toggleWishlist(int productId) {
  // Immediately update UI
  final currentItems = (state as WishlistLoaded).items;
  final updated = currentItems.where((i) => i.productId != productId).toList();
  emit(WishlistLoaded(items: updated));

  // Fire API in background
  repository.toggleWishlist(productId).catchError((e) {
    // Revert on failure
    emit(WishlistLoaded(items: currentItems));
    showToast('Could not update wishlist');
  });
}
```

---

## Local Storage

### SharedPreferences (Non-Sensitive)

| Key | Type | Content |
|-----|------|---------|
| `cart_items` | String (JSON) | Serialized cart |
| `recent_searches` | List<String> | Last 10 searches |
| `onboarding_completed` | bool | First-time flag |
| `last_categories_fetch` | int (timestamp) | Cache TTL check |
| `cached_categories` | String (JSON) | Category list |
| `fcm_token` | String | Push notification token |
| `theme_mode` | String | 'light'/'dark'/'system' |
| `last_viewed_products` | String (JSON) | Last 20 product slugs + basic data |

### flutter_secure_storage (Sensitive)

| Key | Type | Content |
|-----|------|---------|
| `user_profile` | String (JSON) | Cached user data |
| `session_valid_until` | String | Estimated session expiry |

### Image Cache Configuration

```dart
// cached_network_image configuration
CachedNetworkImage(
  imageUrl: product.imageUrl,
  maxWidthDiskCache: 800,  // Don't cache full-res for grid
  memCacheWidth: 400,       // Memory limit
  placeholder: (_, __) => ShimmerPlaceholder(),
  errorWidget: (_, __, ___) => Icon(Icons.image_not_supported),
)
```

Maximum disk cache: **200 MB** (auto-evicts LRU beyond this).

---

## Authentication Expiration Handling

```
App resumes from background
  │
  ├── Check: has been >30 minutes since last API call?
  │     ├── No → proceed normally
  │     └── Yes → ping GET /api/buyer/me
  │           ├── 200 → session alive, continue
  │           └── 401 → session expired
  │                 │
  │                 ├── Clear auth state
  │                 ├── Show: "Session expired. Sign in again."
  │                 ├── Preserve current navigation for ?next
  │                 └── Navigate to /login?next={currentRoute}
  │
  └── Any API call returns 401
        └── Same expiration handling as above
```

### Preventing Data Loss on Expiry

- Cart is local → never lost on session expiry
- Checkout form data: if user was mid-checkout, save form to memory; restore after re-login
- Draft review: save to local before navigating to login

---

## Request Deduplication

Prevent duplicate API calls when:
- User rapidly taps a button
- Pull-to-refresh while already loading
- Tab switch triggers reload while previous load is in-flight

```dart
// In Cubit
CancelToken? _currentToken;

Future<void> loadProducts({bool refresh = false}) async {
  if (state is HomeLoading && !refresh) return; // Already loading

  _currentToken?.cancel();
  _currentToken = CancelToken();

  emit(HomeLoading());
  try {
    final products = await repository.getProducts(
      cancelToken: _currentToken,
    );
    emit(HomeLoaded(products: products));
  } on DioException catch (e) {
    if (e.type != DioExceptionType.cancel) {
      emit(HomeError(e.message ?? 'Failed'));
    }
  }
}
```

---

## Bandwidth Optimization

| Technique | Implementation |
|-----------|----------------|
| Request only needed fields | Use `?fields=` param if backend supports (proposed) |
| Paginate everything | 12 items per page for product grids |
| Thumbnail URLs for lists | Request smaller images for grid cards |
| Compress request bodies | Dio gzip support (auto if server supports) |
| Debounce search | 300ms debounce before firing search suggest |
| Conditional fetch | `If-Modified-Since` header for category list (if backend supports) |
| Avoid duplicate image loads | cached_network_image handles this |
