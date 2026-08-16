import 'package:flutter/material.dart';

abstract final class AppColors {
  // Brand Colors
  static const Color primary = Color(0xFFFF6F00);
  static const Color primaryDark = Color(0xFFE65100);
  static const Color secondary = Color(0xFFFFB300);

  // Surface Colors
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceAlt = Color(0xFFFAFAFA);
  static const Color background = Color(0xFFF8F9FA);

  // Text Colors
  static const Color textPrimary = Color(0xFF202124);
  static const Color textSecondary = Color(0xFF5F6368);
  static const Color textDisabled = Color(0xFF9AA0A6);

  // Feedback Colors
  static const Color error = Color(0xFFB71C1C);
  static const Color success = Color(0xFF1B5E20);
  static const Color warning = Color(0xFFE65100);

  // UI Colors
  static const Color divider = Color(0xFFE5E7EB);
  static const Color disabled = Color(0xFFE5E7EB);
  static const Color shimmerBase = Color(0xFFE5E7EB);
  static const Color shimmerHighlight = Color(0xFFF5F6F7);
  static const Color scrim = Color(0x66000000);
  static const Color snackbar = Color(0xFF202124);
  static const Color badgeRed = Color(0xFFB71C1C);

  // Status Badge Colors
  static const Color statusPending = Color(0xFFFFB300);
  static const Color statusProcessing = Color(0xFFFF6F00);
  static const Color statusShipped = Color(0xFFE65100);
  static const Color statusDelivered = Color(0xFF1B5E20);
  static const Color statusCancelled = Color(0xFFB71C1C);
  static const Color statusRefunded = Color(0xFF5F6368);
}
