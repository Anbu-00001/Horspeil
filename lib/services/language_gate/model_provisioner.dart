import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../config/app_config.dart';

/// Local paths to the provisioned Whisper language-ID model.
class ProvisionedModel {
  const ProvisionedModel({required this.encoderPath, required this.decoderPath});
  final String encoderPath;
  final String decoderPath;
}

/// Ensures the ~98 MB Whisper language-ID model is present on device.
///
/// Downloads each file on first run into the app-support directory (not
/// user-visible, survives app updates), streaming to a `.part` temp file and
/// renaming on success so a killed download never leaves a half file that looks
/// complete. If a source checksum is configured it is enforced; if not, the
/// download is accepted but a re-download is triggered when the file is missing.
class ModelProvisioner {
  ModelProvisioner({
    WhisperModelSource? source,
    http.Client? client,
  })  : source = source ?? AppConfig.defaults.modelSource,
        _client = client ?? http.Client();

  final WhisperModelSource source;
  final http.Client _client;

  /// Reports coarse progress in [0,1] across both files (optional).
  Future<ProvisionedModel> ensure({void Function(double progress)? onProgress}) async {
    final baseDir = await getApplicationSupportDirectory();
    final modelDir = Directory(p.join(baseDir.path, 'models', source.version));
    await modelDir.create(recursive: true);

    final encoder = await _ensureFile(
      dir: modelDir,
      url: source.encoderUrl,
      fileName: source.encoderFile,
      sha256Hex: source.encoderSha256,
      onProgress: onProgress == null ? null : (f) => onProgress(f * 0.5),
    );
    final decoder = await _ensureFile(
      dir: modelDir,
      url: source.decoderUrl,
      fileName: source.decoderFile,
      sha256Hex: source.decoderSha256,
      onProgress: onProgress == null ? null : (f) => onProgress(0.5 + f * 0.5),
    );

    return ProvisionedModel(encoderPath: encoder, decoderPath: decoder);
  }

  Future<String> _ensureFile({
    required Directory dir,
    required String url,
    required String fileName,
    required String? sha256Hex,
    void Function(double fileProgress)? onProgress,
  }) async {
    final file = File(p.join(dir.path, fileName));

    if (await file.exists()) {
      if (sha256Hex == null || await _sha256(file) == sha256Hex.toLowerCase()) {
        onProgress?.call(1);
        return file.path;
      }
      // Corrupt / stale cache — remove and re-download.
      await file.delete();
    }

    final tmp = File('${file.path}.part');
    if (await tmp.exists()) await tmp.delete();

    final request = http.Request('GET', Uri.parse(url));
    final response = await _client.send(request);
    if (response.statusCode != 200) {
      throw ModelDownloadException(
        'Download failed ($fileName): HTTP ${response.statusCode}',
      );
    }

    final total = response.contentLength ?? 0;
    var received = 0;
    final sink = tmp.openWrite();
    try {
      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        if (total > 0) onProgress?.call((received / total).clamp(0, 1));
      }
      await sink.flush();
    } finally {
      await sink.close();
    }

    if (sha256Hex != null) {
      final actual = await _sha256(tmp);
      if (actual != sha256Hex.toLowerCase()) {
        await tmp.delete();
        throw ModelDownloadException(
          'Checksum mismatch for $fileName (expected $sha256Hex, got $actual)',
        );
      }
    }

    await tmp.rename(file.path);
    onProgress?.call(1);
    return file.path;
  }

  Future<String> _sha256(File file) async {
    final digest = await sha256.bind(file.openRead()).first;
    return digest.toString();
  }

  void dispose() => _client.close();
}

class ModelDownloadException implements Exception {
  ModelDownloadException(this.message);
  final String message;
  @override
  String toString() => 'ModelDownloadException: $message';
}
