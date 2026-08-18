import 'package:flutter_bloc/flutter_bloc.dart';
import '../services/auth_service.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthService _service = AuthService();

  AuthCubit() : super(const AuthInitial());

  /// Check if user has an existing session (call on app start).
  /// Only checks locally stored email — does NOT make network calls
  /// because the backend returns 200 HTML even for anonymous users.
  Future<void> checkSession() async {
    emit(const AuthChecking());
    try {
      final email = await _service.getStoredEmail();
      if (email != null && email.isNotEmpty) {
        // Found stored email — assume session may be valid.
        // Profile screen will verify on load and handle failures.
        emit(AuthAuthenticated(email: email));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (_) {
      emit(const AuthUnauthenticated());
    }
  }

  /// Login with email + password
  Future<void> login({
    required String email,
    required String password,
  }) async {
    emit(const AuthLoggingIn());
    try {
      await _service.login(email: email, password: password);
      emit(const AuthLoginSuccess());
      emit(AuthAuthenticated(email: email));
    } catch (e) {
      final message = _parseError(e);
      emit(AuthError(message));
      emit(const AuthUnauthenticated());
    }
  }

  /// Register new account
  Future<void> register({
    required String firstName,
    required String lastName,
    required String email,
    required String password,
  }) async {
    emit(const AuthRegistering());
    try {
      await _service.register(
        firstName: firstName,
        lastName: lastName,
        email: email,
        password: password,
      );
      emit(const AuthLoginSuccess());
      emit(AuthAuthenticated(email: email));
    } catch (e) {
      final message = _parseError(e);
      emit(AuthError(message));
      emit(const AuthUnauthenticated());
    }
  }

  /// Logout
  Future<void> logout() async {
    await _service.logout();
    emit(const AuthUnauthenticated());
  }

  /// Reset to unauthenticated (used when auth screen is dismissed)
  void resetToUnauthenticated() {
    emit(const AuthUnauthenticated());
  }

  String _parseError(dynamic error) {
    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }
    return 'Something went wrong. Please try again.';
  }
}
