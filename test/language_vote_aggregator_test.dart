import 'package:flutter_test/flutter_test.dart';
import 'package:horspiel/config/app_config.dart';
import 'package:horspiel/services/language_gate/language_gate_result.dart';
import 'package:horspiel/services/language_gate/language_vote_aggregator.dart';

void main() {
  // Default gate: target 'de', accept when >= 60% of windows are German,
  // need at least 1 analysed window to decide.
  const config = LanguageGateConfig();
  const aggregator = LanguageVoteAggregator(config);

  group('LanguageVoteAggregator', () {
    test('all German windows -> accepted, 100% match', () {
      final r = aggregator.aggregate(['de', 'de', 'de', 'de', 'de']);
      expect(r.decision, GateDecision.accepted);
      expect(r.detectedLang, 'de');
      expect(r.matchFraction, 1.0);
      expect(r.analyzedWindows, 5);
    });

    test('all English windows -> rejected, detected en', () {
      final r = aggregator.aggregate(['en', 'en', 'en']);
      expect(r.decision, GateDecision.rejected);
      expect(r.detectedLang, 'en');
      expect(r.matchFraction, 0.0);
    });

    test('majority German (3/5 = 60%) -> accepted at the boundary', () {
      final r = aggregator.aggregate(['de', 'de', 'de', 'en', 'fr']);
      expect(r.decision, GateDecision.accepted);
      expect(r.matchFraction, closeTo(0.6, 1e-9));
    });

    test('minority German (2/5 = 40%) -> rejected', () {
      final r = aggregator.aggregate(['de', 'de', 'en', 'en', 'fr']);
      expect(r.decision, GateDecision.rejected);
      expect(r.matchFraction, closeTo(0.4, 1e-9));
    });

    test('empty input -> uncertain, not a hard reject', () {
      final r = aggregator.aggregate([]);
      expect(r.decision, GateDecision.uncertain);
      expect(r.analyzedWindows, 0);
      expect(r.detectedLang, isNull);
    });

    test('blank/whitespace langs are ignored', () {
      final r = aggregator.aggregate(['de', '', '  ', 'de']);
      expect(r.analyzedWindows, 2);
      expect(r.decision, GateDecision.accepted);
      expect(r.matchFraction, 1.0);
    });

    test('case and padding are normalised', () {
      final r = aggregator.aggregate([' DE ', 'De', 'dE']);
      expect(r.detectedLang, 'de');
      expect(r.decision, GateDecision.accepted);
    });

    test('votes tally is exposed for UI / appeal record', () {
      final r = aggregator.aggregate(['de', 'de', 'en', 'fr', 'fr', 'fr']);
      expect(r.votes['de'], 2);
      expect(r.votes['en'], 1);
      expect(r.votes['fr'], 3);
      expect(r.detectedLang, 'fr'); // argmax
      expect(r.decision, GateDecision.rejected); // only 2/6 German
    });

    test('stricter config raises the bar', () {
      const strict = LanguageGateConfig(minAcceptFraction: 0.8);
      const strictAgg = LanguageVoteAggregator(strict);
      final r = strictAgg.aggregate(['de', 'de', 'de', 'en']); // 75%
      expect(r.decision, GateDecision.rejected);
    });

    test('minWindowsForDecision guards against too-few samples', () {
      const needThree = LanguageGateConfig(minWindowsForDecision: 3);
      const agg = LanguageVoteAggregator(needThree);
      expect(agg.aggregate(['de', 'de']).decision, GateDecision.uncertain);
      expect(agg.aggregate(['de', 'de', 'de']).decision, GateDecision.accepted);
    });
  });
}
