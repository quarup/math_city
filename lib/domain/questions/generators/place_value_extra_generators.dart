import 'dart:math';

import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// K-G5 place-value and algebra-property fill-in. Text-only single-integer
/// or MC-over-digit-strings answers.

// ─────────────────────────────────────────────────────────────────────────
// Internal helpers
// ─────────────────────────────────────────────────────────────────────────

List<String> _distinctStrings(String correct, List<String> candidates) {
  final out = <String>[];
  final seen = <String>{correct};
  for (final c in candidates) {
    if (out.length >= 3) break;
    if (seen.add(c)) out.add(c);
  }
  // Fallback: if [correct] parses as int, fill with off-by-N ints.
  final asInt = int.tryParse(correct);
  if (asInt != null) {
    for (var k = 1; out.length < 3 && k < 200; k++) {
      for (final delta in <int>[k, -k]) {
        final v = asInt + delta;
        if (v < 0) continue;
        final s = '$v';
        if (seen.add(s)) out.add(s);
        if (out.length >= 3) break;
      }
    }
  }
  return out.take(3).toList();
}

const _onesWords = [
  'zero',
  'one',
  'two',
  'three',
  'four',
  'five',
  'six',
  'seven',
  'eight',
  'nine',
  'ten',
  'eleven',
  'twelve',
  'thirteen',
  'fourteen',
  'fifteen',
  'sixteen',
  'seventeen',
  'eighteen',
  'nineteen',
];

const _tensWords = [
  '',
  '',
  'twenty',
  'thirty',
  'forty',
  'fifty',
  'sixty',
  'seventy',
  'eighty',
  'ninety',
];

String _belowThousand(int value) {
  assert(value >= 0 && value < 1000, 'value out of range: $value');
  if (value == 0) return '';
  var n = value;
  final parts = <String>[];
  if (n >= 100) {
    parts.add('${_onesWords[n ~/ 100]} hundred');
    n %= 100;
  }
  if (n >= 20) {
    if (n % 10 == 0) {
      parts.add(_tensWords[n ~/ 10]);
    } else {
      parts.add('${_tensWords[n ~/ 10]}-${_onesWords[n % 10]}');
    }
  } else if (n > 0) {
    parts.add(_onesWords[n]);
  }
  return parts.join(' ');
}

/// English number-name for `n ∈ [0, 999_999_999]`. Uses hyphenated compound
/// words ("twenty-three") and singular thousand/million groupings.
String numberToWords(int n) {
  if (n == 0) return 'zero';
  final parts = <String>[];
  var remainder = n;
  if (remainder >= 1000000) {
    parts.add('${_belowThousand(remainder ~/ 1000000)} million');
    remainder %= 1000000;
  }
  if (remainder >= 1000) {
    parts.add('${_belowThousand(remainder ~/ 1000)} thousand');
    remainder %= 1000;
  }
  if (remainder > 0) {
    parts.add(_belowThousand(remainder));
  }
  return parts.join(' ');
}

// ─────────────────────────────────────────────────────────────────────────
// decompose_10 (K)
// ─────────────────────────────────────────────────────────────────────────

