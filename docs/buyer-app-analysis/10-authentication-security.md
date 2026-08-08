# Phase 3: Authentication & Security

## Authentication Architecture

### Session-Based Auth (Cookie)

The Softstore backend uses **server-side PHP sessions**, not JWT tokens. The mobile app authenticates via:

1. POST login credentials → backend sets `SOFTSTORE_SESSID` cookie
2. All subsequent requests include this cookie automatically (via Dio's cookie jar)
3. Backend reads session from cookie → identifies the buyer

This is the same mechanism the seller React Native app uses successfully.

```
┌─────────────┐         ┌─────────────────────┐
│  Flutter App │         │  Softstore Backend   │
│             │         │                     │
│  POST /login │────────►│ Validate credentials │
│  {email,pwd} │         │ Create session       │
│             │◄────────│ Set-Cookie:          │
│             │         │  SOFTSTORE_SESSID=x  │
│             │         │                     │
│  GET /orders │────────►│ Read session from    │
│  Cookie: x   │         │ cookie → buyer #42   │
│             │◄────────│ Return buyer's data   │
└─────────────┘         └─────────────────────┘
```

---

## Registration Flow

```
1. User fills: full_name, email, phone (optional), password (min 8)
   └── Client-side validation before submit

2. Invisible reCAPTCHA widget generates token
   └── recaptcha_enterprise_flutter package

3. POST /api/buyer/register
   {full_name, email, phone, password, captcha_token}
   └── Backend:
       - Validates captcha token with Google
       - Checks email uniqueness in marketplace_customers
       - Hashes password (bcrypt)
       - Creates row in marketplace_customers
       - Issues email OTP via issueEmailOtp()
       - Sets session (auto-login)
       - Returns user object + otp_sent: true

4. OTP Verification Screen
   └── User enters 6-digit code from email
   └── POST /api/buyer/verify-email {otp_code}
   └── Backend verifies hash, sets email_verified = true

5. Navigate to home (or ?next target)
```

---

## Login Flow

```
1. User enters email + password
   └── Client validation: email format, password non-empty

2. Invisible reCAPTCHA generates token

3. POST /api/buyer/login
   {email, password, captcha_token}
   └── Backend:
       - Validates captcha
       - Checks rate limit (login throttle)
       - Verifies email/password against marketplace_customers
       - Sets session: marketplace_customer = {id, email, full_name}
       - Returns Set-Cookie header
       - Returns user object

4. App stores session cookie in persistent cookie jar
   └── flutter_secure_storage for cookie persistence

5. Navigate to ?next or home
```

### Google OAuth Login

```
1. User taps "Continue with Google"

2. google_sign_in package opens native sign-in flow

3. On success, get ID token from Google

4. POST /api/buyer/auth/google
   {id_token}
   └── Backend:
       - Verifies ID token with Google
       - Looks up oauth_identity_links for this Google ID
       - If found: log in existing buyer, set session
       - If not found: create new marketplace_customer, link identity
       - Returns user object + is_new_account flag

5. App receives session cookie, navigates home
```

---

## Logout Flow

```
1. User taps "Sign out" → confirmation dialog

2. POST /api/buyer/logout
   └── Backend destroys session

3. App clears:
   - Cookie jar (session cookie gone)
   - Secure storage (any cached session data)
   - Auth state (emit Unauthenticated)
   - NOT cleared: cart (preserved for next login), preferences

4. Navigate to login screen
```

---

## Password Reset Flow

```
1. User taps "Forgot password?" on login screen

2. Forgot Password Screen
   └── Enter email
   └── POST /api/buyer/forgot-password {email}
   └── Backend sends reset link to email (with token)
   └── Always shows "Check your email" (no email enumeration)

3. User taps link in email → opens app via deep link
   └── softstore://reset-password/{token}
   └── OR https://softstore.pk/reset-password/{token}

4. Reset Password Screen
   └── New password + confirm password
   └── POST /api/buyer/reset-password {token, password, password_confirmation}
   └── Backend validates token (expiry, used), updates password hash
   └── Returns success

5. Navigate to login with success message
```

---

## Session Handling

### Cookie Persistence

```dart
// Dio setup with persistent cookie jar
final cookieJar = PersistCookieJar(
  storage: FileStorage(appDocDir.path + '/.cookies/'),
);
dio.interceptors.add(CookieManager(cookieJar));
```

The `PersistCookieJar` saves cookies to disk. The session survives app restarts.

### Session Expiry Detection

The backend session expires after **8 hours** of inactivity.

```dart
// Auth interceptor
class AuthInterceptor extends Interceptor {
  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // JSON API returns 401 when session expired
    if (response.statusCode == 401) {
      authCubit.onSessionExpired();
      // Router redirects to /login?next=currentRoute
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      authCubit.onSessionExpired();
    }
    handler.next(err);
  }
}
```

### Session Refresh Strategy

PHP sessions extend on activity. As long as the user makes API calls within the 8-hour window, the session stays alive. No explicit refresh token is needed.

**Proactive keep-alive:** On app resume from background (if >30 min elapsed), make a lightweight `GET /api/buyer/me` call. If it returns 401, redirect to login. If 200, session is still valid.

---

## Secure Storage

| Data | Storage | Reason |
|------|---------|--------|
| Session cookie | `PersistCookieJar` (file-based, app-private dir) | Managed by Dio cookie jar |
| User profile cache | `flutter_secure_storage` | Contains PII (name, email) |
| Cart data | `SharedPreferences` | Not sensitive (product IDs, prices) |
| Recent searches | `SharedPreferences` | Not sensitive |
| FCM token | `SharedPreferences` | Not sensitive |
| Onboarding flag | `SharedPreferences` | Not sensitive |

### flutter_secure_storage Configuration

```dart
const secureStorage = FlutterSecureStorage(
  aOptions: AndroidOptions(encryptedSharedPreferences: true),
  iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
);
```

---

## API Authorization

### Request Authentication

All authenticated requests include the session cookie automatically:

```dart
// Dio is configured with credentials: true equivalent
dio.options.extra['withCredentials'] = true;
// CookieManager interceptor handles cookie attachment
```

### CSRF Protection

For the proposed JSON API routes: CSRF exemption on `/api/*` paths (recommended — standard for API routes since they're already protected by the session cookie and CORS). If the backend team requires CSRF on API routes:

```dart
class CsrfInterceptor extends Interceptor {
  String? _csrfToken;

  @override
  Future<void> onRequest(RequestOptions options, handler) async {
    if (options.method != 'GET' && _csrfToken == null) {
      _csrfToken = await _fetchCsrfToken();
    }
    if (_csrfToken != null && options.method != 'GET') {
      options.headers['X-CSRF-TOKEN'] = _csrfToken;
    }
    handler.next(options);
  }

  Future<String?> _fetchCsrfToken() async {
    final response = await dio.get('/api/csrf-token');
    return response.data['token'];
  }
}
```

---

## Input Validation

### Client-Side (Flutter)

| Field | Validation | Error Message |
|-------|-----------|---------------|
| Email | RFC 5322 format | "Enter a valid email address" |
| Password | Min 8 chars | "Password must be at least 8 characters" |
| Full name | Min 3 chars, non-empty | "Enter your full name" |
| Phone | Pakistani format: starts with 03, 11 digits | "Enter a valid Pakistani phone number" |
| Address | Min 8 chars | "Enter a complete address" |
| City | Min 2 chars | "Enter your city" |
| OTP | Exactly 6 digits | "Enter the 6-digit code" |
| Quantity | 1 to stock max | "Maximum {stock} available" |
| Coupon | Non-empty before Apply | — |

### Server-Side (Trusted)

Client validation is UX only. Server enforces:
- Email uniqueness
- Password strength (bcrypt hash)
- Stock availability at checkout time
- Price calculation (PricingService — never from client)
- Coupon validity and applicability
- Rate limiting on login, register, OTP endpoints
- Session verification before order placement

---

## HTTPS & Transport Security

| Requirement | Implementation |
|-------------|----------------|
| All traffic over HTTPS | Base URL: `https://softstore.pk` — no HTTP fallback |
| Certificate pinning | NOT recommended for MVP (complicates cert rotation) |
| Network security config (Android) | `cleartextTrafficPermitted="false"` |
| App Transport Security (iOS) | Default (enforces HTTPS) |
| TLS version | TLS 1.2+ (server-side) |

---

## Sensitive Data Handling

### What We Never Store

- Passwords (plaintext) — only sent over HTTPS, never cached
- Full credit card numbers — N/A (COD only)
- OTP codes — entered and sent, never persisted
- CSRF tokens — held in memory only, refreshed per session

### What We Clear on Logout

- Session cookie (cookie jar cleared)
- Cached user profile (secure storage)
- Auth state in memory

### What We Keep After Logout

- Cart items (convenience for next login)
- App preferences (theme, onboarding flag)
- Recent searches
- FCM token (server-side mapping is invalidated)

---

## reCAPTCHA Implementation

### Invisible Widget (v3 / Enterprise)

```dart
// Using recaptcha_enterprise_flutter
final recaptcha = RecaptchaEnterprise();

// Initialize on app start
await recaptcha.initialize(siteKey: 'YOUR_SITE_KEY');

// Before login/register submit
final token = await recaptcha.execute('login'); // or 'register'

// Include in API call
api.post('/api/buyer/login', {
  email: email,
  password: password,
  captcha_token: token,
});
```

**Used on:** Login, Register, Forgot Password (same endpoints the web uses reCAPTCHA on).

**Not used on:** Add to cart, checkout, wishlist toggle, profile updates.

---

## Rate Limiting Response Handling

```dart
// When API returns 429
if (response.statusCode == 429) {
  final retryAfter = response.data['retry_after'] ?? 60;
  emit(AuthError(
    message: 'Too many attempts. Please wait ${retryAfter}s.',
    type: AuthErrorType.rateLimited,
  ));
}
```

---

## Security Checklist

| Item | Status |
|------|--------|
| No hardcoded secrets in source | Enforced (env vars / build config) |
| No sensitive data in logs | Strip PII from debug logs |
| ProGuard/R8 obfuscation (Android release) | Enabled |
| No sensitive data in screenshots (app switcher) | FLAG_SECURE on checkout/login screens |
| Biometric auth (Phase 2) | Local-only, protects stored session |
| Jailbreak/root detection | Phase 2 (not MVP) |
| SSL pinning | Phase 2 (not MVP — cert rotation complexity) |
| API key in build config, not source | For reCAPTCHA site key |
