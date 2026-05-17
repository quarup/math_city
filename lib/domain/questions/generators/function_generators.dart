import 'dart:math';

import 'package:math_city/domain/questions/generated_question.dart';

/// Function-family generators — slope, line construction, function
/// recognition (Grade 8).
///
/// All math is integer-only in v1. Slopes are non-zero integers in
/// [-3, 4]; the math works text-only ("through (3, 5) and (7, 13)") so
/// no `CoordinatePlane` widget is required. The visual widget can be
/// wired in later for a richer UX.

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
/// chosen so both x's and both y's are small signed integers.
GeneratedQuestion slopeFromTwoPoints(Random rand) {
  // Pick m from a non-zero integer set; bias toward small absolute values.
  const slopes = <int>[-3, -2, -1, 1, 2, 3, 4];
  final m = slopes[rand.nextInt(slopes.length)];
  // run = x2 - x1, positive so the prompt reads "(x1, y1) and (x2, y2)"
  // with x2 > x1.
  final run = rand.nextInt(4) + 1; // 1..4
  final x1 = rand.nextInt(9) - 4; // -4..4
  final x2 = x1 + run;
  final y1 = rand.nextInt(15) - 5; // -5..9
  final y2 = y1 + m * run;
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
/// integer; b ∈ [-9, 12] integer.
GeneratedQuestion linearFunctionConstruct(Random rand) {
  const slopes = <int>[-3, -2, -1, 1, 2, 3, 4];
  final m = slopes[rand.nextInt(slopes.length)];
  final b = rand.nextInt(20) - 7; // -7..12
  // Pick two distinct x's and derive y = m·x + b.
  final x1 = rand.nextInt(7) - 3; // -3..3
  final run = rand.nextInt(4) + 1; // 1..4
  final x2 = x1 + run;
  final y1 = m * x1 + b;
  final y2 = m * x2 + b;

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
