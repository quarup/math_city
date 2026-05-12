import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/generator_registry.dart';

const _iterations = 300;
const _minus = '−'; // U+2212

GeneratedQuestion _gen(GeneratorRegistry r, String id, [int seed = 13]) =>
    r.generate(id, random: Random(seed));

/// Parses an answer string like "−5" or "12" back into a signed int.
int _parseSigned(String s) {
  if (s.startsWith(_minus)) return -int.parse(s.substring(_minus.length));
  return int.parse(s);
}

/// Parses a leading-operand or trailing-operand display ("5", "−5",
/// "(−5)") back to int.
int _parseOperand(String s) {
  var stripped = s;
  if (stripped.startsWith('(') && stripped.endsWith(')')) {
    stripped = stripped.substring(1, stripped.length - 1);
  }
  return _parseSigned(stripped);
}

void _expectThreeDistinctDistractors(GeneratedQuestion q) {
  expect(q.distractors, hasLength(3));
  expect(q.distractors.toSet(), hasLength(3));
  expect(q.distractors, isNot(contains(q.correctAnswer)));
}

void main() {
  late GeneratorRegistry registry;
  setUp(() => registry = GeneratorRegistry.defaultRegistry());

  group('integers_add', () {
    test('a, b ∈ [−20, 20]; sum correct; at least one operand negative', () {
      final re = RegExp(r'^(\S+) \+ (\S+) = \?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'integers_add', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final a = _parseOperand(m!.group(1)!);
        final b = _parseOperand(m.group(2)!);
        expect(a, inInclusiveRange(-20, 20));
        expect(b, inInclusiveRange(-20, 20));
        expect(a < 0 || b < 0, isTrue, reason: 'no negative in $a + $b');
        expect(_parseSigned(q.correctAnswer), a + b);
        _expectThreeDistinctDistractors(q);
      }
    });

    test('trailing operand is parenthesised when negative, bare when '
        'positive', () {
      for (var i = 0; i < 200; i++) {
        final q = _gen(registry, 'integers_add', i);
        final m = RegExp(r'^(\S+) \+ (\S+) = \?$').firstMatch(q.prompt)!;
        final trailing = m.group(2)!;
        final isNeg = _parseOperand(trailing) < 0;
        if (isNeg) {
          expect(trailing.startsWith('('), isTrue, reason: trailing);
          expect(trailing.endsWith(')'), isTrue, reason: trailing);
        } else {
          expect(trailing.startsWith('('), isFalse, reason: trailing);
        }
      }
    });
  });

  group('integers_subtract', () {
    test('a, b ∈ [−20, 20]; difference correct; at least one negative', () {
      final re = RegExp('^' r'(\S+) ' '$_minus' r' (\S+) = \?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'integers_subtract', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final a = _parseOperand(m!.group(1)!);
        final b = _parseOperand(m.group(2)!);
        expect(a, inInclusiveRange(-20, 20));
        expect(b, inInclusiveRange(-20, 20));
        expect(a < 0 || b < 0, isTrue);
        expect(_parseSigned(q.correctAnswer), a - b);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('integers_multiply_divide', () {
    test('mult: a × b correct; both ≠ 0,±1; at least one negative', () {
      final multRe = RegExp(r'^(\S+) × (\S+) = \?$');
      var sawMult = false;
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'integers_multiply_divide', i);
        final m = multRe.firstMatch(q.prompt);
        if (m == null) continue;
        sawMult = true;
        final a = _parseOperand(m.group(1)!);
        final b = _parseOperand(m.group(2)!);
        expect(a, inInclusiveRange(-9, 9));
        expect(b, inInclusiveRange(-9, 9));
        expect(a, isNot(0));
        expect(a, isNot(1));
        expect(a, isNot(-1));
        expect(b, isNot(0));
        expect(b, isNot(1));
        expect(b, isNot(-1));
        expect(a < 0 || b < 0, isTrue);
        expect(_parseSigned(q.correctAnswer), a * b);
        _expectThreeDistinctDistractors(q);
      }
      expect(sawMult, isTrue);
    });

    test('div: dividend ÷ divisor exact; divisor ≠ 0,±1; one negative', () {
      final divRe = RegExp(r'^(\S+) ÷ (\S+) = \?$');
      var sawDiv = false;
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'integers_multiply_divide', i);
        final m = divRe.firstMatch(q.prompt);
        if (m == null) continue;
        sawDiv = true;
        final dividend = _parseOperand(m.group(1)!);
        final divisor = _parseOperand(m.group(2)!);
        expect(divisor, isNot(0));
        expect(divisor, isNot(1));
        expect(divisor, isNot(-1));
        final quotient = _parseSigned(q.correctAnswer);
        expect(divisor * quotient, dividend);
        expect(dividend < 0 || divisor < 0, isTrue);
        _expectThreeDistinctDistractors(q);
      }
      expect(sawDiv, isTrue);
    });
  });
}
