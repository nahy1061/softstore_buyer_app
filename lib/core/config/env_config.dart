/// Environment configuration read from --dart-define flags.
/// Defaults to development for safety.
class EnvConfig {
  static const String appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'SoftStore',
  );

  static const String siteName = String.fromEnvironment(
    'SITE_NAME',
    defaultValue: 'SoftStore',
  );

  static const String baseUrl = String.fromEnvironment(
    'BASE_URL',
    defaultValue: 'https://softstore.pk',
  );

  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'dev'
  );

  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
    defaultValue: 'softstore-dev',
  );

  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
    defaultValue: '',
  );

  /// reCAPTCHA v3 site key for login/register
  static const String reCaptchaSiteKey = String.fromEnvironment(
    'RECAPTCHA_SITE_KEY',
    defaultValue: String.fromEnvironment(
      'RECAPTCHA_KEY',
      defaultValue: '6Ldqn3ctAAAAAIrfgKNTGbqPVJhsP1jYITlxdArv',
    ),
  );

  /// Google OAuth client ID (for future Google Sign-In)
  static const String googleClientId = String.fromEnvironment(
    'GOOGLE_CLIENT_ID',
    defaultValue:
        '40211309448-3v1tcc991u2fru0l8im5g2p1od2c3e.apps.googleusercontent.com',
  );

  /// OneSignal App ID for push notifications and announcements
  static const String oneSignalAppId = String.fromEnvironment(
    'ONESIGNAL_APP_ID',
    defaultValue: 'YOUR_ONESIGNAL_APP_ID',
  );

  // Helper methods
  static bool get isProd => environment == 'prod';
  static bool get isDev => environment == 'dev';
  static bool get isStaging => environment == 'staging';

  static String get apiBaseUrl => baseUrl;
}

