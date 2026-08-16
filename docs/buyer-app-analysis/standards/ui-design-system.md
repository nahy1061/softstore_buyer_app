# UI Design System

## Task 1 — Softstore Visual Identity

### Confirmed (From Website Source Code)

#### Colors

| Role | Hex | Usage |
|------|-----|-------|
| Primary | `#FF6F00` | CTAs, active states, links, app bar accent, primary buttons, price display |
| Primary Dark | `#E65100` | Pressed/hover states, "pending" status badge |
| Secondary / Accent | `#FFB300` | Highlights, star ratings, free delivery indicator, badges |
| Surface | `#FFFFFF` | Card backgrounds, bottom sheets, modals |
| Surface Alt | `#FAFAFA` | Alternate card surface |
| Background | `#F8F9FA` | Screen/page backgrounds |
| Text Primary | `#202124` | Headings, body text |
| Text Secondary | `#5F6368` | Captions, labels, descriptions, inactive states |
| Divider | `#E5E7EB` | Card borders, list separators |
| Error | `#B71C1C` | Error states, cancelled order status |
| Success | `#1B5E20` | Delivered status, success confirmations |
| Warning | `#E65100` | Low stock warnings (reuses primary dark) |

**Design rule from source:** No blue in the palette. Orange/amber on Material greys only.

#### Status Badge Colors

| Status | Color |
|--------|-------|
| Pending | `#FFB300` (amber) |
| Confirmed / Processing | `#FF6F00` (primary orange) |
| Shipped | `#E65100` (dark orange) |
| Delivered | `#1B5E20` (green) |
| Cancelled / Failed | `#B71C1C` (red) |
| Refunded | `#5F6368` (grey) |

#### Typography

| Font | Role |
|------|------|
| Inter | Body text, all general content |
| Google Sans | Headings, buttons, emphasis |
| Roboto Mono | Prices, invoice numbers, OTP digits |

| Element | Size | Weight |
|---------|------|--------|
| Screen title | 20sp | Bold |
| Section heading | 16sp | SemiBold |
| Product name (card) | 14sp | Medium |
| Product name (detail) | 18sp | Bold |
| Price (primary) | 18sp | Bold |
| Price (strikethrough) | 14sp | Regular |
| Body text | 14sp | Regular |
| Caption/label | 12sp | Medium |
| Button text | 14sp | SemiBold |
| Badge/chip | 12sp | Bold |

#### Spacing

| Context | Value |
|---------|-------|
| Screen horizontal padding | 16dp |
| Grid card gap | 8dp |
| List item gap | 12dp |
| Section separation | 24dp |
| Touch target minimum | 48×48dp |
| Touch target spacing | 8dp |

#### Border Radius

| Size | Value |
|------|-------|
| Small (chips, badges) | 10px |
| Medium (cards, inputs) | 14px |
| Large (bottom sheets, modals) | 20px |

#### Component Patterns

- **Primary button:** Orange `#FF6F00` bg, white text, 14sp SemiBold UPPERCASE, 48dp min height
- **Button pressed:** `#E65100` background
- **Product card (grid):** Image 60% height, name 1-line ellipsis, price, seller name, "Add" button
- **Product card (list):** Image 80px left, text details right
- **Sticky buy bar:** Fixed bottom bar on product detail with "Add to Cart" + "Buy Now"
- **Checkout stepper:** 3 steps: Cart → Delivery → Confirm
- **Filter/sort:** Bottom sheet (mobile)
- **Category chips:** Horizontal scrolling pills
- **Status badge:** Colored pill, 12sp bold text
- **OTP input:** 6 separate boxes, auto-advance

### Recommended (For Mobile App)

#### Additions Not in Website (Needed for Mobile)

| Token | Value | Reason |
|-------|-------|--------|
| Disabled button bg | `#E5E7EB` | Grey out non-interactive buttons |
| Disabled text | `#9AA0A6` | Faded text for disabled states |
| Overlay/scrim | `#000000` at 40% opacity | Behind bottom sheets, dialogs |
| Shimmer base | `#E5E7EB` | Skeleton loading base |
| Shimmer highlight | `#F5F6F7` | Skeleton loading animation |
| Card shadow | `0dp 2dp 8dp rgba(0,0,0,0.08)` | Subtle card elevation |
| FAB shadow | `0dp 4dp 12dp rgba(0,0,0,0.15)` | Floating button elevation |
| Snackbar bg | `#202124` | Dark snackbar background |
| Snackbar text | `#FFFFFF` | White text on dark snackbar |
| Badge (cart count) | `#B71C1C` on white text | Red notification dot/badge |

