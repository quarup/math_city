import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/fraction.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/word_problems/word_problem_framework.dart';

// ---------------------------------------------------------------------------
// Shared helpers
// ---------------------------------------------------------------------------

/// Picks three fraction-string distractors for [correct], skipping any
/// candidate that is mathematically equivalent to it. Candidates are tried
/// in order, then random ±1 numerator/denominator perturbations of
/// [correct] are appended as fallbacks until three unique non-equivalent
/// strings have been collected.
///
/// The strings returned are the candidates' *original* surface forms
/// (typically un-reduced) — generators emit a canonical reduced answer
/// while their distractors stay in the "computational" un-reduced shape
/// that kids actually write down before simplifying.
List<String> _fractionDistractors(
  Fraction correct,
  List<String> candidates,
  Random rand,
) {
  final out = <String>[];
  final seen = <String>{correct.toCanonical()};
  bool tryAdd(String s) {
    if (seen.contains(s)) return false;
    final f = Fraction.tryParse(s);
    if (f != null && f.equalsByValue(correct)) return false;
    seen.add(s);
    out.add(s);
    return true;
  }

  for (final c in candidates) {
    if (out.length >= 3) break;
    tryAdd(c);
  }
  // Fallback perturbations.
  for (var i = 0; i < 40 && out.length < 3; i++) {
    final dn = rand.nextInt(5) - 2; // -2..2
    final dd = rand.nextInt(5) - 2;
    final n2 = correct.numerator + dn;
    final d2 = correct.denominator + dd;
    if (d2 <= 0 || n2 == 0 || n2 < 0) continue;
    tryAdd('$n2/$d2');
  }
  while (out.length < 3) {
    // Extreme fallback: just emit unique tiny fractions.
    out.add('${out.length + 1}/${out.length + 2}');
  }
  return out.take(3).toList();
}

// ---------------------------------------------------------------------------
// Generators
// ---------------------------------------------------------------------------

/// "What fraction is shaded?" — shows a fraction bar and asks for a/b.
///
/// The canonical answer is the *visible* form on the bar (kid counts what
/// they see). Shape: exactString because this concept's lesson IS "count
/// what's depicted" — simplification is a separate concept
/// (`simplify_fraction`).
GeneratedQuestion fractionAOverB(Random rand) {
  final denominator = rand.nextInt(7) + 2; // 2..8
  final numerator = rand.nextInt(denominator - 1) + 1; // 1..denom-1 (proper)
  final correct = '$numerator/$denominator';
  final correctF = Fraction(numerator, denominator);
  final distractors = _fractionDistractors(
    correctF,
    [
      '$denominator/$numerator', // swapped
      '${numerator + 1}/$denominator',
      '$numerator/${denominator + 1}',
      if (numerator > 1) '${numerator - 1}/$denominator',
      '$numerator/${denominator - 1}',
    ],
    rand,
  );
  return GeneratedQuestion(
    conceptId: 'fraction_a_over_b',
    prompt: 'What fraction is shaded?',
    diagram: FractionBarSpec(
      numerator: numerator,
      denominator: denominator,
    ),
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'The bar is split into $denominator equal parts.',
      '$numerator of them are shaded, so it is $numerator/$denominator.',
    ],
    answerFormat: AnswerFormat.fraction,
    answerShape: AnswerShape.exactString,
  );
}

/// Compare two fractions with the same denominator. Answer is the larger
/// fraction (ties excluded).
GeneratedQuestion compareFractionsSameDenom(Random rand) {
  final denominator = rand.nextInt(7) + 3; // 3..9
  final n1 = rand.nextInt(denominator - 1) + 1;
  int n2;
  do {
    n2 = rand.nextInt(denominator) + 1; // 1..denom
  } while (n2 == n1);
  final left = '$n1/$denominator';
  final right = '$n2/$denominator';
  final correct = n1 > n2 ? left : right;
  final wrong = n1 > n2 ? right : left;
  return GeneratedQuestion(
    conceptId: 'compare_fractions_same_denom',
    prompt: 'Which is bigger: $left or $right?',
    correctAnswer: correct,
    distractors: <String>[
      wrong,
      'They are equal',
      '$n1+$n2/$denominator',
    ],
    explanation: [
      'Both fractions have $denominator on the bottom.',
      'So just compare the tops: ${n1 > n2 ? '$n1 > $n2' : '$n2 > $n1'}.',
      '$correct is bigger.',
    ],
    // answerFormat: string (default) — MC of fixed strings; no equivalence
    // checking needed because the kid picks one of two displayed fractions.
  );
}

/// "Find an equivalent fraction" — show a starting fraction, name a
/// multiplier in the prompt, ask for the result. Requires canonical form
/// because the multiplier is fixed (the lesson is "apply the multiplier",
/// not "find any equivalent").
GeneratedQuestion equivalentFractionsVisual(Random rand) {
  final denominator = rand.nextInt(4) + 2; // 2..5
  final numerator = rand.nextInt(denominator - 1) + 1; // proper
  final multiplier = rand.nextInt(3) + 2; // 2..4
  final equivN = numerator * multiplier;
  final equivD = denominator * multiplier;
  final correct = '$equivN/$equivD';
  final distractors = _fractionDistractors(
    Fraction(equivN, equivD),
    [
      '${numerator * multiplier}/$denominator', // only-num scaled
      '$numerator/${denominator * multiplier}', // only-denom scaled
      '${equivN + 1}/$equivD', // off-by-one num
      '$equivN/${equivD + 1}', // off-by-one denom
    ],
    rand,
  );
  return GeneratedQuestion(
    conceptId: 'equivalent_fractions_visual',
    prompt:
        'Which is equal to $numerator/$denominator? '
        '(Multiply top and bottom by $multiplier.)',
    diagram: FractionBarSpec(
      numerator: numerator,
      denominator: denominator,
    ),
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      '$numerator × $multiplier = $equivN',
      '$denominator × $multiplier = $equivD',
      'So $numerator/$denominator = $equivN/$equivD.',
    ],
    answerFormat: AnswerFormat.fraction,
    answerShape: AnswerShape.exactString,
  );
}