/// "10 = 3 + ?" — 50/50 with "10 = ? + 3", same arithmetic. Subset of
/// the make-10 partner-pair vocabulary; answer is always 10 − a.
GeneratedQuestion decompose10(Random rand) {
  final a = rand.nextInt(9) + 1; // 1..9
  final correct = 10 - a;
  final blankFirst = rand.nextBool();
  final prompt = blankFirst ? '10 = ___ + $a' : '10 = $a + ___';
  return GeneratedQuestion(
    conceptId: 'decompose_10',
    prompt: prompt,
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      misconception: 10 + a, // added instead of subtracted
    ),
    explanation: ['$a + $correct = 10'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// associative_add (G1)
// ─────────────────────────────────────────────────────────────────────────

/// "If (a + b) + c = s, then a + (b + c) = ?" — analog of commutative_add.
GeneratedQuestion associativeAdd(Random rand) {
  // Three single-digit addends so the sum stays ≤ 27 (a + b + c).
  late int a;
  late int b;
  late int c;
  int sum;
  do {
    a = rand.nextInt(9) + 1; // 1..9
    b = rand.nextInt(9) + 1;
    c = rand.nextInt(9) + 1;
    sum = a + b + c;
  } while (sum > 20);
  final leftFirst = rand.nextBool();
  final lhs = leftFirst ? '($a + $b) + $c' : '$a + ($b + $c)';
  final rhs = leftFirst ? '$a + ($b + $c)' : '($a + $b) + $c';
  return GeneratedQuestion(
    conceptId: 'associative_add',
    prompt: 'If $lhs = $sum, then $rhs = ?',
    correctAnswer: '$sum',
    distractors: integerDistractorsWith(
      sum,
      rand,
      misconception: sum + 1,
    ),
    explanation: [
      'Associative: regrouping addends gives the same sum.',
      '$lhs = $rhs = $sum.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// add_2digit_multiple_of_10 (G1)
// ─────────────────────────────────────────────────────────────────────────

/// "32 + 40 = ?" — 2-digit number plus a multiple of 10. Re-rolls until
/// the sum stays ≤ 99 so the kid doesn't hit a 3-digit answer they
/// haven't learned yet.
GeneratedQuestion add2digitMultipleOf10(Random rand) {
  late int a;
  late int b;
  do {
    a = rand.nextInt(89) + 10; // 10..98 (avoid 99 to leave room)
    final tens = rand.nextInt(8) + 1; // 10..80
    b = tens * 10;
  } while (a + b > 99);
  final correct = a + b;
  return GeneratedQuestion(
    conceptId: 'add_2digit_multiple_of_10',
    prompt: '$a + $b = ?',
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      misconception: correct + 10, // added one too many tens
    ),
    explanation: ['$a + $b = $correct'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// add_up_to_4_2digit (G2)
// ─────────────────────────────────────────────────────────────────────────

/// "12 + 23 + 14 + 35 = ?" — 3 or 4 two-digit addends. Each addend
/// in [10, 50] so the sum stays ≤ 200 (G2 territory).
GeneratedQuestion addUpTo4TwoDigit(Random rand) {
  final n = rand.nextInt(2) + 3; // 3 or 4 addends
  final addends = <int>[];
  for (var i = 0; i < n; i++) {
    addends.add(rand.nextInt(41) + 10); // 10..50
  }
  final correct = addends.reduce((a, b) => a + b);
  return GeneratedQuestion(
    conceptId: 'add_up_to_4_2digit',
    prompt: '${addends.join(' + ')} = ?',
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      misconception: correct + 10,
    ),
    explanation: ['${addends.join(' + ')} = $correct'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// add_sub_fluency_within_20 (G2)
// ─────────────────────────────────────────────────────────────────────────

/// Mixed +/− within 20 drilled together — the CCSS "fluently +/− within 20
/// from memory" skill. Single-digit operands for + (so the kid feels the
/// memorization); subtraction picks `a ∈ [10, 18], b ∈ [1, 9]` so the
/// answer stays in [1, 17].
GeneratedQuestion addSubFluencyWithin20(Random rand) {
  final isAdd = rand.nextBool();
  late int a;
  late int b;
  late int correct;
  late String op;
  if (isAdd) {
    op = '+';
    do {
      a = rand.nextInt(9) + 1; // 1..9
      b = rand.nextInt(9) + 1;
    } while (a + b > 18);
    correct = a + b;
  } else {
    op = '−';
    a = rand.nextInt(9) + 10; // 10..18
    b = rand.nextInt(9) + 1; // 1..9
    correct = a - b;
  }
  return GeneratedQuestion(
    conceptId: 'add_sub_fluency_within_20',
    prompt: '$a $op $b = ?',
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      // Misconception: did the other operation.
      misconception: isAdd ? (a - b).abs() : a + b,
    ),
    explanation: ['$a $op $b = $correct'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// read_write_3digit (G2)
// ─────────────────────────────────────────────────────────────────────────

/// "Which number is 'four hundred twenty-three'?" → MC of digit strings.
GeneratedQuestion readWrite3digit(Random rand) {
  int n;
  do {
    n = rand.nextInt(900) + 100; // 100..999
  } while (n % 100 == 0); // skip flat hundreds (trivial)
  final correct = '$n';
  final words = numberToWords(n);
  final h = n ~/ 100;
  final t = (n ~/ 10) % 10;
  final o = n % 10;
  // Distractor strategies (skip any that collide with the correct number):
  final candidates = <String>[
    '$o$t$h', // reversed
    '$h$o$t', // swapped tens / ones (forget that order)
    '$t$h$o', // swapped hundreds / tens
    '${h * 1000 + n % 100}', // injected zero ("four thousand twenty-three")
    '${h}0$t$o', // mis-heard the hundred as thousand
  ];
  return GeneratedQuestion(
    conceptId: 'read_write_3digit',
    prompt: 'Which number is “$words”?',
    correctAnswer: correct,
    distractors: _distinctStrings(correct, candidates),
    explanation: ['$h hundreds, $t tens, $o ones → $correct.'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// compare_3digit (G2)
// ─────────────────────────────────────────────────────────────────────────

/// "Which is greater: 437 or 473?" → MC: 437 / 473 / "They are equal".
GeneratedQuestion compare3digit(Random rand) {
  late int a;
  late int b;
  do {
    a = rand.nextInt(900) + 100;
    b = rand.nextInt(900) + 100;
  } while (a == b);
  final isGreater = rand.nextBool();
  final correct = isGreater ? max(a, b) : min(a, b);
  final wrong = isGreater ? min(a, b) : max(a, b);
  final candidates = <String>[
    '$wrong',
    '${a + b}', // gave the sum
    '${(a - b).abs()}', // gave the difference
  ];
  return GeneratedQuestion(
    conceptId: 'compare_3digit',
    prompt: 'Which number is ${isGreater ? "greater" : "smaller"}: $a or $b?',
    correctAnswer: '$correct',
    distractors: _distinctStrings('$correct', candidates),
    explanation: [
      'The ${isGreater ? "greater" : "smaller"} of $a and $b is $correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// read_write_multidigit (G4)
// ─────────────────────────────────────────────────────────────────────────

/// "Which number is 'twelve thousand four hundred sixty'?" — 4-6 digit
/// numbers. Skips multiples of 1000 to keep it non-trivial.
GeneratedQuestion readWriteMultidigit(Random rand) {
  final digits = rand.nextInt(3) + 4; // 4..6
  final lo = _pow10(digits - 1);
  final hi = _pow10(digits) - 1;
  int n;
  do {
    n = lo + rand.nextInt(hi - lo + 1);
  } while (n % 1000 == 0);
  final correct = '$n';
  final words = numberToWords(n);
  // Common misconceptions:
  // 1) Heard "thousand" as a separate digit-block, inserted 0 padding.
  // 2) Swap of last two digits.
  // 3) Off-by-power (×10 or ÷10).
  final candidates = <String>[
    '${n * 10}',
    '${n ~/ 10}',
    _swapLastTwo(n),
    _insertZeroAfterThousands(n, digits),
  ];
  return GeneratedQuestion(
    conceptId: 'read_write_multidigit',
    prompt: 'Which number is “$words”?',
    correctAnswer: correct,
    distractors: _distinctStrings(correct, candidates),
    explanation: ['Read the number-name straight off: $correct.'],
  );
}

String _swapLastTwo(int n) {
  final s = '$n';
  if (s.length < 2) return s;
  final last = s.substring(s.length - 1);
  final secondLast = s.substring(s.length - 2, s.length - 1);
  return s.substring(0, s.length - 2) + last + secondLast;
}

String _insertZeroAfterThousands(int n, int digits) {
  // Surfaces the "ten-thousand four hundred" → "100,400" parse error.
  // Pads an extra leading digit if needed; returns canonical (no commas).
  return '${n}0';
}

// ─────────────────────────────────────────────────────────────────────────
// compare_multidigit (G4)
// ─────────────────────────────────────────────────────────────────────────

/// "Which is greater: 12,345 or 12,453?" — 4-6 digit comparison. Includes
/// commas in the prompt for readability.
GeneratedQuestion compareMultidigit(Random rand) {
  final digits = rand.nextInt(3) + 4; // 4..6
  final lo = _pow10(digits - 1);
  final hi = _pow10(digits) - 1;
  late int a;
  late int b;
  do {
    a = lo + rand.nextInt(hi - lo + 1);
    b = lo + rand.nextInt(hi - lo + 1);
  } while (a == b);
  final isGreater = rand.nextBool();
  final correct = isGreater ? max(a, b) : min(a, b);
  final wrong = isGreater ? min(a, b) : max(a, b);
  return GeneratedQuestion(
    conceptId: 'compare_multidigit',
    prompt:
        'Which number is ${isGreater ? "greater" : "smaller"}: '
        '${_withCommas(a)} or ${_withCommas(b)}?',
    correctAnswer: '$correct',
    distractors: _distinctStrings('$correct', [
      '$wrong',
      '${correct + 1}',
      '${correct - 1}',
    ]),
    explanation: [
      'Compare digit by digit from the left.',
      '${_withCommas(correct)} is ${isGreater ? "greater" : "smaller"}.',
    ],
  );
}

String _withCommas(int n) {
  final s = '$n';
  final buf = StringBuffer();
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) buf.write(',');
    buf.write(s[i]);
  }
  return buf.toString();
}

// ─────────────────────────────────────────────────────────────────────────
// place_value_relationship_10x (G5)
// ─────────────────────────────────────────────────────────────────────────

/// "How many tens are in $n hundreds?" → 10n. Same shape walks up the
/// place-value ladder: hundreds → tens, thousands → hundreds, etc.
/// CCSS 5.NBT.A.1: "a digit in one place represents 10× as much as it
/// represents in the place to its right".
GeneratedQuestion placeValueRelationship10x(Random rand) {
  // Bigger place → smaller place. Pairs:
  // (hundreds → tens), (thousands → hundreds), (ten thousands → thousands).
  const pairs = [
    ('hundreds', 'tens'),
    ('thousands', 'hundreds'),
    ('ten thousands', 'thousands'),
  ];
  final pair = pairs[rand.nextInt(pairs.length)];
  final n = rand.nextInt(8) + 2; // 2..9
  final correct = n * 10;
  return GeneratedQuestion(
    conceptId: 'place_value_relationship_10x',
    prompt: 'How many ${pair.$2} are in $n ${pair.$1}?',
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      misconception: n, // gave the same digit
    ),
    explanation: [
      'Each ${pair.$1.replaceAll(RegExp(r's\$'), '')} is 10 ${pair.$2}.',
      '$n × 10 = $correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// powers_of_10 (G5)
// ─────────────────────────────────────────────────────────────────────────

/// "10^4 = ?" → 10000. Exponent ∈ [1, 6] so the answer fits without
/// stretching into the millions where the keypad gets awkward.
GeneratedQuestion powersOf10(Random rand) {
  final exp = rand.nextInt(6) + 1; // 1..6
  final correct = _pow10(exp);
  return GeneratedQuestion(
    conceptId: 'powers_of_10',
    prompt: '10^$exp = ?',
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      misconception: 10 * exp, // multiplied instead of repeated mult
    ),
    explanation: [
      '10^$exp means 10 multiplied by itself $exp times.',
      '10^$exp = $correct.',
    ],
  );
}

int _pow10(int exp) {
  var v = 1;
  for (var i = 0; i < exp; i++) {
    v *= 10;
  }
  return v;
}
