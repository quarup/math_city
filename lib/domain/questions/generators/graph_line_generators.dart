import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// Linear-equation-on-a-grid generators (Grade 8, `prealgebra` and
/// `stats` categories).
///
/// `graph_linear_equation` draws one line with chosen slope/intercept on
/// a `CoordinatePlane` and asks the student to pick the matching
/// equation. `informal_line_of_fit` shows a scatter plot with a dashed
/// candidate line and asks for the line's slope.

const _minus = '−'; // U+2212

/// Format a signed integer with the kid-textbook minus sign.
String _signed(int n) => n >= 0 ? '$n' : '$_minus${-n}';

/// "y = mx + b" string with conventional formatting:
///   - m = 1 → "y = x + b" (drop the 1)
///   - m = -1 → "y = -x + b"
///   - b > 0 → "+ b"
///   - b < 0 → "- |b|"
///   - b = 0 → "y = mx"
String _equation(int m, int b) {
  final mPart = switch (m) {
    1 => 'x',
    -1 => '${_minus}x',
    _ => '${_signed(m)}x',
  };
  if (b == 0) return 'y = $mPart';
  final sign = b > 0 ? '+' : _minus;
  return 'y = $mPart $sign ${b.abs()}';
}

// ─────────────────────────────────────────────────────────────────────────
// graph_linear_equation (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// Draw a line on a 4-quadrant `[-6, 6]` plane and ask which equation it
/// matches. Slope ∈ {±1, ±2}; intercept ∈ [-3, 3] excluding 0 so y = mx
/// (degenerate form) doesn't appear as the answer.
GeneratedQuestion graphLinearEquation(Random rand) {
  final m = const [-2, -1, 1, 2][rand.nextInt(4)];
  // Pick b ∈ [-3, 3] excluding 0.
  late int b;
  do {
    b = rand.nextInt(7) - 3;
  } while (b == 0);

  // Two anchor points on the line — pick any two distinct integer x
  // values where the line is in range. m·x + b for x = -2 and x = 2
  // always gives y ∈ [-3 + 2·(-2), 3 + 2·2] = [-7, 7], which is inside
  // [-6, 6] except for the extreme m=2,b=±3,x=±2 case (y=±7). Use x=-1
  // and x=1 instead — y stays in [-5, 5].
  final p1 = (x: -1, y: -m + b);
  final p2 = (x: 1, y: m + b);

  final correct = _equation(m, b);

  // Misconception distractors — each picks a common slope/intercept
  // confusion.
  final candidates = <String>[
    // Sign-flipped slope.
    _equation(-m, b),
    // Sign-flipped intercept.
    _equation(m, -b),
    // Off-by-one slope.
    _equation(m + 1, b),
    _equation(m - 1, b),
    // Swap m and b (only when both are non-zero and would yield a
    // distinct-looking equation).
    if (b != m && b != 0) _equation(b, m),
  ];

  return GeneratedQuestion(
    conceptId: 'graph_linear_equation',
    prompt: 'Which equation does the line on this plane represent?',
    diagram: CoordinatePlaneSpec(
      minX: -6,
      maxX: 6,
      minY: -6,
      maxY: 6,
      lines: [
        CoordinatePlaneLine(
          x1: p1.x,
          y1: p1.y,
          x2: p2.x,
          y2: p2.y,
        ),
      ],
    ),
    correctAnswer: correct,
    distractors: _distinctStrings(correct, candidates),
    explanation: [
      'The line rises by $m for every step right (slope m = $m).',
      'It crosses the y-axis at $b (intercept b = $b).',
      'So y = mx + b = $correct.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// informal_line_of_fit (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// Show 8 scatter-plot points along y ≈ mx + b plus a dashed "best fit"
/// line at the exact (m, b). Ask: "What is the slope of the dashed line
/// of best fit?" Slope is restricted to ±1 or ±2 for clean MC.
GeneratedQuestion informalLineOfFit(Random rand) {
  final m = const [-2, -1, 1, 2][rand.nextInt(4)];
  // Intercept chosen so the line passes near the centre of the visible
  // [-6, 6] × [-6, 6] plot at reasonable x values.
  final b = rand.nextInt(3) - 1; // -1, 0, 1
  const xs = [-5, -4, -2, -1, 1, 2, 4, 5];
  final points = <CoordinatePlanePoint>[];
  for (final x in xs) {
    // y = mx + b with small symmetric jitter (-1, 0, +1)
    final y = (m * x + b + rand.nextInt(3) - 1).clamp(-6, 6);
    points.add(CoordinatePlanePoint(x: x, y: y));
  }
  // Two anchor points for the dashed best-fit line.
  final p1 = (x: -1, y: -m + b);
  final p2 = (x: 1, y: m + b);

  final correct = _signed(m);
  // MC over plausible-but-wrong slope guesses.
  final candidates = <String>[
    _signed(-m),
    _signed(m + 1),
    _signed(m - 1),
    '0',
  ];

  return GeneratedQuestion(
    conceptId: 'informal_line_of_fit',
    prompt: 'What is the slope of the dashed line of best fit?',
    diagram: CoordinatePlaneSpec(
      minX: -6,
      maxX: 6,
      minY: -6,
      maxY: 6,
      points: points,
      lines: [
        CoordinatePlaneLine(
          x1: p1.x,
          y1: p1.y,
          x2: p2.x,
          y2: p2.y,
          style: CoordinatePlaneLineStyle.dashed,
        ),
      ],
    ),
    correctAnswer: correct,
    distractors: _distinctStrings(correct, candidates),
    explanation: [
      'Pick two points on the line such as (-1, ${-m + b}) and (1, ${m + b}).',
      'Slope = (${m + b} − ${-m + b}) / (1 − ${-1}) = ${2 * m} / 2 = $m.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

/// Three unique string distractors that differ from [correct]. Throws
/// if the candidate pool exhausts (loud failure beats junk strings).
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
