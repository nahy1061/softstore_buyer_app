import 'package:flutter_bloc/flutter_bloc.dart';
import '../../auth/cubit/auth_cubit.dart';
import '../models/dashboard_stats_model.dart';
import '../models/user_model.dart';
import '../services/profile_service.dart';
import 'profile_state.dart';

class ProfileCubit extends Cubit<ProfileState> {
  final ProfileService _profileService;

  ProfileCubit({ProfileService? profileService})
      : _profileService = profileService ?? ProfileService(),
        super(const ProfileInitial());

  User get _currentUser {
    final s = state;
    if (s is ProfileLoaded) return s.user;
    if (s is ProfileUpdating) return s.user;
    if (s is ProfileUpdateSuccess) return s.user;
    if (s is ProfileChangingPassword) return s.user;
    if (s is PasswordChangeSuccess) return s.user;
    return const User(firstName: '', lastName: '', email: '');
  }

  DashboardStats get _currentStats {
    final s = state;
    if (s is ProfileLoaded) return s.stats;
    if (s is ProfileUpdating) return s.stats;
    if (s is ProfileUpdateSuccess) return s.stats;
    if (s is ProfileChangingPassword) return s.stats;
    if (s is PasswordChangeSuccess) return s.stats;
    return const DashboardStats();
  }

  /// Load profile and dashboard stats (API Mapping #22 + #25)
  Future<void> loadProfile() async {
    final previousUser = _currentUser;
    final previousStats = _currentStats;
    emit(const ProfileLoading());
    try {
      final results = await Future.wait([
        _profileService.getProfile(),
        _profileService.getDashboard(),
      ]);
      var user = results[0] as User;
      final stats = results[1] as DashboardStats;

      // If user from HTML has empty name but we had a valid local name, merge
      if (user.firstName.isEmpty && previousUser.firstName.isNotEmpty) {
        user = user.copyWith(
          firstName: previousUser.firstName,
          lastName: previousUser.lastName,
          phone: user.phone.isNotEmpty ? user.phone : previousUser.phone,
          email: user.email.isNotEmpty ? user.email : previousUser.email,
        );
      }

      emit(ProfileLoaded(user: user, stats: stats));
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      emit(ProfileError(message: cleanMsg));
      if (previousUser.firstName.isNotEmpty || previousUser.email.isNotEmpty) {
        emit(ProfileLoaded(user: previousUser, stats: previousStats));
      }
    }
  }

  /// Update profile (API Mapping #23)
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
    AuthCubit? authCubit,
  }) async {
    final currentUser = _currentUser;
    final currentStats = _currentStats;
    emit(ProfileUpdating(user: currentUser, stats: currentStats));
    try {
      await _profileService.updateProfile(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      final updatedUser = currentUser.copyWith(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      authCubit?.updateUser(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      emit(ProfileUpdateSuccess(
        user: updatedUser,
        stats: currentStats,
        message: 'Profile updated successfully',
      ));
      emit(ProfileLoaded(user: updatedUser, stats: currentStats));
    } catch (e) {
      final errorStr = e.toString();
      final isNetwork = errorStr.contains('internet') ||
          errorStr.contains('Failed host lookup') ||
          errorStr.contains('SocketException') ||
          errorStr.contains('Connection refused') ||
          errorStr.contains('timed out');

      final updatedUser = currentUser.copyWith(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );
      authCubit?.updateUser(
        firstName: firstName,
        lastName: lastName,
        phone: phone,
      );

      if (isNetwork) {
        emit(ProfileUpdateSuccess(
          user: updatedUser,
          stats: currentStats,
          message: 'Profile saved locally (offline mode)',
        ));
        emit(ProfileLoaded(user: updatedUser, stats: currentStats));
      } else {
        final cleanMsg = errorStr.replaceFirst('Exception: ', '');
        emit(ProfileError(message: cleanMsg));
        emit(ProfileLoaded(user: updatedUser, stats: currentStats));
      }
    }
  }

  /// Change password (API Mapping #24)
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    final currentUser = _currentUser;
    final currentStats = _currentStats;
    emit(ProfileChangingPassword(user: currentUser, stats: currentStats));
    try {
      await _profileService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      emit(PasswordChangeSuccess(
        user: currentUser,
        stats: currentStats,
        message: 'Password changed successfully',
      ));
      emit(ProfileLoaded(user: currentUser, stats: currentStats));
    } catch (e) {
      final cleanMsg = e.toString().replaceFirst('Exception: ', '');
      emit(ProfileError(message: cleanMsg));
      emit(ProfileLoaded(user: currentUser, stats: currentStats));
    }
  }

  void reset() => emit(const ProfileInitial());
}
