import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// K-G2 place-value generators using the new BaseTenBlocks widget:
/// teen_numbers_as_ten_plus.

// ─────────────────────────────────────────────────────────────────────────
// teen_numbers_as_ten_plus (K)
// ─────────────────────────────────────────────────────────────────────────

/// "This is 1 ten and some ones. How many ones are there?" The kid
/// is shown 1 tens-rod and `ones` unit cubes, and answers `ones`.
/// CCSS K.NBT.A.1 — compose 11–19 as ten + extras.
GeneratedQuestion teenNumbersAsTenPlus(Random rand) {
  // Teen numbers strictly: 11..19 → tens=1, ones=1..9.
  final ones = rand.nextInt(9) + 1;
  final total = 10 + ones;
  return GeneratedQuestion(
    conceptId: 'teen_numbers_as_ten_plus',
    prompt:
        'This picture shows $total as 1 ten and some ones. How many ones '
        'are there?',
    diagram: BaseTenBlocksSpec(tens: 1, ones: ones),
    correctAnswer: '$ones',
    // Common kid mistake: count the rod as one of the ones (ones + 1)
    // or report the whole number (total = 10 + ones).
    distractors: integerDistractorsWith(
      ones,
      rand,
      misconception: total,
    ),
    explanation: [
      'The rod is the ten; the $ones little cubes are the ones.',
    ],
  );
}
