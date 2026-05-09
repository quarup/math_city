import 'dart:math';

import 'package:math_dash/domain/questions/distractors.dart';
import 'package:math_dash/domain/questions/generated_question.dart';
import 'package:math_dash/domain/questions/generator_registry.dart';

const _minus = '−'; // U+2212 minus sign

String _addConceptIdForN(int n) => switch (n) {
  5 => 'add_within_5',
  10 => 'add_within_10',
  20 => 'add_within_20',
  100 => 'add_within_100',
  1000 => 'add_within_1000',
  _ => throw ArgumentError('Unsupported n: $n'),
};

String _subConceptIdForN(int n) => switch (n) {
  5 => 'sub_within_5',
  10 => 'sub_within_10',
  20 => 'sub_within_20',
  100 => 'sub_within_100',
  1000 => 'sub_within_1000',
  _ => throw ArgumentError('Unsupported n: $n'),
};

/// "Add within N": a, b ∈ [0, N], sum ≤ N.
QuestionGenerator addWithinN(int n) => (rand) {
  final a = rand.nextInt(n + 1); // 0..N
  final b = rand.nextInt(n - a + 1); // 0..N-a so sum ≤ N
  final correct = a + b;
  return GeneratedQuestion(
    conceptId: _addConceptIdForN(n),
    prompt: '$a + $b = ?',
    correctAnswer: correct.toString(),
    distractors: integerDistractors(correct, rand),
    explanation: ['$a + $b = $correct'],
  );
};

/// "Subtract within N": minuend ≤ N, subtrahend ≤ minuend (no negatives).
QuestionGenerator subWithinN(int n) => (rand) {
  final a = rand.nextInt(n + 1); // 0..N
  final b = rand.nextInt(a + 1); // 0..a
  final correct = a - b;
  return GeneratedQuestion(
    conceptId: _subConceptIdForN(n),
    prompt: '$a $_minus $b = ?',
    correctAnswer: correct.toString(),
    distractors: integerDistractors(correct, rand),
    explanation: ['$a $_minus $b = $correct'],
  );
};

/// 2-digit + 2-digit, *forced regrouping* (ones digits sum ≥ 10).
GeneratedQuestion addWithCarry(Random rand) {
  final aOnes = rand.nextInt(9) + 1; // 1..9
  // bOnes ∈ [10 - aOnes, 9] so aOnes + bOnes ∈ [10, 18].
  final bOnes = (10 - aOnes) + rand.nextInt(aOnes);
  final aTens = rand.nextInt(8) + 1; // 1..8 (leave room for carry)
  final bTens = rand.nextInt(8) + 1; // 1..8
  final a = aTens * 10 + aOnes;
  final b = bTens * 10 + bOnes;
  final correct = a + b;
  return GeneratedQuestion(
    conceptId: 'add_2digit_carry',
    prompt: '$a + $b = ?',
    correctAnswer: correct.toString(),
    distractors: integerDistractors(correct, rand),
    explanation: [
      // ignore: no_adjacent_strings_in_list — single line wrapped for length
      'Ones: $aOnes + $bOnes = ${aOnes + bOnes} '
          '(write ${(aOnes + bOnes) % 10}, carry 1)',
      'Tens: $aTens + $bTens + 1 = ${aTens + bTens + 1}',
      'Total: $correct',
    ],
  );
}

/// 2-digit − 2-digit, *forced borrow* (minuend ones < subtrahend ones).
GeneratedQuestion subWithBorrow(Random rand) {
  final bOnes = rand.nextInt(8) + 1; // 1..8
  final aOnes = rand.nextInt(bOnes); // 0..bOnes-1 forces borrow
  final bTens = rand.nextInt(8) + 1; // 1..8
  final aTens = bTens + 1 + rand.nextInt(9 - bTens); // > bTens so a > b
  final a = aTens * 10 + aOnes;
  final b = bTens * 10 + bOnes;
  final correct = a - b;
  return GeneratedQuestion(
    conceptId: 'sub_2digit_borrow',
    prompt: '$a $_minus $b = ?',
    correctAnswer: correct.toString(),
    distractors: integerDistractors(correct, rand),
    explanation: [
      'Borrow 1 from the tens of $a (so ones become ${aOnes + 10}).',
      'Ones: ${aOnes + 10} $_minus $bOnes = ${aOnes + 10 - bOnes}',
      'Tens: ${aTens - 1} $_minus $bTens = ${aTens - 1 - bTens}',
      'Total: $correct',
    ],
  );
}

/// Multi-digit (3-5 digit) addition.
GeneratedQuestion addMultidigit(Random rand) {
  final digits = rand.nextInt(3) + 3; // 3..5 digits
  final lo = _powerOf10(digits - 1);
  final hi = _powerOf10(digits) - 1;
  final a = lo + rand.nextInt(hi - lo + 1);
  final b = lo + rand.nextInt(hi - lo + 1);
  final correct = a + b;
  return GeneratedQuestion(
    conceptId: 'add_multidigit_standard_alg',
    prompt: '$a + $b = ?',
    correctAnswer: correct.toString(),
    distractors: integerDistractors(correct, rand),
    explanation: ['$a + $b = $correct'],
  );
}

/// Multi-digit (3-5 digit) subtraction, no negatives.
GeneratedQuestion subMultidigit(Random rand) {
  final digits = rand.nextInt(3) + 3; // 3..5
  final lo = _powerOf10(digits - 1);
  final hi = _powerOf10(digits) - 1;
  final a = lo + rand.nextInt(hi - lo + 1);
  final b = lo + rand.nextInt(a - lo + 1); // b ≤ a
  final correct = a - b;
  return GeneratedQuestion(
    conceptId: 'sub_multidigit_standard_alg',
    prompt: '$a $_minus $b = ?',
    correctAnswer: correct.toString(),
    distractors: integerDistractors(correct, rand),
    explanation: ['$a $_minus $b = $correct'],
  );
}

int _powerOf10(int n) {
  var v = 1;
  for (var i = 0; i < n; i++) {
    v *= 10;
  }
  return v;
}
