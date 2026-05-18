import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/fraction.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// G2-G3 length-measurement generators using the new Ruler widget:
/// measure_with_ruler_inches, measure_with_ruler_cm,
/// measure_to_half_quarter_inch.

// ─────────────────────────────────────────────────────────────────────────
// measure_with_ruler_inches (G2)
// ─────────────────────────────────────────────────────────────────────────

/// Show a ruler with an object spanning a whole number of inches; ask
/// for the length. CCSS 2.MD.A.1.
GeneratedQuestion measureWithRulerInches(Random rand) {
  // Object length in [1, 8] inches; ruler total length = max(object + 1, 6)
  // so there's always at least one tick of headroom to the right.
  final length = rand.nextInt(8) + 1; // 1..8
  final totalLength = length + 1 > 6 ? length + 1 : 6;
  return GeneratedQuestion(
    conceptId: 'measure_with_ruler_inches',
    prompt: 'How long is the bar, in inches?',
    diagram: RulerSpec(
      totalLength: totalLength,
      markedLength: length,
      unitLabel: 'in',
    ),
    correctAnswer: '$length',
    distractors: integerDistractorsWith(
      length,
      rand,
      // Misconception: counted ticks instead of intervals (off by 1).
      misconception: length + 1,
    ),
    explanation: ['The bar reaches the $length-inch tick → $length inches.'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// measure_with_ruler_cm (G2)
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion measureWithRulerCm(Random rand) {
  // Object length in [2, 14] cm; ruler total in {12, 15, 20} cm based on
  // length so the ruler still feels right-sized.
  final length = rand.nextInt(13) + 2; // 2..14
  final totalLength = length + 2 > 15 ? 20 : (length + 2 > 12 ? 15 : 12);
  return GeneratedQuestion(
    conceptId: 'measure_with_ruler_cm',
    prompt: 'How long is the bar, in centimetres?',
    diagram: RulerSpec(
      totalLength: totalLength,
      markedLength: length,
      unitLabel: 'cm',
    ),
    correctAnswer: '$length',
    distractors: integerDistractorsWith(
      length,
      rand,
      misconception: length + 1,
    ),
    explanation: ['The bar reaches the $length-cm tick → $length cm.'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// measure_to_half_quarter_inch (G3)
// ─────────────────────────────────────────────────────────────────────────

/// Show a ruler subdivided into halves or quarters; the object's right
/// edge lands on a non-whole tick. CCSS 3.MD.B.4.
GeneratedQuestion measureToHalfQuarterInch(Random rand) {
  final sub = rand.nextBool() ? 2 : 4; // halves or quarters
  // Internal: length in 1/sub-inch units; pick so length / sub has a
  // fractional component (i.e. length is NOT a multiple of sub).
  int rawLength;
  do {
    rawLength = rand.nextInt(6 * sub - sub) + sub + 1; // sub+1..6·sub
  } while (rawLength % sub == 0);
  const totalLength = 6;
  // Display the answer as a mixed number (e.g. "1 1/2", "2 3/4") or as
  // a simple proper fraction when whole = 0.
  final whole = rawLength ~/ sub;
  final num = rawLength % sub;
  // Reduce num/sub if possible: gcd(num, sub) (always 1 or 2 since sub
  // is 2 or 4 and num ∈ [1, sub-1]).
  final reduced = Fraction(num, sub).reduce();
  final fractionStr = '${reduced.numerator}/${reduced.denominator}';
  final correct = whole == 0 ? fractionStr : '$whole $fractionStr';
  return GeneratedQuestion(
    conceptId: 'measure_to_half_quarter_inch',
    prompt: 'How long is the bar?',
    diagram: RulerSpec(
      totalLength: totalLength,
      markedLength: rawLength,
      unitLabel: 'in',
      subdivisions: sub,
    ),
    correctAnswer: correct,
    distractors: _distinctStringDistractors(correct, [
      // Misconception: dropped the fractional part — gave the whole only.
      if (whole > 0) '$whole',
      // Misconception: read up to the next whole tick.
      '${whole + 1}',
      // Misconception: read the fractional part backwards (sub − num)/sub.
      _mixedOrFraction(whole, sub - num, sub),
      // Misconception: counted ticks 1-indexed.
      _mixedOrFraction(whole, num + 1, sub),
      // Last-resort: nudge whole by 1.
      if (whole > 0) _mixedOrFraction(whole - 1, num, sub),
    ]),
    explanation: [
      'The bar reaches $rawLength/$sub = $correct.',
    ],
    answerFormat: AnswerFormat.mixedNumber,
  );
}

String _mixedOrFraction(int whole, int num, int sub) {
  if (num <= 0 || num >= sub) return '$whole';
  final reduced = Fraction(num, sub).reduce();
  final fractionStr = '${reduced.numerator}/${reduced.denominator}';
  return whole == 0 ? fractionStr : '$whole $fractionStr';
}

List<String> _distinctStringDistractors(
  String correct,
  List<String> candidates,
) {
  final out = <String>[];
  final seen = <String>{correct};
  for (final c in candidates) {
    if (out.length >= 3) break;
    if (seen.add(c)) out.add(c);
  }
  if (out.length < 3) {
    throw StateError(
      'distractor pool exhausted; need 3 distinct vs "$correct"',
    );
  }
  return out.take(3).toList();
}
