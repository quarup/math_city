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
