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
// theoretical_vs_experimental (Grade 7)
// ─────────────────────────────────────────────────────────────────────────

/// Two-shape generator that drills the *contrast* between theoretical
/// and experimental probability. Same scenario in both shapes — only
/// the question (THEORETICAL or EXPERIMENTAL) differs — so the
/// "other" probability shows up as the natural misconception
/// distractor.
///
/// Devices are fair (coin / 6-die / 4-spin / 5-spin) so theoretical P
/// is a simple unit fraction. Observed count is forced away from the
/// expected count so the two answers visibly differ.
GeneratedQuestion theoreticalVsExperimental(Random rand) {
  // (preamble, theoreticalNum, theoreticalDen, action phrase, result short)
  // theoretical = num/den is the fixed device probability.
  const scenarios = <(String, int, int, String, String)>[
    ('A fair coin was flipped', 1, 2, 'landed heads', 'heads'),
    ('A fair 6-sided die was rolled', 1, 6, 'showed a 4', 'a 4'),
    ('A 4-color spinner was spun', 1, 4, 'landed on red', 'red'),
    ('A 5-color spinner was spun', 1, 5, 'landed on blue', 'blue'),
  ];
  final s = scenarios[rand.nextInt(scenarios.length)];
  final den = s.$3;
  final numerator = s.$2;

  // Pick trials as a multiple of the denominator so expected =
  // trials × numerator/den is a clean integer.
  final mult = rand.nextInt(8) + 3; // 3..10
  final trials = mult * den;
  final expected = mult * numerator;

  // Observed: stay near expected but ≠ expected, and the resulting
  // reduced experimental fraction must differ from the theoretical
  // (otherwise both shapes give the same answer and the contrast is lost).
  final theoretical = Fraction(numerator, den).reduce();
  var observed = expected + 1; // fallback seed; overwritten below.
  var experimental = Fraction(observed, trials).reduce();
  for (var attempt = 0; attempt < 20; attempt++) {
    final magnitude = rand.nextInt(3) + 2; // 2..4
    final sign = rand.nextBool() ? 1 : -1;
    final candidate = expected + sign * magnitude;
    if (candidate < 1 || candidate >= trials) continue;
    final candFraction = Fraction(candidate, trials).reduce();
    if (candFraction.equalsByValue(theoretical)) continue;
    observed = candidate;
    experimental = candFraction;
    break;
  }
  // If the loop exited without break, the fallback seed (expected + 1)
  // is used. (expected + 1) / trials reduces to num/den only if
  // (expected + 1) × den == num × trials, i.e. expected × den + den ==
  // expected × den, which is impossible. So the seed always satisfies
  // experimental ≠ theoretical.

  final theoreticalStr = theoretical.toCanonical();
  final experimentalStr = experimental.toCanonical();

  final askTheoretical = rand.nextBool();
  final correct = askTheoretical ? theoreticalStr : experimentalStr;
  final preamble = '${s.$1} $trials times and ${s.$4} $observed times.';
  final question = askTheoretical
      ? 'What is the theoretical probability of ${s.$5}?'
      : 'What is the experimental probability of ${s.$5}?';

  // Distractor pool. The PRIMARY misconception distractor is the
  // *other* probability — that's the central confusion this generator
  // tests for.
  final otherAnswer = askTheoretical ? experimentalStr : theoreticalStr;
  // Complement: when asked for theoretical, the complement experimental
  // ((trials-observed)/trials) is a believable wrong choice; when asked
  // for experimental, the complement theoretical ((den-num)/den) is.
  final complement = askTheoretical
      ? Fraction(trials - observed, trials).reduce().toCanonical()
      : Fraction(den - numerator, den).reduce().toCanonical();
  // Un-reduced form of the experimental (a common slip).
  final unreduced = '$observed/$trials';

  final candidates = <String>[
    otherAnswer,
    complement,
    unreduced,
    // Fallback: a different unit fraction. (No scenario has den == 3,
    // so 1/3 is always distinct from the theoretical.)
    '1/3',
  ];

  final out = <String>[];
  final seen = <String>{correct};
  for (final c in candidates) {
    if (out.length >= 3) break;
    if (seen.contains(c)) continue;
    final f = Fraction.tryParse(c);
    if (f != null && f.equalsByValue(Fraction.tryParse(correct)!)) continue;
    seen.add(c);
    out.add(c);
  }
  for (var i = 1; out.length < 3 && i < 10; i++) {
    final cand = '${i + 1}/${den + i}';
    if (seen.add(cand)) out.add(cand);
  }

  return GeneratedQuestion(
    conceptId: 'theoretical_vs_experimental',
    prompt: '$preamble $question',
    correctAnswer: correct,
    distractors: out.take(3).toList(),
    explanation: askTheoretical
        ? [
            'Theoretical probability depends on the device, not the data.',
            'For a fair $numerator-out-of-$den device, P = $theoreticalStr.',
          ]
        : [
            'Experimental P = successes ÷ trials.',
            '$observed / $trials reduced = $experimentalStr.',
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
