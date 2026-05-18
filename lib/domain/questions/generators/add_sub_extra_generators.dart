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
