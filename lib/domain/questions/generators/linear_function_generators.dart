import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// G8 linear-function generators that build on the `CoordinatePlane`
/// line extension from Chunk 33.
///
/// `identify_linear_vs_nonlinear` shows a table of (x, y) pairs in the
/// prompt and asks whether the relationship is linear; no diagram.
/// `solve_system_by_graphing` draws two lines with a known integer
/// intersection on the coordinate plane and asks for the intersection
/// point.

const _minus = '−'; // U+2212

String _signed(int n) => n >= 0 ? '$n' : '$_minus${-n}';

String _coord(int x, int y) => '(${_signed(x)}, ${_signed(y)})';

// ─────────────────────────────────────────────────────────────────────────
// identify_linear_vs_nonlinear (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// "Is this relationship linear or nonlinear?" — show a 4-row table.
/// 50% linear (constant Δy/Δx), 50% nonlinear (Δy/Δx changes). The
/// table itself is the only thing the kid sees — no diagram, no
/// coordinate plane.
GeneratedQuestion identifyLinearVsNonlinear(Random rand) {
  final isLinear = rand.nextBool();
  // x-values are 4 consecutive integers starting at some x0 ∈ [-2, 2].
  // Step is always +1 so the "Δy/Δx is constant" check reduces to
  // "consecutive y-differences are all equal".
  final x0 = rand.nextInt(5) - 2;
  final xs = [for (var i = 0; i < 4; i++) x0 + i];

  late List<int> ys;
  if (isLinear) {
    // y = mx + b with m ∈ {-2, -1, 1, 2} (skip 0 — too obviously linear)
    // and b ∈ [-3, 3].
    final m = const [-2, -1, 1, 2][rand.nextInt(4)];
    final b = rand.nextInt(7) - 3;
    ys = xs.map((x) => m * x + b).toList();
  } else {
    // Nonlinear: y = x² + offset, y = x³ + offset, or |x| + offset.
    // Add a small offset so the table doesn't always start at 0.
    final offset = rand.nextInt(5) - 2;
    switch (rand.nextInt(3)) {
      case 0:
        ys = xs.map((x) => x * x + offset).toList();
      case 1:
        ys = xs.map((x) => x * x * x + offset).toList();
      default:
        ys = xs.map((x) => x.abs() + offset).toList();
    }
    // Safety check: this MIGHT accidentally produce a linear sequence
    // (e.g., y = |x| with x ∈ {0, 1, 2, 3} is monotonic but linear —
    // [0, 1, 2, 3] has constant Δ). Re-roll if so.
    if (_isArithmetic(ys)) return identifyLinearVsNonlinear(rand);
  }

  final correct = isLinear ? 'Linear' : 'Nonlinear';
  // Distractors are the standard confidence-builder choices.
  final distractors = [
    if (isLinear) 'Nonlinear' else 'Linear',
    'Cannot tell from a table',
    'Only a graph can answer this',
  ];

  final tableStr = [
    for (var i = 0; i < 4; i++) '(${xs[i]}, ${ys[i]})',
  ].join('; ');

  return GeneratedQuestion(
    conceptId: 'identify_linear_vs_nonlinear',
    prompt: 'Table: $tableStr. Is this relationship linear or nonlinear?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: isLinear
        ? [
            'Δy between rows is constant (${ys[1] - ys[0]} each step).',
            'A constant rate of change means the relationship is linear.',
          ]
        : [
            'Δy varies: ${ys[1] - ys[0]}, ${ys[2] - ys[1]}, ${ys[3] - ys[2]}.',
            'A changing rate of change means the relationship is nonlinear.',
          ],
    answerFormat: AnswerFormat.string,
  );
}

bool _isArithmetic(List<int> ys) {
  if (ys.length < 2) return true;
  final d = ys[1] - ys[0];
  for (var i = 2; i < ys.length; i++) {
    if (ys[i] - ys[i - 1] != d) return false;
  }
  return true;
}

// ─────────────────────────────────────────────────────────────────────────
// solve_system_by_graphing (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// Draw two lines on a `[-6, 6]` four-quadrant plane with a known integer
/// intersection. Ask "Where do the lines intersect?" — 4-choice MC over
/// coordinate strings.
GeneratedQuestion solveSystemByGraphing(Random rand) {
  // Intersection at (a, b) ∈ [-3, 3] × [-3, 3].
  final a = rand.nextInt(7) - 3;
  final b = rand.nextInt(7) - 3;

  // Two distinct slopes from {±1, ±2} so the lines actually cross.
  late int m1;
  late int m2;
  do {
    m1 = const [-2, -1, 1, 2][rand.nextInt(4)];
    m2 = const [-2, -1, 1, 2][rand.nextInt(4)];
  } while (m1 == m2);

  // y-intercepts derived so each line passes through (a, b):
  //   y = m·x + bIntercept  ⇒  bIntercept = b − m·a
  final bInt1 = b - m1 * a;
  final bInt2 = b - m2 * a;

  // Anchor each line at x = a − 2 and x = a + 2 — guaranteed in [-5, 5]
  // since a ∈ [-3, 3]. y at these anchors is b ± 2·m which stays inside
  // [-9, 9] but the renderer clips to the visible rect anyway.
  CoordinatePlaneLine lineFor(int m, int bInt) {
    final x1 = a - 2;
    final x2 = a + 2;
    return CoordinatePlaneLine(
      x1: x1,
      y1: m * x1 + bInt,
      x2: x2,
      y2: m * x2 + bInt,
    );
  }

  final correct = _coord(a, b);
  // Misconception distractors:
  //   - swap (a, b) → (b, a)
  //   - off-by-one in either coord
  //   - "No solution" (the standard "wait, do they cross?" red herring)
  final candidates = <String>[
    if (a != b) _coord(b, a),
    _coord(a + 1, b),
    _coord(a, b + 1),
    _coord(a - 1, b),
    _coord(a, b - 1),
    'No solution',
  ];

  return GeneratedQuestion(
    conceptId: 'solve_system_by_graphing',
    prompt: 'At what point do the two lines intersect?',
    diagram: CoordinatePlaneSpec(
      minX: -6,
      maxX: 6,
      minY: -6,
      maxY: 6,
      lines: [
        lineFor(m1, bInt1),
        lineFor(m2, bInt2),
      ],
    ),
    correctAnswer: correct,
    distractors: _distinctStrings(correct, candidates),
    explanation: [
      'Trace each line. They both pass through ${_coord(a, b)}.',
      'That is the solution to the system.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

List<String> _distinctStrings(String correct, List<String> candidates) {
  final out = <String>[];
  final seen = <String>{correct};
  for (final c in candidates) {
    if (out.length >= 3) break;
    if (seen.add(c)) out.add(c);
  }
  if (out.length < 3) {
    throw StateError(
      'distractor pool exhausted: correct="$correct" candidates=$candidates',
    );
  }
  return out;
}
