import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/generator_registry.dart';

const _iterations = 300;
const _minus = '−'; // U+2212

GeneratedQuestion _gen(GeneratorRegistry r, String id, [int seed = 13]) =>
    r.generate(id, random: Random(seed));

int _parseSigned(String s) {
  if (s.startsWith(_minus)) return -int.parse(s.substring(_minus.length));
  return int.parse(s);
}

void _expectThreeDistinctDistractors(GeneratedQuestion q) {
  expect(q.distractors, hasLength(3));
  expect(q.distractors.toSet(), hasLength(3));
  expect(q.distractors, isNot(contains(q.correctAnswer)));
}

int _prec(String op) => (op == '×' || op == '÷') ? 2 : 1;

int? _apply(int x, String op, int y) {
  switch (op) {
    case '+':
      return x + y;
    case _minus:
      return x - y;
    case '×':
      return x * y;
    case '÷':
      if (y == 0 || x % y != 0) return null;
      return x ~/ y;
  }
  return null;
}

int? _evalPrecedence(int a, String op1, int b, String op2, int c) {
  if (_prec(op2) > _prec(op1)) {
    final bc = _apply(b, op2, c);
    if (bc == null) return null;
    return _apply(a, op1, bc);
  }
  final ab = _apply(a, op1, b);
  if (ab == null) return null;
  return _apply(ab, op2, c);
}

