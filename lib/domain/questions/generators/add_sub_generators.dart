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
// missing_addend_within_20 (Grade 1)
// ─────────────────────────────────────────────────────────────────────────

/// "5 + ? = 13" → 8. Two prompt shapes — blank in either addend position.
/// Operands chosen so the answer ∈ [1, 9] and the sum ∈ [2, 20].
GeneratedQuestion missingAddendWithin20(Random rand) {
  final sum = rand.nextInt(19) + 2; // 2..20
  final known = rand.nextInt(sum - 1) + 1; // 1..sum-1
  final answer = sum - known;
  final shape = rand.nextInt(2);
  final prompt = shape == 0
      ? 'What goes in the box? $known + ? = $sum'
      : 'What goes in the box? ? + $known = $sum';
  return GeneratedQuestion(
    conceptId: 'missing_addend_within_20',
    prompt: prompt,
    correctAnswer: '$answer',
    // Misconception: the kid just gave the total.
    distractors: integerDistractorsWith(answer, rand, misconception: sum),
    explanation: [
      '$known + $answer = $sum.',
      'So the missing addend is $answer.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// add_sub_unknown_position (Grade 1)
// ─────────────────────────────────────────────────────────────────────────

/// "Find the missing number." Six prompt shapes covering both addition
/// and subtraction with the unknown in each position. All operands and
/// results stay within `add_within_20` / `sub_within_20`. Tests CCSS
/// 1.OA.D.8 (Determine the unknown whole number in an addition or
/// subtraction equation).
GeneratedQuestion addSubUnknownPosition(Random rand) {
  // Pick a result first, then derive consistent operands.
  final result = rand.nextInt(19) + 1; // 1..19
  final shape = rand.nextInt(6);
  late String prompt;
  late int answer;
  late int misconception; // common "got the wrong number from the equation"

  switch (shape) {
    case 0:
      // ? + b = c → ? = c − b
      final b = rand.nextInt(result) + 1; // 1..result
      answer = result - b;
      misconception = result; // gave the total
      prompt = 'Find the missing number: ? + $b = $result';
    case 1:
      // a + ? = c → ? = c − a
      final a = rand.nextInt(result) + 1;
      answer = result - a;
      misconception = result;
      prompt = 'Find the missing number: $a + ? = $result';
    case 2:
      // a + b = ? → ? = a + b
      final a = rand.nextInt(result) + 1;
      final b = result - a;
      answer = result;
      misconception = (a - b).abs(); // did subtraction
      prompt = 'Find the missing number: $a + $b = ?';
    case 3:
      // ? − b = c → ? = b + c; pick b so total ≤ 20
      final maxB = 20 - result;
      if (maxB < 1) return addSubUnknownPosition(rand); // retry
      final b = rand.nextInt(maxB) + 1;
      answer = result + b;
      misconception = result; // gave the diff
      prompt = 'Find the missing number: ? $_minus $b = $result';
    case 4:
      // a − ? = c → ? = a − c; pick a > result, a ≤ 20
      if (result >= 20) return addSubUnknownPosition(rand);
      final a = result + rand.nextInt(20 - result) + 1; // > result, ≤ 20
      answer = a - result;
      misconception = a; // gave the minuend
      prompt = 'Find the missing number: $a $_minus ? = $result';
    default:
      // a − b = ? → ? = a − b; pick a, b with a ≥ b
      if (result >= 20) return addSubUnknownPosition(rand);
      final a = result + rand.nextInt(20 - result) + 1; // a > result
      final b = a - result;
      answer = result;
      misconception = a + b; // added instead
      prompt = 'Find the missing number: $a $_minus $b = ?';
  }

  return GeneratedQuestion(
    conceptId: 'add_sub_unknown_position',
    prompt: prompt,
    correctAnswer: '$answer',
    distractors: integerDistractorsWith(
      answer,
      rand,
      misconception: misconception,
    ),
    explanation: ['Find the missing number that makes the equation true.'],
  );
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
// add_3_addends_within_20 (Grade 1)
// ─────────────────────────────────────────────────────────────────────────

/// "$a + $b + $c = ?". Three single-digit addends with sum ≤ 20.
GeneratedQuestion add3AddendsWithin20(Random rand) {
  // Pick a, b, c ∈ [0, 9] with sum ≤ 20.
  int a;
  int b;
  int c;
  do {
    a = rand.nextInt(10); // 0..9
    b = rand.nextInt(10);
    c = rand.nextInt(10);
  } while (a + b + c > 20);
  final correct = a + b + c;
  return GeneratedQuestion(
    conceptId: 'add_3_addends_within_20',
    prompt: '$a + $b + $c = ?',
    correctAnswer: '$correct',
    distractors: integerDistractors(correct, rand),
    explanation: ['$a + $b + $c = $correct'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// associative_add (Grade 1)
// ─────────────────────────────────────────────────────────────────────────

/// "If (3 + 4) + 5 = 12, what is 3 + (4 + 5)?" → 12. Tests CCSS 1.OA.B.3 —
/// re-grouping addends doesn't change the sum. Addends chosen so the sum
/// stays within `add_3_addends_within_20` and the inner re-grouping is
/// visibly distinct (b + c ≠ a + b).
GeneratedQuestion associativeAdd(Random rand) {
  int a;
  int b;
  int c;
  do {
    a = rand.nextInt(8) + 1; // 1..8
    b = rand.nextInt(8) + 1;
    c = rand.nextInt(8) + 1;
  } while (a + b + c > 20 || a == c);
  final correct = a + b + c;
  return GeneratedQuestion(
    conceptId: 'associative_add',
    prompt: 'If ($a + $b) + $c = $correct, what is $a + ($b + $c)?',
    correctAnswer: '$correct',
    distractors: integerDistractors(correct, rand),
    explanation: [
      'Grouping addends differently gives the same sum.',
      '$a + ($b + $c) = ($a + $b) + $c = $correct.',
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