/// "Find an equivalent fraction with denominator D." The kid has to figure
/// out the multiplier themselves (vs `equivalent_fractions_visual` where
/// the multiplier is stated). Canonical-required because D fixes the
/// answer form.
GeneratedQuestion equivalentFractionsCompute(Random rand) {
  final baseDen = rand.nextInt(7) + 2; // 2..8
  final baseNum = rand.nextInt(baseDen - 1) + 1; // proper
  final multiplier = rand.nextInt(8) + 2; // 2..9
  final targetDen = baseDen * multiplier;
  final targetNum = baseNum * multiplier;
  final correct = '$targetNum/$targetDen';
  final distractors = _fractionDistractors(
    Fraction(targetNum, targetDen),
    [
      '$baseNum/$targetDen', // forgot to scale numerator
      '$targetNum/$baseDen', // forgot to scale denominator
      '${targetNum + 1}/$targetDen',
      '$targetNum/${targetDen + 1}',
      '${baseNum + multiplier}/${baseDen + multiplier}', // added instead of multiplied
    ],
    rand,
  );
  return GeneratedQuestion(
    conceptId: 'equivalent_fractions_compute',
    prompt:
        'Fill in the blank: $baseNum/$baseDen = ?/$targetDen',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Bottoms: $baseDen × $multiplier = $targetDen.',
      'Apply the same multiplier on top: $baseNum × $multiplier = $targetNum.',
      'So $baseNum/$baseDen = $targetNum/$targetDen.',
    ],
    answerFormat: AnswerFormat.fraction,
    answerShape: AnswerShape.exactString,
  );
}

/// Compare two fractions with the same numerator (e.g. 3/4 vs 3/7).
/// Bigger denominator → smaller fraction. Answer is the larger of the two
/// shown fractions.
GeneratedQuestion compareFractionsSameNum(Random rand) {
  final numerator = rand.nextInt(5) + 1; // 1..5
  final d1 = rand.nextInt(7) + numerator + 1; // > num so the fraction is proper
  int d2;
  do {
    d2 = rand.nextInt(7) + numerator + 1;
  } while (d2 == d1);
  final left = '$numerator/$d1';
  final right = '$numerator/$d2';
  final correct = d1 < d2 ? left : right; // smaller denom → bigger fraction
  final wrong = d1 < d2 ? right : left;
  return GeneratedQuestion(
    conceptId: 'compare_fractions_same_num',
    prompt: 'Which is bigger: $left or $right?',
    correctAnswer: correct,
    distractors: <String>[
      wrong,
      'They are equal',
      'Cannot tell',
    ],
    explanation: [
      'Both fractions have $numerator on top.',
      'Smaller bottom = bigger pieces ⇒ bigger fraction.',
      '${d1 < d2 ? '$d1 < $d2' : '$d2 < $d1'}, so $correct is bigger.',
    ],
  );
}

/// Compare two fractions with different numerators AND different
/// denominators. Solved via cross-multiplication. Answer is the larger of
/// the two shown fractions.
GeneratedQuestion compareFractionsUnlike(Random rand) {
  var n1 = 0;
  var d1 = 0;
  var n2 = 0;
  var d2 = 0;
  // Loop until we get two non-equivalent, non-trivially-comparable fractions.
  while (d1 == d2 || n1 == n2 || n1 * d2 == n2 * d1) {
    d1 = rand.nextInt(7) + 3; // 3..9
    n1 = rand.nextInt(d1 - 1) + 1; // 1..d1-1
    d2 = rand.nextInt(7) + 3;
    n2 = rand.nextInt(d2 - 1) + 1;
  }
  final left = '$n1/$d1';
  final right = '$n2/$d2';
  final cross1 = n1 * d2;
  final cross2 = n2 * d1;
  final correct = cross1 > cross2 ? left : right;
  final wrong = cross1 > cross2 ? right : left;
  final compareSummary = cross1 > cross2
      ? '$cross1 > $cross2'
      : '$cross2 > $cross1';
  return GeneratedQuestion(
    conceptId: 'compare_fractions_unlike',
    prompt: 'Which is bigger: $left or $right?',
    correctAnswer: correct,
    distractors: <String>[
      wrong,
      'They are equal',
      'Cannot tell',
    ],
    explanation: [
      'Cross-multiply to compare: $n1 × $d2 = $cross1, $n2 × $d1 = $cross2.',
      '$compareSummary, so $correct is bigger.',
    ],
  );
}

/// "Simplify this fraction to lowest terms." Picks a reducible fraction
/// (GCF > 1) and asks for the reduced form. Canonical-required — the
/// lesson IS producing the simplest form.
GeneratedQuestion simplifyFraction(Random rand) {
  var baseN = 0;
  var baseD = 0;
  var gcf = 0;
  // Loop until we pick a reducible fraction (gcf > 1) with reasonable size.
  while (gcf <= 1 || baseD > 60 || _gcdInt(baseN, baseD) <= 1) {
    final reducedN = rand.nextInt(6) + 1; // 1..6
    final reducedD = rand.nextInt(8) + 2; // 2..9
    if (reducedN >= reducedD) continue;
    gcf = rand.nextInt(4) + 2; // 2..5
    baseN = reducedN * gcf;
    baseD = reducedD * gcf;
  }
  final correctF = Fraction(baseN, baseD);
  final correct = correctF.toCanonical();
  final distractors = _fractionDistractors(
    correctF,
    [
      // "divided only numerator" / "divided only denominator" misconceptions.
      '${baseN ~/ gcf}/$baseD',
      '$baseN/${baseD ~/ gcf}',
      // Off-by-one variants on the reduced form.
      '${(baseN ~/ gcf) + 1}/${baseD ~/ gcf}',
      // Swapped reduced.
      '${baseD ~/ gcf}/${baseN ~/ gcf}',
    ],
    rand,
  );
  return GeneratedQuestion(
    conceptId: 'simplify_fraction',
    prompt: 'Simplify $baseN/$baseD to lowest terms.',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Find a number that divides both $baseN and $baseD.',
      '$baseN ÷ $gcf = ${baseN ~/ gcf}; $baseD ÷ $gcf = ${baseD ~/ gcf}',
      'So $baseN/$baseD = $correct.',
    ],
    answerFormat: AnswerFormat.fraction,
    answerShape: AnswerShape.exactString,
  );
}

