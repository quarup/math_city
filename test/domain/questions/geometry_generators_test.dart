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

  group('area_rectangle_formula', () {
    test('area = length × width', () {
      final re = RegExp(
        r'^A rectangle has length (\d+) and width (\d+)\. What is its area\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'area_rectangle_formula', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final l = int.parse(m!.group(1)!);
        final w = int.parse(m.group(2)!);
        expect(q.correctAnswer, '${l * w}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('perimeter_polygon', () {
    test('square: 4s; rectangle: 2(l+w)', () {
      final sq = RegExp(
        r'^A square has side length (\d+)\. What is its perimeter\?$',
      );
      final rect = RegExp(
        r'^A rectangle has length (\d+) and width (\d+)\. What is its perimeter\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'perimeter_polygon', i);
        final sm = sq.firstMatch(q.prompt);
        final rm = rect.firstMatch(q.prompt);
        if (sm != null) {
          final s = int.parse(sm.group(1)!);
          expect(q.correctAnswer, '${4 * s}');
        } else if (rm != null) {
          final l = int.parse(rm.group(1)!);
          final w = int.parse(rm.group(2)!);
          expect(q.correctAnswer, '${2 * (l + w)}');
        } else {
          fail('unrecognised prompt shape: ${q.prompt}');
        }
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('area_triangle', () {
    test('area = base × height ÷ 2 (always integer)', () {
      final re = RegExp(
        r'^A triangle has base (\d+) and height (\d+)\. What is its area\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'area_triangle', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final b = int.parse(m!.group(1)!);
        final h = int.parse(m.group(2)!);
        expect((b * h).isEven, isTrue, reason: 'base×height must be even');
        expect(q.correctAnswer, '${b * h ~/ 2}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });
}
