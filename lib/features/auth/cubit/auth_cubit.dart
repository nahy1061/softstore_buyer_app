import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../repository/auth_repository.dart';
import 'auth_state.dart';

/// Manages authentication state for the entire app.
///
/// Inject via [BlocProvider] at the top level in [main.dart] so all screens
/// can access the current auth status.
class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthInitial());

  final AuthRepository _repo = AuthRepository.instance;

  // ─── Session Restoration ─────────────────────────────────────────────────

  /// Called on app launch. Checks if a persisted session cookie is valid.
  /// Emits [AuthAuthenticated] or [AuthUnauthenticated].
  Future<void> restoreSession() async {
    emit(const AuthLoading());
    try {
      final user = await _repo.restoreSession();
      if (user != null) {
        debugPrint('[AuthCubit] Session restored: ${user.email}');
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      debugPrint('[AuthCubit] Session restore failed: $e');
      emit(const AuthUnauthenticated());
    }
  }

  // ─── Login ────────────────────────────────────────────────────────────────

  Future<void> login({
    required String email,
    required String password,
    String recaptchaToken = '',
  }) async {
    emit(const AuthLoading());
    try {
      final user = await _repo.login(
        email: email,
        password: password,
        recaptchaToken: recaptchaToken,
      );
      emit(AuthAuthenticated(user));
    } on AuthFailure catch (e) {
      emit(AuthError(e.message));
    } on NetworkFailure catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ─── Register ─────────────────────────────────────────────────────────────

  Future<void> register({
    required String firstName,
    required String email,
    required String password,
    String? lastName,
    String? phone,
    String recaptchaToken = '',
  }) async {
    debugPrint('[AuthCubit] Register attempt: email=$email');
    emit(const AuthLoading());
    try {
      debugPrint('[AuthCubit] Captcha token length: ${recaptchaToken.length}');
      final user = await _repo.register(
        firstName: firstName,
        email: email,
        password: password,
        lastName: lastName,
        phone: phone,
        recaptchaToken: recaptchaToken,
      );
      debugPrint('[AuthCubit] Register SUCCESS: ${user.email}');
      emit(AuthAuthenticated(user));
    } on AuthFailure catch (e) {
      debugPrint('[AuthCubit] Register AuthFailure: ${e.message}');
      emit(AuthError(e.message));
    } on NetworkFailure catch (e) {
      debugPrint('[AuthCubit] Register NetworkFailure: ${e.message}');
      emit(AuthError(e.message));
    } catch (e) {
      debugPrint('[AuthCubit] Register unexpected error: $e');
      emit(AuthError(e.toString()));
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await _repo.logout();
    emit(const AuthUnauthenticated());
  }

  // ─── Email Verification ───────────────────────────────────────────────────

  Future<void> sendVerificationCode(String email) async {
    emit(const AuthLoading());
    try {
      await _repo.sendVerificationCode(email);
      emit(AuthOtpSent(email));
    } on AuthFailure catch (e) {
      emit(AuthError(e.message));
    } on NetworkFailure catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> verifyCode(String code) async {
    emit(const AuthLoading());
    try {
      final success = await _repo.verifyCode(code);
      if (success) {
        emit(const AuthOtpVerified());
      } else {
        emit(const AuthError('Invalid or expired verification code.'));
      }
    } on AuthFailure catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Returns the currently authenticated user, or null.
  dynamic get currentUser =>
      state is AuthAuthenticated ? (state as AuthAuthenticated).user : null;
}
