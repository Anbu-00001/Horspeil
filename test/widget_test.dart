// Smoke test: the app boots and, with no signed-in user, lands on onboarding.
//
// Kept deliberately shallow — it exercises app construction + the AuthGate
// branch, without driving plugin-backed flows (recording, playback, model
// download) that require a real device.

import 'package:flutter_test/flutter_test.dart';

import 'package:horspiel/app_services.dart';
import 'package:horspiel/main.dart';
import 'package:horspiel/ui/onboarding/onboarding_screen.dart';

void main() {
  testWidgets('boots to onboarding when signed out', (WidgetTester tester) async {
    final services = AppServices.local();
    addTearDown(services.dispose);

    await tester.pumpWidget(HorspielApp(services: services));
    // One frame for the AuthGate StreamBuilder to resolve to the null-user state.
    await tester.pump();

    expect(find.byType(OnboardingScreen), findsOneWidget);
  });
}
