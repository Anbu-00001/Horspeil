/// Outcome of the German language gate.
enum GateDecision {
  /// Enough sampled windows were the target language — publish allowed.
  accepted,

  /// The clip is (probably) not the target language — publish blocked, but the
  /// user can request manual review.
  rejected,

  /// Not enough could be analysed to decide (too short / silent / model error).
  /// Treated as a soft failure, distinct from a confident reject.
  uncertain,
}

/// Result of analysing a clip. Note there is NO confidence score from the
/// model; [matchFraction] (target-language votes / analysed windows) is our
/// stand-in signal, and [votes] exposes the full per-language tally for UI /
/// debugging / an appeal record.
class LanguageGateResult {
  const LanguageGateResult({
    required this.decision,
    required this.targetLang,
    required this.detectedLang,
    required this.votes,
    required this.analyzedWindows,
    required this.matchFraction,
    required this.message,
  });

  final GateDecision decision;
  final String targetLang;

  /// Most frequently detected language across windows (null if none analysed).
  final String? detectedLang;

  /// language code -> number of windows that voted for it.
  final Map<String, int> votes;

  final int analyzedWindows;

  /// votes[targetLang] / analyzedWindows, in [0, 1].
  final double matchFraction;

  /// Human-readable, German-facing summary (shown on the gate result screen).
  final String message;

  bool get accepted => decision == GateDecision.accepted;

  Map<String, dynamic> toJson() => {
        'decision': decision.name,
        'targetLang': targetLang,
        'detectedLang': detectedLang,
        'votes': votes,
        'analyzedWindows': analyzedWindows,
        'matchFraction': matchFraction,
        'message': message,
      };

  @override
  String toString() =>
      'LanguageGateResult(${decision.name}, detected: $detectedLang, '
      'match: ${(matchFraction * 100).toStringAsFixed(0)}%, votes: $votes)';
}
