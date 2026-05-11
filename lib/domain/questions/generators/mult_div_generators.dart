import 'dart:math';

import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// Multiplication facts up to 100. Operands ∈ [2, 9] (skip ×0 and ×1).
GeneratedQuestion multFactsWithin100(Random rand) {
  final a = rand.nextInt(8) + 2; // 2..9
  final b = rand.nextInt(8) + 2; // 2..9
  final correct = a * b;
  return GeneratedQuestion(
    conceptId: 'mult_facts_within_100',
    prompt: '$a × $b = ?',
    correctAnswer: correct.toString(),
    distractors: integerDistractors(correct, rand),
    explanation: ['$a × $b = $correct'],
  );
}

/// Division facts up to 100. Generated as quotient × divisor → exact.
GeneratedQuestion divFactsWithin100(Random rand) {
  final divisor = rand.nextInt(8) + 2; // 2..9
  final quotient = rand.nextInt(9) + 1; // 1..9
  final dividend = divisor * quotient;
  return GeneratedQuestion(
    conceptId: 'div_facts_within_100',
    prompt: '$dividend ÷ $divisor = ?',
    correctAnswer: quotient.toString(),
    distractors: integerDistractors(quotient, rand),
    explanation: [
      '$dividend ÷ $divisor = $quotient',
      'Check: $quotient × $divisor = $dividend',
    ],
  );
}

/// Division with a remainder. Divisor ∈ [2,9], quotient ∈ [2,12], remainder
/// ∈ [1, divisor-1]. Answer is rendered as "qRr" — a compact format that
/// surfaces a single 'R' key on the numpad and reads as "q remainder r".
GeneratedQuestion divWithRemainder(Random rand) {
  final divisor = rand.nextInt(8) + 2; // 2..9
  final quotient = rand.nextInt(11) + 2; // 2..12
  final remainder = rand.nextInt(divisor - 1) + 1; // 1..divisor-1
  final dividend = divisor * quotient + remainder;
  final correct = '${quotient}R$remainder';

  // Distractors expose common misconceptions.
  final pool = <String>{
    '${quotient}R0', // forgot the remainder
    '${quotient + 1}R0', // rounded up to the next multiple
    '${quotient - 1}R$remainder', // off-by-one quotient
    '${quotient}R${(remainder % divisor) + 1}', // off-by-one remainder
    '${remainder}R$quotient', // swapped quotient and remainder
  }..remove(correct);

  final list = pool.toList()..shuffle(rand);
  final distractors = list.take(3).toList();

  return GeneratedQuestion(
    conceptId: 'div_with_remainder',
    prompt: '$dividend ÷ $divisor = ?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      '$divisor × $quotient = ${divisor * quotient}',
      '$dividend $_minus ${divisor * quotient} = $remainder',
      'So $dividend ÷ $divisor = $quotient with remainder $remainder.',
    ],
  );
}

/// 4-digit × 1-digit. a ∈ [1000, 9999], b ∈ [2, 9].
GeneratedQuestion mult4digitBy1digit(Random rand) {
  final a = rand.nextInt(9000) + 1000; // 1000..9999
  final b = rand.nextInt(8) + 2; // 2..9
  final correct = a * b;
  return GeneratedQuestion(
    conceptId: 'mult_4digit_by_1digit',
    prompt: '$a × $b = ?',
    correctAnswer: correct.toString(),
    distractors: integerDistractors(correct, rand),
    explanation: ['$a × $b = $correct'],
  );
}

/// 2-digit × 2-digit. a, b ∈ [10, 99]. Reports partial products in the
/// explanation since long-multiplication is the new skill at this stage.
GeneratedQuestion mult2digitBy2digit(Random rand) {
  final a = rand.nextInt(90) + 10; // 10..99
  final b = rand.nextInt(90) + 10; // 10..99
  final bOnes = b % 10;
  final bTens = b ~/ 10;
  final partOnes = a * bOnes;
  final partTens = a * bTens * 10;
  final correct = a * b;
  return GeneratedQuestion(
    conceptId: 'mult_2digit_by_2digit',
    prompt: '$a × $b = ?',
    correctAnswer: correct.toString(),
    distractors: integerDistractors(correct, rand),
    explanation: [
      '$a × $bOnes = $partOnes',
      '$a × ${bTens * 10} = $partTens',
      '$partOnes + $partTens = $correct',
    ],
  );
}

