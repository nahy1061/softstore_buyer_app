import '../core/networking/web_session_client.dart';
import '../core/networking/api_error.dart';
import '../core/models/buyer.dart';
import '../core/storage/session_store.dart';

class AuthService {
  final _web = WebSessionClient.shared;

  Future<Buyer> login(String email, String password, {String? recaptchaToken}) async {
    final csrf = await _web.fetchCsrf('/login');
    final fields = <String, String>{
      '_csrf_token': csrf,
      'email': email,
      'password': password,
    };
    if (recaptchaToken != null) fields['g-recaptcha-response'] = recaptchaToken;

    final (:html, :finalUrl) = await _web.postForm('/login', fields, referer: '/login');

    if (html.contains('alert-danger') || html.contains('invalid') || html.contains('Invalid')) {
      final errM = RegExp(r'alert[^>]*danger[^>]*>\s*(?:<[^>]+>)*\s*([^<]{5,200}?)\s*(?:</[^>]+>)*\s*</').firstMatch(html);
      throw ApiError(errM?.group(1)?.trim() ?? 'Invalid email or password.');
    }
    if (finalUrl.contains('/login') && !finalUrl.contains('/logout')) {
      throw ApiError('Login failed. Please check your credentials.');
    }

    return fetchProfile();
  }

  Future<void> register(String firstName, String lastName, String email, String password, {String? phone, String? recaptchaToken}) async {
    final csrf = await _web.fetchCsrf('/register');
    final fields = <String, String>{
      '_csrf_token': csrf,
      'first_name': firstName,
      'last_name': lastName,
      'email': email,
      'password': password,
      'password_confirmation': password,
    };
    if (phone != null && phone.isNotEmpty) fields['phone'] = phone;
    if (recaptchaToken != null) fields['g-recaptcha-response'] = recaptchaToken;

    final (:html, :finalUrl) = await _web.postForm('/register', fields, referer: '/register');
    if (html.contains('alert-danger')) {
      final errM = RegExp(r'alert[^>]*danger[^>]*>\s*(?:<[^>]+>)*\s*([^<]{5,200}?)\s*').firstMatch(html);
      throw ApiError(errM?.group(1)?.trim() ?? 'Registration failed. Please try again.');
    }
  }

  Future<void> forgotPassword(String email) async {
    final csrf = await _web.fetchCsrf('/forgot-password');
    await _web.postForm('/forgot-password', {'_csrf_token': csrf, 'email': email}, referer: '/forgot-password');
  }

  Future<void> logout() async {
    try {
      await _web.fetchHtml('/marketplace/logout');
    } catch (_) {}
    await SessionStore.instance.signOut();
  }

  Future<Buyer> fetchProfile() async {
    final html = await _web.fetchHtml('/marketplace/account/profile');
    return _parseProfile(html);
  }

  Buyer _parseProfile(String html) {
    String? first(String pattern) => RegExp(pattern, dotAll: true).firstMatch(html)?.group(1)?.trim();

    final email = first(r'type="email"[^>]*value="([^"]+)"')
        ?? first(r'name="email"[^>]*value="([^"]+)"')
        ?? first(r'"email":"([^"]+)"')
        ?? '';
    final firstName = first(r'name="first_name"[^>]*value="([^"]+)"') ?? '';
    final lastName = first(r'name="last_name"[^>]*value="([^"]+)"') ?? '';
    final phone = first(r'name="phone"[^>]*value="([^"]+)"');
    final idM = RegExp(r'id="buyer_id"[^>]*value="(\d+)"').firstMatch(html)
        ?? RegExp(r'"buyer_id":(\d+)').firstMatch(html);
    final id = int.tryParse(idM?.group(1) ?? '') ?? 0;

    return Buyer(
      id: id,
      firstName: firstName.isEmpty ? null : firstName,
      lastName: lastName.isEmpty ? null : lastName,
      email: email,
      phone: phone,
      emailVerified: true,
    );
  }
}
