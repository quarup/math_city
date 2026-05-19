import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// Function-family generators — slope, line construction, function
/// recognition (Grade 8).
///
/// All math is integer-only in v1. Slopes are non-zero integers in
/// [-3, 4]. `slope_from_two_points` and `linear_function_construct`
/// render a `CoordinatePlane` diagram showing the two labelled points
/// + the line through them — sampling is rejected when any coord
/// would fall outside the visible plot ([-8, 8] square).

const _minus = '−'; // U+2212

String _signed(int n) => n >= 0 ? '$n' : '$_minus${-n}';

/// "(x, y)" coordinate string with signed components.
String _coord(int x, int y) => '(${_signed(x)}, ${_signed(y)})';

/// String-MC distractor helper that guarantees 3 unique strings ≠ correct.
List<String> _uniqueDistractors(
  String correct,
  List<String> candidates, [
  List<String> fallback = const [],
]) {
  final out = <String>[];
  final seen = <String>{correct};
  for (final c in candidates) {
    if (out.length >= 3) break;
    if (seen.add(c)) out.add(c);
  }
  for (final c in fallback) {
    if (out.length >= 3) break;
    if (seen.add(c)) out.add(c);
  }
  return out.take(3).toList();
}

// ─────────────────────────────────────────────────────────────────────────
// slope_from_two_points (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// "What is the slope of the line through (3, 5) and (7, 13)?" → 2.
/// Integer slopes only in v1 — m ∈ {-3, -2, -1, 1, 2, 3, 4}. Coords
/// re-rolled until both points fit inside [-8, 8] so the diagram
/// renders cleanly on a fixed plot.
GeneratedQuestion slopeFromTwoPoints(Random rand) {
  const slopes = <int>[-3, -2, -1, 1, 2, 3, 4];
  late int m;
  late int run;
  late int x1;
  late int x2;
  late int y1;
  late int y2;
  for (var attempt = 0; attempt < 60; attempt++) {
    m = slopes[rand.nextInt(slopes.length)];
    run = rand.nextInt(4) + 1; // 1..4
    x1 = rand.nextInt(9) - 4; // -4..4
    x2 = x1 + run;
    y1 = rand.nextInt(15) - 5; // -5..9
    y2 = y1 + m * run;
    if (x1 >= -8 && x2 <= 8 && y1 >= -8 && y1 <= 8 && y2 >= -8 && y2 <= 8) {
      break;
    }
  }
  final correct = _signed(m);

  final candidates = <String>[
    // Misconception: wrong sign.
    _signed(-m),
    // Misconception: gave Δy itself (forgot to divide by Δx).
    if (y2 - y1 != m) _signed(y2 - y1),
    // Misconception: gave Δx itself (denominator instead of slope).
    _signed(run),
    // Off-by-one.
    _signed(m + 1),
    _signed(m - 1),
  ];

  return GeneratedQuestion(
    conceptId: 'slope_from_two_points',
    prompt:
        'What is the slope of the line through '
        '${_coord(x1, y1)} and ${_coord(x2, y2)}?',
    diagram: CoordinatePlaneSpec(
      minX: -8,
      maxX: 8,
      minY: -8,
      maxY: 8,
      points: [
        CoordinatePlanePoint(x: x1, y: y1, label: 'A'),
        CoordinatePlanePoint(x: x2, y: y2, label: 'B'),
      ],
      lines: [
        CoordinatePlaneLine(x1: x1, y1: y1, x2: x2, y2: y2),
      ],
    ),
    correctAnswer: correct,
    distractors: _uniqueDistractors(correct, candidates),
    explanation: [
      'Slope = (y₂ − y₁) ÷ (x₂ − x₁).',
      'Δy = ${_signed(y2)} − ${_signed(y1)} = ${_signed(y2 - y1)}.',
      'Δx = ${_signed(x2)} − ${_signed(x1)} = ${_signed(run)}.',
      'Slope = ${_signed(y2 - y1)} ÷ ${_signed(run)} = ${_signed(m)}.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// linear_function_construct (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// "Find the equation of the line through (1, 5) and (3, 11)" →
/// "y = 3x + 2". Output is a slope-intercept string. m ∈ {-3..-1, 1..4}
/// integer; b sampled so both points fit inside [-8, 8] for the diagram.
GeneratedQuestion linearFunctionConstruct(Random rand) {
  const slopes = <int>[-3, -2, -1, 1, 2, 3, 4];
  late int m;
  late int b;
  late int x1;
  late int x2;
  late int run;
  late int y1;
  late int y2;
  for (var attempt = 0; attempt < 60; attempt++) {
    m = slopes[rand.nextInt(slopes.length)];
    b = rand.nextInt(20) - 7; // -7..12
    x1 = rand.nextInt(7) - 3; // -3..3
    run = rand.nextInt(4) + 1; // 1..4
    x2 = x1 + run;
    y1 = m * x1 + b;
    y2 = m * x2 + b;
    if (x1 >= -8 && x2 <= 8 && y1 >= -8 && y1 <= 8 && y2 >= -8 && y2 <= 8) {
      break;
    }
  }

  String eqn(int mm, int bb) {
    final mPart = mm == 1
        ? 'x'
        : mm == -1
        ? '${_minus}x'
        : '${_signed(mm)}x';
    if (bb == 0) return 'y = $mPart';
    if (bb > 0) return 'y = $mPart + $bb';
    return 'y = $mPart $_minus ${-bb}';
  }

  final correct = eqn(m, b);
  final candidates = <String>[
    // Misconception: wrong-sign slope.
    eqn(-m, b),
    // Misconception: used y1 as intercept (forgot to subtract m·x1).
    if (y1 != b) eqn(m, y1),
    // Misconception: dropped the constant.
    if (b != 0) eqn(m, 0),
    // Misconception: swapped m and b (only when distinct & nonzero).
    if (m != b && b != 0) eqn(b, m),
  ];
  // Fallback distractors guaranteed distinct from correct: tweak intercept.
  final fallback = <String>[
    eqn(m, b + 1),
    eqn(m, b + 2),
    eqn(m, b - 1),
    eqn(m, b - 2),
  ];

  return GeneratedQuestion(
    conceptId: 'linear_function_construct',
    prompt:
        'Find the equation of the line through '
        '${_coord(x1, y1)} and ${_coord(x2, y2)}.',
    diagram: CoordinatePlaneSpec(
      minX: -8,
      maxX: 8,
      minY: -8,
      maxY: 8,
      points: [
        CoordinatePlanePoint(x: x1, y: y1, label: 'A'),
        CoordinatePlanePoint(x: x2, y: y2, label: 'B'),
      ],
      lines: [
        CoordinatePlaneLine(x1: x1, y1: y1, x2: x2, y2: y2),
      ],
    ),
    correctAnswer: correct,
    distractors: _uniqueDistractors(correct, candidates, fallback),
    explanation: [
      'Slope: m = Δy ÷ Δx = ${_signed(y2 - y1)} ÷ ${_signed(run)}.',
      'So m = ${_signed(m)}.',
      'Intercept: b = y₁ − m·x₁ = ${_signed(y1 - m * x1)}.',
      'Equation: $correct.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// function_definition_check (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// "Is this a function? {(1, 2), (3, 4), (5, 6)}" → "Yes".
/// "Is this a function? {(1, 2), (3, 4), (1, 5)}" → "No".
/// Half the questions are functions (distinct x's), half repeat an x
/// with a different y.
GeneratedQuestion functionDefinitionCheck(Random rand) {
  final isFunction = rand.nextBool();
  final n = rand.nextBool() ? 3 : 4;
  // Pool of distinct x candidates.
  final xs = (List<int>.generate(11, (i) => i - 2)..shuffle(rand)).take(n);
  final pairs = <List<int>>[];
  for (final x in xs) {
    final y = rand.nextInt(11); // 0..10
    pairs.add([x, y]);
  }

  if (!isFunction) {
    // Replace one x with a previously-used x (different index), assign a
    // different y so the relation is not a function.
    final dupTargetIdx = rand.nextInt(n - 1); // 0..n-2
    final dupSourceIdx = n - 1; // overwrite the last entry
    final repeatedX = pairs[dupTargetIdx][0];
    int newY;
    do {
      newY = rand.nextInt(11);
    } while (newY == pairs[dupTargetIdx][1]);
    pairs[dupSourceIdx] = [repeatedX, newY];
    pairs.shuffle(rand);
  }

  final setText = '{${pairs.map((p) => _coord(p[0], p[1])).join(', ')}}';
  final correct = isFunction ? 'Yes' : 'No';
  final distractors = <String>[
    if (isFunction) 'No' else 'Yes',
    "Can't tell",
    'Sometimes',
  ];

  return GeneratedQuestion(
    conceptId: 'function_definition_check',
    prompt: 'Is this a function? $setText',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'A function maps each input (x) to exactly one output (y).',
      if (isFunction)
        'Every x in the set appears once — this is a function.'
      else
        'The same x appears with two different y values — not a function.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// compare_functions_representations (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// "Function f: y = 3x + 2. Function g: passes through (1, 7) and (3, 17).
/// Which has the greater rate of change?" → "Function g".
///
/// Both f and g are linear with distinct positive integer slopes; their
/// representations are randomly chosen distinct entries from {equation,
/// two points, table}. Restricting slopes to positives keeps "greater
/// rate of change" unambiguous for grade 8.
GeneratedQuestion compareFunctionsRepresentations(Random rand) {
  int mF;
  int mG;
  do {
    mF = rand.nextInt(5) + 2; // 2..6
    mG = rand.nextInt(5) + 2;
  } while (mF == mG);
  final bF = rand.nextInt(9) + 1; // 1..9
  final bG = rand.nextInt(9) + 1;

  const reps = <String>['equation', 'two_points', 'table'];
  // Pick two distinct rep types — one each for f and g.
  final order = List<int>.generate(reps.length, (i) => i)..shuffle(rand);
  final repF = reps[order[0]];
  final repG = reps[order[1]];

  final fDesc = _describeLinearFunction(mF, bF, repF);
  final gDesc = _describeLinearFunction(mG, bG, repG);

  final greater = mF > mG ? 'f' : 'g';
  final correct = 'Function $greater';
  final other = greater == 'f' ? 'g' : 'f';

  final distractors = <String>[
    'Function $other',
    'They have the same rate of change',
    "It can't be determined",
  ];

  return GeneratedQuestion(
    conceptId: 'compare_functions_representations',
    prompt:
        'Function f: $fDesc. Function g: $gDesc. '
        'Which has the greater rate of change?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Find the slope of each function.',
      'Slope of f: $mF. Slope of g: $mG.',
      'Since $mF ${mF > mG ? '>' : '<'} $mG, Function $greater is greater.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

String _describeLinearFunction(int m, int b, String rep) {
  switch (rep) {
    case 'equation':
      return 'y = ${m}x + $b';
    case 'two_points':
      // x = 1 and x = 3 chosen for legibility; with positive integer m and
      // b the resulting y values are also positive integers.
      return 'passes through (1, ${m + b}) and (3, ${3 * m + b})';
    case 'table':
      return 'x→y values {(0, $b), (1, ${m + b}), (2, ${2 * m + b})}';
  }
  throw ArgumentError('Unknown representation: $rep');
}
