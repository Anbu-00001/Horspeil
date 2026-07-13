import '../../config/app_config.dart';
import 'language_gate_result.dart';

/// Pure decision logic for the language gate: given the per-window language
/// codes produced by the model, decide accept / reject / uncertain.
///
/// Kept deliberately free of any FFI / audio / IO so it is fully unit-testable
/// in plain Dart (see test/language_vote_aggregator_test.dart). This is where
/// the "no confidence score, so vote instead" strategy lives.
class LanguageVoteAggregator {
  const LanguageVoteAggregator(this.config);

  final LanguageGateConfig config;

  LanguageGateResult aggregate(List<String> perWindowLangs) {
    final target = config.targetLang.toLowerCase();

    final cleaned = perWindowLangs
        .map((l) => l.trim().toLowerCase())
        .where((l) => l.isNotEmpty)
        .toList();

    final analyzed = cleaned.length;

    if (analyzed < config.minWindowsForDecision) {
      return LanguageGateResult(
        decision: GateDecision.uncertain,
        targetLang: target,
        detectedLang: null,
        votes: const {},
        analyzedWindows: analyzed,
        matchFraction: 0,
        message: 'Sprache konnte nicht geprüft werden. Bitte erneut versuchen.',
      );
    }

    final votes = <String, int>{};
    for (final lang in cleaned) {
      votes[lang] = (votes[lang] ?? 0) + 1;
    }

    // argmax with stable tie-break (first-seen order preserved by iterating
    // the insertion-ordered map).
    String detected = cleaned.first;
    int best = -1;
    votes.forEach((lang, count) {
      if (count > best) {
        best = count;
        detected = lang;
      }
    });

    final targetVotes = votes[target] ?? 0;
    final fraction = targetVotes / analyzed;
    final accepted = fraction >= config.minAcceptFraction;

    return LanguageGateResult(
      decision: accepted ? GateDecision.accepted : GateDecision.rejected,
      targetLang: target,
      detectedLang: detected,
      votes: Map.unmodifiable(votes),
      analyzedWindows: analyzed,
      matchFraction: fraction,
      message: accepted
          ? 'Deutsch erkannt.'
          : 'Kein Deutsch erkannt (erkannt: $detected). '
              'Nur deutschsprachige Hörspiele sind erlaubt.',
    );
  }
}
