import 'dart:math';

import 'package:math_city/domain/questions/fraction.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// Probability generators (Grade 7). All algorithmic; the
/// curriculum-suggested `Spinner` / `Dice` widgets are not needed for
/// the introductory rows since the sample space can be described in
/// words ("Bag has 3 red and 5 blue marbles").

// ─────────────────────────────────────────────────────────────────────────
// probability_zero_to_one (Grade 7)
// ─────────────────────────────────────────────────────────────────────────

/// "An event has probability 0.5. It is most likely…" or
/// "An event is impossible. Its probability is…"
/// Tests the kid's intuition for the 0..1 probability scale via MC.
GeneratedQuestion probabilityZeroToOne(Random rand) {
  // Pick one of a small set of canonical scenarios.
  const scenarios = <(String, String, List<String>)>[
    (
      'An event that is impossible has a probability of:',
      '0',
      ['1', '0.5', '−1'],
    ),
    (
      'An event that is certain to happen has a probability of:',
      '1',
      ['0', '0.5', '100'],
    ),
    (
      'An event with probability 0.5 is best described as:',
      'equally likely',
      ['certain', 'impossible', 'unlikely'],
    ),
    (
      'Which probability means "very unlikely"?',
      '0.1',
      ['0.5', '0.9', '1'],
    ),
    (
      'Which probability means "very likely"?',
      '0.9',
      ['0.1', '0.5', '0'],
    ),
    (
      'A probability of 1.5 is:',
      'not possible',
      ['certain', 'very likely', 'impossible'],
    ),
  ];
  final pick = scenarios[rand.nextInt(scenarios.length)];

  return GeneratedQuestion(
    conceptId: 'probability_zero_to_one',
    prompt: pick.$1,
    correctAnswer: pick.$2,
    distractors: pick.$3,
    explanation: [
      'Probability is always between 0 and 1.',
      '0 means impossible; 1 means certain; 0.5 means equally likely.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// probability_simple_event (Grade 7)
// ─────────────────────────────────────────────────────────────────────────

/// "A bag has 3 red marbles and 5 blue marbles. What is P(red)?"
/// Answer is the reduced fraction `count(favorable) / count(total)`.
GeneratedQuestion probabilitySimpleEvent(Random rand) {
  const colorPairs = <(String, String)>[
    ('red', 'blue'),
    ('green', 'yellow'),
    ('black', 'white'),
    ('purple', 'orange'),
  ];
  final colors = colorPairs[rand.nextInt(colorPairs.length)];
  final a = rand.nextInt(7) + 2; // 2..8 favourable
  final b = rand.nextInt(7) + 2; // 2..8 other
  final total = a + b;
  final reduced = Fraction(a, total).reduce();
  final correct = reduced.toCanonical();

  // Misconception distractors:
  //   - gave the un-reduced fraction (a/(a+b)).
  //   - used count(other) / total.
  //   - used a/b (forgot the total).
  final candidates = <String>[
    '$a/$total',
    Fraction(b, total).reduce().toCanonical(),
    '$a/$b',
  ];

  final out = <String>[];
  final seen = <String>{correct};
  for (final c in candidates) {
    if (out.length >= 3) break;
    if (seen.contains(c)) continue;
    final f = Fraction.tryParse(c);
    if (f != null && f.equalsByValue(reduced)) continue;
    seen.add(c);
    out.add(c);
  }
  // Fallback: ±1 numerator perturbations.
  for (var i = 1; out.length < 3 && i < 10; i++) {
    final cand = '${reduced.numerator + i}/${reduced.denominator}';
    if (seen.add(cand)) out.add(cand);
  }

  return GeneratedQuestion(
    conceptId: 'probability_simple_event',
    prompt:
        'A bag has $a ${colors.$1} marbles and $b ${colors.$2} marbles. '
        'You pick one at random. What is P(${colors.$1})?',
    correctAnswer: correct,
    distractors: out.take(3).toList(),
    explanation: [
      'P = favourable ÷ total.',
      'Favourable: $a ${colors.$1}; total: $a + $b = $total.',
      '$a/$total reduced = $correct.',
    ],
    answerFormat: AnswerFormat.fraction,
    answerShape: AnswerShape.exactString,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// experimental_probability (Grade 7)
// ─────────────────────────────────────────────────────────────────────────

/// "A coin was flipped 20 times and landed heads 12 times. What is the
/// experimental probability of heads?" → reduced fraction (3/5).
GeneratedQuestion experimentalProbability(Random rand) {
  const scenarios = <(String, String, String, String)>[
    ('A coin was flipped', 'times', 'and landed heads', 'heads'),
    ('A die was rolled', 'times', 'and landed on 6', 'a 6'),
    ('A spinner was spun', 'times', 'and landed on red', 'red'),
  ];
  final s = scenarios[rand.nextInt(scenarios.length)];
  // Pick trials and successes so successes < trials and gcd > 1.
  int trials;
  int successes;
  do {
    trials = (rand.nextInt(5) + 2) * 5; // 10, 15, 20, …, 30
    successes = rand.nextInt(trials - 1) + 1; // 1..trials-1
  } while (Fraction(successes, trials).reduce().denominator == trials);
  final reduced = Fraction(successes, trials).reduce();
  final correct = reduced.toCanonical();

  final candidates = <String>[
    '$successes/$trials', // un-reduced
    Fraction(trials - successes, trials).reduce().toCanonical(), // complement
    '$successes/${trials - successes}', // ratio not probability
  ];
  final out = <String>[];
  final seen = <String>{correct};
  for (final c in candidates) {
    if (out.length >= 3) break;
    if (seen.contains(c)) continue;
    final f = Fraction.tryParse(c);
    if (f != null && f.equalsByValue(reduced)) continue;
    seen.add(c);
    out.add(c);
  }
  for (var i = 1; out.length < 3 && i < 10; i++) {
    final cand = '${reduced.numerator + i}/${reduced.denominator}';
    if (seen.add(cand)) out.add(cand);
  }

  return GeneratedQuestion(
    conceptId: 'experimental_probability',
    prompt:
        '${s.$1} $trials ${s.$2} ${s.$3} $successes times. '
        'What is the experimental probability of ${s.$4}?',
    correctAnswer: correct,
    distractors: out.take(3).toList(),
    explanation: [
      'Experimental P = successes ÷ trials.',
      '$successes / $trials reduced = $correct.',
    ],
    answerFormat: AnswerFormat.fraction,
    answerShape: AnswerShape.exactString,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// sample_space_list (Grade 7)
// ─────────────────────────────────────────────────────────────────────────

/// "Roll two dice. How many outcomes are in the sample space?" → 36.
/// Pure counting — the kid multiplies the per-trial counts. Three
/// scenario shapes for variety.
GeneratedQuestion sampleSpaceList(Random rand) {
  const scenarios = <(String, int, int)>[
    ('Roll two dice', 6, 6),
    ('Flip a coin three times', 2, 4), // 2 × 4 = 8 (interpret as 2×2×2)
    ('Spin a 4-section spinner twice', 4, 4),
    ('Pick one of 5 hats and one of 3 jackets', 5, 3),
    ('Pick one of 4 shirts and one of 6 pairs of pants', 4, 6),
    ('Flip a coin and roll a die', 2, 6),
  ];
  final pick = scenarios[rand.nextInt(scenarios.length)];
  final total = pick.$2 * pick.$3;
  final correct = '$total';

  final candidates = <String>[
    // Misconception: added counts.
    '${pick.$2 + pick.$3}',
    // Misconception: one of the input counts.
    '${pick.$2}',
    '${pick.$3}',
    // Off-by-1 (sometimes kids confuse outcomes with pairs).
    '${total + 1}',
  ];

  return GeneratedQuestion(
    conceptId: 'sample_space_list',
    prompt: '${pick.$1}. How many outcomes are possible?',
    correctAnswer: correct,
    distractors: <String>[
      ...{
        for (final c in candidates)
          if (c != correct) c,
      }.take(3),
    ],
    explanation: [
      'Multiply the number of choices at each step.',
      '${pick.$2} × ${pick.$3} = $total.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// theoretical_vs_experimental (Grade 7)
// ─────────────────────────────────────────────────────────────────────────

/// Distinguishes theoretical from experimental probability with both
/// surfaced in the same prompt. Tests CCSS 7.SP.C.6.
///
/// Scenario: a fair spinner / die / coin with `n` equally-likely
/// outcomes is run `trials` times; the target outcome occurs
/// `successes` times. The kid is asked for ONE of {theoretical,
/// experimental}; the other is the lead distractor.
GeneratedQuestion theoreticalVsExperimental(Random rand) {
  const scenarios = <(String, int, String)>[
    ('a 4-section spinner', 4, 'section 1'),
    ('a 6-section spinner', 6, 'section 3'),
    ('a 6-sided die', 6, 'a 4'),
    ('an 8-section spinner', 8, 'section 5'),
    ('a 10-section spinner', 10, 'section 7'),
  ];
  final s = scenarios[rand.nextInt(scenarios.length)];
  final n = s.$2;
  // Pick trials and successes so theoretical (1/n) and experimental
  // (successes/trials) reduce to *different* fractions — otherwise the
  // distinction is invisible.
  int trials;
  int successes;
  Fraction experimental;
  do {
    trials = (rand.nextInt(5) + 2) * 5; // 10, 15, 20, 25, 30
    successes = rand.nextInt(trials - 1) + 1; // 1..trials-1
    experimental = Fraction(successes, trials).reduce();
  } while (experimental.equalsByValue(Fraction(1, n)));
  final theoretical = Fraction(1, n).reduce();
  final askTheoretical = rand.nextBool();
  final correctF = askTheoretical ? theoretical : experimental;
  final otherF = askTheoretical ? experimental : theoretical;
  final correct = correctF.toCanonical();
  final which = askTheoretical ? 'theoretical' : 'experimental';

  // Distractor pool: the OTHER probability (lead misconception), plus
  // un-reduced and inverted forms.
  final unreduced = '$successes/$trials';
  final inverted = '$trials/$successes';
  final unreducedF = Fraction.tryParse(unreduced);
  final candidates = <String>[
    otherF.toCanonical(), // the "other" probability
    if (unreduced != correct &&
        (unreducedF == null || !unreducedF.equalsByValue(correctF)))
      unreduced,
    if (inverted != correct) inverted,
    // Off-by-1 numerator fallback.
    '${correctF.numerator + 1}/${correctF.denominator}',
  ];
  final distractors = <String>[];
  final seen = <String>{correct};
  for (final c in candidates) {
    if (distractors.length >= 3) break;
    final f = Fraction.tryParse(c);
    if (f != null && f.equalsByValue(correctF)) continue;
    if (seen.add(c)) distractors.add(c);
  }

  return GeneratedQuestion(
    conceptId: 'theoretical_vs_experimental',
    prompt:
        '${s.$1} is spun or rolled $trials times and lands on ${s.$3} '
        '$successes times. What is the $which probability of ${s.$3}?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: askTheoretical
        ? [
            'Theoretical P uses the fair outcomes — ignore the trial data.',
            'There are $n equally-likely outcomes, so P = 1/$n = $correct.',
          ]
        : [
            'Experimental P = successes ÷ trials.',
            '$successes / $trials reduced = $correct.',
          ],
    answerFormat: AnswerFormat.fraction,
    answerShape: AnswerShape.exactString,
  );
}