int _gcdInt(int a, int b) {
  var x = a.abs();
  var y = b.abs();
  while (y != 0) {
    final t = y;
    y = x % y;
    x = t;
  }
  return x;
}

/// Add fractions with like denominators: a/d + b/d = (a+b)/d, displayed in
/// reduced form. The "added denominators too" misconception is preserved
/// as a distractor.
GeneratedQuestion addFractionsLikeDenom(Random rand) {
  final denominator = rand.nextInt(6) + 3; // 3..8
  final a = rand.nextInt(denominator - 1) + 1; // 1..denom-1
  final b = rand.nextInt(denominator - a) + 1; // 1..denom-a, sum ≤ denom
  final sumNum = a + b;
  final sumF = Fraction(sumNum, denominator);
  final correct = sumF.toCanonical();
  final distractors = _fractionDistractors(
    sumF,
    [
      '$sumNum/${denominator * 2}', // misconception: added denoms
      '${sumNum + 1}/$denominator', // off-by-one
      '${a > 0 ? a - 1 : a + 1}/$denominator', // close
      '$sumNum/${denominator + 1}', // wrong denom
    ],
    rand,
  );
  return GeneratedQuestion(
    conceptId: 'add_fractions_like_denom',
    prompt: '$a/$denominator + $b/$denominator = ?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Same bottoms — just add the tops.',
      '$a + $b = $sumNum',
      'So $a/$denominator + $b/$denominator = $sumNum/$denominator.',
      if (correct != '$sumNum/$denominator') 'Simplified, that is $correct.',
    ],
    answerFormat: AnswerFormat.fraction,
  );
}

/// Subtract fractions with like denominators: a/d − b/d = (a−b)/d.
/// Result ≥ 0; canonical = reduced form.
GeneratedQuestion subFractionsLikeDenom(Random rand) {
  final denominator = rand.nextInt(6) + 3; // 3..8
  final a = rand.nextInt(denominator - 1) + 1; // 1..denom-1
  final b = rand.nextInt(a) + 1; // 1..a, so a ≥ b
  final diffNum = a - b;
  final diffF = Fraction(diffNum, denominator);
  final correct = diffF.toCanonical();
  final distractors = _fractionDistractors(
    diffF,
    [
      '${a + b}/$denominator', // added instead of subtracted
      '$diffNum/${denominator * 2}', // subtracted denoms too
      '${diffNum + 1}/$denominator', // off-by-one
      '$diffNum/${denominator - 1}', // wrong denom
    ],
    rand,
  );
  return GeneratedQuestion(
    conceptId: 'sub_fractions_like_denom',
    prompt: '$a/$denominator − $b/$denominator = ?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Same bottoms — just subtract the tops.',
      '$a − $b = $diffNum',
      'So $a/$denominator − $b/$denominator = $diffNum/$denominator.',
      if (correct != '$diffNum/$denominator')
        'Simplified, that is $correct.',
    ],
    answerFormat: AnswerFormat.fraction,
  );
}

/// Convert an improper fraction (e.g. 7/4) to a mixed number (e.g. 1 3/4).
/// Shape: mixedForm — the lesson IS producing the mixed form (re-typing
/// the improper would defeat it), but within that, any simplified
/// equivalent is accepted with a nudge (e.g. `3 1/2` for canonical
/// `3 2/4`).
GeneratedQuestion improperToMixed(Random rand) {
  // Choose mixed parts first, then derive the improper form. Ensures the
  // answer is always genuinely mixed (whole ≥ 1, proper part > 0).
  final whole = rand.nextInt(5) + 1; // 1..5
  final denominator = rand.nextInt(7) + 2; // 2..8
  final properNum = rand.nextInt(denominator - 1) + 1; // 1..denom-1
  final improperNum = whole * denominator + properNum;
  final correct = '$whole $properNum/$denominator';
  // Distractor pool — kid-typical errors.
  final wrongWholes = <int>[whole + 1, if (whole > 1) whole - 1];
  final wrongRems = <int>[
    if (properNum > 1) properNum - 1,
    if (properNum < denominator - 1) properNum + 1,
  ];
  final candidates = <String>[
    for (final w in wrongWholes) '$w $properNum/$denominator',
    for (final r in wrongRems) '$whole $r/$denominator',
    '$properNum $whole/$denominator', // swapped whole and rem
    if (denominator > 2) '$whole $properNum/${denominator - 1}',
  ];
  // Pick first 3 unique non-canonical, non-equivalent strings.
  final correctF = Fraction(improperNum, denominator);
  final distractors = <String>[];
  final seen = <String>{correct};
  for (final c in candidates) {
    if (distractors.length >= 3) break;
    if (seen.contains(c)) continue;
    final f = Fraction.tryParse(c);
    if (f == null || f.equalsByValue(correctF)) continue;
    distractors.add(c);
    seen.add(c);
  }
  // Pad if needed (rare).
  var pad = 1;
  while (distractors.length < 3) {
    final s = '${whole + pad} $properNum/$denominator';
    if (!seen.contains(s)) {
      distractors.add(s);
      seen.add(s);
    }
    pad++;
  }
  return GeneratedQuestion(
    conceptId: 'improper_to_mixed',
    prompt: 'Write $improperNum/$denominator as a mixed number.',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Divide: $improperNum ÷ $denominator = $whole remainder $properNum.',
      'The whole part is $whole; the leftover is $properNum/$denominator.',
      'So $improperNum/$denominator = $whole and $properNum/$denominator.',
    ],
    answerFormat: AnswerFormat.mixedNumber,
    answerShape: AnswerShape.mixedForm,
  );
}

