import 'dart:math';

import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/word_problems/word_problem_framework.dart';

/// 1-step addition word problem with sum ≤ 100.
///
/// Constraints (keep all quantities plural):
///   a ∈ [2, 98], b ∈ [2, 100 - a], so a + b ∈ [4, 100].
///
/// Misconception distractor: `a - b` (mistaking the operation for
/// subtraction). Dropped when negative by `integerDistractorsWith`.
GeneratedQuestion addWordProblemsWithin100(Random rand) {
  final name = pickRandom(wordProblemNames, rand);
  final items = pickRandom(wordProblemItems, rand);
  final context = pickRandom(additionContextsV1, rand);

  final a = 2 + rand.nextInt(97); // 2..98
  final b = 2 + rand.nextInt(99 - a); // 2..(100 - a)
  final correct = a + b;

  final prompt = composeAdditionWordProblem(
    name: name,
    items: items,
    a: a,
    b: b,
    context: context,
  );

  return GeneratedQuestion(
    conceptId: 'add_word_problems_within_100',
    prompt: prompt,
    correctAnswer: correct.toString(),
    distractors: integerDistractorsWith(correct, rand, misconception: a - b),
    explanation: [
      'Start with $a $items.',
      'Add $b more: $a + $b = $correct.',
      '$name has $correct $items.',
    ],
  );
}
