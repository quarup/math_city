import 'dart:math';

import 'package:math_city/domain/questions/generated_question.dart';

/// Signed-integer arithmetic generators.
///
/// Display conventions (consistent with kid-textbook style):
///   * Leading operand: bare sign for negatives ("−5 + 3").
///   * Trailing operand: parens around negatives ("5 + (−3)") so the
///     operator and the sign are visually distinct.
///   * Answer: bare sign for negatives ("−2").

const _minus = '−'; // U+2212 minus sign (matches add_sub_generators)

String _signedNoParens(int n) => n >= 0 ? '$n' : '$_minus${-n}';
String _signed(int n) => n >= 0 ? '$n' : '($_minus${-n})';

/// Returns three string distractors for a signed integer answer.
/// Strategy: sign-flipped misconception + nearby integers, distinct,
/// never equal to the correct answer.
List<String> _signedDistractors(int correct, Random rand) {
  final candidates = <int>{
    -correct,
    correct + 1,
    correct - 1,
    correct + 2,
    correct - 2,
    correct + 5,
    correct - 5,
  }..remove(correct);
  for (var i = 3; candidates.length < 3; i++) {
    candidates.add(correct + i * 3);
  }
  final list = candidates.toList()..shuffle(rand);
  return list.take(3).map(_signedNoParens).toList();
}

// ─────────────────────────────────────────────────────────────────────────
// Generators
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion _binaryOpQuestion({
  required String conceptId,
  required String op, // visible operator: "+", "−", "×", "÷"
  required int a,
  required int b,
  required int correct,
  required Random rand,
}) {
  final line =
      '${_signedNoParens(a)} $op ${_signed(b)} = '
      '${_signedNoParens(correct)}';
  return GeneratedQuestion(
    conceptId: conceptId,
    prompt: '${_signedNoParens(a)} $op ${_signed(b)} = ?',
    correctAnswer: _signedNoParens(correct),
    distractors: _signedDistractors(correct, rand),
    explanation: [line],
  );
}

/// `−20 ≤ a, b ≤ 20`; addition. At least one operand is negative (we
/// already cover purely-positive addition elsewhere).
GeneratedQuestion integersAdd(Random rand) {
  int a;
  int b;
  do {
    a = rand.nextInt(41) - 20; // −20..20
    b = rand.nextInt(41) - 20;
  } while (a >= 0 && b >= 0);
  return _binaryOpQuestion(
    conceptId: 'integers_add',
    op: '+',
    a: a,
    b: b,
    correct: a + b,
    rand: rand,
  );
}

/// `−20 ≤ a, b ≤ 20`; subtraction. At least one operand is negative so
/// each problem genuinely exercises sign rules.
GeneratedQuestion integersSubtract(Random rand) {
  int a;
  int b;
  do {
    a = rand.nextInt(41) - 20;
    b = rand.nextInt(41) - 20;
  } while (a >= 0 && b >= 0);
  return _binaryOpQuestion(
    conceptId: 'integers_subtract',
    op: _minus,
    a: a,
    b: b,
    correct: a - b,
    rand: rand,
  );
}

/// Random pick between × and ÷ on signed integers. Multiplication
/// operands ∈ [−9, 9]\{0, ±1}; division generated as quotient × divisor
/// for exact results.
GeneratedQuestion integersMultiplyDivide(Random rand) {
  final isMult = rand.nextBool();

  int pickFactor() {
    int v;
    do {
      v = rand.nextInt(19) - 9; // −9..9
    } while (v == 0 || v == 1 || v == -1);
    return v;
  }

  if (isMult) {
    final a = pickFactor();
    final b = pickFactor();
    // Require at least one negative — purely positive cases are already
    // covered by mult_facts_within_100.
    final aSigned = (a >= 0 && b >= 0) ? -a : a;
    return _binaryOpQuestion(
      conceptId: 'integers_multiply_divide',
      op: '×',
      a: aSigned,
      b: b,
      correct: aSigned * b,
      rand: rand,
    );
  }
  // Division — generate as divisor × quotient so result is exact.
  final divisor = pickFactor();
  final quotient = pickFactor();
  // Ensure at least one negative.
  final dSigned = (divisor >= 0 && quotient >= 0) ? -divisor : divisor;
  final dividend = dSigned * quotient;
  return _binaryOpQuestion(
    conceptId: 'integers_multiply_divide',
    op: '÷',
    a: dividend,
    b: dSigned,
    correct: quotient,
    rand: rand,
  );
}
