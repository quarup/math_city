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
