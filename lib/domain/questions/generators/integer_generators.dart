import 'dart:math';

import 'package:math_city/domain/questions/generated_question.dart';

/// Signed-integer arithmetic generators.
///
/// Display conventions (consistent with kid-textbook style):
///   * Leading operand: bare sign for negatives ("−5 + 3").
///   * Trailing operand: parens around negatives ("5 + (−3)") so the
///     operator and the sign are visually distinct.
///   * Answer: bare sign for negatives ("−2").

const _minus = '−'; // U+2212 minus sign (matches add_sub_generators)

String _signedNoParens(int n) => n >= 0 ? '$n' : '$_minus${-n}';
String _signed(int n) => n >= 0 ? '$n' : '($_minus${-n})';

/// Returns three string distractors for a signed integer answer.
/// Strategy: sign-flipped misconception + nearby integers, distinct,
/// never equal to the correct answer.
List<String> _signedDistractors(int correct, Random rand) {
  final candidates = <int>{
    -correct,
    correct + 1,
    correct - 1,
    correct + 2,
    correct - 2,
    correct + 5,
    correct - 5,
  }..remove(correct);
  for (var i = 3; candidates.length < 3; i++) {
    candidates.add(correct + i * 3);
  }
  final list = candidates.toList()..shuffle(rand);
  return list.take(3).map(_signedNoParens).toList();
}

// ─────────────────────────────────────────────────────────────────────────
// Generators
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion _binaryOpQuestion({
  required String conceptId,
  required String op, // visible operator: "+", "−", "×", "÷"
  required int a,
  required int b,
  required int correct,
  required Random rand,
}) {
  final line =
      '${_signedNoParens(a)} $op ${_signed(b)} = '
      '${_signedNoParens(correct)}';
  return GeneratedQuestion(
    conceptId: conceptId,
    prompt: '${_signedNoParens(a)} $op ${_signed(b)} = ?',
    correctAnswer: _signedNoParens(correct),
    distractors: _signedDistractors(correct, rand),
    explanation: [line],
  );
}

/// `−20 ≤ a, b ≤ 20`; addition. At least one operand is negative (we
/// already cover purely-positive addition elsewhere).
GeneratedQuestion integersAdd(Random rand) {
  int a;
  int b;
  do {
    a = rand.nextInt(41) - 20; // −20..20
    b = rand.nextInt(41) - 20;
  } while (a >= 0 && b >= 0);
  return _binaryOpQuestion(
    conceptId: 'integers_add',
    op: '+',
    a: a,
    b: b,
    correct: a + b,
    rand: rand,
  );
}

/// `−20 ≤ a, b ≤ 20`; subtraction. At least one operand is negative so
/// each problem genuinely exercises sign rules.
GeneratedQuestion integersSubtract(Random rand) {
  int a;
  int b;
  do {
    a = rand.nextInt(41) - 20;
    b = rand.nextInt(41) - 20;
  } while (a >= 0 && b >= 0);
  return _binaryOpQuestion(
    conceptId: 'integers_subtract',
    op: _minus,
    a: a,
    b: b,
    correct: a - b,
    rand: rand,
  );
}

