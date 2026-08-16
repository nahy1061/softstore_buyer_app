import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../networking/web_session_client.dart';
import '../models/buyer.dart';
import '../constants/app_constants.dart';

enum SessionPhase { restoring, signedIn, signedOut }

class SessionStore extends ChangeNotifier {
  static final SessionStore instance = SessionStore._();
  SessionStore._();

  SessionPhase _phase = SessionPhase.restoring;
  Buyer? _buyer;

  SessionPhase get phase => _phase;
  Buyer? get buyer => _buyer;
  bool get isSignedIn => _phase == SessionPhase.signedIn;

  Future<void> restore() async {
    _phase = SessionPhase.restoring;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 900));

    final signedIn = await WebSessionClient.shared.checkSignedIn();
    if (signedIn) {
      await _loadCachedBuyer();
      _phase = SessionPhase.signedIn;
    } else {
      _phase = SessionPhase.signedOut;
    }
    notifyListeners();
  }

  Future<void> _loadCachedBuyer() async {
    final prefs = await SharedPreferences.getInstance();
    final email = prefs.getString(AppConstants.buyerEmailKey);
    final name = prefs.getString(AppConstants.buyerNameKey);
    final id = prefs.getInt(AppConstants.buyerIdKey);
    if (email != null && id != null) {
      final parts = name?.split(' ') ?? [];
      _buyer = Buyer(
        id: id,
        firstName: parts.isNotEmpty ? parts.first : null,
        lastName: parts.length > 1 ? parts.sublist(1).join(' ') : null,
        email: email,
        emailVerified: true,
      );
    }
  }

  Future<void> signIn(Buyer buyer) async {
    _buyer = buyer;
    _phase = SessionPhase.signedIn;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.buyerEmailKey, buyer.email);
    await prefs.setString(AppConstants.buyerNameKey, buyer.fullName);
    await prefs.setInt(AppConstants.buyerIdKey, buyer.id);
    notifyListeners();
  }

  Future<void> signOut() async {
    await WebSessionClient.shared.clearSession();
    _buyer = null;
    _phase = SessionPhase.signedOut;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AppConstants.buyerEmailKey);
    await prefs.remove(AppConstants.buyerNameKey);
    await prefs.remove(AppConstants.buyerIdKey);
    notifyListeners();
  }

  void updateBuyer(Buyer buyer) {
    _buyer = buyer;
    notifyListeners();
    SharedPreferences.getInstance().then((prefs) {
      prefs.setString(AppConstants.buyerEmailKey, buyer.email);
      prefs.setString(AppConstants.buyerNameKey, buyer.fullName);
      prefs.setInt(AppConstants.buyerIdKey, buyer.id);
    });
  }
}
