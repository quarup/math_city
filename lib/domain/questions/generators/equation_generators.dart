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
