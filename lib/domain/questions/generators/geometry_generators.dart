import 'dart:math';

import 'package:math_city/domain/questions/generated_question.dart';

/// Geometry generators — area + perimeter (Grades 3 & 6).
///
/// Implemented without the curriculum-suggested `RectangleArea` / `Shape`
/// widgets — the math works verbally ("rectangle with length 5 and
/// width 7"). The visual widgets can be added later for richer UX.

// ─────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────

List<String> _wholeDistractors(
  int correct,
  List<String> candidates,
  Random rand,
) {
  final out = <String>[];
  final seen = <String>{'$correct'};
  for (final c in candidates) {
    if (out.length >= 3) break;
    if (seen.add(c)) out.add(c);
  }
  for (var i = 1; out.length < 3 && i < 30; i++) {
    for (final delta in <int>[i, -i]) {
      final v = correct + delta;
      if (v < 1) continue;
      final s = '$v';
      if (seen.add(s)) out.add(s);
      if (out.length >= 3) break;
    }
  }
  return out.take(3).toList();
}

// ─────────────────────────────────────────────────────────────────────────
// area_rectangle_formula (Grade 3)
// ─────────────────────────────────────────────────────────────────────────

/// "A rectangle has length 7 and width 5. What is its area?" → 35.
/// Sides chosen so the product fits in [4, 144].
GeneratedQuestion areaRectangleFormula(Random rand) {
  final l = rand.nextInt(11) + 2; // 2..12
  final w = rand.nextInt(11) + 2; // 2..12
  final area = l * w;
  final correct = '$area';

  final candidates = <String>[
    // Misconception: perimeter (2l + 2w).
    '${2 * (l + w)}',
    // Misconception: l + w (semi-perimeter).
    '${l + w}',
    // Off-by-one in one dimension.
    '${(l + 1) * w}',
  ];

  return GeneratedQuestion(
    conceptId: 'area_rectangle_formula',
    prompt: 'A rectangle has length $l and width $w. What is its area?',
    correctAnswer: correct,
    distractors: _wholeDistractors(area, candidates, rand),
    explanation: [
      'Area = length × width.',
      '$l × $w = $area.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// perimeter_polygon (Grade 3)
// ─────────────────────────────────────────────────────────────────────────

/// Half the time: square (4 sides equal). Half the time: rectangle.
/// "A rectangle has length 7 and width 5. What is its perimeter?" → 24.
GeneratedQuestion perimeterPolygon(Random rand) {
  final isSquare = rand.nextBool();
  if (isSquare) {
    final s = rand.nextInt(19) + 2; // 2..20
    final p = 4 * s;
    final correct = '$p';
    final candidates = <String>[
      // Misconception: gave the side length.
      '$s',
      // Misconception: gave area (s²).
      '${s * s}',
      // Misconception: 3s.
      '${3 * s}',
    ];
    return GeneratedQuestion(
      conceptId: 'perimeter_polygon',
      prompt: 'A square has side length $s. What is its perimeter?',
      correctAnswer: correct,
      distractors: _wholeDistractors(p, candidates, rand),
      explanation: [
        'Perimeter of a square = 4 × side.',
        '4 × $s = $p.',
      ],
    );
  } else {
    final l = rand.nextInt(15) + 2;
    final w = rand.nextInt(15) + 2;
    final p = 2 * (l + w);
    final correct = '$p';
    final candidates = <String>[
      // Misconception: l × w (area).
      '${l * w}',
      // Misconception: l + w (semi-perimeter).
      '${l + w}',
      // Off by 2.
      '${p + 2}',
    ];
    return GeneratedQuestion(
      conceptId: 'perimeter_polygon',
      prompt: 'A rectangle has length $l and width $w. What is its perimeter?',
      correctAnswer: correct,
      distractors: _wholeDistractors(p, candidates, rand),
      explanation: [
        'Perimeter = 2 × (length + width).',
        '2 × ($l + $w) = 2 × ${l + w} = $p.',
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// area_parallelogram (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "A parallelogram has base 6 and height 4. What is its area?" → 24.
/// Same formula as rectangle (base × height) but with the geometric
/// reminder that the side length is NOT what counts.
GeneratedQuestion areaParallelogram(Random rand) {
  final base = rand.nextInt(11) + 2; // 2..12
  final height = rand.nextInt(11) + 2;
  final area = base * height;
  final correct = '$area';

  final candidates = <String>[
    // Misconception: ½ × b × h (confused with triangle).
    '${(base * height) ~/ 2}',
    // Misconception: base + height.
    '${base + height}',
    // Misconception: 2 × (b + h) (perimeter-style).
    '${2 * (base + height)}',
  ];

  return GeneratedQuestion(
    conceptId: 'area_parallelogram',
    prompt:
        'A parallelogram has base $base and height $height. '
        'What is its area?',
    correctAnswer: correct,
    distractors: _wholeDistractors(area, candidates, rand),
    explanation: [
      'Area of a parallelogram = base × height.',
      '$base × $height = $area.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// area_trapezoid (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "A trapezoid has parallel sides 4 and 6, and height 8. Area?" → 40.
/// Formula: ½ × (b1 + b2) × h. Generator re-rolls until (b1+b2)×h is
/// even, guaranteeing an integer answer.
GeneratedQuestion areaTrapezoid(Random rand) {
  late int b1;
  late int b2;
  late int h;
  do {
    b1 = rand.nextInt(9) + 2; // 2..10
    b2 = rand.nextInt(9) + 2;
    h = rand.nextInt(9) + 2;
  } while (b1 == b2 || ((b1 + b2) * h).isOdd);
  final area = ((b1 + b2) * h) ~/ 2;
  final correct = '$area';

  final candidates = <String>[
    // Misconception: (b1 + b2) × h (forgot the ½).
    '${(b1 + b2) * h}',
    // Misconception: b1 × b2 (wrong formula entirely).
    '${b1 * b2}',
    // Misconception: only one base.
    '${b1 * h}',
  ];

  return GeneratedQuestion(
    conceptId: 'area_trapezoid',
    prompt:
        'A trapezoid has parallel sides of length $b1 and $b2, and '
        'height $h. What is its area?',
    correctAnswer: correct,
    distractors: _wholeDistractors(area, candidates, rand),
    explanation: [
      'Area of a trapezoid = ½ × (b₁ + b₂) × h.',
      '½ × ($b1 + $b2) × $h = ½ × ${b1 + b2} × $h = $area.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// perimeter_unknown_side (Grade 3)
// ─────────────────────────────────────────────────────────────────────────

/// "A rectangle has perimeter 24 and length 8. What is its width?"
/// → 4. Given P and one side, recover the other.
GeneratedQuestion perimeterUnknownSide(Random rand) {
  final l = rand.nextInt(11) + 2; // 2..12
  final w = rand.nextInt(11) + 2;
  final p = 2 * (l + w);
  final correct = '$w';

  final candidates = <String>[
    // Misconception: gave the perimeter directly.
    '$p',
    // Misconception: gave the given side.
    '$l',
    // Misconception: subtracted but didn't ÷ 2.
    '${p - 2 * l}',
  ];

  return GeneratedQuestion(
    conceptId: 'perimeter_unknown_side',
    prompt: 'A rectangle has perimeter $p and length $l. What is its width?',
    correctAnswer: correct,
    distractors: _wholeDistractors(w, candidates, rand),
    explanation: [
      'P = 2 × (l + w).  So l + w = P ÷ 2 = ${p ~/ 2}.',
      'Width = (P ÷ 2) − l = ${p ~/ 2} − $l = $w.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// area_triangle (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "A triangle has base 8 and height 5. What is its area?" → 20.
/// Base × height is always even so the ÷2 is exact.
GeneratedQuestion areaTriangle(Random rand) {
  // Need base × height to be even. Force at least one of them to be even.
  late int base;
  late int height;
  do {
    base = rand.nextInt(11) + 2; // 2..12
    height = rand.nextInt(11) + 2;
  } while ((base * height).isOdd);
  final area = (base * height) ~/ 2;
  final correct = '$area';

  final candidates = <String>[
    // Misconception: forgot to divide by 2 (full rectangle).
    '${base * height}',
    // Misconception: added base + height.
    '${base + height}',
    // Off-by-one.
    '${area + 1}',
  ];

  return GeneratedQuestion(
    conceptId: 'area_triangle',
    prompt: 'A triangle has base $base and height $height. What is its area?',
    correctAnswer: correct,
    distractors: _wholeDistractors(area, candidates, rand),
    explanation: [
      'Area of a triangle = ½ × base × height.',
      '½ × $base × $height = ${base * height} ÷ 2 = $area.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// supplementary_angles (Grade 7)
// ─────────────────────────────────────────────────────────────────────────

/// "Two angles are supplementary. One is 65°. What is the other?" → 115°.
/// Implemented text-only; the visual `Angle` widget can wire in later.
GeneratedQuestion supplementaryAngles(Random rand) {
  // Pick angle1 in [10, 170] excluding 90 (would give a == b = 90°).
  int a;
  do {
    a = rand.nextInt(161) + 10; // 10..170
  } while (a == 90);
  final b = 180 - a;
  final correct = '$b';

  final candidates = <String>[
    // Misconception: used complementary (90 − a) — only valid when a < 90.
    if (a < 90) '${90 - a}',
    // Misconception: gave the same angle back.
    '$a',
    // Misconception: used 360 (angles around a point).
    '${360 - a}',
    // Misconception: doubled the original.
    '${2 * a}',
  ];

  return GeneratedQuestion(
    conceptId: 'supplementary_angles',
    prompt: 'Two angles are supplementary. One is $a°. What is the other?',
    correctAnswer: correct,
    distractors: _wholeDistractors(b, candidates, rand),
    explanation: [
      'Supplementary angles add up to 180°.',
      'Other = 180° − $a° = $b°.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// complementary_angles (Grade 7)
// ─────────────────────────────────────────────────────────────────────────

/// "Two angles are complementary. One is 35°. What is the other?" → 55°.
GeneratedQuestion complementaryAngles(Random rand) {
  // Pick angle1 in [10, 80] excluding 45 (would give a == b = 45°).
  int a;
  do {
    a = rand.nextInt(71) + 10; // 10..80
  } while (a == 45);
  final b = 90 - a;
  final correct = '$b';

  final candidates = <String>[
    // Misconception: used supplementary (180 − a).
    '${180 - a}',
    // Misconception: gave the same angle back.
    '$a',
    // Misconception: added instead of subtracted.
    '${90 + a}',
  ];

  return GeneratedQuestion(
    conceptId: 'complementary_angles',
    prompt: 'Two angles are complementary. One is $a°. What is the other?',
    correctAnswer: correct,
    distractors: _wholeDistractors(b, candidates, rand),
    explanation: [
      'Complementary angles add up to 90°.',
      'Other = 90° − $a° = $b°.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// vertical_angles (Grade 7)
// ─────────────────────────────────────────────────────────────────────────

/// Two intersecting lines form four angles. Two adjacent angles form a
/// linear pair (sum to 180°); two opposite (vertical) angles are equal.
/// Half the questions ask for the vertical angle (= a); half ask for an
/// adjacent angle (= 180° − a).
GeneratedQuestion verticalAngles(Random rand) {
  int a;
  do {
    a = rand.nextInt(161) + 10; // 10..170
  } while (a == 90);
  final askVertical = rand.nextBool();
  final answer = askVertical ? a : 180 - a;
  final relation = askVertical ? 'vertical to' : 'adjacent to';
  final correct = '$answer';

  final candidates = <String>[
    // Misconception: confused vertical and adjacent — gave the *other* answer.
    '${askVertical ? 180 - a : a}',
    // Misconception: used 360 (whole turn).
    '${360 - a}',
    // Misconception: used 90 (right angle).
    '${(90 - a).abs()}',
  ];

  return GeneratedQuestion(
    conceptId: 'vertical_angles',
    prompt:
        'Two lines cross. One angle measures $a°. What is the angle '
        '$relation it?',
    correctAnswer: correct,
    distractors: _wholeDistractors(answer, candidates, rand),
    explanation: [
      'Vertical (opposite) angles are equal.',
      'Adjacent angles on a straight line add to 180°.',
      if (askVertical)
        'The vertical angle equals $a°.'
      else
        'The adjacent angle is 180° − $a° = ${180 - a}°.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// triangle_angle_sum (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// "A triangle has angles 35° and 75°. What is the third angle?" → 70°.
GeneratedQuestion triangleAngleSum(Random rand) {
  // Need a + b in [10, 170] so the third angle is in [10, 170].
  int a;
  int b;
  do {
    a = rand.nextInt(151) + 10; // 10..160
    b = rand.nextInt(151) + 10;
  } while (a + b < 20 || a + b > 170 || a + b == 90);
  final c = 180 - a - b;
  final correct = '$c';

  final candidates = <String>[
    // Misconception: used 90° sum.
    if (a + b < 90) '${90 - a - b}',
    // Misconception: used 360° sum.
    '${360 - a - b}',
    // Misconception: gave a + b (sum, not third angle).
    '${a + b}',
    // Misconception: 180 - max(a, b) only.
    '${180 - (a > b ? a : b)}',
  ];

  return GeneratedQuestion(
    conceptId: 'triangle_angle_sum',
    prompt: 'A triangle has angles $a° and $b°. What is the third angle?',
    correctAnswer: correct,
    distractors: _wholeDistractors(c, candidates, rand),
    explanation: [
      'The three angles of a triangle add up to 180°.',
      'Third = 180° − $a° − $b° = $c°.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// parallel_lines_transversal (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// "Two parallel lines are cut by a transversal. One angle is 65°. What
/// is the *corresponding* angle?" → 65°.
///
/// Four relationship types are sampled uniformly. Three are equal-angle
/// (corresponding, alternate interior, alternate exterior); one is
/// supplementary (co-interior / same-side interior).
GeneratedQuestion parallelLinesTransversal(Random rand) {
  int a;
  do {
    a = rand.nextInt(141) + 20; // 20..160
  } while (a == 90);
  const relations = <String>[
    'corresponding',
    'alternate interior',
    'alternate exterior',
    'co-interior',
  ];
  final relation = relations[rand.nextInt(relations.length)];
  final isSupplementary = relation == 'co-interior';
  final answer = isSupplementary ? 180 - a : a;
  final correct = '$answer';

  final candidates = <String>[
    // Misconception: applied the *other* rule.
    '${isSupplementary ? a : 180 - a}',
    // Misconception: complementary.
    if (a < 90) '${90 - a}',
    // Misconception: full turn.
    '${360 - a}',
  ];

  return GeneratedQuestion(
    conceptId: 'parallel_lines_transversal',
    prompt:
        'Two parallel lines are cut by a transversal. One angle is $a°. '
        'What is the $relation angle?',
    correctAnswer: correct,
    distractors: _wholeDistractors(answer, candidates, rand),
    explanation: [
      if (isSupplementary)
        'Co-interior (same-side interior) angles add up to 180°.'
      else
        '$relation angles are equal when lines are parallel.',
      if (isSupplementary)
        'Other = 180° − $a° = ${180 - a}°.'
      else
        'Other = $a°.',
    ],
  );
}
