class AppDurations {
  // Animation Durations
  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 200);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 450);

  // Page & Navigation
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration navigationTransition = Duration(milliseconds: 250);

  // Specialized Durations
  static const Duration shimmer = Duration(milliseconds: 1500);
  static const Duration snackbar = Duration(seconds: 3);
  static const Duration debounce = Duration(milliseconds: 300);

  // UI Interactions
  static const Duration tooltipWait = Duration(milliseconds: 500);
  static const Duration longPress = Duration(milliseconds: 500);

  // Batch Operation
  static const Duration staggered = Duration(milliseconds: 50);
}
