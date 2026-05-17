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

  group('pythagorean_apply_2d', () {
    test('a² + b² = c² holds in every generated question', () {
      final hypRe = RegExp(
        r'^A right triangle has legs (\d+) and (\d+)\. '
        r'What is the length of the hypotenuse\?$',
      );
      final legRe = RegExp(
        r'^A right triangle has hypotenuse (\d+) and one leg (\d+)\. '
        r'What is the other leg\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'pythagorean_apply_2d', i);
        final mH = hypRe.firstMatch(q.prompt);
        final mL = legRe.firstMatch(q.prompt);
        expect(mH != null || mL != null, isTrue, reason: q.prompt);
        if (mH != null) {
          final a = int.parse(mH.group(1)!);
          final b = int.parse(mH.group(2)!);
          final c = int.parse(q.correctAnswer);
          expect(a * a + b * b, c * c);
        } else {
          final c = int.parse(mL!.group(1)!);
          final a = int.parse(mL.group(2)!);
          final b = int.parse(q.correctAnswer);
          expect(a * a + b * b, c * c);
        }
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('volume_rect_prism_formula', () {
    test('volume = l × w × h', () {
      final re = RegExp(
        r'^A rectangular box has length (\d+), width (\d+), and height (\d+)\. '
        r'What is its volume\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'volume_rect_prism_formula', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final l = int.parse(m!.group(1)!);
        final w = int.parse(m.group(2)!);
        final h = int.parse(m.group(3)!);
        expect(q.correctAnswer, '${l * w * h}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('scientific_notation_ops', () {
    test('multiplication: ab × 10^(p+q)', () {
      final re = RegExp(
        r'^\((\d+) × 10\^(\d+)\) × \((\d+) × 10\^(\d+)\) = \?$',
      );
      final ansRe = RegExp(r'^(\d+) × 10\^(\d+)$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'scientific_notation_ops', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final a = int.parse(m!.group(1)!);
        final p = int.parse(m.group(2)!);
        final b = int.parse(m.group(3)!);
        final qq = int.parse(m.group(4)!);
        final am = ansRe.firstMatch(q.correctAnswer);
        expect(am, isNotNull, reason: q.correctAnswer);
        expect(int.parse(am!.group(1)!), a * b);
        expect(int.parse(am.group(2)!), p + qq);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('compare_order_rationals', () {
    test('correct is one of the four shown values and is the greatest', () {
      final re = RegExp(r'^Which is the greatest: ([^?]+)\?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'compare_order_rationals', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final values = m!
            .group(1)!
            .split(',')
            .map((s) => num.parse(s.trim()))
            .toList();
        final maxV = values.reduce((a, b) => a > b ? a : b);
        // The correct answer must parse to that max.
        final parsed = num.parse(q.correctAnswer);
        expect(parsed, maxV);
      }
    });
  });

  group('irrational_recognize', () {
    test('answer is "rational" or "irrational"', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'irrational_recognize', i);
        expect(['rational', 'irrational'].contains(q.correctAnswer), isTrue);
      }
    });
  });
}
