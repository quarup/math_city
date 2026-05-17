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

  group('area_parallelogram', () {
    test('area = base × height', () {
      final re = RegExp(
        r'^A parallelogram has base (\d+) and height (\d+)\. What is its area\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'area_parallelogram', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final base = int.parse(m!.group(1)!);
        final height = int.parse(m.group(2)!);
        expect(q.correctAnswer, '${base * height}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('area_trapezoid', () {
    test('area = (b1 + b2) × h ÷ 2 (always integer)', () {
      final re = RegExp(
        r'^A trapezoid has parallel sides of length (\d+) and (\d+), and '
        r'height (\d+)\. What is its area\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'area_trapezoid', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final b1 = int.parse(m!.group(1)!);
        final b2 = int.parse(m.group(2)!);
        final h = int.parse(m.group(3)!);
        expect(
          ((b1 + b2) * h).isEven,
          isTrue,
          reason: '(b1+b2)·h must be even: ${q.prompt}',
        );
        expect(q.correctAnswer, '${(b1 + b2) * h ~/ 2}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('perimeter_unknown_side', () {
    test('answer = P÷2 − l (valid rectangle)', () {
      final re = RegExp(
        r'^A rectangle has perimeter (\d+) and length (\d+)\. What is its width\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'perimeter_unknown_side', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final p = int.parse(m!.group(1)!);
        final l = int.parse(m.group(2)!);
        final w = int.parse(q.correctAnswer);
        expect(2 * (l + w), p);
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

  group('supplementary_angles', () {
    test('answer = 180 − a; a never equals 90', () {
      final re = RegExp(
        r'^Two angles are supplementary\. One is (\d+)°\. '
        r'What is the other\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'supplementary_angles', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final a = int.parse(m!.group(1)!);
        expect(a, isNot(90), reason: 'a == 90 would yield duplicate answer');
        expect(q.correctAnswer, '${180 - a}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('complementary_angles', () {
    test('answer = 90 − a; a never equals 45', () {
      final re = RegExp(
        r'^Two angles are complementary\. One is (\d+)°\. '
        r'What is the other\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'complementary_angles', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final a = int.parse(m!.group(1)!);
        expect(a, isNot(45), reason: 'a == 45 would yield duplicate answer');
        expect(q.correctAnswer, '${90 - a}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('vertical_angles', () {
    test('vertical = a; adjacent = 180 − a; both modes covered', () {
      final re = RegExp(
        r'^Two lines cross\. One angle measures (\d+)°\. '
        r'What is the angle (vertical to|adjacent to) it\?$',
      );
      final modesSeen = <String>{};
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'vertical_angles', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final a = int.parse(m!.group(1)!);
        final relation = m.group(2)!;
        modesSeen.add(relation);
        final expected = relation == 'vertical to' ? a : 180 - a;
        expect(q.correctAnswer, '$expected');
        _expectThreeDistinctDistractors(q);
      }
      expect(modesSeen, containsAll(<String>['vertical to', 'adjacent to']));
    });
  });

  group('triangle_angle_sum', () {
    test('answer = 180 − a − b; all three angles positive', () {
      final re = RegExp(
        r'^A triangle has angles (\d+)° and (\d+)°\. '
        r'What is the third angle\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'triangle_angle_sum', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final a = int.parse(m!.group(1)!);
        final b = int.parse(m.group(2)!);
        final c = 180 - a - b;
        expect(c, greaterThan(0), reason: 'third angle must be positive');
        expect(a, greaterThan(0));
        expect(b, greaterThan(0));
        expect(q.correctAnswer, '$c');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('parallel_lines_transversal', () {
    test(
      'equal-angle relations return a; co-interior returns 180 − a',
      () {
        final re = RegExp(
          r'^Two parallel lines are cut by a transversal\. '
          r'One angle is (\d+)°\. '
          'What is the (corresponding|alternate interior|'
          r'alternate exterior|co-interior) angle\?$',
        );
        final relationsSeen = <String>{};
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'parallel_lines_transversal', i);
          final m = re.firstMatch(q.prompt);
          expect(m, isNotNull, reason: q.prompt);
          final a = int.parse(m!.group(1)!);
          final relation = m.group(2)!;
          relationsSeen.add(relation);
          final expected = relation == 'co-interior' ? 180 - a : a;
          expect(q.correctAnswer, '$expected');
          _expectThreeDistinctDistractors(q);
        }
        expect(
          relationsSeen,
          containsAll(<String>[
            'corresponding',
            'alternate interior',
            'alternate exterior',
            'co-interior',
          ]),
        );
      },
    );
  });
}
