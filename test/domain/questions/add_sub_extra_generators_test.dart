import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/generator_registry.dart';

const _iterations = 200;

GeneratedQuestion _gen(GeneratorRegistry r, String id, [int seed = 13]) =>
    r.generate(id, random: Random(seed));

void _expectThreeDistinctDistractors(GeneratedQuestion q) {
  expect(q.distractors, hasLength(3));
  expect(q.distractors.toSet(), hasLength(3));
  expect(q.distractors, isNot(contains(q.correctAnswer)));
}

void main() {
  late GeneratorRegistry registry;
  setUp(() => registry = GeneratorRegistry.defaultRegistry());

  group('count_within_1000', () {
    test('answer = n + 1; n ∈ [120, 999]', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'count_within_1000', i);
        final m = RegExp(r'right after (\d+)').firstMatch(q.prompt);
        expect(m, isNotNull);
        final n = int.parse(m!.group(1)!);
        expect(n, inInclusiveRange(120, 999));
        expect(int.parse(q.correctAnswer), n + 1);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('even_odd', () {
    test('answer matches parity of the prompt number', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'even_odd', i);
        final m = RegExp(r'Is (\d+) even or odd').firstMatch(q.prompt);
        expect(m, isNotNull);
        final n = int.parse(m!.group(1)!);
        expect(q.correctAnswer, n.isEven ? 'Even' : 'Odd');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('compare_2digit', () {
    test('answer = max/min based on direction', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'compare_2digit', i);
        final m = RegExp(r'(greater|smaller): (\d+) or (\d+)')
            .firstMatch(q.prompt);
        expect(m, isNotNull);
        final dir = m!.group(1)!;
        final a = int.parse(m.group(2)!);
        final b = int.parse(m.group(3)!);
        expect(int.parse(q.correctAnswer),
            dir == 'greater' ? max(a, b) : min(a, b));
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('make_10_pair', () {
    test('answer + prompt-n = 10', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'make_10_pair', i);
        final m = RegExp(r'plus (\d+) equals 10').firstMatch(q.prompt);
        expect(m, isNotNull);
        final n = int.parse(m!.group(1)!);
        expect(int.parse(q.correctAnswer) + n, 10);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('add_3_addends_within_20', () {
    test('answer = a + b + c', () {
      final re = RegExp(r'^(\d+) \+ (\d+) \+ (\d+) = \?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'add_3_addends_within_20', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull);
        final a = int.parse(m!.group(1)!);
        final b = int.parse(m.group(2)!);
        final c = int.parse(m.group(3)!);
        expect(int.parse(q.correctAnswer), a + b + c);
        expect(a + b + c, lessThanOrEqualTo(20));
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('add_sub_unknown_position', () {
    test('the equation with answer substituted is true', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'add_sub_unknown_position', i);
        // Substitute the answer into the prompt and verify the equation.
        final answer = int.parse(q.correctAnswer);
        final substituted = q.prompt.replaceFirst('?', '$answer');
        final m = RegExp(r'^(\d+) ([+−]) (\d+) = (\d+)$').firstMatch(
          substituted,
        );
        expect(m, isNotNull, reason: substituted);
        final lhs = int.parse(m!.group(1)!);
        final op = m.group(2)!;
        final rhs = int.parse(m.group(3)!);
        final res = int.parse(m.group(4)!);
        expect(op == '+' ? lhs + rhs : lhs - rhs, res, reason: substituted);
        _expectThreeDistinctDistractors(q);
      }
    });
  });
}
