import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app_services.dart';
import 'repositories/auth_repository.dart';
import 'ui/home/home_shell.dart';
import 'ui/onboarding/onboarding_screen.dart';
import 'ui/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(HorspielApp(services: AppServices.local()));
}

class HorspielApp extends StatelessWidget {
  const HorspielApp({super.key, required this.services});

  final AppServices services;

  @override
  Widget build(BuildContext context) {
    return Provider<AppServices>.value(
      value: services,
      child: MaterialApp(
        title: 'Hörspiel',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        darkTheme: AppTheme.dark(),
        home: const AuthGate(),
      ),
    );
  }
}

/// Shows onboarding until signed in, then the main app shell.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AppServices>().auth;
    return StreamBuilder<AppUser?>(
      stream: auth.authState(),
      builder: (context, snapshot) {
        if (snapshot.data == null) return const OnboardingScreen();
        return const HomeShell();
      },
    );
  }
}
