import 'package:math_city/domain/questions/diagram_spec.dart';

/// Shape of the player's expected answer. Drives how the question screen
/// parses the input (keypad extra-chars) and how the answer-checker
/// compares it against [GeneratedQuestion.correctAnswer].
enum AnswerFormat {
  /// Plain integer answer (e.g. `42`, `-3`). Equality is exact-string.
  integer,

  /// Fraction shape `a/b` (proper or improper). Equality may be by value
  /// (e.g. `2/4` accepted for `1/2`) subject to
  /// [GeneratedQuestion.answerShape].
  fraction,

  /// Mixed-number shape `a b/c` (kept-improper `a/b` also parses).
  /// Equality is by value subject to [GeneratedQuestion.answerShape].
  mixedNumber,

  /// Any other text answer (e.g. time-of-day `3:30`, comparison operator
  /// `>`). Equality is exact-string.
  string,
}

/// Constrains *which forms* the answer-checker accepts as the player's
/// input. Layered on top of [AnswerFormat] — format says "what kind of
/// value", shape says "in which surface form".
enum AnswerShape {
  /// Any equivalent value is accepted (subject to format). Default. Used
  /// for ordinary arithmetic where simplifying or expanding the answer is
  /// fine.
  any,

  /// Only the exact canonical string matches. Use when the lesson IS
  /// producing one specific form — `simplify_fraction` (lowest terms),
  /// `equivalent_fractions_compute` (specified denominator),
  /// `equivalent_fractions_visual` (specified multiplier),
  /// `fraction_a_over_b` (count what's depicted).
  exactString,

  /// Require mixed-number form `a b/c` (whole part present, space-
  /// separated). Within that constraint, accept any equivalent (e.g.
  /// player typing `3 1/2` is accepted when canonical is `3 2/4`). Use for
  /// `improper_to_mixed` — the lesson is producing the mixed form, not a
  /// specific un-reduced version of it.
  mixedForm,

  /// Require single-fraction form `a/b` (no whole part, no space). Within
  /// that constraint, accept any equivalent (e.g. `7/2` accepted when
  /// canonical is `14/4`). Use for `mixed_to_improper`.
  improperFraction,
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
    this.answerShape = AnswerShape.any,
  });

  final String conceptId;

  /// Question text shown to the player. May contain literal numbers; the
  /// diagram (if any) carries the visual representation.
  final String prompt;

  /// Optional diagram rendered above/alongside the prompt.
  final DiagramSpec? diagram;

  /// Canonical (lowest-terms, kid-textbook) answer string. The
  /// answer-checker uses this as the reference; equivalent forms may also
  /// be accepted depending on [answerFormat] and [answerShape].
  final String correctAnswer;

  /// Exactly three wrong answers; none equals [correctAnswer] and (for
  /// fraction/mixed answers) none is mathematically equivalent to it.
  final List<String> distractors;

  /// 1–4 step-by-step lines shown on the result screen when the player
  /// answers incorrectly. Lines are rendered top-to-bottom.
  final List<String> explanation;

  /// Format of the expected answer — drives keypad extra-chars and the
  /// kind of value-parsing the checker uses.
  final AnswerFormat answerFormat;

  /// Surface-form constraint on accepted answers. See [AnswerShape].
  final AnswerShape answerShape;

  /// All four choices unsorted — callers should shuffle before displaying.
  List<String> get allChoices => [correctAnswer, ...distractors];
}
