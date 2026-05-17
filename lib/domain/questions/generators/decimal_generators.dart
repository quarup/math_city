import 'dart:math';

import 'package:math_city/domain/questions/decimal.dart';
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
