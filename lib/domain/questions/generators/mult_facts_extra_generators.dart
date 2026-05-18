import 'dart:math';

import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// G3 multiplication-fact fill-in. Per-factor ×N tables and the algebraic
/// properties (commutative, associative, distributive-style missing factor).
/// All text-only single-integer answers; no diagrams.

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
// mult_facts_N (G3) — per-row of the multiplication table
// ─────────────────────────────────────────────────────────────────────────

/// Builds a generator for `n × b = ?` with `b ∈ [2, 9]`. The other factor
/// is fixed to [n]; this is the per-row drill that CCSS 3.OA names out
/// explicitly (×2, ×3, …, ×10).
GeneratedQuestion Function(Random rand) _multFactsRow(int n, String conceptId) {
  return (Random rand) {
    final b = rand.nextInt(8) + 2; // 2..9
    final correct = n * b;
    // 50/50 swap so the kid sometimes sees "b × n" — same skill, different
    // surface — which avoids them learning "the first number is always n".
    final swap = rand.nextBool();
    final lhs = swap ? '$b × $n' : '$n × $b';
    return GeneratedQuestion(
      conceptId: conceptId,
      prompt: '$lhs = ?',
      correctAnswer: '$correct',
      distractors: integerDistractorsWith(
        correct,
        rand,
        misconception: correct + n, // one off in the count of n's
      ),
      explanation: ['$n × $b = $correct'],
    );
  };
}

final GeneratedQuestion Function(Random) multFacts2 = _multFactsRow(
  2,
  'mult_facts_2',
);
final GeneratedQuestion Function(Random) multFacts3 = _multFactsRow(
  3,
  'mult_facts_3',
);
final GeneratedQuestion Function(Random) multFacts4 = _multFactsRow(
  4,
  'mult_facts_4',
);
final GeneratedQuestion Function(Random) multFacts5 = _multFactsRow(
  5,
  'mult_facts_5',
);
final GeneratedQuestion Function(Random) multFacts6 = _multFactsRow(
  6,
  'mult_facts_6',
);
final GeneratedQuestion Function(Random) multFacts7 = _multFactsRow(
  7,
  'mult_facts_7',
);
final GeneratedQuestion Function(Random) multFacts8 = _multFactsRow(
  8,
  'mult_facts_8',
);
final GeneratedQuestion Function(Random) multFacts9 = _multFactsRow(
  9,
  'mult_facts_9',
);
final GeneratedQuestion Function(Random) multFacts10 = _multFactsRow(
  10,
  'mult_facts_10',
);

// ─────────────────────────────────────────────────────────────────────────
// mult_1digit_by_multiple_of_10 (G3)
// ─────────────────────────────────────────────────────────────────────────

