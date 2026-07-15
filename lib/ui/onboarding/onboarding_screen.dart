import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app_services.dart';
import '../../config/app_language.dart';
import '../../config/app_palette.dart';
import '../../config/locale_controller.dart';

/// Welcome + email auth. Mirrors the Stitch onboarding: the "Podcasts. Nur auf
/// Deutsch." hook, a primary CTA, and a fast guest path. Also hosts the DE/EN
/// language toggle — this is the first screen, so a user who can't read German
/// can switch the interface before going any further.
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
    final s = context.strings;
    setState(() => _busy = true);
    try {
      await action();
      // On success, AuthGate swaps this screen out via the auth stream.
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(s.authFailed(_reason(e)))));
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  /// Reads `.message` off Supabase's AuthException without importing the SDK
  /// here (keeps the repository seam intact).
  String _reason(Object e) {
    try {
      return ((e as dynamic).message as String?) ?? e.toString();
    } catch (_) {
      return e.toString();
    }
  }

  Future<void> _submit() {
    final auth = context.read<AppServices>().auth;
    final s = context.strings;
    return _runAuth(() async {
      if (_isSignUp) {
        await auth.signUp(
          email: _email.text.trim(),
          password: _password.text,
          displayName:
              _name.text.trim().isEmpty ? s.defaultListenerName : _name.text.trim(),
        );
      } else {
        await auth.signIn(email: _email.text.trim(), password: _password.text);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.l10n;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: _LanguageToggle(),
                ),
                const SizedBox(height: 4),
                Text(s.appName,
                    textAlign: TextAlign.center,
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(color: AppPalette.primary)),
                const SizedBox(height: 24),
                Text.rich(
                  TextSpan(children: [
                    TextSpan(text: '${s.onbTagline1}\n'),
                    TextSpan(
                      text: s.onbTagline2,
                      style: TextStyle(color: AppPalette.primary),
                    ),
                  ]),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  s.onbSubtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppPalette.mutedText),
                ),
                const SizedBox(height: 28),
                if (_isSignUp) _field(_name, s.fieldName, TextInputType.name),
                _field(_email, s.fieldEmail, TextInputType.emailAddress),
                _field(_password, s.fieldPassword, TextInputType.visiblePassword,
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
                      : Text(_isSignUp ? s.signUpCta : s.signInCta),
                ),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _isSignUp = !_isSignUp),
                  child: Text(_isSignUp ? s.toSignIn : s.toSignUp),
                ),
                const Divider(height: 32),
                OutlinedButton(
                  onPressed: _busy
                      ? null
                      : () => _runAuth(
                          () => context.read<AppServices>().auth.continueAsGuest()),
                  child: Text(s.guestCta),
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

/// Compact DE | EN segmented switch for the UI language.
class _LanguageToggle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final controller = context.watch<LocaleController>();
    return SegmentedButton<AppLanguage>(
      showSelectedIcon: false,
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStatePropertyAll(
            TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      ),
      segments: const [
        ButtonSegment(value: AppLanguage.de, label: Text('DE')),
        ButtonSegment(value: AppLanguage.en, label: Text('EN')),
      ],
      selected: {controller.language},
      onSelectionChanged: (sel) => controller.setLanguage(sel.first),
    );
  }
}
