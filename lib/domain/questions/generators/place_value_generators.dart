import 'dart:math';

import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// Place-value & rounding generators.
///
/// All generators ask about a *digit at a place* — the answer is always a
/// single digit (0–9). Distractors come from the digit pool, with the
/// other digits of the same number biased in as misconception candidates.

// ─────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────

/// Place names indexed by position (0 = ones, 1 = tens, …, 6 = millions).
const _placeNames = [
  'ones',
  'tens',
  'hundreds',
  'thousands',
  'ten thousands',
  'hundred thousands',
  'millions',
];

/// Returns the digit at place [place] (0-indexed from the right) of [n].
int _digitAt(int n, int place) => (n ~/ _pow10(place)) % 10;

int _pow10(int p) {
  var v = 1;
  for (var i = 0; i < p; i++) {
    v *= 10;
  }
  return v;
}

/// Renders [n] with thousands separators (e.g. 12547 → "12,547").
String formatWithCommas(int n) {
  final s = n.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buffer.write(',');
    buffer.write(s[i]);
  }
  return buffer.toString();
}

/// Picks 3 distinct single-digit distractors from 0–9 that exclude
/// [correct]. The first slot prefers an "other digit of the source
/// number" misconception when distinct from the correct digit.
List<String> _digitDistractors(
  int correct, {
  required int sourceNumber,
  required int correctPlace,
  required Random rand,
}) {
  // Collect all other digits of sourceNumber as misconception candidates.
  var n = sourceNumber;
  final pool = <int>{};
  while (n > 0) {
    pool.add(n % 10);
    n ~/= 10;
  }
  pool.remove(correct);

  // Bias the strongest misconception (the digit at the *previous* place)
  // into slot 0 if it isn't equal to correct.
  final biasPlace = correctPlace == 0 ? correctPlace + 1 : correctPlace - 1;
  final biased = _digitAt(sourceNumber, biasPlace);

  final all = <int>{...pool};
  // Top up from the universal digit pool.
  for (var d = 0; d <= 9; d++) {
    if (d != correct) all.add(d);
  }

  // Order: biased first (if valid), then the rest of the from-source pool,
  // then universal digits.
  final ordered = <int>[];
  if (biased != correct) ordered.add(biased);
  for (final d in pool) {
    if (!ordered.contains(d)) ordered.add(d);
  }
  for (final d in all) {
    if (!ordered.contains(d)) ordered.add(d);
  }

  // Shuffle the *remainder* (after the biased one) so picks stay varied
  // across iterations.
  if (ordered.length > 1) {
    final tail = ordered.sublist(1)..shuffle(rand);
    ordered
      ..removeRange(1, ordered.length)
      ..addAll(tail);
  }

  return ordered.take(3).map((d) => d.toString()).toList();
}

// ─────────────────────────────────────────────────────────────────────────
// Place-value generators
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion _placeValueGen({
  required Random rand,
  required String conceptId,
  required int n,
  required int maxPlace, // inclusive — e.g. 1 for 2-digit (ones, tens)
}) {
  final place = rand.nextInt(maxPlace + 1); // 0..maxPlace
  final correct = _digitAt(n, place);
  final placeName = _placeNames[place];
  final formatted = maxPlace >= 3 ? formatWithCommas(n) : n.toString();

  return GeneratedQuestion(
    conceptId: conceptId,
    prompt: 'What digit is in the $placeName place of $formatted?',
    correctAnswer: correct.toString(),
    distractors: _digitDistractors(
      correct,
      sourceNumber: n,
      correctPlace: place,
      rand: rand,
    ),
    explanation: [
      'In $formatted, the $placeName place has $correct.',
    ],
  );
}

/// 2-digit place value: "What digit is in the (ones|tens) place of 47?"
GeneratedQuestion placeValue2digit(Random rand) {
  final n = 10 + rand.nextInt(90); // 10..99
  return _placeValueGen(
    rand: rand,
    conceptId: 'place_value_2digit',
    n: n,
    maxPlace: 1,
  );
}

/// 3-digit place value: ones / tens / hundreds.
GeneratedQuestion placeValue3digit(Random rand) {
  final n = 100 + rand.nextInt(900); // 100..999
  return _placeValueGen(
    rand: rand,
    conceptId: 'place_value_3digit',
    n: n,
    maxPlace: 2,
  );
}

