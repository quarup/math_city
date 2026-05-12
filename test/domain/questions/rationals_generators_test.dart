import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/fraction.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/generator_registry.dart';

const _iterations = 300;

GeneratedQuestion _gen(GeneratorRegistry r, String id, [int seed = 13]) =>
    r.generate(id, random: Random(seed));

void _expectThreeDistinctDistractors(GeneratedQuestion q) {
  expect(q.distractors, hasLength(3));
  expect(q.distractors.toSet(), hasLength(3));
  expect(q.distractors, isNot(contains(q.correctAnswer)));
}

/// Parses a prompt of shape `<a> <op> <b> = ?` where:
///   * `<a>` is a signed canonical-form rational (e.g. `3/4`, `-3/4`, `-2`)
///   * `<b>` is either a positive canonical-form rational or
///     `(<negative>)` (matching the kid-textbook trailing-negative style).
({Fraction a, String op, Fraction b}) _parsePrompt(String prompt) {
  final m = RegExp(
    r'^(-?\d+(?:/\d+)?)\s+([+−×÷])\s+(\(-?\d+(?:/\d+)?\)|-?\d+(?:/\d+)?)'
    r'\s+=\s+\?$',
  ).firstMatch(prompt);
  if (m == null) {
    throw FormatException('prompt did not match: $prompt');
  }
  final aStr = m.group(1)!;
  final op = m.group(2)!;
  var bStr = m.group(3)!;
  if (bStr.startsWith('(') && bStr.endsWith(')')) {
    bStr = bStr.substring(1, bStr.length - 1);
  }
  return (a: Fraction.tryParse(aStr)!, op: op, b: Fraction.tryParse(bStr)!);
}

void main() {
  late GeneratorRegistry registry;
  setUp(() => registry = GeneratorRegistry.defaultRegistry());

  group('rationals_add_sub', () {
    test('correct answer matches arithmetic; at least one operand negative',
        () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'rationals_add_sub', i);
        expect(q.conceptId, 'rationals_add_sub');
        final parsed = _parsePrompt(q.prompt);
        // At least one operand negative (we force this in the generator).
        expect(
          parsed.a.numerator < 0 || parsed.b.numerator < 0,
          isTrue,
          reason: 'expected at least one negative operand: ${q.prompt}',
        );
        final result =
            parsed.op == '+' ? parsed.a + parsed.b : parsed.a - parsed.b;
        expect(q.correctAnswer, result.toCanonical());
        expect(q.answerFormat, AnswerFormat.fraction);
        _expectThreeDistinctDistractors(q);
      }
    });

    test('trailing-negative operand is wrapped in parens', () {
      for (var i = 0; i < 200; i++) {
        final q = _gen(registry, 'rationals_add_sub', i + 1000);
        final parsed = _parsePrompt(q.prompt);
        if (parsed.b.numerator < 0) {
          // The trailing string had to be `(-x/y)` for the parser to peel
          // off parens — assert it appears that way in the prompt.
          final trailing = q.prompt.split(parsed.op).last.trim();
          expect(
            trailing.startsWith('('),
            isTrue,
            reason: 'expected paren-wrapped negative: ${q.prompt}',
          );
        }
      }
    });
  });

  group('rationals_multiply_divide', () {
    test('correct answer matches arithmetic; divisor never 0', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'rationals_multiply_divide', i);
        expect(q.conceptId, 'rationals_multiply_divide');
        final parsed = _parsePrompt(q.prompt);
        expect(parsed.b.numerator, isNot(0));
        final result =
            parsed.op == '×' ? parsed.a * parsed.b : parsed.a / parsed.b;
        expect(q.correctAnswer, result.toCanonical());
        expect(q.answerFormat, AnswerFormat.fraction);
        _expectThreeDistinctDistractors(q);
      }
    });

    test('sign rules: neg × pos = neg; neg × neg = pos', () {
      for (var i = 0; i < 200; i++) {
        final q = _gen(registry, 'rationals_multiply_divide', i + 5000);
        final parsed = _parsePrompt(q.prompt);
        if (parsed.op != '×') continue;
        final aNeg = parsed.a.numerator < 0;
        final bNeg = parsed.b.numerator < 0;
        final answer = Fraction.tryParse(q.correctAnswer)!;
        final shouldBeNeg = aNeg != bNeg;
        // Allow result of exactly 0 (won't happen here since both magnitudes
        // are >= 1, but defensive).
        if (answer.numerator == 0) continue;
        expect(
          answer.numerator < 0,
          shouldBeNeg,
          reason:
              'sign mismatch for ${q.prompt}: expected '
              '${shouldBeNeg ? 'neg' : 'pos'}, got ${answer.toCanonical()}',
        );
      }
    });
  });
}
