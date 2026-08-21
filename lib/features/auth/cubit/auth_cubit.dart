import 'dart:developer' as developer;

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../../../core/services/notification_service.dart';
import '../../support/data/support_repository.dart';
import '../../cart/repository/cart_repository.dart';
import '../models/user_model.dart';
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
        developer.log('[AuthCubit] Session restored: ${user.email}', name: 'auth');
        NotificationService.instance.setBuyerUser(
          email: user.email,
          userId: user.id,
          phone: user.phone,
          firstName: user.firstName,
        );
        await SupportRepository().setUserId(user.email);
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthUnauthenticated());
      }
    } catch (e) {
      developer.log('[AuthCubit] Session restore failed: $e', name: 'auth');
      emit(const AuthUnauthenticated());
    }
  }

  /// Refreshes user data from the backend Session API without full loading state.
  /// Used after OTP verification or profile updates.
  Future<User?> refreshUser() async {
    try {
      final user = await _repo.restoreSession();
      if (user != null) {
        developer.log('[AuthCubit] User refreshed: ${user.email}, isEmailVerified: ${user.isEmailVerified}', name: 'auth');
        NotificationService.instance.setBuyerUser(
          email: user.email,
          userId: user.id,
          phone: user.phone,
          firstName: user.firstName,
        );
        await SupportRepository().setUserId(user.email);
        emit(AuthAuthenticated(user));
        return user;
      }
    } catch (e) {
      developer.log('[AuthCubit] Session refresh error: $e', name: 'auth');
    }

    if (state is AuthAuthenticated) {
      final current = (state as AuthAuthenticated).user;
      final isVerified = await CartRepository.instance.isEmailVerified(current.email);
      if (isVerified && !current.isEmailVerified) {
        final updated = current.copyWith(isEmailVerified: true);
        emit(AuthAuthenticated(updated));
        return updated;
      }
      return current;
    }

    return null;
  }

  /// Updates the verification status of the current user in state.
  void updateEmailVerificationStatus(bool isVerified) {
    if (state is AuthAuthenticated) {
      final current = (state as AuthAuthenticated).user;
      emit(AuthAuthenticated(current.copyWith(isEmailVerified: isVerified)));
    }
  }

  // ─── Login ────────────────────────────────────────────────────────────────

  Future<void> login({
    required String email,
    required String password,
    required String recaptchaToken,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await _repo.login(
        email: email,
        password: password,
        recaptchaToken: recaptchaToken,
      );
      NotificationService.instance.setBuyerUser(
        email: user.email,
        userId: user.id,
        phone: user.phone,
        firstName: user.firstName,
      );
      SupportRepository().setUserId(user.email);
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
    required String recaptchaToken,
  }) async {
    emit(const AuthLoading());
    try {
      final user = await _repo.register(
        firstName: firstName,
        email: email,
        password: password,
        lastName: lastName,
        phone: phone,
        recaptchaToken: recaptchaToken,
      );
      NotificationService.instance.setBuyerUser(
        email: user.email,
        userId: user.id,
        phone: user.phone,
        firstName: user.firstName,
      );
      SupportRepository().setUserId(user.email);
      emit(AuthAuthenticated(user));
    } on AuthFailure catch (e) {
      emit(AuthError(e.message));
    } on NetworkFailure catch (e) {
      emit(AuthError(e.message));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // ─── Logout ───────────────────────────────────────────────────────────────

  Future<void> logout() async {
    await SupportRepository().clearCache();
    await NotificationService.instance.clearUserOnLogout();
    await _repo.logout();
    emit(const AuthUnauthenticated());
  }

  // ─── Email Verification ───────────────────────────────────────────────────

  /// Sends a 6-digit OTP to [email] using the existing Send OTP endpoint.
  Future<void> sendVerificationCode(
    String email, {
    String? name,
    String? phone,
    bool isResend = false,
  }) async {
    try {
      await _repo.sendVerificationCode(
        email,
        name: name,
        phone: phone,
        isResend: isResend,
      );
    } on AuthFailure {
      rethrow;
    } on NetworkFailure {
      rethrow;
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  /// Verifies the OTP [code] with the existing Verify OTP endpoint.
  /// On success, marks email verified in local cache and refreshes user session.
  Future<bool> verifyCode(String code, {String? email}) async {
    try {
      final success = await _repo.verifyCode(code);
      if (success) {
        final targetEmail = email ?? (currentUser is User ? (currentUser as User).email : '');
        if (targetEmail.isNotEmpty) {
          await CartRepository.instance.markEmailVerified(targetEmail);
        }
        await refreshUser();
        updateEmailVerificationStatus(true);
        return true;
      }
      return false;
    } on AuthFailure {
      rethrow;
    } on NetworkFailure {
      rethrow;
    } catch (e) {
      throw AuthFailure(e.toString());
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  /// Updates current user profile details in state.
  void updateUser({
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
  }) {
    if (state is AuthAuthenticated) {
      final current = (state as AuthAuthenticated).user;
      final updated = current.copyWith(
        firstName: firstName ?? current.firstName,
        lastName: lastName ?? current.lastName,
        phone: phone ?? current.phone,
        email: email ?? current.email,
      );
      emit(AuthAuthenticated(updated));
    }
  }

  /// Returns the currently authenticated user, or null.
  User? get currentUser =>
      state is AuthAuthenticated ? (state as AuthAuthenticated).user : null;
}
