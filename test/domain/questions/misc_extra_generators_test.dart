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

  group('am_pm', () {
    test('correct answer matches the context word', () {
      const am = [
        'in the morning',
        'when the sun comes up',
        'at sunrise',
        'before lunch',
        'at breakfast',
      ];
      const pm = [
        'in the afternoon',
        'in the evening',
        'at night',
        'after lunch',
        'at sunset',
        'at dinnertime',
      ];
      var seenAm = false;
      var seenPm = false;
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'am_pm', i);
        final pickAm = am.any(q.prompt.contains);
        final pickPm = pm.any(q.prompt.contains);
        expect(pickAm ^ pickPm, isTrue, reason: q.prompt);
        if (pickAm) {
          expect(q.correctAnswer, 'a.m.');
          seenAm = true;
        } else {
          expect(q.correctAnswer, 'p.m.');
          seenPm = true;
        }
        _expectThreeDistinctDistractors(q);
      }
      expect(seenAm && seenPm, isTrue);
    });
  });

  group('length_diff_units', () {
    test('answer = a − b, both lengths in [10, 89]', () {
      final re = RegExp(
        r'A (\w+) is (\d+) (\w+) long. A (\w+) is (\d+) \w+ long.',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'length_diff_units', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final a = int.parse(m!.group(2)!);
        final b = int.parse(m.group(5)!);
        expect(a, greaterThan(b));
        expect(a - b, greaterThanOrEqualTo(2));
        expect(int.parse(q.correctAnswer), a - b);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('triangle_inequality_recognize', () {
    test('Yes iff each side < sum of the other two; both outcomes appear', () {
      final re = RegExp(
        r'Can a triangle have sides of length (\d+), (\d+), and (\d+)\?',
      );
      var seenYes = false;
      var seenNo = false;
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'triangle_inequality_recognize', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull);
        final s = [
          int.parse(m!.group(1)!),
          int.parse(m.group(2)!),
          int.parse(m.group(3)!),
        ]..sort();
        final isValid = s[0] + s[1] > s[2];
        expect(q.correctAnswer, isValid ? 'Yes' : 'No');
        if (isValid) {
          seenYes = true;
        } else {
          seenNo = true;
        }
        _expectThreeDistinctDistractors(q);
      }
      expect(seenYes && seenNo, isTrue);
    });
  });

  group('adjacent_angles', () {
    test('a + answer = 90 or 180', () {
      final re = RegExp(
        r'form a (right angle|straight line)\. One angle measures (\d+)°',
      );
      var seenRight = false;
      var seenStraight = false;
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'adjacent_angles', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final isRight = m!.group(1) == 'right angle';
        final a = int.parse(m.group(2)!);
        final total = isRight ? 90 : 180;
        if (isRight) {
          seenRight = true;
        } else {
          seenStraight = true;
        }
        expect(a, inInclusiveRange(1, total - 1));
        expect(int.parse(q.correctAnswer), total - a);
        _expectThreeDistinctDistractors(q);
      }
      expect(seenRight && seenStraight, isTrue);
    });
  });

  group('exterior_angle_triangle', () {
    test('exterior = a + b (remote interior sum)', () {
      final re = RegExp(
        r'two interior angles measuring (\d+)° and (\d+)°',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'exterior_angle_triangle', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull);
        final a = int.parse(m!.group(1)!);
        final b = int.parse(m.group(2)!);
        expect(a, inInclusiveRange(20, 100));
        expect(b, inInclusiveRange(20, 100));
        expect(a + b, inInclusiveRange(30, 170));
        expect(int.parse(q.correctAnswer), a + b);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('inspect_system_no_solution', () {
    test('all three outcomes appear across seeds', () {
      const opts = [
        'Exactly one solution',
        'No solution',
        'Infinitely many solutions',
      ];
      final seen = <String>{};
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'inspect_system_no_solution', i);
        expect(opts, contains(q.correctAnswer));
        seen.add(q.correctAnswer);
        _expectThreeDistinctDistractors(q);
      }
      expect(seen.length, 3);
    });
  });

  group('unit_rate_with_fractions', () {
    test('answer is rate ∈ [2, 5]', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'unit_rate_with_fractions', i);
        final rate = int.parse(q.correctAnswer);
        expect(rate, inInclusiveRange(2, 5));
        _expectThreeDistinctDistractors(q);
      }
    });
  });
}
