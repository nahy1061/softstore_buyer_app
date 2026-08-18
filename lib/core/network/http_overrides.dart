import 'dart:io';

/// Custom HttpOverrides to bypass SSL certificate chain verification and set a standard browser
/// User-Agent for all HTTP requests (including Flutter Image.network for softstore.pk product images).
class SoftStoreHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback =
        (X509Certificate cert, String host, int port) => true;
    client.userAgent =
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36';
    return client;
  }
}

