/// Build-time secrets, injected via `--dart-define-from-file=.env`.
///
/// Nothing here is hardcoded: when the app is run/built without the env file,
/// both values are empty strings and [hasSupabase] is false, so the app falls
/// back to the fully-local Phase 1 wiring. The publishable key is client-safe
/// by design (protected by Storage RLS + row policies), so baking it into the
/// binary at build time is acceptable — unlike a service_role/secret key, which
/// must never reach the client.
///
/// Run with:
///   flutter run --dart-define-from-file=.env
class Env {
  const Env._();

  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabasePublishableKey =
      String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');

  /// True only when both values were supplied at build time.
  static bool get hasSupabase =>
      supabaseUrl.isNotEmpty && supabasePublishableKey.isNotEmpty;
}
