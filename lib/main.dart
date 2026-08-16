import 'package:flutter/material.dart' hide RootWidget;
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'core/storage/session_store.dart';
import 'core/storage/cart_store.dart';
import 'core/theme/app_theme.dart';
import 'features/app/root_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitDown]);
  await CartStore.instance.load();
  runApp(const SoftStoreBuyerApp());
}

class SoftStoreBuyerApp extends StatefulWidget {
  const SoftStoreBuyerApp({super.key});

  @override
  State<SoftStoreBuyerApp> createState() => _SoftStoreBuyerAppState();
}

class _SoftStoreBuyerAppState extends State<SoftStoreBuyerApp> {
  @override
  void initState() {
    super.initState();
    SessionStore.instance.restore();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: SessionStore.instance),
        ChangeNotifierProvider.value(value: CartStore.instance),
      ],
      child: MaterialApp(
        title: 'SoftStore',
        debugShowCheckedModeBanner: false,
        theme: buildLightTheme(),
        darkTheme: buildDarkTheme(),
        themeMode: ThemeMode.light,
        home: const RootWidget(),
      ),
    );
  }
}
