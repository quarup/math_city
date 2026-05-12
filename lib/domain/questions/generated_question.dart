import 'package:math_city/domain/questions/diagram_spec.dart';

/// Shape of the player's expected answer. Drives how the question screen
/// parses the input (keypad extra-chars) and how the answer-checker
/// compares it against [GeneratedQuestion.correctAnswer].
enum AnswerFormat {
  /// Plain integer answer (e.g. `42`, `-3`). Equality is exact-string.
  integer,

  /// Fraction shape `a/b` (proper or improper). Equality may be by value
  /// (e.g. `2/4` accepted for `1/2`) unless
  /// [GeneratedQuestion.requiresCanonicalForm] is set.
  fraction,

  /// Mixed-number shape `a b/c` (kept-improper `a/b` also parses).
  /// Equality is by value unless [GeneratedQuestion.requiresCanonicalForm]
  /// is set.
  mixedNumber,

  /// Any other text answer (e.g. time-of-day `3:30`, comparison operator
  /// `>`). Equality is exact-string.
  string,
}

/// A single question presented to the player.
///
/// All values are pure data (no Flutter imports). Answer values are stored
/// as their rendered string form — generators are responsible for
/// formatting (e.g. fractions as "1/2", times as "3:30").
class GeneratedQuestion {
  const GeneratedQuestion({
    required this.conceptId,
    required this.prompt,
    required this.correctAnswer,
    required this.distractors,
    required this.explanation,
    this.diagram,
    this.answerFormat = AnswerFormat.integer,
    this.requiresCanonicalForm = false,
  });

  final String conceptId;

  /// Question text shown to the player. May contain literal numbers; the
  /// diagram (if any) carries the visual representation.
  final String prompt;

  /// Optional diagram rendered above/alongside the prompt.
  final DiagramSpec? diagram;

  /// Canonical (lowest-terms, kid-textbook) answer string. The
  /// answer-checker uses this as the reference; equivalent forms may also
  /// be accepted depending on [answerFormat] and [requiresCanonicalForm].
  final String correctAnswer;

  /// Exactly three wrong answers; none equals [correctAnswer] and (for
  /// fraction/mixed answers) none is mathematically equivalent to it.
  final List<String> distractors;

  /// 1–4 step-by-step lines shown on the result screen when the player
  /// answers incorrectly. Lines are rendered top-to-bottom.
  final List<String> explanation;

  /// Shape of the expected answer — drives keypad extra-chars and the
  /// answer-equivalence policy.
  final AnswerFormat answerFormat;

  /// When true, only [correctAnswer] (string-equal) is accepted — even
  /// equivalent fraction forms are marked wrong. Set this on generators
  /// whose lesson IS producing the canonical form (simplify, equivalent-
  /// fractions-with-given-multiplier/denominator, mixed↔improper).
  final bool requiresCanonicalForm;

  /// All four choices unsorted — callers should shuffle before displaying.
  List<String> get allChoices => [correctAnswer, ...distractors];
}
