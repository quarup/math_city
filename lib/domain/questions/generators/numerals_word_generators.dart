import 'dart:math';

import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/generators/place_value_extra_generators.dart'
    show numberToWords;
import 'package:math_city/domain/questions/word_problems/word_problem_framework.dart';

/// K read/write numerals (0–20) + a batch of word-problem generators that
/// CCSS treats as dataset-sourced but which can be templated cleanly:
/// `interpret_remainder_word`, `fraction_word_problems`,
/// `multistep_ratio_word`, `rationals_four_op_word`,
/// `word_problem_two_step_eq`, `system_word_problem`.

// ─────────────────────────────────────────────────────────────────────────
// read_numerals_0_20 (K) — words → MC over digit strings
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion readNumerals0to20(Random rand) {
  final n = rand.nextInt(21); // 0..20
  final correct = '$n';
  final words = numberToWords(n);
  // Distractor strategy: nearby numbers in [0, 20], plus reversed digits
  // for the two-digit cases (no-op for single-digit n).
  final candidates = <String>{};
  // Off-by-1, off-by-10, off-by-2.
  for (final delta in [-1, 1, -2, 2, -10, 10]) {
    final v = n + delta;
    if (v >= 0 && v <= 99) candidates.add('$v');
  }
  // Reverse digits (only meaningful for 10..20).
  if (n >= 10) {
    candidates.add('${n % 10}${n ~/ 10}');
  }
  candidates.remove(correct);
  final list = candidates.toList()..shuffle(rand);
  return GeneratedQuestion(
    conceptId: 'read_numerals_0_20',
    prompt: 'Which number is “$words”?',
    correctAnswer: correct,
    distractors: list.take(3).toList(),
    explanation: ['"$words" is the number $correct.'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// write_numerals_0_20 (K) — "How do you write 17?" → MC over word strings
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion writeNumerals0to20(Random rand) {
  final n = rand.nextInt(21); // 0..20
  final correct = numberToWords(n);
  // Distractor pool: word forms of nearby numbers.
  final pool = <String>{};
  for (final delta in [-1, 1, -2, 2, -10, 10]) {
    final v = n + delta;
    if (v >= 0 && v <= 99) pool.add(numberToWords(v));
  }
  pool.remove(correct);
  final list = pool.toList()..shuffle(rand);
  return GeneratedQuestion(
    conceptId: 'write_numerals_0_20',
    prompt: 'How do you write the number $n in words?',
    correctAnswer: correct,
    distractors: list.take(3).toList(),
    explanation: ['$n is written as "$correct".'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// interpret_remainder_word (G4)
// ─────────────────────────────────────────────────────────────────────────

/// Three remainder-interpretation flavors (CCSS 4.OA.A.3):
///   * "How many full ___?" → answer = quotient (drop the remainder)
///   * "How many ___ are needed?" → answer = quotient + 1 (round up)
///   * "How many leftover ___?" → answer = remainder
GeneratedQuestion interpretRemainderWord(Random rand) {
  final divisor = rand.nextInt(8) + 3; // 3..10
  final quotient = rand.nextInt(8) + 3; // 3..10
  final remainder = rand.nextInt(divisor - 1) + 1; // 1..(divisor-1)
  final dividend = divisor * quotient + remainder;
  final flavor = rand.nextInt(3);
  final name = pickRandom(wordProblemNames, rand);

  String prompt;
  int correct;
  List<String> explanation;
  int misconception;
  switch (flavor) {
    case 0: // drop
      prompt =
          '$name has $dividend cookies. Each box holds $divisor cookies. '
          'How many FULL boxes can $name fill?';
      correct = quotient;
      misconception = quotient + 1;
      explanation = [
        '$dividend ÷ $divisor = $quotient with $remainder left over.',
        'Only $quotient boxes are completely full.',
      ];
    case 1: // round up
      prompt =
          '$dividend students go on a field trip. Each van holds $divisor '
          'students. How many vans are NEEDED?';
      correct = quotient + 1;
      misconception = quotient;
      explanation = [
        '$dividend ÷ $divisor = $quotient with $remainder left over.',
        'The leftover $remainder students still need a van — $correct total.',
      ];
    default: // remainder
      prompt =
          '$name bakes $dividend cookies and packs them into bags of '
          '$divisor. How many cookies are LEFT OVER?';
      correct = remainder;
      misconception = quotient;
      explanation = [
        '$dividend ÷ $divisor = $quotient with $remainder left over.',
        'The leftover is $remainder cookies.',
      ];
  }
  return GeneratedQuestion(
    conceptId: 'interpret_remainder_word',
    prompt: prompt,
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      misconception: misconception,
    ),
    explanation: explanation,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// fraction_word_problems (G5) — fraction +/− framed as a story
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion fractionWordProblems(Random rand) {
  // Generate "a/d + b/d = (a+b)/d" or "a/d − b/d = (a−b)/d" with the same
  // denominator so kids only have to deal with the named arithmetic.
  final d = [2, 3, 4, 5, 6, 8][rand.nextInt(6)];
  final isAdd = rand.nextBool();
  late int a;
  late int b;
  late int resultNum;
  if (isAdd) {
    a = rand.nextInt(d - 1) + 1; // 1..d-1
    b = rand.nextInt(d - 1) + 1;
    resultNum = a + b;
  } else {
    a = rand.nextInt(d - 1) + 2; // 2..d-1 (force ≥ 2 so b can be ≥ 1)
    if (a == 1) a = 2;
    b = rand.nextInt(a - 1) + 1; // 1..a-1
    resultNum = a - b;
  }
  final name = pickRandom(wordProblemNames, rand);
  late String prompt;
  late String correct;
  late int misNum;
  if (isAdd) {
    prompt =
        '$name eats $a/$d of a pizza. Then $name eats $b/$d more. '
        'How much pizza did $name eat in all?';
    correct = '$resultNum/$d';
    misNum = a + b + d; // "added the denominators too"
  } else {
    prompt =
        '$name has $a/$d of a pizza. $name eats $b/$d of the pizza. '
        'How much pizza is left?';
    correct = '$resultNum/$d';
    misNum = a - b - 1; // off-by-one in subtraction
    if (misNum < 0) misNum = 0;
  }
  // 4 distinct distractor strings around the correct fraction shape.
  final pool = <String>{
    '${a + b}/${2 * d}', // added both numerator and denominator
    '$a/$d', // gave the first quantity
    '$b/$d', // gave the second
    '${resultNum + 1}/$d', // off-by-one
    if (resultNum >= 1) '${resultNum - 1}/$d',
    '$misNum/$d',
  }..remove(correct);
  final list = pool.toList()..shuffle(rand);
  return GeneratedQuestion(
    conceptId: 'fraction_word_problems',
    prompt: prompt,
    correctAnswer: correct,
    distractors: list.take(3).toList(),
    explanation: [
      if (isAdd)
        '$a/$d + $b/$d = ${a + b}/$d'
      else
        '$a/$d − $b/$d = ${a - b}/$d',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// multistep_ratio_word (G7) — unit-rate or scaling word problem
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion multistepRatioWord(Random rand) {
  final name = pickRandom(wordProblemNames, rand);
  final kind = rand.nextInt(2);
  if (kind == 0) {
    // d = r × t  (distance = rate × time)
    final rate = rand.nextInt(40) + 30; // 30..69 mph
    final time = rand.nextInt(4) + 2; // 2..5 hours
    final correct = rate * time;
    return GeneratedQuestion(
      conceptId: 'multistep_ratio_word',
      prompt:
          '$name drives at $rate miles per hour for $time hours. '
          'How many miles does $name drive?',
      correctAnswer: '$correct',
      distractors: integerDistractorsWith(
        correct,
        rand,
        misconception: rate + time, // added instead of multiplied
      ),
      explanation: ['distance = rate × time = $rate × $time = $correct mi.'],
    );
  } else {
    // unit-pricing scaling: "n items cost $p, how much for m items?"
    final small = rand.nextInt(4) + 2; // 2..5
    final pricePerSmall = rand.nextInt(4) + 1; // 1..4 dollars
    final smallCost = small * pricePerSmall;
    final scale = rand.nextInt(4) + 2; // 2..5 multiplier
    final big = small * scale;
    final correct = pricePerSmall * big;
    return GeneratedQuestion(
      conceptId: 'multistep_ratio_word',
      prompt:
          '$small apples cost \$$smallCost. '
          'At the same price each, how much do $big apples cost in dollars?',
      correctAnswer: '$correct',
      distractors: integerDistractorsWith(
        correct,
        rand,
        misconception: smallCost + scale,
      ),
      explanation: [
        'Price per apple: \$$smallCost ÷ $small = \$$pricePerSmall.',
        '$big apples cost $big × \$$pricePerSmall = \$$correct.',
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// rationals_four_op_word (G7) — temperature/elevation word problem
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion rationalsFourOpWord(Random rand) {
  final kind = rand.nextInt(2);
  if (kind == 0) {
    // Temperature change.
    final startTemp = rand.nextInt(31) - 10; // -10..20
    final delta = rand.nextInt(20) - 10; // -10..9
    final actualDelta = delta == 0 ? 5 : delta;
    final correct = startTemp + actualDelta;
    final action = actualDelta >= 0
        ? 'rises by $actualDelta'
        : 'falls by ${-actualDelta}';
    return GeneratedQuestion(
      conceptId: 'rationals_four_op_word',
      prompt:
          'The temperature is ${_signed(startTemp)}°C in the morning. '
          'By noon it $action degrees. What is the temperature at noon, in °C?',
      correctAnswer: '$correct',
      distractors: integerDistractorsWith(
        correct,
        rand,
        // Misconception: subtracted instead of added.
        misconception: startTemp - actualDelta,
      ),
      explanation: ['$startTemp + ${_signed(actualDelta)} = $correct.'],
    );
  } else {
    // Elevation.
    final startElev = rand.nextInt(20) - 5; // -5..14
    final descent = rand.nextInt(15) + 5; // 5..19
    final correct = startElev - descent;
    return GeneratedQuestion(
      conceptId: 'rationals_four_op_word',
      prompt:
          'A submarine is at ${_signed(startElev)} m. '
          'It dives $descent m. What is its new depth, in meters?',
      correctAnswer: '$correct',
      distractors: integerDistractorsWith(
        correct,
        rand,
        misconception: startElev + descent, // added instead of subtracted
      ),
      explanation: ['$startElev − $descent = $correct.'],
    );
  }
}

String _signed(int n) => n < 0 ? '−${-n}' : '$n';

// ─────────────────────────────────────────────────────────────────────────
// word_problem_two_step_eq (G7) — story → solve px + q = r
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion wordProblemTwoStepEq(Random rand) {
  final name = pickRandom(wordProblemNames, rand);
  // Build a clean px + q = r with integer x ∈ [2, 9].
  final x = rand.nextInt(8) + 2; // 2..9
  final p = rand.nextInt(4) + 2; // 2..5 (price per item)
  final q = rand.nextInt(8) + 2; // 2..9 (fixed fee)
  final r = p * x + q;
  return GeneratedQuestion(
    conceptId: 'word_problem_two_step_eq',
    prompt:
        '$name buys some apples at \$$p each, plus a \$$q delivery fee. '
        'The total cost is \$$r. How many apples did $name buy?',
    correctAnswer: '$x',
    distractors: integerDistractorsWith(
      x,
      rand,
      // Misconception: divided total without subtracting fee.
      misconception: r ~/ p,
    ),
    explanation: [
      'Let x = number of apples. Then ${p}x + $q = $r.',
      '${p}x = ${r - q}',
      'x = ${r - q} ÷ $p = $x.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// system_word_problem (G8) — sum & difference of two unknowns
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion systemWordProblem(Random rand) {
  // Two unknowns a > b > 0 with answer-form "the larger number is $a".
  // Sum s = a + b, difference d = a − b. Generate distinct positive a, b.
  late int a;
  late int b;
  do {
    a = rand.nextInt(28) + 12; // 12..39
    b = rand.nextInt(a - 2) + 2; // 2..(a-1)
  } while (a == b || a + b > 50);
  final sum = a + b;
  final diff = a - b;
  // Pick which one we ask for.
  final askLarger = rand.nextBool();
  final correct = askLarger ? a : b;
  return GeneratedQuestion(
    conceptId: 'system_word_problem',
    prompt:
        'Two numbers add to $sum. Their difference is $diff. '
        'What is the ${askLarger ? "larger" : "smaller"} number?',
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      // Misconception: gave the other number.
      misconception: askLarger ? b : a,
    ),
    explanation: [
      'larger = (sum + diff) / 2 = ($sum + $diff) / 2 = $a.',
      'smaller = (sum − diff) / 2 = ($sum − $diff) / 2 = $b.',
    ],
  );
}
