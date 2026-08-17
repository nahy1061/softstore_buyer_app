/// API endpoint paths for all backend requests.
/// Organized by feature area. Base URL is configured in env_config.dart.
class ApiEndpoints {
  // Auth endpoints
  static const String login = '/login';
  static const String register = '/register';
  static const String logout = '/logout';
  static const String googleAuth = '/auth/google/callback';
  static const String checkSession = '/store/account/profile';

  // Checkout Email Verification OTP endpoints
  static const String sendCheckoutOtp = '/store/checkout/send-code';
  static const String verifyCheckoutOtp = '/store/checkout/verify-code';

  // Catalog & Products endpoints
  static const String storeHome = '/store';
  static const String searchProducts = '/store/search';
  static const String productDetail = '/product'; // /product/{slug}
  static const String categories = '/store/categories';
  static const String sellerStore = '/store'; // /store/{slug}

  // Cart & Checkout endpoints
  static const String shippingQuote = '/api/store/shipping-quote';
  static const String validateCoupon = '/api/store/validate-coupon';
  static const String checkout = '/store/checkout';

  // Wishlist endpoints
  static const String wishlist = '/store/account/wishlist';
  static const String toggleWishlist = '/store/wishlist/toggle';

  // Orders endpoints
  static const String getOrders = '/store/account/orders';
  static const String getOrderDetail = '/store/account/orders'; // /store/account/orders/{invoiceNumber}
  static const String trackOrder = '/store/track-order';
  static const String getReturns = '/store/account/returns';
  static const String requestReturn = '/store/account/orders'; // /store/account/orders/{invoiceNumber}/return

  // Profile & Addresses endpoints
  static const String profile = '/store/account/profile';
  static const String changePassword = '/store/account/password';
  static const String dashboardStats = '/store/account/dashboard';
  static const String addresses = '/store/account/addresses';
  static const String deleteAddress = '/store/account/addresses'; // /store/account/addresses/{id}/delete

  // Messaging & Chat endpoints
  static const String messages = '/store/messages';
  static const String newMessage = '/store/messages/new';

  // Support Tickets endpoints
  static const String supportTickets = '/store/support/tickets';
}
