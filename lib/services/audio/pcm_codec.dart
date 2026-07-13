import 'dart:io';
import 'dart:typed_data';

/// Conversions between raw 16-bit PCM and the formats the rest of the app needs:
/// - [pcm16ToFloat32] feeds the language gate (Whisper wants float [-1, 1]).
/// - [wavFromPcmFile] wraps a headerless PCM capture into a playable WAV so
///   `just_audio` can preview it without pulling in an encoder.
class PcmCodec {
  const PcmCodec._();

  /// Little-endian signed 16-bit PCM bytes -> normalised float samples.
  static Float32List pcm16ToFloat32(Uint8List bytes) {
    final sampleCount = bytes.length ~/ 2;
    final out = Float32List(sampleCount);
    final data = ByteData.sublistView(bytes, 0, sampleCount * 2);
    for (var i = 0; i < sampleCount; i++) {
      out[i] = data.getInt16(i * 2, Endian.little) / 32768.0;
    }
    return out;
  }

  /// Build a 44-byte canonical WAV header for the given PCM payload size.
  static Uint8List wavHeader({
    required int dataLength,
    required int sampleRate,
    int numChannels = 1,
    int bitsPerSample = 16,
  }) {
    final byteRate = sampleRate * numChannels * bitsPerSample ~/ 8;
    final blockAlign = numChannels * bitsPerSample ~/ 8;
    final header = ByteData(44);

    void writeAscii(int offset, String s) {
      for (var i = 0; i < s.length; i++) {
        header.setUint8(offset + i, s.codeUnitAt(i));
      }
    }

    writeAscii(0, 'RIFF');
    header.setUint32(4, 36 + dataLength, Endian.little);
    writeAscii(8, 'WAVE');
    writeAscii(12, 'fmt ');
    header.setUint32(16, 16, Endian.little); // PCM fmt chunk size
    header.setUint16(20, 1, Endian.little); // audio format = PCM
    header.setUint16(22, numChannels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    writeAscii(36, 'data');
    header.setUint32(40, dataLength, Endian.little);

    return header.buffer.asUint8List();
  }

  /// Stream a headerless PCM file into a new WAV file without loading it all
  /// into memory (podcasts can be long).
  static Future<File> wavFromPcmFile({
    required String pcmPath,
    required String wavPath,
    required int sampleRate,
    int numChannels = 1,
  }) async {
    final pcm = File(pcmPath);
    final dataLength = await pcm.length();
    final wav = File(wavPath);
    final sink = wav.openWrite();
    try {
      sink.add(wavHeader(
        dataLength: dataLength,
        sampleRate: sampleRate,
        numChannels: numChannels,
      ));
      await sink.addStream(pcm.openRead());
      await sink.flush();
    } finally {
      await sink.close();
    }
    return wav;
  }
}
