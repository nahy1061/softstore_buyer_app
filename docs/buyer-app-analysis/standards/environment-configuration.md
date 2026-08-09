# Environment Configuration

## Environments

| Environment | Purpose | API Base URL | Firebase Project |
|-------------|---------|-------------|-----------------|
| Development | Local dev, debugging | `https://dev.softstore.pk` (or staging URL) | `softstore-dev` |
| Staging | QA testing, pre-release | `https://staging.softstore.pk` | `softstore-staging` |
| Production | Live users | `https://softstore.pk` | `softstore-prod` |

---

## Flutter Environment Strategy

### Approach: Dart `--dart-define` + Flavor classes

**Why not `.env` files with `flutter_dotenv`?**
- Adds a package dependency for something Dart can do natively
- `.env` files are included in the app bundle (not truly secret)
- `--dart-define` is compile-time, zero runtime overhead

### How It Works

```bash
# Development
flutter run --dart-define=ENV=dev --dart-define=API_BASE_URL=https://dev.softstore.pk

# Staging
flutter run --dart-define=ENV=staging --dart-define=API_BASE_URL=https://staging.softstore.pk

# Production (release)
flutter build apk --dart-define=ENV=prod --dart-define=API_BASE_URL=https://softstore.pk
```

### Environment Config Class

```dart
// lib/core/constants/env_config.dart
abstract final class EnvConfig {
  static const env = String.fromEnvironment('ENV', defaultValue: 'dev');
  static const apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://dev.softstore.pk',
  );
  static const recaptchaSiteKey = String.fromEnvironment('RECAPTCHA_SITE_KEY');

  static bool get isDev => env == 'dev';
  static bool get isStaging => env == 'staging';
  static bool get isProd => env == 'prod';
}
```

### Usage

```dart
// In api_client.dart
final dio = Dio(BaseOptions(
  baseUrl: EnvConfig.apiBaseUrl,
  // ...
));

// In recaptcha setup
await recaptcha.initialize(siteKey: EnvConfig.recaptchaSiteKey);

// Conditional debug behavior
if (EnvConfig.isDev) {
  dio.interceptors.add(LogInterceptor(responseBody: true));
}
```

---

## VS Code Launch Configs

```json
// .vscode/launch.json
{
  "configurations": [
    {
      "name": "Dev",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=ENV=dev",
        "--dart-define=API_BASE_URL=https://dev.softstore.pk",
        "--dart-define=RECAPTCHA_SITE_KEY=dev_site_key_here"
      ]
    },
    {
      "name": "Staging",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=ENV=staging",
        "--dart-define=API_BASE_URL=https://staging.softstore.pk",
        "--dart-define=RECAPTCHA_SITE_KEY=staging_site_key_here"
      ]
    },
    {
      "name": "Production",
      "request": "launch",
      "type": "dart",
      "args": [
        "--dart-define=ENV=prod",
        "--dart-define=API_BASE_URL=https://softstore.pk",
        "--dart-define=RECAPTCHA_SITE_KEY=prod_site_key_here"
      ]
    }
  ]
}
```

---

## Firebase Configuration

### Per-Environment Setup

Each environment uses a separate Firebase project:
- `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) are environment-specific
- Use the `flutterfire configure` command per environment

### File Placement

```
android/app/src/dev/google-services.json
android/app/src/staging/google-services.json
android/app/src/prod/google-services.json