#### Additional Typography

| Element | Size | Weight | Reason |
|---------|------|--------|--------|
| Overline | 10sp | Medium | Tiny labels ("FREE DELIVERY", "NEW") |
| Price (cart total) | 20sp | Bold | Larger for summary totals |
| Empty state message | 16sp | Regular | Centered empty screens |
| Error message (inline) | 12sp | Regular | Below form fields |

#### Mobile-Specific Spacing

| Context | Value | Reason |
|---------|-------|--------|
| Bottom nav height | 56dp | Material standard |
| App bar height | 56dp | Material standard |
| FAB bottom offset | 16dp | Above bottom nav |
| Sticky bar height | 64dp | Product detail buy bar |
| Bottom sheet handle top padding | 12dp | Drag indicator spacing |

---

## Task 2 — Design System Architecture

### File Structure

```
lib/
└── core/
    └── theme/
        ├── app_theme.dart           # ThemeData construction (light + dark)
        ├── app_colors.dart          # All color constants
        ├── app_typography.dart      # TextStyle definitions
        ├── app_spacing.dart         # EdgeInsets, gaps, padding constants
        ├── app_dimensions.dart      # Border radius, elevation, sizes
        └── app_durations.dart       # Animation durations
```

This fits within the existing `core/` folder defined in `06-flutter-architecture.md`. No new layer — just a `theme/` subfolder inside `core/`.

### Design Tokens

#### `app_colors.dart`

```dart
abstract final class AppColors {
  // Brand
  static const primary = Color(0xFFFF6F00);
  static const primaryDark = Color(0xFFE65100);
  static const secondary = Color(0xFFFFB300);

  // Surfaces
  static const surface = Color(0xFFFFFFFF);
  static const surfaceAlt = Color(0xFFFAFAFA);
  static const background = Color(0xFFF8F9FA);

  // Text
  static const textPrimary = Color(0xFF202124);
  static const textSecondary = Color(0xFF5F6368);
  static const textDisabled = Color(0xFF9AA0A6);

  // Feedback
  static const error = Color(0xFFB71C1C);
  static const success = Color(0xFF1B5E20);
  static const warning = Color(0xFFE65100);

  // UI
  static const divider = Color(0xFFE5E7EB);
  static const disabled = Color(0xFFE5E7EB);
  static const shimmerBase = Color(0xFFE5E7EB);
  static const shimmerHighlight = Color(0xFFF5F6F7);
  static const scrim = Color(0x66000000);
  static const snackbar = Color(0xFF202124);
  static const badgeRed = Color(0xFFB71C1C);

  // Status (order-specific)
  static const statusPending = Color(0xFFFFB300);
  static const statusProcessing = Color(0xFFFF6F00);
  static const statusShipped = Color(0xFFE65100);
  static const statusDelivered = Color(0xFF1B5E20);
  static const statusCancelled = Color(0xFFB71C1C);
  static const statusRefunded = Color(0xFF5F6368);
}
```

#### `app_typography.dart`

```dart
abstract final class AppTypography {
  static const _inter = 'Inter';
  static const _googleSans = 'Google Sans';
  static const _robotoMono = 'Roboto Mono';

  // Headings (Google Sans)
  static final screenTitle = TextStyle(fontFamily: _googleSans, fontSize: 20, fontWeight: FontWeight.w700);
  static final sectionHeading = TextStyle(fontFamily: _googleSans, fontSize: 16, fontWeight: FontWeight.w600);

  // Body (Inter)
  static final bodyLarge = TextStyle(fontFamily: _inter, fontSize: 16, fontWeight: FontWeight.w400);
  static final bodyMedium = TextStyle(fontFamily: _inter, fontSize: 14, fontWeight: FontWeight.w400);
  static final bodySmall = TextStyle(fontFamily: _inter, fontSize: 12, fontWeight: FontWeight.w400);

  // Labels (Inter)
  static final labelLarge = TextStyle(fontFamily: _inter, fontSize: 14, fontWeight: FontWeight.w600);
  static final labelMedium = TextStyle(fontFamily: _inter, fontSize: 12, fontWeight: FontWeight.w500);
  static final labelSmall = TextStyle(fontFamily: _inter, fontSize: 10, fontWeight: FontWeight.w500);

  // Product-specific
  static final productName = TextStyle(fontFamily: _inter, fontSize: 14, fontWeight: FontWeight.w500);
  static final productNameDetail = TextStyle(fontFamily: _googleSans, fontSize: 18, fontWeight: FontWeight.w700);
  static final pricePrimary = TextStyle(fontFamily: _robotoMono, fontSize: 18, fontWeight: FontWeight.w700);
  static final priceStrikethrough = TextStyle(fontFamily: _robotoMono, fontSize: 14, fontWeight: FontWeight.w400, decoration: TextDecoration.lineThrough);
  static final priceTotal = TextStyle(fontFamily: _robotoMono, fontSize: 20, fontWeight: FontWeight.w700);

  // Button (Google Sans)
  static final buttonText = TextStyle(fontFamily: _googleSans, fontSize: 14, fontWeight: FontWeight.w600);

  // Badge (Inter)
  static final badge = TextStyle(fontFamily: _inter, fontSize: 12, fontWeight: FontWeight.w700);
}
```

