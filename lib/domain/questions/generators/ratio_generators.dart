import 'dart:math';

import 'package:math_city/domain/questions/generated_question.dart';

/// Ratio + proportion generators (Grades 6–7).
///
/// Notation conventions:
///   * `a:b` is the canonical ratio shape. The on-screen keypad surfaces
///     `:` automatically (it's derived from the canonical answer).
///   * For "Mia has N items" word problems, names are drawn from a small
///     curated pool to keep questions varied without going wild.

const _names = <String>[
  'Mia',
  'Leo',
  'Aria',
  'Noah',
  'Lila',
  'Kai',
  'Maya',
  'Theo',
  'Zoe',
  'Eli',
  'Ivy',
  'Owen',
];

const _itemPairs = <(String, String)>[
  ('apples', 'oranges'),
  ('cats', 'dogs'),
  ('red balloons', 'blue balloons'),
  ('books', 'magazines'),
  ('pens', 'pencils'),
  ('bricks', 'tiles'),
  ('roses', 'tulips'),
];

// ─────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────

/// Returns three distinct whole-number-string distractors that differ
/// from [correct]. Seeds with [candidates], then walks outward.
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

/// String-distractor variant for ratio "a:b" answers.
List<String> _ratioStringDistractors(
  String correct,
  List<String> candidates,
) {
  final out = <String>[];
  final seen = <String>{correct};
  for (final c in candidates) {
    if (out.length >= 3) break;
    if (seen.add(c)) out.add(c);
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
// ratio_intro (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "Mia has 3 apples and 5 oranges. What is the ratio of apples to
/// oranges?" → "3:5". Operands in [1, 9]; the answer is left
/// un-reduced because the lesson is "read off the count", not "simplify".
GeneratedQuestion ratioIntro(Random rand) {
  final name = _names[rand.nextInt(_names.length)];
  final pair = _itemPairs[rand.nextInt(_itemPairs.length)];
  int a;
  int b;
  do {
    a = rand.nextInt(8) + 2; // 2..9
    b = rand.nextInt(8) + 2;
  } while (a == b); // skip degenerate 1:1 ratios
  final correct = '$a:$b';

  // Misconception distractors: order swapped; counted only one side;
  // wrote the sum instead of the ratio.
  final distractors = _ratioStringDistractors(correct, <String>[
    '$b:$a', // swapped
    '$a:${a + b}', // ratio of a to total
    '${a + b}:$a', // total to a
    '$b:${a + b}',
  ]);

  return GeneratedQuestion(
    conceptId: 'ratio_intro',
    prompt:
        '$name has $a ${pair.$1} and $b ${pair.$2}. '
        'What is the ratio of ${pair.$1} to ${pair.$2}?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      '$a ${pair.$1} compared to $b ${pair.$2}.',
      'Ratio = $a to $b, written $a:$b.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// ratio_language (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "Which of these is the same as 3:5?" — multiple-choice that
/// teaches the equivalence among `a:b`, `a/b`, and `a to b` notations.
/// Answer is always the `a/b` form (the cross-notation kids tend to
/// miss first).
GeneratedQuestion ratioLanguage(Random rand) {
  int a;
  int b;
  do {
    a = rand.nextInt(8) + 2; // 2..9
    b = rand.nextInt(8) + 2;
  } while (a == b);
  final correct = '$a/$b';

  // Distractors mix correct and incorrect notation variants.
  final distractors = _ratioStringDistractors(correct, <String>[
    '$b/$a', // swapped
    '$a/${a + b}', // part-to-total mistake
    '${a + b}/$b', // total-to-part
    '${a - 1}/$b',
  ]);

  return GeneratedQuestion(
    conceptId: 'ratio_language',
    prompt: 'Which is the same as the ratio $a:$b?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      '$a:$b can also be written as $a to $b, or as the fraction $a/$b.',
      'All three notations mean the same comparison.',
    ],
    answerFormat: AnswerFormat.fraction,
    // exactString because the lesson IS the surface form; we don't want
    // to accept e.g. 6/10 as "equivalent to 3:5" — that's a different
    // lesson (equivalent_ratios).
    answerShape: AnswerShape.exactString,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// equivalent_ratios (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "Complete: 2:3 = ?:12" — given a base ratio and a target denominator,
/// ask for the numerator that makes the ratios equivalent. Multiplier
/// k in [2, 6] keeps numbers manageable.
GeneratedQuestion equivalentRatios(Random rand) {
  // Base ratio a:b in lowest terms (avoid 1:1 and equal values for variety).
  int a;
  int b;
  do {
    a = rand.nextInt(5) + 2; // 2..6
    b = rand.nextInt(5) + 2;
  } while (a == b || _gcd(a, b) != 1);
  final k = rand.nextInt(5) + 2; // 2..6
  final scaledA = a * k;
  final scaledB = b * k;
  // Randomise which side is the blank.
  final blankOnLeft = rand.nextBool();
  final prompt = blankOnLeft
      ? 'Complete: $a:$b = ?:$scaledB'
      : 'Complete: $a:$b = $scaledA:?';
  final answer = blankOnLeft ? scaledA : scaledB;
  final correct = '$answer';

  final candidates = <String>[
    // Misconception: added the multiplier instead of multiplying.
    '${answer + 1}',
    // Misconception: used the other side's scaled value.
    '${blankOnLeft ? scaledB : scaledA}',
    // Misconception: kept the original term (forgot to scale).
    '${blankOnLeft ? a : b}',
  ];

  return GeneratedQuestion(
    conceptId: 'equivalent_ratios',
    prompt: prompt,
    correctAnswer: correct,
    distractors: _wholeDistractors(answer, candidates, rand),
    explanation: [
      '$a:$b scaled up by $k gives $scaledA:$scaledB.',
      'Both terms multiply by the same number.',
      'Answer: $correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// unit_rate (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "60 miles in 3 hours. What's the unit rate (miles per hour)?" → 20.
/// Parameters picked so the unit rate is always a whole number.
GeneratedQuestion unitRate(Random rand) {
  // Pick rate (the unit-per-1 answer) in [2, 30] and divisor in [2, 12].
  final rate = rand.nextInt(29) + 2;
  final divisor = rand.nextInt(11) + 2;
  final total = rate * divisor;
  final correct = '$rate';

  // Choose a (unit, denom-noun) context for the prompt wording.
  const contexts = <(String, String, String)>[
    ('miles', 'hours', 'miles per hour'),
    ('words', 'minutes', 'words per minute'),
    ('pages', 'days', 'pages per day'),
    ('apples', 'baskets', 'apples per basket'),
    ('candies', 'kids', 'candies per kid'),
    ('cookies', 'plates', 'cookies per plate'),
  ];
  final ctx = contexts[rand.nextInt(contexts.length)];

  final candidates = <String>[
    // Misconception: gave the total.
    '$total',
    // Misconception: gave the divisor.
    '$divisor',
    // Misconception: subtracted instead of divided.
    '${total - divisor}',
  ];

  return GeneratedQuestion(
    conceptId: 'unit_rate',
    prompt:
        '$total ${ctx.$1} in $divisor ${ctx.$2}. '
        'What is the unit rate (${ctx.$3})?',
    correctAnswer: correct,
    distractors: _wholeDistractors(rate, candidates, rand),
    explanation: [
      'Unit rate = total ÷ how many units.',
      '$total ÷ $divisor = $rate ${ctx.$3}.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// unit_pricing (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "Three apples cost \$6. What's the unit price (dollars per apple)?"
/// → 2. Same arithmetic shape as `unit_rate`, framed as money.
/// Curriculum tags as dataset; implemented algorithmically per design
/// principle 4.
GeneratedQuestion unitPricing(Random rand) {
  final price = rand.nextInt(8) + 2; // 2..9 dollars per item
  final count = rand.nextInt(8) + 2; // 2..9 items
  final total = price * count;

  const items = <String>[
    'apples',
    'oranges',
    'pens',
    'notebooks',
    'cookies',
    'candles',
    'magnets',
    'erasers',
  ];
  final item = items[rand.nextInt(items.length)];

  final correct = '$price';
  final candidates = <String>['$total', '$count', '${total - count}'];

  return GeneratedQuestion(
    conceptId: 'unit_pricing',
    prompt:
        '$count $item cost \$$total. What is the unit price '
        '(dollars per $item)?',
    correctAnswer: correct,
    distractors: _wholeDistractors(price, candidates, rand),
    explanation: [
      'Unit price = total ÷ how many items.',
      '\$$total ÷ $count = \$$price per $item.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// convert_units_using_ratio (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "1 ft = 12 in. How many inches in 4 ft?" → 48. Uses small whole-
/// number conversion factors so the answer is always an integer.
GeneratedQuestion convertUnitsUsingRatio(Random rand) {
  // Curated (from-unit, to-unit, factor) triples; factor = to/from.
  const conversions = <(String, String, int)>[
    ('foot', 'inches', 12),
    ('yard', 'feet', 3),
    ('meter', 'centimeters', 100),
    ('hour', 'minutes', 60),
    ('minute', 'seconds', 60),
    ('day', 'hours', 24),
    ('week', 'days', 7),
    ('kilogram', 'grams', 1000),
  ];
  final c = conversions[rand.nextInt(conversions.length)];
  final quantity = rand.nextInt(8) + 2; // 2..9
  // Cap big-factor conversions so the answer stays kid-tractable.
  final cappedQuantity = c.$3 >= 100 ? (rand.nextInt(4) + 2) : quantity;
  final answer = cappedQuantity * c.$3;
  final correct = '$answer';

  final candidates = <String>[
    '${cappedQuantity + c.$3}',
    '$cappedQuantity', // forgot to multiply
    '${c.$3}',
  ];

  return GeneratedQuestion(
    conceptId: 'convert_units_using_ratio',
    prompt:
        '1 ${c.$1} = ${c.$3} ${c.$2}. '
        'How many ${c.$2} are in $cappedQuantity ${c.$1}'
        '${cappedQuantity == 1 ? "" : "s"}?',
    correctAnswer: correct,
    distractors: _wholeDistractors(answer, candidates, rand),
    explanation: [
      '1 ${c.$1} = ${c.$3} ${c.$2}.',
      'Multiply by $cappedQuantity: ${c.$3} × $cappedQuantity = $answer.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// proportional_relationship (Grade 7)
// ─────────────────────────────────────────────────────────────────────────

/// "Given x: 1, 2, 3; y: 4, 8, 12. Is this proportional?" → "Yes" / "No".
/// Verbal-table version (the curriculum.md row asks for a coordinate-
/// plane diagram, but the underlying lesson — "is y/x constant?" —
/// works fine with a typed mini-table). MC of {Yes, No}.
GeneratedQuestion proportionalRelationship(Random rand) {
  final isProportional = rand.nextBool();
  // Three x-values 1..5 (distinct, increasing).
  final xs = <int>[1, 2, 3];
  late final List<int> ys;
  if (isProportional) {
    final k = rand.nextInt(8) + 2; // 2..9
    ys = xs.map((x) => x * k).toList();
  } else {
    // Pick non-proportional: y = mx + b with b != 0.
    final m = rand.nextInt(5) + 1; // 1..5
    final b = rand.nextInt(8) + 1; // 1..8 (b != 0 breaks proportionality)
    ys = xs.map((x) => m * x + b).toList();
  }

  final tableX = xs.join(', ');
  final tableY = ys.join(', ');
  final correct = isProportional ? 'Yes' : 'No';
  final distractors = <String>[
    if (isProportional) 'No' else 'Yes',
    "Can't tell",
    'Sometimes',
  ];

  return GeneratedQuestion(
    conceptId: 'proportional_relationship',
    prompt: 'x: $tableX; y: $tableY. Is y proportional to x?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Proportional iff y/x is the same constant for every pair.',
      if (isProportional)
        'Every y ÷ x = ${ys.first ~/ xs.first} here — same constant.'
      else
        'y ÷ x changes across rows — so it is not proportional.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// constant_of_proportionality (Grade 7)
// ─────────────────────────────────────────────────────────────────────────

/// "y = kx, and y = 12 when x = 3. What is k?" → 4. Always pick an
/// integer k.
GeneratedQuestion constantOfProportionality(Random rand) {
  final k = rand.nextInt(9) + 2; // 2..10
  final x = rand.nextInt(8) + 2; // 2..9
  final y = k * x;

  final correct = '$k';
  final candidates = <String>[
    '${y - x}', // subtracted instead of divided
    '$x',
    '$y',
    '${y + x}',
  ];

  return GeneratedQuestion(
    conceptId: 'constant_of_proportionality',
    prompt: 'y = kx. If y = $y when x = $x, what is k?',
    correctAnswer: correct,
    distractors: _wholeDistractors(k, candidates, rand),
    explanation: [
      'k = y ÷ x.',
      '$y ÷ $x = $k.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// proportional_equation (Grade 7)
// ─────────────────────────────────────────────────────────────────────────

/// "y is proportional to x. y = 12 when x = 3. Pick the equation."
/// MC over four equation forms — the kid practises identifying the
/// proportional `y = kx` shape vs. additive, inverse, etc.
GeneratedQuestion proportionalEquation(Random rand) {
  final k = rand.nextInt(9) + 2; // 2..10
  final x = rand.nextInt(8) + 2; // 2..9
  final y = k * x;
  final correct = 'y = ${k}x';
  final distractors = <String>[
    'y = x + $k', // additive shift
    'y = $k/x', // inverse
    'y = ${k}x + 1', // linear with intercept
  ];

  return GeneratedQuestion(
    conceptId: 'proportional_equation',
    prompt: 'y is proportional to x. When x = $x, y = $y. Which equation fits?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'For a proportional relationship: y = kx where k = y ÷ x.',
      'k = $y ÷ $x = $k.',
      'So y = ${k}x.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// constant_speed (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// Distance = rate × time. Picks one of three blanks to fill so the
/// kid practises the same relationship from all three angles.
GeneratedQuestion constantSpeed(Random rand) {
  final rate = (rand.nextInt(9) + 2) * 5; // 10, 15, 20, …, 50 (mph)
  final time = rand.nextInt(7) + 2; // 2..8 hours
  final distance = rate * time;

  final whichBlank = rand.nextInt(3); // 0 = distance, 1 = time, 2 = rate
  final String prompt;
  final int correctInt;
  switch (whichBlank) {
    case 0:
      prompt =
          'A car travels at $rate mph for $time hours. '
          'How far does it go (in miles)?';
      correctInt = distance;
    case 1:
      prompt =
          'A car travels $distance miles at $rate mph. '
          'How many hours does it take?';
      correctInt = time;
    default:
      prompt =
          'A car travels $distance miles in $time hours. '
          'What is its speed (in mph)?';
      correctInt = rate;
  }
  final correct = '$correctInt';

  // Misconception distractors common to all three: confused inputs.
  final candidates = <String>[
    '$rate',
    '$time',
    '$distance',
    '${rate + time}',
  ]..remove(correct);

  return GeneratedQuestion(
    conceptId: 'constant_speed',
    prompt: prompt,
    correctAnswer: correct,
    distractors: _wholeDistractors(correctInt, candidates, rand),
    explanation: [
      'distance = rate × time.',
      '$distance = $rate × $time.',
      'Answer: $correct.',
    ],
  );
}
