import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'auth_screen.dart';
import 'register_screen.dart';

/// Login Screen matching the exact SoftStore design (Screenshot 3).
/// Can be presented as a standalone page or as a bottom sheet modal.
class LoginScreen extends StatefulWidget {
  final bool isModal;
  final VoidCallback? onSwitchToRegister;
  final VoidCallback? onClosed;

  const LoginScreen({
    super.key,
    this.isModal = false,
    this.onSwitchToRegister,
    this.onClosed,
  });

  /// Opens the Login screen as a modal bottom sheet.
  /// Returns `true` if authentication succeeded.
  static Future<bool?> showAsModal(BuildContext context) {
    return AuthScreen.show(context, isRegister: false);
  }

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _passwordCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  bool get _hasValidInput =>
      _emailCtrl.text.trim().isNotEmpty && _passwordCtrl.text.isNotEmpty;

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    // reCAPTCHA token placeholder for mobile compatibility
    const String recaptchaToken = '';

    context.read<AuthCubit>().login(
          email: _emailCtrl.text.trim(),
          password: _passwordCtrl.text,
          recaptchaToken: recaptchaToken,
        );
  }

  void _onForgotPassword() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Reset Password',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'Please contact support or check your registered email to reset your password.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK',
                style: TextStyle(
                    color: Color(0xFFFF6A00), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _onGoogleSignIn() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Sign-In is launching...'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _goToRegister() {
    if (widget.isModal && widget.onSwitchToRegister != null) {
      widget.onSwitchToRegister!();
    } else if (widget.isModal) {
      Navigator.of(context).pop();
      RegisterScreen.showAsModal(context);
    } else {
      context.push(AppRoutes.register);
    }
  }

  void _onClose() {
    if (widget.isModal) {
      if (widget.onClosed != null) {
        widget.onClosed!();
      } else {
        Navigator.of(context).pop(false);
      }
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          if (widget.isModal) {
            Navigator.of(context).pop(true);
          } else {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          }
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      child: widget.isModal ? _buildModalSheet(context) : _buildFullScreen(context),
    );
  }

  Widget _buildFullScreen(BuildContext context) {
    final topPadding = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: topPadding + 16),
              // Rounded modal card container matching the screenshot layout
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.06),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _buildFormContent(context),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModalSheet(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: _buildFormContent(context),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top Bar with Circular Close Button ('X') ───────────────────
            Align(
              alignment: Alignment.topLeft,
              child: GestureDetector(
                onTap: _onClose,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFF5A5E66),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 4),

            // ── SoftStore.pk Brand Logo ───────────────────────────────────
            Center(
              child: Image.asset(
                'images/logo/logo-softstore-with-text.png',
                height: 86,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Column(
                  children: [
                    Image.asset(
                      'assets/images/logo.jpeg',
                      height: 54,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'SoftStore.pk',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1E2022),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            // ── Subtitle ──────────────────────────────────────────────────
            const Center(
              child: Text(
                'Sign in to manage your account',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF6B7280),
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Email Field ───────────────────────────────────────────────
            const Text(
              'Email',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF111827),
              ),
              decoration: _buildInputDecoration(''),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Email is required';
                if (!v.contains('@') || !v.contains('.')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),

            // ── Password Field ────────────────────────────────────────────
            const Text(
              'Password',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordCtrl,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF111827),
              ),
              decoration: _buildInputDecoration('').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xFF6B7280),
                    size: 22,
                  ),
                  onPressed: () {
                    if (mounted) {
                      setState(() => _obscurePassword = !_obscurePassword);
                    }
                  },
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Password is required';
                if (v.length < 6) return 'Password must be at least 6 characters';
                return null;
              },
            ),

            const SizedBox(height: 10),

            // ── Forgot Password? Link ─────────────────────────────────────
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: _onForgotPassword,
                child: const Text(
                  'Forgot password?',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFFF6A00),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 20),

            // ── Sign In Button ────────────────────────────────────────────
            BlocBuilder<AuthCubit, AuthState>(
              builder: (context, state) {
                final isLoading = state is AuthLoading;
                final isEnabled = _hasValidInput && !isLoading;

                return SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isEnabled
                          ? const Color(0xFFFF6A00)
                          : const Color(0xFFE5E7EB),
                      foregroundColor: isEnabled
                          ? Colors.white
                          : const Color(0xFF6B7280),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: isEnabled
                                  ? Colors.white
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                  ),
                );
              },
            ),

            const SizedBox(height: 22),

            // ── "or" Divider ──────────────────────────────────────────────
            const Row(
              children: [
                Expanded(
                  child: Divider(color: Color(0xFFE5E7EB), thickness: 1),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF9CA3AF),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(color: Color(0xFFE5E7EB), thickness: 1),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ── "Continue with Google" Button ─────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _onGoogleSignIn,
                style: OutlinedButton.styleFrom(
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Color(0xFFD1D5DB), width: 1.1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  elevation: 0,
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'G',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'Roboto',
                        color: Color(0xFF4285F4),
                      ),
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Continue with Google',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF111827),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 28),

            // ── Footer: New to SoftStore? Create an account ───────────────
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'New to SoftStore? ',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Color(0xFF4B5563),
                    ),
                  ),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: _goToRegister,
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      child: Text(
                        'Create an account',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFFFF6A00),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: Color(0xFFFF6A00), width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.error, width: 1.5),
      ),
    );
  }
}