#### `app_spacing.dart`

```dart
abstract final class AppSpacing {
  // Base unit: 4dp
  static const xs = 4.0;
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;
  static const xxl = 32.0;

  // Screen padding
  static const screenHorizontal = EdgeInsets.symmetric(horizontal: 16.0);
  static const screenAll = EdgeInsets.all(16.0);

  // Card/list gaps
  static const gridGap = 8.0;
  static const listGap = 12.0;
  static const sectionGap = 24.0;
}
```

#### `app_dimensions.dart`

```dart
abstract final class AppDimensions {
  // Border radius
  static final radiusSm = BorderRadius.circular(10);
  static final radiusMd = BorderRadius.circular(14);
  static final radiusLg = BorderRadius.circular(20);

  // Elevation
  static const elevationCard = 2.0;
  static const elevationSheet = 8.0;
  static const elevationFab = 6.0;

  // Sizes
  static const touchTarget = 48.0;
  static const bottomNavHeight = 56.0;
  static const appBarHeight = 56.0;
  static const stickyBarHeight = 64.0;
  static const productImageRatio = 0.6; // 60% of card height
  static const listImageSize = 80.0;

  // Shadows
  static final cardShadow = [
    BoxShadow(color: Color(0x14000000), blurRadius: 8, offset: Offset(0, 2)),
  ];
  static final sheetShadow = [
    BoxShadow(color: Color(0x26000000), blurRadius: 16, offset: Offset(0, -4)),
  ];
}
```

#### `app_durations.dart`

```dart
abstract final class AppDurations {
  static const instant = Duration(milliseconds: 100);
  static const fast = Duration(milliseconds: 200);
  static const normal = Duration(milliseconds: 300);
  static const slow = Duration(milliseconds: 450);
  static const pageTransition = Duration(milliseconds: 300);
  static const shimmer = Duration(milliseconds: 1500);
  static const snackbar = Duration(seconds: 3);
  static const debounce = Duration(milliseconds: 300);
}
```

### How Developers Access the Design System

**Rule:** Never use raw values. Always reference design system constants.

```dart
// WRONG
Container(
  padding: EdgeInsets.all(16),
  decoration: BoxDecoration(
    color: Color(0xFFFF6F00),
    borderRadius: BorderRadius.circular(14),
  ),
  child: Text('Hello', style: TextStyle(fontSize: 14)),
)

// CORRECT
Container(
  padding: AppSpacing.screenAll,
  decoration: BoxDecoration(
    color: AppColors.primary,
    borderRadius: AppDimensions.radiusMd,
  ),
  child: Text('Hello', style: AppTypography.bodyMedium),
)
```

**For theme-aware colors** (colors that change in dark mode), use `Theme.of(context).colorScheme`:
```dart
// For elements that must adapt to light/dark
final colors = Theme.of(context).colorScheme;
Container(color: colors.surface)
```

**For fixed brand colors** (orange stays orange in both modes), use `AppColors` directly:
```dart
// Brand colors never change
Text('Rs 500', style: AppTypography.pricePrimary.copyWith(color: AppColors.primary))
```

---

## Task 3 — App Theme Architecture

### ThemeData Structure (`app_theme.dart`)