/// Convert a mixed number (e.g. 1 3/4) to an improper fraction (e.g. 7/4).
/// Shape: improperFraction — the lesson IS producing the single-fraction
/// form, but any simplified equivalent in that shape is accepted with a
/// nudge.
GeneratedQuestion mixedToImproper(Random rand) {
  final whole = rand.nextInt(5) + 1; // 1..5
  final denominator = rand.nextInt(7) + 2; // 2..8
  final properNum = rand.nextInt(denominator - 1) + 1; // 1..denom-1
  final improperNum = whole * denominator + properNum;
  final correct = '$improperNum/$denominator';
  final correctF = Fraction(improperNum, denominator);
  final candidates = <String>[
    '${whole + properNum}/$denominator', // added instead of multiplied
    '${whole * properNum}/$denominator', // multiplied whole × num
    '$improperNum/${whole + denominator}', // wrong denom
    '${improperNum + denominator}/$denominator', // off-by-whole
    '${improperNum - 1}/$denominator', // off-by-one
  ];
  final distractors = _fractionDistractors(correctF, candidates, rand);
  return GeneratedQuestion(
    conceptId: 'mixed_to_improper',
    prompt:
        'Write $whole and $properNum/$denominator as an improper fraction.',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      '$whole × $denominator = ${whole * denominator} (whole × bottom).',
      '${whole * denominator} + $properNum = $improperNum (then add the top).',
      'So $whole and $properNum/$denominator = $improperNum/$denominator.',
    ],
    answerFormat: AnswerFormat.fraction,
    answerShape: AnswerShape.improperFraction,
  );
}

/// Add two fractions with different denominators. Uses LCM for the common
/// denominator. Canonical = reduced.
GeneratedQuestion addFractionsUnlikeDenom(Random rand) {
  // Pick small denoms in 2..6, distinct, so the LCM stays modest.
  var d1 = 0;
  var d2 = 0;
  while (d1 == d2) {
    d1 = rand.nextInt(5) + 2; // 2..6
    d2 = rand.nextInt(5) + 2;
  }
  final n1 = rand.nextInt(d1 - 1) + 1; // proper
  final n2 = rand.nextInt(d2 - 1) + 1;
  final common = lcm(d1, d2);
  final scaled1 = n1 * (common ~/ d1);
  final scaled2 = n2 * (common ~/ d2);
  final sumNum = scaled1 + scaled2;
  final sumF = Fraction(sumNum, common);
  final correct = sumF.toCanonical();
  final distractors = _fractionDistractors(
    sumF,
    [
      '${n1 + n2}/${d1 + d2}', // tops+tops, bottoms+bottoms misconception
      '${n1 + n2}/$d1', // tops+tops, kept one denom
      '${n1 + n2}/${d1 * d2}', // tops+tops, denoms multiplied
      '$sumNum/${common + 1}',
      '${sumNum + 1}/$common',
    ],
    rand,
  );
  return GeneratedQuestion(
    conceptId: 'add_fractions_unlike_denom',
    prompt: '$n1/$d1 + $n2/$d2 = ?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Common bottom is $common (smallest multiple of $d1 and $d2).',
      '$n1/$d1 = $scaled1/$common; $n2/$d2 = $scaled2/$common.',
      '$scaled1/$common + $scaled2/$common = $sumNum/$common.',
      if (correct != '$sumNum/$common') 'Simplified, that is $correct.',
    ],
    answerFormat: AnswerFormat.fraction,
  );
}

/// Subtract two fractions with different denominators. Result ≥ 0.
/// Canonical = reduced.
GeneratedQuestion subFractionsUnlikeDenom(Random rand) {
  var d1 = 0;
  var d2 = 0;
  var n1 = 0;
  var n2 = 0;
  var common = 0;
  var scaled1 = 0;
  var scaled2 = 1; // forces first loop iteration
  // Loop until denoms differ AND scaled1 > scaled2 so the result is positive.
  while (d1 == d2 || scaled1 <= scaled2) {
    d1 = rand.nextInt(5) + 2;
    d2 = rand.nextInt(5) + 2;
    if (d1 == d2) continue;
    n1 = rand.nextInt(d1 - 1) + 1;
    n2 = rand.nextInt(d2 - 1) + 1;
    common = lcm(d1, d2);
    scaled1 = n1 * (common ~/ d1);
    scaled2 = n2 * (common ~/ d2);
  }
  final diffNum = scaled1 - scaled2;
  final diffF = Fraction(diffNum, common);
  final correct = diffF.toCanonical();
  final distractors = _fractionDistractors(
    diffF,
    [
      '${(n1 - n2).abs()}/${(d1 - d2).abs() == 0 ? d1 : (d1 - d2).abs()}',
      '${n1 - n2}/$d1', // subtracted tops, kept one denom
      '$diffNum/${common + 1}',
      '${diffNum + 1}/$common',
      '${scaled1 + scaled2}/$common', // added instead of subtracted
    ],
    rand,
  );
  return GeneratedQuestion(
    conceptId: 'sub_fractions_unlike_denom',
    prompt: '$n1/$d1 − $n2/$d2 = ?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Common bottom is $common (smallest multiple of $d1 and $d2).',
      '$n1/$d1 = $scaled1/$common; $n2/$d2 = $scaled2/$common.',
      '$scaled1/$common − $scaled2/$common = $diffNum/$common.',
      if (correct != '$diffNum/$common') 'Simplified, that is $correct.',
    ],
    answerFormat: AnswerFormat.fraction,
  );
}

