import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../../core/errors/failures.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_spacing.dart';
import '../repository/auth_repository.dart';

/// Modal dialog shown immediately after a user successfully signs up.
///
/// Prompts the user to verify their email address now or later.
/// - 'verify_success': User tapped "Verify Now" -> Send OTP API succeeded -> triggers opening OTP dialog.
/// - 'later': User tapped "Later" -> skips OTP, allows normal app usage as unverified.
class EmailVerificationPromptDialog extends StatefulWidget {
  final String email;
  final String? name;
  final String? phone;

  const EmailVerificationPromptDialog({
    super.key,
    required this.email,
    this.name,
    this.phone,
  });

  /// Shows the dialog and returns 'verify_success', 'later', or null if dismissed.
  static Future<String?> show(
    BuildContext context, {
    required String email,
    String? name,
    String? phone,
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => EmailVerificationPromptDialog(
        email: email,
        name: name,
        phone: phone,
      ),
    );
  }

  @override
  State<EmailVerificationPromptDialog> createState() =>
      _EmailVerificationPromptDialogState();
}

class _EmailVerificationPromptDialogState
    extends State<EmailVerificationPromptDialog> {
  bool _isSending = false;
  String? _errorMessage;

  Future<void> _onVerifyNow() async {
    final targetEmail = widget.email.trim();
    if (targetEmail.isEmpty) {
      setState(() {
        _errorMessage = 'No valid email address found to send verification code.';
      });
      return;
    }

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    try {
      developer.log(
        '[EmailVerificationPrompt] Calling Send OTP API for email: $targetEmail',
        name: 'auth',
      );
      await AuthRepository.instance.sendVerificationCode(
        targetEmail,
        name: widget.name,
        phone: widget.phone,
      );

      developer.log(
        '[EmailVerificationPrompt] Send OTP API succeeded for $targetEmail',
        name: 'auth',
      );

      if (!mounted) return;
      Navigator.of(context).pop('verify_success');
    } on AuthFailure catch (e) {
      developer.log(
        '[EmailVerificationPrompt] Send OTP failed with AuthFailure: ${e.message}',
        name: 'auth',
        error: e,
      );
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMessage = e.message;
      });
    } on NetworkFailure catch (e) {
      developer.log(
        '[EmailVerificationPrompt] Send OTP failed with NetworkFailure: ${e.message}',
        name: 'auth',
        error: e,
      );
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMessage = e.message;
      });
    } catch (e) {
      developer.log(
        '[EmailVerificationPrompt] Send OTP unexpected error: $e',
        name: 'auth',
        error: e,
      );
      if (!mounted) return;
      setState(() {
        _isSending = false;
        _errorMessage = 'Unable to send verification code. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.surface,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: AppDimensions.radiusLg,
      ),
      contentPadding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
      actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon badge
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_unread_outlined,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Title
          const Text(
            'Verify Your Email',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Description
          const Text(
            'Your account has been created successfully. Would you like to verify your email now?',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),

          if (widget.email.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: AppDimensions.radiusSm,
                border: Border.all(color: AppColors.border, width: 0.8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.email_outlined,
                    size: 16,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      widget.email,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Error banner if sending OTP failed
          if (_errorMessage != null) ...[
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: AppDimensions.radiusSm,
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Row(
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
            ),
          ],
        ],
      ),
      actions: [
        Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Verify Now button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isSending ? null : _onVerifyNow,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppDimensions.radiusSm,
                  ),
                ),
                child: _isSending
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.2,
                        ),
                      )
                    : const Text(
                        'Verify Now',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),

            // Later button
            SizedBox(
              height: 44,
              child: TextButton(
                onPressed: _isSending ? null : () => Navigator.of(context).pop('later'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.textSecondary,
                  shape: RoundedRectangleBorder(
                    borderRadius: AppDimensions.radiusSm,
                  ),
                ),
                child: const Text(
                  'Later',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
