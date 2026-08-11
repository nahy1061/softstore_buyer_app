import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../app/router.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  // Empty list to show the empty state from your design
  final List<dynamic> items = []; 

  @override
  Widget build(BuildContext context) {
    // Scaffold and SafeArea are removed because they are provided by AppShell 
    // to keep the header and footer consistent across the application.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 1. Breadcrumbs
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.xs),
          child: Row(
            children: [
              Text(
                'Marketplace',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
              ),
              const Icon(Icons.chevron_right, size: 14, color: AppColors.textSecondary),
              Text(
                'Cart',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),

        // 2. Content Title
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Text(
            'Your cart',
            style: AppTypography.screenTitle.copyWith(
              fontSize: 24,
              color: AppColors.textPrimary,
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // 3. Progress Stepper
        const _CartProgressIndicator(currentStep: 1),

        const SizedBox(height: AppSpacing.xl),

        // 4. Content (Empty State)
        Expanded(
          child: items.isEmpty 
              ? const _EmptyCartState() 
              : const Center(child: Text("Cart Items List")),
        ),
      ],
    );
  }
}

class _CartProgressIndicator extends StatelessWidget {
  final int currentStep;
  const _CartProgressIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      child: Row(
        children: [
          _buildStep(1, isActive: currentStep >= 1),
          _buildLine(isActive: currentStep > 1),
          _buildStep(2, isActive: currentStep >= 2),
          _buildLine(isActive: currentStep > 2),
          _buildStep(3, isActive: currentStep >= 3),
        ],
      ),
    );
  }

  Widget _buildStep(int number, {required bool isActive}) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: isActive ? AppColors.primary : AppColors.background,
        shape: BoxShape.circle,
        border: isActive ? null : Border.all(color: AppColors.divider),
      ),
      child: Center(
        child: Text(
          '$number',
          style: AppTypography.labelMedium.copyWith(
            color: isActive ? Colors.white : AppColors.textDisabled,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildLine({required bool isActive}) {
    return Expanded(
      child: Container(
        height: 1,
        margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        color: isActive ? AppColors.primary : AppColors.divider,
      ),
    );
  }
}

class _EmptyCartState extends StatelessWidget {
  const _EmptyCartState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxl, horizontal: AppSpacing.xl),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppDimensions.radiusMd,
          border: Border.all(color: AppColors.divider.withOpacity(0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Shopping Bag Icon in Rounded Square
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF), // Light blue tint
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Icon(
                  Icons.shopping_bag_outlined,
                  size: 32,
                  color: Color(0xFF92400E), // Brownish tint icon
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xl),

            // Text content
            Text(
              'Your cart is empty',
              style: AppTypography.sectionHeading.copyWith(
                fontSize: 18,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Browse the marketplace and add\nsomething you like.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),

            // Browse Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () => context.go(AppRoutes.home),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                child: const Text('Browse the marketplace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
