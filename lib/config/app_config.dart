import '../models/podcast_category.dart';
import '../models/cefr_level.dart';

/// Tunables for the on-device German language gate.
///
/// IMPORTANT: the sherpa-onnx spoken-language-ID API returns only a top-1
/// language string with NO confidence score, so we cannot threshold on a
/// probability. Instead we sample several windows across the clip, run language
/// ID on each, and require a supermajority to be [targetLang] (see
/// LanguageVoteAggregator). Every number here is a knob, not a magic constant.
class LanguageGateConfig {
  const LanguageGateConfig({
    this.targetLang = 'de',
    this.sampleRate = 16000,
    this.windowSeconds = 20.0,
    this.maxWindows = 5,
    this.minAcceptFraction = 0.6,
    this.minWindowsForDecision = 1,
  });

  /// ISO-639-1 code that must be spoken (German).
  final String targetLang;

  /// Sample rate fed to the model. Whisper works at 16 kHz.
  final int sampleRate;

  /// Length of each analysed window, in seconds.
  final double windowSeconds;

  /// Max number of windows sampled evenly across the clip.
  final int maxWindows;

  /// Fraction of analysed windows that must be [targetLang] to ACCEPT.
  final double minAcceptFraction;

  /// Below this many analysed windows the result is UNCERTAIN, not a hard
  /// reject (e.g. a clip too short / silent to sample).
  final int minWindowsForDecision;

  LanguageGateConfig copyWith({
    String? targetLang,
    int? sampleRate,
    double? windowSeconds,
    int? maxWindows,
    double? minAcceptFraction,
    int? minWindowsForDecision,
  }) {
    return LanguageGateConfig(
      targetLang: targetLang ?? this.targetLang,
      sampleRate: sampleRate ?? this.sampleRate,
      windowSeconds: windowSeconds ?? this.windowSeconds,
      maxWindows: maxWindows ?? this.maxWindows,
      minAcceptFraction: minAcceptFraction ?? this.minAcceptFraction,
      minWindowsForDecision: minWindowsForDecision ?? this.minWindowsForDecision,
    );
  }
}

/// Where the on-device Whisper language-ID model is fetched from.
///
/// The model (~98 MB int8) is downloaded on first run and cached, rather than
/// bundled, to keep the app binary small. URLs/filenames live here so they are
/// never hardcoded inside logic and can be swapped (e.g. to a self-hosted
/// mirror or a larger model) without touching the gate.
class WhisperModelSource {
  const WhisperModelSource({
    this.baseUrl =
        'https://huggingface.co/csukuangfj/sherpa-onnx-whisper-tiny/resolve/main',
    this.encoderFile = 'tiny-encoder.int8.onnx',
    this.decoderFile = 'tiny-decoder.int8.onnx',
    this.encoderSha256,
    this.decoderSha256,
    this.version = 'whisper-tiny-int8-v1',
  });

  final String baseUrl;
  final String encoderFile;
  final String decoderFile;

  /// Optional integrity checks. Left null until the exact hashes are pinned —
  /// we deliberately do NOT hardcode an unverified checksum (a wrong one would
  /// reject a valid download). When set, the provisioner enforces them.
  final String? encoderSha256;
  final String? decoderSha256;

  /// Cache-dir subfolder; bump when the model changes to force a re-download.
  final String version;

  String get encoderUrl => '$baseUrl/$encoderFile';
  String get decoderUrl => '$baseUrl/$decoderFile';
}

/// Top-level, immutable app configuration. Nothing product-shaping is hardcoded
/// in feature code — it is read from here (and can later be overlaid by remote
/// config / .env without changing call sites).
class AppConfig {
  const AppConfig({
    this.appName = 'Hörspiel',
    this.languageGate = const LanguageGateConfig(),
    this.modelSource = const WhisperModelSource(),
  });

  final String appName;
  final LanguageGateConfig languageGate;
  final WhisperModelSource modelSource;

  /// The active category taxonomy (see PodcastCategory for the topic-vs-genre note).
  List<PodcastCategory> get categories => PodcastCategory.values;

  /// CEFR levels offered for filtering (Phase 4).
  List<CefrLevel> get cefrLevels => CefrLevel.values;

  static const AppConfig defaults = AppConfig();
}
