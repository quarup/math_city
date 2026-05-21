import 'package:math_city/domain/questions/decimal.dart';
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

  /// Player's input does not match canonically nor by value, OR matches by
  /// value but in a disallowed surface form (e.g. typing the improper
  /// fraction when the lesson asked for a mixed number).
  wrong,
}

/// Compares [playerAnswer] against [question]'s correct answer, honouring
/// the question's [GeneratedQuestion.answerFormat] and
/// [GeneratedQuestion.answerShape] settings.
///
/// Returns one of three outcomes:
///
///   * [AnswerOutcome.canonical] — exact string match, always accepted.
///   * [AnswerOutcome.equivalentNonCanonical] — same mathematical value
///     under the question's answer format, AND the input's surface form
///     is allowed by the answer shape.
///   * [AnswerOutcome.wrong] — neither.
///
/// Whitespace at the ends of [playerAnswer] is trimmed before comparison
/// (the keypad widget pads loosely). Internal spacing in mixed-number
/// answers is preserved (the parser handles that).
AnswerOutcome checkAnswer(GeneratedQuestion question, String playerAnswer) {
  final input = playerAnswer.trim();
  if (input == question.correctAnswer) return AnswerOutcome.canonical;

  // Shape check: reject inputs whose surface form is not allowed for this
  // question, even if their value matches.
  switch (question.answerShape) {
    case AnswerShape.exactString:
      // Only the exact canonical string matches; we already failed that.
      return AnswerOutcome.wrong;
    case AnswerShape.any:
      break;
    case AnswerShape.mixedForm:
      if (!_isMixedForm(input)) return AnswerOutcome.wrong;
    case AnswerShape.improperFraction:
      if (!_isImproperFractionForm(input)) return AnswerOutcome.wrong;
  }

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
    case AnswerFormat.decimal:
      final playerD = Decimal.tryParse(input);
      final correctD = Decimal.tryParse(question.correctAnswer);
      if (playerD == null || correctD == null) return AnswerOutcome.wrong;
      return playerD.equalsByValue(correctD)
          ? AnswerOutcome.equivalentNonCanonical
          : AnswerOutcome.wrong;
    case AnswerFormat.commaList:
      return _checkCommaList(input, question.correctAnswer);
  }
}

/// Compares two comma-list answers entry-wise. Each entry is parsed as a
/// `Fraction` (which already handles integers and mixed/improper forms);
/// `Decimal` entries are converted to `Fraction` for cross-type
/// equivalence (`0.5 == 1/2`). Lists must have the same length; order
/// matters.
AnswerOutcome _checkCommaList(String input, String correct) {
  final playerEntries = _splitCommaList(input);
  final correctEntries = _splitCommaList(correct);
  if (playerEntries.length != correctEntries.length) return AnswerOutcome.wrong;
  for (var i = 0; i < playerEntries.length; i++) {
    final p = _parseListEntry(playerEntries[i]);
    final c = _parseListEntry(correctEntries[i]);
    if (p == null || c == null) return AnswerOutcome.wrong;
    if (!p.equalsByValue(c)) return AnswerOutcome.wrong;
  }
  return AnswerOutcome.equivalentNonCanonical;
}

List<String> _splitCommaList(String s) =>
    s.split(',').map((e) => e.trim()).toList();

Fraction? _parseListEntry(String s) {
  if (s.isEmpty) return null;
  // Try decimal first — its parser is stricter (rejects "1/2") and lets
  // us convert into a Fraction for cross-type comparison.
  final d = Decimal.tryParse(s);
  if (d != null) {
    final pow10 = _pow10(d.scale);
    return Fraction(d.scaled, pow10);
  }
  return Fraction.tryParse(s);
}

int _pow10(int n) {
  var r = 1;
  for (var i = 0; i < n; i++) {
    r *= 10;
  }
  return r;
}

final _mixedFormPattern = RegExp(r'^-?\d+\s+\d+/\d+$');
final _improperFractionPattern = RegExp(r'^-?\d+/\d+$');

bool _isMixedForm(String s) => _mixedFormPattern.hasMatch(s);
bool _isImproperFractionForm(String s) => _improperFractionPattern.hasMatch(s);
