import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/fraction.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// G2/G3/G7/G8 fill-in batch: am_pm, length_diff_units,
/// triangle_inequality_recognize, adjacent_angles, exterior_angle_triangle,
/// inspect_system_no_solution, unit_rate_with_fractions.

// ─────────────────────────────────────────────────────────────────────────
// am_pm (G2)
// ─────────────────────────────────────────────────────────────────────────

const _amContexts = [
  'in the morning',
  'when the sun comes up',
  'at sunrise',
  'before lunch',
  'at breakfast',
];
const _pmContexts = [
  'in the afternoon',
  'in the evening',
  'at night',
  'after lunch',
  'at sunset',
  'at dinnertime',
];

/// "8:30 in the morning is ___" → a.m. (or p.m.). Context word
/// uniquely determines the period; time is decorative.
GeneratedQuestion amPm(Random rand) {
  final isAm = rand.nextBool();
  final ctx = isAm
      ? _amContexts[rand.nextInt(_amContexts.length)]
      : _pmContexts[rand.nextInt(_pmContexts.length)];
  final hour = rand.nextInt(11) + 1; // 1..11
  final minute = rand.nextInt(60);
  final mm = minute.toString().padLeft(2, '0');
  final correct = isAm ? 'a.m.' : 'p.m.';
  final wrong = isAm ? 'p.m.' : 'a.m.';
  return GeneratedQuestion(
    conceptId: 'am_pm',
    prompt: '$hour:$mm $ctx is ___',
    correctAnswer: correct,
    distractors: [wrong, 'Both', 'Neither'],
    explanation: ['"$ctx" tells you it is $correct.'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// length_diff_units (G2)
// ─────────────────────────────────────────────────────────────────────────

const _lengthScenarios = [
  ('pencil', 'eraser', 'cm'),
  ('marker', 'crayon', 'cm'),
  ('book', 'notebook', 'cm'),
  ('rope', 'string', 'in'),
  ('table', 'chair', 'in'),
];

/// "A pencil is 17 cm long. An eraser is 4 cm long. How much longer is
/// the pencil than the eraser?" → 13. Length difference word problem.
GeneratedQuestion lengthDiffUnits(Random rand) {
  final scenario = _lengthScenarios[rand.nextInt(_lengthScenarios.length)];
  final longer = scenario.$1;
  final shorter = scenario.$2;
  final unit = scenario.$3;
  late int a;
  late int b;
  do {
    a = rand.nextInt(80) + 10; // 10..89
    b = rand.nextInt(80) + 10;
  } while (a <= b || a - b < 2); // gap ≥ 2 so off-by-one distractors stay clean
  final correct = a - b;
  return GeneratedQuestion(
    conceptId: 'length_diff_units',
    prompt:
        'A $longer is $a $unit long. A $shorter is $b $unit long. '
        'How much longer is the $longer than the $shorter?',
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      misconception: a + b, // added instead of subtracted
    ),
    explanation: ['$a − $b = $correct $unit'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// triangle_inequality_recognize (G7)
// ─────────────────────────────────────────────────────────────────────────

/// "Can a triangle have sides of 3, 4, and 5?" → Yes / No. Three sides
/// form a triangle iff each side is < sum of the other two. 50% valid,
/// 50% invalid (one side ≥ sum of others) with a re-roll guard.
GeneratedQuestion triangleInequalityRecognize(Random rand) {
  final wantValid = rand.nextBool();
  late int a;
  late int b;
  late int c;
  while (true) {
    a = rand.nextInt(11) + 2; // 2..12
    b = rand.nextInt(11) + 2;
    c = rand.nextInt(11) + 2;
    final sides = [a, b, c]..sort();
    final isValid = sides[0] + sides[1] > sides[2];
    if (isValid == wantValid) break;
  }
  final correct = wantValid ? 'Yes' : 'No';
  return GeneratedQuestion(
    conceptId: 'triangle_inequality_recognize',
    prompt: 'Can a triangle have sides of length $a, $b, and $c?',
    correctAnswer: correct,
    distractors: [
      if (wantValid) 'No' else 'Yes',
      'Only if it is a right triangle',
      'Only if it is equilateral',
    ],
    explanation: [
      'Each side must be less than the sum of the other two.',
      if (wantValid)
        '$a < ${b + c}, $b < ${a + c}, $c < ${a + b} ✓'
      else
        'One side is at least the sum of the other two — no triangle.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// adjacent_angles (G7)
// ─────────────────────────────────────────────────────────────────────────

/// "Two adjacent angles share a side and together form a right angle
/// (or a straight line). One measures $a°. What is the other?" → 90−a
/// (or 180−a). Same arithmetic as complementary / supplementary but
/// surfaces the "adjacent angles share a side" framing.
GeneratedQuestion adjacentAngles(Random rand) {
  final isRight = rand.nextBool();
  final total = isRight ? 90 : 180;
  late int a;
  do {
    a = rand.nextInt(total - 1) + 1; // 1..(total-1)
  } while (a == total ~/ 2); // skip a == total/2 so distractor variety holds
  final correct = total - a;
  final figure = isRight ? 'right angle' : 'straight line';
  return GeneratedQuestion(
    conceptId: 'adjacent_angles',
    prompt:
        'Two adjacent angles share a side and together form a $figure. '
        'One angle measures $a°. What is the other angle in degrees?',
    diagram: AngleSpec(
      // Right angle: rays at 0°, 90°. Straight line: rays at 0°, 180°.
      // Divider ray at a° splits the full wedge into a° and (total − a)°.
      rayAnglesDeg: [0, a, total],
      wedgeLabels: [
        AngleWedgeLabel(rayIndex: 0, label: '$a°'),
        const AngleWedgeLabel(rayIndex: 1, label: '?'),
      ],
    ),
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      // Misconception: used the other total (right vs straight).
      misconception: (isRight ? 180 : 90) - a,
    ),
    explanation: [
      'The two angles together equal $total°.',
      '$total − $a = $correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// exterior_angle_triangle (G8)
// ─────────────────────────────────────────────────────────────────────────

/// "A triangle has interior angles measuring $a° and $b°. What is the
/// measure of the exterior angle adjacent to the third interior angle?"
/// → a + b (exterior angle theorem). Misconception: third interior
/// angle (180 − a − b).
GeneratedQuestion exteriorAngleTriangle(Random rand) {
  late int a;
  late int b;
  do {
    a = rand.nextInt(81) + 20; // 20..100
    b = rand.nextInt(81) + 20;
  } while (a + b < 30 || a + b > 170);
  final correct = a + b;
  final third = 180 - a - b;
  return GeneratedQuestion(
    conceptId: 'exterior_angle_triangle',
    prompt:
        'A triangle has two interior angles measuring $a° and $b°. '
        'What is the measure of the exterior angle adjacent to the '
        'third interior angle, in degrees?',
    diagram: TriangleAnglesSpec(
      angleDegA: a,
      angleDegB: b,
      angleDegC: third,
      labelA: '$a°',
      labelB: '$b°',
      labelC: '?',
      showExteriorAtC: true,
    ),
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      misconception: third, // gave the third interior angle
    ),
    explanation: [
      'Exterior angle = sum of the two remote interior angles.',
      '$a + $b = $correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// inspect_system_no_solution (G8)
// ─────────────────────────────────────────────────────────────────────────

/// Three-way classification of a system of two linear equations into
/// "one solution" / "no solution" / "infinitely many". Same logic as
/// solve_linear_eq_no_or_inf but on a SYSTEM rather than a single
/// equation. Distinct test: same slope + same intercept → infinite;
/// same slope + diff intercept → none; diff slope → one.
GeneratedQuestion inspectSystemNoSolution(Random rand) {
  final outcome = rand.nextInt(3); // 0 = one, 1 = none, 2 = infinite
  late int m1;
  late int m2;
  late int b1;
  late int b2;
  switch (outcome) {
    case 0:
      do {
        m1 = rand.nextInt(7) - 3; // -3..3
        m2 = rand.nextInt(7) - 3;
      } while (m1 == m2);
      b1 = rand.nextInt(11) - 5;
      b2 = rand.nextInt(11) - 5;
    case 1:
      m1 = m2 = rand.nextInt(5) + 1; // 1..5
      do {
        b1 = rand.nextInt(11) - 5;
        b2 = rand.nextInt(11) - 5;
      } while (b1 == b2);
    default: // 2
      m1 = m2 = rand.nextInt(5) + 1;
      b1 = b2 = rand.nextInt(11) - 5;
  }
  final correct = switch (outcome) {
    0 => 'Exactly one solution',
    1 => 'No solution',
    _ => 'Infinitely many solutions',
  };
  final distractors = <String>[
    'Exactly one solution',
    'No solution',
    'Infinitely many solutions',
    'Cannot tell from these equations',
  ]..removeWhere((s) => s == correct);
  return GeneratedQuestion(
    conceptId: 'inspect_system_no_solution',
    prompt:
        'How many solutions does this system have?\n'
        '• y = ${_fmtMx(m1)} ${_fmtB(b1)}\n'
        '• y = ${_fmtMx(m2)} ${_fmtB(b2)}',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Same slope, same intercept → infinitely many.',
      'Same slope, different intercept → none.',
      'Different slope → exactly one.',
    ],
  );
}

String _fmtMx(int m) {
  if (m == 0) return '0';
  if (m == 1) return 'x';
  if (m == -1) return '−x';
  return m < 0 ? '−${-m}x' : '${m}x';
}

String _fmtB(int b) {
  if (b == 0) return '';
  return b < 0 ? '− ${-b}' : '+ $b';
}

// ─────────────────────────────────────────────────────────────────────────
// unit_rate_with_fractions (G7)
// ─────────────────────────────────────────────────────────────────────────

/// "Sarah ran 1/2 mile in 1/4 hour. How many miles per hour did she run?"
/// → 2. Distance and time are both fractions; the quotient is forced to
/// a small whole number so the kid sees a clean unit-rate result.
GeneratedQuestion unitRateWithFractions(Random rand) {
  // Build the answer first: rate ∈ {2, 3, 4, 5} mi/hr.
  final rate = rand.nextInt(4) + 2;
  // Pick a time fraction t = p/q with q ∈ {2, 3, 4}, p ∈ [1, q-1].
  final q = [2, 3, 4][rand.nextInt(3)];
  final p = rand.nextInt(q - 1) + 1; // 1..(q-1)
  final time = Fraction(p, q);
  // distance = rate × time, kept as a fraction (always proper-or-improper
  // canonical) so the prompt feels natural.
  final distance = Fraction(rate * p, q).reduce();
  final correct = '$rate';
  final timeStr = _renderFraction(time);
  final distanceStr = _renderFraction(distance);
  return GeneratedQuestion(
    conceptId: 'unit_rate_with_fractions',
    prompt:
        'Sam ran $distanceStr miles in $timeStr hours. '
        'How many miles per hour did Sam run?',
    correctAnswer: correct,
    distractors: integerDistractorsWith(
      rate,
      rand,
      // Misconception: multiplied instead of divided.
      misconception: distance.numerator * time.numerator,
    ),
    explanation: [
      'rate = distance ÷ time = $distanceStr ÷ $timeStr = $rate.',
    ],
  );
}

String _renderFraction(Fraction f) {
  final s = f.reduce();
  if (s.denominator == 1) return '${s.numerator}';
  // Render mixed for improper fractions to read naturally as "1 1/2".
  if (s.numerator.abs() > s.denominator) {
    final whole = s.numerator ~/ s.denominator;
    final rem = s.numerator.abs() - whole.abs() * s.denominator;
    if (rem == 0) return '$whole';
    return '$whole $rem/${s.denominator}';
  }
  return '${s.numerator}/${s.denominator}';
}
