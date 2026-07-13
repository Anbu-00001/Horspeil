import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import 'pcm_codec.dart';

/// The artefacts of one finished recording.
class RecordingResult {
  const RecordingResult({
    required this.wavPath,
    required this.pcmPath,
    required this.duration,
    required this.sampleRate,
  });

  /// Playable WAV (for preview + upload in Phase 1).
  final String wavPath;

  /// Raw headerless PCM (handy to feed the language gate window-by-window).
  final String pcmPath;

  final Duration duration;
  final int sampleRate;
}

/// Records mic audio straight to 16 kHz mono PCM — the exact format the language
/// gate and Whisper want — so no decoding/resampling step is needed for the gate
/// in Phase 1. PCM is streamed to disk (not held in memory) so long episodes
/// don't blow up the heap, then wrapped into a WAV on stop.
class RecorderService {
  RecorderService({this.sampleRate = 16000});

  final int sampleRate;
  final AudioRecorder _recorder = AudioRecorder();

  IOSink? _sink;
  File? _pcmFile;
  int _byteCount = 0;
  StreamSubscription<Uint8List>? _sub;
  final StreamController<double> _levels = StreamController<double>.broadcast();

  /// Emits a normalised 0..1 RMS level per audio chunk (drives the waveform UI).
  Stream<double> get levels => _levels.stream;

  bool get isRecording => _sub != null;

  Future<bool> hasPermission() => _recorder.hasPermission();

  Future<void> start() async {
    if (isRecording) return;
    if (!await hasPermission()) {
      throw StateError('Mikrofon-Berechtigung fehlt.');
    }

    final dir = await getApplicationDocumentsDirectory();
    final recDir = Directory(p.join(dir.path, 'recordings'));
    await recDir.create(recursive: true);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    _pcmFile = File(p.join(recDir.path, 'rec_$stamp.pcm'));
    _sink = _pcmFile!.openWrite();
    _byteCount = 0;

    final stream = await _recorder.startStream(
      RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: sampleRate,
        numChannels: 1,
      ),
    );

    _sub = stream.listen(
      (chunk) {
        _sink?.add(chunk);
        _byteCount += chunk.length;
        _levels.add(_rms(chunk));
      },
      onError: (Object e) => _levels.addError(e),
    );
  }

  Future<RecordingResult> stop() async {
    if (!isRecording) {
      throw StateError('Es läuft keine Aufnahme.');
    }
    await _recorder.stop();
    await _sub?.cancel();
    _sub = null;
    await _sink?.flush();
    await _sink?.close();
    _sink = null;

    final pcmPath = _pcmFile!.path;
    final wavPath = p.setExtension(pcmPath, '.wav');
    await PcmCodec.wavFromPcmFile(
      pcmPath: pcmPath,
      wavPath: wavPath,
      sampleRate: sampleRate,
    );

    final durationMs =
        (_byteCount / (2 * sampleRate) * 1000).round(); // 16-bit mono
    return RecordingResult(
      wavPath: wavPath,
      pcmPath: pcmPath,
      duration: Duration(milliseconds: durationMs),
      sampleRate: sampleRate,
    );
  }

  double _rms(Uint8List chunk) {
    final samples = chunk.length ~/ 2;
    if (samples == 0) return 0;
    final data = ByteData.sublistView(chunk, 0, samples * 2);
    var sumSquares = 0.0;
    for (var i = 0; i < samples; i++) {
      final s = data.getInt16(i * 2, Endian.little) / 32768.0;
      sumSquares += s * s;
    }
    return math.sqrt(sumSquares / samples).clamp(0.0, 1.0);
  }

  Future<void> dispose() async {
    await _sub?.cancel();
    await _sink?.close();
    await _recorder.dispose();
    await _levels.close();
  }
}