```dart
abstract final class AppTheme {
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: _lightColorScheme,
    textTheme: _textTheme,
    appBarTheme: _appBarTheme,
    bottomNavigationBarTheme: _bottomNavTheme,
    cardTheme: _cardTheme,
    elevatedButtonTheme: _elevatedButtonTheme,
    outlinedButtonTheme: _outlinedButtonTheme,
    textButtonTheme: _textButtonTheme,
    inputDecorationTheme: _inputTheme,
    bottomSheetTheme: _bottomSheetTheme,
    dialogTheme: _dialogTheme,
    snackBarTheme: _snackBarTheme,
    dividerTheme: _dividerTheme,
    scaffoldBackgroundColor: AppColors.background,
    splashColor: AppColors.primary.withOpacity(0.1),
    highlightColor: AppColors.primary.withOpacity(0.05),
  );
}
```

### Light Color Scheme

```dart
static final _lightColorScheme = ColorScheme(
  brightness: Brightness.light,
  primary: AppColors.primary,
  onPrimary: Colors.white,
  primaryContainer: AppColors.primary.withOpacity(0.1),
  secondary: AppColors.secondary,
  onSecondary: AppColors.textPrimary,
  surface: AppColors.surface,
  onSurface: AppColors.textPrimary,
  error: AppColors.error,
  onError: Colors.white,
  outline: AppColors.divider,
);
```

### Component Themes

#### AppBar
```dart
static final _appBarTheme = AppBarTheme(
  backgroundColor: AppColors.surface,
  foregroundColor: AppColors.textPrimary,
  elevation: 0,
  scrolledUnderElevation: 1,
  centerTitle: false,
  titleTextStyle: AppTypography.screenTitle.copyWith(color: AppColors.textPrimary),
);
```

#### Bottom Navigation
```dart
static final _bottomNavTheme = BottomNavigationBarThemeData(
  backgroundColor: AppColors.surface,
  selectedItemColor: AppColors.primary,
  unselectedItemColor: AppColors.textSecondary,
  type: BottomNavigationBarType.fixed,
  elevation: 8,
  selectedLabelStyle: AppTypography.labelSmall,
  unselectedLabelStyle: AppTypography.labelSmall,
);
```

#### Elevated Button (Primary CTA)
```dart
static final _elevatedButtonTheme = ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    minimumSize: Size(double.infinity, AppDimensions.touchTarget),
    shape: RoundedRectangleBorder(borderRadius: AppDimensions.radiusSm),
    textStyle: AppTypography.buttonText,
    elevation: 0,
  ),
);
```

#### Outlined Button (Secondary CTA)
```dart
static final _outlinedButtonTheme = OutlinedButtonThemeData(
  style: OutlinedButton.styleFrom(
    foregroundColor: AppColors.primary,
    minimumSize: Size(double.infinity, AppDimensions.touchTarget),
    shape: RoundedRectangleBorder(borderRadius: AppDimensions.radiusSm),
    side: BorderSide(color: AppColors.primary),
    textStyle: AppTypography.buttonText,
  ),
);
```

#### Text Button
```dart
static final _textButtonTheme = TextButtonThemeData(
  style: TextButton.styleFrom(
    foregroundColor: AppColors.primary,
    textStyle: AppTypography.labelLarge,
    minimumSize: Size(48, 48),
  ),
);
```

#### Input Decoration
```dart
static final _inputTheme = InputDecorationTheme(
  filled: true,
  fillColor: AppColors.surfaceAlt,
  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  border: OutlineInputBorder(
    borderRadius: AppDimensions.radiusMd,
    borderSide: BorderSide(color: AppColors.divider),
  ),
  enabledBorder: OutlineInputBorder(
    borderRadius: AppDimensions.radiusMd,
    borderSide: BorderSide(color: AppColors.divider),
  ),
  focusedBorder: OutlineInputBorder(
    borderRadius: AppDimensions.radiusMd,
    borderSide: BorderSide(color: AppColors.primary, width: 1.5),
  ),
  errorBorder: OutlineInputBorder(
    borderRadius: AppDimensions.radiusMd,
    borderSide: BorderSide(color: AppColors.error),
  ),
  labelStyle: AppTypography.labelMedium.copyWith(color: AppColors.textSecondary),
  hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
  errorStyle: AppTypography.bodySmall.copyWith(color: AppColors.error),
);
```

