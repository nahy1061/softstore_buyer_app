/// API endpoint paths for all backend requests.
/// Organized by feature area. Base URL is configured in env_config.dart.
class ApiEndpoints {
  // Auth endpoints
  static const String login = '/auth/login';
  static const String register = '/auth/register';
  static const String logout = '/auth/logout';
  static const String googleAuth = '/auth/google';
  static const String verifyOtp = '/auth/verify-otp';
  static const String resendOtp = '/auth/resend-otp';
  static const String forgotPassword = '/auth/forgot-password';
  static const String resetPassword = '/auth/reset-password';
  static const String checkSession = '/auth/me';
  static const String refreshToken = '/auth/refresh-token';

  // Products endpoints
  static const String getProducts = '/products';
  static const String getProductDetail = '/products/:slug';
  static const String getProductReviews = '/products/:slug/reviews';
  static const String getRelatedProducts = '/products/:slug/related';

  // Categories endpoints
  static const String getCategories = '/categories';
  static const String getCategoryProducts = '/categories/:slug/products';

  // Search endpoints
  static const String getSearchSuggestions = '/search/suggestions';
  static const String searchProducts = '/search';

  // Seller endpoints
  static const String getSellerStore = '/sellers/:slug';
  static const String getSellerProducts = '/sellers/:slug/products';
  static const String followSeller = '/sellers/:slug/follow';
  static const String unfollowSeller = '/sellers/:slug/unfollow';

  // Cart endpoints
  static const String validateCartItem = '/cart/validate-item';
  static const String validateCart = '/cart/validate';

  // Wishlist endpoints
  static const String getWishlist = '/wishlist';
  static const String addToWishlist = '/wishlist';
  static const String removeFromWishlist = '/wishlist/:productId';
  static const String checkWishlisted = '/wishlist/check';

  // Checkout endpoints
  static const String sendCheckoutOtp = '/checkout/send-otp';
  static const String verifyCheckoutOtp = '/checkout/verify-otp';
  static const String validateCoupon = '/checkout/validate-coupon';
  static const String placeOrder = '/checkout/place-order';
  static const String getCheckoutRecommendations = '/checkout/recommendations';

  // Orders endpoints
  static const String getOrders = '/orders';
  static const String getOrderDetail = '/orders/:id';
  static const String trackOrder = '/orders/track';
  static const String cancelOrder = '/orders/:id/cancel';

  // Returns endpoints
  static const String getReturns = '/returns';
  static const String getReturnDetail = '/returns/:id';
  static const String submitReturn = '/returns';
  static const String uploadReturnEvidence = '/returns/:id/upload-evidence';

  // Profile endpoints
  static const String getProfile = '/profile';
  static const String updateProfile = '/profile';
  static const String changePassword = '/profile/change-password';

  // Addresses endpoints
  static const String getAddresses = '/addresses';
  static const String addAddress = '/addresses';
  static const String updateAddress = '/addresses/:id';
  static const String deleteAddress = '/addresses/:id';
  static const String setDefaultAddress = '/addresses/:id/set-default';

  // Notifications endpoints
  static const String getNotifications = '/notifications';
  static const String markNotificationRead = '/notifications/:id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static const String registerFcmToken = '/notifications/register-token';

  // Support endpoints
  static const String createSupportTicket = '/support/tickets';
  static const String getSupportTickets = '/support/tickets';
  static const String getSupportTicketMessages = '/support/tickets/:id/messages';
  static const String sendSupportMessage = '/support/tickets/:id/messages';
}
