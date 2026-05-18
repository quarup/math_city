import 'dart:math';

import 'package:math_city/domain/questions/generated_question.dart';

/// Kindergarten and Grade-1 counting generators (`counting` category).
///
/// All produce single-integer answers, no diagrams. Distractors are
/// nearby numbers picked from a small misconception pool plus the
/// generic ±i fallback.

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
// count_to_10 / count_to_20 / count_to_100_by_1 (K)
// ─────────────────────────────────────────────────────────────────────────

/// "What number comes right after `n`?" with the predecessor chosen so
/// the answer stays inside the relevant range.
GeneratedQuestion _counterUpTo(int max, String conceptId, Random rand) {
  // Predecessor n in [1, max - 1] so the answer n+1 in [2, max].
  final n = rand.nextInt(max - 1) + 1;
  final correct = n + 1;
  final candidates = <String>[
    '${n - 1}', // off-by-one (gave the predecessor)
    '$n', // didn't count at all
    '${n + 2}', // skipped one
  ];
  return GeneratedQuestion(
    conceptId: conceptId,
    prompt: 'What number comes right after $n?',
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, candidates),
    explanation: ['Counting up by 1: $n, then ${n + 1}.'],
  );
}

GeneratedQuestion countTo10(Random rand) =>
    _counterUpTo(10, 'count_to_10', rand);
GeneratedQuestion countTo20(Random rand) =>
    _counterUpTo(20, 'count_to_20', rand);
GeneratedQuestion countTo100By1(Random rand) =>
    _counterUpTo(100, 'count_to_100_by_1', rand);

// ─────────────────────────────────────────────────────────────────────────
// one_more_one_less_within_20 (K)
// ─────────────────────────────────────────────────────────────────────────

/// "What is one more than `n`?" or "What is one less than `n`?" —
/// 50/50; `n` chosen so both options stay in `[0, 20]`.
GeneratedQuestion oneMoreOneLessWithin20(Random rand) {
  // n ∈ [1, 19] so both n-1 and n+1 land in [0, 20].
  final n = rand.nextInt(19) + 1;
  final isMore = rand.nextBool();
  final correct = isMore ? n + 1 : n - 1;
  final candidates = <String>[
    '${isMore ? n - 1 : n + 1}', // wrong direction
    '${correct + 1}',
    '${correct - 1}',
    '$n', // gave n itself
  ];
  return GeneratedQuestion(
    conceptId: 'one_more_one_less_within_20',
    prompt: 'What is one ${isMore ? "more" : "less"} than $n?',
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, candidates),
    explanation: [
      'Count ${isMore ? "up" : "down"} by 1: $n → $correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// compare_numerals_1_10 (K)
// ─────────────────────────────────────────────────────────────────────────

/// "Which number is greater: `a` or `b`?" — answer is the larger of
/// the two distinct integers in `[1, 10]`.
GeneratedQuestion compareNumerals1to10(Random rand) {
  late int a;
  late int b;
  do {
    a = rand.nextInt(10) + 1;
    b = rand.nextInt(10) + 1;
  } while (a == b);
  final isGreater = rand.nextBool();
  final correct = isGreater ? max(a, b) : min(a, b);
  final wrong = isGreater ? min(a, b) : max(a, b);
  final candidates = <String>[
    '$wrong',
    '${correct + 1}',
    '${a + b}', // gave the sum
    '${(a - b).abs()}', // gave the difference
  ];
  return GeneratedQuestion(
    conceptId: 'compare_numerals_1_10',
    prompt: 'Which number is ${isGreater ? "greater" : "smaller"}: $a or $b?',
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, candidates),
    explanation: [
      'The ${isGreater ? "greater" : "smaller"} of $a and $b is $correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// skip_count_2 (G1)
// ─────────────────────────────────────────────────────────────────────────

/// "Skip count by 2s: 4, 6, __, 10" — pick the missing term.
/// Sequence is `[start, start+2, start+4, start+6]` with the 3rd
/// position blanked.
GeneratedQuestion skipCount2(Random rand) {
  // Start ∈ {2, 4, 6, ..., 20}.
  final start = (rand.nextInt(10) + 1) * 2;
  final correct = start + 4;
  final sequence = [start, start + 2, '__', start + 6];
  final candidates = <String>[
    '${start + 2}',
    '${start + 6}',
    '${start + 3}', // counted by 1 instead of 2
    '${start + 5}',
    '$start',
  ];
  return GeneratedQuestion(
    conceptId: 'skip_count_2',
    prompt: 'Skip count by 2s: ${sequence.join(", ")}. '
        'What number goes in the blank?',
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, candidates),
    explanation: ['Each step adds 2: ${start + 2} + 2 = $correct.'],
  );
}
