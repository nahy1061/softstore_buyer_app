import 'package:equatable/equatable.dart';
import '../models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state — session check hasn't run yet (splash screen)
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Session is being checked or an auth action is in progress
class AuthLoading extends AuthState {
  const AuthLoading();
}

/// User is authenticated
class AuthAuthenticated extends AuthState {
  final User user;
  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

/// User is not authenticated (logged out or session expired)
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// An auth operation failed (login/register/etc.)
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Email verification OTP was sent
class AuthOtpSent extends AuthState {
  final String email;
  const AuthOtpSent(this.email);

  @override
  List<Object?> get props => [email];
}

/// Email verification completed successfully
class AuthOtpVerified extends AuthState {
  const AuthOtpVerified();
}
