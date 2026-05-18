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
// count_to_100_by_10 (K)
// ─────────────────────────────────────────────────────────────────────────

/// "What comes next when counting by 10s: 10, 20, 30, __?" — answer
/// is the next multiple of 10 after the last shown. Sequence has 3
/// terms visible, one blank at the end.
GeneratedQuestion countTo100By10(Random rand) {
  // Start ∈ {10, 20, ..., 70} so the answer (start + 30) ∈ [40, 100].
  final start = (rand.nextInt(7) + 1) * 10;
  final correct = start + 30;
  final shown = [start, start + 10, start + 20];
  final candidates = <String>[
    '${start + 20}', // repeated the last term
    '${start + 31}', // off-by-one
    '${start + 29}',
    '${start + 25}',
  ];
  return GeneratedQuestion(
    conceptId: 'count_to_100_by_10',
    prompt: 'Counting by 10s: ${shown.join(", ")}, __. '
        'What comes next?',
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, candidates),
    explanation: ['Each step adds 10: ${shown.last} + 10 = $correct.'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// count_to_120 (G1)
// ─────────────────────────────────────────────────────────────────────────

/// "What number comes right after `n`?" extended into G1 territory by
/// having the predecessor land in `[100, 119]`. Same shape as
/// `count_to_10` but tests the 100–120 range specifically.
GeneratedQuestion countTo120(Random rand) {
  final n = rand.nextInt(20) + 100; // 100..119
  final correct = n + 1;
  final candidates = <String>[
    '${n - 1}',
    '$n',
    '${n + 2}',
    '${n + 10}', // crossed a decade by accident
  ];
  return GeneratedQuestion(
    conceptId: 'count_to_120',
    prompt: 'What number comes right after $n?',
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, candidates),
    explanation: ['Counting up by 1: $n, then $correct.'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// count_forward_from_n (K)
// ─────────────────────────────────────────────────────────────────────────

/// "Start at `n` and count `k` more. What number do you reach?" — same
/// math as add_within_20 but framed as counting up rather than addition.
/// Start ∈ [10, 80], count ∈ [2, 5], answer = start + count ≤ 85.
GeneratedQuestion countForwardFromN(Random rand) {
  final start = rand.nextInt(71) + 10; // 10..80
  final count = rand.nextInt(4) + 2; // 2..5
  final correct = start + count;
  final candidates = <String>[
    '${start + count - 1}', // off-by-one (kid counted "start" as 1)
    '${start + count + 1}',
    '${start - count}', // counted backwards
    '$count', // gave the count instead of the result
    '$start',
  ];
  return GeneratedQuestion(
    conceptId: 'count_forward_from_n',
    prompt: 'Start at $start and count forward $count steps. '
        'What number do you reach?',
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, candidates),
    explanation: ['$start + $count = $correct.'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// ten_more_ten_less (G1)
// ─────────────────────────────────────────────────────────────────────────

/// "What is ten more / ten less than `n`?" with `n ∈ [10, 90]` so both
/// directions stay in [0, 100].
GeneratedQuestion tenMoreTenLess(Random rand) {
  final n = rand.nextInt(81) + 10; // 10..90
  final isMore = rand.nextBool();
  final correct = isMore ? n + 10 : n - 10;
  final candidates = <String>[
    '${isMore ? n - 10 : n + 10}', // wrong direction
    '${isMore ? n + 1 : n - 1}', // off by 1 instead of 10
    '${correct + 1}',
    '${correct - 1}',
    '$n',
  ];
  return GeneratedQuestion(
    conceptId: 'ten_more_ten_less',
    prompt: 'What is ten ${isMore ? "more" : "less"} than $n?',
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, candidates),
    explanation: [
      '$n ${isMore ? "+ 10" : "− 10"} = $correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// skip_count_5 / skip_count_10 / skip_count_100 (G1–G2)
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion _skipCountByStep(
  int step,
  String conceptId,
  Random rand, {
  required int startMin,
  required int startMax,
}) {
  // Start ∈ [startMin, startMax], stepped on `step`.
  final stepCount = (startMax - startMin) ~/ step + 1;
  final start = startMin + rand.nextInt(stepCount) * step;
  final correct = start + 2 * step;
  final shown = [start, start + step, '__', start + 3 * step];
  final candidates = <String>[
    '${start + step}',
    '${start + 3 * step}',
    '${start + step + 1}', // counted by 1 instead
    '${start + 2 * step - 1}',
    '${start + 2 * step + 1}',
    '$start',
  ];
  return GeneratedQuestion(
    conceptId: conceptId,
    prompt: 'Skip count by ${step}s: ${shown.join(", ")}. '
        'What number goes in the blank?',
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, candidates),
    explanation: ['Each step adds $step: ${start + step} + $step = $correct.'],
  );
}

GeneratedQuestion skipCount5(Random rand) => _skipCountByStep(
  5,
  'skip_count_5',
  rand,
  startMin: 5,
  startMax: 50,
);

GeneratedQuestion skipCount10(Random rand) => _skipCountByStep(
  10,
  'skip_count_10',
  rand,
  startMin: 10,
  startMax: 60,
);

GeneratedQuestion skipCount100(Random rand) => _skipCountByStep(
  100,
  'skip_count_100',
  rand,
  startMin: 100,
  startMax: 600,
);

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
