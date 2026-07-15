import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as sb;

/// Where a finished (gate-passed) podcast's audio is persisted so it can be
/// played back by a URL/path the [PodcastRepository] stores.
///
/// A seam, not a Supabase detail: [LocalAudioStorage] keeps Phase 1 runnable
/// offline, [SupabaseAudioStorage] is the cloud path. Callers depend only on
/// this interface.
abstract interface class AudioStorage {
  /// Persists [bytes] and returns a URI the player can open later.
  ///
  /// [ownerId] namespaces the object (and, on Supabase, must match the caller's
  /// `auth.uid()` so the Storage RLS insert policy allows the write).
  Future<String> uploadPodcastAudio({
    required String ownerId,
    required String fileName,
    required Uint8List bytes,
    String contentType = 'audio/mpeg',
  });
}

/// Copies audio into the app documents dir and returns a `file://`-style path.
/// Good enough to demo record → gate → publish → play without any backend.
class LocalAudioStorage implements AudioStorage {
  @override
  Future<String> uploadPodcastAudio({
    required String ownerId,
    required String fileName,
    required Uint8List bytes,
    String contentType = 'audio/mpeg',
  }) async {
    final dir = await getApplicationDocumentsDirectory();
    final destDir = Directory(p.join(dir.path, 'audio', ownerId));
    await destDir.create(recursive: true);
    final dest = File(p.join(destDir.path, fileName));
    await dest.writeAsBytes(bytes, flush: true);
    return dest.path;
  }
}

/// Uploads audio to a Supabase Storage bucket under `{ownerId}/{fileName}` and
/// returns the public URL. The owner-id path prefix is what the bucket's RLS
/// insert policy keys off (see docs/supabase_storage_policy.sql).
class SupabaseAudioStorage implements AudioStorage {
  SupabaseAudioStorage(this._storage, {this.bucket = 'podcasts'});

  final sb.SupabaseStorageClient _storage;
  final String bucket;

  @override
  Future<String> uploadPodcastAudio({
    required String ownerId,
    required String fileName,
    required Uint8List bytes,
    String contentType = 'audio/mpeg',
  }) async {
    final objectPath = '$ownerId/$fileName';
    await _storage.from(bucket).uploadBinary(
          objectPath,
          bytes,
          fileOptions: sb.FileOptions(contentType: contentType, upsert: false),
        );
    return _storage.from(bucket).getPublicUrl(objectPath);
  }
}
