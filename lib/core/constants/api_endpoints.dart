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

  // Profile endpoints (API Mapping #22-#25)
  static const String getProfile = '/store/account/profile';
  static const String updateProfile = '/store/account/profile';
  static const String changePassword = '/store/account/password';
  static const String getDashboard = '/store/account/dashboard';

  // Addresses endpoints (API Mapping #26-#28)
  static const String getAddresses = '/store/account/addresses';
  static const String addAddress = '/store/account/addresses';
  static const String deleteAddress = '/store/account/addresses/:id/delete';

  // Wishlist endpoints (API Mapping #36-#37)
  static const String getWishlist = '/store/account/wishlist';
  static const String toggleWishlist = '/store/wishlist/toggle';

  // Checkout endpoints
  static const String sendCheckoutOtp = '/checkout/send-otp';
  static const String verifyCheckoutOtp = '/checkout/verify-otp';
  static const String validateCoupon = '/checkout/validate-coupon';
  static const String placeOrder = '/checkout/place-order';
  static const String getCheckoutRecommendations = '/checkout/recommendations';

  // Orders endpoints (API Mapping #17-#21)
  static const String getOrders = '/store/account/orders';
  static const String getOrderDetail = '/store/account/orders/:id';
  static const String trackOrder = '/store/track-order';
  static const String cancelOrder = '/orders/:id/cancel';
  static const String requestReturn = '/store/account/orders/:id/return';
  static const String getReturns = '/store/account/returns';
  static const String getReturnDetail = '/returns/:id';
  static const String submitReturn = '/returns';
  static const String uploadReturnEvidence = '/returns/:id/upload-evidence';

  // Messages endpoints (API Mapping #29-#32)
  static const String getMessages = '/store/messages';
  static const String newMessage = '/store/messages/new';

  // Support endpoints (API Mapping #33-#35)
  static const String getSupportTickets = '/store/support/tickets';
  static const String createSupportTicket = '/store/support/tickets';
  static const String getSupportTicketDetail = '/store/support/tickets/:id';
  static const String getSupportTicketMessages = '/store/support/tickets/:id/messages';
  static const String sendSupportMessage = '/store/support/tickets/:id/messages';

  // Notifications endpoints
  static const String getNotifications = '/notifications';
  static const String markNotificationRead = '/notifications/:id/read';
  static const String markAllNotificationsRead = '/notifications/read-all';
  static const String registerFcmToken = '/notifications/register-token';
}
