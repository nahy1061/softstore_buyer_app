import 'package:flutter/foundation.dart';

/// Result of scanning a message text for personal contact information
@immutable
class ContactFilterResult {
  final bool hasViolation;
  final String? warningMessage;
  final List<String> detectedTypes;
  final String sanitizedText;

  const ContactFilterResult({
    required this.hasViolation,
    this.warningMessage,
    this.detectedTypes = const [],
    required this.sanitizedText,
  });

  @override
  String toString() =>
      'ContactFilterResult(hasViolation: $hasViolation, types: $detectedTypes, sanitized: $sanitizedText)';
}

/// Service to detect, prevent, and redact personal contact information
/// (Phone numbers, WhatsApp links, Emails, Social media links, Off-platform payment accounts)
/// to comply with SoftStore Marketplace Safety and Buyer Protection Policies.
class ContactFilterService {
  ContactFilterService._();
  static final ContactFilterService instance = ContactFilterService._();

  // ─── Regex Patterns ────────────────────────────────────────────────────────

  // 1. Email Pattern
  static final RegExp _emailRegex = RegExp(
    r'\b[A-Za-z0-9._%+-]+(?:\s*@\s*|\s*\[at\]\s*)[A-Za-z0-9.-]+(?:\s*\.\s*|\s*\[dot\]\s*)[A-Za-z]{2,}\b',
    caseSensitive: false,
  );

  // 2. WhatsApp Links
  static final RegExp _whatsappLinkRegex = RegExp(
    r'(?:https?:\/\/)?(?:www\.)?(?:wa\.me|api\.whatsapp\.com|chat\.whatsapp\.com)\/[A-Za-z0-9_/?=-]+',
    caseSensitive: false,
  );

  // 3. WhatsApp Keywords & Numbers
  static final RegExp _whatsappKeywordRegex = RegExp(
    r'\b(?:whatsapp|watsapp|whtsapp|whatsap|wtsapp|watsap|wa\s*(?:no|number|num|pe))\b(?:\s*[:=-]?\s*[\d\s+\-()]+)?',
    caseSensitive: false,
  );

  // 4. Social Media URLs & Profiles
  static final RegExp _socialUrlRegex = RegExp(
    r'(?:https?:\/\/)?(?:www\.)?(?:instagram\.com|facebook\.com|fb\.com|t\.me|telegram\.me|tiktok\.com|twitter\.com|x\.com)\/[A-Za-z0-9_.?=-]+',
    caseSensitive: false,
  );

  // 5. Direct Payment keywords (EasyPaisa / JazzCash / IBAN accounts)
  static final RegExp _paymentAccountRegex = RegExp(
    r'\b(?:easypaisa|easy\s*paisa|jazzcash|jazz\s*cash|iban|bank\s*transfer|account\s*(?:no|number))\b\s*[:=-]?\s*[\d\s+\-()]{6,}',
    caseSensitive: false,
  );

  // 6. Pakistani Mobile & Landline Phone Numbers
  static final RegExp _pkPhoneRegex = RegExp(
    r'(?:\+?92|0092|0)\s*(?:[-.\s]*\d){9,11}\b',
    caseSensitive: false,
  );

  // 7. General Phone Number sequences
  static final RegExp _generalPhoneRegex = RegExp(
    r'(?:\b|\+)\d{1,4}[-.\s]?\(?\d{2,4}\)?[-.\s]?\d{3,4}[-.\s]?\d{3,4}\b',
    caseSensitive: false,
  );

  // 8. Spaced out digits: e.g. "0 3 0 0 1 2 3 4 5 6 7"
  static final RegExp _spacedDigitsRegex = RegExp(
    r'\b(?:\d\s+){9,14}\d\b',
  );

  // ─── Public Analysis & Redaction Methods ───────────────────────────────────

  /// Scans [text] and returns a detailed [ContactFilterResult].
  ContactFilterResult analyze(String text) {
    if (text.trim().isEmpty) {
      return const ContactFilterResult(
        hasViolation: false,
        sanitizedText: '',
      );
    }

    final List<String> detectedTypes = [];
    String workingText = text;

    // 1. Check WhatsApp Links
    if (_whatsappLinkRegex.hasMatch(workingText)) {
      detectedTypes.add('WhatsApp Contact');
      workingText = workingText.replaceAll(_whatsappLinkRegex, '§§WA_LINK§§');
    }

    // 2. Check WhatsApp Keywords
    if (_whatsappKeywordRegex.hasMatch(workingText)) {
      detectedTypes.add('WhatsApp Contact');
      workingText = workingText.replaceAll(_whatsappKeywordRegex, '§§WA_INFO§§');
    }

    // 3. Check Social Media URLs
    if (_socialUrlRegex.hasMatch(workingText)) {
      detectedTypes.add('Social Media Profile');
      workingText = workingText.replaceAll(_socialUrlRegex, '§§SOCIAL§§');
    }

    // 4. Check Emails
    if (_emailRegex.hasMatch(workingText)) {
      detectedTypes.add('Email Address');
      workingText = workingText.replaceAll(_emailRegex, '§§EMAIL§§');
    }

    // 5. Check Direct Payment Accounts
    if (_paymentAccountRegex.hasMatch(workingText)) {
      detectedTypes.add('Direct Payment Account');
      workingText = workingText.replaceAll(_paymentAccountRegex, '§§PAYMENT§§');
    }

    // 6. Check Phone Numbers
    if (_pkPhoneRegex.hasMatch(workingText) || _generalPhoneRegex.hasMatch(workingText)) {
      detectedTypes.add('Phone Number');
      workingText = workingText.replaceAll(_pkPhoneRegex, '§§PHONE§§');
      workingText = workingText.replaceAll(_generalPhoneRegex, '§§PHONE§§');
    }

    // 7. Check Spaced Digits
    if (_spacedDigitsRegex.hasMatch(workingText)) {
      detectedTypes.add('Phone Number');
      workingText = workingText.replaceAll(_spacedDigitsRegex, '§§PHONE§§');
    }

    // Map all unique tokens to user-facing masked representations
    final sanitized = workingText
        .replaceAll('§§WA_LINK§§', '[WhatsApp Link Hidden]')
        .replaceAll('§§WA_INFO§§', '[WhatsApp Info Hidden]')
        .replaceAll('§§SOCIAL§§', '[Social Link Hidden]')
        .replaceAll('§§EMAIL§§', '[Email Address Hidden]')
        .replaceAll('§§PAYMENT§§', '[Payment Details Hidden]')
        .replaceAll('§§PHONE§§', '[Phone Number Hidden]');

    final hasViolation = detectedTypes.isNotEmpty;
    String? warningMessage;

    if (hasViolation) {
      final typesStr = detectedTypes.toSet().join(', ');
      warningMessage =
          'Sharing personal contact information ($typesStr) is not permitted. '
          'Please keep all communication within SoftStore for your safety and buyer protection.';
    }

    return ContactFilterResult(
      hasViolation: hasViolation,
      warningMessage: warningMessage,
      detectedTypes: detectedTypes.toSet().toList(),
      sanitizedText: sanitized,
    );
  }

  /// Convenience check: returns `true` if text contains any restricted contact info.
  bool containsContactInfo(String text) {
    return analyze(text).hasViolation;
  }

  /// Redacts sensitive contact information from [text] for safe display on screen.
  String redact(String text) {
    return analyze(text).sanitizedText;
  }
}
