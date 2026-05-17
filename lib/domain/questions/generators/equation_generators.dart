import 'dart:math';

import 'package:math_city/domain/questions/generated_question.dart';

/// Order-of-operations + expression-evaluation + one-/two-step-equation
/// generators (Grades 5–7).
///
/// All math is integer-only. Division is generated as
/// `dividend = quotient × divisor` for exact integer answers. The minus
/// sign for negative results uses U+2212 to match the other generator
/// families' convention.

const _minus = '−'; // U+2212

// ─────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────

String _signed(int n) => n >= 0 ? '$n' : '$_minus${-n}';

/// Three distinct signed-integer-string distractors that differ from
/// [correct].
List<String> _intDistractors(
  int correct,
  List<String> candidates,
  Random rand,
) {
  final out = <String>[];
  final seen = <String>{_signed(correct)};
  for (final c in candidates) {
    if (out.length >= 3) break;
    if (seen.add(c)) out.add(c);
  }
  for (var i = 1; out.length < 3 && i < 30; i++) {
    for (final delta in <int>[i, -i]) {
      final s = _signed(correct + delta);
      if (seen.add(s)) out.add(s);
      if (out.length >= 3) break;
    }
  }
  return out.take(3).toList();
}

// ─────────────────────────────────────────────────────────────────────────
// order_of_operations_no_exp (Grade 5)
// ─────────────────────────────────────────────────────────────────────────

/// "3 + 4 × 2 = ?" → 11. Three-operand expressions with two operators
/// drawn from {+, −, ×, ÷}. Division only when the kid would actually
/// get an exact integer; subtraction only when the result stays ≥ 0.
GeneratedQuestion orderOfOperationsNoExp(Random rand) {
  const ops = <String>['+', '−', '×', '÷'];
  // Re-roll until we get a tractable expression.
  late int a;
  late int b;
  late int c;
  late String op1;
  late String op2;
  late int answer;
  late int wrongAnswer;
  var attempts = 0;
  while (true) {
    attempts++;
    a = rand.nextInt(19) + 2; // 2..20
    b = rand.nextInt(9) + 2; // 2..10
    c = rand.nextInt(9) + 2; // 2..10
    op1 = ops[rand.nextInt(ops.length)];
    op2 = ops[rand.nextInt(ops.length)];
    // Evaluate with precedence: × and ÷ before + and −. Equal-precedence
    // operators are left-to-right, so the right-grouping branch only
    // applies when op2 strictly binds tighter than op1.
    final pre1 = _prec(op1);
    final pre2 = _prec(op2);
    int? answerCandidate;
    int? wrongCandidate;
    if (pre2 > pre1) {
      // op2 binds tighter: compute (b op2 c) first, then a op1 ?.
      final bc = _apply(b, op2, c);
      if (bc == null) continue;
      final res = _apply(a, op1, bc);
      if (res == null || res < 0) continue;
      answerCandidate = res;
      // Left-to-right wrong: (a op1 b) op2 c.
      final ab = _apply(a, op1, b);
      if (ab == null) continue;
      final left = _apply(ab, op2, c);
      if (left == null) continue;
      wrongCandidate = left;
    } else {
      // op1 binds tighter (× / ÷ before + / −): compute (a op1 b) then op2 c.
      final ab = _apply(a, op1, b);
      if (ab == null) continue;
      final res = _apply(ab, op2, c);
      if (res == null || res < 0) continue;
      answerCandidate = res;
      // Right-to-left wrong: a op1 (b op2 c).
      final bc = _apply(b, op2, c);
      if (bc == null) continue;
      final right = _apply(a, op1, bc);
      if (right == null) continue;
      wrongCandidate = right;
    }
    answer = answerCandidate;
    wrongAnswer = wrongCandidate;
    // Want the wrong answer to be different from the right answer so
    // the misconception distractor is meaningful.
    if (answer != wrongAnswer && answer <= 200) break;
    if (attempts > 80) break;
  }

  return GeneratedQuestion(
    conceptId: 'order_of_operations_no_exp',
    prompt: '$a $op1 $b $op2 $c = ?',
    correctAnswer: _signed(answer),
    distractors: _intDistractors(answer, <String>[
      _signed(wrongAnswer), // ignored precedence
    ], rand),
    explanation: [
      '× and ÷ before + and −.',
      '$a $op1 $b $op2 $c = ${_signed(answer)}.',
    ],
  );
}

int _prec(String op) => (op == '×' || op == '÷') ? 2 : 1;

