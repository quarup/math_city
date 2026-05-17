import 'dart:math';

import 'package:math_city/domain/questions/generated_question.dart';

/// Number-theory generators (Grade 4 / Grade 6): factors, multiples,
/// GCF, LCM. All algorithmic, integer-only. The factors / multiples
/// generators are MC over four candidates (one correct).

// ─────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────

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

// ─────────────────────────────────────────────────────────────────────────
// factors_of_n (Grade 4)
// ─────────────────────────────────────────────────────────────────────────

/// "Which of these is a factor of 24?" → MC over four candidates,
/// exactly one of which divides n. Excludes the trivial 1 and n itself
/// so the kid has to actually do divisibility.
GeneratedQuestion factorsOfN(Random rand) {
  // Pick n with at least one non-trivial factor in [2, 9].
  int n;
  List<int> factors;
  do {
    n = rand.nextInt(50) + 12; // 12..61
    factors = <int>[
      for (var i = 2; i < n; i++)
        if (n % i == 0 && i <= 9) i,
    ];
  } while (factors.isEmpty);
  final factor = factors[rand.nextInt(factors.length)];
  // Pick three non-factors in the same 2..9 range.
  final nonFactors = <int>[
    for (var i = 2; i <= 9; i++)
      if (n % i != 0) i,
  ]..shuffle(rand);
  final distractors = nonFactors.take(3).map((v) => '$v').toList();

  return GeneratedQuestion(
    conceptId: 'factors_of_n',
    prompt: 'Which of these is a factor of $n?',
    correctAnswer: '$factor',
    distractors: distractors,
    explanation: [
      '$n ÷ $factor = ${n ~/ factor}, with no remainder.',
      'So $factor is a factor of $n.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// multiples_of_n (Grade 4)
// ─────────────────────────────────────────────────────────────────────────

/// "Which of these is a multiple of 7?" → MC over four candidates,
/// exactly one of which is divisible by n.
GeneratedQuestion multiplesOfN(Random rand) {
  final n = rand.nextInt(8) + 2; // 2..9
  final k = rand.nextInt(8) + 2; // 2..9
  final correct = n * k; // multiple of n
  // Pick three non-multiples in a nearby range.
  final candidates = <int>{};
  while (candidates.length < 3) {
    final v = rand.nextInt(50) + 5; // 5..54
    if (v == correct || v % n == 0) continue;
    candidates.add(v);
  }
  final distractors = candidates.map((v) => '$v').toList();

  return GeneratedQuestion(
    conceptId: 'multiples_of_n',
    prompt: 'Which of these is a multiple of $n?',
    correctAnswer: '$correct',
    distractors: distractors,
    explanation: [
      '$correct = $n × $k.',
      'So $correct is a multiple of $n.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// gcf_two_numbers (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "Find the GCF of 12 and 18" → 6. Picks two numbers with a clean
/// GCF in [2, 12].
GeneratedQuestion gcfTwoNumbers(Random rand) {
  // Pick GCF and two co-prime cofactors.
  final g = rand.nextInt(11) + 2; // 2..12
  int p;
  int q;
  do {
    p = rand.nextInt(8) + 2; // 2..9
    q = rand.nextInt(8) + 2;
  } while (p == q || _gcd(p, q) != 1);
  final a = g * p;
  final b = g * q;
  final correct = '$g';

  final candidates = <String>[
    // Misconception: gave the LCM instead.
    '${a * b ~/ g}',
    // Misconception: gave one of the inputs.
    '$a',
    '$b',
    // Misconception: gave the sum.
    '${a + b}',
  ];

  return GeneratedQuestion(
    conceptId: 'gcf_two_numbers',
    prompt: 'Find the GCF of $a and $b.',
    correctAnswer: correct,
    distractors: _wholeDistractors(g, candidates, rand),
    explanation: [
      '$a = $g × $p; $b = $g × $q.',
      'Greatest common factor = $g.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// lcm_two_numbers (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "Find the LCM of 4 and 6" → 12. Same `g × p / q` parametrisation
/// as `gcf_two_numbers`; the LCM is `a × b ÷ gcd(a, b)`.
GeneratedQuestion lcmTwoNumbers(Random rand) {
  final g = rand.nextInt(3) + 1; // 1..3 — keep LCMs reasonable
  int p;
  int q;
  do {
    p = rand.nextInt(5) + 2; // 2..6
    q = rand.nextInt(5) + 2;
  } while (p == q || _gcd(p, q) != 1);
  final a = g * p;
  final b = g * q;
  final lcm = a * b ~/ g;
  final correct = '$lcm';

  final candidates = <String>[
    // Misconception: gave the GCF instead.
    '$g',
    // Misconception: gave the product.
    '${a * b}',
    // Misconception: gave one input.
    '$a',
    '$b',
  ];

  return GeneratedQuestion(
    conceptId: 'lcm_two_numbers',
    prompt: 'Find the LCM of $a and $b.',
    correctAnswer: correct,
    distractors: _wholeDistractors(lcm, candidates, rand),
    explanation: [
      'Multiples of $a: $a, ${a * 2}, ${a * 3}, …',
      'Smallest one divisible by $b is $lcm.',
    ],
  );
}