#### Card
```dart
static final _cardTheme = CardThemeData(
  color: AppColors.surface,
  elevation: 0,
  shape: RoundedRectangleBorder(
    borderRadius: AppDimensions.radiusMd,
    side: BorderSide(color: AppColors.divider, width: 0.5),
  ),
  margin: EdgeInsets.zero,
);
```

#### Bottom Sheet
```dart
static final _bottomSheetTheme = BottomSheetThemeData(
  backgroundColor: AppColors.surface,
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
  ),
  showDragHandle: true,
  dragHandleColor: AppColors.divider,
);
```

#### Dialog
```dart
static final _dialogTheme = DialogThemeData(
  backgroundColor: AppColors.surface,
  shape: RoundedRectangleBorder(borderRadius: AppDimensions.radiusLg),
  titleTextStyle: AppTypography.sectionHeading.copyWith(color: AppColors.textPrimary),
  contentTextStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
);
```

#### Snackbar
```dart
static final _snackBarTheme = SnackBarThemeData(
  backgroundColor: AppColors.snackbar,
  contentTextStyle: AppTypography.bodyMedium.copyWith(color: Colors.white),
  behavior: SnackBarBehavior.floating,
  shape: RoundedRectangleBorder(borderRadius: AppDimensions.radiusSm),
  insetPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
);
```

### Dark Mode Decision

**Decision: NOT in MVP. Planned for Phase 2 post-launch.**

**Reasoning:**
1. Softstore's website has no dark mode — brand identity is defined on white/light grey
2. MVP scope is already 11 weeks with 4 devs — adding dark mode doubles the QA surface for visual bugs
3. The architecture supports dark mode trivially (just add `AppTheme.dark` later) — it's not blocked
4. Pakistani e-commerce apps (Daraz, FoodPanda) shipped without dark mode initially

**Preparation for future dark mode:**
- All colors accessed via `AppColors` constants (change once, apply everywhere)
- Theme-aware colors via `Theme.of(context).colorScheme` where needed
- No hardcoded `Colors.white` or `Colors.black` in feature code
- When dark mode is added: define `_darkColorScheme`, add `AppTheme.dark`, and the app adapts

### Theme Usage in App

```dart
// app.dart
MaterialApp.router(
  theme: AppTheme.light,
  // darkTheme: AppTheme.dark,  // Phase 2
  // themeMode: ThemeMode.system, // Phase 2
  routerConfig: router,
)
```

---

## Task 6 — Responsive & Accessible UI

### Screen Size Strategy

**Decision: Phone-only layout. No tablet optimization in MVP.**

Softstore is a Pakistani marketplace. Target devices:
- Budget/mid-range Android: 360–412dp width (most common)
- iPhone SE to iPhone 15 Pro Max: 375–430dp width
- Tablets: Not in scope (negligible traffic for Pakistani e-commerce)

### Layout Rules

| Rule | Value | Reason |
|------|-------|--------|
| Min supported width | 320dp | Oldest supported devices |
| Design target width | 375dp | iPhone SE / most Android midrange |
| Product grid columns | Always 2 | Consistent across all phone sizes |
| Max content width | None (stretch) | Phone-only, no need to constrain |
| Orientation | Portrait locked | Shopping apps don't benefit from landscape |

### Safe Areas

```dart
// Every screen wraps content in SafeArea
SafeArea(
  bottom: false, // Bottom nav handles its own safe area
  child: screenContent,
)
```

- Top: SafeArea for status bar
- Bottom: Bottom nav bar sits above system gesture area (handled by Scaffold)
- Screens with sticky bottom bars (product detail, cart): padding above system nav

### Keyboard Handling

| Situation | Behavior |
|-----------|----------|
| Form screen | `resizeToAvoidBottomInset: true` (default) — screen scrolls up |
| Checkout form | Scroll to focused field automatically |
| OTP screen | Auto-focus first box, keyboard type: number |
| Search | Auto-focus search field on screen open |
| Bottom sheet with input | Sheet rises above keyboard |

### Touch Targets

| Rule | Value |
|------|-------|
| Minimum tappable area | 48×48dp |
| Minimum spacing between targets | 8dp |
| Icon button padding | Built into Flutter's IconButton (48dp default) |
| List item minimum height | 56dp |
| Chip minimum height | 32dp (with 48dp tap area via padding) |

### Text Scaling

```dart
// Respect system font size but cap at 1.3x to prevent layout breaks
MediaQuery(
  data: MediaQuery.of(context).copyWith(
    textScaler: TextScaler.linear(
      MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.3),
    ),
  ),
  child: child,
)
```