/// Multiply a whole number by a proper fraction: n × a/b = (n·a)/b,
/// displayed in reduced (whole-when-whole) form.
GeneratedQuestion multFractionByWhole(Random rand) {
  final whole = rand.nextInt(8) + 2; // 2..9
  final denominator = rand.nextInt(7) + 2; // 2..8
  final numerator = rand.nextInt(denominator - 1) + 1; // proper
  final productF = Fraction(whole * numerator, denominator);
  final correct = productF.toCanonical();
  final distractors = _fractionDistractors(
    productF,
    [
      '$numerator/${whole * denominator}', // multiplied denom instead of num
      '${whole + numerator}/$denominator', // added instead of multiplied
      '${whole * numerator}/${whole * denominator}', // multiplied both
      '${whole * numerator + 1}/$denominator', // off-by-one num
      '${whole * numerator}/${denominator + 1}', // off-by-one denom
    ],
    rand,
  );
  return GeneratedQuestion(
    conceptId: 'mult_fraction_by_whole',
    prompt: '$whole × $numerator/$denominator = ?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Top × whole: $whole × $numerator = ${whole * numerator}.',
      'Bottom stays the same: $denominator.',
      'Result: ${whole * numerator}/$denominator.',
      if (correct != '${whole * numerator}/$denominator')
        'Simplified, that is $correct.',
    ],
    answerFormat: AnswerFormat.fraction,
  );
}

/// Multiply two proper fractions: (a/b) × (c/d) = (a·c)/(b·d), reduced.
/// Renders an area-grid diagram showing the product as the deepest-shaded
/// rectangle.
GeneratedQuestion multFractionsProper(Random rand) {
  final b = rand.nextInt(4) + 2; // 2..5
  final d = rand.nextInt(4) + 2; // 2..5
  final a = rand.nextInt(b - 1) + 1; // 1..b-1
  final c = rand.nextInt(d - 1) + 1; // 1..d-1
  final productF = Fraction(a * c, b * d);
  final correct = productF.toCanonical();
  final distractors = _fractionDistractors(
    productF,
    [
      '${a + c}/${b + d}', // added everything
      '${a * c}/${b + d}', // multiplied top, added bottom
      '${a + c}/${b * d}', // added top, multiplied bottom
      '${a * c + 1}/${b * d}', // off-by-one num
      '${a * c}/${b * d + 1}', // off-by-one denom
    ],
    rand,
  );
  return GeneratedQuestion(
    conceptId: 'mult_fractions_proper',
    prompt: '$a/$b × $c/$d = ?',
    diagram: AreaGridSpec(
      rows: d,
      cols: b,
      shadedRows: c,
      shadedCols: a,
    ),
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Multiply the tops: $a × $c = ${a * c}.',
      'Multiply the bottoms: $b × $d = ${b * d}.',
      'So $a/$b × $c/$d = ${a * c}/${b * d}.',
      if (correct != '${a * c}/${b * d}') 'Simplified, that is $correct.',
    ],
    answerFormat: AnswerFormat.fraction,
  );
}

/// Divide a unit fraction by a whole number: (1/n) ÷ m = 1/(n·m).
/// Renders the unit fraction on a bar so kids can see what's being split.
GeneratedQuestion divUnitFractionByWhole(Random rand) {
  final n = rand.nextInt(7) + 2; // 2..8
  final m = rand.nextInt(5) + 2; // 2..6
  final productF = Fraction(1, n * m);
  final correct = productF.toCanonical();
  final distractors = _fractionDistractors(
    productF,
    [
      '$m/$n', // inverted (kid divided by 1/m instead)
      '${n * m}/1', // multiplied instead of divided
      '1/${n + m}', // added bottom
      '1/${(n * m) + 1}',
      '1/${(n * m) - 1}',
    ],
    rand,
  );
  return GeneratedQuestion(
    conceptId: 'div_unit_fraction_by_whole',
    prompt: '1/$n ÷ $m = ?',
    diagram: FractionBarSpec(numerator: 1, denominator: n),
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Splitting 1/$n into $m equal parts makes each part $m times smaller.',
      'New bottom: $n × $m = ${n * m}.',
      'So 1/$n ÷ $m = 1/${n * m}.',
    ],
    answerFormat: AnswerFormat.fraction,
  );
}

/// Divide a whole number by a unit fraction: m ÷ (1/n) = m·n.
/// Renders the unit fraction on a bar to anchor "how many of these fit
/// into m wholes?".
GeneratedQuestion divWholeByUnitFraction(Random rand) {
  final n = rand.nextInt(7) + 2; // 2..8 (unit-fraction denom)
  final m = rand.nextInt(7) + 2; // 2..8 (whole)
  final product = m * n;
  final productF = Fraction(product, 1);
  final correct = productF.toCanonical(); // bare integer string
  final distractors = _fractionDistractors(
    productF,
    [
      '$m/$n', // forgot to invert
      '${m + n}', // added instead of multiplied
      '${(m * n) + 1}',
      '${(m * n) - 1}',
      '${m * n}/$n', // off-by-divisor
    ],
    rand,
  );
  return GeneratedQuestion(
    conceptId: 'div_whole_by_unit_fraction',
    prompt: '$m ÷ 1/$n = ?',
    diagram: FractionBarSpec(numerator: 1, denominator: n),
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'How many 1/$n pieces fit in one whole? $n.',
      'And in $m wholes? $m × $n = ${m * n}.',
      'So $m ÷ 1/$n = ${m * n}.',
    ],
    answerFormat: AnswerFormat.fraction,
  );
}

