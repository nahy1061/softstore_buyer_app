/// Application-level configuration constants.
/// All non-configurable values that affect business logic.
class AppConfig {
  // Delivery configuration
  static const double deliveryFee = 199.0;
  static const double freeDeliveryThreshold = 1500.0;

  // OTP configuration
  static const int otpLength = 6;
  static const Duration otpResendDelay = Duration(seconds: 60);
  static const int otpMaxRetries = 3;

  // Session configuration
  static const Duration sessionTimeout = Duration(minutes: 30);
  static const Duration sessionCheckInterval = Duration(minutes: 5);

  // Cart configuration
  static const int maxCartItems = 999;
  static const int minCartItemQty = 1;

  // Pagination
  static const int defaultPageSize = 20;
  static const int searchPageSize = 20;
  static const int orderPageSize = 10;
  static const int notificationPageSize = 20;

  // Return eligibility
  static const Duration returnEligibilityWindow = Duration(days: 7);

  // App versioning
  static const String appVersion = '1.0.0';
  static const String buildNumber = '1';

  // Network configuration
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
  static const int maxRetries = 2;
  static const Duration retryDelay = Duration(seconds: 1);

  // Image configuration
  static const int imageQualityCompression = 85;
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
}
