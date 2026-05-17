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
// prime_or_composite (Grade 4)
// ─────────────────────────────────────────────────────────────────────────

/// "Is 17 prime or composite?" → "prime" or "composite". MC of
/// {prime, composite}. Excludes 1 (neither) and the small primes ≤ 3
/// to keep the kid thinking.
GeneratedQuestion primeOrComposite(Random rand) {
  int n;
  bool isPrime;
  do {
    n = rand.nextInt(48) + 4; // 4..51
    isPrime = _isPrime(n);
  } while (n < 4); // dummy condition for clarity
  final correct = isPrime ? 'prime' : 'composite';
  final distractors = <String>[
    if (isPrime) 'composite' else 'prime',
    'neither',
    'both',
  ];

  return GeneratedQuestion(
    conceptId: 'prime_or_composite',
    prompt: 'Is $n prime or composite?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      if (isPrime)
        '$n has no factors other than 1 and itself — it is prime.'
      else
        '$n has factors besides 1 and itself — it is composite.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

bool _isPrime(int n) {
  if (n < 2) return false;
  for (var i = 2; i * i <= n; i++) {
    if (n % i == 0) return false;
  }
  return true;
}

// ─────────────────────────────────────────────────────────────────────────
// exponents_whole_number (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "What is 2³?" → 8. Base ∈ [2, 9], exponent ∈ [2, 4] so the answer
/// stays kid-tractable.
GeneratedQuestion exponentsWholeNumber(Random rand) {
  final base = rand.nextInt(8) + 2; // 2..9
  // Cap exponent based on base so n^e doesn't blow up.
  final maxExp = switch (base) {
    2 => 6, // 2^6 = 64
    3 => 4, // 3^4 = 81
    >= 4 && <= 6 => 3, // 6^3 = 216
    _ => 2, // 9^2 = 81
  };
  final exp = rand.nextInt(maxExp - 1) + 2; // 2..maxExp
  var value = 1;
  for (var i = 0; i < exp; i++) {
    value *= base;
  }
  final correct = '$value';

  final candidates = <String>[
    // Misconception: multiplied base × exponent.
    '${base * exp}',
    // Misconception: added base + exponent.
    '${base + exp}',
    // Off by one factor of base.
    '${value * base}',
  ];

  return GeneratedQuestion(
    conceptId: 'exponents_whole_number',
    prompt: 'What is $base^$exp?',
    correctAnswer: correct,
    distractors: _wholeDistractors(value, candidates, rand),
    explanation: [
      '$base^$exp means $base multiplied by itself $exp times.',
      '${List.filled(exp, '$base').join(' × ')} = $value.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// order_of_operations_with_exp (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "$a + $b² = ?" — order of operations with one exponent term. Three
/// shapes: $a + $b², $a × $b², $a − $b².
GeneratedQuestion orderOfOperationsWithExp(Random rand) {
  final a = rand.nextInt(19) + 2; // 2..20
  final b = rand.nextInt(6) + 2; // 2..7 — keep squared values small
  final shape = rand.nextInt(3);
  final bSquared = b * b;
  late int answer;
  late String prompt;
  switch (shape) {
    case 0:
      answer = a + bSquared;
      prompt = '$a + $b^2 = ?';
    case 1:
      answer = a * bSquared;
      prompt = '$a × $b^2 = ?';
    case _:
      // Ensure non-negative result.
      if (a < bSquared) return orderOfOperationsWithExp(rand);
      answer = a - bSquared;
      prompt = '$a − $b^2 = ?';
  }
  final correct = '$answer';

  final candidates = <String>[
    // Misconception: didn't square; used b literally.
    if (shape == 0) '${a + b}' else if (shape == 1) '${a * b}' else '${a - b}',
    // Misconception: did the op first, then squared.
    switch (shape) {
      0 => '${(a + b) * (a + b)}',
      1 => '${(a * b) * (a * b)}',
      _ => a > b ? '${(a - b) * (a - b)}' : '${a + b}',
    },
    // Off by one in the exponent magnitude.
    '${answer + bSquared}',
  ];

  return GeneratedQuestion(
    conceptId: 'order_of_operations_with_exp',
    prompt: prompt,
    correctAnswer: correct,
    distractors: _wholeDistractors(answer, candidates, rand),
    explanation: [
      'Exponents bind tighter than +, −, ×, ÷.',
      'Evaluate $b^2 = $bSquared first.',
      'Then $prompt → $correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// sqrt_perfect_squares (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// "√81 = ?" → 9. Root ∈ [2, 15] so the square is in [4, 225].
GeneratedQuestion sqrtPerfectSquares(Random rand) {
  final root = rand.nextInt(14) + 2; // 2..15
  final square = root * root;
  final correct = '$root';

  final candidates = <String>[
    // Misconception: gave the square instead of the root.
    '$square',
    // Misconception: half the square.
    '${square ~/ 2}',
    // Off by one.
    '${root + 1}',
  ];

  return GeneratedQuestion(
    conceptId: 'sqrt_perfect_squares',
    prompt: 'What is √$square?',
    correctAnswer: correct,
    distractors: _wholeDistractors(root, candidates, rand),
    explanation: [
      '√$square = the number whose square is $square.',
      '$root × $root = $square, so √$square = $root.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// cbrt_perfect_cubes (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// "∛27 = ?" → 3. Root ∈ [2, 8] so the cube ≤ 512.
GeneratedQuestion cbrtPerfectCubes(Random rand) {
  final root = rand.nextInt(7) + 2; // 2..8
  final cube = root * root * root;
  final correct = '$root';

  final candidates = <String>[
    // Misconception: gave the cube.
    '$cube',
    // Misconception: gave root × 3 (confused with root times exponent).
    '${root * 3}',
    // Off by one.
    '${root + 1}',
  ];

  return GeneratedQuestion(
    conceptId: 'cbrt_perfect_cubes',
    prompt: 'What is ∛$cube?',
    correctAnswer: correct,
    distractors: _wholeDistractors(root, candidates, rand),
    explanation: [
      '∛$cube = the number whose cube is $cube.',
      '$root × $root × $root = $cube, so ∛$cube = $root.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// scientific_notation_read (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// "What is 3.5 × 10^4?" → 35000. Coefficient at tenths precision in
/// [1.1, 9.9]; exponent ∈ [2, 5] so the result fits comfortably.
GeneratedQuestion scientificNotationRead(Random rand) {
  // Coefficient as scaled int over /10. Pick 11..99 (= 1.1..9.9).
  final coeffTenths = rand.nextInt(89) + 11;
  // Exponent ∈ [2, 5].
  final exp = rand.nextInt(4) + 2;
  // Result = coeffTenths × 10^(exp - 1) since coefficient is /10.
  var value = coeffTenths;
  for (var i = 1; i < exp; i++) {
    value *= 10;
  }
  final correct = '$value';

  final coeffStr = '${coeffTenths ~/ 10}.${coeffTenths % 10}';
  final candidates = <String>[
    // Misconception: off by one power of 10.
    '${value * 10}',
    '${value ~/ 10}',
    // Misconception: just multiplied coefficient by exponent.
    '${coeffTenths * exp ~/ 10}',
  ];

  return GeneratedQuestion(
    conceptId: 'scientific_notation_read',
    prompt: 'What is $coeffStr × 10^$exp written as a whole number?',
    correctAnswer: correct,
    distractors: _wholeDistractors(value, candidates, rand),
    explanation: [
      '$coeffStr × 10^$exp means shift the decimal point $exp places right.',
      '$coeffStr → $correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// scientific_notation_write (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// "Write 35000 in scientific notation" → "3.5 × 10^4". MC over four
/// plausibly-similar forms.
GeneratedQuestion scientificNotationWrite(Random rand) {
  final coeffTenths = rand.nextInt(89) + 11; // 1.1..9.9
  final exp = rand.nextInt(4) + 2; // 2..5
  var value = coeffTenths;
  for (var i = 1; i < exp; i++) {
    value *= 10;
  }
  final coeffStr = '${coeffTenths ~/ 10}.${coeffTenths % 10}';
  final correct = '$coeffStr × 10^$exp';
  final distractors = <String>{
    // Off by one in the exponent.
    '$coeffStr × 10^${exp + 1}',
    '$coeffStr × 10^${exp - 1}',
    // Wrong coefficient: shifted decimal by one place.
    '${coeffTenths * 10 ~/ 10}.${(coeffTenths * 10) % 10 ~/ 1} × 10^$exp',
  }.where((s) => s != correct).take(3).toList();
  // Fallback distractor if dedup left us short (rare).
  while (distractors.length < 3) {
    final extra =
        '${(coeffTenths + 11) ~/ 10}.${(coeffTenths + 11) % 10} × 10^$exp';
    if (extra != correct && !distractors.contains(extra)) {
      distractors.add(extra);
    } else {
      break;
    }
  }

  return GeneratedQuestion(
    conceptId: 'scientific_notation_write',
    prompt: 'Write $value in scientific notation.',
    correctAnswer: correct,
    distractors: distractors.take(3).toList(),
    explanation: [
      'Move the decimal point until exactly one non-zero digit sits before it.',
      '$value → $coeffStr × 10^$exp.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// integer_exponent_props (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// "Simplify: 2^3 × 2^4" → "2^7". MC over four exponent-rule outcomes:
/// product (a^m·a^n = a^(m+n)), quotient (a^m÷a^n = a^(m−n)), or power
/// of a power ((a^m)^n = a^(mn)).
GeneratedQuestion integerExponentProps(Random rand) {
  final base = rand.nextInt(8) + 2; // 2..9
  final m = rand.nextInt(5) + 2; // 2..6
  final n = rand.nextInt(4) + 2; // 2..5
  final shape = rand.nextInt(3);
  late int newExp;
  late String prompt;
  switch (shape) {
    case 0:
      newExp = m + n;
      prompt = 'Simplify: $base^$m × $base^$n';
    case 1:
      // Ensure m > n so the answer is positive.
      if (m <= n) return integerExponentProps(rand);
      newExp = m - n;
      prompt = 'Simplify: $base^$m ÷ $base^$n';
    default:
      newExp = m * n;
      prompt = 'Simplify: ($base^$m)^$n';
  }
  final correct = '$base^$newExp';
  // Build candidate distractors per shape — the "did the wrong rule"
  // exponent for each case.
  final wrongExp = switch (shape) {
    // For mult: a^m × a^n should be a^(m+n); kid does a^(m·n).
    0 => m * n,
    // For div: a^m ÷ a^n should be a^(m−n); kid does a^(m÷n) (or m+n).
    1 => m + n,
    // For power-of-power: (a^m)^n should be a^(m·n); kid does a^(m+n).
    _ => m + n,
  };
  final candidates = <String>[
    '$base^$wrongExp',
    // Misconception: did the wrong op on the BASES (doubled the base).
    '${base * 2}^$newExp',
    // Misconception: an unrelated nearby exponent.
    '$base^${newExp + 1}',
    '$base^${newExp > 1 ? newExp - 1 : newExp + 2}',
  ];
  final distractors = <String>[];
  final seen = <String>{correct};
  for (final c in candidates) {
    if (distractors.length >= 3) break;
    if (seen.add(c)) distractors.add(c);
  }

  return GeneratedQuestion(
    conceptId: 'integer_exponent_props',
    prompt: prompt,
    correctAnswer: correct,
    distractors: distractors,
    explanation: switch (shape) {
      0 => [
        'a^m × a^n = a^(m+n).',
        '$base^$m × $base^$n = $base^${m + n}.',
      ],
      1 => [
        'a^m ÷ a^n = a^(m−n).',
        '$base^$m ÷ $base^$n = $base^${m - n}.',
      ],
      _ => [
        '(a^m)^n = a^(m·n).',
        '($base^$m)^$n = $base^${m * n}.',
      ],
    },
    answerFormat: AnswerFormat.string,
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
