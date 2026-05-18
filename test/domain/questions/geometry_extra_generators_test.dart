import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';
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

  group('compose_shapes', () {
    test('answer matches the known compositions', () {
      const expected = {
        ShapeKind.rectangle: 'square',
        ShapeKind.hexagon: 'trapezoid',
        ShapeKind.rhombus: 'triangle',
        ShapeKind.square: 'triangle',
      };
      final seen = <ShapeKind>{};
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'compose_shapes', i);
        final spec = q.diagram! as ShapeSpec;
        expect(expected.containsKey(spec.kind), isTrue);
        expect(q.correctAnswer, expected[spec.kind]);
        _expectThreeDistinctDistractors(q);
        seen.add(spec.kind);
      }
      expect(seen, expected.keys.toSet());
    });
  });

  group('cross_section_3d', () {
    test('horizontal cross-section matches the solid', () {
      const expected = {
        ShapeKind.cube: 'square',
        ShapeKind.cylinder: 'circle',
        ShapeKind.cone: 'circle',
        ShapeKind.sphere: 'circle',
      };
      final seen = <ShapeKind>{};
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'cross_section_3d', i);
        final spec = q.diagram! as ShapeSpec;
        expect(expected.containsKey(spec.kind), isTrue);
        expect(q.correctAnswer, expected[spec.kind]);
        _expectThreeDistinctDistractors(q);
        seen.add(spec.kind);
      }
      expect(seen, expected.keys.toSet());
    });
  });

  group('volume_unit_cubes', () {
    test('answer = l × w × h from the Box3DSpec', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'volume_unit_cubes', i);
        final spec = q.diagram! as Box3DSpec;
        expect(spec.showUnitGrid, isTrue);
        expect(int.parse(q.correctAnswer),
            spec.length * spec.width * spec.height);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('surface_area_from_net', () {
    test('answer = 6·s² where s = Net3DSpec.edgeLength', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'surface_area_from_net', i);
        final spec = q.diagram! as Net3DSpec;
        final s = spec.edgeLength;
        expect(int.parse(q.correctAnswer), 6 * s * s);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('area_polygon_decompose', () {
    test('answer = a + b drawn from the prompt', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'area_polygon_decompose', i);
        final nums = RegExp(r'\d+')
            .allMatches(q.prompt)
            .map((m) => int.parse(m.group(0)!))
            .toList();
        expect(nums.length, greaterThanOrEqualTo(2));
        final a = nums[0];
        final b = nums[1];
        expect(int.parse(q.correctAnswer), a + b);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('scale_drawing', () {
    test('both forward and inverse flavours appear; arithmetic checks', () {
      var forwardCount = 0;
      var inverseCount = 0;
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'scale_drawing', i);
        final nums = RegExp(r'\d+')
            .allMatches(q.prompt)
            .map((m) => int.parse(m.group(0)!))
            .toList();
        expect(nums.length, greaterThanOrEqualTo(2));
        final ans = int.parse(q.correctAnswer);
        if (q.prompt.contains('long is the actual wall')) {
          // Forward: "1 inch represents s feet. drawing is d inches.
          // How long is the actual wall?" — nums = [1, s, d].
          final s = nums[1];
          final d = nums[2];
          expect(ans, d * s);
          forwardCount++;
        } else {
          // Inverse: "A wall is r feet long. ... 1 inch represents s
          // feet, how many inches?" — nums = [r, 1, s].
          final r = nums[0];
          final s = nums[2];
          expect(ans, r ~/ s);
          inverseCount++;
        }
        _expectThreeDistinctDistractors(q);
      }
      expect(forwardCount, greaterThan(0));
      expect(inverseCount, greaterThan(0));
    });
  });
}
