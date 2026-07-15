import 'dart:async';

import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Minimal user identity used to attribute podcasts.
class AppUser {
  const AppUser({required this.id, required this.displayName, this.email});
  final String id;
  final String displayName;
  final String? email;
}

/// Auth seam. Phase 1 ships [LocalAuthRepository]; a FirebaseAuthRepository
/// implements the same interface later without touching call sites.
abstract interface class AuthRepository {
  AppUser? get currentUser;
  Stream<AppUser?> authState();

  /// Email/password are accepted for API shape parity with Firebase, but the
  /// local implementation does not verify them — it just mints a session.
  Future<AppUser> signIn({required String email, required String password});
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  });
  Future<AppUser> continueAsGuest();
  Future<void> signOut();
}

/// In-memory auth for local development. No real credentials, no persistence
/// across cold starts beyond the current session — enough to attribute uploads.
class LocalAuthRepository implements AuthRepository {
  AppUser? _current;
  final StreamController<AppUser?> _controller =
      StreamController<AppUser?>.broadcast();

  @override
  AppUser? get currentUser => _current;

  @override
  Stream<AppUser?> authState() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) {
    final name = email.contains('@') ? email.split('@').first : email;
    return _set(AppUser(id: 'local:$email', displayName: name, email: email));
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) {
    return _set(
        AppUser(id: 'local:$email', displayName: displayName, email: email));
  }

  @override
  Future<AppUser> continueAsGuest() {
    final id = 'guest:${DateTime.now().millisecondsSinceEpoch}';
    return _set(AppUser(id: id, displayName: 'Gast'));
  }

  @override
  Future<void> signOut() async {
    _current = null;
    _controller.add(null);
  }

  Future<AppUser> _set(AppUser user) async {
    _current = user;
    _controller.add(user);
    return user;
  }
}

/// Supabase-backed auth. Maps Supabase's [sb.User] onto [AppUser] so the rest
/// of the app never imports the Supabase SDK. Display name is stored in user
/// metadata (`display_name`) at sign-up and read back on every session.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._auth);

  final sb.GoTrueClient _auth;

  static const String _displayNameKey = 'display_name';

  AppUser? _toAppUser(sb.User? user) {
    if (user == null) return null;
    final metaName = user.userMetadata?[_displayNameKey] as String?;
    final fallback = user.email?.split('@').first ?? 'Gast';
    return AppUser(
      id: user.id,
      displayName: (metaName != null && metaName.isNotEmpty) ? metaName : fallback,
      email: user.email,
    );
  }

  @override
  AppUser? get currentUser => _toAppUser(_auth.currentUser);

  @override
  Stream<AppUser?> authState() async* {
    yield _toAppUser(_auth.currentUser);
    yield* _auth.onAuthStateChange.map((state) => _toAppUser(state.session?.user));
  }

  @override
  Future<AppUser> signIn({required String email, required String password}) async {
    final res = await _auth.signInWithPassword(email: email, password: password);
    final user = _toAppUser(res.user);
    if (user == null) throw StateError('Sign-in returned no user');
    return user;
  }

  @override
  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final res = await _auth.signUp(
      email: email,
      password: password,
      data: {_displayNameKey: displayName},
    );
    final user = _toAppUser(res.user);
    if (user == null) throw StateError('Sign-up returned no user');
    return user;
  }

  @override
  Future<AppUser> continueAsGuest() async {
    final res = await _auth.signInAnonymously();
    final user = _toAppUser(res.user);
    if (user == null) throw StateError('Anonymous sign-in returned no user');
    return user;
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
