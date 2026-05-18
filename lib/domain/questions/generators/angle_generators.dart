import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// G4 angle generators built on the new Angle widget:
/// right_acute_obtuse_angle, angle_addition.
/// Plus the G3 `fraction_on_number_line` follow-up which rides on
/// the existing NumberLine widget.

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
      'distractor pool exhausted; need 3 distinct vs "$correct", '
      'got ${out.length}: $out',
    );
  }
  return out.take(3).toList();
}

// ─────────────────────────────────────────────────────────────────────────
// right_acute_obtuse_angle (G4)
// ─────────────────────────────────────────────────────────────────────────

/// Classify a drawn angle as acute (< 90°), right (= 90°), or obtuse
/// (> 90°). CCSS 4.G.A.1.
///
/// Three classes drawn uniformly: acute ∈ [15, 85], right = 90, obtuse
/// ∈ [95, 165]. Reflex angles (> 180°) intentionally skipped — G4 doesn't
/// formally include them and the visual gets confusing.
GeneratedQuestion rightAcuteObtuseAngle(Random rand) {
  final kind = rand.nextInt(3); // 0 = acute, 1 = right, 2 = obtuse
  late int a;
  late String correct;
  switch (kind) {
    case 0:
      a = rand.nextInt(71) + 15; // 15..85
      correct = 'Acute';
    case 1:
      a = 90;
      correct = 'Right';
    default:
      a = rand.nextInt(71) + 95; // 95..165
      correct = 'Obtuse';
  }
  return GeneratedQuestion(
    conceptId: 'right_acute_obtuse_angle',
    prompt: 'How would you classify this angle?',
    diagram: AngleSpec(
      rayAnglesDeg: [0, a],
      wedgeLabels: const [AngleWedgeLabel(rayIndex: 0, label: '?')],
    ),
    correctAnswer: correct,
    distractors: _distinctStringDistractors(correct, [
      if (correct != 'Acute') 'Acute',
      if (correct != 'Right') 'Right',
      if (correct != 'Obtuse') 'Obtuse',
      'Straight',
    ]),
    explanation: [
      'Acute: less than 90°. Right: exactly 90°. Obtuse: more than 90°.',
      'This angle measures $a°, so it is $correct.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// angle_addition (G4)
// ─────────────────────────────────────────────────────────────────────────

/// "An angle has been split into two adjacent angles measuring $a° and
/// $b°. What is the total angle measure?" → a + b. CCSS 4.MD.C.7.
GeneratedQuestion angleAddition(Random rand) {
  // a + b in [20, 170] so the total fits comfortably under a straight line
  // and both sub-angles are visibly non-trivial (≥ 10°).
  int a;
  int b;
  do {
    a = rand.nextInt(80) + 10; // 10..89
    b = rand.nextInt(80) + 10; // 10..89
  } while (a + b > 170 || a + b < 30 || (a + b) == 90 || (a + b) == 180);
  final correct = a + b;
  return GeneratedQuestion(
    conceptId: 'angle_addition',
    prompt:
        'An angle has been split into two adjacent angles measuring '
        '$a° and $b°. What is the total angle measure?',
    diagram: AngleSpec(
      rayAnglesDeg: [0, a, a + b],
      wedgeLabels: [
        AngleWedgeLabel(rayIndex: 0, label: '$a°'),
        AngleWedgeLabel(rayIndex: 1, label: '$b°'),
      ],
    ),
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      // Misconception: subtracted instead of adding.
      misconception: (a - b).abs(),
    ),
    explanation: [
      'When two adjacent angles share a side, their measures add.',
      '$a° + $b° = $correct°.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// fraction_on_number_line (G3)
// ─────────────────────────────────────────────────────────────────────────

/// "What fraction is marked on the number line?" Number line spans 0..1
/// with the denominator as the number of divisions; the numerator marks
/// the highlighted tick. CCSS 3.NF.A.2.
///
/// Excludes numerator = denominator (= 1) and numerator = 0 so the
/// answer is a non-trivial proper fraction.
GeneratedQuestion fractionOnNumberLine(Random rand) {
  // Pick denom ∈ {2, 3, 4, 5, 6, 8}; numerator in [1, denom - 1].
  final d = [2, 3, 4, 5, 6, 8][rand.nextInt(6)];
  final n = rand.nextInt(d - 1) + 1; // 1..(d-1)
  final correct = '$n/$d';
  final value = n / d;
  return GeneratedQuestion(
    conceptId: 'fraction_on_number_line',
    prompt: 'What fraction is marked on the number line?',
    diagram: NumberLineSpec(
      min: 0,
      max: 1,
      divisions: d,
      markedPoints: [value],
    ),
    correctAnswer: correct,
    distractors: _distinctStringDistractors(correct, [
      // Misconception: swapped numerator and denominator (only when n != d-n
      // so it doesn't collide with correct).
      if (n != d - n) '$d/$n',
      // Misconception: counted the wrong tick (read complementary). Only
      // when n != d/2 to avoid collision with correct.
      if (2 * n != d) '${d - n}/$d',
      // Misconception: counted from 1 instead of 0 (off-by-one).
      if (n + 1 < d) '${n + 1}/$d',
      if (n - 1 >= 1) '${n - 1}/$d',
      // Misconception: thought there are d±1 / d±2 divisions.
      '$n/${d + 1}',
      if (n < d - 1) '$n/${d - 1}',
      '$n/${d + 2}',
      // Last-resort fallbacks for degenerate cases (e.g. n=1, d=2).
      '${n + 2}/$d',
      '${n + 1}/${d + 1}',
      if (n - 1 >= 1) '${n - 1}/${d - 1}',
    ]),
    explanation: [
      'The line 0 to 1 is divided into $d equal parts.',
      'The mark is at the ${_ordinal(n)} tick → $n/$d.',
    ],
    answerFormat: AnswerFormat.fraction,
    answerShape: AnswerShape.exactString,
  );
}

String _ordinal(int n) {
  if (n == 1) return '1st';
  if (n == 2) return '2nd';
  if (n == 3) return '3rd';
  return '${n}th';
}
