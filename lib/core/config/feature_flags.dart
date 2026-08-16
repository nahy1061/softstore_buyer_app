/// Feature flags to toggle features on/off without rebuilding.
/// Read from --dart-define environment variables.
class FeatureFlags {
  // Use mock repositories instead of real API calls
  static const bool useMockRepositories = bool.fromEnvironment(
    'USE_MOCK',
    defaultValue: false,
  );

  // Enable detailed logging for debugging
  static const bool enableDetailedLogs = bool.fromEnvironment(
    'DEBUG_LOGS',
    defaultValue: false,
  );

  // Enable performance profiling
  static const bool enableProfiling = bool.fromEnvironment(
    'ENABLE_PROFILING',
    defaultValue: false,
  );

  // Enable network request logging
  static const bool enableNetworkLogging = bool.fromEnvironment(
    'NETWORK_LOGS',
    defaultValue: false,
  );

  // Force offline mode for testing
  static const bool forceOfflineMode = bool.fromEnvironment(
    'FORCE_OFFLINE',
    defaultValue: false,
  );

  // Enable deep linking
  static const bool enableDeepLinks = bool.fromEnvironment(
    'ENABLE_DEEP_LINKS',
    defaultValue: true,
  );
}