/// Divide two fractions: (a/b) ÷ (c/d) = (a·d)/(b·c), reduced.
/// "Keep, change, flip."
GeneratedQuestion divFractionByFraction(Random rand) {
  final b = rand.nextInt(5) + 2; // 2..6
  final d = rand.nextInt(5) + 2; // 2..6
  final a = rand.nextInt(b - 1) + 1; // proper
  final c = rand.nextInt(d - 1) + 1; // proper
  final productF = Fraction(a * d, b * c);
  final correct = productF.toCanonical();
  final distractors = _fractionDistractors(
    productF,
    [
      '${a * c}/${b * d}', // forgot to flip — multiplied directly
      '${b * c}/${a * d}', // inverted answer
      '${a + d}/${b + c}', // added everything
      '${(a * d) + 1}/${b * c}',
      '${a * d}/${(b * c) + 1}',
    ],
    rand,
  );
  return GeneratedQuestion(
    conceptId: 'div_fraction_by_fraction',
    prompt: '$a/$b ÷ $c/$d = ?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Keep, change, flip: $a/$b ÷ $c/$d = $a/$b × $d/$c.',
      'Multiply tops: $a × $d = ${a * d}; bottoms: $b × $c = ${b * c}.',
      'So $a/$b ÷ $c/$d = ${a * d}/${b * c}.',
      if (correct != '${a * d}/${b * c}') 'Simplified, that is $correct.',
    ],
    answerFormat: AnswerFormat.fraction,
  );
}

/// Whole number as a fraction with a given denominator: write `n` as
/// `(n·d)/d`. Form is fixed by the requested denominator, so shape is
/// exactString.
GeneratedQuestion wholeNumberAsFraction(Random rand) {
  final n = rand.nextInt(7) + 2; // 2..8
  final d = rand.nextInt(7) + 2; // 2..8
  final correctNum = n * d;
  final correct = '$correctNum/$d';
  final correctF = Fraction(correctNum, d);
  final distractors = _fractionDistractors(
    correctF,
    [
      '$n/$d', // forgot to multiply
      '$d/$n', // swapped
      '${n + d}/$d', // added instead of multiplied
      '$correctNum/${d + 1}',
      '${correctNum + 1}/$d',
    ],
    rand,
  );
  return GeneratedQuestion(
    conceptId: 'whole_number_as_fraction',
    prompt: 'Write $n as a fraction with denominator $d.',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      '$n is the same as $n wholes.',
      'Each whole = $d/$d, so $n wholes = $n × $d/$d.',
      'Top: $n × $d = $correctNum.',
      'So $n = $correctNum/$d.',
    ],
    answerFormat: AnswerFormat.fraction,
    answerShape: AnswerShape.exactString,
  );
}

/// Add two mixed numbers with the same denominator: combine wholes and
/// add the proper parts (handling carry into the whole when the proper
/// sum exceeds 1). Canonical is the reduced mixed-number form.
GeneratedQuestion addMixedLikeDenom(Random rand) {
  final denominator = rand.nextInt(6) + 3; // 3..8
  final w1 = rand.nextInt(4) + 1; // 1..4
  final w2 = rand.nextInt(4) + 1;
  final n1 = rand.nextInt(denominator - 1) + 1;
  final n2 = rand.nextInt(denominator - 1) + 1;
  final improperA = w1 * denominator + n1;
  final improperB = w2 * denominator + n2;
  final sumNum = improperA + improperB;
  final sumF = Fraction(sumNum, denominator);
  final correct = sumF.toMixed();
  final rawSumTop = n1 + n2; // ones-place sum before carry
  final carried = rawSumTop >= denominator;
  final distractors = _fractionDistractors(
    sumF,
    [
      // Forgot to carry: kept top sum even when ≥ denominator.
      if (carried) '${w1 + w2} $rawSumTop/$denominator',
      // Doubled denominator misconception.
      '${w1 + w2} $rawSumTop/${denominator * 2}',
      // Added everything indiscriminately.
      '${w1 + w2 + 1} $rawSumTop/$denominator',
      // Off-by-one whole.
      '${w1 + w2} ${n1 + n2 - 1}/$denominator',
    ],
    rand,
  );
  return GeneratedQuestion(
    conceptId: 'add_mixed_like_denom',
    prompt: '$w1 $n1/$denominator + $w2 $n2/$denominator = ?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Add the wholes: $w1 + $w2 = ${w1 + w2}.',
      'Add the tops: $n1 + $n2 = $rawSumTop, over $denominator.',
      if (carried)
        'Top is $rawSumTop ≥ $denominator → carry 1 to the wholes.',
      'Sum: $correct.',
    ],
    answerFormat: AnswerFormat.mixedNumber,
  );
}

