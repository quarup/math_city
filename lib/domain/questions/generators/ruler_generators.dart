import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/fraction.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// G2-G3 length-measurement generators using the Ruler widget:
/// measure_with_ruler_cm, measure_to_half_cm. (The inch rulers were
/// retired 2026-10-03 — see curriculum.md §3.8.)

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
// measure_to_half_cm (G3)
// ─────────────────────────────────────────────────────────────────────────

/// A centimetre ruler with half-centimetre ticks; the bar ends on a half
/// tick, so the answer is a mixed number like "3 1/2". The metric take on
/// CCSS 3.MD.B.4 (which measures to halves and quarters of an inch —
/// quarter-centimetre ticks don't exist on real rulers).
GeneratedQuestion measureToHalfCm(Random rand) {
  const sub = 2;
  const totalLength = 8;
  final whole = rand.nextInt(totalLength - 1) + 1; // 1..7
  final rawLength = whole * sub + 1; // ends on the half tick after it
  final correct = '$whole 1/2';
  final next = whole + 1;
  return GeneratedQuestion(
    conceptId: 'measure_to_half_cm',
    prompt: 'How long is the bar, in centimetres?',
    diagram: RulerSpec(
      totalLength: totalLength,
      markedLength: rawLength,
      unitLabel: 'cm',
      subdivisions: sub,
    ),
    correctAnswer: correct,
    distractors: _distinctStringDistractors(correct, [
      // Misconception: dropped the half — gave the whole only.
      '$whole',
      // Misconception: read up to the next whole tick.
      '${whole + 1}',
      // Misconception: counted half ticks as centimetres.
      '$rawLength',
      // Last-resort: nudge whole by 1.
      _mixedOrFraction(whole - 1, 1, sub),
    ]),
    explanation: [
      'Each small tick is half a centimetre.',
      'The bar stops halfway from $whole to $next → $correct cm.',
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
