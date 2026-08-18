import 'package:html/parser.dart' as html_parser;

/// Utility to extract CSRF tokens from SoftStore HTML pages.
class CsrfExtractor {
  /// Extracts the CSRF token from raw HTML response.
  /// Checks hidden input tags, meta tags, and inline JS variable definitions.
  static String? extract(String html) {
    if (html.isEmpty) return null;

    try {
      final doc = html_parser.parse(html);

      // 1. Look for input element: <input name="_csrf_token" value="...">
      final inputElement = doc.querySelector('input[name="_csrf_token"]') ??
          doc.querySelector('input[name="csrf_token"]') ??
          doc.querySelector('input[name="_token"]');

      final inputValue = inputElement?.attributes['value'];
      if (inputValue != null && inputValue.trim().isNotEmpty) {
        return inputValue.trim();
      }

      // 2. Look for meta element: <meta name="csrf-token" content="...">
      final metaElement = doc.querySelector('meta[name="csrf-token"]');
      final metaContent = metaElement?.attributes['content'];
      if (metaContent != null && metaContent.trim().isNotEmpty) {
        return metaContent.trim();
      }
    } catch (_) {
      // Fall through to regex if DOM parsing fails
    }

    // 3. Fallback regex patterns for HTML and Javascript variables
    final regexPatterns = [
      RegExp(r'''name=["']_?csrf_token["']\s+value=["']([^"']+)["']''', caseSensitive: false),
      RegExp(r'''value=["']([^"']+)["']\s+name=["']_?csrf_token["']''', caseSensitive: false),
      RegExp(r'''var\s+csrfToken\s*=\s*['"]([^'"]+)['"]''', caseSensitive: false),
      RegExp(r'''csrfToken\s*:\s*['"]([^'"]+)['"]''', caseSensitive: false),
      RegExp(r'''['"]_csrf_token['"]\s*:\s*['"]([^'"]+)['"]''', caseSensitive: false),
    ];

    for (final pattern in regexPatterns) {
      final match = pattern.firstMatch(html);
      if (match != null && match.groupCount >= 1) {
        final token = match.group(1);
        if (token != null && token.trim().isNotEmpty) {
          return token.trim();
        }
      }
    }

    return null;
  }
}
