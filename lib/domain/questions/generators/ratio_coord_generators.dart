import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// Grade-6 generators that combine ratios with the coordinate plane.
///
/// `ratio_to_coordinate_pairs` plots a ratio's equivalent ordered pairs
/// `(k·a, k·b)` for `k = 1, 2, 3` and asks the kid to read off the
/// underlying ratio `a:b`.
///
/// `dependent_independent_vars` is text-only — picks a real-world
/// scenario (cost vs hours, distance vs time, …) and asks which of
/// the two named variables is the independent (or dependent) one.

// ─────────────────────────────────────────────────────────────────────────
// ratio_to_coordinate_pairs (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// Pick a ratio `a:b` in lowest terms with `a, b ∈ [1, 4]` and `a != b`
/// (so the swap-distractor is meaningfully different). Plot
/// `(a, b)`, `(2a, 2b)`, `(3a, 3b)` on a Q1 plane. Ask: "What ratio do
/// these ordered pairs show?"
GeneratedQuestion ratioToCoordinatePairs(Random rand) {
  late int a;
  late int b;
  for (var attempt = 0; attempt < 30; attempt++) {
    a = rand.nextInt(4) + 1;
    b = rand.nextInt(4) + 1;
    if (a != b && _gcd(a, b) == 1) break;
  }

  final points = [
    CoordinatePlanePoint(x: a, y: b),
    CoordinatePlanePoint(x: 2 * a, y: 2 * b),
    CoordinatePlanePoint(x: 3 * a, y: 3 * b),
  ];

  final correct = '$a:$b';
  final candidates = <String>[
    '$b:$a', // swapped
    '${a + 1}:$b',
    '$a:${b + 1}',
    '${a + b}:$b',
  ];

  return GeneratedQuestion(
    conceptId: 'ratio_to_coordinate_pairs',
    prompt:
        'These three plotted points all show the same ratio of '
        'x-value to y-value. What ratio is it?',
    diagram: CoordinatePlaneSpec(
      minX: 0,
      maxX: 3 * a + 2,
      minY: 0,
      maxY: 3 * b + 2,
      points: points,
    ),
    correctAnswer: correct,
    distractors: _distinctStrings(correct, candidates),
    explanation: [
      'Read any plotted point: x = $a, y = $b.',
      'So the ratio of x to y is $a:$b.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

int _gcd(int a, int b) => b == 0 ? a : _gcd(b, a % b);

// ─────────────────────────────────────────────────────────────────────────
// dependent_independent_vars (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

class _Scenario {
  const _Scenario({
    required this.dependent,
    required this.independent,
    required this.context,
  });

  /// The variable that's CHANGED BY the other (the response).
  final String dependent;

  /// The variable you CHOOSE / the input.
  final String independent;

  /// One-sentence narrative pasted into the prompt.
  final String context;
}

const _scenarios = <_Scenario>[
  _Scenario(
    dependent: 'cost',
    independent: 'hours worked',
    context:
        'A handyman charges by the hour. Total cost depends on '
        'the hours worked.',
  ),
  _Scenario(
    dependent: 'distance travelled',
    independent: 'time',
    context:
        'A car drives at a steady speed. The distance travelled '
        'depends on the time elapsed.',
  ),
  _Scenario(
    dependent: 'plant height',
    independent: 'days since planting',
    context:
        'A bean plant grows a bit each day. Its height depends '
        'on how many days have passed since planting.',
  ),
  _Scenario(
    dependent: 'water in the tank',
    independent: 'minutes filling',
    context:
        'A tank is being filled at a constant rate. The amount '
        'of water depends on the minutes spent filling.',
  ),
  _Scenario(
    dependent: 'cost',
    independent: 'number of apples',
    context:
        r'Apples cost $1 each. The total cost depends on the '
        'number of apples bought.',
  ),
];

/// "Which is the independent variable in this scenario?" — 50/50
/// between asking for the independent or dependent variable. 4-choice MC:
/// the two named variables + "Both vary together" + "Neither is a variable".
GeneratedQuestion dependentIndependentVars(Random rand) {
  final s = _scenarios[rand.nextInt(_scenarios.length)];
  final askIndependent = rand.nextBool();
  final correct = askIndependent ? s.independent : s.dependent;
  final wrong = askIndependent ? s.dependent : s.independent;

  return GeneratedQuestion(
    conceptId: 'dependent_independent_vars',
    prompt:
        '${s.context} Which is the '
        '${askIndependent ? "independent" : "dependent"} variable?',
    correctAnswer: correct,
    distractors: [
      wrong,
      'Both vary together',
      'Neither is a variable',
    ],
    explanation: [
      if (askIndependent)
        'The independent variable is the INPUT (chosen): ${s.independent}.'
      else
        'The dependent variable RESPONDS to the other: ${s.dependent}.',
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
