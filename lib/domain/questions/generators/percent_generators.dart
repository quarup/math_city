import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// Percent generators (Grade 6).
///
/// All three answers are bare whole-number strings (no `%` symbol) so
/// the keypad stays digits-only and the answer-checker can use plain
/// exact-string match. Parameters are constrained so every answer lands
/// on an integer — no decimal results.

// ─────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────

/// Returns three distinct whole-number-string distractors that differ
/// from [correct]. Seeds with [candidates], then walks outward by ±i
/// from [correct] to fill the rest.
List<String> _wholeDistractors(
  int correct,
  List<String> candidates,
  Random rand,
) {
  final out = <String>[];
  final seen = <String>{'$correct'};
  for (final c in candidates) {
    if (out.length >= 3) break;
    if (seen.add(c)) out.add(c);
  }
  for (var i = 1; out.length < 3 && i < 30; i++) {
    for (final delta in <int>[i, -i]) {
      final v = correct + delta;
      if (v < 1) continue;
      final s = '$v';
      if (seen.add(s)) out.add(s);
      if (out.length >= 3) break;
    }
  }
  return out.take(3).toList();
}

// ─────────────────────────────────────────────────────────────────────────
// percent_intro (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "What percent is shaded?" — shows a 10×10 grid with N cells shaded,
/// asks for N. Avoids 0, 100, and the trivial 50 so the kid has to count
/// rather than recognise a stock fraction.
GeneratedQuestion percentIntro(Random rand) {
  int n;
  do {
    n = rand.nextInt(99) + 1; // 1..99
  } while (n == 50);
  final correct = '$n';

  // Misconception distractors:
  //   - misread the grid (off-by-one row or column)
  //   - swapped shaded/unshaded (100 − n)
  //   - read it as a fraction-over-10 instead of out-of-100
  final candidates = <String>[
    '${100 - n}',
    '${(n ~/ 10) + 1}',
    '${n ~/ 10}',
  ];

  return GeneratedQuestion(
    conceptId: 'percent_intro',
    prompt: 'What percent is shaded?',
    diagram: PercentGridSpec(shadedCount: n),
    correctAnswer: correct,
    distractors: _wholeDistractors(n, candidates, rand),
    explanation: [
      'The grid has 100 squares.',
      '$n of them are shaded.',
      '"Percent" means "out of 100" — so $n out of 100 is $n%.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// percent_of_quantity (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "What is P% of Q?" — picks P, Q so the answer is a whole number.
///
/// To guarantee an integer result, parameters are drawn from two
/// templates with equal probability:
///   * P ∈ {10, 20, 25, 30, 40, 50, 60, 70, 75, 80, 90} with Q a
///     multiple of (100 ÷ gcd(P, 100)). E.g. P=25 → Q ∈ {4, 8, 12, …}.
///   * P ∈ {1..99} with Q a multiple of 100 (P% of 100k = k·P).
GeneratedQuestion percentOfQuantity(Random rand) {
  final useFriendlyPercent = rand.nextBool();
  final int percent;
  final int quantity;
  if (useFriendlyPercent) {
    const friendly = <int>[10, 20, 25, 30, 40, 50, 60, 70, 75, 80, 90];
    percent = friendly[rand.nextInt(friendly.length)];
    // Quantity must be a multiple of 100 / gcd(percent, 100) for an
    // integer result.
    final step = 100 ~/ _gcd(percent, 100);
    // Pick a multiple in [step, step·12] so the answer stays small-ish.
    final units = rand.nextInt(12) + 1; // 1..12
    quantity = step * units;
  } else {
    percent = rand.nextInt(99) + 1; // 1..99
    // Quantity = 100·k for k ∈ [1, 10]. Answer = percent · k.
    final k = rand.nextInt(10) + 1;
    quantity = 100 * k;
  }
  final answer = (percent * quantity) ~/ 100;
  final correct = '$answer';

  // Misconception distractors:
  //   - dropped the % entirely (used percent as a multiplier).
  //   - applied the percent twice / forgot to divide by 100.
  //   - swapped percent and quantity in the division.
  final candidates = <String>[
    '${percent * quantity}',
    '${quantity ~/ percent.clamp(1, 100)}',
    '${quantity - answer}', // "the rest"
  ];

  return GeneratedQuestion(
    conceptId: 'percent_of_quantity',
    prompt: 'What is $percent% of $quantity?',
    correctAnswer: correct,
    distractors: _wholeDistractors(answer, candidates, rand),
    explanation: [
      '$percent% means $percent/100.',
      '$percent% of $quantity = $percent ÷ 100 × $quantity.',
      '= $correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// find_whole_from_part_percent (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "P% of what number is X?" — inverse of [percentOfQuantity]. Generated
/// by drawing the same friendly parameter sets, computing the part, and
/// then asking for the whole.
GeneratedQuestion findWholeFromPartPercent(Random rand) {
  final useFriendlyPercent = rand.nextBool();
  final int percent;
  final int whole;
  if (useFriendlyPercent) {
    const friendly = <int>[10, 20, 25, 40, 50, 60, 75, 80];
    percent = friendly[rand.nextInt(friendly.length)];
    final step = 100 ~/ _gcd(percent, 100);
    final units = rand.nextInt(10) + 1;
    whole = step * units;
  } else {
    percent = rand.nextInt(99) + 1;
    final k = rand.nextInt(8) + 1;
    whole = 100 * k;
  }
  final part = (percent * whole) ~/ 100;
  final correct = '$whole';

  // Misconception distractors:
  //   - took the part as the whole.
  //   - inverted percent (e.g. "100 / percent · part").
  //   - just multiplied percent × part, forgetting the percent meaning.
  final candidates = <String>[
    '$part',
    '${part * percent}',
    '${part + percent}',
  ];

  return GeneratedQuestion(
    conceptId: 'find_whole_from_part_percent',
    prompt: '$part is $percent% of what number?',
    correctAnswer: correct,
    distractors: _wholeDistractors(whole, candidates, rand),
    explanation: [
      '"$part is $percent% of W" means $part = $percent/100 × W.',
      'So W = $part × 100 ÷ $percent.',
      '= $correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────

int _gcd(int a, int b) {
  var x = a.abs();
  var y = b.abs();
  while (y != 0) {
    final t = y;
    y = x % y;
    x = t;
  }
  return x;
}
