import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/theme/app_theme.dart';
import '../features/auth/cubit/auth_cubit.dart';
import '../features/cart/cubit/cart_cubit.dart';
import '../features/profile/cubit/profile_cubit.dart';
import '../features/profile/cubit/address_cubit.dart';
import 'router.dart';

class SoftstoreBuyerApp extends StatelessWidget {
  const SoftstoreBuyerApp({super.key});

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
        theme: AppTheme.light,
        routerConfig: goRouter,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
