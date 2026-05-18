import 'dart:math';

import 'package:math_city/domain/questions/generated_question.dart';

/// Additional K-G2 addition/subtraction generators that round out the
/// foundational arithmetic catalog. All text-only single-integer or
/// string answers; no diagrams.

List<String> _distinctIntStrings(int correct, List<String> candidates) {
  final out = <String>[];
  final seen = <String>{'$correct'};
  for (final c in candidates) {
    if (out.length >= 3) break;
    if (seen.add(c)) out.add(c);
  }
  for (var i = 1; out.length < 3 && i < 30; i++) {
    for (final delta in <int>[i, -i]) {
      final v = correct + delta;
      if (v < 0) continue;
      final s = '$v';
      if (seen.add(s)) out.add(s);
      if (out.length >= 3) break;
    }
  }
  return out.take(3).toList();
}

// ─────────────────────────────────────────────────────────────────────────
// count_within_1000 (G2)
// ─────────────────────────────────────────────────────────────────────────

/// "What number comes right after `n`?" for `n ∈ [120, 999]`. Same shape
/// as `count_to_120` but extended into the 3-digit range.
GeneratedQuestion countWithin1000(Random rand) {
  final n = rand.nextInt(880) + 120; // 120..999
  final correct = n + 1;
  final candidates = <String>[
    '${n - 1}',
    '$n',
    '${n + 2}',
    '${n + 10}', // crossed a decade
  ];
  return GeneratedQuestion(
    conceptId: 'count_within_1000',
    prompt: 'What number comes right after $n?',
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, candidates),
    explanation: ['Counting up by 1: $n, then $correct.'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// even_odd (G2)
// ─────────────────────────────────────────────────────────────────────────

/// "Is `n` even or odd?" — 4-choice MC over "Even" / "Odd" + two
/// confidence-builder distractors.
GeneratedQuestion evenOdd(Random rand) {
  final n = rand.nextInt(50) + 1; // 1..50
  final isEven = n.isEven;
  return GeneratedQuestion(
    conceptId: 'even_odd',
    prompt: 'Is $n even or odd?',
    correctAnswer: isEven ? 'Even' : 'Odd',
    distractors: [
      if (isEven) 'Odd' else 'Even',
      'Both even and odd',
      'Neither',
    ],
    explanation: [
      if (isEven)
        '$n ends in ${n % 10} → even (ends in 0, 2, 4, 6, 8).'
      else
        '$n ends in ${n % 10} → odd (ends in 1, 3, 5, 7, 9).',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// compare_2digit (G1)
// ─────────────────────────────────────────────────────────────────────────

/// "Which is greater / smaller: `a` or `b`?" — two distinct 2-digit
/// integers.
GeneratedQuestion compare2digit(Random rand) {
  late int a;
  late int b;
  do {
    a = rand.nextInt(90) + 10; // 10..99
    b = rand.nextInt(90) + 10;
  } while (a == b);
  final isGreater = rand.nextBool();
  final correct = isGreater ? max(a, b) : min(a, b);
  final wrong = isGreater ? min(a, b) : max(a, b);
  return GeneratedQuestion(
    conceptId: 'compare_2digit',
    prompt: 'Which number is ${isGreater ? "greater" : "smaller"}: $a or $b?',
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, [
      '$wrong',
      '${a + b}', // sum
      '${(a - b).abs()}', // difference
    ]),
    explanation: [
      'The ${isGreater ? "greater" : "smaller"} of $a and $b is $correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// make_10_pair (K)
// ─────────────────────────────────────────────────────────────────────────

/// "What plus `n` equals 10?" — finds the complement to 10. `n ∈ [1, 9]`.
GeneratedQuestion make10Pair(Random rand) {
  final n = rand.nextInt(9) + 1; // 1..9
  final correct = 10 - n;
  return GeneratedQuestion(
    conceptId: 'make_10_pair',
    prompt: 'What plus $n equals 10?',
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, [
      '$n', // gave the partner back
      '${10 + n}', // added instead of subtracted
      '${correct + 1}',
      '${correct - 1}',
    ]),
    explanation: ['10 − $n = $correct, so $correct + $n = 10.'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// add_3_addends_within_20 (G1)
// ─────────────────────────────────────────────────────────────────────────

/// "5 + 6 + 4 = ?" — three single-digit addends summing to ≤ 20.
GeneratedQuestion add3AddendsWithin20(Random rand) {
  late int a;
  late int b;
  late int c;
  do {
    a = rand.nextInt(9) + 1;
    b = rand.nextInt(9) + 1;
    c = rand.nextInt(9) + 1;
  } while (a + b + c > 20 || a + b + c < 6);
  final correct = a + b + c;
  return GeneratedQuestion(
    conceptId: 'add_3_addends_within_20',
    prompt: '$a + $b + $c = ?',
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, [
      '${a + b}', // dropped the third
      '${b + c}',
      '${a + c}',
      '${correct + 1}',
      '${correct - 1}',
    ]),
    explanation: [
      'Add two first: $a + $b = ${a + b}.',
      'Then add the third: ${a + b} + $c = $correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// equal_sign_meaning (G1)
// ─────────────────────────────────────────────────────────────────────────

/// "Is the equation 8 + 3 = 11 true?" — 50/50 true/false. Half-time
/// the equation balances; half-time the right-hand side is off by 1 or 2.
GeneratedQuestion equalSignMeaning(Random rand) {
  final a = rand.nextInt(8) + 1; // 1..8
  final b = rand.nextInt(8) + 1; // 1..8
  final realSum = a + b;
  final isTrue = rand.nextBool();
  final shownSum =
      isTrue ? realSum : realSum + (rand.nextBool() ? 1 : -1);
  return GeneratedQuestion(
    conceptId: 'equal_sign_meaning',
    prompt: 'Is the equation $a + $b = $shownSum true?',
    correctAnswer: isTrue ? 'True' : 'False',
    distractors: [
      if (isTrue) 'False' else 'True',
      "It's missing a number",
      'Cannot tell',
    ],
    explanation: [
      '$a + $b = $realSum.',
      if (isTrue)
        'The equation shows $shownSum, which matches. True.'
      else
        'The equation shows $shownSum, but $realSum is correct. False.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// commutative_add (G1)
// ─────────────────────────────────────────────────────────────────────────

/// "If a + b = result, then b + a = ?" — tests the commutative property.
/// Answer is just `result`; the swap distractor (`a + b - 1` etc.) is
/// included.
GeneratedQuestion commutativeAdd(Random rand) {
  final a = rand.nextInt(9) + 2; // 2..10
  final b = rand.nextInt(9) + 2; // 2..10
  final sum = a + b;
  return GeneratedQuestion(
    conceptId: 'commutative_add',
    prompt: 'If $a + $b = $sum, then $b + $a = ?',
    correctAnswer: '$sum',
    distractors: _distinctIntStrings(sum, [
      '${a + b - 1}', // off-by-one
      '$a', '$b', // gave one of the addends
      '${(a - b).abs()}', // gave the difference
      '${a * b}',
    ]),
    explanation: [
      'Adding in any order gives the same sum: $b + $a = $a + $b = $sum.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// add_2digit_1digit (G1)
// ─────────────────────────────────────────────────────────────────────────

/// "23 + 5 = ?" — 2-digit + 1-digit addition without explicit carry
/// constraint. Picks values so the sum stays in [10, 99].
GeneratedQuestion add2digit1digit(Random rand) {
  late int a;
  late int b;
  do {
    a = rand.nextInt(90) + 10; // 10..99
    b = rand.nextInt(9) + 1; // 1..9
  } while (a + b > 99);
  final correct = a + b;
  return GeneratedQuestion(
    conceptId: 'add_2digit_1digit',
    prompt: '$a + $b = ?',
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, [
      '${a - b}', // subtracted instead
      '${correct + 1}',
      '${correct - 1}',
      '${a + b * 10}', // misaligned place value
    ]),
    explanation: ['$a + $b = $correct.'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// sub_multiples_of_10 (G1)
// ─────────────────────────────────────────────────────────────────────────

/// "60 − 20 = ?" — subtract two multiples of 10 with non-negative result.
GeneratedQuestion subMultiplesOf10(Random rand) {
  // a > b, both multiples of 10 in [10, 90].
  late int a;
  late int b;
  do {
    a = (rand.nextInt(9) + 1) * 10;
    b = (rand.nextInt(9) + 1) * 10;
  } while (a <= b);
  final correct = a - b;
  return GeneratedQuestion(
    conceptId: 'sub_multiples_of_10',
    prompt: '$a − $b = ?',
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, [
      '${a + b}', // added instead
      '${correct + 10}',
      '${correct - 10}',
      '${a ~/ 10 - b ~/ 10}', // dropped the zero
    ]),
    explanation: [
      '${a ~/ 10} tens − ${b ~/ 10} tens = ${(a - b) ~/ 10} tens = $correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// mental_add_10_or_100 (G2)
// ─────────────────────────────────────────────────────────────────────────

/// "47 + 100 = ?" or "47 − 10 = ?" — add or subtract 10 / 100 mentally.
GeneratedQuestion mentalAdd10Or100(Random rand) {
  final base = rand.nextInt(800) + 100; // 100..899
  final delta = rand.nextBool() ? 10 : 100;
  final isAdd = rand.nextBool();
  final correct = isAdd ? base + delta : base - delta;
  if (correct < 0) return mentalAdd10Or100(rand);
  return GeneratedQuestion(
    conceptId: 'mental_add_10_or_100',
    prompt: '$base ${isAdd ? "+" : "−"} $delta = ?',
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, [
      '${isAdd ? base - delta : base + delta}', // wrong direction
      '${isAdd ? base + 1 : base - 1}', // confused 10/100 with 1
      '${isAdd ? base + 10 : base - 10}'.padLeft(0), // wrong magnitude
      '${correct + 1}',
      '${correct - 1}',
    ]),
    explanation: [
      '$base ${isAdd ? "+ $delta = $correct" : "− $delta = $correct"}.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// add_sub_unknown_position (G1)
// ─────────────────────────────────────────────────────────────────────────

/// "? + 7 = 12" or "5 + ? = 12" or "12 − ? = 5" — solve for the missing
/// number. Picks position uniformly among 4 patterns; result and addends
/// in [1, 20].
GeneratedQuestion addSubUnknownPosition(Random rand) {
  // Pick result r ∈ [3, 20] and an addend in [1, r-2] so both addends ≥ 1.
  final r = rand.nextInt(18) + 3; // 3..20
  final a = rand.nextInt(r - 1) + 1; // 1..r-1
  final b = r - a;

  final pattern = rand.nextInt(4);
  late String prompt;
  late int correct;
  switch (pattern) {
    case 0:
      prompt = '? + $b = $r';
      correct = a;
    case 1:
      prompt = '$a + ? = $r';
      correct = b;
    case 2:
      prompt = '$r − ? = $a';
      correct = b;
    case 3:
      prompt = '? − $b = $a';
      correct = r;
    default:
      throw StateError('unreachable: pattern=$pattern');
  }
  return GeneratedQuestion(
    conceptId: 'add_sub_unknown_position',
    prompt: prompt,
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, [
      '${correct + 1}',
      '${correct - 1}',
      '$r', // gave the result instead
      '${a + b + 1}',
    ]),
    explanation: ['$a + $b = $r — the missing number is $correct.'],
  );
}