int? _apply(int x, String op, int y) {
  switch (op) {
    case '+':
      return x + y;
    case '−':
      return x - y;
    case '×':
      return x * y;
    case '÷':
      if (y == 0 || x % y != 0) return null;
      return x ~/ y;
  }
  return null;
}

// ─────────────────────────────────────────────────────────────────────────
// nested_grouping (Grade 5)
// ─────────────────────────────────────────────────────────────────────────

/// "(3 + 4) × 2 = ?" → 14. Parenthesised pair followed (or preceded)
/// by an operator and a third operand. The parens always change the
/// outcome — otherwise the question doesn't exercise grouping.
GeneratedQuestion nestedGrouping(Random rand) {
  const ops = <String>['+', '−', '×', '÷'];
  late int a;
  late int b;
  late int c;
  late String inner;
  late String outer;
  late bool parenOnLeft;
  late int answer;
  late int withoutParens;
  var attempts = 0;
  while (true) {
    attempts++;
    a = rand.nextInt(19) + 2; // 2..20
    b = rand.nextInt(9) + 2;
    c = rand.nextInt(9) + 2;
    inner = ops[rand.nextInt(ops.length)];
    outer = ops[rand.nextInt(ops.length)];
    parenOnLeft = rand.nextBool();
    int? grouped;
    int? plain;
    if (parenOnLeft) {
      // (a inner b) outer c
      final ab = _apply(a, inner, b);
      if (ab == null) continue;
      grouped = _apply(ab, outer, c);
      // Without parens: a inner b outer c (use normal precedence).
      plain = _evalPrecedence(a, inner, b, outer, c);
    } else {
      // a outer (b inner c)
      final bc = _apply(b, inner, c);
      if (bc == null) continue;
      grouped = _apply(a, outer, bc);
      plain = _evalPrecedence(a, outer, b, inner, c);
    }
    if (grouped == null || grouped < 0 || grouped > 200) continue;
    if (plain == null) continue;
    if (grouped == plain) continue; // parens must matter
    answer = grouped;
    withoutParens = plain;
    break;
  }

  if (attempts > 80) {
    // Fallback to a deterministic safe case if generation kept rejecting.
    a = 3;
    b = 4;
    c = 2;
    inner = '+';
    outer = '×';
    parenOnLeft = true;
    answer = (a + b) * c;
    withoutParens = a + b * c;
  }

  final prompt = parenOnLeft
      ? '($a $inner $b) $outer $c = ?'
      : '$a $outer ($b $inner $c) = ?';

  return GeneratedQuestion(
    conceptId: 'nested_grouping',
    prompt: prompt,
    correctAnswer: _signed(answer),
    distractors: _intDistractors(answer, <String>[
      _signed(withoutParens), // ignored the parens entirely
    ], rand),
    explanation: [
      'Do what is inside the parentheses first.',
      '$prompt → ${_signed(answer)}.',
    ],
  );
}

int? _evalPrecedence(int a, String op1, int b, String op2, int c) {
  if (_prec(op2) > _prec(op1)) {
    final bc = _apply(b, op2, c);
    if (bc == null) return null;
    return _apply(a, op1, bc);
  } else {
    final ab = _apply(a, op1, b);
    if (ab == null) return null;
    return _apply(ab, op2, c);
  }
}

