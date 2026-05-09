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
