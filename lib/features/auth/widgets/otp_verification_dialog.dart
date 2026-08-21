import 'dart:async';
import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../../cart/repository/cart_repository.dart';
import '../cubit/auth_cubit.dart';
import '../repository/auth_repository.dart';

/// Reusable modal dialog for 6-digit OTP email verification.
///
/// Used in both:
/// 1. Post-signup email verification flow
/// 2. Checkout email verification flow
class OtpVerificationDialog extends StatefulWidget {
  final String email;
  final String? name;
  final String? phone;
  final String title;
  final String subtitle;
  final String primaryButtonText;
  final bool autoSendOtp;
  final VoidCallback? onVerified;
  final VoidCallback? onCancel;

  const OtpVerificationDialog({
    super.key,
    required this.email,
    this.name,
    this.phone,
    this.title = 'Verify Your Email',
    this.subtitle = 'Enter the 6-digit code sent to your email to verify your account.',
    this.primaryButtonText = 'Verify',
    this.autoSendOtp = true,
    this.onVerified,
    this.onCancel,
  });

  /// Displays the OTP dialog. Returns `true` if verified, `false` if cancelled.
  static Future<bool> show(
    BuildContext context, {
    required String email,
    String? name,
    String? phone,
    String title = 'Verify Your Email',
    String? subtitle,
    String primaryButtonText = 'Verify',
    bool autoSendOtp = true,
    VoidCallback? onVerified,
    VoidCallback? onCancel,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => OtpVerificationDialog(
        email: email,
        name: name,
        phone: phone,
        title: title,
        subtitle: subtitle ??
            (email.isNotEmpty
                ? 'Enter the 6-digit code sent to $email.'
                : 'Enter the 6-digit code sent to your registered email.'),
        primaryButtonText: primaryButtonText,
        autoSendOtp: autoSendOtp,
        onVerified: onVerified,
        onCancel: onCancel,
      ),
    );
    return result ?? false;
  }

  @override
  State<OtpVerificationDialog> createState() => _OtpVerificationDialogState();
}

class _OtpVerificationDialogState extends State<OtpVerificationDialog> {
  final TextEditingController _otpCtrl = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();

  bool _isSending = false;
  bool _isVerifying = false;
  String? _errorMessage;
  String? _successMessage;
  int _resendSeconds = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _otpCtrl.addListener(_onOtpChanged);

    if (widget.autoSendOtp) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _sendOtp();
      });
    } else {
      _resendSeconds = 60;
      _successMessage = widget.email.isNotEmpty
          ? 'Verification code sent to ${widget.email}'
          : 'Verification code sent to your registered email';
      _startResendTimer();
    }
  }

  void _onOtpChanged() {
    if (mounted) {
      setState(() {
        // Clear previous error message as soon as user types or edits OTP
        if (_errorMessage != null) {
          _errorMessage = null;
        }
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

  /// Sends the 6-digit OTP using the existing Send OTP endpoint.
  Future<void> _sendOtp({bool isResend = false}) async {
    if (widget.email.isEmpty) {
      setState(() {
        _errorMessage = 'Email address is required to receive verification code.';
      });
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      await AuthRepository.instance.sendVerificationCode(
        widget.email,
        name: widget.name,
        phone: widget.phone,
        isResend: isResend,
      );

      if (!mounted) return;
      setState(() {
        _isSending = false;
        _successMessage = isResend
            ? 'A new verification code has been sent to ${widget.email}'
            : 'Verification code sent to ${widget.email}';
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

  /// Verifies the entered 6-digit OTP using the existing Verify OTP endpoint.
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
        throw const AuthFailure('Invalid OTP. Please enter the correct verification code.');
      }

      // Mark email as verified permanently in local repository cache
      if (widget.email.isNotEmpty) {
        await CartRepository.instance.markEmailVerified(widget.email);
      }

      // Refresh user session from backend Session API
      if (mounted) {
        final authCubit = context.read<AuthCubit>();
        await authCubit.refreshUser();
        authCubit.updateEmailVerificationStatus(true);
      }

      developer.log('[OtpVerification] Successfully verified OTP for ${widget.email}', name: 'otp');

      if (!mounted) return;
      widget.onVerified?.call();
      Navigator.of(context).pop(true);
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() {
        _isVerifying = false;
        // Specific error handling for expired vs invalid OTP
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

  void _onCancelPressed() {
    _resendTimer?.cancel();
    widget.onCancel?.call();
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final otpLength = _otpCtrl.text.trim().length;
    final isButtonEnabled = otpLength == 6 && !_isVerifying && !_isSending;

    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppDimensions.radiusLg,
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      content: SizedBox(
        width: 340,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon Badge
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Title
              Text(
                widget.title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // Subtitle & Registered Email
              RichText(
                textAlign: TextAlign.center,
                text: TextSpan(
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.4,
                    color: AppColors.textSecondary,
                  ),
                  children: [
                    const TextSpan(text: 'Enter the 6-digit code sent to\n'),
                    TextSpan(
                      text: widget.email.isNotEmpty ? widget.email : 'your registered email',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),

              // 6-digit OTP Input Field
              Container(
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: AppDimensions.radiusSm,
                  border: Border.all(
                    color: _errorMessage != null
                        ? AppColors.error
                        : AppColors.border,
                    width: _errorMessage != null ? 1.5 : 1.0,
                  ),
                ),
                child: TextFormField(
                  controller: _otpCtrl,
                  focusNode: _otpFocusNode,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    letterSpacing: 10,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                  decoration: const InputDecoration(
                    hintText: '• • • • • •',
                    hintStyle: TextStyle(
                      color: AppColors.textDisabled,
                      fontSize: 18,
                      letterSpacing: 6,
                    ),
                    counterText: '',
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  ),
                ),
              ),

              // Error feedback
              if (_errorMessage != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.error,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              // Success feedback
              if (_successMessage != null && _errorMessage == null) ...[
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    const Icon(Icons.check_circle_outline, color: AppColors.success, size: 16),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _successMessage!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.success,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              const SizedBox(height: AppSpacing.lg),

              // Verify Button
              SizedBox(
                width: double.infinity,
                height: 48,
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
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.2,
                          ),
                        )
                      : Text(
                          widget.primaryButtonText,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isButtonEnabled ? Colors.white : AppColors.textDisabled,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              // Resend OTP Countdown / Action
              Center(
                child: _resendSeconds > 0
                    ? Text(
                        'Resend code in ${_resendSeconds}s',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textDisabled,
                        ),
                      )
                    : GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: _isSending ? null : () => _sendOtp(isResend: true),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          child: Text(
                            _isSending ? 'Sending...' : 'Resend OTP',
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
              ),

              const SizedBox(height: AppSpacing.xs),

              // Cancel / Close
              Center(
                child: TextButton(
                  onPressed: _onCancelPressed,
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.textSecondary,
                  ),
                  child: const Text(
                    'Cancel',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
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
