// ─────────────────────────────────────────────────────────────────────────────
// DealsScreen — Sponsors & Deals hub.
// Reached by tapping the center "S" circle in the bottom nav bar.
// Shows sponsor banners at the top, then a grid of discounted deal products.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_bottom_nav_bar.dart';

class DealsScreen extends StatelessWidget {
  const DealsScreen({super.key});

  // ── Mock sponsor data ─────────────────────────────────────────────────────
  static const List<_SponsorData> _sponsors = [
    _SponsorData(
      name: 'TechZone',
      tagline: 'Up to 40% off on Electronics',
      icon: Icons.devices,
      color: Color(0xFF1565C0),
    ),
    _SponsorData(
      name: 'FashionHub',
      tagline: 'New arrivals — Buy 2 Get 1 Free',
      icon: Icons.checkroom,
      color: Color(0xFF6A1B9A),
    ),
    _SponsorData(
      name: 'HomeNest',
      tagline: 'Furniture flash sale — 50% off',
      icon: Icons.chair,
      color: Color(0xFF2E7D32),
    ),
  ];

  // ── Mock deal products ────────────────────────────────────────────────────
  static const List<_DealProduct> _deals = [
    _DealProduct(name: 'Wireless Headphones', originalPrice: 8000, dealPrice: 4500, discount: 44, icon: Icons.headphones),
    _DealProduct(name: 'Smart Watch', originalPrice: 18000, dealPrice: 10999, discount: 39, icon: Icons.watch),
    _DealProduct(name: 'Mechanical Keyboard', originalPrice: 11000, dealPrice: 7500, discount: 32, icon: Icons.keyboard),
    _DealProduct(name: 'Running Shoes', originalPrice: 6500, dealPrice: 3999, discount: 38, icon: Icons.directions_run),
    _DealProduct(name: 'Coffee Maker', originalPrice: 9000, dealPrice: 5500, discount: 39, icon: Icons.coffee),
    _DealProduct(name: 'Backpack Pro', originalPrice: 5000, dealPrice: 2999, discount: 40, icon: Icons.backpack),
    _DealProduct(name: 'Sunglasses', originalPrice: 3500, dealPrice: 1799, discount: 49, icon: Icons.wb_sunny),
    _DealProduct(name: 'Bluetooth Speaker', originalPrice: 7000, dealPrice: 4299, discount: 39, icon: Icons.speaker),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,

      // ── App bar ──────────────────────────────────────────────────────────
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        title: Row(
          children: [
            // S logo badge in app bar
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Center(
                child: Text(
                  'S',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                    height: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Text(
              'Deals & Sponsors',
              style: AppTypography.screenTitle.copyWith(color: Colors.white),
            ),
          ],
        ),
      ),

      // ── Center S nav tab index = 2 ────────────────────────────────────────
      bottomNavigationBar: const AppBottomNavBar(currentIndex: 2),

      body: CustomScrollView(
        slivers: [

          // ── Header banner ────────────────────────────────────────────────
          SliverToBoxAdapter(child: _HeaderBanner()),

          // ── Sponsors section ─────────────────────────────────────────────
          const SliverToBoxAdapter(child: _SectionTitle(title: 'Our Sponsors')),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 110,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                itemCount: _sponsors.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(width: AppSpacing.md),
                itemBuilder: (context, i) => _SponsorCard(data: _sponsors[i]),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.lg)),

          // ── Flash deals section ──────────────────────────────────────────
          const SliverToBoxAdapter(child: _SectionTitle(title: 'Flash Deals')),
          SliverPadding(
            padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md, vertical: AppSpacing.sm),
            sliver: SliverGrid(
              delegate: SliverChildBuilderDelegate(
                (context, i) => _DealCard(deal: _deals[i]),
                childCount: _deals.length,
              ),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: AppSpacing.sm,
                mainAxisSpacing: AppSpacing.sm,
              ),
            ),
          ),

          // Bottom breathing room
          const SliverToBoxAdapter(child: SizedBox(height: AppSpacing.xl)),
        ],
      ),
    );
  }
}

// ── Header gradient banner ────────────────────────────────────────────────────
class _HeaderBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 140,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.secondary, AppColors.primary, AppColors.primaryDark],
        ),
      ),
      child: Stack(
        children: [
          // Background decorative circles
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: 40,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Exclusive Deals',
                  style: AppTypography.screenTitle.copyWith(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Handpicked offers from our sponsors',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withValues(alpha: 0.4), width: 1),
                  ),
                  child: Text(
                    'Limited time offers',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section title row ─────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.sm),
      child: Text(
        title,
        style: AppTypography.sectionHeading,
      ),
    );
  }
}

// ── Sponsor card (horizontal scroll) ─────────────────────────────────────────
class _SponsorCard extends StatelessWidget {
  final _SponsorData data;
  const _SponsorCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.divider),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Sponsor icon circle
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: data.color.withValues(alpha: 0.1),
            ),
            child: Icon(data.icon, color: data.color, size: 24),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  data.name,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  data.tagline,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Deal product card (grid) ──────────────────────────────────────────────────
class _DealCard extends StatelessWidget {
  final _DealProduct deal;
  const _DealCard({required this.deal});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.divider),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Product icon area
          Expanded(
            child: Container(
              width: double.infinity,
              color: AppColors.background,
              child: Stack(
                children: [
                  Center(
                    child:
                        Icon(deal.icon, size: 56, color: AppColors.primary),
                  ),
                  // Discount badge
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primaryDark,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '-${deal.discount}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Product info
          Padding(
            padding:
                const EdgeInsets.fromLTRB(AppSpacing.sm, AppSpacing.sm, AppSpacing.sm, AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  deal.name,
                  style: AppTypography.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                // Deal price
                Text(
                  'PKR ${deal.dealPrice}',
                  style: AppTypography.pricePrimary.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // Original (strikethrough)
                Text(
                  'PKR ${deal.originalPrice}',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textDisabled,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Data classes ──────────────────────────────────────────────────────────────

class _SponsorData {
  final String name;
  final String tagline;
  final IconData icon;
  final Color color;
  const _SponsorData({
    required this.name,
    required this.tagline,
    required this.icon,
    required this.color,
  });
}

class _DealProduct {
  final String name;
  final int originalPrice;
  final int dealPrice;
  final int discount;
  final IconData icon;
  const _DealProduct({
    required this.name,
    required this.originalPrice,
    required this.dealPrice,
    required this.discount,
    required this.icon,
  });
}
