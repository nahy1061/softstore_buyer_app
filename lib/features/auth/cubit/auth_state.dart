import 'package:equatable/equatable.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

/// Initial state — checking session on app start
class AuthInitial extends AuthState {
  const AuthInitial();
}

/// Currently checking if user has a session
class AuthChecking extends AuthState {
  const AuthChecking();
}

/// User is not authenticated — must login/register
class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

/// User authenticated via explicit login/register in this session
class AuthAuthenticated extends AuthState {
  final String? email;
  const AuthAuthenticated({this.email});

  @override
  List<Object?> get props => [email];
}

/// Login in progress
class AuthLoggingIn extends AuthState {
  const AuthLoggingIn();
}

/// Registration in progress
class AuthRegistering extends AuthState {
  const AuthRegistering();
}

/// Login/register succeeded — triggers navigation
class AuthLoginSuccess extends AuthState {
  const AuthLoginSuccess();
}

/// Auth operation failed
class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}