- Support up to 130% system font scaling
- Beyond 130%: text truncates with ellipsis rather than breaking layout
- Price displays and badges use fixed size (no scaling) to maintain layout integrity

### Accessibility

| Requirement | Implementation |
|-------------|----------------|
| Semantic labels | All `Icon`, `Image`, custom widgets get `Semantics` or `semanticLabel` |
| Button semantics | ElevatedButton/TextButton already semantic; custom buttons need `Semantics(button: true)` |
| Image alt text | Product images: `semanticLabel: product.name` |
| Contrast ratio | All text/bg combos meet WCAG AA (4.5:1 normal, 3:1 large) |
| Focus order | Natural reading order (top-to-bottom, left-to-right) |
| Error announcement | Form errors announced via `Semantics(liveRegion: true)` |
| Reduce motion | Check `MediaQuery.of(context).disableAnimations` — skip non-essential animations |

### Contrast Verification

| Combination | Ratio | Pass? |
|-------------|-------|-------|
| `#202124` on `#FFFFFF` | 16.6:1 | AA |
| `#5F6368` on `#FFFFFF` | 5.9:1 | AA |
| `#FFFFFF` on `#FF6F00` | 3.5:1 | AA (large text only) |
| `#FFFFFF` on `#E65100` | 4.6:1 | AA |
| `#FFFFFF` on `#B71C1C` | 5.9:1 | AA |
| `#FFFFFF` on `#1B5E20` | 7.4:1 | AA |

Note: White text on primary orange (`#FF6F00`) passes for large/bold text (buttons at 14sp SemiBold). For small text on orange background, use dark text (`#202124`) instead.

---

## Task 7 — Animation & Interaction Guidelines

### When to Animate

| Interaction | Animation | Duration | Curve |
|-------------|-----------|----------|-------|
| Page transition (push) | Slide from right | 300ms | `easeInOut` |
| Page transition (pop) | Slide to right | 300ms | `easeInOut` |
| Bottom sheet open | Slide up | 300ms | `easeOut` |
| Bottom sheet close | Slide down | 200ms | `easeIn` |
| Dialog appear | Fade + scale (0.95→1.0) | 200ms | `easeOut` |
| Button press feedback | Ripple (Material default) | — | — |
| Add to cart | Brief scale bounce on cart icon | 200ms | `elasticOut` |
| Wishlist toggle | Heart fill animation | 200ms | `easeOut` |
| Skeleton shimmer | Gradient sweep | 1500ms loop | `linear` |
| Snackbar appear | Slide up + fade | 200ms | `easeOut` |
| Snackbar dismiss | Fade out | 150ms | `easeIn` |
| Tab switch (bottom nav) | Fade crossfade | 200ms | `easeInOut` |
| Pull-to-refresh | Material refresh indicator | Built-in | — |
| Loading button | Spinner replaces text | instant | — |
| Success checkmark (order placed) | Draw path + scale | 450ms | `easeOut` |

### When NOT to Animate

- Product grid scroll (should be 60fps, no per-item animation)
- Form field focus (border color change is enough)
- Navigation between checkout steps (just slide, no fancy transitions)
- Data refresh in background (no visual indication unless user-initiated)
- Error state appearance (show immediately, don't animate)

### Implementation Pattern

```dart
// Use AppDurations constants, not raw milliseconds
AnimatedContainer(
  duration: AppDurations.fast,
  curve: Curves.easeOut,
  // ...
)

// For complex sequences, use AnimationController
// But prefer implicit animations (AnimatedX widgets) for simple cases
```

### Reduce Motion Support

```dart
// Check user preference
final reduceMotion = MediaQuery.of(context).disableAnimations;

// If reduce motion is on: skip non-essential animations, use instant transitions
AnimatedContainer(
  duration: reduceMotion ? Duration.zero : AppDurations.normal,
  // ...
)
```

### Rules

1. **No animation without purpose.** Every animation must either: provide spatial context (where something came from/goes to), confirm an action (cart bounce), or reduce perceived latency (skeleton shimmer).
2. **Keep it fast.** Nothing over 450ms except shimmer loops.
3. **No animation on data load.** When products load into the grid, they just appear. No stagger, no fade-in-one-by-one (kills perceived performance).
4. **Respect system settings.** If `disableAnimations` is true, skip everything except loading indicators.