/// Subtract two mixed numbers with the same denominator. Generator
/// guarantees the result is non-negative.
GeneratedQuestion subMixedLikeDenom(Random rand) {
  final denominator = rand.nextInt(6) + 3; // 3..8
  // Build (w1, n1) − (w2, n2) so the value of the first is ≥ the second.
  var w1 = 0;
  var w2 = 0;
  var n1 = 0;
  var n2 = 0;
  var improperA = 0;
  var improperB = 1; // forces first loop iteration
  while (improperA <= improperB) {
    w1 = rand.nextInt(4) + 2; // 2..5
    w2 = rand.nextInt(w1) + 1; // 1..w1
    n1 = rand.nextInt(denominator - 1) + 1;
    n2 = rand.nextInt(denominator - 1) + 1;
    improperA = w1 * denominator + n1;
    improperB = w2 * denominator + n2;
  }
  final diffNum = improperA - improperB;
  final diffF = Fraction(diffNum, denominator);
  final correct = diffF.toMixed();
  final borrowed = n1 < n2;
  final wholeDiff = w1 - w2;
  final distractors = _fractionDistractors(
    diffF,
    [
      // Forgot to borrow: subtracted tops anyway, getting a negative top.
      if (borrowed && wholeDiff > 0)
        '$wholeDiff ${(n1 - n2).abs()}/$denominator',
      // Added the tops instead of subtracting (or treated borrow as add).
      if (wholeDiff > 0) '$wholeDiff ${n1 + n2}/$denominator',
      // Doubled denominator misconception.
      if (wholeDiff > 0)
        '$wholeDiff ${(n1 - n2).abs()}/${denominator * 2}',
      // Just the whole-part difference, ignoring fractional parts.
      '$wholeDiff',
      // Off-by-one numerator on improper form.
      '${diffNum + 1}/$denominator',
    ],
    rand,
  );
  return GeneratedQuestion(
    conceptId: 'sub_mixed_like_denom',
    prompt: '$w1 $n1/$denominator − $w2 $n2/$denominator = ?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      if (borrowed) 'Top: $n1 < $n2 → borrow 1 from the wholes.',
      if (borrowed)
        'Now: ${w1 - 1} − $w2 wholes, ${n1 + denominator} − $n2 tops.'
      else
        '$w1 − $w2 = ${w1 - w2}; $n1 − $n2 = ${n1 - n2}.',
      'Result: $correct.',
    ],
    answerFormat: AnswerFormat.mixedNumber,
  );
}

/// Add two mixed numbers with different denominators. Reuses the LCM
/// common-denominator strategy, then re-mixes.
GeneratedQuestion addMixedUnlikeDenom(Random rand) {
  var d1 = 0;
  var d2 = 0;
  while (d1 == d2) {
    d1 = rand.nextInt(5) + 2; // 2..6
    d2 = rand.nextInt(5) + 2;
  }
  final w1 = rand.nextInt(3) + 1; // 1..3
  final w2 = rand.nextInt(3) + 1;
  final n1 = rand.nextInt(d1 - 1) + 1;
  final n2 = rand.nextInt(d2 - 1) + 1;
  final improperA = w1 * d1 + n1;
  final improperB = w2 * d2 + n2;
  final common = lcm(d1, d2);
  final scaledA = improperA * (common ~/ d1);
  final scaledB = improperB * (common ~/ d2);
  final sumNum = scaledA + scaledB;
  final sumF = Fraction(sumNum, common);
  final correct = sumF.toMixed();
  final distractors = _fractionDistractors(
    sumF,
    [
      // Added wholes; tops+tops, bottoms+bottoms misconception.
      '${w1 + w2} ${n1 + n2}/${d1 + d2}',
      // Added wholes; multiplied bottoms.
      '${w1 + w2} ${n1 + n2}/${d1 * d2}',
      // Just the wholes — forgot the fractional parts.
      '${w1 + w2}',
      // Off-by-one numerator on improper form.
      '${sumNum + 1}/$common',
    ],
    rand,
  );
  return GeneratedQuestion(
    conceptId: 'add_mixed_unlike_denom',
    prompt: '$w1 $n1/$d1 + $w2 $n2/$d2 = ?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Common bottom is $common.',
      '$w1 $n1/$d1 = $scaledA/$common.',
      '$w2 $n2/$d2 = $scaledB/$common.',
      '$scaledA + $scaledB = $sumNum, so the sum is $sumNum/$common.',
      'As a mixed number: $correct.',
    ],
    answerFormat: AnswerFormat.mixedNumber,
  );
}

/// Subtract two mixed numbers with different denominators. Result ≥ 0.
GeneratedQuestion subMixedUnlikeDenom(Random rand) {
  var d1 = 0;
  var d2 = 0;
  var n1 = 0;
  var n2 = 0;
  var w1 = 0;
  var w2 = 0;
  var common = 0;
  var scaledA = 0;
  var scaledB = 1;
  // Loop until denoms differ, both fractional parts are proper, and
  // scaledA > scaledB so the result is strictly positive.
  while (d1 == d2 || scaledA <= scaledB) {
    d1 = rand.nextInt(5) + 2;
    d2 = rand.nextInt(5) + 2;
    if (d1 == d2) continue;
    w1 = rand.nextInt(3) + 2; // 2..4
    w2 = rand.nextInt(w1) + 1; // 1..w1
    n1 = rand.nextInt(d1 - 1) + 1;
    n2 = rand.nextInt(d2 - 1) + 1;
    common = lcm(d1, d2);
    scaledA = (w1 * d1 + n1) * (common ~/ d1);
    scaledB = (w2 * d2 + n2) * (common ~/ d2);
  }
  final diffNum = scaledA - scaledB;
  final diffF = Fraction(diffNum, common);
  final correct = diffF.toMixed();
  final fractionalDiffAbs = (n1 * d2 - n2 * d1).abs();
  final distractors = _fractionDistractors(
    diffF,
    [
      // Subtracted wholes; tops−tops, bottoms−bottoms misconception.
      () {
        final dDiff = (d1 - d2).abs() == 0 ? d1 : (d1 - d2).abs();
        return '${w1 - w2} ${(n1 - n2).abs()}/$dDiff';
      }(),
      // Subtracted wholes; multiplied bottoms.
      '${w1 - w2} ${(n1 - n2).abs()}/${d1 * d2}',
      // Just the whole-part difference.
      '${w1 - w2}',
      // Off-by-one numerator on improper form.
      '${diffNum + 1}/$common',
      // Common-bottom found but tops subtracted directly.
      '${w1 - w2} $fractionalDiffAbs/$common',
    ],
    rand,
  );
  return GeneratedQuestion(
    conceptId: 'sub_mixed_unlike_denom',
    prompt: '$w1 $n1/$d1 − $w2 $n2/$d2 = ?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Common bottom is $common.',
      '$w1 $n1/$d1 = $scaledA/$common.',
      '$w2 $n2/$d2 = $scaledB/$common.',
      '$scaledA − $scaledB = $diffNum, so the result is $diffNum/$common.',
      'As a mixed number: $correct.',
    ],
    answerFormat: AnswerFormat.mixedNumber,
  );
}

