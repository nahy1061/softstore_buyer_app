import 'package:equatable/equatable.dart';

class AuthState extends Equatable {
  final bool isLoggedIn;
  final String? userId;
  final String? userName;

  const AuthState({
    this.isLoggedIn = false,
    this.userId,
    this.userName,
  });

  AuthState copyWith({bool? isLoggedIn, String? userId, String? userName}) {
    return AuthState(
      isLoggedIn: isLoggedIn ?? this.isLoggedIn,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
    );
  }

  @override
  List<Object?> get props => [isLoggedIn, userId, userName];
}
