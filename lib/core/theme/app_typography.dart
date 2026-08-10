import 'package:flutter/material.dart';

abstract final class AppTypography {
  static const String _inter = 'Inter';
  static const String _googleSans = 'Google Sans';
  static const String _robotoMono = 'Roboto Mono';

  // Headings (Google Sans)
  static const TextStyle screenTitle = TextStyle(
    fontFamily: _googleSans,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle sectionHeading = TextStyle(
    fontFamily: _googleSans,
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // Body Text (Inter)
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _inter,
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _inter,
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _inter,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  // Labels (Inter)
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _inter,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: _inter,
    fontSize: 12,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _inter,
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );

  // Product-Specific Styles
  static const TextStyle productName = TextStyle(
    fontFamily: _inter,
    fontSize: 14,
    fontWeight: FontWeight.w500,
  );

  static const TextStyle productNameDetail = TextStyle(
    fontFamily: _googleSans,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  // Price Styles (Roboto Mono)
  static const TextStyle pricePrimary = TextStyle(
    fontFamily: _robotoMono,
    fontSize: 18,
    fontWeight: FontWeight.w700,
  );

  static const TextStyle priceStrikethrough = TextStyle(
    fontFamily: _robotoMono,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    decoration: TextDecoration.lineThrough,
  );

  static const TextStyle priceTotal = TextStyle(
    fontFamily: _robotoMono,
    fontSize: 20,
    fontWeight: FontWeight.w700,
  );

  // Button Text (Google Sans)
  static const TextStyle buttonText = TextStyle(
    fontFamily: _googleSans,
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  // Badge Text (Inter)
  static const TextStyle badge = TextStyle(
    fontFamily: _inter,
    fontSize: 12,
    fontWeight: FontWeight.w700,
  );

  // Error/Helper Text
  static const TextStyle errorText = TextStyle(
    fontFamily: _inter,
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  // Overline (Tiny labels)
  static const TextStyle overline = TextStyle(
    fontFamily: _inter,
    fontSize: 10,
    fontWeight: FontWeight.w500,
  );
}
