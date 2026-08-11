# F11-F20 Quick Reference

## File Locations

```
lib/core/
├── config/
│   ├── env_config.dart          (F14) Environment: base URL, Firebase, reCAPTCHA
│   └── feature_flags.dart       (F14) Toggles: useMockRepositories, debugLogs, etc.
├── constants/
│   ├── api_endpoints.dart       (F11) All 50 API paths
│   ├── app_config.dart          (F12) Delivery fee, OTP, timeouts, pagination
│   └── storage_keys.dart        (F13) SharedPrefs + SecureStorage key names
├── errors/
│   └── failures.dart            (F20) NetworkFailure, AuthFailure, TimeoutFailure, etc.
└── network/
    ├── dio_client.dart          (F16) HTTP client singleton
    └── interceptors/
        ├── auth_interceptor.dart        (F17) 401 detection
        ├── retry_interceptor.dart       (F18) Exponential backoff
        └── logging_interceptor.dart     (F19) HTTP request/response logging
```

## Usage Patterns

### Import API Endpoints
```dart
import 'package:softstore_buyer_app/core/constants/api_endpoints.dart';

final response = await dioClient.get(ApiEndpoints.getProducts);
final userProfile = await dioClient.get(ApiEndpoints.getProfile);
```

### Access App Config
```dart
import 'package:softstore_buyer_app/core/constants/app_config.dart';

if (subtotal < AppConfig.freeDeliveryThreshold) {
  deliveryFee = AppConfig.deliveryFee;
}

await Future.delayed(AppConfig.otpResendDelay);
```

### Use DioClient
```dart
import 'package:softstore_buyer_app/core/network/dio_client.dart';

// Initialize once in main()
await DioClient().init();

// Use in repositories
class ProductRepository {
  final dioClient = DioClient();
  
  Future<List<Product>> getProducts() async {
    final response = await dioClient.get(ApiEndpoints.getProducts);
    return (response.data as List).map((p) => Product.fromJson(p)).toList();
  }
}
```

### Handle Failures
```dart
import 'package:softstore_buyer_app/core/errors/failures.dart';

try {
  await productRepository.getProducts();
} on AuthFailure catch (e) {
  // Redirect to login
  context.go('/login');
} on TimeoutFailure catch (e) {
  // Show retry button
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(title: Text('Request timeout. Tap to retry.'))
  );
} on NetworkFailure catch (e) {
  // Show offline message
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(title: Text('No internet connection'))
  );
}
```

### Storage Keys
```dart
import 'package:softstore_buyer_app/core/constants/storage_keys.dart';

// In LocalStorageService (F24)
await prefs.setString(StorageKeys.cartItems, jsonEncode(items));

// In SecureStorageService (F23)
await secureStorage.write(StorageKeys.authToken, token);
```

### Check Environment
```dart
import 'package:softstore_buyer_app/core/config/env_config.dart';

if (EnvConfig.isProd) {
  // Production-specific code
}

if (EnvConfig.isDev) {
  // Development-only logging
}
```

### Use Feature Flags
```dart
import 'package:softstore_buyer_app/core/config/feature_flags.dart';

if (FeatureFlags.useMockRepositories) {
  // Use mock repositories for testing
  getIt.registerSingleton<ProductRepository>(
    MockProductRepository()
  );
} else {
  // Use real repositories
  getIt.registerSingleton<ProductRepository>(
    ProductRepository()
  );
}

if (FeatureFlags.enableDetailedLogs) {
  developer.log('Detailed debug info...');
}
```

## Run Commands

```bash
# Development (default)
flutter run

# Production
flutter run --dart-define=ENVIRONMENT=prod \
            --dart-define=BASE_URL=https://api.softstore.com

# With mock data (UI testing without backend)
flutter run --dart-define=USE_MOCK=true

# With detailed logging
flutter run --dart-define=DEBUG_LOGS=true \
            --dart-define=NETWORK_LOGS=true

# All together
flutter run --dart-define=ENVIRONMENT=dev \
            --dart-define=BASE_URL=https://api.dev.softstore.com \
            --dart-define=DEBUG_LOGS=true \
            --dart-define=NETWORK_LOGS=true
```

## Key Constants

```dart
// Delivery
deliveryFee: 199.0
freeDeliveryThreshold: 1500.0

// OTP
otpLength: 6
otpResendDelay: 60 seconds
otpMaxRetries: 3

// Session
sessionTimeout: 30 minutes
sessionCheckInterval: 5 minutes

// Network
connectTimeout: 30 seconds
receiveTimeout: 30 seconds
sendTimeout: 30 seconds
maxRetries: 2 (with 1s, 2s backoff)

// Pagination
defaultPageSize: 20
searchPageSize: 20
orderPageSize: 10

// Returns
returnEligibilityWindow: 7 days
```

## API Endpoints Summary

| Feature | Count | Examples |
|---------|-------|----------|
| Auth | 10 | login, register, verifyOtp, forgotPassword, etc. |
| Products | 4 | getProducts, getProductDetail, getReviews, getRelated |
| Cart | 2 | validateItem, validateCart |
| Wishlist | 4 | getWishlist, addToWishlist, removeFromWishlist, check |
| Checkout | 4 | sendOtp, verifyOtp, validateCoupon, placeOrder |
| Orders | 4 | getOrders, getDetail, track, cancel |
| Returns | 4 | getReturns, submitReturn, uploadEvidence |
| Profile | 3 | getProfile, updateProfile, changePassword |
| Addresses | 5 | list, add, update, delete, setDefault |
| Notifications | 4 | getNotifications, markRead, markAllRead, registerToken |
| Support | 4 | createTicket, getTickets, getMessages, sendMessage |
| Search | 2 | suggestions, search |
| Seller | 4 | getStore, getProducts, follow, unfollow |
| Categories | 2 | getCategories, getProducts |

**Total: 54 endpoints** (base + variations)

## Failure Types Reference

```
NetworkFailure    → No internet, connection refused
TimeoutFailure    → Request timeout
ServerFailure     → 5xx errors (statusCode included)
ValidationFailure → 422, field validation errors (errors map included)
AuthFailure       → 401, session expired
RateLimitFailure  → 429, too many requests (retryAfter included)
NotFoundFailure   → 404, resource not found
CacheFailure      → Local storage error
UnknownFailure    → Generic/unknown error
```

## Interceptor Order

```
Request  →  LoggingInterceptor  →  AuthInterceptor  →  RetryInterceptor  →  CookieManager  →  Server
Response ←  LoggingInterceptor  ←  AuthInterceptor  ←  RetryInterceptor  ←  CookieManager  ←  Server
```

- **LoggingInterceptor:** Logs request/response if `enableNetworkLogging` flag is true
- **AuthInterceptor:** Detects 401, rejects with AuthFailure
- **RetryInterceptor:** Retries timeout/5xx up to 2 times with 1s, 2s backoff
- **CookieManager:** Persists cookies to disk automatically

## Storage Keys Organized

```dart
// Auth
authToken, refreshToken, sessionId

// User
userId, userName, userEmail, userPhone

// Cart
cartItems, cartLastModified

// Wishlist
wishlistItems

// Device
deviceFcmToken, deviceId

// Preferences
themeMode, notificationsEnabled, lastAppVersion

// Search
recentSearches

// Session
lastSessionTime, sessionExpiryTime

// Feature Flags
useMockRepositories, enableDetailedLogs
```

---

**Generated Files:** 10 | **Dependencies:** 11 | **Status:** ✅ Ready to use
