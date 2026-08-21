import 'dart:convert';
import 'dart:developer' as developer;

import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;

import '../config/env_config.dart';

/// Shared HTML parsing helpers for the SoftStore buyer app.
///
/// SoftStore's backend is a PHP MVC app that returns HTML for ~90% of
/// responses. This utility centralises all DOM-scraping logic so it can
/// be maintained in one place.
class HtmlParserUtil {
  HtmlParserUtil._();

  // ─── CSRF Token Extraction ────────────────────────────────────────────────

  /// Extracts a CSRF token from raw HTML.
  ///
  /// Tries three locations in order:
  ///  1. Hidden input `<input name="_csrf_token" value="...">`
  ///  2. JavaScript variable `var csrfToken = '...'`
  ///  3. Meta tag `<meta name="csrf-token" content="...">`
  static String? extractCsrfToken(String htmlBody) {
    try {
      final doc = html_parser.parse(htmlBody);

      // 1. Hidden input
      final hiddenInput = doc.querySelector('input[name="_csrf_token"]');
      if (hiddenInput != null) {
        final val = hiddenInput.attributes['value'];
        if (val != null && val.isNotEmpty) {
          developer.log('[CSRF] Extracted from hidden input', name: 'csrf');
          return val;
        }
      }

      // 2. JavaScript variable: var csrfToken = 'TOKEN';
      final scripts = doc.querySelectorAll('script');
      for (final script in scripts) {
        final text = script.text;
        final match = RegExp(
          r'''(?:var\s+csrfToken|window\._csrfToken)\s*=\s*['"]([^'"]+)['"]''',
        ).firstMatch(text);
        if (match != null) {
          final token = match.group(1);
          if (token != null && token.isNotEmpty) {
            developer.log('[CSRF] Extracted from JS variable', name: 'csrf');
            return token;
          }
        }
      }

      // 3. Meta tag
      final metaTag = doc.querySelector('meta[name="csrf-token"]');
      if (metaTag != null) {
        final content = metaTag.attributes['content'];
        if (content != null && content.isNotEmpty) {
          developer.log('[CSRF] Extracted from meta tag', name: 'csrf');
          return content;
        }
      }
    } catch (e) {
      developer.log('[CSRF] Extraction failed: $e', name: 'csrf');
    }
    return null;
  }

  // ─── Form Error Extraction ────────────────────────────────────────────────

  /// Returns the first error text found in HTML or JSON body, or
  /// null if the response contains no visible error messages.
  static String? extractFormError(String htmlBody) {
    if (htmlBody.trim().isEmpty) return null;

    // Check if JSON response e.g. {"success":false,"message":"..."}
    final trimmed = htmlBody.trim();
    if (trimmed.startsWith('{') && trimmed.endsWith('}')) {
      try {
        final decoded = jsonDecode(trimmed);
        if (decoded is Map<String, dynamic>) {
          final msg = decoded['message'] ?? decoded['error'] ?? decoded['msg'];
          if (msg != null && msg.toString().isNotEmpty) {
            return msg.toString();
          }
        }
      } catch (_) {}
    }

    try {
      final doc = html_parser.parse(htmlBody);

      // Check SoftStore specific error elements & common validation containers
      const errorSelectors = [
        '.invalid-feedback',
        '.alert-danger',
        '.alert-error',
        '.sx-alert-err',
        '.alert-tf.alert-danger',
        '.text-danger',
        '.error-message',
        '.error-msg',
        '.form-error',
        '.error',
        '.help-block.text-danger',
        '.alert-warning',
        '.sx-alert-warn',
      ];

      for (final selector in errorSelectors) {
        final el = doc.querySelector(selector);
        if (el != null) {
          final text = el.text.trim();
          if (text.isNotEmpty && !text.toLowerCase().contains('javascript')) {
            return text;
          }
        }
      }

      // Check general alert elements, excluding success and info banners
      final alerts = doc.querySelectorAll('.alert, .sx-alert, [role="alert"]');
      for (final el in alerts) {
        final classes = el.classes;
        if (classes.contains('alert-success') ||
            classes.contains('alert-info') ||
            classes.contains('alert-primary') ||
            classes.contains('sx-alert-ok')) {
          continue;
        }
        final text = el.text.trim();
        if (text.isNotEmpty && !text.toLowerCase().contains('javascript')) {
          return text;
        }
      }
    } catch (e) {
      developer.log('[HtmlParser] Error extraction failed: $e', name: 'html');
    }
    return null;
  }

