import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/storage/session_store.dart';
import '../app/splash_screen.dart';
import '../app/main_tab.dart';

class RootWidget extends StatelessWidget {
  const RootWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SessionStore>(
      builder: (context, session, _) {
        switch (session.phase) {
          case SessionPhase.restoring:
            return const SplashScreen();
          case SessionPhase.signedIn:
          case SessionPhase.signedOut:
            return const MainTabView();
        }
      },
    );
  }
}
