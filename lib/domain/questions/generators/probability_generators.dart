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