// ─────────────────────────────────────────────────────────────────────────
// evaluate_expression (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "Evaluate 3x + 5 when x = 4" → 17. Linear form ax + b with a in
/// [2, 9], b in [1, 20], x in [2, 12].
GeneratedQuestion evaluateExpression(Random rand) {
  final a = rand.nextInt(8) + 2; // 2..9
  final b = rand.nextInt(20) + 1; // 1..20
  final x = rand.nextInt(11) + 2; // 2..12
  final answer = a * x + b;
  final correct = '$answer';

  // Misconception distractors:
  //   - added a, b, x without multiplying.
  //   - forgot the +b term.
  //   - multiplied b too.
  final candidates = <String>[
    '${a + b + x}',
    '${a * x}',
    '${a * (x + b)}',
    '${(a + b) * x}',
  ];

  return GeneratedQuestion(
    conceptId: 'evaluate_expression',
    prompt: 'Evaluate ${a}x + $b when x = $x.',
    correctAnswer: correct,
    distractors: _intDistractors(answer, candidates, rand),
    explanation: [
      'Substitute x = $x: $a × $x + $b.',
      '$a × $x = ${a * x}.',
      '${a * x} + $b = $answer.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// solve_one_step_eq_addition (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "Solve x + 5 = 12" → 7. Two variants: addition and subtraction of a
/// known constant. Answer is always a positive integer.
GeneratedQuestion solveOneStepEqAddition(Random rand) {
  final x = rand.nextInt(19) + 2; // 2..20
  final p = rand.nextInt(19) + 2; // 2..20
  final isAddition = rand.nextBool();
  // x + p = q  → q = x + p
  // x − p = q  → q = x − p; need q ≥ 0 (allow 0).
  late int q;
  if (isAddition) {
    q = x + p;
  } else {
    q = x - p;
    if (q < 0) {
      // re-roll p smaller
      final p2 = rand.nextInt(x - 1) + 1;
      q = x - p2;
      return _buildOneStepAddition(x, p2, q, isAddition: false, rand: rand);
    }
  }
  return _buildOneStepAddition(x, p, q, isAddition: isAddition, rand: rand);
}

GeneratedQuestion _buildOneStepAddition(
  int x,
  int p,
  int q, {
  required bool isAddition,
  required Random rand,
}) {
  final op = isAddition ? '+' : _minus;
  final prompt = 'Solve for x: x $op $p = $q';
  final correct = '$x';
  final candidates = <String>[
    // Misconception: did the same op instead of inverse.
    '${isAddition ? q + p : q - p}',
    // Misconception: swapped sides without inversion.
    '${q + p}',
    '${(q - p).abs()}',
  ];
  return GeneratedQuestion(
    conceptId: 'solve_one_step_eq_addition',
    prompt: prompt,
    correctAnswer: correct,
    distractors: _intDistractors(x, candidates, rand),
    explanation: [
      if (isAddition)
        'Subtract $p from both sides: x = $q − $p.'
      else
        'Add $p to both sides: x = $q + $p.',
      'x = $x.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// solve_one_step_eq_mult (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "Solve 3x = 12" → 4. Two variants: multiplication (px = q) and
/// division (x/p = q). Always integer answers.
GeneratedQuestion solveOneStepEqMult(Random rand) {
  final p = rand.nextInt(8) + 2; // 2..9 (avoid 0, 1)
  final x = rand.nextInt(11) + 2; // 2..12
  final isMult = rand.nextBool();
  if (isMult) {
    final q = p * x;
    return _buildOneStepMult(x, p, q, isMult: true, rand: rand);
  }
  // Division form: x ÷ p = q, with x = p × q so the answer is x.
  final qActual = x;
  final xActual = p * qActual;
  return _buildOneStepMult(xActual, p, qActual, isMult: false, rand: rand);
}

GeneratedQuestion _buildOneStepMult(
  int x,
  int p,
  int q, {
  required bool isMult,
  required Random rand,
}) {
  final correct = '$x';
  final candidates = <String>[
    // Misconception: same op instead of inverse.
    '${isMult ? p * q : q ~/ (p == 0 ? 1 : p)}',
    // Misconception: subtract instead of divide.
    '${(q - p).abs()}',
    '${q + p}',
  ];
  return GeneratedQuestion(
    conceptId: 'solve_one_step_eq_mult',
    prompt: isMult ? 'Solve for x: ${p}x = $q' : 'Solve for x: x ÷ $p = $q',
    correctAnswer: correct,
    distractors: _intDistractors(x, candidates, rand),
    explanation: [
      if (isMult)
        'Divide both sides by $p: x = $q ÷ $p.'
      else
        'Multiply both sides by $p: x = $q × $p.',
      'x = $x.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// solve_two_step_eq (Grade 7)
// ─────────────────────────────────────────────────────────────────────────

/// "Solve 3x + 5 = 14" → 3. Two-step form `px + q = r` or `px − q = r`.
/// Answer is always a positive integer x ∈ [2, 12].
GeneratedQuestion solveTwoStepEq(Random rand) {
  final x = rand.nextInt(11) + 2; // 2..12
  final p = rand.nextInt(8) + 2; // 2..9
  final q = rand.nextInt(19) + 1; // 1..19
  final isPlus = rand.nextBool();
  final r = isPlus ? p * x + q : p * x - q;
  // Re-roll if r came out negative under the subtract branch.
  if (r < 1) return solveTwoStepEq(rand);

  final op = isPlus ? '+' : _minus;
  final prompt = 'Solve for x: ${p}x $op $q = $r';
  final correct = '$x';
  final candidates = <String>[
    // Misconception: forgot to undo the +/−.
    '${r ~/ p}',
    // Misconception: applied operations in wrong order.
    '${(r - q) ~/ (p == 0 ? 1 : p) + (isPlus ? q : -q)}',
    // Misconception: subtracted/added instead of dividing.
    '${r - p}',
  ];

  return GeneratedQuestion(
    conceptId: 'solve_two_step_eq',
    prompt: prompt,
    correctAnswer: correct,
    distractors: _intDistractors(x, candidates, rand),
    explanation: [
      if (isPlus)
        'Subtract $q from both sides: ${p}x = $r − $q = ${p * x}.'
      else
        'Add $q to both sides: ${p}x = $r + $q = ${p * x}.',
      'Divide both sides by $p: x = ${p * x} ÷ $p = $x.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// expand_linear_expression (Grade 7)
// ─────────────────────────────────────────────────────────────────────────

/// "Expand 3(x + 4)" → "3x + 12". MC over four expansion variants
/// (the right answer, the "didn't distribute" answer, the "added
/// instead of multiplied" answer, etc.).
GeneratedQuestion expandLinearExpression(Random rand) {
  final a = rand.nextInt(8) + 2; // 2..9
  final b = rand.nextInt(11) + 2; // 2..12
  final isPlus = rand.nextBool();
  final op = isPlus ? '+' : _minus;
  final prompt = 'Expand: $a(x $op $b)';
  final product = a * b;
  final correct = '${a}x $op $product';
  final distractors = <String>[
    // Misconception: didn't distribute to the constant term.
    '${a}x $op $b',
    // Misconception: distributed to x only, kept the constant.
    'x $op $product',
    // Misconception: added instead of multiplied (a + x style).
    '${a + 1}x $op $product',
  ];

  return GeneratedQuestion(
    conceptId: 'expand_linear_expression',
    prompt: prompt,
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Distribute $a to both terms inside the parentheses.',
      '$a × x = ${a}x; $a × $b = $product.',
      'Result: $correct.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// add_subtract_linear_expressions (Grade 7)
// ─────────────────────────────────────────────────────────────────────────

/// "Simplify 3x + 5 + 2x − 1" → "5x + 4". Combines two linear terms
/// each of shape `ax + b` (b can be any integer). Answer is the
/// canonical `cx + d` form, MC-only.
GeneratedQuestion addSubtractLinearExpressions(Random rand) {
  // First term: a1·x + b1 with a1 in [1, 7], b1 in [1, 9].
  final a1 = rand.nextInt(7) + 1;
  final b1 = rand.nextInt(9) + 1;
  // Second term added or subtracted; both terms kept positive in their
  // shown form so the prompt reads like "3x + 5 + 2x + 1" or
  // "3x + 5 + 2x − 1" — no nested-negative gymnastics.
  final isPlus = rand.nextBool();
  final a2 = rand.nextInt(7) + 1;
  final b2 = rand.nextInt(9) + 1;

  final op = isPlus ? '+' : _minus;
  // Use a parenthesised second pair so the sign rule is unambiguous:
  //   "3x + 5 + (2x + 1)" → "3x + 5 + 2x + 1"
  //   "3x + 5 − (2x + 1)" → "3x + 5 − 2x − 1"
  final actualA = a1 + (isPlus ? a2 : -a2);
  final actualB = b1 + (isPlus ? b2 : -b2);
  // Re-roll degenerate cases (zero x or zero constant — too easy / odd).
  if (actualA == 0 || actualB == 0) return addSubtractLinearExpressions(rand);
  // Re-roll if the result has a negative coefficient — keeps the answer
  // in the canonical "cx + d" form rather than "−cx ± d".
  if (actualA < 0) return addSubtractLinearExpressions(rand);

  final correct = actualB > 0
      ? '${actualA}x + $actualB'
      : '${actualA}x $_minus ${-actualB}';
  final prompt2 = 'Simplify: ${a1}x + $b1 $op (${a2}x + $b2)';
  // Misconception distractors. The "didn't apply sign to constant"
  // distractor is the same as correct when isPlus, so use it only in
  // the subtraction branch.
  final candidatePool = <String>[
    if (!isPlus) '${actualA}x + ${b1 + b2}',
    // Combined x coefficients only (forgot to apply sign to a2).
    if (!isPlus) '${a1 + a2}x + $actualB',
    // Did the op on x and constant separately but used the wrong sign.
    '${a1 - (isPlus ? -a2 : a2)}x + $actualB',
    // Added everything as a single constant.
    '${a1 + b1 + (isPlus ? a2 + b2 : -(a2 + b2))}',
    // Swapped x coefficient with constant.
    '${actualB}x + $actualA',
  ];
  final distractors = <String>[];
  final seen = <String>{correct};
  for (final c in candidatePool) {
    if (distractors.length >= 3) break;
    if (seen.add(c)) distractors.add(c);
  }
  // Fallback: bump the x coefficient ±1.
  for (var i = 1; distractors.length < 3 && i < 10; i++) {
    for (final delta in <int>[i, -i]) {
      final na = actualA + delta;
      if (na < 1) continue;
      final s = '${na}x ${actualB > 0 ? "+" : _minus} ${actualB.abs()}';
      if (seen.add(s)) distractors.add(s);
      if (distractors.length >= 3) break;
    }
  }

  return GeneratedQuestion(
    conceptId: 'add_subtract_linear_expressions',
    prompt: prompt2,
    correctAnswer: correct,
    distractors: distractors.take(3).toList(),
    explanation: [
      'Combine x terms: ${a1}x ${isPlus ? "+" : _minus} ${a2}x = ${actualA}x.',
      'Combine constants: $b1 ${isPlus ? "+" : _minus} $b2 = $actualB.',
      'Result: $correct.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// equivalent_expressions_props (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "Which is equivalent to 3(x + 2)?" → "3x + 6". MC over a small
/// menu of expansion / distribution variants.
GeneratedQuestion equivalentExpressionsProps(Random rand) {
  final a = rand.nextInt(7) + 2; // 2..8
  final b = rand.nextInt(8) + 2; // 2..9
  final correct = '${a}x + ${a * b}';
  final distractors = <String>[
    // Misconception: didn't distribute.
    '${a}x + $b',
    // Misconception: distributed to one side only.
    'x + ${a * b}',
    // Misconception: added a + b first.
    '${a + b}x + ${a * b}',
  ];

  return GeneratedQuestion(
    conceptId: 'equivalent_expressions_props',
    prompt: 'Which is equivalent to $a(x + $b)?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Distributive property: $a(x + $b) = $a·x + $a·$b.',
      '= ${a}x + ${a * b}.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// factor_linear_expression (Grade 7)
// ─────────────────────────────────────────────────────────────────────────

/// "Factor 6x + 12" → "6(x + 2)". Picks a GCF k ≥ 2 and inner
/// expression (x + b), then expands to get the prompt; the answer is
/// the original factored form. MC over four plausible factored forms.
GeneratedQuestion factorLinearExpression(Random rand) {
  int k;
  int b;
  do {
    k = rand.nextInt(7) + 2; // 2..8
    b = rand.nextInt(8) + 2; // 2..9
  } while (k == b); // avoid distractor `b(x + k)` colliding with correct
  final coeff = k;
  final constant = k * b;
  final prompt = 'Factor: ${coeff}x + $constant';
  final correct = '$k(x + $b)';
  final distractors = <String>[
    // Misconception: factored out coefficient but kept constant unchanged.
    '$k(x + $constant)',
    // Misconception: used the wrong GCF (b instead of k).
    '$b(x + $k)',
    // Misconception: factored x out.
    'x($k + $constant)',
  ];

  return GeneratedQuestion(
    conceptId: 'factor_linear_expression',
    prompt: prompt,
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'GCF of $coeff and $constant is $k.',
      '$coeff = $k × 1, so ${coeff}x = $k × x; $constant = $k × $b.',
      'Pull out $k: $correct.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// solve_two_step_eq_distributive (Grade 7)
// ─────────────────────────────────────────────────────────────────────────

/// "Solve 3(x + 2) = 12" → 2. Three-step solve: distribute, then
/// subtract, then divide. Integer x ∈ [2, 9].
GeneratedQuestion solveTwoStepEqDistributive(Random rand) {
  final p = rand.nextInt(7) + 2; // 2..8
  final q = rand.nextInt(9) + 1; // 1..9
  final x = rand.nextInt(8) + 2; // 2..9
  final isPlus = rand.nextBool();
  final inner = isPlus ? x + q : x - q;
  if (inner < 1) return solveTwoStepEqDistributive(rand);
  final r = p * inner;
  final op = isPlus ? '+' : _minus;
  final prompt = 'Solve for x: $p(x $op $q) = $r';
  final correct = '$x';
  final candidates = <String>[
    // Misconception: didn't distribute (treated as p × x = r).
    '${r ~/ p}',
    // Misconception: distributed but did the wrong inverse op.
    '${isPlus ? inner + q : inner - q}',
    // Off-by-one.
    '${x + 1}',
  ];

  return GeneratedQuestion(
    conceptId: 'solve_two_step_eq_distributive',
    prompt: prompt,
    correctAnswer: correct,
    distractors: _intDistractors(x, candidates, rand),
    explanation: [
      'Distribute: ${p}x ${isPlus ? "+" : _minus} ${p * q} = $r.',
      'Then ${isPlus ? "subtract ${p * q}" : "add ${p * q}"} and divide by $p.',
      'x = $x.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// solve_linear_eq_one_solution (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// "Solve 3x + 5 = 2x + 11" → 6. Variable on both sides; always pick
/// coefficients so the resulting one-step `(a−c)x = d−b` has an integer
/// solution.
GeneratedQuestion solveLinearEqOneSolution(Random rand) {
  // Pick the answer x, then pick a, b, c, d such that
  //   a·x + b = c·x + d  AND  a != c.
  final x = rand.nextInt(8) + 2; // 2..9
  int a;
  int c;
  do {
    a = rand.nextInt(7) + 2; // 2..8
    c = rand.nextInt(5) + 1; // 1..5
  } while (a == c);
  // Pick a small positive intercept on the right; then b = c·x + d − a·x.
  final d = rand.nextInt(9) + 1; // 1..9
  final b = (c - a) * x + d;
  // Require b ≥ 1 so the prompt reads naturally (no negative constants).
  if (b < 1) return solveLinearEqOneSolution(rand);
  final prompt = 'Solve for x: ${a}x + $b = ${c}x + $d';
  final correct = '$x';
  final candidates = <String>[
    // Misconception: divided d by a.
    '${d ~/ (a == 0 ? 1 : a)}',
    // Misconception: ignored variable on right.
    '${(d - b) ~/ (a == 0 ? 1 : a)}',
    // Off-by-one.
    '${x + 1}',
  ];

  return GeneratedQuestion(
    conceptId: 'solve_linear_eq_one_solution',
    prompt: prompt,
    correctAnswer: correct,
    distractors: _intDistractors(x, candidates, rand),
    explanation: [
      'Move x terms to one side: (${a - c})x = ${d - b}.',
      'Divide by ${a - c}: x = ${d - b} ÷ ${a - c} = $x.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// inequality_one_var_intro (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "Which inequality is true for x = 5?" → MC over {x > 3, x < 3,
/// x ≥ 6, x = 5}. Tests basic inequality-symbol comprehension.
GeneratedQuestion inequalityOneVarIntro(Random rand) {
  // Pick the value of x, then a constant c < x so "x > c" is true.
  final x = rand.nextInt(8) + 3; // 3..10
  final cLess = rand.nextInt(x - 1) + 1; // 1..x-1 (strict less)
  final cGreater = x + rand.nextInt(5) + 1; // x+1..x+5
  // Correct: x > cLess.
  final correct = 'x > $cLess';
  final distractors = <String>[
    'x < $cLess', // wrong direction
    'x > $cGreater', // not satisfied
    'x = ${x + 1}', // value-equality, wrong number
  ];

  return GeneratedQuestion(
    conceptId: 'inequality_one_var_intro',
    prompt: 'Which inequality is true when x = $x?',
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Check each: is x = $x bigger than $cLess? Yes.',
      'So x > $cLess is true.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// solve_two_step_inequality (Grade 7)
// ─────────────────────────────────────────────────────────────────────────

/// "Solve 3x + 2 > 11" → "x > 3". String MC over four solution-set
/// forms. Always picks parameters so the integer boundary is positive.
GeneratedQuestion solveTwoStepInequality(Random rand) {
  final p = rand.nextInt(8) + 2; // 2..9
  final boundary = rand.nextInt(8) + 2; // 2..9 (the answer's c)
  final q = rand.nextInt(9) + 1; // 1..9
  // r is chosen so that px + q = r when x = boundary.
  final r = p * boundary + q;
  // Two operator variants: "> " or "< ".
  final isGreater = rand.nextBool();
  final op = isGreater ? '>' : '<';
  final ansOp = isGreater ? '>' : '<';
  final prompt = 'Solve for x: ${p}x + $q $op $r';
  final correct = 'x $ansOp $boundary';
  final distractors = <String>[
    // Misconception: flipped direction.
    'x ${isGreater ? '<' : '>'} $boundary',
    // Misconception: off-by-one.
    'x $ansOp ${boundary + 1}',
    // Misconception: forgot to undo the constant first.
    'x $ansOp ${r ~/ p}',
  ];

  return GeneratedQuestion(
    conceptId: 'solve_two_step_inequality',
    prompt: prompt,
    correctAnswer: correct,
    distractors: distractors,
    explanation: [
      'Subtract $q from both sides: ${p}x $op ${r - q}.',
      'Divide both sides by $p: x $ansOp $boundary.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// substitute_to_check (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "Is x = 5 a solution to x + 3 = 8?" → "Yes". Half the questions
/// use a correct value of x, the other half use a wrong value.
GeneratedQuestion substituteToCheck(Random rand) {
  final p = rand.nextInt(8) + 2; // 2..9
  final x = rand.nextInt(11) + 2; // 2..12
  final q = rand.nextInt(19) + 1; // 1..19
  final isPlus = rand.nextBool();
  final op = isPlus ? '+' : _minus;
  final r = isPlus ? p * x + q : p * x - q;
  if (r < 1) return substituteToCheck(rand);
  // Show prompt "Is x = $candidate a solution to ${p}x ± $q = $r?"
  // candidate is the real x half the time, otherwise off by ±1..±3.
  final isCorrect = rand.nextBool();
  late int candidate;
  if (isCorrect) {
    candidate = x;
  } else {
    final delta = (rand.nextInt(3) + 1) * (rand.nextBool() ? 1 : -1);
    candidate = x + delta;
    if (candidate < 1) candidate = x + 1;
  }
  final answer = isCorrect ? 'Yes' : 'No';
  final distractors = <String>[
    if (answer == 'Yes') 'No' else 'Yes',
    "Can't tell",
    'Maybe',
  ];

  return GeneratedQuestion(
    conceptId: 'substitute_to_check',
    prompt: 'Is x = $candidate a solution to ${p}x $op $q = $r?',
    correctAnswer: answer,
    distractors: distractors,
    explanation: [
      'Substitute x = $candidate into the left side.',
      'Result: ${isPlus ? p * candidate + q : p * candidate - q}.',
      'Right side is $r — ${isCorrect ? "equal." : "not equal."}',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// solve_linear_eq_with_distrib_collect (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// "Solve: 2(x + 3) + 4x = 30" → 4. Combines distribution and collecting
/// like terms before solving. Form: `a(x + b) + cx = d` with a, b, c, d
/// chosen so x ∈ [2, 9] is an integer. The constant inside the parens
/// is always positive; the outer `cx` term is always positive too.
GeneratedQuestion solveLinearEqWithDistribCollect(Random rand) {
  final x = rand.nextInt(8) + 2; // 2..9
  final a = rand.nextInt(4) + 2; // 2..5
  final b = rand.nextInt(8) + 1; // 1..8
  final c = rand.nextInt(7) + 1; // 1..7
  // d = a·x + a·b + c·x = (a + c)·x + a·b
  final d = (a + c) * x + a * b;
  final prompt = 'Solve for x: $a(x + $b) + ${c}x = $d';
  final correct = '$x';

  final candidates = <String>[
    // Misconception: divided d straight by (a + c), ignored the constant.
    '${d ~/ (a + c)}',
    // Misconception: distributed but ignored the cx term.
    '${(d - a * b) ~/ a}',
    // Off-by-one.
    '${x + 1}',
  ];

  return GeneratedQuestion(
    conceptId: 'solve_linear_eq_with_distrib_collect',
    prompt: prompt,
    correctAnswer: correct,
    distractors: _intDistractors(x, candidates, rand),
    explanation: [
      'Distribute: ${a}x + ${a * b} + ${c}x = $d.',
      'Combine x terms: ${a + c}x + ${a * b} = $d.',
      'Subtract ${a * b}: ${a + c}x = ${d - a * b}.',
      'Divide by ${a + c}: x = $x.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// solve_system_substitution (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// "Solve: y = 2x + 1 and y = −x + 7" → "(2, 5)". Both equations in
/// slope-intercept form; pick (x, y) integer first and back-build two
/// distinct lines through that point. Answer is the ordered-pair string.
GeneratedQuestion solveSystemSubstitution(Random rand) {
  final x = rand.nextInt(7) + 1; // 1..7
  final y = rand.nextInt(11) + 2; // 2..12
  int m1;
  int m2;
  // Pick two distinct non-zero slopes in [-3, 3] \ {0}.
  do {
    m1 = rand.nextInt(7) - 3; // -3..3
  } while (m1 == 0);
  do {
    m2 = rand.nextInt(7) - 3;
  } while (m2 == 0 || m2 == m1);
  final b1 = y - m1 * x;
  final b2 = y - m2 * x;
  final correct = '(${_signed(x)}, ${_signed(y)})';

  String eqn(int m, int b) {
    final mPart = m == 1
        ? 'x'
        : m == -1
        ? '${_minus}x'
        : '${_signed(m)}x';
    if (b == 0) return 'y = $mPart';
    if (b > 0) return 'y = $mPart + $b';
    return 'y = $mPart $_minus ${-b}';
  }

  final prompt = 'Solve the system: ${eqn(m1, b1)} and ${eqn(m2, b2)}.';

  final candidates = <String>[
    // Misconception: swapped coords.
    '(${_signed(y)}, ${_signed(x)})',
    // Misconception: sign error on x.
    '(${_signed(-x)}, ${_signed(y)})',
    // Misconception: sign error on y.
    '(${_signed(x)}, ${_signed(-y)})',
    // Misconception: used one equation only — solved m1·x + b1 = 0.
    if (m1 != 0 && b1 % m1 == 0 && -b1 ~/ m1 != x)
      '(${_signed(-b1 ~/ m1)}, ${_signed(0)})',
  ];
  return GeneratedQuestion(
    conceptId: 'solve_system_substitution',
    prompt: prompt,
    correctAnswer: correct,
    distractors: _stringDistractors(correct, candidates, x, y),
    explanation: [
      'Both equations equal y. Set the right sides equal and solve.',
      '${eqn(m1, b1).substring(4)} = ${eqn(m2, b2).substring(4)} → x = $x.',
      'Substitute back: y = $y. Answer: $correct.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// solve_system_elimination (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// "Solve: 3x + 2y = 16 and 5x − 2y = 8" → "(3, 7/2)" — but we restrict
/// coefficients so x and y are positive integers. The two equations have
/// matching y coefficients with opposite signs so adding the equations
/// eliminates y in one step.
GeneratedQuestion solveSystemElimination(Random rand) {
  final x = rand.nextInt(7) + 1; // 1..7
  final y = rand.nextInt(7) + 1; // 1..7
  final a = rand.nextInt(4) + 1; // 1..4
  final d = rand.nextInt(4) + 1; // 1..4
  final b = rand.nextInt(3) + 1; // 1..3 (coefficient on y; same magnitude)
  final c1 = a * x + b * y;
  final c2 = d * x - b * y;
  final correct = '(${_signed(x)}, ${_signed(y)})';

  String term(int coeff, String varName) =>
      coeff == 1 ? varName : '$coeff$varName';

  final prompt =
      'Solve the system: ${term(a, "x")} + ${term(b, "y")} = ${_signed(c1)} '
      'and ${term(d, "x")} $_minus ${term(b, "y")} = ${_signed(c2)}.';

  final candidates = <String>[
    // Swapped coords.
    '(${_signed(y)}, ${_signed(x)})',
    // Sign error on x.
    '(${_signed(-x)}, ${_signed(y)})',
    // Sign error on y.
    '(${_signed(x)}, ${_signed(-y)})',
    // Forgot to back-substitute — gave x as the sole answer.
    _signed(x),
  ];
  return GeneratedQuestion(
    conceptId: 'solve_system_elimination',
    prompt: prompt,
    correctAnswer: correct,
    distractors: _stringDistractors(correct, candidates, x, y),
    explanation: [
      'Add the equations: ${a + d}x = ${c1 + c2}, so x = $x.',
      'Substitute x = $x back: ${b}y = ${c1 - a * x}, so y = $y.',
      'Answer: $correct.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

/// String-MC distractor helper that guarantees 3 unique values different
/// from [correct]. Falls back to off-by-one tweaks of (x, y) if the
/// candidate pool dedupes to fewer than 3.
List<String> _stringDistractors(
  String correct,
  List<String> candidates,
  int x,
  int y,
) {
  final out = <String>[];
  final seen = <String>{correct};
  for (final c in candidates) {
    if (out.length >= 3) break;
    if (seen.add(c)) out.add(c);
  }
  // Fallback: nudge (x, y) by ±i in either coord.
  for (var i = 1; out.length < 3 && i < 20; i++) {
    for (final pair in <List<int>>[
      [x + i, y],
      [x - i, y],
      [x, y + i],
      [x, y - i],
    ]) {
      final s = '(${_signed(pair[0])}, ${_signed(pair[1])})';
      if (seen.add(s)) out.add(s);
      if (out.length >= 3) break;
    }
  }
  return out.take(3).toList();
}
