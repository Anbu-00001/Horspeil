import 'package:just_audio/just_audio.dart';

/// Playback seam for preview + feed playback.
///
/// An interface so screens depend on the capability, not on just_audio. The
/// concrete [JustAudioPlayerService] eagerly initialises the native platform in
/// its constructor, which throws under the headless `flutter test` harness — so
/// tests inject a lightweight fake instead of constructing the real player.
abstract interface class PlayerService {
  Stream<Duration> get position;
  Stream<Duration?> get duration;
  Stream<PlayerState> get playerState;
  bool get isPlaying;

  Future<void> playSource(String uri);
  Future<void> pause();
  Future<void> resume();
  Future<void> seek(Duration position);
  Future<void> stop();
  Future<void> dispose();
}

/// Thin wrapper over just_audio. Handles both local files (Phase 1
/// recordings/drafts) and remote URLs (audio in Supabase Storage), so callers
/// don't branch on the source.
class JustAudioPlayerService implements PlayerService {
  final AudioPlayer _player = AudioPlayer();

  @override
  Stream<Duration> get position => _player.positionStream;
  @override
  Stream<Duration?> get duration => _player.durationStream;
  @override
  Stream<PlayerState> get playerState => _player.playerStateStream;
  @override
  bool get isPlaying => _player.playing;

  @override
  Future<void> playSource(String uri) async {
    final isRemote = uri.startsWith('http://') || uri.startsWith('https://');
    if (isRemote) {
      await _player.setUrl(uri);
    } else {
      await _player.setFilePath(uri);
    }
    await _player.play();
  }

  @override
  Future<void> pause() => _player.pause();
  @override
  Future<void> resume() => _player.play();
  @override
  Future<void> seek(Duration position) => _player.seek(position);
  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> dispose() => _player.dispose();
}
