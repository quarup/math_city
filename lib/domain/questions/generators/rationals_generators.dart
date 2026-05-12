import 'dart:math';

import 'package:math_city/domain/questions/fraction.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// Signed-rational arithmetic generators (Grade 7).
///
/// Display conventions (consistent with integer_generators.dart):
///   * Leading operand: bare sign for negatives — e.g. `-3/4 + 1/2`.
///   * Trailing operand: parens around negatives — e.g. `3/4 + (-1/2)`.
///   * Answer: bare sign on the numerator (Fraction.toCanonical already
///     produces `-3/4` for negative values).
///
/// Note: uses ASCII '-' rather than U+2212 throughout, so the keypad
/// extra-char surfaces the same '-' the player needs to type to match the
/// canonical answer.

/// Picks a non-zero signed fraction with denominator 2..6 and numerator
/// ranging up to 2× the denominator (so improper fractions land roughly
/// half the time). Sign chosen uniformly.
Fraction _pickSignedFraction(Random rand) {
  final denominator = rand.nextInt(5) + 2; // 2..6
  // Numerator magnitude up to 2 * denominator so we span proper + improper
  // — gives a healthy mix of values between -2 and 2.
  final mag = rand.nextInt(2 * denominator) + 1; // 1..2d
  final sign = rand.nextBool() ? 1 : -1;
  return Fraction(sign * mag, denominator);
}

String _trailing(Fraction f) {
  final s = f.toCanonical();
  return s.startsWith('-') ? '($s)' : s;
}

/// Returns three string distractors for a signed-rational answer.
/// Strategy: a few targeted misconceptions, then ±1 numerator
/// perturbations as fallback. Filters out anything that parses to the
/// same value as [correct].
List<String> _rationalDistractors(
  Fraction correct,
  List<String> seedCandidates,
  Random rand,
) {
  final out = <String>[];
  final seen = <String>{correct.toCanonical()};
  bool tryAdd(String s) {
    if (seen.contains(s)) return false;
    final f = Fraction.tryParse(s);
    if (f != null && f.equalsByValue(correct)) return false;
    seen.add(s);
    out.add(s);
    return true;
  }

  for (final c in seedCandidates) {
    if (out.length >= 3) break;
    tryAdd(c);
  }
  for (var i = 0; i < 40 && out.length < 3; i++) {
    final dn = rand.nextInt(7) - 3; // -3..3
    final n2 = correct.numerator + dn;
    if (n2 == 0) continue;
    tryAdd(Fraction(n2, correct.denominator).toCanonical());
  }
  while (out.length < 3) {
    out.add('${out.length + 7}/9');
  }
  return out.take(3).toList();
}

/// Add or subtract two signed fractions. Result in canonical (reduced)
/// form; can be integer, proper, improper, positive, or negative.
GeneratedQuestion rationalsAddSub(Random rand) {
  final isAdd = rand.nextBool();
  var a = _pickSignedFraction(rand);
  var b = _pickSignedFraction(rand);
  // Force at least one negative — purely positive cases are already
  // covered by add_fractions_unlike_denom.
  if (a.numerator > 0 && b.numerator > 0) {
    if (rand.nextBool()) {
      a = Fraction(-a.numerator, a.denominator);
    } else {
      b = Fraction(-b.numerator, b.denominator);
    }
  }
  final result = isAdd ? a + b : a - b;
  final correct = result.toCanonical();

  final opSym = isAdd ? '+' : '−';
  final leadingStr = a.toCanonical();
  final trailingStr = _trailing(b);
  final prompt = '$leadingStr $opSym $trailingStr = ?';

  // Misconception distractors: flipped op, wrong sign, etc.
  final flippedOp = isAdd ? a - b : a + b;
  final negResult = Fraction(-result.numerator, result.denominator);
  final distractors = _rationalDistractors(
    result,
    [
      flippedOp.toCanonical(), // swapped + and -
      negResult.toCanonical(), // sign-flipped answer
    ],
    rand,
  );

  return GeneratedQuestion(
    conceptId: 'rationals_add_sub',
    prompt: prompt,
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      '$leadingStr $opSym $trailingStr',
      if (isAdd)
        'Add with signs: positive + negative = subtract magnitudes.'
      else
        'Subtract = add the opposite (flip the trailing sign).',
      'Common bottom, combine tops, reduce.',
      'Result: $correct.',
    ],
    answerFormat: AnswerFormat.fraction,
  );
}

/// Multiply or divide two signed fractions. Result reduced; never divide
/// by 0.
GeneratedQuestion rationalsMultiplyDivide(Random rand) {
  final isMult = rand.nextBool();
  var a = _pickSignedFraction(rand);
  var b = _pickSignedFraction(rand);
  // Force at least one negative.
  if (a.numerator > 0 && b.numerator > 0) {
    if (rand.nextBool()) {
      a = Fraction(-a.numerator, a.denominator);
    } else {
      b = Fraction(-b.numerator, b.denominator);
    }
  }
  final result = isMult ? a * b : a / b;
  final correct = result.toCanonical();

  final opSym = isMult ? '×' : '÷';
  final leadingStr = a.toCanonical();
  final trailingStr = _trailing(b);
  final prompt = '$leadingStr $opSym $trailingStr = ?';

  final negResult = Fraction(-result.numerator, result.denominator);
  final flippedOp = isMult ? a / b : a * b;
  final distractors = _rationalDistractors(
    result,
    [
      negResult.toCanonical(), // sign-flipped answer
      flippedOp.toCanonical(), // swapped × and ÷
    ],
    rand,
  );

  return GeneratedQuestion(
    conceptId: 'rationals_multiply_divide',
    prompt: prompt,
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      '$leadingStr $opSym $trailingStr',
      if (isMult)
        'Multiply tops × tops; bottoms × bottoms; then reduce.'
      else
        'Keep, change, flip: divide → multiply by reciprocal.',
      'Sign: neg × pos = neg; neg × neg = pos.',
      'Result: $correct.',
    ],
    answerFormat: AnswerFormat.fraction,
  );
}
