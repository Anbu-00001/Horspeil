// Smoke test: the app boots and, with no signed-in user, lands on onboarding.
//
// Kept deliberately shallow — it exercises app construction + the AuthGate
// branch, without driving plugin-backed flows (recording, playback, model
// download) that require a real device.
//
// The real JustAudioPlayerService eagerly initialises the native platform in
// its constructor (throws under the headless test harness), so we inject a
// no-op PlayerService via the PlayerService interface instead.

import 'package:flutter_test/flutter_test.dart';
import 'package:just_audio/just_audio.dart';

import 'package:horspiel/app_services.dart';
import 'package:horspiel/config/app_config.dart';
import 'package:horspiel/main.dart';
import 'package:horspiel/repositories/auth_repository.dart';
import 'package:horspiel/repositories/podcast_repository.dart';
import 'package:horspiel/services/audio/player_service.dart';
import 'package:horspiel/services/storage/audio_storage.dart';
import 'package:horspiel/ui/onboarding/onboarding_screen.dart';

/// No-op player: constructs nothing native, returns empty streams.
class FakePlayerService implements PlayerService {
  @override
  Stream<Duration> get position => const Stream.empty();
  @override
  Stream<Duration?> get duration => const Stream.empty();
  @override
  Stream<PlayerState> get playerState => const Stream.empty();
  @override
  bool get isPlaying => false;
  @override
  Future<void> playSource(String uri) async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> dispose() async {}
}

AppServices _testServices() => AppServices(
      config: AppConfig.defaults,
      auth: LocalAuthRepository(),
      podcasts: LocalPodcastRepository(),
      audioStorage: LocalAudioStorage(),
      player: FakePlayerService(),
    );

void main() {
  testWidgets('boots to onboarding when signed out', (WidgetTester tester) async {
    final services = _testServices();
    addTearDown(services.dispose);

    await tester.pumpWidget(HorspielApp(services: services));
    // One frame for the AuthGate StreamBuilder to resolve to the null-user state.
    await tester.pump();

    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