/// Multiply two mixed numbers: convert each to improper, multiply, reduce
/// back to mixed form. Operands chosen small so the answer stays kid-
/// readable.
GeneratedQuestion multMixedNumbers(Random rand) {
  final d1 = rand.nextInt(4) + 2; // 2..5
  final d2 = rand.nextInt(4) + 2;
  final w1 = rand.nextInt(3) + 1; // 1..3
  final w2 = rand.nextInt(3) + 1;
  final n1 = rand.nextInt(d1 - 1) + 1;
  final n2 = rand.nextInt(d2 - 1) + 1;
  final improperA = w1 * d1 + n1;
  final improperB = w2 * d2 + n2;
  final productF = Fraction(improperA * improperB, d1 * d2);
  final correct = productF.toMixed();
  final distractors = _fractionDistractors(
    productF,
    [
      // Distributed naively: multiplied wholes, multiplied fractions,
      // glued them back together (a real misconception for this skill).
      '${w1 * w2} ${n1 * n2}/${d1 * d2}',
      // Forgot to convert: multiplied fractions only, ignored wholes.
      '${n1 * n2}/${d1 * d2}',
      // Multiplied wholes only.
      '${w1 * w2}',
      // Off-by-one numerator on the improper-form product.
      '${improperA * improperB + 1}/${d1 * d2}',
    ],
    rand,
  );
  return GeneratedQuestion(
    conceptId: 'mult_mixed_numbers',
    prompt: '$w1 $n1/$d1 × $w2 $n2/$d2 = ?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Make them improper: $improperA/$d1 and $improperB/$d2.',
      'Tops: $improperA × $improperB = ${improperA * improperB}.',
      'Bottoms: $d1 × $d2 = ${d1 * d2}.',
      'Product: ${improperA * improperB}/${d1 * d2} = $correct.',
    ],
    answerFormat: AnswerFormat.mixedNumber,
  );
}

/// Multiplication as scaling: without computing, decide whether N × a/b
/// is bigger, smaller, or equal to N. Multiple choice over fixed strings.
GeneratedQuestion multAsScaling(Random rand) {
  final n = rand.nextInt(8) + 2; // 2..9 (the "whole" anchor)
  final denominator = rand.nextInt(6) + 2; // 2..7
  // Choose factor as either proper (< 1), improper > 1, or = 1.
  // Bias to proper/improper because = 1 is the rarer case.
  final flavor = rand.nextInt(5); // 0..4
  final int numerator;
  final String result;
  if (flavor == 0) {
    // Equal: numerator == denominator (factor = 1).
    numerator = denominator;
    result = 'the same';
  } else if (flavor < 3) {
    // Proper fraction (< 1): smaller.
    numerator = rand.nextInt(denominator - 1) + 1;
    result = 'smaller';
  } else {
    // Improper (> 1): bigger.
    numerator = denominator + rand.nextInt(denominator - 1) + 1;
    result = 'bigger';
  }
  const pool = ['bigger', 'smaller', 'the same', "can't tell"];
  return GeneratedQuestion(
    conceptId: 'mult_as_scaling',
    prompt:
        'Without computing: $n × $numerator/$denominator is ___ than $n.',
    correctAnswer: result,
    distractors: pool.where((s) => s != result).toList(),
    explanation: [
      if (numerator < denominator)
        '$numerator/$denominator is less than 1.',
      if (numerator > denominator)
        '$numerator/$denominator is more than 1.',
      if (numerator == denominator)
        '$numerator/$denominator equals 1 (top = bottom).',
      '× by less than 1 shrinks; × by more than 1 grows; × by 1 keeps it.',
      'So $n × $numerator/$denominator is $result than $n.',
    ],
  );
}

/// Fraction as division — CCSS framing. "Y kids share X cookies equally"
/// → X/Y per kid. Reuses the word-problem name & edible-item pools so the
/// scenario reads naturally.
///
/// Constrained to X < Y so the canonical answer is always a *proper*
/// fraction (no mixed-number input needed).
GeneratedQuestion fractionAsDivision(Random rand) {
  final kids = rand.nextInt(6) + 3; // 3..8
  final cookies = rand.nextInt(kids - 1) + 1; // 1..kids-1 → proper fraction
  final name = pickRandom(wordProblemNames, rand);
  final item = pickRandom(edibleWordProblemItems, rand);
  final correctF = Fraction(cookies, kids);
  final correct = correctF.toCanonical();
  final distractors = _fractionDistractors(
    correctF,
    [
      '$kids/$cookies', // swapped — sharing is kids ÷ cookies misconception
      '${kids - cookies}/$kids', // subtracted instead of dividing
      '$cookies/${kids + 1}',
      '${cookies + 1}/$kids',
    ],
    rand,
  );
  return GeneratedQuestion(
    conceptId: 'fraction_as_division',
    prompt:
        '$name has $cookies $item to share equally among '
        '$kids friends. How much does each friend get?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Sharing equally means dividing: $cookies ÷ $kids.',
      'That is $cookies/$kids.',
      if (correct != '$cookies/$kids') 'Simplified, that is $correct.',
    ],
    answerFormat: AnswerFormat.fraction,
  );
}