/// Standard multi-digit × (algorithm). Mixes 3-digit × 2-digit with
/// 4-digit × 2-digit and 2-digit × 3-digit so the kid sees variety
/// without ever falling back to the easier mult_2digit_by_2digit case.
GeneratedQuestion multMultidigitStandardAlg(Random rand) {
  // Three shapes (a's digit count, b's digit count): {3×2, 4×2, 2×3}.
  final shape = rand.nextInt(3);
  final (aDigits, bDigits) = switch (shape) {
    0 => (3, 2),
    1 => (4, 2),
    _ => (2, 3),
  };
  final a = _randomNDigit(aDigits, rand);
  final b = _randomNDigit(bDigits, rand);
  final correct = a * b;
  return GeneratedQuestion(
    conceptId: 'mult_multidigit_standard_alg',
    prompt: '$a × $b = ?',
    correctAnswer: correct.toString(),
    distractors: integerDistractors(correct, rand),
    explanation: ['$a × $b = $correct'],
  );
}

/// 4-digit ÷ 1-digit, exact (no remainder). Dividend ∈ [1000, 9999],
/// divisor ∈ [2, 9]. Generated as divisor × quotient = dividend.
GeneratedQuestion div4digitBy1digit(Random rand) {
  final divisor = rand.nextInt(8) + 2; // 2..9
  final qLo = (1000 + divisor - 1) ~/ divisor;
  final qHi = 9999 ~/ divisor;
  final quotient = qLo + rand.nextInt(qHi - qLo + 1);
  final dividend = divisor * quotient;
  return GeneratedQuestion(
    conceptId: 'div_4digit_by_1digit',
    prompt: '$dividend ÷ $divisor = ?',
    correctAnswer: quotient.toString(),
    distractors: integerDistractors(quotient, rand),
    explanation: [
      '$dividend ÷ $divisor = $quotient',
      'Check: $quotient × $divisor = $dividend',
    ],
  );
}

/// 4-digit ÷ 2-digit, exact (no remainder). Dividend ∈ [1000, 9999],
/// divisor ∈ [11, 99], generated as divisor × quotient with the constraint
/// that the dividend stays in the 4-digit band.
GeneratedQuestion div4digitBy2digit(Random rand) {
  // Pick divisor first; pick quotient so dividend lands in [1000, 9999].
  // Divisor ∈ [11, 99] keeps it strictly two-digit (no degenerate ÷ 10).
  final divisor = rand.nextInt(89) + 11; // 11..99
  final qLo = (1000 + divisor - 1) ~/ divisor;
  final qHi = 9999 ~/ divisor;
  final quotient = qLo + rand.nextInt(qHi - qLo + 1);
  final dividend = divisor * quotient;
  return GeneratedQuestion(
    conceptId: 'div_4digit_by_2digit',
    prompt: '$dividend ÷ $divisor = ?',
    correctAnswer: quotient.toString(),
    distractors: integerDistractors(quotient, rand),
    explanation: [
      '$dividend ÷ $divisor = $quotient',
      'Check: $quotient × $divisor = $dividend',
    ],
  );
}

const _minus = '−'; // U+2212 minus sign — matches add_sub_generators.dart.

/// Random integer with exactly [n] digits (so the leading digit is ≥ 1).
int _randomNDigit(int n, Random rand) {
  if (n < 1) throw ArgumentError('n must be ≥ 1');
  final lo = n == 1 ? 0 : _pow10(n - 1);
  final hi = _pow10(n) - 1;
  return lo + rand.nextInt(hi - lo + 1);
}

int _pow10(int n) {
  var v = 1;
  for (var i = 0; i < n; i++) {
    v *= 10;
  }
  return v;
}
