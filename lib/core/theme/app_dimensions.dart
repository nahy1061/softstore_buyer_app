import 'package:flutter/material.dart';

abstract final class AppDimensions {
  // Border Radius
  static final BorderRadius radiusSm = BorderRadius.circular(10);
  static final BorderRadius radiusMd = BorderRadius.circular(14);
  static final BorderRadius radiusLg = BorderRadius.circular(20);

  // Elevation
  static const double elevationCard = 2.0;
  static const double elevationSheet = 8.0;
  static const double elevationFab = 6.0;

  // Component Sizes
  static const double touchTarget = 48.0;
  static const double bottomNavHeight = 56.0;
  static const double appBarHeight = 56.0;
  static const double stickyBarHeight = 64.0;
  static const double productImageRatio = 0.6; // 60% of card height
  static const double listImageSize = 80.0;

  // Card Shadows
  static final List<BoxShadow> cardShadow = [
    const BoxShadow(
      color: Color(0x14000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  // Sheet Shadows
  static final List<BoxShadow> sheetShadow = [
    const BoxShadow(
      color: Color(0x26000000),
      blurRadius: 16,
      offset: Offset(0, -4),
    ),
  ];

  // FAB Shadows
  static final List<BoxShadow> fabShadow = [
    const BoxShadow(
      color: Color(0x26000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];
}
