import 'dart:async';
import 'dart:developer' as developer;
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';
import '../../../core/config/env_config.dart';

/// Singleton controller for Google reCAPTCHA v3.
class RecaptchaController {
  static final RecaptchaController instance = RecaptchaController._();
  RecaptchaController._();
  factory RecaptchaController() => instance;

  _RecaptchaInvisibleViewState? _state;

  void _attach(_RecaptchaInvisibleViewState state) {
    _state = state;
  }

  void _detach(_RecaptchaInvisibleViewState state) {
    if (_state == state) {
      _state = null;
    }
  }

  /// Mints a fresh, single-use reCAPTCHA v3 token on demand
  Future<String> getFreshToken({Duration timeout = const Duration(seconds: 4)}) async {
    if (_state == null) return '';
    return _state!.getFreshToken(timeout: timeout);
  }
}

/// Invisible host widget for Google reCAPTCHA v3.
///
/// Uses Android Texture Composition to completely avoid GPU Surface allocations.
class RecaptchaInvisibleView extends StatefulWidget {
  final String siteKey;
  final ValueChanged<String>? onTokenReceived;
  final ValueChanged<String>? onError;
  final void Function(RecaptchaController controller)? onControllerCreated;

  const RecaptchaInvisibleView({
    super.key,
    this.siteKey = EnvConfig.reCaptchaSiteKey,
    this.onTokenReceived,
    this.onError,
    this.onControllerCreated,
  });

  @override
  State<RecaptchaInvisibleView> createState() => _RecaptchaInvisibleViewState();
}

class _RecaptchaInvisibleViewState extends State<RecaptchaInvisibleView> {
  static WebViewController? _sharedWebController;
  static bool _sharedIsReady = false;
  static Completer<String>? _sharedTokenCompleter;

