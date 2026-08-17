/// API endpoint paths for all backend requests.
/// Organized by feature area. Base URL is configured in env_config.dart.
class ApiEndpoints {
  // Checkout endpoints (session-cookie based PHP backend)
  static const String checkoutPage = '/store/checkout';
  static const String sendVerificationCode = '/store/checkout/send-code';
  static const String verifyCode = '/store/checkout/verify-code';
  static const String placeOrder = '/store/checkout';

  // API endpoints (JSON, no CSRF)
  static const String shippingQuote = '/api/store/shipping-quote';
  static const String validateCoupon = '/api/store/validate-coupon';

  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';

  // Products endpoints
  static const String getProducts = '/products';
  static const String getProductDetail = '/products/:slug';

  // Orders endpoints
  static const String getOrders = '/orders';
  static const String getOrderDetail = '/orders/:id';
  static const String trackOrder = '/orders/track';

  // Profile endpoints
  static const String getProfile = '/profile';
  static const String updateProfile = '/profile';
}
