import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/cubit/auth_cubit.dart';
import '../features/auth/cubit/auth_state.dart';
import '../features/cart/cubit/cart_cubit.dart';
import '../features/profile/cubit/profile_cubit.dart';
import '../features/profile/cubit/address_cubit.dart';
import '../main.dart' show closeHiveBoxes;
import 'router.dart';

class SoftstoreBuyerApp extends StatefulWidget {
  const SoftstoreBuyerApp({super.key});

  @override
  State<SoftstoreBuyerApp> createState() => _SoftstoreBuyerAppState();
}

class _SoftstoreBuyerAppState extends State<SoftstoreBuyerApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.detached) {
      closeHiveBoxes();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit()),
        BlocProvider(create: (_) => CartCubit()),
        BlocProvider(create: (_) => ProfileCubit()),
        BlocProvider(create: (_) => AddressCubit()),
      ],
      child: MaterialApp.router(
        title: 'Softstore Buyer',
        theme: buildLightTheme(),
        routerConfig: goRouter,
        debugShowCheckedModeBanner: false,
        builder: (context, child) {
          return BlocListener<AuthCubit, AuthState>(
            listenWhen: (prev, curr) {
              final prevId = prev is AuthAuthenticated
                  ? (prev.user.id?.isNotEmpty == true ? prev.user.id : prev.user.email)
                  : null;
              final currId = curr is AuthAuthenticated
                  ? (curr.user.id?.isNotEmpty == true ? curr.user.id : curr.user.email)
                  : null;
              return prevId != currId;
            },
            listener: (context, state) {
              final cartCubit = context.read<CartCubit>();
              if (state is AuthAuthenticated) {
                // User logged in — switch to their user-specific cart and sync to server
                final user = state.user;
                final userId = (user.id != null && user.id!.isNotEmpty)
                    ? user.id
                    : (user.email.isNotEmpty ? user.email : null);
                cartCubit.reloadForUser(userId).then((_) {
                  cartCubit.syncToServer();
                });
              } else {
                // User logged out — switch to guest cart
                cartCubit.reloadForUser(null);
              }
            },
            child: child ?? const SizedBox.shrink(),
          );
        },
      ),
    );
  }
}
