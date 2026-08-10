import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';
import 'router.dart';

class SoftstoreBuyerApp extends StatelessWidget {
  const SoftstoreBuyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Softstore Buyer',
      theme: AppTheme.light,
      routerConfig: goRouter,
      debugShowCheckedModeBanner: false,
    );
    // TODO: Wrap with MultiBlocProvider when Cubits are ready:
    // return MultiBlocProvider(
    //   providers: [
    //     BlocProvider(create: (context) => AuthCubit()),
    //     BlocProvider(create: (context) => CartCubit()),
    //     BlocProvider(create: (context) => ConnectivityCubit()),
    //   ],
    //   child: MaterialApp.router(...),
    // );
  }
}
