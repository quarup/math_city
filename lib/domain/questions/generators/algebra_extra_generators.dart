import 'dart:math';

import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/word_problems/word_problem_framework.dart';

/// Text-only algorithmic fill-in: missing_addend_within_20, missing_factor,
/// numerical_pattern_rule, signed_quantities_context,
/// write_expression_from_words, identify_parts_expression,
/// convert_units_within_system, volume_prism_fractional_edges.

const _minus = '−'; // U+2212 — the typeset minus sign

// ─────────────────────────────────────────────────────────────────────────
// missing_addend_within_20 (G1)
// ─────────────────────────────────────────────────────────────────────────

/// "7 + ___ = 12" or "___ + 7 = 12" → answer fills the blank.
/// Distinct from `add_sub_unknown_position` (which mixes 4 patterns
/// including subtraction) — this one is strictly addend-finding.
GeneratedQuestion missingAddendWithin20(Random rand) {
  late int a;
  late int sum;
  do {
    a = rand.nextInt(18) + 1; // 1..18
    sum = rand.nextInt(19 - a) + a + 1; // > a, ≤ 19
  } while (sum > 19);
  final correct = sum - a;
  final blankFirst = rand.nextBool();
  final prompt = blankFirst ? '___ + $a = $sum' : '$a + ___ = $sum';
  return GeneratedQuestion(
    conceptId: 'missing_addend_within_20',
    prompt: prompt,
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      // Misconception: added instead of subtracted.
      misconception: a + sum,
    ),
    explanation: ['$a + $correct = $sum'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// missing_factor (G3)
// ─────────────────────────────────────────────────────────────────────────

/// "What number, when multiplied by 6, gives 42?" → 7. Word-form variant
/// of `div_as_unknown_factor` (which uses `___ × 6 = 42` symbol form).
GeneratedQuestion missingFactor(Random rand) {
  final known = rand.nextInt(8) + 2; // 2..9
  final answer = rand.nextInt(9) + 1; // 1..9
  final product = known * answer;
  return GeneratedQuestion(
    conceptId: 'missing_factor',
    prompt:
        'What number, when multiplied by $known, gives $product?',
    correctAnswer: '$answer',
    distractors: integerDistractorsWith(
      answer,
      rand,
      misconception: product - known, // subtracted instead of divided
    ),
    explanation: ['$known × $answer = $product'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// numerical_pattern_rule (G4)
// ─────────────────────────────────────────────────────────────────────────

/// "Look at the pattern: 5, 10, 15, 20. What is the rule?" → "Add 5".
/// MC over 4 rule-strings: correct add-step + add-step±1 + multiply-by-2
/// (looks-similar-but-different). CCSS 4.OA.C.5 — Generate a number
/// pattern that follows a given rule.
GeneratedQuestion numericalPatternRule(Random rand) {
  final step = rand.nextInt(8) + 2; // 2..9
  final start = rand.nextInt(9) + 1; // 1..9
  final t0 = start;
  final t1 = t0 + step;
  final t2 = t1 + step;
  final t3 = t2 + step;
  final correct = 'Add $step each time';
  final distractors = <String>{
    'Add ${step + 1} each time',
    'Add ${step - 1} each time',
    'Multiply by 2 each time',
    'Multiply by $step each time',
    if (step + 2 < 12) 'Add ${step + 2} each time',
  }..remove(correct);
  final list = distractors.toList()..shuffle(rand);
  return GeneratedQuestion(
    conceptId: 'numerical_pattern_rule',
    prompt: 'Look at the pattern: $t0, $t1, $t2, $t3. What is the rule?',
    correctAnswer: correct,
    distractors: list.take(3).toList(),
    explanation: [
      '$t1 − $t0 = $step, $t2 − $t1 = $step, $t3 − $t2 = $step.',
      'Each term is $step more than the one before.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// signed_quantities_context (G6)
// ─────────────────────────────────────────────────────────────────────────

const _signedScenarios = [
  ('owes', 'has', 'dollars'),
  ('is below sea level', 'is above sea level', 'meters'),
  ('lost', 'gained', 'points'),
  ('is below zero', 'is above zero', 'degrees Celsius'),
];

/// "Maria owes \$10. What integer represents this?" → −10.
/// 50/50 negative/positive context.
GeneratedQuestion signedQuantitiesContext(Random rand) {
  final scenario = _signedScenarios[rand.nextInt(_signedScenarios.length)];
  final isNegative = rand.nextBool();
  final magnitude = rand.nextInt(50) + 5; // 5..54
  final correct = isNegative ? -magnitude : magnitude;
  final action = isNegative ? scenario.$1 : scenario.$2;
  final name = pickRandom(wordProblemNames, rand);
  return GeneratedQuestion(
    conceptId: 'signed_quantities_context',
    prompt:
        '$name $action $magnitude ${scenario.$3}. '
        'Which integer represents this situation?',
    correctAnswer: _signed(correct),
    distractors: [
      _signed(-correct), // wrong sign
      '0',
      _signed(correct + (isNegative ? -1 : 1)),
    ],
    explanation: [
      '"$action" means the value is ${isNegative ? "below" : "above"} zero.',
      'So the integer is ${_signed(correct)}.',
    ],
  );
}

String _signed(int n) {
  if (n == 0) return '0';
  return n < 0 ? '$_minus${-n}' : '+$n';
}

// ─────────────────────────────────────────────────────────────────────────
// write_expression_from_words (G6)
// ─────────────────────────────────────────────────────────────────────────

const _exprTemplates = [
  // (template, expression-builder)
  ('the sum of n and {b}', '+'),
  ('{b} more than n', 'plus_after'),
  ('the difference of n and {b}', '-'),
  ('{b} less than n', 'minus_after'),
  ('the product of n and {b}', '*'),
  ('{b} times n', 'mult'),
  ('n divided by {b}', '/'),
];

/// "Write an expression for: 5 more than a number n." → MC over four
/// expression strings. Tests the kid's ability to translate English to
/// algebra.
GeneratedQuestion writeExpressionFromWords(Random rand) {
  final tmpl = _exprTemplates[rand.nextInt(_exprTemplates.length)];
  final b = rand.nextInt(8) + 2; // 2..9
  final phrase = tmpl.$1.replaceAll('{b}', '$b');
  final correct = switch (tmpl.$2) {
    '+' => 'n + $b',
    'plus_after' => 'n + $b',
    '-' => 'n − $b',
    'minus_after' => 'n − $b',
    '*' => '$b·n',
    'mult' => '$b·n',
    _ => 'n ÷ $b',
  };
  // Distractor pool — kid-realistic misreads:
  final pool = <String>{
    '$b + n', // commutativity-irrelevant for + but matters for −/÷
    '$b − n',
    'n − $b',
    'n + $b',
    '$b·n',
    'n·$b',
    'n ÷ $b',
    '$b ÷ n',
  }..remove(correct);
  final list = pool.toList()..shuffle(rand);
  return GeneratedQuestion(
    conceptId: 'write_expression_from_words',
    prompt: 'Which expression matches "$phrase"?',
    correctAnswer: correct,
    distractors: list.take(3).toList(),
    explanation: ['"$phrase" → $correct'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// identify_parts_expression (G6)
// ─────────────────────────────────────────────────────────────────────────

/// "In the expression 4x + 7, what is the coefficient of x?" → 4.
/// Three question shapes drawn uniformly: coefficient / constant / # of
/// terms. CCSS 6.EE.A.2 — Identify parts of an expression.
GeneratedQuestion identifyPartsExpression(Random rand) {
  // Two-term expression `ax + b` with `a ∈ [2, 9]`, `b ∈ [1, 19]`.
  final a = rand.nextInt(8) + 2;
  final b = rand.nextInt(19) + 1;
  final flavor = rand.nextInt(3);
  late String prompt;
  late String correct;
  late List<String> distractors;
  switch (flavor) {
    case 0: // coefficient
      prompt =
          'In the expression ${a}x + $b, what is the coefficient of x?';
      correct = '$a';
      distractors = integerDistractorsWith(
        a,
        rand,
        misconception: b, // gave the constant
      );
    case 1: // constant
      prompt = 'In the expression ${a}x + $b, what is the constant term?';
      correct = '$b';
      distractors = integerDistractorsWith(
        b,
        rand,
        misconception: a, // gave the coefficient
      );
    default: // # of terms
      prompt = 'How many terms are in the expression ${a}x + $b?';
      correct = '2';
      distractors = ['1', '3', '${a + b}'];
  }
  return GeneratedQuestion(
    conceptId: 'identify_parts_expression',
    prompt: prompt,
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Coefficient of x: $a. Constant term: $b. Number of terms: 2.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// convert_units_within_system (G4)
// ─────────────────────────────────────────────────────────────────────────

const _unitConversions = [
  ('feet', 'inches', 12),
  ('yards', 'feet', 3),
  ('hours', 'minutes', 60),
  ('minutes', 'seconds', 60),
  ('pounds', 'ounces', 16),
  ('meters', 'centimeters', 100),
  ('kilometers', 'meters', 1000),
];

/// "How many inches are in 4 feet?" → 48. Big-unit → small-unit
/// conversion with integer multiplier. Tests CCSS 4.MD.A.1.
GeneratedQuestion convertUnitsWithinSystem(Random rand) {
  final c = _unitConversions[rand.nextInt(_unitConversions.length)];
  final n = rand.nextInt(8) + 2; // 2..9
  final correct = n * c.$3;
  return GeneratedQuestion(
    conceptId: 'convert_units_within_system',
    prompt: 'How many ${c.$2} are in $n ${c.$1}?',
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      misconception: n + c.$3, // added instead of multiplied
    ),
    explanation: [
      '1 ${_singular(c.$1)} = ${c.$3} ${c.$2}.',
      '$n × ${c.$3} = $correct.',
    ],
  );
}

String _singular(String plural) {
  if (plural.endsWith('es')) return plural.substring(0, plural.length - 2);
  if (plural.endsWith('s')) return plural.substring(0, plural.length - 1);
  return plural;
}

// ─────────────────────────────────────────────────────────────────────────
// volume_prism_fractional_edges (G6)
// ─────────────────────────────────────────────────────────────────────────

/// "A rectangular prism has length 1/2 m, width 3 m, height 2 m. Volume?"
/// → 3 m³. l × w × h where at most one edge is a unit fraction so the
/// answer remains a clean whole number.
GeneratedQuestion volumePrismFractionalEdges(Random rand) {
  // l = 1/d with d ∈ {2, 3, 4}; w, h ∈ [2, 12] with w * h divisible by d.
  final d = [2, 3, 4][rand.nextInt(3)];
  late int w;
  late int h;
  do {
    w = rand.nextInt(11) + 2;
    h = rand.nextInt(11) + 2;
  } while ((w * h) % d != 0);
  final correct = (w * h) ~/ d;
  return GeneratedQuestion(
    conceptId: 'volume_prism_fractional_edges',
    prompt:
        'A rectangular prism has length 1/$d m, width $w m, '
        'and height $h m. What is its volume, in cubic meters?',
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      misconception: w * h, // forgot to multiply by 1/d
    ),
    explanation: [
      'V = l × w × h = (1/$d) × $w × $h.',
      '= ${w * h}/$d = $correct.',
    ],
  );
}
