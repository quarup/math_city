import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
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

void main() {
  late GeneratorRegistry registry;
  setUp(() => registry = GeneratorRegistry.defaultRegistry());

  group('factors_of_n', () {
    test('correct answer divides n; distractors do not', () {
      final re = RegExp(r'^Which of these is a factor of (\d+)\?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'factors_of_n', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final n = int.parse(m!.group(1)!);
        final correct = int.parse(q.correctAnswer);
        expect(n % correct, 0, reason: '$correct should divide $n');
        for (final d in q.distractors) {
          final v = int.parse(d);
          expect(n % v, isNot(0), reason: '$v should NOT divide $n');
        }
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('multiples_of_n', () {
    test('correct answer is a multiple of n; distractors are not', () {
      final re = RegExp(r'^Which of these is a multiple of (\d+)\?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'multiples_of_n', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final n = int.parse(m!.group(1)!);
        final correct = int.parse(q.correctAnswer);
        expect(correct % n, 0);
        for (final d in q.distractors) {
          final v = int.parse(d);
          expect(v % n, isNot(0), reason: '$v should NOT be a multiple of $n');
        }
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('gcf_two_numbers', () {
    test('answer is gcd(a, b)', () {
      final re = RegExp(r'^Find the GCF of (\d+) and (\d+)\.$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'gcf_two_numbers', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final a = int.parse(m!.group(1)!);
        final b = int.parse(m.group(2)!);
        final g = int.parse(q.correctAnswer);
        expect(a % g, 0);
        expect(b % g, 0);
        // Verify no larger common divisor.
        for (var d = g + 1; d <= a; d++) {
          if (a % d == 0 && b % d == 0) {
            fail('$d also divides both — gcf should be > $g');
          }
        }
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('lcm_two_numbers', () {
    test('answer is divisible by both a and b; no smaller common multiple', () {
      final re = RegExp(r'^Find the LCM of (\d+) and (\d+)\.$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'lcm_two_numbers', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final a = int.parse(m!.group(1)!);
        final b = int.parse(m.group(2)!);
        final lcm = int.parse(q.correctAnswer);
        expect(lcm % a, 0);
        expect(lcm % b, 0);
        for (var k = a; k < lcm; k++) {
          if (k % a == 0 && k % b == 0) {
            fail('$k is a smaller common multiple — lcm should be ≤ $k');
          }
        }
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('absolute_value', () {
    test('answer = |v| where v is parsed from "|v|" in the prompt', () {
      final re = RegExp(r'^What is \|([−-]?\d+)\|\?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'absolute_value', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final vStr = m!.group(1)!;
        final v = vStr.startsWith('−')
            ? -int.parse(vStr.substring(1))
            : int.parse(vStr);
        expect(q.correctAnswer, '${v.abs()}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('opposites_and_zero', () {
    test('answer = −v', () {
      final re = RegExp(r'^What is the opposite of ([−-]?\d+)\?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'opposites_and_zero', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final vStr = m!.group(1)!;
        final v = vStr.startsWith('−')
            ? -int.parse(vStr.substring(1))
            : int.parse(vStr);
        final expected = -v;
        final expectedStr = expected >= 0 ? '$expected' : '−${-expected}';
        expect(q.correctAnswer, expectedStr);
      }
    });
  });
}
