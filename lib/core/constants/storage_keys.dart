/// All SharedPreferences and SecureStorage key names.
/// Organized by feature to avoid collisions.
class StorageKeys {
  // Auth - SecureStorage
  static const String authToken = 'auth_token';
  static const String refreshToken = 'refresh_token';
  static const String sessionId = 'session_id';

  // User - SharedPreferences
  static const String userId = 'user_id';
  static const String userName = 'user_name';
  static const String userEmail = 'user_email';
  static const String userPhone = 'user_phone';

  // Cart - SharedPreferences
  static const String cartItems = 'cart_items';
  static const String cartLastModified = 'cart_last_modified';

  // Wishlist - SharedPreferences (wishlist data cached locally)
  static const String wishlistItems = 'wishlist_items';

  // Preferences - SharedPreferences
  static const String themeMode = 'theme_mode';
  static const String notificationsEnabled = 'notifications_enabled';
  static const String lastAppVersion = 'last_app_version';

  // Search - SharedPreferences
  static const String recentSearches = 'recent_searches';

  // Device - SharedPreferences
  static const String deviceFcmToken = 'device_fcm_token';
  static const String deviceId = 'device_id';

  // Session - SecureStorage
  static const String lastSessionTime = 'last_session_time';
  static const String sessionExpiryTime = 'session_expiry_time';

  // Feature flags - SharedPreferences
  static const String useMockRepositories = 'use_mock_repositories';
  static const String enableDetailedLogs = 'enable_detailed_logs';

  // Messaging - SharedPreferences (productId → threadUrl cache)
  static const String conversationCache = 'conversation_cache';

  // Recently viewed products - SharedPreferences
  static const String recentlyViewed = 'recently_viewed';

  // Followed stores - SharedPreferences (client-side only)
  static const String followedStores = 'followed_stores';
}
