/// Environment configuration read from --dart-define flags.
/// Defaults to development for safety.
class EnvConfig {
  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://api.dev.softstore.com',
  );

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'dev',
  );

  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'softstore-dev',
  );

  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );

  static const String reCaptchaKey = String.fromEnvironment(
    'RECAPTCHA_KEY',
    defaultValue: '',
  );

  // Helper methods
  static bool get isProd => environment == 'prod';
  static bool get isDev => environment == 'dev';
  static bool get isStaging => environment == 'staging';

  static String get apiBaseUrl => baseUrl;
}
