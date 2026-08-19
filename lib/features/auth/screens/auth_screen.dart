import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../cubit/auth_cubit.dart';
import 'login_screen.dart';
import 'register_screen.dart';

/// Modal container for Authentication (Login / Register).
/// Opens when user taps "Buy Now" or "Sign In" on Profile screen.
/// Smoothly transitions between Login and Register views without closing the bottom sheet.
class AuthScreen extends StatefulWidget {
  final bool initialIsRegister;

  const AuthScreen({
    super.key,
    this.initialIsRegister = false,
  });

  /// Static helper to open the Auth flow as a modal bottom sheet.
  /// Returns `true` if login/registration was successful.
  static Future<bool?> show(
    BuildContext context, {
    bool isRegister = false,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => BlocProvider.value(
        value: context.read<AuthCubit>(),
        child: AuthScreen(initialIsRegister: isRegister),
      ),
    );
  }

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _isRegister;

  @override
  void initState() {
    super.initState();
    _isRegister = widget.initialIsRegister;
  }

  @override
  Widget build(BuildContext context) {
    return _isRegister
        ? RegisterScreen(
            isModal: true,
            onSwitchToLogin: () {
              if (mounted) setState(() => _isRegister = false);
            },
            onClosed: () {
              if (mounted) Navigator.of(context).pop(false);
            },
          )
        : LoginScreen(
            isModal: true,
            onSwitchToRegister: () {
              if (mounted) setState(() => _isRegister = true);
            },
            onClosed: () {
              if (mounted) Navigator.of(context).pop(false);
            },
          );
  }
}
