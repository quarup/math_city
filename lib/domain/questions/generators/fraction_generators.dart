import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// "What fraction is shaded?" — shows a fraction bar and asks for a/b.
///
/// Answer is rendered as "a/b". Distractors swap numerator/denominator,
/// off-by-one each.
GeneratedQuestion fractionAOverB(Random rand) {
  final denominator = rand.nextInt(7) + 2; // 2..8
  final numerator = rand.nextInt(denominator - 1) + 1; // 1..denom-1 (proper)
  final correct = '$numerator/$denominator';
  final distractors = _fractionDistractors(
    correct,
    numerator,
    denominator,
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
  );
}

/// Compare two fractions with the same denominator. Answer is the larger
/// fraction (ties excluded).
GeneratedQuestion compareFractionsSameDenom(Random rand) {
  final denominator = rand.nextInt(7) + 3; // 3..9
  // Two distinct numerators in [1, denom].
  final n1 = rand.nextInt(denominator - 1) + 1;
  int n2;
  do {
    n2 = rand.nextInt(denominator) + 1; // 1..denom (allow n2 = denom)
  } while (n2 == n1);
  final left = '$n1/$denominator';
  final right = '$n2/$denominator';
  final correct = n1 > n2 ? left : right;
  final wrong = n1 > n2 ? right : left;
  // Distractors: the smaller one + 2 misleading "equal" or "swapped" forms.
  final distractors = <String>[
    wrong,
    'They are equal',
    '$n1+$n2/$denominator',
  ];
  return GeneratedQuestion(
    conceptId: 'compare_fractions_same_denom',
    prompt: 'Which is bigger: $left or $right?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Both fractions have $denominator on the bottom.',
      'So just compare the tops: ${n1 > n2 ? '$n1 > $n2' : '$n2 > $n1'}.',
      '$correct is bigger.',
    ],
  );
}

/// "Is a/b equal to c/d?" with a fraction-bar visualisation.
///
/// We always show two fraction bars (one on each side) where one represents
/// the original fraction and the other is either equivalent (correct
/// answer = "Yes") or near-equivalent (correct = "No"). For Phase 5 we
/// just ask the player to *find an equivalent fraction* given a target —
/// MC over ratios.
GeneratedQuestion equivalentFractionsVisual(Random rand) {
  final denominator = rand.nextInt(4) + 2; // 2..5
  final numerator = rand.nextInt(denominator - 1) + 1; // proper
  final multiplier = rand.nextInt(3) + 2; // 2..4
  final equivN = numerator * multiplier;
  final equivD = denominator * multiplier;
  final correct = '$equivN/$equivD';
  // Distractors: only-num scaled, only-denom scaled, off-by-one.
  final distractors = <String>{
    '${numerator * multiplier}/$denominator',
    '$numerator/${denominator * multiplier}',
    '${equivN + 1}/$equivD',
    '$equivN/${equivD + 1}',
  }..remove(correct);
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
    distractors: distractors.take(3).toList(),
    explanation: [
      '$numerator × $multiplier = $equivN',
      '$denominator × $multiplier = $equivD',
      'So $numerator/$denominator = $equivN/$equivD.',
    ],
  );
}

/// Add fractions with like denominators: a/d + b/d = (a+b)/d.
/// Distractor includes the "added denominators too" misconception.
GeneratedQuestion addFractionsLikeDenom(Random rand) {
  final denominator = rand.nextInt(6) + 3; // 3..8
  final a = rand.nextInt(denominator - 1) + 1; // 1..denom-1
  final b = rand.nextInt(denominator - a) + 1; // 1..denom-a, sum ≤ denom
  final sumNum = a + b;
  final correct = '$sumNum/$denominator';
  final distractors = <String>{
    '$sumNum/${denominator * 2}', // misconception: added denoms
    '${a + b + 1}/$denominator', // off-by-one
    '${a > 0 ? a - 1 : a + 1}/$denominator', // close
    '$sumNum/${denominator + 1}', // wrong denom
  }..remove(correct);
  return GeneratedQuestion(
    conceptId: 'add_fractions_like_denom',
    prompt: '$a/$denominator + $b/$denominator = ?',
    correctAnswer: correct,
    distractors: distractors.take(3).toList(),
    explanation: [
      'Same bottoms — just add the tops.',
      '$a + $b = $sumNum',
      'Bottom stays $denominator. Answer: $sumNum/$denominator.',
    ],
  );
}

List<String> _fractionDistractors(
  String correct,
  int numerator,
  int denominator,
  Random rand,
) {
  final candidates = <String>{
    '$denominator/$numerator', // swapped
    '${numerator + 1}/$denominator',
    '$numerator/${denominator + 1}',
    if (numerator > 1) '${numerator - 1}/$denominator',
    '$numerator/${denominator - 1}',
  }..remove(correct);
  final list = candidates.toList()..shuffle(rand);
  // Pad if pool is too thin (very small fractions).
  while (list.length < 3) {
    final pad = '${numerator + list.length + 2}/${denominator + 1}';
    if (pad != correct && !list.contains(pad)) list.add(pad);
  }
  return list.take(3).toList();
}
