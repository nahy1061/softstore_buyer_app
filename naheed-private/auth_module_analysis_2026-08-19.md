# Auth Module Analysis — 19 August 2026

## Issues Identified

| # | Issue | Severity | Status |
|---|-------|----------|--------|
| 1 | Empty reCAPTCHA tokens sent to backend | Critical | Attempted fix (captcha package swap) |
| 2 | Missing error handling for 302 redirects | High | Fixed |
| 3 | SnackBar errors invisible in modal bottom sheet | Medium | Fixed (switched to AlertDialog) |
| 4 | No debug logging in auth flow | Low | Fixed (added debugPrint throughout) |
| 5 | `recaptchaToken` parameter exposed in cubit API | Low | Fixed (generated internally) |
| 6 | Wrong reCAPTCHA package (Enterprise vs standard v3) | Critical | Fixed (switched to flutter_gcaptcha_v3) |
| 7 | Native Android/iOS configs for wrong package | Medium | Fixed |
| 8 | CaptchaService required init at app startup | Low | Fixed (lazy setup in AuthScreen) |

## Architecture Notes

- Backend: PHP (SoftStore), uses session cookies (`SOFTSTORE_SESSID`), CSRF tokens, form-encoded POST
- reCAPTCHA site key: `6Ldqn3ctAAAAAIrfgKNTGbqPVJhsP1jYITlxdArv` (standard v3)
- Backend expects `recaptcha_token` and `g-recaptcha-response` form fields
- Backend returns `302` on success, `200` with HTML error divs on failure

## Files Referenced

- `lib/core/services/captcha_service.dart` — reCAPTCHA token generation
- `lib/features/auth/cubit/auth_cubit.dart` — Auth state management
- `lib/features/auth/repository/auth_repository.dart` — API calls
- `lib/features/auth/screens/register_screen.dart` — Register UI
- `lib/features/auth/screens/login_screen.dart` — Login UI
- `lib/features/auth/screens/auth_screen.dart` — Modal container
- `lib/core/network/dio_client.dart` — HTTP client
- `lib/core/network/interceptors/auth_interceptor.dart` — 302/419 detection
- `lib/core/utils/csrf_service.dart` — CSRF token management
- `lib/core/utils/html_parser_util.dart` — HTML error extraction
