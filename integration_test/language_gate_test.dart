// Real end-to-end verification of the German language gate.
//
// This is the single riskiest, previously-unproven piece of Phase 1: does the
// on-device sherpa-onnx Whisper language-ID model, wired through our windowing
// + voting logic, actually ACCEPT German speech and REJECT non-German speech?
//
// It runs the *real* native stack (no mocks): downloads the model via the real
// ModelProvisioner, loads the real FFI library, and classifies two real
// natural-speech fixtures. Because it needs the native .so and file/network IO,
// it runs as an integration test on a desktop/device, not as a unit test:
//
//   flutter test integration_test/language_gate_test.dart -d linux \
//     --dart-define=FIXTURES_DIR=$(pwd)/test/fixtures
//
// Fixtures (16 kHz mono s16 WAV) come from the sherpa-onnx language-ID demo:
//   de-german.wav  -> expected ACCEPT (detected 'de')
//   en-english.wav -> expected REJECT (detected non-'de')

import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:horspiel/config/app_config.dart';
import 'package:horspiel/services/audio/pcm_codec.dart';
import 'package:horspiel/services/language_gate/language_gate.dart';
import 'package:horspiel/services/language_gate/model_provisioner.dart';

/// Absolute path to the fixtures dir. Passed via --dart-define so the test does
/// not depend on the process working directory. Falls back to the conventional
/// location relative to the current directory.
const _fixturesDefine = String.fromEnvironment('FIXTURES_DIR');

String get _fixturesDir => _fixturesDefine.isNotEmpty
    ? _fixturesDefine
    : '${Directory.current.path}/test/fixtures';

/// Extracts the PCM payload and sample rate from a canonical PCM WAV file by
/// walking the RIFF chunks (robust to header size differences).
({Uint8List pcm, int sampleRate}) _readWavPcm(String path) {
  final bytes = File(path).readAsBytesSync();
  final data = ByteData.sublistView(bytes);

  // 'RIFF' .... 'WAVE'
  if (bytes.length < 12) {
    throw StateError('WAV too small: $path');
  }
  var offset = 12; // skip RIFF header
  int sampleRate = 16000;
  Uint8List? pcm;

  while (offset + 8 <= bytes.length) {
    final id = String.fromCharCodes(bytes.sublist(offset, offset + 4));
    final size = data.getUint32(offset + 4, Endian.little);
    final body = offset + 8;
    if (id == 'fmt ') {
      sampleRate = data.getUint32(body + 4, Endian.little);
    } else if (id == 'data') {
      pcm = Uint8List.sublistView(bytes, body, body + size);
    }
    offset = body + size + (size.isOdd ? 1 : 0); // chunks are word-aligned
  }

  if (pcm == null) throw StateError('No data chunk in WAV: $path');
  return (pcm: pcm, sampleRate: sampleRate);
}

Future<LanguageGate> _buildGate() async {
  final provisioner = ModelProvisioner();
  addTearDown(provisioner.dispose);
  final model = await provisioner.ensure();
  final gate = SherpaLanguageGate(
    model: model,
    config: AppConfig.defaults.languageGate,
  );
  addTearDown(gate.dispose);
  return gate;
}

Future<LanguageGateResultView> _classify(LanguageGate gate, String file) async {
  final wav = _readWavPcm('$_fixturesDir/$file');
  final samples = PcmCodec.pcm16ToFloat32(wav.pcm);
  final result = await gate.analyzeSamples(samples, wav.sampleRate);
  // ignore: avoid_print
  print('[$file] $result');
  return LanguageGateResultView(
    accepted: result.accepted,
    detectedLang: result.detectedLang,
    matchFraction: result.matchFraction,
  );
}

/// Minimal view to keep the assertions readable.
class LanguageGateResultView {
  LanguageGateResultView({
    required this.accepted,
    required this.detectedLang,
    required this.matchFraction,
  });
  final bool accepted;
  final String? detectedLang;
  final double matchFraction;
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('German language gate (real sherpa-onnx model)', () {
    late LanguageGate gate;

    setUpAll(() async {
      gate = await _buildGate();
    });

    testWidgets('accepts German speech', (tester) async {
      final r = await _classify(gate, 'de-german.wav');
      expect(r.detectedLang, 'de');
      expect(r.accepted, isTrue);
    }, timeout: const Timeout(Duration(minutes: 5)));

    testWidgets('rejects English speech', (tester) async {
      final r = await _classify(gate, 'en-english.wav');
      expect(r.detectedLang, isNot('de'));
      expect(r.accepted, isFalse);
    }, timeout: const Timeout(Duration(minutes: 5)));
  });
}
