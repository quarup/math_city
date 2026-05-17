import 'dart:math';

import 'package:math_city/domain/questions/decimal.dart';
import 'package:math_city/domain/questions/fraction.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// Decimal generators (Grades 4–5).
///
/// All math is done in scaled-integer form via [Decimal] — never as
/// `double` — so `0.1 + 0.2` is exactly `0.3` and answers are bit-stable.
/// Canonical answer strings have no trailing zeros: `0.5`, not `0.50`.
/// The answer-checker accepts equivalent forms (player typing `1.50` for
/// canonical `1.5`) as `equivalentNonCanonical`.

// ─────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────

/// Returns three distinct decimal-string distractors that don't equal
/// [correct] by value. Tries [candidates] first, then falls back to
/// nearby values.
List<String> _decimalDistractors(
  Decimal correct,
  List<String> candidates,
  Random rand,
) {
  final out = <String>[];
  final seen = <String>{correct.toCanonical()};
  bool tryAdd(String s) {
    if (seen.contains(s)) return false;
    final d = Decimal.tryParse(s);
    if (d != null && d.equalsByValue(correct)) return false;
    seen.add(s);
    out.add(s);
    return true;
  }

  for (final c in candidates) {
    if (out.length >= 3) break;
    tryAdd(c);
  }
  // Fallback: perturb the scaled value by ±1..±9 at the answer's own
  // scale. Stays in the same scale so the distractor "looks like" the
  // answer.
  for (var i = 0; i < 30 && out.length < 3; i++) {
    final delta = (rand.nextInt(9) + 1) * (rand.nextBool() ? 1 : -1);
    final perturbed = Decimal(correct.scaled + delta, correct.scale);
    tryAdd(perturbed.toCanonical());
  }
  // Extreme fallback so the contract is never violated.
  while (out.length < 3) {
    out.add('${out.length + 7}.${out.length + 1}');
  }
  return out.take(3).toList();
}

/// Returns three distinct whole-number-string distractors that differ
/// from [correct]. Used by generators (like `div_by_decimal`) whose
/// canonical answer is always a whole integer rendered as a bare string.
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

/// Shifts [d]'s decimal point by [places] (positive = left, i.e. divide
/// by 10^places; negative = right, multiply). Used to build "wrong place
/// value" misconception distractors.
Decimal _shiftPoint(Decimal d, int places) {
  if (places >= 0) {
    return Decimal(d.scaled, d.scale + places);
  }
  // places < 0: multiply by 10^|places|.
  var v = d.scaled;
  for (var i = 0; i < -places; i++) {
    v *= 10;
  }
  return Decimal(v, d.scale);
}

// ─────────────────────────────────────────────────────────────────────────
// Notation generators (Grade 4)
// ─────────────────────────────────────────────────────────────────────────

/// "Write N tenths as a decimal." → e.g. 7 → "0.7".
GeneratedQuestion decimalNotationTenths(Random rand) {
  final n = rand.nextInt(9) + 1; // 1..9
  final answer = Decimal(n, 1); // 0.n
  final correct = answer.toCanonical();

  final distractors = _decimalDistractors(
    answer,
    [
      // Misconception: wrote N as a whole number.
      '$n',
      // Misconception: treated as hundredths (off by one place).
      _shiftPoint(answer, 1).toCanonical(),
      // Shift the other way.
      _shiftPoint(answer, -1).toCanonical(),
    ],
    rand,
  );

  return GeneratedQuestion(
    conceptId: 'decimal_notation_tenths',
    prompt: 'Write $n tenths as a decimal.',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      '"N tenths" means N divided by 10.',
      '$n ÷ 10 = $correct.',
      'One digit after the point — the tenths place.',
    ],
    answerFormat: AnswerFormat.decimal,
  );
}

