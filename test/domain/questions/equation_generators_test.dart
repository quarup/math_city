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
        expect(_parseSigned(q.correctAnswer), expected!);
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
        expect(_parseSigned(q.correctAnswer), expected!);
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
}