  // ─── JSON-LD Extraction ───────────────────────────────────────────────────

  /// Parses all `<script type="application/ld+json">` blocks in the page
  /// and returns the list of decoded JSON objects.
  static List<Map<String, dynamic>> extractJsonLd(String htmlBody) {
    final results = <Map<String, dynamic>>[];
    try {
      final doc = html_parser.parse(htmlBody);
      final scripts = doc.querySelectorAll('script[type="application/ld+json"]');
      for (final script in scripts) {
        try {
          final decoded = jsonDecode(script.text);
          if (decoded is Map<String, dynamic>) {
            results.add(decoded);
          } else if (decoded is List) {
            for (final item in decoded) {
              if (item is Map<String, dynamic>) results.add(item);
            }
          }
        } catch (_) {
          // Skip malformed JSON-LD blocks
        }
      }
    } catch (e) {
      developer.log('[HtmlParser] JSON-LD extraction failed: $e', name: 'html');
    }
    return results;
  }

  /// Returns the first JSON-LD block matching [type], e.g. `"Product"`.
  static Map<String, dynamic>? findJsonLdByType(
    String htmlBody,
    String type,
  ) {
    final blocks = extractJsonLd(htmlBody);
    for (final block in blocks) {
      final blockType = block['@type'];
      if (blockType == type) return block;
      if (blockType is List && blockType.contains(type)) return block;
    }
    return null;
  }

  // ─── URL Normalisation ────────────────────────────────────────────────────

  /// Converts a relative or protocol-relative URL to an absolute HTTPS URL.
  ///
  /// Examples:
  ///   `/media/foo.jpg`      → `https://beta.softstore.pk/media/foo.jpg`
  ///   `//softstore.pk/img`  → `https://softstore.pk/img`
  ///   `https://…`           → unchanged
  static String toAbsoluteUrl(String url) {
    if (url.isEmpty) return url;
    if (url.startsWith('http://') || url.startsWith('https://')) return url;
    if (url.startsWith('//')) return 'https:$url';
    if (url.startsWith('/')) return '${EnvConfig.apiBaseUrl}$url';
    return url;
  }

  // ─── Image URL Extraction ─────────────────────────────────────────────────

  /// Extracts image URL(s) from a schema.org `"image"` field.
  ///
  /// The field can be:
  ///   - a String                  → `["url"]`
  ///   - a `List<String>`            → as-is
  ///   - an ImageObject Map        → `[imageObject["url"]]`
  ///   - a `List<ImageObject/String>`
  static List<String> extractSchemaImages(dynamic imageField) {
    if (imageField == null) return [];
    final raw = imageField is List ? imageField : [imageField];
    final urls = <String>[];
    for (final item in raw) {
      if (item is String) {
        urls.add(toAbsoluteUrl(item));
      } else if (item is Map<String, dynamic>) {
        final url = item['url'] as String? ?? item['contentUrl'] as String?;
        if (url != null) urls.add(toAbsoluteUrl(url));
      }
    }
    return urls;
  }

  // ─── General DOM Helpers ──────────────────────────────────────────────────

  /// Parses raw HTML and returns a [Document] for further querying.
  static Document parse(String htmlBody) => html_parser.parse(htmlBody);

  /// Returns trimmed text of the first element matching [selector], or null.
  static String? queryText(Document doc, String selector) {
    return doc.querySelector(selector)?.text.trim();
  }

  /// Returns [attribute] value of the first element matching [selector], or null.
  static String? queryAttr(Document doc, String selector, String attribute) {
    return doc.querySelector(selector)?.attributes[attribute];
  }

  /// Returns the number parsed from text such as `"1,234 products"`.
  static int? parseNumberFromText(String? text) {
    if (text == null) return null;
    final cleaned = text.replaceAll(',', '').replaceAll('.', '');
    final match = RegExp(r'\d+').firstMatch(cleaned);
    return match != null ? int.tryParse(match.group(0)!) : null;
  }

  /// Detects whether a server response is actually a redirect to the login page.
  /// Useful when followRedirects is disabled.
  static bool isLoginRedirect(String? location) {
    if (location == null) return false;
    return location.contains('/login');
  }

  /// Returns true if an HTML page contains a recognisable "no results" marker.
  static bool hasNoResults(String htmlBody) {
    final lower = htmlBody.toLowerCase();
    return lower.contains('no products found') ||
        lower.contains('no results') ||
        lower.contains('0 results');
  }
}