/// Random pick between × and ÷ on signed integers. Multiplication
/// operands ∈ [−9, 9]\{0, ±1}; division generated as quotient × divisor
/// for exact results.
GeneratedQuestion integersMultiplyDivide(Random rand) {
  final isMult = rand.nextBool();

  int pickFactor() {
    int v;
    do {
      v = rand.nextInt(19) - 9; // −9..9
    } while (v == 0 || v == 1 || v == -1);
    return v;
  }

  if (isMult) {
    final a = pickFactor();
    final b = pickFactor();
    // Require at least one negative — purely positive cases are already
    // covered by mult_facts_within_100.
    final aSigned = (a >= 0 && b >= 0) ? -a : a;
    return _binaryOpQuestion(
      conceptId: 'integers_multiply_divide',
      op: '×',
      a: aSigned,
      b: b,
      correct: aSigned * b,
      rand: rand,
    );
  }
  // Division — generate as divisor × quotient so result is exact.
  final divisor = pickFactor();
  final quotient = pickFactor();
  // Ensure at least one negative.
  final dSigned = (divisor >= 0 && quotient >= 0) ? -divisor : divisor;
  final dividend = dSigned * quotient;
  return _binaryOpQuestion(
    conceptId: 'integers_multiply_divide',
    op: '÷',
    a: dividend,
    b: dSigned,
    correct: quotient,
    rand: rand,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// absolute_value (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "What is |−7|?" → 7. Picks a non-zero integer; positive half the
/// time, negative the other half so the kid sees both cases.
GeneratedQuestion absoluteValue(Random rand) {
  final magnitude = rand.nextInt(19) + 1; // 1..19
  final isNeg = rand.nextBool();
  final value = isNeg ? -magnitude : magnitude;
  final shown = _signedNoParens(value);
  final correct = '$magnitude';

  final distractors = <String>{
    // Misconception: kept the sign.
    if (isNeg) _signedNoParens(value),
    // Misconception: flipped a positive to negative.
    if (!isNeg) _signedNoParens(-value),
    // Off-by-one.
    '${magnitude + 1}',
    '${magnitude > 1 ? magnitude - 1 : magnitude + 2}',
    '${magnitude + 2}',
  }.where((s) => s != correct).take(3).toList();

  return GeneratedQuestion(
    conceptId: 'absolute_value',
    prompt: 'What is |$shown|?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Absolute value = distance from 0 — always ≥ 0.',
      '|$shown| = $magnitude.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// opposites_and_zero (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "What is the opposite of −7?" → 7. Special case: opposite of 0 is 0.
GeneratedQuestion oppositesAndZero(Random rand) {
  // Avoid 0 most of the time — too trivial. Include it ~10% to teach
  // that the opposite of 0 is 0.
  late int value;
  if (rand.nextDouble() < 0.1) {
    value = 0;
  } else {
    final magnitude = rand.nextInt(19) + 1;
    value = rand.nextBool() ? -magnitude : magnitude;
  }
  final shown = _signedNoParens(value);
  final correct = _signedNoParens(-value);

  final distractors = <String>{
    // Misconception: gave the same value back.
    shown,
    // Misconception: absolute value.
    '${value.abs()}',
    // Off-by-one.
    _signedNoParens(-value + 1),
    _signedNoParens(-value - 1),
  }.where((s) => s != correct).take(3).toList();

  return GeneratedQuestion(
    conceptId: 'opposites_and_zero',
    prompt: 'What is the opposite of $shown?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Opposite means same magnitude, flipped sign.',
      'Opposite of $shown is $correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// signed_quantities_context (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// MC over four word scenarios — three with the opposite sign of the
/// asked-for one. Tests CCSS 6.NS.C.5 — understanding negatives as
/// quantities in real-world contexts.
GeneratedQuestion signedQuantitiesContext(Random rand) {
  // Each scenario: (description, sign — +1 or −1).
  const scenarios = <(String, int)>[
    ('A temperature of 12 degrees below zero', -1),
    (r'A bank withdrawal of $40', -1),
    ('Walking down 3 floors', -1),
    (r'Owing a friend $8', -1),
    ('5 feet below sea level', -1),
    ('Losing 6 points in a game', -1),
    ('Gaining 7 points on a quiz', 1),
    (r'A bank deposit of $25', 1),
    ('A temperature of 8 degrees above zero', 1),
    ('Climbing up 4 floors', 1),
    (r'Earning $15 on a chore', 1),
    ('10 feet above ground', 1),
  ];
  final correctSign = rand.nextBool() ? -1 : 1;
  final matching = scenarios.where((s) => s.$2 == correctSign).toList()
    ..shuffle(rand);
  final correctScenario = matching.first;
  final opposite = scenarios.where((s) => s.$2 != correctSign).toList()
    ..shuffle(rand);
  final distractors = opposite.take(3).map((s) => s.$1).toList();
  final word = correctSign == -1 ? 'negative' : 'positive';

  return GeneratedQuestion(
    conceptId: 'signed_quantities_context',
    prompt: 'Which situation can be represented by a $word number?',
    correctAnswer: correctScenario.$1,
    distractors: distractors,
    explanation: [
      'Negative numbers represent quantities below zero, owed, or lost.',
      'Positive numbers represent quantities above zero, earned, or gained.',
      '"${correctScenario.$1}" matches a $word value.',
    ],
    answerFormat: AnswerFormat.string,
  );
}
