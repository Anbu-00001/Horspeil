import 'dart:typed_data';

import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa;

import '../../config/app_config.dart';
import 'language_gate_result.dart';
import 'language_vote_aggregator.dart';
import 'model_provisioner.dart';

/// Detects whether a clip is spoken German.
abstract interface class LanguageGate {
  /// Analyse 16 kHz mono float samples in [-1, 1].
  Future<LanguageGateResult> analyzeSamples(Float32List samples, int sampleRate);

  Future<void> dispose();
}

/// On-device implementation backed by sherpa-onnx's Whisper spoken-language-ID.
///
/// The model exposes only a top-1 language string per clip (no score), so we
/// sample several windows across the audio, run language ID on each, and let
/// [LanguageVoteAggregator] decide by supermajority.
///
/// PERF NOTE: `compute()` is a synchronous native (FFI) call and is CPU-heavy.
/// For long clips with several windows this can block the UI thread. Phase 1
/// keeps it on the calling isolate for simplicity; moving the per-clip loop to
/// a background isolate (keeping one persistent identifier there) is a
/// well-scoped follow-up that won't change this interface.
class SherpaLanguageGate implements LanguageGate {
  SherpaLanguageGate({
    required this.model,
    LanguageGateConfig? config,
  }) : config = config ?? AppConfig.defaults.languageGate;

  final ProvisionedModel model;
  final LanguageGateConfig config;

  sherpa.SpokenLanguageIdentification? _slid;
  static bool _bindingsInitialized = false;

  void _ensureInitialized() {
    if (_slid != null) return;

    if (!_bindingsInitialized) {
      sherpa.initBindings();
      _bindingsInitialized = true;
    }

    _slid = sherpa.SpokenLanguageIdentification(
      sherpa.SpokenLanguageIdentificationConfig(
        whisper: sherpa.SpokenLanguageIdentificationWhisperConfig(
          encoder: model.encoderPath,
          decoder: model.decoderPath,
        ),
        numThreads: 2,
        provider: 'cpu',
      ),
    );
  }

  @override
  Future<LanguageGateResult> analyzeSamples(
      Float32List samples, int sampleRate) async {
    _ensureInitialized();
    final slid = _slid!;

    final windows = _selectWindows(samples, sampleRate);
    final perWindowLangs = <String>[];

    for (final window in windows) {
      final stream = slid.createStream();
      try {
        stream.acceptWaveform(samples: window, sampleRate: sampleRate);
        final result = slid.compute(stream);
        perWindowLangs.add(result.lang);
      } finally {
        stream.free();
      }
    }

    return LanguageVoteAggregator(config).aggregate(perWindowLangs);
  }

  /// Pick up to [config.maxWindows] evenly-spaced windows across the clip.
  /// If the clip is shorter than one window, analyse the whole clip once.
  List<Float32List> _selectWindows(Float32List samples, int sampleRate) {
    final windowLen = (config.windowSeconds * sampleRate).round();
    if (samples.length <= windowLen || config.maxWindows <= 1) {
      return [samples];
    }

    final n = config.maxWindows;
    final maxStart = samples.length - windowLen;
    final windows = <Float32List>[];
    for (var i = 0; i < n; i++) {
      final frac = i / (n - 1); // 0.0 .. 1.0 inclusive
      final start = (maxStart * frac).round().clamp(0, maxStart);
      windows.add(Float32List.sublistView(samples, start, start + windowLen));
    }
    return windows;
  }

  @override
  Future<void> dispose() async {
    _slid?.free();
    _slid = null;
  }
}
