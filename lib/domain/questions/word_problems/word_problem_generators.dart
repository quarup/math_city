import 'dart:math';

import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/word_problems/word_problem_framework.dart';

/// 1-step + or − word problem with operands ≥ 2 and result ≥ 2 (so item
/// nouns stay plural).
///
/// Constraints:
///   * Addition: a ∈ [2, 98], b ∈ [2, 100 − a], so a + b ∈ [4, 100].
///   * Subtraction: a ∈ [4, 100], b ∈ [2, a − 2], so a − b ∈ [2, 98].
///
/// Op is chosen by the random `WordProblemContext`, so each invocation
/// surfaces both shapes proportionally to the contexts in `addSubContextsV1`.
///
/// The concept ID is `add_word_problems_within_100` for legacy reasons —
/// the curriculum.md row covers `+/− word problems (100)`. The Dart
/// function is named for what it does.
///
/// Misconception distractor: the opposite operation (added when sub, or
/// subtracted when add). Dropped automatically if it's negative.
GeneratedQuestion addSubWordProblemsWithin100(Random rand) {
  final name = pickRandom(wordProblemNames, rand);
  final context = pickRandom(addSubContextsV1, rand);
  final items = pickWordProblemItem(context, rand);

  final int a;
  final int b;
  final int correct;
  final int misconception;
  final List<String> explanation;

  if (context.op == WordProblemOp.add) {
    a = 2 + rand.nextInt(97); // 2..98
    b = 2 + rand.nextInt(99 - a); // 2..(100 − a)
    correct = a + b;
    misconception = a - b; // operation confusion
    explanation = [
      'Start with $a $items.',
      'Add $b more: $a + $b = $correct.',
      '$name has $correct $items.',
    ];
  } else {
    // Subtraction: ensure result ≥ 2 (plural items) and b ≥ 2.
    a = 4 + rand.nextInt(97); // 4..100
    b = 2 + rand.nextInt(a - 3); // 2..(a − 2)
    correct = a - b;
    misconception = a + b; // operation confusion
    explanation = [
      'Start with $a $items.',
      'Take away $b: $a − $b = $correct.',
      '$name has $correct $items left.',
    ];
  }

  final prompt = composeWordProblem(
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
    distractors: integerDistractorsWith(
      correct,
      rand,
      misconception: misconception,
    ),
    explanation: explanation,
  );
}

/// Multiplicative-comparison word problem ("X has K times as many as Y").
/// Algorithmically generated despite curriculum.md tagging this as
/// `dataset` — the comparison framing is templatable and stays within the
/// word-problem framework's pools.
///
/// Constraints: k ∈ [2, 9], n ∈ [2, 11], so the product k·n ≤ 99 (within
/// 100). Items use the full word-problem pool (not restricted to edibles
/// — the verbs don't require edibility).
///
/// Misconception distractor: added instead of multiplied (k + n).
GeneratedQuestion multCompareWord(Random rand) {
  // Pick two distinct names — leader (has more) and follower (has less).
  final name1 = pickRandom(wordProblemNames, rand);
  String name2;
  do {
    name2 = pickRandom(wordProblemNames, rand);
  } while (name2 == name1);

  final items = pickRandom(wordProblemItems, rand);
  final k = rand.nextInt(8) + 2; // 2..9
  final n = rand.nextInt(10) + 2; // 2..11
  final correct = k * n;
  final prompt = '$name1 has $k times as many $items as $name2. '
      '$name2 has $n $items. How many $items does $name1 have?';

  return GeneratedQuestion(
    conceptId: 'mult_compare_word',
    prompt: prompt,
    correctAnswer: correct.toString(),
    distractors: integerDistractorsWith(
      correct,
      rand,
      misconception: k + n, // added instead of multiplied
    ),
    explanation: [
      '$name2 has $n $items.',
      '$name1 has $k times as many, so multiply.',
      '$k × $n = $correct.',
      '$name1 has $correct $items.',
    ],
  );
}
