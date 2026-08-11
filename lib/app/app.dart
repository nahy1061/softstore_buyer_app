import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../core/theme/app_theme.dart';
import '../features/orders/cubit/order_cubit.dart';
import 'router.dart';

class SoftstoreBuyerApp extends StatelessWidget {
  const SoftstoreBuyerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => OrderCubit()),
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