/// "Write N hundredths as a decimal." → e.g. 7 → "0.07", 35 → "0.35".
/// N ranges 1..99; the single-digit case is the key misconception
/// trap (7 hundredths is 0.07, not 0.7).
GeneratedQuestion decimalNotationHundredths(Random rand) {
  final n = rand.nextInt(99) + 1; // 1..99
  final answer = Decimal(n, 2); // 0.0n .. 0.99
  final correct = answer.toCanonical();

  final distractors = <String>[
    // Misconception: dropped the leading zero / shifted left
    // (read as tenths). For n=7 this is "0.7"; for n=35 this is "3.5".
    _shiftPoint(answer, -1).toCanonical(),
    // Misconception: wrote N as a whole number.
    '$n',
    // Off by one place in the other direction.
    _shiftPoint(answer, 1).toCanonical(),
  ];

  return GeneratedQuestion(
    conceptId: 'decimal_notation_hundredths',
    prompt: 'Write $n hundredths as a decimal.',
    correctAnswer: correct,
    distractors: _decimalDistractors(answer, distractors, rand),
    explanation: [
      '"N hundredths" means N divided by 100.',
      '$n ÷ 100 = $correct.',
      'Two digits after the point — the hundredths place.',
    ],
    answerFormat: AnswerFormat.decimal,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Comparison (Grade 4)
// ─────────────────────────────────────────────────────────────────────────

/// "Which is bigger: 0.45 or 0.5?" — answer is the larger of the two
/// strings (matches the existing `compare_fractions_*` shape, which
/// avoids the keypad-with-`<`/`>` UX problem).
///
/// 40% of the time one operand is at tenths and the other at hundredths,
/// to trip the classic "longer = bigger" misconception
/// (e.g. 0.45 vs 0.5).
GeneratedQuestion compareDecimalsHundredths(Random rand) {
  Decimal a;
  Decimal b;
  if (rand.nextDouble() < 0.4) {
    // Misconception bait: one tenths, one hundredths.
    final tenths = rand.nextInt(9) + 1; // 1..9
    final hundredthsTail = rand.nextInt(9) + 1; // 1..9
    // E.g. shorter = 0.4 (4 tenths), longer = 0.4N where N != 0 with
    // the hundredths digit picked so the magnitudes are NOT equal.
    final shorter = Decimal(tenths, 1);
    final longer = Decimal(tenths * 10 - hundredthsTail, 2);
    if (rand.nextBool()) {
      a = shorter;
      b = longer;
    } else {
      a = longer;
      b = shorter;
    }
  } else {
    // General: two random hundredths in [0.01, 0.99]. Re-roll on ties.
    do {
      a = Decimal(rand.nextInt(99) + 1, 2);
      b = Decimal(rand.nextInt(99) + 1, 2);
    } while (a.compareTo(b) == 0);
  }

  final aStr = a.toCanonical();
  final bStr = b.toCanonical();
  final correct = a.compareTo(b) > 0 ? aStr : bStr;
  final wrong = a.compareTo(b) > 0 ? bStr : aStr;

  return GeneratedQuestion(
    conceptId: 'compare_decimals_hundredths',
    prompt: 'Which is bigger: $aStr or $bStr?',
    correctAnswer: correct,
    distractors: <String>[
      // Primary misconception: pick the visually longer one.
      wrong,
      'They are equal',
      // "Both" wording, a kid sometimes picks the leftmost.
      'Neither',
    ],
    explanation: [
      'Pad both with zeros to the same length, then compare digit by digit.',
      '$correct is bigger.',
      'Tip: a "longer" decimal is not always bigger — 0.5 beats 0.45.',
    ],
    // answerFormat: string (default) — exact string match against the
    // two displayed values; no keypad symbol issues.
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Addition / subtraction (Grade 5)
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion _addSubDecimals({
  required String conceptId,
  required Decimal a,
  required Decimal b,
  required bool isAdd,
  required Random rand,
}) {
  final result = isAdd ? a + b : a - b;
  final op = isAdd ? '+' : '−';
  final correct = result.toCanonical();

  // Misconception distractors: treat as integers and concatenate the
  // scales (e.g. 1.25 + 0.4 → kid pads wrong and gets 1.29 instead of
  // 1.65). Also the opposite-op slip.
  final flipped = isAdd ? a - b : a + b;
  final candidates = <String>[
    flipped.toCanonical(),
    // "Treat as integers" trap: combine scaled values at min scale, not
    // max — i.e. ignore that one operand has fewer fractional digits.
    if (a.scale != b.scale)
      _badConcatDistractor(a, b, isAdd: isAdd).toCanonical(),
    // Off-by-1 in the smallest place of the answer.
    Decimal(result.scaled + 1, result.scale).toCanonical(),
    Decimal(result.scaled - 1, result.scale).toCanonical(),
  ];

  return GeneratedQuestion(
    conceptId: conceptId,
    prompt: '${a.toCanonical()} $op ${b.toCanonical()} = ?',
    correctAnswer: correct,
    distractors: _decimalDistractors(result, candidates, rand),
    explanation: [
      '${a.toCanonical()} $op ${b.toCanonical()}',
      'Line up the decimal points (pad with zeros if needed).',
      'Then ${isAdd ? "add" : "subtract"} like whole numbers.',
      'Result: $correct.',
    ],
    answerFormat: AnswerFormat.decimal,
  );
}

/// Builds the "treated as integers, didn't align" misconception result.
/// Concatenates the raw scaled values at the larger scale's slot count,
/// producing e.g. `1.25 + 0.4 → 1.29` (since "1.25 + 0.04" reads scaled
/// 125 + 4 = 129, kept at scale 2). For sub the same pattern.
Decimal _badConcatDistractor(Decimal a, Decimal b, {required bool isAdd}) {
  final maxScale = a.scale > b.scale ? a.scale : b.scale;
  // Bug: scaled values are added directly without padding the shorter
  // one. The integer math is at the operand's own scale.
  final s = isAdd ? a.scaled + b.scaled : a.scaled - b.scaled;
  return Decimal(s, maxScale);
}

/// `add_decimals`: a + b where each operand is in [0.01, 9.99] at
/// tenths or hundredths precision. Mixing scales (e.g. tenths + hundredths)
/// shows up ~half the time to exercise the alignment skill.
GeneratedQuestion addDecimals(Random rand) {
  final a = _pickAddSubOperand(rand);
  final b = _pickAddSubOperand(rand);
  return _addSubDecimals(
    conceptId: 'add_decimals',
    a: a,
    b: b,
    isAdd: true,
    rand: rand,
  );
}

/// `sub_decimals`: generate as `(a+b) − b` so the minuend is always at
/// least the subtrahend (no negative results).
GeneratedQuestion subDecimals(Random rand) {
  final smaller = _pickAddSubOperand(rand);
  final delta = _pickAddSubOperand(rand);
  final larger = smaller + delta;
  // Randomly subtract either operand from the sum.
  final Decimal a;
  final Decimal b;
  if (rand.nextBool()) {
    a = larger;
    b = smaller;
  } else {
    a = larger;
    b = delta;
  }
  return _addSubDecimals(
    conceptId: 'sub_decimals',
    a: a,
    b: b,
    isAdd: false,
    rand: rand,
  );
}

/// Picks a decimal in [0.01, 9.99] at either tenths (50%) or hundredths
/// (50%) precision.
Decimal _pickAddSubOperand(Random rand) {
  final tenths = rand.nextBool();
  if (tenths) {
    // 0.1 .. 9.9 in tenths.
    return Decimal(rand.nextInt(99) + 1, 1);
  }
  // 0.01 .. 9.99 in hundredths.
  return Decimal(rand.nextInt(999) + 1, 2);
}

// ─────────────────────────────────────────────────────────────────────────
// Multiplication (Grade 5)
// ─────────────────────────────────────────────────────────────────────────

/// `mult_decimal_by_whole`: e.g. `0.3 × 4 = 1.2`. Decimal operand in
/// [0.01, 9.9] with a non-zero fractional part; whole in [2, 9].
GeneratedQuestion multDecimalByWhole(Random rand) {
  // Pick a decimal that actually has a fractional part (re-roll if
  // canonicalisation collapses it to a whole number — the lesson is
  // specifically about decimal × whole).
  Decimal dec;
  do {
    final scale = rand.nextBool() ? 1 : 2;
    dec = scale == 1
        ? Decimal(rand.nextInt(99) + 1, 1) // 0.1..9.9
        : Decimal(rand.nextInt(990) + 1, 2); // 0.01..9.90
  } while (dec.scale == 0);
  final whole = rand.nextInt(8) + 2; // 2..9
  final result = dec * Decimal(whole, 0);
  final correct = result.toCanonical();

  // Misconception distractors:
  //   - off-by-one decimal shift (forgot to count fractional digits).
  //   - whole × whole answer, ignoring the point entirely.
  final candidates = <String>[
    _shiftPoint(result, -1).toCanonical(),
    _shiftPoint(result, 1).toCanonical(),
    '${dec.scaled * whole}',
    // ±1 in smallest place.
    Decimal(result.scaled + 1, result.scale).toCanonical(),
  ];

  // Display: present decimal × whole randomly as decimal × whole or
  // whole × decimal, since commutativity is in scope for this concept.
  final decFirst = rand.nextBool();
  final prompt = decFirst
      ? '${dec.toCanonical()} × $whole = ?'
      : '$whole × ${dec.toCanonical()} = ?';

  return GeneratedQuestion(
    conceptId: 'mult_decimal_by_whole',
    prompt: prompt,
    correctAnswer: correct,
    distractors: _decimalDistractors(result, candidates, rand),
    explanation: [
      if (decFirst)
        '${dec.toCanonical()} × $whole'
      else
        '$whole × ${dec.toCanonical()}',
      'Ignore the point: ${dec.scaled} × $whole = ${dec.scaled * whole}.',
      'Then put the point ${dec.scale} from the right.',
      'Result: $correct.',
    ],
    answerFormat: AnswerFormat.decimal,
  );
}

/// `mult_decimals`: e.g. `0.5 × 0.4 = 0.2`. Both operands at tenths or
/// hundredths with non-zero fractional parts; result scale ≤ 4.
/// Magnitudes kept small so the answer stays kid-friendly.
GeneratedQuestion multDecimals(Random rand) {
  // Re-roll if either operand canonicalises to a whole number — the
  // lesson is decimal × decimal, not whole × whole disguised.
  Decimal pickOperand() {
    Decimal d;
    do {
      final scale = rand.nextBool() ? 1 : 2;
      d = scale == 1
          ? Decimal(rand.nextInt(49) + 1, 1) // 0.1..4.9
          : Decimal(rand.nextInt(499) + 1, 2); // 0.01..4.99
    } while (d.scale == 0);
    return d;
  }

  final a = pickOperand();
  final b = pickOperand();
  final result = a * b;
  final correct = result.toCanonical();

  final candidates = <String>[
    // Misconception: shifted the point one place wrong.
    _shiftPoint(result, -1).toCanonical(),
    _shiftPoint(result, 1).toCanonical(),
    // Misconception: added the operands instead of multiplying.
    (a + b).toCanonical(),
    Decimal(result.scaled + 1, result.scale).toCanonical(),
  ];

  return GeneratedQuestion(
    conceptId: 'mult_decimals',
    prompt: '${a.toCanonical()} × ${b.toCanonical()} = ?',
    correctAnswer: correct,
    distractors: _decimalDistractors(result, candidates, rand),
    explanation: [
      '${a.toCanonical()} × ${b.toCanonical()}',
      'Ignore the points: ${a.scaled} × ${b.scaled} = ${a.scaled * b.scaled}.',
      'Digits after points: ${a.scale} + ${b.scale} = ${a.scale + b.scale}.',
      'Put the point that many spots from the right → $correct.',
    ],
    answerFormat: AnswerFormat.decimal,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Thousandths notation / comparison (Grade 5)
// ─────────────────────────────────────────────────────────────────────────

/// "Write N thousandths as a decimal." → e.g. 7 → "0.007", 123 → "0.123".
GeneratedQuestion decimalToThousandthsRead(Random rand) {
  final n = rand.nextInt(999) + 1; // 1..999
  final answer = Decimal(n, 3);
  final correct = answer.toCanonical();

  final distractors = <String>[
    // Misconception: dropped one or two leading zeros (read as hundredths
    // or tenths instead).
    _shiftPoint(answer, -1).toCanonical(),
    _shiftPoint(answer, -2).toCanonical(),
    // Misconception: wrote N as a whole number.
    '$n',
  ];

  return GeneratedQuestion(
    conceptId: 'decimal_to_thousandths_read',
    prompt: 'Write $n thousandths as a decimal.',
    correctAnswer: correct,
    distractors: _decimalDistractors(answer, distractors, rand),
    explanation: [
      '"N thousandths" means N divided by 1000.',
      '$n ÷ 1000 = $correct.',
      'Three digits after the point — the thousandths place.',
    ],
    answerFormat: AnswerFormat.decimal,
  );
}

/// "Which is bigger: 0.345 or 0.4?" Variant of
/// [compareDecimalsHundredths] extended to thousandths precision. Same
/// "longer = bigger" misconception bait when scales differ.
GeneratedQuestion compareDecimalsThousandths(Random rand) {
  Decimal a;
  Decimal b;
  if (rand.nextDouble() < 0.5) {
    // Misconception bait: mismatched scales. Pick the shorter at
    // tenths or hundredths and the longer at thousandths.
    final shorterScale = rand.nextBool() ? 1 : 2;
    final shorter = shorterScale == 1
        ? Decimal(rand.nextInt(9) + 1, 1) // 0.1..0.9
        : Decimal(rand.nextInt(99) + 1, 2); // 0.01..0.99
    Decimal longer;
    do {
      longer = Decimal(rand.nextInt(999) + 1, 3); // 0.001..0.999
    } while (longer.scale != 3 || longer.compareTo(shorter) == 0);
    if (rand.nextBool()) {
      a = shorter;
      b = longer;
    } else {
      a = longer;
      b = shorter;
    }
  } else {
    // General: two random thousandths.
    do {
      a = Decimal(rand.nextInt(999) + 1, 3);
      b = Decimal(rand.nextInt(999) + 1, 3);
    } while (a.compareTo(b) == 0);
  }

  final aStr = a.toCanonical();
  final bStr = b.toCanonical();
  final correct = a.compareTo(b) > 0 ? aStr : bStr;
  final wrong = a.compareTo(b) > 0 ? bStr : aStr;

  return GeneratedQuestion(
    conceptId: 'compare_decimals_thousandths',
    prompt: 'Which is bigger: $aStr or $bStr?',
    correctAnswer: correct,
    distractors: <String>[wrong, 'They are equal', 'Neither'],
    explanation: [
      'Pad both with zeros to the same length, then compare digit by digit.',
      '$correct is bigger.',
      'Tip: extra digits do not mean bigger — 0.4 beats 0.345.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Rounding decimals (Grade 5)
// ─────────────────────────────────────────────────────────────────────────

/// "Round 0.567 to the nearest tenth." → "0.6". Place ∈ {whole, tenths,
/// hundredths}. Uses round-half-away-from-zero (standard kid convention).
GeneratedQuestion roundDecimals(Random rand) {
  // Generate a decimal at thousandths precision in [0.001, 9.999].
  Decimal value;
  do {
    value = Decimal(rand.nextInt(9999) + 1, 3);
  } while (value.scale < 3); // ensure a thousandths digit actually exists

  // Pick the place to round to (smaller than the value's own scale so the
  // rounding is non-trivial).
  final placeOptions = <_RoundPlace>[
    const _RoundPlace(0, 'whole number'),
    const _RoundPlace(1, 'tenth'),
    const _RoundPlace(2, 'hundredth'),
  ];
  final place = placeOptions[rand.nextInt(placeOptions.length)];

  final rounded = _roundHalfAwayFromZero(value, place.scale);
  final correct = rounded.toCanonical();

  // Misconception: rounded in the wrong direction (truncate vs round up).
  final truncated = _truncate(value, place.scale);
  final flipped = truncated.compareTo(rounded) == 0
      // truncate == round → bump by one in the smallest place
      ? Decimal(rounded.scaled + 1, rounded.scale)
      : truncated;

  return GeneratedQuestion(
    conceptId: 'round_decimals',
    prompt: 'Round ${value.toCanonical()} to the nearest ${place.name}.',
    correctAnswer: correct,
    distractors: _decimalDistractors(
      rounded,
      <String>[
        flipped.toCanonical(),
        // Misconception: rounded to the wrong place (off by one).
        _roundHalfAwayFromZero(
          value,
          (place.scale - 1).clamp(0, 3),
        ).toCanonical(),
        // Truncated form.
        truncated.toCanonical(),
      ],
      rand,
    ),
    explanation: [
      'Look at the digit one place to the right of the ${place.name}.',
      'If that digit is 5 or more, round up; otherwise round down.',
      '${value.toCanonical()} → $correct.',
    ],
    answerFormat: AnswerFormat.decimal,
  );
}

class _RoundPlace {
  const _RoundPlace(this.scale, this.name);
  final int scale;
  final String name;
}

/// Rounds [v] to [targetScale] digits after the point using half-away-
/// from-zero.
Decimal _roundHalfAwayFromZero(Decimal v, int targetScale) {
  if (v.scale <= targetScale) return v;
  final factor = _intPow10(v.scale - targetScale);
  final scaled = v.scaled;
  // Half-away: divide and add 0.5 with the sign.
  final half = scaled >= 0 ? factor ~/ 2 : -(factor ~/ 2);
  final out = (scaled + half) ~/ factor;
  return Decimal(out, targetScale);
}

/// Truncates [v] toward zero to [targetScale] digits after the point.
Decimal _truncate(Decimal v, int targetScale) {
  if (v.scale <= targetScale) return v;
  final factor = _intPow10(v.scale - targetScale);
  return Decimal(v.scaled ~/ factor, targetScale);
}

int _intPow10(int n) {
  var x = 1;
  for (var i = 0; i < n; i++) {
    x *= 10;
  }
  return x;
}

// ─────────────────────────────────────────────────────────────────────────
// Division (Grades 5–6)
// ─────────────────────────────────────────────────────────────────────────

/// `div_decimal_by_whole`: "0.6 ÷ 3 = ?" → "0.2". Generated as
/// `quotient × divisor = dividend` so the result is always an exact
/// terminating decimal at the same scale as the quotient.
GeneratedQuestion divDecimalByWhole(Random rand) {
  Decimal quotient;
  do {
    final scale = rand.nextBool() ? 1 : 2;
    quotient = scale == 1
        ? Decimal(rand.nextInt(99) + 1, 1) // 0.1..9.9
        : Decimal(rand.nextInt(990) + 1, 2); // 0.01..9.90
  } while (quotient.scale == 0); // require a real fractional part
  final divisor = rand.nextInt(8) + 2; // 2..9
  final dividend = quotient * Decimal(divisor, 0);
  final correct = quotient.toCanonical();

  return GeneratedQuestion(
    conceptId: 'div_decimal_by_whole',
    prompt: '${dividend.toCanonical()} ÷ $divisor = ?',
    correctAnswer: correct,
    distractors: _decimalDistractors(
      quotient,
      <String>[
        // Misconception: wrong decimal-point shift.
        _shiftPoint(quotient, 1).toCanonical(),
        _shiftPoint(quotient, -1).toCanonical(),
        // Misconception: divided ignoring the point.
        '${dividend.scaled ~/ divisor}',
      ],
      rand,
    ),
    explanation: [
      '${dividend.toCanonical()} ÷ $divisor',
      'Divide as if no point: ${dividend.scaled} ÷ $divisor.',
      '= ${dividend.scaled ~/ divisor}. Put point in same spot → $correct.',
    ],
    answerFormat: AnswerFormat.decimal,
  );
}

/// `div_by_decimal`: "6 ÷ 0.3 = ?" → "20". Quotient is always a whole
/// number to keep results kid-friendly; divisor is a decimal at tenths
/// or hundredths precision with a non-zero fractional part.
GeneratedQuestion divByDecimal(Random rand) {
  Decimal divisor;
  do {
    final scale = rand.nextBool() ? 1 : 2;
    divisor = scale == 1
        ? Decimal(rand.nextInt(9) + 1, 1) // 0.1..0.9
        : Decimal(rand.nextInt(99) + 1, 2); // 0.01..0.99
  } while (divisor.scale == 0);
  final quotient = rand.nextInt(19) + 2; // 2..20
  final dividend = divisor * Decimal(quotient, 0);
  final correct = '$quotient';

  return GeneratedQuestion(
    conceptId: 'div_by_decimal',
    prompt: '${dividend.toCanonical()} ÷ ${divisor.toCanonical()} = ?',
    correctAnswer: correct,
    distractors: _wholeDistractors(
      quotient,
      <String>[
        // Misconception: forgot to shift; divided the raw integer parts.
        '${dividend.scaled ~/ divisor.scaled}',
        // Wrong shift direction (×10 / ÷10 of the answer).
        '${quotient * 10}',
        '${quotient > 10 ? quotient ~/ 10 : quotient + 10}',
      ],
      rand,
    ),
    explanation: [
      '${dividend.toCanonical()} ÷ ${divisor.toCanonical()}',
      'Shift the point in both by ${divisor.scale} so the divisor is whole.',
      'Then divide: ${dividend.scaled} ÷ ${divisor.scaled} = $correct.',
    ],
    // answerFormat: integer (default) — answer is always a whole number.
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Conversions (Grades 5–6)
// ─────────────────────────────────────────────────────────────────────────

/// `decimal_to_fraction`: "Write 0.25 as a fraction in lowest terms."
/// → "1/4". Picks decimals at hundredths so the un-reduced fraction is
/// N/100; answer is the reduced form. `AnswerShape.exactString` because
/// the lesson IS "in lowest terms".
GeneratedQuestion decimalToFraction(Random rand) {
  // Pick a hundredth in [0.01, 0.99] that actually reduces (so the
  // lesson exercises simplification rather than producing trivial N/100
  // half the time).
  Decimal value;
  Fraction reduced;
  do {
    value = Decimal(rand.nextInt(99) + 1, 2);
    final n = value.scaled;
    final d = _intPow10(value.scale);
    reduced = Fraction(n, d).reduce();
  } while (reduced.denominator == 100); // require non-trivial reduction
  final correct = reduced.toCanonical();

  // Misconception distractors:
  //  - the un-reduced N/100 form.
  //  - flipped numerator/denominator.
  //  - half-reduced (divide by 2 only).
  final unReduced = '${value.scaled}/${_intPow10(value.scale)}';
  final flipped = '${reduced.denominator}/${reduced.numerator}';
  final candidates = <String>[unReduced, flipped];

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
  // Fallback: small perturbations on numerator.
  for (var i = 1; out.length < 3 && i < 10; i++) {
    final cand = '${reduced.numerator + i}/${reduced.denominator}';
    if (seen.add(cand)) out.add(cand);
  }

  return GeneratedQuestion(
    conceptId: 'decimal_to_fraction',
    prompt: 'Write ${value.toCanonical()} as a fraction in lowest terms.',
    correctAnswer: correct,
    distractors: out.take(3).toList(),
    explanation: [
      '${value.toCanonical()} = ${value.scaled}/${_intPow10(value.scale)}.',
      'Reduce by the GCF → $correct.',
    ],
    answerFormat: AnswerFormat.fraction,
    answerShape: AnswerShape.exactString,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// Composite (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// `decimals_fluent_4ops`: mixed +/−/×/÷ practice for kids who already
/// have each operation separately. Picks one of the four underlying
/// generators uniformly and returns its question, retagged with the
/// composite concept ID so proficiency tracks the mixed-practice skill.
GeneratedQuestion decimalsFluent4ops(Random rand) {
  final pick = rand.nextInt(4);
  final inner = switch (pick) {
    0 => addDecimals(rand),
    1 => subDecimals(rand),
    2 => multDecimals(rand),
    _ => divByDecimal(rand),
  };
  return GeneratedQuestion(
    conceptId: 'decimals_fluent_4ops',
    prompt: inner.prompt,
    correctAnswer: inner.correctAnswer,
    distractors: inner.distractors,
    explanation: inner.explanation,
    answerFormat: inner.answerFormat,
    answerShape: inner.answerShape,
    diagram: inner.diagram,
  );
}

/// `fraction_to_decimal`: "Write 3/4 as a decimal." → "0.75". Only
/// fractions with terminating decimal expansions (denominators whose
/// prime factors are 2 and 5 only) are generated.
GeneratedQuestion fractionToDecimal(Random rand) {
  // Curated list of denominators whose decimal expansion terminates and
  // stays within ≤ 4 decimal places: 2, 4, 5, 8, 10, 20, 25, 50.
  const terminatingDenominators = [2, 4, 5, 8, 10, 20, 25, 50];
  final denominator =
      terminatingDenominators[rand.nextInt(terminatingDenominators.length)];
  // Pick a proper numerator (so the decimal stays < 1) and re-roll if
  // the fraction reduces to a whole number (e.g. 4/4) or to a simpler
  // form already covered by an easier denominator.
  int numerator;
  do {
    numerator = rand.nextInt(denominator - 1) + 1; // 1..denom-1
  } while (Fraction(numerator, denominator).reduce().denominator == 1);

  // Compute decimal expansion exactly via scaled integers. Multiply
  // numerator by 10^4 (max needed for these denominators), divide by
  // denominator, build a Decimal at that scale — Decimal's canonical
  // form will strip the trailing zeros.
  const workingScale = 4;
  final scaled = (numerator * _intPow10(workingScale)) ~/ denominator;
  final answer = Decimal(scaled, workingScale);
  final correct = answer.toCanonical();

  // Misconception distractors:
  //  - concatenated form: "0.N/D" combined → "0.numdenom" (the classic
  //    "3/4 = 0.34" mistake). Use the digits concatenated.
  //  - off-by-one place.
  final concat = '0.$numerator$denominator';
  final candidates = <String>[
    concat,
    _shiftPoint(answer, 1).toCanonical(),
    _shiftPoint(answer, -1).toCanonical(),
    // "Backwards": denominator/numerator interpretation.
    Decimal(
      (denominator * _intPow10(workingScale)) ~/ numerator,
      workingScale,
    ).toCanonical(),
  ];

  return GeneratedQuestion(
    conceptId: 'fraction_to_decimal',
    prompt: 'Write $numerator/$denominator as a decimal.',
    correctAnswer: correct,
    distractors: _decimalDistractors(answer, candidates, rand),
    explanation: [
      '$numerator/$denominator means $numerator ÷ $denominator.',
      'Long-divide (or scale to a power-of-10 denominator).',
      '$numerator ÷ $denominator = $correct.',
    ],
    answerFormat: AnswerFormat.decimal,
  );
}
