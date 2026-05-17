import 'dart:math';

import 'package:math_city/domain/questions/decimal.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/fraction.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// Percent generators (Grade 6).
///
/// All three answers are bare whole-number strings (no `%` symbol) so
/// the keypad stays digits-only and the answer-checker can use plain
/// exact-string match. Parameters are constrained so every answer lands
/// on an integer — no decimal results.

// ─────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────

/// Returns three distinct whole-number-string distractors that differ
/// from [correct]. Seeds with [candidates], then walks outward by ±i
/// from [correct] to fill the rest.
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

// ─────────────────────────────────────────────────────────────────────────
// percent_intro (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "What percent is shaded?" — shows a 10×10 grid with N cells shaded,
/// asks for N. Avoids 0, 100, and the trivial 50 so the kid has to count
/// rather than recognise a stock fraction.
GeneratedQuestion percentIntro(Random rand) {
  int n;
  do {
    n = rand.nextInt(99) + 1; // 1..99
  } while (n == 50);
  final correct = '$n';

  // Misconception distractors:
  //   - misread the grid (off-by-one row or column)
  //   - swapped shaded/unshaded (100 − n)
  //   - read it as a fraction-over-10 instead of out-of-100
  final candidates = <String>[
    '${100 - n}',
    '${(n ~/ 10) + 1}',
    '${n ~/ 10}',
  ];

  return GeneratedQuestion(
    conceptId: 'percent_intro',
    prompt: 'What percent is shaded?',
    diagram: PercentGridSpec(shadedCount: n),
    correctAnswer: correct,
    distractors: _wholeDistractors(n, candidates, rand),
    explanation: [
      'The grid has 100 squares.',
      '$n of them are shaded.',
      '"Percent" means "out of 100" — so $n out of 100 is $n%.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// percent_of_quantity (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "What is P% of Q?" — picks P, Q so the answer is a whole number.
///
/// To guarantee an integer result, parameters are drawn from two
/// templates with equal probability:
///   * P ∈ {10, 20, 25, 30, 40, 50, 60, 70, 75, 80, 90} with Q a
///     multiple of (100 ÷ gcd(P, 100)). E.g. P=25 → Q ∈ {4, 8, 12, …}.
///   * P ∈ {1..99} with Q a multiple of 100 (P% of 100k = k·P).
GeneratedQuestion percentOfQuantity(Random rand) {
  final useFriendlyPercent = rand.nextBool();
  final int percent;
  final int quantity;
  if (useFriendlyPercent) {
    const friendly = <int>[10, 20, 25, 30, 40, 50, 60, 70, 75, 80, 90];
    percent = friendly[rand.nextInt(friendly.length)];
    // Quantity must be a multiple of 100 / gcd(percent, 100) for an
    // integer result.
    final step = 100 ~/ _gcd(percent, 100);
    // Pick a multiple in [step, step·12] so the answer stays small-ish.
    final units = rand.nextInt(12) + 1; // 1..12
    quantity = step * units;
  } else {
    percent = rand.nextInt(99) + 1; // 1..99
    // Quantity = 100·k for k ∈ [1, 10]. Answer = percent · k.
    final k = rand.nextInt(10) + 1;
    quantity = 100 * k;
  }
  final answer = (percent * quantity) ~/ 100;
  final correct = '$answer';

  // Misconception distractors:
  //   - dropped the % entirely (used percent as a multiplier).
  //   - applied the percent twice / forgot to divide by 100.
  //   - swapped percent and quantity in the division.
  final candidates = <String>[
    '${percent * quantity}',
    '${quantity ~/ percent.clamp(1, 100)}',
    '${quantity - answer}', // "the rest"
  ];

  return GeneratedQuestion(
    conceptId: 'percent_of_quantity',
    prompt: 'What is $percent% of $quantity?',
    correctAnswer: correct,
    distractors: _wholeDistractors(answer, candidates, rand),
    explanation: [
      '$percent% means $percent/100.',
      '$percent% of $quantity = $percent ÷ 100 × $quantity.',
      '= $correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// find_whole_from_part_percent (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "P% of what number is X?" — inverse of [percentOfQuantity]. Generated
/// by drawing the same friendly parameter sets, computing the part, and
/// then asking for the whole.
GeneratedQuestion findWholeFromPartPercent(Random rand) {
  final useFriendlyPercent = rand.nextBool();
  final int percent;
  final int whole;
  if (useFriendlyPercent) {
    const friendly = <int>[10, 20, 25, 40, 50, 60, 75, 80];
    percent = friendly[rand.nextInt(friendly.length)];
    final step = 100 ~/ _gcd(percent, 100);
    final units = rand.nextInt(10) + 1;
    whole = step * units;
  } else {
    percent = rand.nextInt(99) + 1;
    final k = rand.nextInt(8) + 1;
    whole = 100 * k;
  }
  final part = (percent * whole) ~/ 100;
  final correct = '$whole';

  // Misconception distractors:
  //   - took the part as the whole.
  //   - inverted percent (e.g. "100 / percent · part").
  //   - just multiplied percent × part, forgetting the percent meaning.
  final candidates = <String>[
    '$part',
    '${part * percent}',
    '${part + percent}',
  ];

  return GeneratedQuestion(
    conceptId: 'find_whole_from_part_percent',
    prompt: '$part is $percent% of what number?',
    correctAnswer: correct,
    distractors: _wholeDistractors(whole, candidates, rand),
    explanation: [
      '"$part is $percent% of W" means $part = $percent/100 × W.',
      'So W = $part × 100 ÷ $percent.',
      '= $correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// percent_change (Grade 7)
// ─────────────────────────────────────────────────────────────────────────

/// "Increased from O to N. What's the percent increase?" — or the
/// decrease variant. Picks parameters so the percent is a clean whole
/// number in [5, 90], avoiding ±100% so the kid never sees a degenerate
/// "all gone" or "doubled" case.
GeneratedQuestion percentChange(Random rand) {
  final isIncrease = rand.nextBool();
  // Friendly percent magnitudes that produce clean integer values
  // against the friendly original magnitudes below.
  const friendlyPercents = <int>[10, 20, 25, 30, 40, 50, 60, 75, 80];
  final percent = friendlyPercents[rand.nextInt(friendlyPercents.length)];
  // Step makes percent × original divisible by 100.
  final step = 100 ~/ _gcd(percent, 100);
  final units = rand.nextInt(8) + 2; // 2..9
  final original = step * units;
  final delta = original * percent ~/ 100;
  final updated = isIncrease ? original + delta : original - delta;
  final correct = '$percent';

  final word = isIncrease ? 'increase' : 'decrease';
  final candidates = <String>[
    // Misconception: reported the raw change magnitude, not the percent.
    '$delta',
    // Misconception: used updated instead of original as the base.
    '${(delta * 100) ~/ (updated == 0 ? 1 : updated)}',
    // Off-by-power-of-10.
    '${percent * 10}',
  ];

  return GeneratedQuestion(
    conceptId: 'percent_change',
    prompt: isIncrease
        ? 'A value goes from $original to $updated. What percent increase?'
        : 'A value goes from $original to $updated. What percent decrease?',
    correctAnswer: correct,
    distractors: _wholeDistractors(percent, candidates, rand),
    explanation: [
      'Change = |$updated − $original| = $delta.',
      'Percent $word = change ÷ original × 100.',
      '$delta ÷ $original × 100 = $percent%.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// simple_interest (Grade 7)
// ─────────────────────────────────────────────────────────────────────────

/// "Principal \$P at R% per year for T years. How much interest?"
/// I = P × R × T / 100. Parameters chosen so I is always a whole dollar.
GeneratedQuestion simpleInterest(Random rand) {
  // Friendly rates (small whole percents).
  const rates = <int>[2, 3, 4, 5, 6, 8, 10];
  final rate = rates[rand.nextInt(rates.length)];
  // Term in years 1..5.
  final years = rand.nextInt(5) + 1;
  // Principal must make rate × years × principal divisible by 100.
  // Easiest: principal is a multiple of 100.
  final principal = 100 * (rand.nextInt(20) + 1); // 100..2000 in 100s
  final interest = principal * rate * years ~/ 100;
  final correct = '$interest';

  final candidates = <String>[
    // Misconception: forgot to multiply by time.
    '${principal * rate ~/ 100}',
    // Misconception: added rate + years instead of multiplying.
    '${principal * (rate + years) ~/ 100}',
    // Off by ÷100.
    '${principal * rate * years}',
  ];

  return GeneratedQuestion(
    conceptId: 'simple_interest',
    prompt:
        '\$$principal earns $rate% simple interest per year for $years '
        'year${years == 1 ? "" : "s"}. How much interest? (in dollars)',
    correctAnswer: correct,
    distractors: _wholeDistractors(interest, candidates, rand),
    explanation: [
      'Simple interest = principal × rate × time ÷ 100.',
      '\$$principal × $rate × $years ÷ 100 = \$$correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// commission (Grade 7)
// ─────────────────────────────────────────────────────────────────────────

/// "A salesperson earns R% commission on a \$S sale. Commission = ?"
/// Reuses the percent-of-quantity arithmetic shape.
GeneratedQuestion commission(Random rand) {
  const rates = <int>[2, 3, 4, 5, 6, 8, 10, 12, 15, 20];
  final rate = rates[rand.nextInt(rates.length)];
  // Sale must make rate × sale divisible by 100.
  final step = 100 ~/ _gcd(rate, 100);
  final units = rand.nextInt(10) + 1; // 1..10
  final sale = step * units;
  final earned = sale * rate ~/ 100;
  final correct = '$earned';

  final candidates = <String>[
    // Misconception: full sale (forgot to take a percent).
    '$sale',
    // Misconception: forgot the ÷100 step.
    '${sale * rate}',
    // Misconception: subtracted rate from sale.
    '${sale - rate}',
  ];

  return GeneratedQuestion(
    conceptId: 'commission',
    prompt:
        'A salesperson earns $rate% commission on a \$$sale sale. '
        'How much commission? (in dollars)',
    correctAnswer: correct,
    distractors: _wholeDistractors(earned, candidates, rand),
    explanation: [
      'Commission = sale × rate ÷ 100.',
      '\$$sale × $rate ÷ 100 = \$$correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// markup_markdown (Grade 7)
// ─────────────────────────────────────────────────────────────────────────

/// Either "marked UP by R% from P → new price?" or "marked DOWN".
/// Currently tagged `dataset` in curriculum.md but implemented
/// algorithmically per the design principle 4 precedent (mult_compare_word).
GeneratedQuestion markupMarkdown(Random rand) {
  final isUp = rand.nextBool();
  const rates = <int>[10, 15, 20, 25, 30, 40, 50];
  final rate = rates[rand.nextInt(rates.length)];
  final step = 100 ~/ _gcd(rate, 100);
  final units = rand.nextInt(8) + 2; // 2..9
  final original = step * units;
  final delta = original * rate ~/ 100;
  final updated = isUp ? original + delta : original - delta;
  final correct = '$updated';

  final candidates = <String>[
    // Misconception: just the change amount.
    '$delta',
    // Misconception: wrong direction.
    '${isUp ? original - delta : original + delta}',
    // Misconception: original price.
    '$original',
  ];

  final prompt = isUp
      ? 'A store buys an item for \$$original and marks it up $rate%. '
            'What is the new price? (in dollars)'
      : 'An item costs \$$original. After a $rate% markdown, what is the '
            'sale price? (in dollars)';

  return GeneratedQuestion(
    conceptId: 'markup_markdown',
    prompt: prompt,
    correctAnswer: correct,
    distractors: _wholeDistractors(updated, candidates, rand),
    explanation: [
      '${isUp ? "Markup" : "Markdown"} = \$$original × $rate ÷ 100 = \$$delta.',
      'New = \$$original ${isUp ? "+" : "−"} \$$delta = \$$correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// sales_tax_tip (Grade 7)
// ─────────────────────────────────────────────────────────────────────────

/// "A bill is \$B; the tax/tip rate is R%. How much extra?" Asks just
/// for the tax/tip amount (not the total) so the answer is a clean
/// percent-of-quantity. Currently tagged `dataset` in curriculum.md but
/// implemented algorithmically per design-principle-4 precedent.
GeneratedQuestion salesTaxTip(Random rand) {
  final isTip = rand.nextBool();
  const tipRates = <int>[10, 15, 18, 20, 25];
  const taxRates = <int>[5, 6, 7, 8, 10];
  final rate = (isTip
      ? tipRates
      : taxRates)[rand.nextInt((isTip ? tipRates : taxRates).length)];
  final step = 100 ~/ _gcd(rate, 100);
  final units = rand.nextInt(10) + 1; // 1..10
  final bill = step * units;
  final extra = bill * rate ~/ 100;
  final correct = '$extra';

  final candidates = <String>[
    // Misconception: gave the total instead of just the extra.
    '${bill + extra}',
    // Misconception: gave the bill instead of the extra.
    '$bill',
    // Misconception: forgot the ÷100 step.
    '${bill * rate}',
  ];

  final prompt = isTip
      ? 'A meal cost \$$bill. With a $rate% tip, how much is the tip? '
            '(in dollars)'
      : 'A purchase costs \$$bill. With $rate% sales tax, how much is the '
            'tax? (in dollars)';

  return GeneratedQuestion(
    conceptId: 'sales_tax_tip',
    prompt: prompt,
    correctAnswer: correct,
    distractors: _wholeDistractors(extra, candidates, rand),
    explanation: [
      '${isTip ? "Tip" : "Tax"} = bill × rate ÷ 100.',
      '\$$bill × $rate ÷ 100 = \$$correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// convert_fraction_decimal_percent (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "Write X as Y" where X is one of {fraction, decimal, percent} and Y
/// is a different form. Six variants, equally likely. Base values are
/// drawn from a curated set with clean three-way equivalents (multiples
/// of 5% with neat fraction reductions).
GeneratedQuestion convertFractionDecimalPercent(Random rand) {
  // Pick percent ∈ multiples of 5 in [5, 95] excluding 50 (too trivial)
  // and 100 (degenerate).
  const percents = <int>[
    5,
    10,
    15,
    20,
    25,
    30,
    35,
    40,
    45,
    55,
    60,
    65,
    70,
    75,
    80,
    85,
    90,
    95,
  ];
  final percent = percents[rand.nextInt(percents.length)];
  // Derive the three representations.
  final decimal = Decimal(percent, 2); // e.g. 25 → 0.25
  final fraction = Fraction(percent, 100).reduce(); // e.g. 25/100 → 1/4
  final percentStr = '$percent';
  final decimalStr = decimal.toCanonical();
  final fractionStr = fraction.toCanonical();

  // Pick a (from, to) pair from the 6 variants. `from` is the form
  // shown in the prompt; `to` is the form the answer must be in.
  const variants = <(_Form, _Form)>[
    (_Form.fraction, _Form.decimal),
    (_Form.fraction, _Form.percent),
    (_Form.decimal, _Form.fraction),
    (_Form.decimal, _Form.percent),
    (_Form.percent, _Form.fraction),
    (_Form.percent, _Form.decimal),
  ];
  final variant = variants[rand.nextInt(variants.length)];
  final from = variant.$1;
  final to = variant.$2;

  String shown;
  switch (from) {
    case _Form.fraction:
      shown = fractionStr;
    case _Form.decimal:
      shown = decimalStr;
    case _Form.percent:
      shown = '$percentStr%';
  }
  String targetWord;
  String correct;
  AnswerFormat answerFormat;
  AnswerShape answerShape;
  switch (to) {
    case _Form.fraction:
      targetWord = 'a fraction in lowest terms';
      correct = fractionStr;
      answerFormat = AnswerFormat.fraction;
      // Exact-string because the lesson IS "in lowest terms".
      answerShape = AnswerShape.exactString;
    case _Form.decimal:
      targetWord = 'a decimal';
      correct = decimalStr;
      answerFormat = AnswerFormat.decimal;
      answerShape = AnswerShape.any;
    case _Form.percent:
      targetWord = 'a percent';
      correct = percentStr;
      answerFormat = AnswerFormat.integer;
      answerShape = AnswerShape.any;
  }

  // Distractors: pick one of the other-form representations (a classic
  // confusion: writing the percent number when asked for the decimal,
  // etc.), plus off-by-power-of-10 perturbations.
  final misconceptions = <String>[
    if (to != _Form.percent) percentStr, // wrote the percent number
    if (to != _Form.decimal) decimalStr, // wrote the decimal
    if (to != _Form.fraction) fractionStr, // wrote the fraction
  ];
  final distractors = <String>[];
  final seen = <String>{correct};
  for (final m in misconceptions) {
    if (distractors.length >= 3) break;
    if (seen.add(m)) distractors.add(m);
  }
  // Filler perturbations.
  for (var i = 1; distractors.length < 3 && i < 20; i++) {
    final v = '${percent + i * 5}';
    if (seen.add(v)) distractors.add(v);
    if (distractors.length >= 3) break;
    final v2 = '${(percent - i * 5).clamp(1, 99)}';
    if (seen.add(v2)) distractors.add(v2);
  }

  return GeneratedQuestion(
    conceptId: 'convert_fraction_decimal_percent',
    prompt: 'Write $shown as $targetWord.',
    correctAnswer: correct,
    distractors: distractors.take(3).toList(),
    explanation: [
      'Three forms: $fractionStr = $decimalStr = $percentStr%.',
      'Answer: $correct.',
    ],
    answerFormat: answerFormat,
    answerShape: answerShape,
  );
}

enum _Form { fraction, decimal, percent }

// ─────────────────────────────────────────────────────────────────────────

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
