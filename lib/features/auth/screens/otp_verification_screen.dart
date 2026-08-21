import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router.dart';
import '../../../core/errors/failures.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../cart/repository/cart_repository.dart';
import '../cubit/auth_cubit.dart';
import '../cubit/auth_state.dart';
import '../repository/auth_repository.dart';

/// Full-screen OTP verification view.
///
/// Can be accessed via router `/checkout/otp` or `/verify-email`.
class OtpVerificationScreen extends StatefulWidget {
  final String? email;
  final String? redirectRoute;

  const OtpVerificationScreen({
    super.key,
    this.email,
    this.redirectRoute,
  });

  @override
  State<OtpVerificationScreen> createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController _otpCtrl = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  bool _isSending = false;
  bool _isVerifying = false;
  String? _errorMessage;
  String? _successMessage;
  int _resendSeconds = 60;
  Timer? _resendTimer;

  String _resolvedEmail = '';

  @override
  void initState() {
    super.initState();
    _otpCtrl.addListener(_onOtpChanged);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAndSendOtp();
    });
  }

  void _onOtpChanged() {
    if (mounted) {
      setState(() {
        if (_errorMessage != null) {
          _errorMessage = null;
        }
      });
    }
  }

  void _initAndSendOtp() {
    final authState = context.read<AuthCubit>().state;
    final userEmail = authState is AuthAuthenticated ? authState.user.email : '';
    _resolvedEmail = widget.email ?? userEmail;

    if (_resolvedEmail.isNotEmpty) {
      _sendOtp();
    } else {
      setState(() {
        _errorMessage = 'No registered email found. Please sign in again.';
      });
    }
  }

  @override
  void dispose() {
    _resendTimer?.cancel();
    _otpCtrl.removeListener(_onOtpChanged);
    _otpCtrl.dispose();
    _otpFocusNode.dispose();
    super.dispose();
  }

  Future<void> _sendOtp({bool isResend = false}) async {
    if (_resolvedEmail.isEmpty) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await AuthRepository.instance.sendVerificationCode(
        _resolvedEmail,
        isResend: isResend,
      );
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _successMessage = isResend
            ? 'A new verification code has been sent to $_resolvedEmail'
            : 'Verification code sent to $_resolvedEmail';
        _resendSeconds = 60;
      });
      _startResendTimer();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMessage = e is AuthFailure
            ? e.message
            : (e is NetworkFailure
                ? e.message
                : 'Failed to send verification code. Please try again.');
      });
    }
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_resendSeconds <= 1) {
        timer.cancel();
        setState(() => _resendSeconds = 0);
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  Future<void> _verifyOtp() async {
    final code = _otpCtrl.text.trim();
    if (code.length != 6) return;

    setState(() {
      _isVerifying = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final success = await AuthRepository.instance.verifyCode(code);
      if (!success) {
        throw const AuthFailure('Invalid OTP. Please enter the correct OTP.');
      }

      if (_resolvedEmail.isNotEmpty) {
        await CartRepository.instance.markEmailVerified(_resolvedEmail);
      }

      if (mounted) {
        final authCubit = context.read<AuthCubit>();
        await authCubit.refreshUser();
        authCubit.updateEmailVerificationStatus(true);
      }

      developer.log('[OtpScreen] Verified OTP for $_resolvedEmail', name: 'otp');

      if (!mounted) return;
      if (widget.redirectRoute != null && widget.redirectRoute!.isNotEmpty) {
        context.go(widget.redirectRoute!);
      } else if (context.canPop()) {
        context.pop(true);
      } else {
        context.go(AppRoutes.home);
      }
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        if (e.message.toLowerCase().contains('expire')) {
          _errorMessage = 'This OTP has expired. Please request a new OTP.';
        } else {
          _errorMessage = 'Invalid OTP. Please enter the correct verification code.';
        }
      });
    } on NetworkFailure {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Unable to verify OTP. Please check your internet connection.';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        _errorMessage = 'Invalid OTP. Please enter the correct verification code.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final otpLength = _otpCtrl.text.trim().length;
    final isButtonEnabled = otpLength == 6 && !_isVerifying && !_isSending;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          'Email Verification',
          style: AppTypography.screenTitle,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textPrimary),
          onPressed: () {
            if (context.canPop()) {
              context.pop(false);
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screenAll,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: AppSpacing.xl),

              // Icon Badge
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  color: AppColors.primary,
                  size: 36,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              // Title
              const Text(
                'Verify Your Email Address',
                style: AppTypography.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),

              // Instructions
              Text(
                _resolvedEmail.isNotEmpty
                    ? 'We have sent a 6-digit verification code to:\n$_resolvedEmail'
                    : 'We have sent a 6-digit verification code to your registered email.',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textSecondary,
                  height: 1.45,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xxl),

              // 6-Digit OTP Box
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: AppDimensions.radiusSm,
                  border: Border.all(
                    color: _errorMessage != null
                        ? AppColors.error
                        : AppColors.border,
                    width: _errorMessage != null ? 1.5 : 1.0,
                  ),
                  boxShadow: AppDimensions.cardShadow,
                ),
                child: TextFormField(
                  controller: _otpCtrl,
                  focusNode: _otpFocusNode,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 26,
                    letterSpacing: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: '• • • • • •',
                    hintStyle: TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: 22,
                      letterSpacing: 8,
                    ),
                    counterText: '',
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),

              // Error Display
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Success Display
              if (_successMessage != null && _errorMessage == null) ...[
                const SizedBox(height: AppSpacing.md),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: AppSpacing.xxl),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: isButtonEnabled ? _verifyOtp : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isButtonEnabled ? AppColors.primary : AppColors.disabled,
                    foregroundColor: isButtonEnabled ? Colors.white : AppColors.textDisabled,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: AppDimensions.radiusSm,
                    ),
                  ),
                  child: _isVerifying
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Verify Email',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isButtonEnabled ? Colors.white : AppColors.textDisabled,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: AppSpacing.lg),

              // Resend OTP Action
              Center(
                child: _resendSeconds > 0
                    ? Text(
                        'Resend code in ${_resendSeconds}s',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.textDisabled,
                        ),
                      )
                    : GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _isSending ? null : () => _sendOtp(isResend: true),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          child: Text(
                            _isSending ? 'Sending...' : 'Resend OTP',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
