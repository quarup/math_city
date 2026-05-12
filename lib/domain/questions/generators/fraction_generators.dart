import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/fraction.dart';
import 'package:math_city/domain/questions/generated_question.dart';

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
// Phase 5 generators — kept, rewritten to use Fraction + AnswerFormat.
// ---------------------------------------------------------------------------

/// "What fraction is shaded?" — shows a fraction bar and asks for a/b.
///
/// The canonical answer is the *visible* form on the bar (kid counts what
/// they see). [GeneratedQuestion.requiresCanonicalForm] is `true` because
/// this concept's lesson IS "count what's depicted" — simplification is
/// a separate concept (`simplify_fraction`).
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
    requiresCanonicalForm: true,
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
    requiresCanonicalForm: true,
  );
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
