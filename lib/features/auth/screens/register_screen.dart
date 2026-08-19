import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import 'auth_screen.dart';

import '../widgets/recaptcha_invisible_view.dart';

/// Register Screen matching the exact SoftStore design (Screenshot 1).
/// Can be presented as a standalone page or as a bottom sheet modal.
class RegisterScreen extends StatefulWidget {
  final bool isModal;
  final VoidCallback? onSwitchToLogin;
  final VoidCallback? onClosed;

  const RegisterScreen({
    super.key,
    this.isModal = false,
    this.onSwitchToLogin,
    this.onClosed,
  });

  /// Opens the Register screen as a modal bottom sheet.
  /// Returns `true` if authentication succeeded.
  static Future<bool?> showAsModal(BuildContext context) {
    return AuthScreen.show(context, isRegister: true);
  }

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  RecaptchaController? _recaptchaController;
  String _recaptchaToken = '';
  bool _isMintingToken = false;

  @override
  void initState() {
    super.initState();
    _firstNameCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _emailCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _passwordCtrl.addListener(() {
      if (mounted) setState(() {});
    });
    _confirmPasswordCtrl.addListener(() {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  bool get _hasValidInput =>
      _firstNameCtrl.text.trim().isNotEmpty &&
      _emailCtrl.text.trim().isNotEmpty &&
      _passwordCtrl.text.isNotEmpty &&
      _confirmPasswordCtrl.text.isNotEmpty;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_passwordCtrl.text != _confirmPasswordCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    String token = '';
    if (_recaptchaController != null) {
      token = await _recaptchaController!.getFreshToken();
    }

    if (!mounted) return;

    context.read<AuthCubit>().register(
          firstName: _firstNameCtrl.text.trim(),
          lastName: _lastNameCtrl.text.trim().isEmpty
              ? null
              : _lastNameCtrl.text.trim(),
          email: _emailCtrl.text.trim(),
          phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
          password: _passwordCtrl.text,
          recaptchaToken: token,
        );
  }

  void _onGoogleSignUp() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Google Sign-Up is launching...'),
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _onBack() {
    if (widget.isModal) {
      if (widget.onSwitchToLogin != null) {
        widget.onSwitchToLogin!();
      } else {
        Navigator.of(context).pop(false);
      }
    } else {
      if (context.canPop()) {
        context.pop();
      } else {
        context.go(AppRoutes.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        BlocListener<AuthCubit, AuthState>(
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
        ),
        RecaptchaInvisibleView(
          onControllerCreated: (controller) => _recaptchaController = controller,
        ),
      ],
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
            // ── Top Bar: Circular Back Button & Sign Up / Logo ─────────────
            Stack(
              alignment: Alignment.center,
              children: [
                // Back button on left
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: _onBack,
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFFE5E7EB),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.chevron_left_rounded,
                        color: Color(0xFF1E2022),
                        size: 24,
                      ),
                    ),
                  ),
                ),

                // Center Title & Logo
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Sign Up',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF111827),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Image.asset(
                      'images/logo/logo-softstore-with-text.png',
                      height: 36,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Text(
                        'SoftStore.pk',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6A00),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 24),

            // ── "Create your account" Heading ──────────────────────────────
            const Text(
              'Create your account',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Color(0xFF111827),
                letterSpacing: -0.4,
              ),
            ),

            const SizedBox(height: 20),

            // ── First Name ────────────────────────────────────────────────
            const Text(
              'First name',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _firstNameCtrl,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF111827),
              ),
              decoration: _buildInputDecoration(''),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'First name is required';
                return null;
              },
            ),

            const SizedBox(height: 16),

            // ── Last Name (optional) ──────────────────────────────────────
            const Text(
              'Last name (optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _lastNameCtrl,
              textInputAction: TextInputAction.next,
              textCapitalization: TextCapitalization.words,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF111827),
              ),
              decoration: _buildInputDecoration(''),
            ),

            const SizedBox(height: 16),

            // ── Email ─────────────────────────────────────────────────────
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

            // ── Phone (optional) ──────────────────────────────────────────
            const Text(
              'Phone (optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              validator: Validators.pakistaniPhone,
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF111827),
              ),
              decoration: _buildInputDecoration(''),
            ),

            const SizedBox(height: 16),

            // ── Password ──────────────────────────────────────────────────
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
              textInputAction: TextInputAction.next,
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

            const SizedBox(height: 16),

            // ── Confirm Password ──────────────────────────────────────────
            const Text(
              'Confirm password',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Color(0xFF4B5563),
              ),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _confirmPasswordCtrl,
              obscureText: _obscureConfirmPassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _submit(),
              style: const TextStyle(
                fontSize: 15,
                color: Color(0xFF111827),
              ),
              decoration: _buildInputDecoration('').copyWith(
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: const Color(0xFF6B7280),
                    size: 22,
                  ),
                  onPressed: () {
                    if (mounted) {
                      setState(() =>
                          _obscureConfirmPassword = !_obscureConfirmPassword);
                    }
                  },
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return 'Please confirm your password';
                if (v != _passwordCtrl.text) return 'Passwords do not match';
                return null;
              },
            ),

            const SizedBox(height: 24),

            // ── Create Account Button ─────────────────────────────────────
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
                            'Create Account',
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

            const SizedBox(height: 20),

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

            // ── "Sign up with Google" Button ──────────────────────────────
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton(
                onPressed: _onGoogleSignUp,
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
                      'Sign up with Google',
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
