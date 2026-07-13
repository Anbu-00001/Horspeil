import 'dart:async';

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