/// "4 × 30 = ?" — single-digit times a multiple of 10. Builds on
/// skip_count_10 + mult_facts_within_100.
GeneratedQuestion mult1digitByMultipleOf10(Random rand) {
  final a = rand.nextInt(8) + 2; // 2..9
  final tens = rand.nextInt(8) + 2; // 2..9
  final b = tens * 10;
  final correct = a * b;
  return GeneratedQuestion(
    conceptId: 'mult_1digit_by_multiple_of_10',
    prompt: '$a × $b = ?',
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, [
      '${a * tens}', // forgot to multiply by 10
      '${correct * 10}', // multiplied by 100
      '${a * tens * 100}', // multiplied by 1000
      '${a + b}', // wrong operation
    ]),
    explanation: [
      '$a × $tens = ${a * tens}',
      '$a × $b = ${a * tens} × 10 = $correct',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// commutative_mult (G3)
// ─────────────────────────────────────────────────────────────────────────

/// "If 4 × 7 = 28, then 7 × 4 = ?" — same shape as commutative_add. The
/// kid only needs to recognise the property to give the same product
/// back; the wrong-but-tempting distractors are the operands themselves.
GeneratedQuestion commutativeMult(Random rand) {
  late int a;
  late int b;
  do {
    a = rand.nextInt(8) + 2; // 2..9
    b = rand.nextInt(8) + 2;
  } while (a == b); // distinct so "swap is the same" is non-trivial
  final correct = a * b;
  return GeneratedQuestion(
    conceptId: 'commutative_mult',
    prompt: 'If $a × $b = $correct, then $b × $a = ?',
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, [
      '${a + b}', // wrong operation
      '${(a - b).abs()}', // wrong operation
      '$a', // gave one of the factors
      '$b',
    ]),
    explanation: [
      'Multiplication is commutative: $a × $b = $b × $a.',
      'Both equal $correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// associative_mult (G3)
// ─────────────────────────────────────────────────────────────────────────

/// "If (2 × 3) × 5 = 30, then 2 × (3 × 5) = ?" — tests recognition that
/// regrouping factors doesn't change the product. Operands restricted to
/// small primes so the inner products stay readable (≤ 81) and the
/// final product stays ≤ 100.
GeneratedQuestion associativeMult(Random rand) {
  final pool = [2, 3, 4, 5];
  // Three factors with product ≤ 60 (keeps the answer readable).
  late int a;
  late int b;
  late int c;
  int product;
  do {
    a = pool[rand.nextInt(pool.length)];
    b = pool[rand.nextInt(pool.length)];
    c = pool[rand.nextInt(pool.length)];
    product = a * b * c;
  } while (product > 60);
  // Show one grouping in the LHS, ask for the other grouping.
  final leftFirst = rand.nextBool();
  final lhs = leftFirst ? '($a × $b) × $c' : '$a × ($b × $c)';
  final rhs = leftFirst ? '$a × ($b × $c)' : '($a × $b) × $c';
  return GeneratedQuestion(
    conceptId: 'associative_mult',
    prompt: 'If $lhs = $product, then $rhs = ?',
    correctAnswer: '$product',
    distractors: _distinctIntStrings(product, [
      '${a * b + c}', // forgot to multiply the last
      '${a + b * c}', // forgot the first
      '${a + b + c}', // added everything
      '${a * b}', // gave just the inner product
      '${b * c}',
    ]),
    explanation: [
      'Associative: regrouping factors gives the same product.',
      '$lhs = $rhs = $product.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// div_as_unknown_factor (G3)
// ─────────────────────────────────────────────────────────────────────────

/// "What times 6 equals 42?" → 7. Same arithmetic as div_facts but the
/// surface is "fill in the missing factor", which is the standard frame
/// for ÷ as the inverse of ×.
GeneratedQuestion divAsUnknownFactor(Random rand) {
  final known = rand.nextInt(8) + 2; // 2..9
  final answer = rand.nextInt(9) + 1; // 1..9
  final product = known * answer;
  // 50/50: "? × known = product" vs "known × ? = product".
  final blankFirst = rand.nextBool();
  final prompt = blankFirst
      ? '___ × $known = $product'
      : '$known × ___ = $product';
  return GeneratedQuestion(
    conceptId: 'div_as_unknown_factor',
    prompt: prompt,
    correctAnswer: '$answer',
    distractors: integerDistractorsWith(
      answer,
      rand,
      misconception: product - known, // subtracted instead of divided
    ),
    explanation: [
      '$known × $answer = $product',
      'So the missing factor is $answer.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// arithmetic_patterns_in_tables (G3)
// ─────────────────────────────────────────────────────────────────────────

/// "What's the next number? 4, 8, 12, 16, __" — arithmetic sequence with
/// step ∈ [2, 10]. Start ∈ [1, 9]; the 4-term sequence stays under 100
/// so the answer fits on the wheel keypad. Tests CCSS 3.OA.D.9 (identify
/// arithmetic patterns).
GeneratedQuestion arithmeticPatternsInTables(Random rand) {
  final step = rand.nextInt(9) + 2; // 2..10
  final start = rand.nextInt(9) + 1; // 1..9
  final t0 = start;
  final t1 = t0 + step;
  final t2 = t1 + step;
  final t3 = t2 + step;
  final correct = t3 + step;
  return GeneratedQuestion(
    conceptId: 'arithmetic_patterns_in_tables',
    prompt: 'What comes next? $t0, $t1, $t2, $t3, ?',
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, [
      '${t3 + step + 1}', // off-by-one in step
      '${t3 + step - 1}',
      '$t3', // forgot to add
      '${t3 * 2}', // doubled the last
      '${t3 + 1}', // step = 1
    ]),
    explanation: [
      'Each term is $step more than the one before.',
      '$t3 + $step = $correct.',
    ],
  );
}
