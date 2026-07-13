import 'config/app_config.dart';
import 'repositories/auth_repository.dart';
import 'repositories/podcast_repository.dart';
import 'services/audio/player_service.dart';

/// Simple dependency container passed down via Provider.
///
/// Everything is behind an interface or config, so swapping the local
/// implementations for Firebase-backed ones is a change here only.
class AppServices {
  AppServices({
    required this.config,
    required this.auth,
    required this.podcasts,
    required this.player,
  });

  final AppConfig config;
  final AuthRepository auth;
  final PodcastRepository podcasts;
  final PlayerService player;

  /// Wiring for Phase 1: local, offline, no Firebase project required.
  factory AppServices.local() => AppServices(
        config: AppConfig.defaults,
        auth: LocalAuthRepository(),
        podcasts: LocalPodcastRepository(),
        player: PlayerService(),
      );

  Future<void> dispose() async {
    await player.dispose();
  }
}
