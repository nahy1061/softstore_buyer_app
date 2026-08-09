# Shared Foundation Ownership

## Foundation Components

The following are shared infrastructure that every developer depends on. They must be built first (Week 1) and have clear ownership rules.

---

## Initial Build Ownership

| Component | File(s) | Initial Owner | Why This Person |
|-----------|---------|---------------|-----------------|
| Flutter project creation | `pubspec.yaml`, `main.dart`, folder structure | Naheed | Project lead, owns repo |
| Theme + design system | `core/theme/*` (6 files) | Naheed | Defines visual language for the team |
| Router shell | `app/router.dart` | Naheed | Central file, defines all routes |
| App entry point | `app/app.dart` | Naheed | MultiBlocProvider setup, MaterialApp |
| API client + interceptors | `core/network/*` | Arwah | Handles networking across all features |
| Error handling (Failure classes) | `core/errors/failures.dart` | Arwah | Tied to API client work |
| Auth repository + cubit | `features/auth/` | Arwah | Auth is tightly coupled to API client (cookie jar, session) |
| Shared models (Product, Category) | `features/home/models/` | Munaza | She owns Home/Products |
| Shared widgets (all 15) | `core/widgets/*` | Naheed + Nimra | Split: Naheed builds AppButton, AppTextField, LoadingSkeleton, ErrorStateWidget, EmptyStateWidget, ConfirmationDialog, AppSnackbar. Nimra builds ProductCard, PriceDisplay, RatingDisplay, QuantitySelector, AppImage, StatusBadge, OtpInput, AppSearchBar. |
| Validators | `core/utils/validators.dart` | Arwah | Needed for auth forms first |
| Formatters | `core/utils/formatters.dart` | Nimra | PKR formatting needed for product display |
| Constants (API endpoints, config) | `core/constants/*` | Naheed | Central config, project lead maintains |
| Storage wrappers | `core/storage/*` | Nimra | Cart persistence uses SharedPreferences |
| Environment config | `core/constants/env_config.dart` | Naheed | Build configuration is project-level |

---

## Modification Rules

### Files That Require Team Agreement Before Changing

| File | Why | Process |
|------|-----|---------|
| `pubspec.yaml` | Adding packages affects everyone's build | Message in team chat + wait for acknowledgment |
| `app/router.dart` | Routes affect navigation across all features | Add your routes only; don't modify others' routes |
| `app/app.dart` | Global providers affect all features | Only Naheed modifies (or with explicit approval) |
| `core/theme/app_colors.dart` | Color changes affect entire UI | Discuss in team chat first |
| `core/theme/app_typography.dart` | Typography changes affect entire UI | Discuss first |
| `core/network/api_client.dart` | Interceptor changes affect all API calls | Only Arwah modifies |
| `core/errors/failures.dart` | New failure types affect all repos | Only Arwah adds (or request via chat) |

### Files Any Developer Can Modify (Within Rules)

| File | Rule |
|------|------|
| `core/constants/api_endpoints.dart` | Add your endpoints; don't modify others' |
| `core/constants/storage_keys.dart` | Add your keys; don't modify others' |
| `app/router.dart` | Add your routes in the designated section; don't restructure |
| `core/widgets/*` | Bug fixes OK. New props require discussion. |

### Files Only the Owner Modifies

| File/Folder | Owner | Others Must |
|-------------|-------|-------------|
| `features/auth/*` | Arwah | Create a PR that Arwah reviews |
| `features/home/*` | Munaza | Create a PR that Munaza reviews |
| `features/cart/*` | Nimra | Create a PR that Nimra reviews |
| `features/orders/*` | Nimra | Create a PR that Nimra reviews |
| `features/checkout/*` | Munaza | Create a PR that Munaza reviews |
| `features/profile/*` | Arwah | Create a PR that Arwah reviews |

---

## Shared Component Request Process

If a developer needs a new shared widget or a change to an existing one:

1. Post in team chat: "I need X shared component for feature Y"
2. Check if it qualifies (used by 3+ features?)
3. If yes → Naheed creates or assigns creation
4. If no → build it in your own `features/{name}/presentation/widgets/`
5. If it later turns out to be needed by a third feature → migrate to `core/widgets/`

---

## Foundation Week Deliverables

By end of Week 1, the following must be merged to `develop`:

- [ ] Flutter project with complete folder structure (all empty feature folders exist)
- [ ] `pubspec.yaml` with all dependencies listed in `dependencies.md`
- [ ] `core/theme/*` — all 6 design system files
- [ ] `app/app.dart` — MaterialApp.router with global providers
- [ ] `app/router.dart` — All routes defined (pointing to placeholder screens)
- [ ] `core/network/api_client.dart` — Dio with cookie jar, auth interceptor, retry interceptor
- [ ] `core/errors/failures.dart` — All Failure types
- [ ] `core/storage/*` — SecureStorage + LocalStorage wrappers
- [ ] `core/utils/validators.dart` — Email, phone, password, name
- [ ] `core/utils/formatters.dart` — PKR currency, phone, date
- [ ] `core/constants/*` — ApiEndpoints, AppConfig, StorageKeys, EnvConfig, FeatureFlags
- [ ] `core/widgets/*` — All 15 shared components (can be basic implementations)
- [ ] `features/auth/` — AuthCubit + AuthRepository + Login/Register screens (functional)
- [ ] `.vscode/launch.json` template (without secrets)
- [ ] `.gitignore` properly configured
- [ ] `analysis_options.yaml` with team lint rules

---

## Who Builds What in Foundation Week

| Developer | Foundation Tasks |
|-----------|-----------------|
| **Naheed** | Project creation, folder structure, `pubspec.yaml`, theme files, `app.dart`, `router.dart`, constants, env config, shared widgets (AppButton, AppTextField, LoadingSkeleton, ErrorStateWidget, EmptyStateWidget, ConfirmationDialog, AppSnackbar), `.gitignore`, `analysis_options.yaml` |
| **Arwah** | API client, interceptors (auth, retry, cookie), Failure classes, validators, AuthRepository, AuthCubit, Login screen, Register screen, Google OAuth, OTP verification screen, Forgot password screen |
| **Munaza** | ProductModel, CategoryModel, PricingModel, VariantModel, SellerModel, ReviewModel + JSON serialization, Home repository (with mock data), placeholder Home screen |
| **Nimra** | Shared widgets (ProductCard, PriceDisplay, RatingDisplay, QuantitySelector, AppImage, StatusBadge, OtpInput, AppSearchBar), storage wrappers, formatters, CartItem model, CartCubit (global, local storage), Cart screen (basic) |

All 4 developers work in parallel during Foundation Week. Naheed's project setup commit goes first (Day 1), then others branch from it.