/// Multi-digit place value: 4–7 digit numbers, places up to millions.
GeneratedQuestion placeValueMultidigit(Random rand) {
  // 4..7 digits — randomly chosen so each place name surfaces.
  final digits = 4 + rand.nextInt(4); // 4..7
  final lo = _pow10(digits - 1);
  final hi = _pow10(digits) - 1;
  final n = lo + rand.nextInt(hi - lo + 1);
  return _placeValueGen(
    rand: rand,
    conceptId: 'place_value_multidigit',
    n: n,
    maxPlace: digits - 1,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Rounding generators
// ─────────────────────────────────────────────────────────────────────────

/// Rounds [n] to the nearest multiple of 10^[place]. Standard half-up rule
/// (5 rounds up).
int _roundToPlace(int n, int place) {
  final factor = _pow10(place);
  final remainder = n % factor;
  final base = n - remainder;
  return remainder * 2 >= factor ? base + factor : base;
}

GeneratedQuestion _roundingGen({
  required Random rand,
  required String conceptId,
  required int n,
  required int place,
  required String placeLabel, // "10", "100", "thousands place", etc.
}) {
  final correct = _roundToPlace(n, place);
  final factor = _pow10(place);
  // Distractors: the next multiple in either direction, plus a "rounded
  // wrong direction" misconception.
  final misconception = correct == n - (n % factor)
      ? correct + factor
      : correct - factor;
  final formatted = n.toString().length > 3 ? formatWithCommas(n) : '$n';
  final correctStr = correct.toString().length > 3
      ? formatWithCommas(correct)
      : '$correct';
  final misconceptionStr = misconception.toString().length > 3
      ? formatWithCommas(misconception)
      : '$misconception';

  return GeneratedQuestion(
    conceptId: conceptId,
    prompt: 'Round $formatted to the nearest $placeLabel.',
    correctAnswer: correctStr,
    distractors: _roundingDistractors(
      correct: correct,
      misconception: misconception,
      factor: factor,
      rand: rand,
    ),
    explanation: [
      '$formatted is closer to $correctStr than to $misconceptionStr.',
    ],
  );
}

/// Distractors for rounding: the wrong-direction round + two near-by
/// multiples of the same factor.
List<String> _roundingDistractors({
  required int correct,
  required int misconception,
  required int factor,
  required Random rand,
}) {
  final candidates =
      <int>{
          misconception,
          correct + factor,
          if (correct - factor >= 0) correct - factor,
          correct + factor * 2,
        }
        ..remove(correct)
        ..removeWhere((v) => v < 0);
  while (candidates.length < 3) {
    candidates.add(correct + factor * (candidates.length + 2));
  }
  final list = candidates.toList()..shuffle(rand);
  return list.take(3).map((v) {
    return v.toString().length > 3 ? formatWithCommas(v) : v.toString();
  }).toList();
}

/// Round a 2-digit number to the nearest 10.
GeneratedQuestion roundTo10(Random rand) {
  // Avoid n that's already a multiple of 10 (trivial, no rounding needed).
  int n;
  do {
    n = 11 + rand.nextInt(89); // 11..99
  } while (n % 10 == 0);
  return _roundingGen(
    rand: rand,
    conceptId: 'round_to_10',
    n: n,
    place: 1,
    placeLabel: '10',
  );
}

/// Round a 3-digit number to the nearest 100.
GeneratedQuestion roundTo100(Random rand) {
  int n;
  do {
    n = 101 + rand.nextInt(899); // 101..999
  } while (n % 100 == 0);
  return _roundingGen(
    rand: rand,
    conceptId: 'round_to_100',
    n: n,
    place: 2,
    placeLabel: '100',
  );
}

/// Round a 4–6 digit number to a randomly chosen place (10, 100, 1000,
/// 10000, or 100000).
GeneratedQuestion roundMultidigitAnyPlace(Random rand) {
  final digits = 4 + rand.nextInt(3); // 4..6
  final lo = _pow10(digits - 1);
  final hi = _pow10(digits) - 1;
  // Place must be strictly less than the number's digit count.
  final place = 1 + rand.nextInt(digits - 1); // 1..(digits-1)
  int n;
  do {
    n = lo + rand.nextInt(hi - lo + 1);
  } while (n % _pow10(place) == 0);
  final placeLabel = switch (place) {
    1 => '10',
    2 => '100',
    3 => '1,000',
    4 => '10,000',
    5 => '100,000',
    _ => throw StateError('unsupported place: $place'),
  };
  return _roundingGen(
    rand: rand,
    conceptId: 'round_multidigit_any_place',
    n: n,
    place: place,
    placeLabel: placeLabel,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// compare_2digit / compare_3digit / compare_multidigit
// ─────────────────────────────────────────────────────────────────────────

/// Builds a "Which is bigger: $a or $b?" MC. Same shape as
/// `compare_fractions_*` — the kid picks one of the two displayed
/// numbers (or "They are equal", which is always wrong here because we
/// keep a ≠ b).
GeneratedQuestion _compareIntsGen({
  required String conceptId,
  required int a,
  required int b,
}) {
  assert(a != b, 'compare generators require distinct inputs');
  final aStr = formatWithCommas(a);
  final bStr = formatWithCommas(b);
  final correct = a > b ? aStr : bStr;
  final wrong = a > b ? bStr : aStr;
  // Misconception slot: the difference (kid subtracted instead of compared).
  // Falls back to sum when difference would dup an existing choice — e.g.
  // for (10, 5) where wrong = |a − b| = 5.
  final diff = (a - b).abs();
  final sum = a + b;
  final diffStr = formatWithCommas(diff);
  final sumStr = formatWithCommas(sum);
  final misconception = (diffStr == correct || diffStr == wrong)
      ? sumStr
      : diffStr;
  return GeneratedQuestion(
    conceptId: conceptId,
    prompt: 'Which is bigger: $aStr or $bStr?',
    correctAnswer: correct,
    distractors: <String>[wrong, 'They are equal', misconception],
    explanation: [
      'Line up the digits and compare the leftmost place that differs.',
      '$correct is bigger than $wrong.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

/// "Which is bigger: 47 or 52?" → "52". 2-digit ∈ [10, 99].
GeneratedQuestion compare2digit(Random rand) {
  final a = rand.nextInt(90) + 10; // 10..99
  int b;
  do {
    b = rand.nextInt(90) + 10;
  } while (b == a);
  return _compareIntsGen(conceptId: 'compare_2digit', a: a, b: b);
}

/// "Which is bigger: 472 or 521?" → "521". 3-digit ∈ [100, 999].
GeneratedQuestion compare3digit(Random rand) {
  final a = rand.nextInt(900) + 100; // 100..999
  int b;
  do {
    b = rand.nextInt(900) + 100;
  } while (b == a);
  return _compareIntsGen(conceptId: 'compare_3digit', a: a, b: b);
}

/// "Which is bigger: 47,200 or 47,500?" 4–7 digits each. Operands often
/// share their leading digits so the kid actually has to scan past them
/// — picks a, b within the same order of magnitude 70% of the time.
GeneratedQuestion compareMultidigit(Random rand) {
  final digits = rand.nextInt(4) + 4; // 4..7
  final lo = _pow10(digits - 1);
  final hi = _pow10(digits) - 1;
  final a = lo + rand.nextInt(hi - lo + 1);
  int b;
  do {
    final sameMag = rand.nextInt(10) < 7;
    if (sameMag) {
      b = lo + rand.nextInt(hi - lo + 1);
    } else {
      final otherDigits = rand.nextInt(4) + 4;
      final lo2 = _pow10(otherDigits - 1);
      final hi2 = _pow10(otherDigits) - 1;
      b = lo2 + rand.nextInt(hi2 - lo2 + 1);
    }
  } while (b == a);
  return _compareIntsGen(conceptId: 'compare_multidigit', a: a, b: b);
}

// ─────────────────────────────────────────────────────────────────────────
// place_value_relationship_10x (Grade 5)
// ─────────────────────────────────────────────────────────────────────────

/// "In 770, how many times greater is the value of the leftmost 7 than
/// the rightmost 7?" → 10. Builds a number with a single repeated
/// non-zero digit and zeros elsewhere, gap k ∈ [1, 3]. Tests CCSS
/// 5.NBT.A.1.
GeneratedQuestion placeValueRelationship10x(Random rand) {
  final d = rand.nextInt(9) + 1; // 1..9
  final k = rand.nextInt(3) + 1; // 1..3
  final pRight = rand.nextInt(2); // 0 or 1
  final pLeft = pRight + k;
  // Build digit string left-to-right: position pLeft is leftmost.
  final buf = StringBuffer();
  for (var pos = pLeft; pos >= 0; pos--) {
    buf.write(pos == pLeft || pos == pRight ? d : 0);
  }
  final n = buf.toString();
  final answer = _pow10(k);

  return GeneratedQuestion(
    conceptId: 'place_value_relationship_10x',
    prompt:
        'In $n, how many times greater is the value of the leftmost $d '
        'than the rightmost $d?',
    correctAnswer: '$answer',
    distractors: integerDistractorsWith(
      answer,
      rand,
      // Misconception: gave k × 10 instead of 10^k (so for k=3 says 30).
      misconception: k * 10,
    ),
    explanation: [
      'Each place is 10 times the place to its right.',
      // ignore: no_adjacent_strings_in_list — single line wrapped for length
      'The two ${d}s are $k place${k == 1 ? '' : 's'} apart, so the left '
          'value is 10^$k = $answer times the right value.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// powers_of_10 (Grade 5)
// ─────────────────────────────────────────────────────────────────────────

/// Three shapes covering CCSS 5.NBT.A.2 "multiply/divide by powers of 10":
///   * "What is 10^$k?" → 10^k (k ∈ [1, 5])
///   * "$a × 10^$k = ?" → a × 10^k (a ∈ [2, 9], k ∈ [1, 4])
///   * "$N ÷ 10^$k = ?" → N ÷ 10^k (N generated as a × 10^k for exact div)
GeneratedQuestion powersOf10(Random rand) {
  final shape = rand.nextInt(3);
  late int answer;
  late String prompt;
  late int misconception;
  late List<String> explanation;
  switch (shape) {
    case 0:
      final k = rand.nextInt(5) + 1; // 1..5
      answer = _pow10(k);
      prompt = 'What is 10^$k?';
      misconception = 10 * k; // kid does 10 × k instead of 10^k
      explanation = [
        '10^$k = 1 followed by $k zero${k == 1 ? '' : 's'}.',
        '10^$k = $answer.',
      ];
    case 1:
      final a = rand.nextInt(8) + 2; // 2..9
      final k = rand.nextInt(4) + 1; // 1..4
      answer = a * _pow10(k);
      prompt = '$a × 10^$k = ?';
      misconception = a * k;
      explanation = [
        // ignore: no_adjacent_strings_in_list — single line wrapped for length
        'Multiplying by 10^$k shifts the digits $k '
            'place${k == 1 ? '' : 's'} to the left.',
        '$a × 10^$k = $answer.',
      ];
    default:
      final a = rand.nextInt(8) + 2; // 2..9
      final k = rand.nextInt(4) + 1; // 1..4
      final n = a * _pow10(k);
      answer = a;
      prompt = '$n ÷ 10^$k = ?';
      // Misconception: kid shifted the decimal the wrong way.
      misconception = a * _pow10(2 * k);
      explanation = [
        // ignore: no_adjacent_strings_in_list — single line wrapped for length
        'Dividing by 10^$k shifts the digits $k '
            'place${k == 1 ? '' : 's'} to the right.',
        '$n ÷ 10^$k = $answer.',
      ];
  }
  return GeneratedQuestion(
    conceptId: 'powers_of_10',
    prompt: prompt,
    correctAnswer: '$answer',
    distractors: integerDistractorsWith(
      answer,
      rand,
      misconception: misconception,
    ),
    explanation: explanation,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// expanded_form_3digit (Grade 2)
// ─────────────────────────────────────────────────────────────────────────

/// "Write 472 in expanded form." → "400 + 70 + 2". Re-rolls until all
/// three digits are non-zero so the expansion has exactly three terms.
GeneratedQuestion expandedForm3digit(Random rand) {
  int n;
  do {
    n = rand.nextInt(900) + 100; // 100..999
  } while (n % 10 == 0 || (n ~/ 10) % 10 == 0);
  final hundreds = n ~/ 100;
  final tens = (n ~/ 10) % 10;
  final ones = n % 10;
  final correct = '${hundreds * 100} + ${tens * 10} + $ones';
  final distractors = <String>[
    // Misconception: wrote raw digits without place value.
    '$hundreds + $tens + $ones',
    // Misconception: shifted by one place.
    '${hundreds * 10} + $tens + $ones',
    // Misconception: dropped tens place.
    '${hundreds * 100} + $ones',
  ];

  return GeneratedQuestion(
    conceptId: 'expanded_form_3digit',
    prompt: 'Write $n in expanded form.',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      '$n has $hundreds hundreds, $tens tens, and $ones ones.',
      '= ${hundreds * 100} + ${tens * 10} + $ones.',
    ],
    answerFormat: AnswerFormat.string,
  );
}