ios/config/dev/GoogleService-Info.plist
ios/config/staging/GoogleService-Info.plist
ios/config/prod/GoogleService-Info.plist
```

Select the correct file at build time via Gradle product flavors (Android) or Xcode schemes (iOS).

---

## Secrets Management

### What Is a Secret

| Secret | Where It Goes | NOT Here |
|--------|---------------|----------|
| reCAPTCHA site key | `--dart-define` at build time | NOT in source code |
| Firebase config files | Per-flavor config dirs (gitignored) | NOT in default app/ dir |
| Backend admin credentials | Never in the app | — |
| Google OAuth client ID | Firebase config + `google-services.json` | NOT hardcoded |

### What Is NOT a Secret

| Value | Where It Goes | Why Not Secret |
|-------|---------------|----------------|
| API base URL | `--dart-define` / `EnvConfig` | Public URL, no auth value |
| Delivery fee (Rs 199) | `app_config.dart` | Business logic constant |
| Free delivery threshold | `app_config.dart` | Business logic constant |
| Endpoint paths | `api_endpoints.dart` | Path structure, not credentials |

### .gitignore Rules

```gitignore
# Environment-specific Firebase configs
android/app/src/dev/google-services.json
android/app/src/staging/google-services.json
android/app/src/prod/google-services.json
ios/config/

# IDE launch configs with secrets
.vscode/launch.json

# Key files
*.keystore
*.jks
key.properties
```

### Sharing Secrets Among Team

- Store secrets in a shared password manager (e.g., team Bitwarden vault)
- Each dev creates their own `.vscode/launch.json` from the template
- CI/CD secrets stored in GitHub Actions secrets (not in repo)
- Firebase configs distributed via secure channel (not committed to git)

---

## Feature Flags

### MVP Approach: Simple Boolean Constants

For MVP, we don't need a feature flag service. Simple compile-time flags:

```dart
// lib/core/constants/feature_flags.dart
abstract final class FeatureFlags {
  static const enableDarkMode = false;        // Phase 2
  static const enableBiometric = false;       // Phase 2
  static const enablePushNotifications = true; // MVP but configurable
  static const enableParcelTracking = true;   // MVP
  static const showDebugBanner = bool.fromEnvironment('DEBUG_BANNER', defaultValue: false);
}
```

### Usage

```dart
if (FeatureFlags.enableDarkMode) {
  // Show theme toggle in settings
}
```

### Post-MVP: Remote Feature Flags

When needed (post-launch), migrate to Firebase Remote Config:
- Allows toggling features without app update
- A/B testing capability
- Gradual rollout

For MVP, compile-time flags are sufficient and add zero network overhead.

---

## Build & Release Configuration

### Android

```
android/
├── app/
│   ├── build.gradle          # Define product flavors: dev, staging, prod
│   └── src/
│       ├── dev/              # Dev google-services.json
│       ├── staging/          # Staging google-services.json
│       └── prod/             # Prod google-services.json
├── key.properties            # Signing config (GITIGNORED)
└── upload-keystore.jks       # Release signing key (GITIGNORED)
```

### iOS

```
ios/
├── Runner/
│   └── Info.plist
├── config/
│   ├── dev/GoogleService-Info.plist
│   ├── staging/GoogleService-Info.plist
│   └── prod/GoogleService-Info.plist
└── Runner.xcodeproj/
    └── xcshareddata/        # Xcode schemes per environment
```

### Build Commands

```bash
# Debug (dev)
flutter run --flavor dev --dart-define=ENV=dev --dart-define=API_BASE_URL=https://dev.softstore.pk

# Release APK (prod)
flutter build apk --flavor prod --dart-define=ENV=prod --dart-define=API_BASE_URL=https://softstore.pk

# Release App Bundle (prod, for Play Store)
flutter build appbundle --flavor prod --dart-define=ENV=prod --dart-define=API_BASE_URL=https://softstore.pk
```

---

## Summary

| Concern | Solution |
|---------|----------|
| Environment switching | `--dart-define` + `EnvConfig` class |
| Firebase per-env | Product flavors with separate config files |
| Secrets | Never in source. `--dart-define` at build time, `.gitignore` config files |
| Feature flags | Compile-time constants in `feature_flags.dart` (MVP). Remote Config post-launch. |
| Team secret sharing | Password manager + secure channel. Not in git. |
| CI/CD | GitHub Actions secrets for build-time values |
