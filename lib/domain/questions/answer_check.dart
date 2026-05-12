import 'package:math_city/domain/questions/fraction.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// Outcome of comparing a player's typed/tapped answer against the
/// canonical correct answer for a [GeneratedQuestion].
enum AnswerOutcome {
  /// Player's input matches the canonical answer string exactly.
  canonical,

  /// Player's input is mathematically equivalent but not in canonical form
  /// (e.g. they entered `2/4` for canonical `1/2`). Resolves [GitHub issue
  /// #2 option (c)] — accept, then nudge on the result screen.
  equivalentNonCanonical,

  /// Player's input does not match canonically nor by value.
  wrong,
}

/// Compares [playerAnswer] against [question]'s correct answer, honouring
/// the question's [GeneratedQuestion.answerFormat] and
/// [GeneratedQuestion.requiresCanonicalForm] settings.
///
/// Returns one of three outcomes:
///
///   * [AnswerOutcome.canonical] — exact string match, always accepted.
///   * [AnswerOutcome.equivalentNonCanonical] — same mathematical value
///     under the question's answer format. Only possible when the format
///     supports equivalence (`fraction`, `mixedNumber`) AND the question
///     does NOT require canonical form.
///   * [AnswerOutcome.wrong] — neither.
///
/// Whitespace at the ends of [playerAnswer] is trimmed before comparison
/// (the keypad widget pads loosely). Internal spacing in mixed-number
/// answers is preserved (the parser handles that).
AnswerOutcome checkAnswer(GeneratedQuestion question, String playerAnswer) {
  final input = playerAnswer.trim();
  if (input == question.correctAnswer) return AnswerOutcome.canonical;

  // Canonical-required questions never accept equivalents — there the
  // canonical form *is* the lesson (simplify, equivalent-with-given-
  // denominator, mixed↔improper).
  if (question.requiresCanonicalForm) return AnswerOutcome.wrong;

  switch (question.answerFormat) {
    case AnswerFormat.integer:
    case AnswerFormat.string:
      return AnswerOutcome.wrong;
    case AnswerFormat.fraction:
    case AnswerFormat.mixedNumber:
      final playerF = Fraction.tryParse(input);
      final correctF = Fraction.tryParse(question.correctAnswer);
      if (playerF == null || correctF == null) return AnswerOutcome.wrong;
      return playerF.equalsByValue(correctF)
          ? AnswerOutcome.equivalentNonCanonical
          : AnswerOutcome.wrong;
  }
}
