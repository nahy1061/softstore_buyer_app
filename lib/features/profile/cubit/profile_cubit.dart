import 'package:flutter_bloc/flutter_bloc.dart';
import '../models/user_model.dart';
import '../models/dashboard_stats_model.dart';
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
    emit(const ProfileLoading());
    try {
      final results = await Future.wait([
        _profileService.getProfile(),
        _profileService.getDashboard(),
      ]);
      final user = results[0] as User;
      final stats = results[1] as DashboardStats;
      emit(ProfileLoaded(user: user, stats: stats));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
    }
  }

  /// Update profile (API Mapping #23)
  Future<void> updateProfile({
    required String firstName,
    required String lastName,
    required String phone,
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
      emit(ProfileUpdateSuccess(
        user: updatedUser,
        stats: currentStats,
        message: 'Profile updated successfully',
      ));
      emit(ProfileLoaded(user: updatedUser, stats: currentStats));
    } catch (e) {
      emit(ProfileError(message: e.toString()));
      emit(ProfileLoaded(user: currentUser, stats: currentStats));
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
      emit(ProfileError(message: e.toString()));
      emit(ProfileLoaded(user: currentUser, stats: currentStats));
    }
  }

  void reset() => emit(const ProfileInitial());
}
