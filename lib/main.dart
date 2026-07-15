import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_services.dart';
import 'config/env.dart';
import 'repositories/auth_repository.dart';
import 'ui/home/home_shell.dart';
import 'ui/onboarding/onboarding_screen.dart';
import 'ui/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase only when credentials were injected at build time
  // (--dart-define-from-file=.env). Without them the app runs fully local.
  if (Env.hasSupabase) {
    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
    );
  }

  runApp(HorspielApp(services: AppServices.auto()));
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
