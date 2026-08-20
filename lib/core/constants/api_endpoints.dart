/// API endpoint paths for all backend requests.
/// Base URL: https://softstore.pk (set in env_config.dart)
///
/// IMPORTANT: Most endpoints return HTML, not JSON.
/// JSON endpoints are only under /api/store/* and specific POST actions.
class ApiEndpoints {
  // ─── Authentication ─────────────────────────────────────────────────────────
  /// REST API endpoint for mobile/JSON authentication (bypasses HTML captcha)
  static const String apiAuthLogin = '/api/auth/login';

  /// GET to extract CSRF; POST with form data to authenticate
  static const String loginPage = '/login';
  static const String login = '/login';

  /// GET to extract CSRF; POST with form data to register
  static const String registerPage = '/register';
  static const String register = '/register';

  /// POST with CSRF to clear session cookie
  static const String logout = '/logout';

  /// POST JSON {id_token} — Google OAuth callback
  static const String googleCallback = '/auth/google/callback';
  static const String googleAuth = '/auth/google/callback';

  // ─── Email Verification (Checkout OTP) ──────────────────────────────────────
  /// POST JSON {email, name, phone} — sends 6-digit OTP
  static const String sendVerificationCode = '/store/checkout/send-code';
  static const String sendCheckoutOtp = '/store/checkout/send-code';

  /// POST JSON {code} — verifies OTP
  static const String verifyCode = '/store/checkout/verify-code';
  static const String verifyCheckoutOtp = '/store/checkout/verify-code';

  // ─── Session Restoration ────────────────────────────────────────────────────
  /// GET — parse user profile from HTML form inputs; 302→/login means expired
  /// NOTE: must match iOS AuthService.fetchProfile() path: /marketplace/account/profile
  static const String profilePage = '/marketplace/account/profile';
  static const String checkSession = '/marketplace/account/profile';

  // ─── Catalog ────────────────────────────────────────────────────────────────
  /// GET — homepage HTML with hero banners, categories, product rails
  static const String homepage = '/store';
  static const String storeHome = '/store';

  /// GET ?search=&category=&sort=&page= — product search results HTML
  static const String search = '/store';
  static const String searchProducts = '/store/search';

  /// GET ?q=... — live search suggestions JSON {products, categories}
  static const String searchSuggest = '/api/store/search-suggest';

  /// POST form {tenant_id, _csrf_token} — follow / unfollow seller store
  static const String followStore = '/store/follow';
  static const String unfollowStore = '/store/unfollow';

  /// GET /product/{slug} — product detail HTML with JSON-LD
  static const String productDetail = '/product/';

  /// GET /store/categories — categories list HTML
  static const String categories = '/store/categories';

  /// GET /store/category/{slug} — products filtered by category
  static const String categoryProducts = '/store/category/';

  /// GET /store/{slug} — seller/store profile HTML
  static const String sellerProfile = '/store/';
  static const String sellerStore = '/store';

  /// POST form {_csrf_token, product_id, rating, review_text}
  static const String submitReview = '/store/account/reviews';

  // ─── Cart / Checkout ────────────────────────────────────────────────────────
  /// POST JSON {items:[{id,qty}]} → {delivery_fee, free, currency}
  static const String shippingQuote = '/api/store/shipping-quote';

  /// POST JSON {code, subtotal} → {valid, discount_amount, message}
  static const String validateCoupon = '/api/store/validate-coupon';

  /// GET — extract CSRF for checkout POST
  static const String checkoutPage = '/store/checkout';
  static const String checkout = '/store/checkout';

  /// POST JSON body (with _csrf_token + csrf_token) → {success, invoice_number}
  static const String placeOrder = '/store/checkout';

  // ─── Orders ─────────────────────────────────────────────────────────────────
  /// GET — orders list HTML
  static const String ordersList = '/store/account/orders';
  static const String getOrders = '/store/account/orders';

  /// GET /store/account/orders/{invoiceNumber} — order detail HTML
  static const String orderDetail = '/store/account/orders/';
  static const String getOrderDetail = '/store/account/orders';

  /// POST (with CSRF) {invoice_number, phone} — guest order tracking HTML
  static const String trackOrder = '/store/track-order';

  /// POST multipart /store/account/orders/{invoice}/return
  static const String requestReturnSuffix = '/return';
  static const String requestReturn = '/store/account/orders';

  /// POST /store/account/orders/{invoice}/cancel
  static const String cancelOrderSuffix = '/cancel';
  static const String cancelOrder = '/store/account/orders/';
  static const String apiCancelOrder = '/api/buyer/orders/';

  /// GET — returns list HTML
  static const String returnsList = '/store/account/returns';

  // ─── Profile ────────────────────────────────────────────────────────────────
  /// POST form to profile page (same as GET profilePage)
  static const String updateProfile = '/store/account/profile';
  static const String profile = '/store/account/profile';
  static const String getProfile = '/store/account/profile';

  /// POST form {current_password, new_password}
  static const String changePassword = '/store/account/password';

  /// GET — dashboard stats HTML
  static const String dashboard = '/store/account/dashboard';
  static const String dashboardStats = '/store/account/dashboard';
  static const String getDashboard = '/store/account/dashboard';

  // ─── Addresses ──────────────────────────────────────────────────────────────
  /// GET — addresses list HTML; POST form to add
  static const String addresses = '/store/account/addresses';
  static const String getAddresses = '/store/account/addresses';
  static const String addAddress = '/store/account/addresses';

  /// POST /store/account/addresses/{id}/delete — delete address
  static const String deleteAddressSuffix = '/delete';
  static const String deleteAddress = '/store/account/addresses';

  // ─── Wishlist ───────────────────────────────────────────────────────────────
  /// GET — wishlist HTML (parse mpToggleWishlist(ID) onclick)
  static const String wishlistPage = '/store/account/wishlist';
  static const String wishlist = '/store/account/wishlist';

  /// POST form {product_id} → JSON {success, added}
  static const String toggleWishlist = '/store/wishlist/toggle';

  // ─── Messaging ──────────────────────────────────────────────────────────────
  /// GET — conversations list HTML
  static const String messagesList = '/store/messages';
  static const String messages = '/store/messages';

  /// POST form {product_id, message} → 302 to threadUrl
  static const String newMessage = '/store/messages/new';

  // ─── Support ────────────────────────────────────────────────────────────────
  /// GET — tickets list HTML; POST form to create ticket
  static const String ticketsList = '/store/support/tickets';
  static const String supportTickets = '/store/support/tickets';
  static const String createSupportTicket = '/store/support/tickets';
  static const String getSupportTickets = '/store/support/tickets';

  /// GET /store/support/tickets/{id} — ticket detail HTML; POST to reply
  static const String ticketDetail = '/store/support/tickets/';
  static const String getSupportTicketMessages = '/store/support/tickets';
  static const String sendSupportMessage = '/store/support/tickets';

  /// JSON API: GET /store/support/tickets/{id}/messages?after_id=N
  static const String ticketMessagesApi = '/store/support/tickets';

  /// JSON API: POST /store/support/tickets/{id} with JSON {message} and X-CSRF-TOKEN header
  static const String ticketReplyApi = '/store/support/tickets';
}
