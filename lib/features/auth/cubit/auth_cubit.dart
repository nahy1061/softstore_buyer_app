import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/storage_keys.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(const AuthState()) {
    _loadSession();
  }

  Future<void> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(StorageKeys.authToken);
    final userId = prefs.getString(StorageKeys.userId);
    final userName = prefs.getString(StorageKeys.userName);
    if (token != null && token.isNotEmpty) {
      emit(AuthState(
        isLoggedIn: true,
        userId: userId,
        userName: userName,
      ));
    }
  }

  Future<void> login({
    required String token,
    String? userId,
    String? userName,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(StorageKeys.authToken, token);
    if (userId != null) await prefs.setString(StorageKeys.userId, userId);
    if (userName != null) await prefs.setString(StorageKeys.userName, userName);
    emit(AuthState(
      isLoggedIn: true,
      userId: userId,
      userName: userName,
    ));
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(StorageKeys.authToken);
    await prefs.remove(StorageKeys.userId);
    await prefs.remove(StorageKeys.userName);
    emit(const AuthState());
  }

  void setLoggedIn(bool value) {
    emit(state.copyWith(isLoggedIn: value));
  }
}
