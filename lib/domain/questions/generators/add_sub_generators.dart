import 'dart:math';

import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/generator_registry.dart';

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

// ─────────────────────────────────────────────────────────────────────────
// equal_sign_meaning (Grade 1)
// ─────────────────────────────────────────────────────────────────────────

/// "What number makes this equation true? 4 + 3 = ? + 2" → 5. Tests the
/// "equal sign means same value" understanding from CCSS 1.OA.D.7 by asking
/// for the missing operand on the other side. Three shapes, all using
/// add_within_10 operands so the kid stays in their comfort zone.
GeneratedQuestion equalSignMeaning(Random rand) {
  // Pick a, b ∈ [1, 9] with a + b ≤ 10.
  final a = rand.nextInt(9) + 1; // 1..9
  final b = rand.nextInt(10 - a) + 1; // 1..10-a so a + b ≤ 10
  final total = a + b;
  // Right-hand side: a "?" plus another non-zero addend that's ≤ total.
  // We need the other addend < total so the unknown is ≥ 1.
  final c = rand.nextInt(total - 1) + 1; // 1..total-1
  final correct = total - c;
  // Two shapes: blank on the right side either as first or second operand.
  final shape = rand.nextInt(2);
  final prompt = shape == 0
      ? 'What goes in the box? $a + $b = ? + $c'
      : 'What goes in the box? $a + $b = $c + ?';

  return GeneratedQuestion(
    conceptId: 'equal_sign_meaning',
    prompt: prompt,
    // Common misconception: the kid puts the total on the right (treats
    // = as "the answer goes here"). Surface it as a distractor.
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      misconception: total,
    ),
    explanation: [
      '$a + $b = $total, so both sides must equal $total.',
      '$correct + $c = $total (or $c + $correct = $total).',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// commutative_add (Grade 1)
// ─────────────────────────────────────────────────────────────────────────

/// "If 8 + 5 = 13, what is 5 + 8?" → 13. Tests CCSS 1.OA.B.3 — the
/// commutative property of addition. Sums stay within 20 so we're firmly
/// in the kid's `add_within_20` band.
GeneratedQuestion commutativeAdd(Random rand) {
  // a, b ∈ [1, 9] with a ≠ b so the swap is visually distinct.
  int a;
  int b;
  do {
    a = rand.nextInt(9) + 1; // 1..9
    b = rand.nextInt(9) + 1;
  } while (a == b);
  final correct = a + b;
  return GeneratedQuestion(
    conceptId: 'commutative_add',
    prompt: 'If $a + $b = $correct, what is $b + $a?',
    correctAnswer: '$correct',
    distractors: integerDistractors(correct, rand),
    explanation: [
      'Adding in a different order gives the same sum.',
      '$b + $a = $a + $b = $correct.',
    ],
  );
}
