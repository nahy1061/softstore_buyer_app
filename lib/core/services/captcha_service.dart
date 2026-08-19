import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_gcaptcha_v3/recaptca_config.dart';

import '../config/env_config.dart';

/// Singleton service for generating reCAPTCHA v3 tokens.
///
/// Uses [RecaptchaHandler] from `flutter_gcaptcha_v3` which loads the
/// reCAPTCHA JS in a hidden WebView. The WebView must be placed in the
/// widget tree by [AuthScreen] before tokens can be generated.
///
/// Returns empty string on failure so auth flows can still attempt
/// (backend may have fallback handling).
class CaptchaService {
  CaptchaService._();
  static final CaptchaService instance = CaptchaService._();

  Completer<String>? _completer;

  /// Setup the site key. Called by [AuthScreen] when the WebView is ready.
  void setup() {
    RecaptchaHandler.instance.setupSiteKey(dataSiteKey: EnvConfig.reCaptchaSiteKey);
    debugPrint('[Captcha] Site key set: ${EnvConfig.reCaptchaSiteKey}');
  }

  /// Generates a reCAPTCHA token for the given [action].
  ///
  /// Returns an empty string if token generation fails, so callers
  /// can still proceed (backend may accept empty tokens).
  Future<String> getToken({String action = 'login'}) async {
    try {
      debugPrint('[Captcha] Requesting token for action: $action');
      _completer = Completer<String>();

      RecaptchaHandler.executeV3(action: action);

      final token = await _completer!.future.timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          debugPrint('[Captcha] Token request timed out');
          return '';
        },
      );

      debugPrint('[Captcha] Token obtained (${token.length} chars)');
      return token;
    } catch (e) {
      debugPrint('[Captcha] Token FAILED: $e');
      return '';
    }
  }

  /// Called by the WebView's JavaScript channel when a token arrives.
  void onTokenReceived(String token) {
    debugPrint('[Captcha] Token received via callback (${token.length} chars)');
    if (_completer != null && !_completer!.isCompleted) {
      _completer!.complete(token);
    }
  }
}