  bool get _isTestEnv {
    try {
      return Platform.environment.containsKey('FLUTTER_TEST');
    } catch (_) {
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    RecaptchaController.instance._attach(this);
    widget.onControllerCreated?.call(RecaptchaController.instance);

    if (!kIsWeb && !_isTestEnv) {
      _ensureWebViewInitialized();
    }
  }

  @override
  void dispose() {
    RecaptchaController.instance._detach(this);
    super.dispose();
  }

  void _ensureWebViewInitialized() {
    if (_sharedWebController != null) return;

    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is WebKitWebViewPlatform) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
      );
    } else if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    final controller = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setUserAgent('SoftStoreBuyer/1.0 iOS')
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            developer.log('[reCAPTCHA] Web error: ${error.description}', name: 'recaptcha');
          },
        ),
      )
      ..addJavaScriptChannel(
        'recaptchaToken',
        onMessageReceived: (message) {
          final token = message.message;
          developer.log('[reCAPTCHA] Minted token received: ${token.isNotEmpty}', name: 'recaptcha');
          if (token.isNotEmpty) {
            if (_sharedTokenCompleter != null && !_sharedTokenCompleter!.isCompleted) {
              _sharedTokenCompleter!.complete(token);
            }
            widget.onTokenReceived?.call(token);
          }
        },
      )
      ..addJavaScriptChannel(
        'recaptchaError',
        onMessageReceived: (message) {
          developer.log('[reCAPTCHA] Error: ${message.message}', name: 'recaptcha');
          if (_sharedTokenCompleter != null && !_sharedTokenCompleter!.isCompleted) {
            _sharedTokenCompleter!.complete('');
          }
          widget.onError?.call(message.message);
        },
      )
      ..addJavaScriptChannel(
        'recaptchaReady',
        onMessageReceived: (_) {
          _sharedIsReady = true;
          developer.log('[reCAPTCHA] Service ready', name: 'recaptcha');
          if (_sharedTokenCompleter != null && !_sharedTokenCompleter!.isCompleted) {
            _executeMinting();
          }
        },
      );

    if (controller.platform is AndroidWebViewController) {
      AndroidWebViewController.enableDebugging(false);
      (controller.platform as AndroidWebViewController).setMediaPlaybackRequiresUserGesture(false);
    }

    final html = _buildHTML(widget.siteKey);
    controller.loadHtmlString(html, baseUrl: EnvConfig.baseUrl);
    _sharedWebController = controller;
  }

  Future<void> _executeMinting() async {
    if (_sharedWebController == null) return;
    try {
      await _sharedWebController!.runJavaScript('window.requestToken();');
    } catch (e) {
      if (_sharedTokenCompleter != null && !_sharedTokenCompleter!.isCompleted) {
        _sharedTokenCompleter!.complete('');
      }
      widget.onError?.call(e.toString());
    }
  }

  Future<String> getFreshToken({Duration timeout = const Duration(seconds: 4)}) async {
    if (kIsWeb || _isTestEnv || _sharedWebController == null) {
      return '';
    }

    _sharedTokenCompleter = Completer<String>();

    if (_sharedIsReady) {
      _executeMinting();
    } else {
      _executeMinting();
    }

    try {
      final token = await _sharedTokenCompleter!.future.timeout(timeout);
      return token;
    } catch (_) {
      return '';
    } finally {
      _sharedTokenCompleter = null;
    }
  }

  String _buildHTML(String siteKey) {
    return '''
<!DOCTYPE html><html><head>
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<script src="https://www.google.com/recaptcha/api.js?render=$siteKey"></script>
<script>
(function() {
    var siteKey = '$siteKey';
    var ready = false;
    var pending = false;

    function post(channel, value) {
        try {
            if (window[channel] && window[channel].postMessage) {
                window[channel].postMessage(value);
            } else if (typeof window[channel] !== 'undefined') {
                window[channel].postMessage(value);
            } else if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers[channel]) {
                window.webkit.messageHandlers[channel].postMessage(value);
            }
        } catch (e) {}
    }

    function execute() {
        try {
            grecaptcha.execute(siteKey, {action: 'submit'}).then(function(token) {
                post('recaptchaToken', token);
            }).catch(function(err) {
                post('recaptchaError', String(err));
            });
        } catch (e) {
            post('recaptchaError', String(e));
        }
    }

    window.requestToken = function() {
        if (!ready) { pending = true; return; }
        execute();
    };

    var attempts = 0;
    function pollRecaptcha() {
        if (typeof grecaptcha !== 'undefined' && typeof grecaptcha.ready === 'function') {
            grecaptcha.ready(function() {
                ready = true;
                post('recaptchaReady', 'ready');
                try {
                    grecaptcha.execute(siteKey, {action: 'submit'}).catch(function() {});
                } catch (e) {}
                if (pending) { pending = false; execute(); }
            });
        } else {
            attempts++;
            if (attempts < 80) {
                setTimeout(pollRecaptcha, 100);
            } else {
                post('recaptchaError', 'reCAPTCHA failed to load after 8s');
            }
        }
    }

    if (document.readyState === 'complete' || document.readyState === 'interactive') {
        pollRecaptcha();
    } else {
        window.addEventListener('DOMContentLoaded', pollRecaptcha);
    }
})();
</script>
</head><body></body></html>
''';
  }

  @override
  Widget build(BuildContext context) {
    if (kIsWeb || _isTestEnv || _sharedWebController == null) {
      return const SizedBox.shrink();
    }

    Widget webView;
    if (_sharedWebController!.platform is AndroidWebViewController) {
      webView = WebViewWidget.fromPlatformCreationParams(
        params: AndroidWebViewWidgetCreationParams(
          controller: _sharedWebController!.platform as AndroidWebViewController,
          displayWithHybridComposition: false, // Texture Layer mode: 0 RTS Surface allocations
        ),
      );
    } else {
      webView = WebViewWidget(controller: _sharedWebController!);
    }

    return SizedBox(
      width: 1,
      height: 1,
      child: Opacity(
        opacity: 0.01,
        child: webView,
      ),
    );
  }
}
