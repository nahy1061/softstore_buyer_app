# Rule: UI Design System & Styling Guidelines

This rule defines the strict UI and Design System standards for SoftStore Buyer App.

## 1. Design Token Centralization

All design tokens are strictly defined in `lib/core/theme/`. **Never hardcode values inline.**

### Colors (`lib/core/theme/app_colors.dart`)
* **Primary Brand**: `AppColors.primary` (`#FF6F00` - Amber/Orange), `AppColors.primaryDark` (`#E65100`), `AppColors.secondary` (`#FFB300`).
* **Backgrounds & Surfaces**: `AppColors.background` (`#F8F9FA`), `AppColors.surface` (`#FFFFFF`), `AppColors.cardBackground`.
* **Text**: `AppColors.textPrimary` (`#202124`), `AppColors.textSecondary` (`#5F6368`), `AppColors.textDisabled` (`#9AA0A6`).
* **Semantic Feedback**: `AppColors.error` (`#B71C1C`), `AppColors.success` (`#1B5E20`), `AppColors.warning` (`#E65100`), `AppColors.info` (`#0D47A1`).
* **Borders & Dividers**: `AppColors.border` (`#E0E0E0`), `AppColors.divider` (`#EEEEEE`).

### Spacing (`lib/core/theme/app_spacing.dart`)
* `AppSpacing.xs` (4.0), `AppSpacing.sm` (8.0), `AppSpacing.md` (12.0), `AppSpacing.lg` (16.0), `AppSpacing.xl` (20.0), `AppSpacing.xxl` (24.0), `AppSpacing.xxxl` (32.0).
* Standard horizontal screen padding: `AppSpacing.paddingHorizontal` or `EdgeInsets.symmetric(horizontal: AppSpacing.lg)`.
* Standard vertical item gap: `SizedBox(height: AppSpacing.md)` or `AppSpacing.gapVerticalMd`.

### Typography (`lib/core/theme/app_typography.dart`)
* Headings: `AppTypography.heading1`, `AppTypography.heading2`, `AppTypography.heading3`.
* Body Text: `AppTypography.bodyLarge`, `AppTypography.bodyMedium`, `AppTypography.bodySmall`.
* Price & Numbers: `AppTypography.priceLarge`, `AppTypography.priceMedium`, `AppTypography.priceSmall` (using Roboto Mono / monospace).
* Captions & Badges: `AppTypography.caption`, `AppTypography.badge`.

### Dimensions & Radius (`lib/core/theme/app_dimensions.dart`)
* Border Radius: `AppDimensions.radiusSm` (4.0), `AppDimensions.radiusMd` (8.0), `AppDimensions.radiusLg` (12.0), `AppDimensions.radiusXl` (16.0), `AppDimensions.radiusFull` (999.0).
* Button Heights: `AppDimensions.buttonHeightSm` (36.0), `AppDimensions.buttonHeightMd` (44.0), `AppDimensions.buttonHeightLg` (52.0).
* Card Elevation: `AppDimensions.elevationNone` (0.0), `AppDimensions.elevationSm` (1.0), `AppDimensions.elevationMd` (2.0).

---

## 2. Reusable Core UI Components

Always inspect `lib/core/widgets/` before building any UI component. Reuse existing components:
* `AppButton` (Primary, Secondary, Outline, Text variants)
* `AppTextField` / `AppSearchField`
* `AppCard` / `AppListTile`
* `AppBadge` / `AppChip`
* `AppLoadingIndicator` / `AppShimmer`
* `AppEmptyState` / `AppErrorState`
* `AppPriceTag`
* `AppAppBar` / `AppBottomNavBar`

---

## 3. UI State Handling Pattern

Every screen must explicitly handle 4 visual states:
1. **Loading**: Show shimmer or centered loading spinner.
2. **Success / Content**: Render the actual data list/view.
3. **Empty**: Show standard `AppEmptyState` with a helpful message and action button.
4. **Error**: Show standard `AppErrorState` with retry button.
