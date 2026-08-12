// ─────────────────────────────────────────────────────────────────────────────
// AppBottomNavBar — shared bottom navigation bar with an elevated animated
// glass "S" logo button in the center that overlaps above the bar.
//
// TAB INDEX MAPPING:
//   0 = Marketplace    (left-most)
//   1 = Orders         (second left)
//   2 = Deals/Sponsors (center circle — special animated button)
//   3 = Cart           (second right)
//   4 = Profile        (right-most)
//
// ANIMATIONS on the S circle:
//   • Two staggered sonar pulse rings expand outward and fade in a loop
//   • A diagonal shine streak sweeps across the glass face every 4 s
//   • A static top-arc highlight simulates light hitting a glass sphere
//   • A frost overlay (semi-transparent gradient) gives the glass look
//   • Tap triggers a scale-bounce: shrink → overshoot → settle
//
// HOW TO USE:
//   bottomNavigationBar: AppBottomNavBar(currentIndex: 0)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../app/router.dart';
import '../../features/cart/cubit/cart_cubit.dart';
import '../../features/cart/cubit/cart_state.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class AppBottomNavBar extends StatelessWidget {
  /// Active tab index (0–4). Pass 2 when on the Deals screen.
  final int currentIndex;

  static const double _barHeight     = 60.0;
  static const double _circleOverlap = 22.0; // how far circle pops above bar
  static const double circleSize     = 58.0; // public so _AnimatedSLogo can read it

  const AppBottomNavBar({super.key, required this.currentIndex});

  void _navigate(BuildContext context, int index) {
    switch (index) {
      case 0: context.go(AppRoutes.home);    break;
      case 1: context.go(AppRoutes.orders);  break;
      case 2: context.go(AppRoutes.deals);   break;
      case 3: context.go(AppRoutes.cart);    break;
      case 4: context.go(AppRoutes.profile); break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cartState) {
        // SizedBox tells the Scaffold the bar is only _barHeight tall.
        // The animated circle overflows upward via Stack(clip:none).
        return SizedBox(
          height: _barHeight,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.topCenter,
            children: [

              // ── Flat bar with 4 nav items ──────────────────────────────────
              Positioned.fill(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Divider(height: 1, color: AppColors.divider),
                    Expanded(
                      child: Container(
                        color: AppColors.surface,
                        child: Row(
                          children: [
                            // Left pair
                            _NavItem(
                              icon: Icons.storefront_outlined,
                              activeIcon: Icons.storefront,
                              label: 'Marketplace',
                              index: 0,
                              currentIndex: currentIndex,
                              onTap: () => _navigate(context, 0),
                            ),
                            _NavItem(
                              icon: Icons.receipt_long_outlined,
                              activeIcon: Icons.receipt_long,
                              label: 'Orders',
                              index: 1,
                              currentIndex: currentIndex,
                              onTap: () => _navigate(context, 1),
                            ),

                            // Gap reserved for the elevated S circle
                            SizedBox(width: circleSize + 8),

                            // Right pair
                            _NavItem(
                              icon: Icons.shopping_cart_outlined,
                              activeIcon: Icons.shopping_cart,
                              label: 'Cart',
                              index: 3,
                              currentIndex: currentIndex,
                              badge: cartState.itemCount > 0
                                  ? '${cartState.itemCount}'
                                  : null,
                              onTap: () => _navigate(context, 3),
                            ),
                            _NavItem(
                              icon: Icons.person_outline,
                              activeIcon: Icons.person,
                              label: 'Profile',
                              index: 4,
                              currentIndex: currentIndex,
                              onTap: () => _navigate(context, 4),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Animated S circle (overlaps above the bar) ────────────────
              Positioned(
                top: -_circleOverlap,
                child: _AnimatedSLogo(
                  onTap: () => _navigate(context, 2),
                  isActive: currentIndex == 2,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _AnimatedSLogo — the animated glass S button.
//
// Three independent AnimationControllers run simultaneously:
//   _pulseCtrl  – drives two staggered sonar rings (phase offset 0.5)
//   _shineCtrl  – drives the diagonal streak that sweeps across the face
//   _tapCtrl    – drives the scale-bounce on tap
// ─────────────────────────────────────────────────────────────────────────────
class _AnimatedSLogo extends StatefulWidget {
  final VoidCallback onTap;
  final bool isActive; // true when the Deals screen is open

  const _AnimatedSLogo({required this.onTap, required this.isActive});

  @override
  State<_AnimatedSLogo> createState() => _AnimatedSLogoState();
}

class _AnimatedSLogoState extends State<_AnimatedSLogo>
    with TickerProviderStateMixin {

  static const double _size = AppBottomNavBar.circleSize;

  // ── Sonar pulse rings ─────────────────────────────────────────────────────
  // One controller drives both rings; the second ring uses (value + 0.5) % 1.0
  // so the two rings are always half a cycle apart → continuous sonar feel.
  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat();

  // ── Shine sweep ───────────────────────────────────────────────────────────
  // Maps 0→1 to an x-offset from -_size to +_size*1.6
  // so the streak enters from left, crosses the face, and exits right.
  late final AnimationController _shineCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4000),
  )..repeat();

  // ── Tap bounce ────────────────────────────────────────────────────────────
  // Shrink → overshoot → settle in 280 ms.
  late final AnimationController _tapCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 280),
  );
  late final Animation<double> _tapScale = TweenSequence<double>([
    TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.84), weight: 35),
    TweenSequenceItem(tween: Tween(begin: 0.84, end: 1.10), weight: 40),
    TweenSequenceItem(tween: Tween(begin: 1.10, end: 1.0),  weight: 25),
  ]).animate(CurvedAnimation(parent: _tapCtrl, curve: Curves.easeInOut));

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _shineCtrl.dispose();
    _tapCtrl.dispose();
    super.dispose();
  }

  void _handleTap() {
    // Play bounce first, then navigate after the animation finishes
    _tapCtrl.forward(from: 0).then((_) => widget.onTap());
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: AnimatedBuilder(
        animation: Listenable.merge([_pulseCtrl, _shineCtrl, _tapCtrl]),
        builder: (context, _) {

          // ── Pulse ring values ─────────────────────────────────────────────
          // Ring A: grows from 1.0→1.48 and fades from 0.55→0
          final ringAScale   = 1.0 + _pulseCtrl.value * 0.48;
          final ringAOpacity = (1.0 - _pulseCtrl.value) * 0.55;

          // Ring B: half-phase offset so it pulses between the gaps of ring A
          final ringBProgress = (_pulseCtrl.value + 0.5) % 1.0;
          final ringBScale    = 1.0 + ringBProgress * 0.48;
          final ringBOpacity  = (1.0 - ringBProgress) * 0.38;

          // ── Shine streak x-position ───────────────────────────────────────
          // Eased so it accelerates in, slows near center, then exits
          final shineProgress = Curves.easeInOut.transform(_shineCtrl.value);
          final shineX = (shineProgress * 2.6 - 0.5) * _size;

          return Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [

              // ── Sonar ring A ───────────────────────────────────────────────
              Transform.scale(
                scale: ringAScale,
                child: Container(
                  width: _size,
                  height: _size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: ringAOpacity),
                      width: 2.0,
                    ),
                  ),
                ),
              ),

              // ── Sonar ring B (staggered) ───────────────────────────────────
              Transform.scale(
                scale: ringBScale,
                child: Container(
                  width: _size,
                  height: _size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.secondary.withValues(alpha: ringBOpacity),
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              // ── Main glass circle ─────────────────────────────────────────
              Transform.scale(
                scale: _tapScale.value,
                child: Container(
                  width: _size,
                  height: _size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    // Brand gradient: amber → orange → dark orange
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        AppColors.secondary,
                        AppColors.primary,
                        AppColors.primaryDark,
                      ],
                    ),
                    // White ring visually separates circle from bar
                    border: Border.all(color: Colors.white, width: 3),
                    // Soft colored drop shadow
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.50),
                        blurRadius: 18,
                        spreadRadius: 2,
                        offset: const Offset(0, 5),
                      ),
                      // Subtle inner ambient glow
                      BoxShadow(
                        color: AppColors.secondary.withValues(alpha: 0.25),
                        blurRadius: 8,
                        spreadRadius: -2,
                        offset: const Offset(-2, -2),
                      ),
                    ],
                  ),

                  // ClipOval ensures all glass layers stay within the circle
                  child: ClipOval(
                    child: Stack(
                      children: [

                        // ── Glass frost overlay ────────────────────────────
                        // Semi-transparent white gradient from top-left gives
                        // the frosted / translucent glass surface appearance.
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Colors.white.withValues(alpha: 0.25), // bright corner
                                Colors.white.withValues(alpha: 0.00),
                                Colors.white.withValues(alpha: 0.00),
                                Colors.white.withValues(alpha: 0.10), // subtle far corner
                              ],
                              stops: const [0.0, 0.38, 0.62, 1.0],
                            ),
                          ),
                        ),

                        // ── Top arc highlight ──────────────────────────────
                        // Simulates a light source above the glass sphere —
                        // a bright elliptical patch near the top edge.
                        Positioned(
                          top: 5,
                          left: 10,
                          right: 10,
                          child: Container(
                            height: 14,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(30),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.white.withValues(alpha: 0.60),
                                  Colors.white.withValues(alpha: 0.00),
                                ],
                              ),
                            ),
                          ),
                        ),

                        // ── Animated shine streak ──────────────────────────
                        // A thin, slightly-rotated white strip sweeps across
                        // the face from left to right every _shineCtrl cycle.
                        // Positioned by shineX so it enters and exits the clip.
                        Positioned(
                          left: shineX,
                          top: -_size * 0.3,  // taller than circle so rotation looks full-height
                          bottom: -_size * 0.3,
                          child: Transform.rotate(
                            angle: 0.38, // ~22° diagonal — like light glancing off glass
                            child: Container(
                              width: 20,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Colors.white.withValues(alpha: 0.00),
                                    Colors.white.withValues(alpha: 0.32),
                                    Colors.white.withValues(alpha: 0.00),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),

                        // ── "S" text ───────────────────────────────────────
                        Center(
                          child: Text(
                            'S',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.5,
                              height: 1.0,
                              shadows: [
                                // Soft drop shadow so S pops above the glass layers
                                Shadow(
                                  color: Colors.black.withValues(alpha: 0.30),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1.5),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _NavItem — a single tappable icon + label tab item.
// Expanded so the two items on each side share space equally.
// ─────────────────────────────────────────────────────────────────────────────
class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final int index;
  final int currentIndex;
  final String? badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.index,
    required this.currentIndex,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final bool isActive = index == currentIndex;
    final Color color = isActive ? AppColors.primary : AppColors.textSecondary;

    return Expanded(
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.primary.withValues(alpha: 0.08),
        highlightColor: Colors.transparent,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon + optional cart-count badge
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(isActive ? activeIcon : icon, color: color, size: 24),
                if (badge != null)
                  Positioned(
                    top: -4,
                    right: -8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1.5),
                      ),
                      constraints:
                          const BoxConstraints(minWidth: 16, minHeight: 16),
                      child: Text(
                        badge!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          height: 1,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: AppTypography.labelSmall.copyWith(
                color: color,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
