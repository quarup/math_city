import 'dart:math';

import 'package:math_city/domain/questions/generated_question.dart';

/// Late-grade generators: Pythagorean, volume formula, scientific
/// notation operations, rational ordering, rational-vs-irrational.
/// Kept in a separate file because they don't fit cleanly into one
/// existing category — they span geometry, number theory, and rationals.

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

// ─────────────────────────────────────────────────────────────────────────
// pythagorean_apply_2d (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// Pick a Pythagorean triple (a, b, c) where a² + b² = c². Randomly
/// ask for the hypotenuse OR one of the legs. Triples drawn from the
/// classic short list, optionally scaled by k ∈ {1, 2}.
GeneratedQuestion pythagoreanApply2d(Random rand) {
  const triples = <(int, int, int)>[
    (3, 4, 5),
    (5, 12, 13),
    (6, 8, 10),
    (8, 15, 17),
    (7, 24, 25),
    (9, 12, 15),
    (9, 40, 41),
  ];
  final base = triples[rand.nextInt(triples.length)];
  final k = rand.nextInt(2) + 1; // 1 or 2
  final a = base.$1 * k;
  final b = base.$2 * k;
  final c = base.$3 * k;
  // 70% ask for hypotenuse, 30% ask for a leg.
  final askHypotenuse = rand.nextDouble() < 0.7;
  final int correctInt;
  final String prompt;
  if (askHypotenuse) {
    correctInt = c;
    prompt =
        'A right triangle has legs $a and $b. '
        'What is the length of the hypotenuse?';
  } else {
    // Ask for leg b given a and c.
    correctInt = b;
    prompt =
        'A right triangle has hypotenuse $c and one leg $a. '
        'What is the other leg?';
  }
  final correct = '$correctInt';
  final candidates = <String>[
    // Misconception: added the two givens.
    if (askHypotenuse) '${a + b}' else '${c + a}',
    // Misconception: gave one of the given sides.
    '$a',
    if (askHypotenuse) '$b' else '$c',
  ];

  return GeneratedQuestion(
    conceptId: 'pythagorean_apply_2d',
    prompt: prompt,
    correctAnswer: correct,
    distractors: _wholeDistractors(correctInt, candidates, rand),
    explanation: [
      'Pythagorean theorem: a² + b² = c².',
      if (askHypotenuse)
        '$a² + $b² = ${a * a + b * b} = $c² → c = $c.'
      else
        '$c² − $a² = ${c * c - a * a} = $b² → b = $b.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// volume_rect_prism_formula (Grade 5)
// ─────────────────────────────────────────────────────────────────────────

/// "A box has length 4, width 3, and height 5. What is its volume?"
/// → 60. Edge lengths in [2, 9].
GeneratedQuestion volumeRectPrismFormula(Random rand) {
  final l = rand.nextInt(8) + 2; // 2..9
  final w = rand.nextInt(8) + 2;
  final h = rand.nextInt(8) + 2;
  final volume = l * w * h;
  final correct = '$volume';

  final candidates = <String>[
    // Misconception: surface area-ish 2(lw + lh + wh).
    '${2 * (l * w + l * h + w * h)}',
    // Misconception: added edges instead of multiplying.
    '${l + w + h}',
    // Off by a factor.
    '${l * w}',
  ];

  return GeneratedQuestion(
    conceptId: 'volume_rect_prism_formula',
    prompt:
        'A rectangular box has length $l, width $w, and height $h. '
        'What is its volume?',
    correctAnswer: correct,
    distractors: _wholeDistractors(volume, candidates, rand),
    explanation: [
      'Volume = length × width × height.',
      '$l × $w × $h = $volume.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// scientific_notation_ops (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// "(2 × 10³) × (3 × 10⁴)" → "6 × 10⁷". Coefficients chosen as small
/// whole numbers whose product stays in [2, 9] so the answer is
/// already in proper scientific notation form. MC over four answers.
GeneratedQuestion scientificNotationOps(Random rand) {
  // Pick coefficients a, b in [2, 9] with a·b ≤ 9.
  late int a;
  late int b;
  do {
    a = rand.nextInt(8) + 2;
    b = rand.nextInt(8) + 2;
  } while (a * b > 9);
  final p = rand.nextInt(4) + 2; // 2..5
  final q = rand.nextInt(4) + 2;
  final productCoeff = a * b;
  final productExp = p + q;
  final correct = '$productCoeff × 10^$productExp';

  // Build candidates that don't collide with the correct answer for any
  // (p, q) combination — the p×q variant collides when p+q == p·q (only
  // when both are 2). Several fallbacks keep the pool ≥ 3.
  final candidates = <String>[
    '$productCoeff × 10^${p * q}',
    '${a + b} × 10^$productExp',
    '$productCoeff × 10^$p',
    '$productCoeff × 10^$q',
    '${productCoeff + 1} × 10^$productExp',
    '$productCoeff × 10^${productExp + 1}',
  ];
  final distractors = <String>[];
  final seen = <String>{correct};
  for (final c in candidates) {
    if (distractors.length >= 3) break;
    if (seen.add(c)) distractors.add(c);
  }

  return GeneratedQuestion(
    conceptId: 'scientific_notation_ops',
    prompt: '($a × 10^$p) × ($b × 10^$q) = ?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Multiply the coefficients; add the exponents.',
      '$a × $b = $productCoeff;  $p + $q = $productExp.',
      '→ $correct.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// compare_order_rationals (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "Which is the greatest: −1.5, 0.5, −2, 1?" → "1". MC over the four
/// values shown in the prompt. Generates a mix of decimals and integers
/// (both signed) in [−5, 5].
GeneratedQuestion compareOrderRationals(Random rand) {
  // Pick 4 distinct values from a curated mix of fifths and tenths.
  // Values in [-5, 5] at scale 0 or 1; ensure 4 distinct picks.
  final pool = <num>[
    for (var i = -5; i <= 5; i++) ...<num>[i, i + 0.5],
  ]..shuffle(rand);
  final values = pool.take(4).toList();
  final maxV = values.reduce((a, b) => a > b ? a : b);

  String format(num v) {
    if (v == v.truncate()) return '${v.toInt()}';
    final whole = v.truncate();
    if (whole == 0 && v < 0) return '-0.5';
    // Display half values as e.g. "1.5" or "-2.5".
    return v.toString();
  }

  final strings = values.map(format).toList();
  final correct = format(maxV);
  final distractors = strings.where((s) => s != correct).take(3).toList();

  return GeneratedQuestion(
    conceptId: 'compare_order_rationals',
    prompt: 'Which is the greatest: ${strings.join(", ")}?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Order on the number line: more positive = greater.',
      'Greatest: $correct.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// irrational_recognize (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// "Is √7 rational or irrational?" → MC over {rational, irrational}.
/// Curated cases mix obvious irrationals (√2, √3, √7, π) and obvious
/// rationals (√16 = 4, 3/5, 0.25, 0.333...).
GeneratedQuestion irrationalRecognize(Random rand) {
  const items = <(String, bool)>[
    ('√2', true),
    ('√3', true),
    ('√5', true),
    ('√7', true),
    ('√10', true),
    ('π', true),
    ('√16', false),
    ('√25', false),
    ('√100', false),
    ('3/5', false),
    ('0.25', false),
    ('0.333...', false),
    ('−7', false),
    ('1/9', false),
  ];
  final pick = items[rand.nextInt(items.length)];
  final isIrrational = pick.$2;
  final correct = isIrrational ? 'irrational' : 'rational';
  final distractors = <String>[
    if (isIrrational) 'rational' else 'irrational',
    'integer',
    'neither',
  ];

  return GeneratedQuestion(
    conceptId: 'irrational_recognize',
    prompt: 'Is ${pick.$1} rational or irrational?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      if (isIrrational)
        '${pick.$1} cannot be written as a/b with integers — irrational.'
      else
        '${pick.$1} can be written as a fraction of integers — rational.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// numerical_pattern_rule (Grade 4)
// ─────────────────────────────────────────────────────────────────────────

/// "Find the next number: 3, 7, 11, 15, ?" → 19. Two pattern families:
/// arithmetic (+ step) and geometric (× ratio). Tests CCSS 4.OA.C.5.
GeneratedQuestion numericalPatternRule(Random rand) {
  final isArithmetic = rand.nextBool();
  late List<int> seq;
  late int next;
  late String ruleText;
  late int misconception;
  if (isArithmetic) {
    final start = rand.nextInt(8) + 1; // 1..8
    final step = rand.nextInt(9) + 2; // 2..10
    seq = List.generate(4, (i) => start + step * i);
    next = seq.last + step;
    ruleText = 'add $step';
    misconception = seq.last + step - 1;
  } else {
    final start = rand.nextInt(5) + 1; // 1..5
    final ratio = rand.nextInt(2) + 2; // 2 or 3
    seq = List.generate(4, (i) => start * _intPow(ratio, i));
    next = seq.last * ratio;
    ruleText = 'multiply by $ratio';
    // Misconception: did additive (last + (last − prev)) instead.
    misconception = seq.last + (seq.last - seq[2]);
  }
  final correct = '$next';
  final prompt =
      'Find the next number: '
      '${seq[0]}, ${seq[1]}, ${seq[2]}, ${seq[3]}, ?';

  final candidatesSet = <String>{
    '$misconception',
    '${next + 1}',
    '${next - 1}',
    '${seq.last * 2}',
    '${seq.last + 1}',
  }..remove(correct);
  final candidates = candidatesSet.toList()..shuffle(rand);
  final distractors = candidates.take(3).toList();
  while (distractors.length < 3) {
    final extra = '${next + 5 + distractors.length}';
    if (extra != correct && !distractors.contains(extra)) {
      distractors.add(extra);
    } else {
      break;
    }
  }

  return GeneratedQuestion(
    conceptId: 'numerical_pattern_rule',
    prompt: prompt,
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Rule: $ruleText.',
      // ignore: no_adjacent_strings_in_list — single line wrapped for length
      'Next: ${seq.last}${isArithmetic ? ' + ' : ' × '}'
          '${isArithmetic ? next - seq.last : next ~/ seq.last} = $next.',
    ],
  );
}

int _intPow(int base, int exp) {
  var v = 1;
  for (var i = 0; i < exp; i++) {
    v *= base;
  }
  return v;
}

// ─────────────────────────────────────────────────────────────────────────
// arithmetic_patterns_in_tables (Grade 3)
// ─────────────────────────────────────────────────────────────────────────

/// "Pattern: 6, 12, 18, 24, ?" — multiples of n, n ∈ [2, 10]. Tests
/// CCSS 3.OA.D.9 — recognising multiplicative patterns in the
/// multiplication tables.
GeneratedQuestion arithmeticPatternsInTables(Random rand) {
  final n = rand.nextInt(9) + 2; // 2..10
  final terms = List.generate(4, (i) => n * (i + 1));
  final next = n * 5;
  final correct = '$next';
  final prompt = 'Pattern: ${terms.join(', ')}, ?';

  final candidates = <String>[
    // Misconception: kid added 1 instead of n.
    '${terms.last + 1}',
    // Misconception: kid skipped a step in the table.
    '${next + n}',
    // Misconception: doubled the last term.
    '${terms.last * 2}',
  ];

  return GeneratedQuestion(
    conceptId: 'arithmetic_patterns_in_tables',
    prompt: prompt,
    correctAnswer: correct,
    distractors: _wholeDistractors(next, candidates, rand),
    explanation: ['Each term goes up by $n.', '${terms.last} + $n = $next.'],
  );
}
