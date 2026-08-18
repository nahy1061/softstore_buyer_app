import 'package:equatable/equatable.dart';
import '../models/user_model.dart';
import '../models/dashboard_stats_model.dart';

abstract class ProfileState extends Equatable {
  const ProfileState();

  @override
  List<Object?> get props => [];
}

class ProfileInitial extends ProfileState {
  const ProfileInitial();
}

class ProfileLoading extends ProfileState {
  const ProfileLoading();
}

class ProfileLoaded extends ProfileState {
  final User user;
  final DashboardStats stats;

  const ProfileLoaded({
    required this.user,
    required this.stats,
  });

  @override
  List<Object?> get props => [user, stats];
}

class ProfileUpdating extends ProfileState {
  final User user;
  final DashboardStats stats;

  const ProfileUpdating({
    required this.user,
    required this.stats,
  });

  @override
  List<Object?> get props => [user, stats];
}

class ProfileUpdateSuccess extends ProfileState {
  final User user;
  final DashboardStats stats;
  final String message;

  const ProfileUpdateSuccess({
    required this.user,
    required this.stats,
    required this.message,
  });

  @override
  List<Object?> get props => [user, stats, message];
}

class ProfileChangingPassword extends ProfileState {
  final User user;
  final DashboardStats stats;

  const ProfileChangingPassword({
    required this.user,
    required this.stats,
  });

  @override
  List<Object?> get props => [user, stats];
}

class PasswordChangeSuccess extends ProfileState {
  final User user;
  final DashboardStats stats;
  final String message;

  const PasswordChangeSuccess({
    required this.user,
    required this.stats,
    required this.message,
  });

  @override
  List<Object?> get props => [user, stats, message];
}

class ProfileError extends ProfileState {
  final String message;

  const ProfileError({required this.message});

  @override
  List<Object?> get props => [message];
}
