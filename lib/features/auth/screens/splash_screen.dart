import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';

/// Professional, animated splash screen shown on app launch.
///
/// Features the official SoftStore logo, smooth multi-stage entrance animations,
/// brand identity typography, 3 animated bouncing loading dots, and session restoration.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _animController;
  late final Animation<double> _logoScale;
  late final Animation<double> _logoFade;
  late final Animation<double> _textFade;
  late final Animation<Offset> _textSlide;
  late final Animation<double> _loadingFade;

  bool _isNavigated = false;
  Timer? _minDisplayTimer;
  Timer? _statusTimer;
  String _statusMessage = 'Connecting to SoftStore...';

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _logoScale = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutBack),
    );

    _logoFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeIn),
    );

    _textFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.35, 0.85, curve: Curves.easeIn),
    );

    _textSlide = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _animController,
        curve: const Interval(0.35, 0.85, curve: Curves.easeOutCubic),
      ),
    );

    _loadingFade = CurvedAnimation(
      parent: _animController,
      curve: const Interval(0.65, 1.0, curve: Curves.easeIn),
    );

    _animController.forward();

    // Rotate status message for a polished feel
    _statusTimer = Timer(const Duration(milliseconds: 1100), () {
      if (mounted) {
        setState(() {
          _statusMessage = 'Loading marketplace catalog...';
        });
      }
    });

    // Start session restoration in background
    context.read<AuthCubit>().restoreSession();

    // Display splash gracefully before seamlessly proceeding to Marketplace
    _minDisplayTimer = Timer(const Duration(milliseconds: 2200), () {
      _navigateToHome();
    });
  }

  void _navigateToHome() {
    if (_isNavigated || !mounted) return;
    _isNavigated = true;
    context.go(AppRoutes.home);
  }

  @override
  void dispose() {
    _minDisplayTimer?.cancel();
    _statusTimer?.cancel();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        // If session resolves after minimum display duration, proceed
        if (state is AuthAuthenticated ||
            state is AuthUnauthenticated ||
            state is AuthError) {
          if (_minDisplayTimer == null || !_minDisplayTimer!.isActive) {
            _navigateToHome();
          }
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            // ── Background Ambient Glows ─────────────────────────────────────
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 240,
                height: 240,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF6A00).withValues(alpha: 0.07),
                ),
              ),
            ),
            Positioned(
              bottom: -80,
              left: -80,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFFF6A00).withValues(alpha: 0.05),
                ),
              ),
            ),

            // ── Main Content ────────────────────────────────────────────────
            SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(flex: 3),

                    // 1. Animated Logo Container
                    FadeTransition(
                      opacity: _logoFade,
                      child: ScaleTransition(
                        scale: _logoScale,
                        child: Container(
                          width: 124,
                          height: 124,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(28),
                            border: Border.all(
                              color: const Color(0xFFF1F5F9),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6A00).withValues(alpha: 0.18),
                                blurRadius: 28,
                                offset: const Offset(0, 10),
                                spreadRadius: 2,
                              ),
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.04),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          padding: const EdgeInsets.all(10),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: Image.asset(
                              'assets/images/logo.jpeg',
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) => Container(
                                color: const Color(0xFFFF6A00),
                                alignment: Alignment.center,
                                child: const Icon(
                                  Icons.shopping_bag_rounded,
                                  size: 56,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // 2. Animated Brand Name & Tagline
                    FadeTransition(
                      opacity: _textFade,
                      child: SlideTransition(
                        position: _textSlide,
                        child: Column(
                          children: [
                            const Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: 'SoftStore',
                                    style: TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 32,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                  TextSpan(
                                    text: '.pk',
                                    style: TextStyle(
                                      color: Color(0xFFFF6A00),
                                      fontWeight: FontWeight.w900,
                                      fontSize: 32,
                                      letterSpacing: -0.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 4.5,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF6A00).withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFFFF6A00).withValues(alpha: 0.22),
                                  width: 1,
                                ),
                              ),
                              child: const Text(
                                'PAKISTAN’S TRUSTED MARKETPLACE',
                                style: TextStyle(
                                  color: Color(0xFFE65100),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.0,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const Spacer(flex: 2),

                    // 3. Three Bouncing Loading Dots & Dynamic Status Message
                    FadeTransition(
                      opacity: _loadingFade,
                      child: Column(
                        children: [
                          const SizedBox(
                            height: 32,
                            child: ThreeBouncingDots(
                              color: Color(0xFFFF6A00),
                              size: 10.0,
                              bounceHeight: 9.0,
                            ),
                          ),
                          const SizedBox(height: 12),
                          AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: Text(
                              _statusMessage,
                              key: ValueKey<String>(_statusMessage),
                              style: const TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(flex: 2),

                    // 4. Security / Trust Footer
                    FadeTransition(
                      opacity: _loadingFade,
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.verified_user_rounded,
                                  size: 14,
                                  color: Color(0xFFFF6A00),
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  '100% Genuine & Secure Shopping',
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'v1.0.0 • SoftStore.pk',
                              style: TextStyle(
                                color: Colors.grey.shade400,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A smooth, 3-dot bouncing wave loading animation.
///
/// The three dots remain horizontally positioned in place while oscillating up and down
/// in a fluid harmonic wave pattern.
class ThreeBouncingDots extends StatefulWidget {
  final Color color;
  final double size;
  final double bounceHeight;

  const ThreeBouncingDots({
    super.key,
    this.color = const Color(0xFFFF6A00),
    this.size = 10.0,
    this.bounceHeight = 10.0,
  });

  @override
  State<ThreeBouncingDots> createState() => _ThreeBouncingDotsState();
}

class _ThreeBouncingDotsState extends State<ThreeBouncingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDot(0),
            const SizedBox(width: 8),
            _buildDot(1),
            const SizedBox(width: 8),
            _buildDot(2),
          ],
        );
      },
    );
  }

  Widget _buildDot(int index) {
    // Staggered sine wave phase offset (0, 0.2, 0.4)
    final double delay = index * 0.2;
    final double progress = (_controller.value - delay) % 1.0;

    // Upward bouncing motion using sine curve
    final double sineValue = -math.sin(progress * 2 * math.pi);
    final double offsetY = sineValue * widget.bounceHeight;

    // Scale subtly with movement for realistic bounce feeling
    final double scale = 0.85 + (0.3 * ((sineValue + 1) / 2));

    return Transform.translate(
      offset: Offset(0, offsetY),
      child: Transform.scale(
        scale: scale,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: widget.color,
            boxShadow: [
              BoxShadow(
                color: widget.color.withValues(alpha: 0.35),
                blurRadius: 5,
                offset: const Offset(0, 2),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
