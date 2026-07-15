// Real end-to-end verification of the cloud upload path (no phone/mic needed).
//
// Proves the second-riskiest Phase 1 path after the language gate: that an
// authenticated user can upload audio to Supabase Storage under their own uid
// folder (satisfying the RLS insert policy) and that the returned public URL is
// then readable — i.e. the exact record→upload→playback data flow, minus the
// mic. Uses the REAL SupabaseAudioStorage class and a real anonymous session.
//
//   flutter test integration_test/upload_loop_test.dart -d linux \
//     --dart-define-from-file=.env \
//     --dart-define=FIXTURES_DIR=$(pwd)/test/fixtures
//
// Requires: anonymous sign-ins ENABLED in the Supabase dashboard, and the
// storage RLS policies from docs/supabase_storage_policy.sql applied.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:integration_test/integration_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:horspiel/config/env.dart';
import 'package:horspiel/services/storage/audio_storage.dart';

const _fixturesDefine = String.fromEnvironment('FIXTURES_DIR');
String get _fixturesDir =>
    _fixturesDefine.isNotEmpty ? _fixturesDefine : '${Directory.current.path}/test/fixtures';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('authenticated upload → public URL round-trips', (tester) async {
    if (!Env.hasSupabase) {
      fail('Run with --dart-define-from-file=.env (SUPABASE_URL / KEY missing)');
    }

    await Supabase.initialize(
      url: Env.supabaseUrl,
      publishableKey: Env.supabasePublishableKey,
    );
    final client = Supabase.instance.client;
    addTearDown(() async => client.auth.signOut());

    // 1. Real session (anonymous). uid becomes the storage folder prefix.
    final auth = await client.auth.signInAnonymously();
    final uid = auth.user!.id;
    expect(uid, isNotEmpty);

    // 2. Upload a real audio file through the REAL app storage class.
    final storage = SupabaseAudioStorage(client.storage);
    final bytes = File('$_fixturesDir/de-german.wav').readAsBytesSync();
    final fileName = 'itest_${DateTime.now().millisecondsSinceEpoch}.wav';
    final url = await storage.uploadPodcastAudio(
      ownerId: uid,
      fileName: fileName,
      bytes: bytes,
      contentType: 'audio/wav',
    );
    // ignore: avoid_print
    print('[upload] uid=$uid url=$url');
    expect(url, contains('/storage/v1/object/public/podcasts/$uid/$fileName'));

    // 3. The public URL must serve the same bytes back (what the player fetches).
    final resp = await http.get(Uri.parse(url));
    expect(resp.statusCode, 200);
    expect(resp.bodyBytes.length, bytes.length);

    // 4. Cleanup (owner-delete policy) so the test is repeatable.
    await client.storage.from('podcasts').remove(['$uid/$fileName']);
  }, timeout: const Timeout(Duration(minutes: 2)));
}
