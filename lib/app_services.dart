import 'package:supabase_flutter/supabase_flutter.dart' as sb;

import 'config/app_config.dart';
import 'config/env.dart';
import 'repositories/auth_repository.dart';
import 'repositories/podcast_repository.dart';
import 'services/audio/player_service.dart';
import 'services/storage/audio_storage.dart';

/// Simple dependency container passed down via Provider.
///
/// Everything is behind an interface or config, so swapping the local
/// implementations for Supabase-backed ones is a change here only.
class AppServices {
  AppServices({
    required this.config,
    required this.auth,
    required this.podcasts,
    required this.audioStorage,
    required this.player,
  });

  final AppConfig config;
  final AuthRepository auth;
  final PodcastRepository podcasts;
  final AudioStorage audioStorage;
  final PlayerService player;

  /// Fully-local wiring: offline, no backend required. Used for tests and as
  /// the fallback when Supabase env vars are absent.
  factory AppServices.local() => AppServices(
        config: AppConfig.defaults,
        auth: LocalAuthRepository(),
        podcasts: LocalPodcastRepository(),
        audioStorage: LocalAudioStorage(),
        player: JustAudioPlayerService(),
      );

  /// Supabase-backed wiring: Auth + audio Storage in the cloud. Podcast
  /// metadata stays local in Phase 1 (Postgres metadata is a later phase).
  /// Assumes [sb.Supabase.initialize] has already run.
  factory AppServices.supabase() {
    final client = sb.Supabase.instance.client;
    return AppServices(
      config: AppConfig.defaults,
      auth: SupabaseAuthRepository(client.auth),
      podcasts: LocalPodcastRepository(),
      audioStorage: SupabaseAudioStorage(client.storage),
      player: JustAudioPlayerService(),
    );
  }

  /// Picks Supabase wiring when credentials were provided at build time,
  /// otherwise the local fallback.
  factory AppServices.auto() =>
      Env.hasSupabase ? AppServices.supabase() : AppServices.local();

  Future<void> dispose() async {
    await player.dispose();
  }
}
