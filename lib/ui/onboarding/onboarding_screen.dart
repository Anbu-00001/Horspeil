import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_services.dart';
import '../../config/app_palette.dart';

/// Welcome + email auth. Mirrors the Stitch onboarding: the "Podcasts. Nur auf
/// Deutsch." hook, a primary CTA, and a fast guest path so the slice is
/// reachable without a real backend.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  bool _isSignUp = true;
  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _name.dispose();
    super.dispose();
  }

  /// Runs an auth action with a busy state and a user-facing error snackbar, so
  /// no auth failure (bad password, unconfirmed email, disabled provider, …)
  /// goes silently unhandled.
  Future<void> _runAuth(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      // On success, AuthGate swaps this screen out via the auth stream.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(_authError(e))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Friendly German message. Reads `.message` off Supabase's AuthException
  /// without importing the SDK here (keeps the repository seam intact).
  String _authError(Object e) {
    String detail;
    try {
      detail = ((e as dynamic).message as String?) ?? e.toString();
    } catch (_) {
      detail = e.toString();
    }
    return 'Anmeldung fehlgeschlagen: $detail';
  }

  Future<void> _submit() {
    final auth = context.read<AppServices>().auth;
    return _runAuth(() async {
      if (_isSignUp) {
        await auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          displayName: _name.text.trim().isEmpty ? 'Hörer' : _name.text.trim(),
        );
      } else {
        await auth.signIn(email: _email.text.trim(), password: _password.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 12),
                Text('Hörspiel',
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(color: AppPalette.primary)),
                const SizedBox(height: 24),
                Text.rich(
                  TextSpan(children: [
                    const TextSpan(text: 'Podcasts.\n'),
                    TextSpan(
                      text: 'Nur auf Deutsch.',
                      style: TextStyle(color: AppPalette.primary),
                    ),
                  ]),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Entdecke exklusive Hörspiele und Podcasts in deiner Sprache.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppPalette.mutedText),
                ),
                const SizedBox(height: 28),
                if (_isSignUp)
                  _field(_name, 'Name', TextInputType.name),
                _field(_email, 'E-Mail', TextInputType.emailAddress),
                _field(_password, 'Passwort', TextInputType.visiblePassword,
                    obscure: true),
                const SizedBox(height: 8),
                FilledButton(
                  onPressed: _busy ? null : _submit,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : Text(_isSignUp ? 'Kostenlos starten' : 'Anmelden'),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(_isSignUp
                      ? 'Bereits ein Konto? Anmelden'
                      : 'Noch kein Konto? Jetzt registrieren'),
                ),
                const Divider(height: 32),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _runAuth(
                          () => context.read<AppServices>().auth.continueAsGuest()),
                  child: const Text('Als Gast fortfahren'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, TextInputType type,
      {bool obscure = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: c,
        keyboardType: type,
        obscureText: obscure,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppPalette.surface,
          border:
              OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