void main() {
  late GeneratorRegistry registry;
  setUp(() => registry = GeneratorRegistry.defaultRegistry());

  group('order_of_operations_no_exp', () {
    test('answer matches standard-precedence evaluation', () {
      // Match operator characters as a class, since they aren't \S only.
      final re = RegExp(
        r'^(\d+) ([+\-−×÷]) (\d+) ([+\-−×÷]) (\d+) = \?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'order_of_operations_no_exp', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final a = int.parse(m!.group(1)!);
        final op1 = m.group(2)!;
        final b = int.parse(m.group(3)!);
        final op2 = m.group(4)!;
        final c = int.parse(m.group(5)!);
        final expected = _evalPrecedence(a, op1, b, op2, c);
        expect(expected, isNotNull, reason: q.prompt);
        expect(_parseSigned(q.correctAnswer), expected);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('nested_grouping', () {
    test('answer respects the parentheses', () {
      final leftRe = RegExp(
        r'^\((\d+) ([+\-−×÷]) (\d+)\) ([+\-−×÷]) (\d+) = \?$',
      );
      final rightRe = RegExp(
        r'^(\d+) ([+\-−×÷]) \((\d+) ([+\-−×÷]) (\d+)\) = \?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'nested_grouping', i);
        final mL = leftRe.firstMatch(q.prompt);
        final mR = rightRe.firstMatch(q.prompt);
        expect(mL != null || mR != null, isTrue, reason: q.prompt);
        int? expected;
        if (mL != null) {
          final a = int.parse(mL.group(1)!);
          final op1 = mL.group(2)!;
          final b = int.parse(mL.group(3)!);
          final op2 = mL.group(4)!;
          final c = int.parse(mL.group(5)!);
          final ab = _apply(a, op1, b);
          expected = ab == null ? null : _apply(ab, op2, c);
        } else {
          final a = int.parse(mR!.group(1)!);
          final op2 = mR.group(2)!;
          final b = int.parse(mR.group(3)!);
          final op1 = mR.group(4)!;
          final c = int.parse(mR.group(5)!);
          final bc = _apply(b, op1, c);
          expected = bc == null ? null : _apply(a, op2, bc);
        }
        expect(expected, isNotNull, reason: q.prompt);
        expect(_parseSigned(q.correctAnswer), expected);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('evaluate_expression', () {
    test('answer = a × x + b', () {
      final re = RegExp(r'^Evaluate (\d+)x \+ (\d+) when x = (\d+)\.$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'evaluate_expression', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final a = int.parse(m!.group(1)!);
        final b = int.parse(m.group(2)!);
        final x = int.parse(m.group(3)!);
        expect(q.correctAnswer, '${a * x + b}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('solve_one_step_eq_addition', () {
    test('substituting the answer makes both sides equal', () {
      final re = RegExp(r'^Solve for x: x ([+\-−]) (\d+) = (\d+)$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'solve_one_step_eq_addition', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final op = m!.group(1)!;
        final p = int.parse(m.group(2)!);
        final qVal = int.parse(m.group(3)!);
        final x = int.parse(q.correctAnswer);
        if (op == '+') {
          expect(x + p, qVal);
        } else {
          expect(x - p, qVal);
        }
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('solve_two_step_eq', () {
    test('substituting the answer satisfies the equation', () {
      final re = RegExp(
        r'^Solve for x: (\d+)x ([+\-−]) (\d+) = (\d+)$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'solve_two_step_eq', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final p = int.parse(m!.group(1)!);
        final op = m.group(2)!;
        final qq = int.parse(m.group(3)!);
        final r = int.parse(m.group(4)!);
        final x = int.parse(q.correctAnswer);
        final lhs = op == '+' ? p * x + qq : p * x - qq;
        expect(lhs, r);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('expand_linear_expression', () {
    test('answer matches a(x op b) = ax op (a·b)', () {
      final re = RegExp(r'^Expand: (\d+)\(x ([+−]) (\d+)\)$');
      final ansRe = RegExp(r'^(\d+)x ([+−]) (\d+)$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'expand_linear_expression', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final a = int.parse(m!.group(1)!);
        final op = m.group(2)!;
        final b = int.parse(m.group(3)!);
        final am = ansRe.firstMatch(q.correctAnswer);
        expect(am, isNotNull, reason: q.correctAnswer);
        expect(int.parse(am!.group(1)!), a);
        expect(am.group(2), op);
        expect(int.parse(am.group(3)!), a * b);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('add_subtract_linear_expressions', () {
    test('answer is (a1±a2)x + (b1±b2)', () {
      final re = RegExp(
        r'^Simplify: (\d+)x \+ (\d+) ([+−]) \((\d+)x \+ (\d+)\)$',
      );
      // Answer shape: NX + N or NX − N. Coefficient always positive.
      final ansRe = RegExp(r'^(\d+)x ([+−]) (\d+)$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'add_subtract_linear_expressions', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final a1 = int.parse(m!.group(1)!);
        final b1 = int.parse(m.group(2)!);
        final op = m.group(3)!;
        final a2 = int.parse(m.group(4)!);
        final b2 = int.parse(m.group(5)!);
        final isPlus = op == '+';
        final expectedA = a1 + (isPlus ? a2 : -a2);
        final expectedB = b1 + (isPlus ? b2 : -b2);
        // Generator re-rolls to avoid zero or negative coefficient.
        expect(expectedA, greaterThan(0));
        expect(expectedB, isNot(0));
        final am = ansRe.firstMatch(q.correctAnswer);
        expect(am, isNotNull, reason: q.correctAnswer);
        expect(int.parse(am!.group(1)!), expectedA);
        if (expectedB > 0) {
          expect(am.group(2), '+');
          expect(int.parse(am.group(3)!), expectedB);
        } else {
          expect(am.group(2), '−');
          expect(int.parse(am.group(3)!), -expectedB);
        }
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('equivalent_expressions_props', () {
    test('answer is "ax + a·b" from "a(x + b)"', () {
      final re = RegExp(r'^Which is equivalent to (\d+)\(x \+ (\d+)\)\?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'equivalent_expressions_props', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final a = int.parse(m!.group(1)!);
        final b = int.parse(m.group(2)!);
        expect(q.correctAnswer, '${a}x + ${a * b}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('factor_linear_expression', () {
    test('answer is "k(x + b)" where k·1 = coeff and k·b = const', () {
      final re = RegExp(r'^Factor: (\d+)x \+ (\d+)$');
      final ansRe = RegExp(r'^(\d+)\(x \+ (\d+)\)$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'factor_linear_expression', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final coeff = int.parse(m!.group(1)!);
        final cst = int.parse(m.group(2)!);
        final am = ansRe.firstMatch(q.correctAnswer);
        expect(am, isNotNull, reason: q.correctAnswer);
        final k = int.parse(am!.group(1)!);
        final b = int.parse(am.group(2)!);
        expect(k, coeff);
        expect(k * b, cst);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('solve_two_step_eq_distributive', () {
    test('answer x satisfies p(x op q) = r', () {
      final re = RegExp(r'^Solve for x: (\d+)\(x ([+−]) (\d+)\) = (\d+)$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'solve_two_step_eq_distributive', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final p = int.parse(m!.group(1)!);
        final op = m.group(2)!;
        final qq = int.parse(m.group(3)!);
        final r = int.parse(m.group(4)!);
        final x = int.parse(q.correctAnswer);
        final inner = op == '+' ? x + qq : x - qq;
        expect(p * inner, r);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('solve_linear_eq_one_solution', () {
    test('answer x satisfies ax + b = cx + d; a != c', () {
      final re = RegExp(
        r'^Solve for x: (\d+)x \+ (\d+) = (\d+)x \+ (\d+)$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'solve_linear_eq_one_solution', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final a = int.parse(m!.group(1)!);
        final b = int.parse(m.group(2)!);
        final c = int.parse(m.group(3)!);
        final d = int.parse(m.group(4)!);
        expect(a, isNot(c));
        final x = int.parse(q.correctAnswer);
        expect(a * x + b, c * x + d);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('substitute_to_check', () {
    test('Yes iff substituting candidate yields the right side', () {
      final re = RegExp(
        r'^Is x = (\d+) a solution to (\d+)x ([+−]) (\d+) = (\d+)\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'substitute_to_check', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final cand = int.parse(m!.group(1)!);
        final p = int.parse(m.group(2)!);
        final op = m.group(3)!;
        final qq = int.parse(m.group(4)!);
        final r = int.parse(m.group(5)!);
        final lhs = op == '+' ? p * cand + qq : p * cand - qq;
        expect(q.correctAnswer, lhs == r ? 'Yes' : 'No');
      }
    });
  });

  group('solve_one_step_eq_mult', () {
    test('substituting the answer makes both sides equal', () {
      final multRe = RegExp(r'^Solve for x: (\d+)x = (\d+)$');
      final divRe = RegExp(r'^Solve for x: x ÷ (\d+) = (\d+)$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'solve_one_step_eq_mult', i);
        final mM = multRe.firstMatch(q.prompt);
        final mD = divRe.firstMatch(q.prompt);
        expect(mM != null || mD != null, isTrue, reason: q.prompt);
        final x = int.parse(q.correctAnswer);
        if (mM != null) {
          final p = int.parse(mM.group(1)!);
          final qVal = int.parse(mM.group(2)!);
          expect(p * x, qVal);
        } else {
          final p = int.parse(mD!.group(1)!);
          final qVal = int.parse(mD.group(2)!);
          expect(x ~/ p, qVal);
          expect(x % p, 0, reason: 'x must be divisible by p in: ${q.prompt}');
        }
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('inequality_one_var_intro', () {
    test('correct answer is satisfied when x is the prompted value', () {
      final re = RegExp(r'^Which inequality is true when x = (\d+)\?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'inequality_one_var_intro', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final x = int.parse(m!.group(1)!);
        // Answer is "x > c". Parse and verify.
        final ansMatch = RegExp(
          r'^x ([<>]) (\d+)$',
        ).firstMatch(q.correctAnswer);
        expect(ansMatch, isNotNull, reason: q.correctAnswer);
        final op = ansMatch!.group(1)!;
        final c = int.parse(ansMatch.group(2)!);
        final satisfied = op == '>' ? x > c : x < c;
        expect(satisfied, isTrue, reason: '$x $op $c should be true');
      }
    });
  });

  group('solve_two_step_inequality', () {
    test('boundary value satisfies px + q ⋚ r at equality', () {
      final re = RegExp(
        r'^Solve for x: (\d+)x \+ (\d+) ([<>]) (\d+)$',
      );
      final ansRe = RegExp(r'^x ([<>]) (\d+)$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'solve_two_step_inequality', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final p = int.parse(m!.group(1)!);
        final qq = int.parse(m.group(2)!);
        final op = m.group(3)!;
        final r = int.parse(m.group(4)!);
        final am = ansRe.firstMatch(q.correctAnswer);
        expect(am, isNotNull, reason: q.correctAnswer);
        final ansOp = am!.group(1)!;
        final c = int.parse(am.group(2)!);
        // Direction is preserved (no negative-coefficient flip in this gen).
        expect(ansOp, op);
        // Boundary value: p·c + q == r.
        expect(p * c + qq, r);
      }
    });
  });

  group('solve_linear_eq_no_or_inf', () {
    test('answer matches the case the prompt actually represents', () {
      const cases = {
        'one solution',
        'no solution',
        'infinitely many solutions',
      };
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'solve_linear_eq_no_or_inf', i);
        expect(cases, contains(q.correctAnswer));
        expect(q.prompt.startsWith('Solve for x:'), isTrue);
        // The three case strings must all appear in the four total choices.
        final all = {q.correctAnswer, ...q.distractors};
        expect(cases.difference(all), isEmpty);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('solve_linear_eq_with_distrib_collect', () {
    test('integer x answers the parsed equation', () {
      final re = RegExp(
        r'^Solve for x: (\d+)\(x \+ (\d+)\) − (\d+)x = (\d+)$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'solve_linear_eq_with_distrib_collect', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final p = int.parse(m!.group(1)!);
        final qq = int.parse(m.group(2)!);
        final k = int.parse(m.group(3)!);
        final r = int.parse(m.group(4)!);
        final x = int.parse(q.correctAnswer);
        expect(p - k, greaterThan(0));
        expect(p * (x + qq) - k * x, r);
        _expectThreeDistinctDistractors(q);
      }
    });
  });
}
