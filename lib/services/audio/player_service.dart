import 'package:just_audio/just_audio.dart';

/// Thin wrapper over just_audio for preview + feed playback.
///
/// Handles both local files (Phase 1 recordings/drafts) and remote URLs (once
/// audio lives in Cloud Storage), so callers don't branch on the source.
class PlayerService {
  final AudioPlayer _player = AudioPlayer();

  Stream<Duration> get position => _player.positionStream;
  Stream<Duration?> get duration => _player.durationStream;
  Stream<PlayerState> get playerState => _player.playerStateStream;
  bool get isPlaying => _player.playing;

  Future<void> playSource(String uri) async {
    final isRemote = uri.startsWith('http://') || uri.startsWith('https://');
    if (isRemote) {
      await _player.setUrl(uri);
    } else {
      await _player.setFilePath(uri);
    }
    await _player.play();
  }

  Future<void> pause() => _player.pause();
  Future<void> resume() => _player.play();
  Future<void> seek(Duration position) => _player.seek(position);
  Future<void> stop() => _player.stop();

  Future<void> dispose() => _player.dispose();
}
