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
// triangle_inequality_recognize (Grade 7)
// ─────────────────────────────────────────────────────────────────────────

/// "Can a triangle have sides of length 3, 4, 5?" → "yes". MC over
/// {yes, no, only if all sides are equal, can't tell without more info}.
/// Triangle inequality: each side < sum of the other two.
GeneratedQuestion triangleInequalityRecognize(Random rand) {
  final shouldBeValid = rand.nextBool();
  int a;
  int b;
  int c;
  if (shouldBeValid) {
    a = rand.nextInt(8) + 2; // 2..9
    b = rand.nextInt(8) + 2;
    final lo = (a - b).abs() + 1;
    final hi = a + b - 1;
    if (hi < lo) return triangleInequalityRecognize(rand);
    c = lo + rand.nextInt(hi - lo + 1);
  } else {
    a = rand.nextInt(6) + 2; // 2..7
    b = rand.nextInt(6) + 2;
    c = a + b + rand.nextInt(4); // a + b ≤ c ≤ a + b + 3
  }
  // Shuffle so the over-large side isn't always c.
  final sides = [a, b, c]..shuffle(rand);
  final correct = shouldBeValid ? 'yes' : 'no';
  final distractors = <String>[
    if (shouldBeValid) 'no' else 'yes',
    'only if all sides are equal',
    "can't tell without more info",
  ];

  return GeneratedQuestion(
    conceptId: 'triangle_inequality_recognize',
    prompt:
        'Can a triangle have sides of length '
        '${sides[0]}, ${sides[1]}, and ${sides[2]}?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      // ignore: no_adjacent_strings_in_list — single line wrapped for length
      'Triangle inequality: each side must be less than the sum of the '
          'other two.',
      if (shouldBeValid)
        'All three checks pass — a triangle with these sides exists.'
      else
        'The longest side ≥ sum of the other two — no triangle possible.',
    ],
    answerFormat: AnswerFormat.string,
  );
}
