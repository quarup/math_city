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

ShapeSpec _spec(GeneratedQuestion q) => q.diagram! as ShapeSpec;

void main() {
  late GeneratorRegistry registry;
  setUp(() => registry = GeneratorRegistry.defaultRegistry());

  group('identify_shape_2d', () {
    test('answer matches the rendered shape kind; all six names appear', () {
      final seenAnswers = <String>{};
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'identify_shape_2d', i);
        final spec = _spec(q);
        expect(spec.kind.is3D, isFalse);
        expect(q.correctAnswer, spec.kind.displayName);
        expect(q.answerFormat, AnswerFormat.string);
        _expectThreeDistinctDistractors(q);
        seenAnswers.add(q.correctAnswer);
      }
      // Every kid-name in the answer pool should appear across 300 seeds.
      expect(
        seenAnswers,
        containsAll(<String>[
          'circle',
          'triangle',
          'square',
          'rectangle',
          'pentagon',
          'hexagon',
        ]),
      );
    });
  });

  group('identify_shape_3d', () {
    test('answer matches one of cube/sphere/cylinder/cone; all appear', () {
      final seen = <String>{};
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'identify_shape_3d', i);
        final spec = _spec(q);
        expect(spec.kind.is3D, isTrue);
        expect(q.correctAnswer, spec.kind.displayName);
        expect(
          ['cube', 'sphere', 'cylinder', 'cone'],
          contains(q.correctAnswer),
        );
        _expectThreeDistinctDistractors(q);
        seen.add(q.correctAnswer);
      }
      expect(seen, hasLength(4));
    });
  });

  group('shape_attributes_basic', () {
    test('answer equals sideCount of the rendered shape', () {
      final seenSides = <int>{};
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'shape_attributes_basic', i);
        final spec = _spec(q);
        final n = spec.kind.sideCount;
        // Must come from the 2D polygon pool (3, 4, 5, 6, or 8 sides).
        expect([3, 4, 5, 6, 8], contains(n));
        expect(int.parse(q.correctAnswer), n);
        _expectThreeDistinctDistractors(q);
        seenSides.add(n);
      }
      // At least three distinct side-counts should be visited.
      expect(seenSides.length, greaterThanOrEqualTo(3));
    });
  });

  group('identify_polygons', () {
    test('correct name maps by side count; pool covers all four names', () {
      const expectedByCount = {
        3: 'triangle',
        4: 'quadrilateral',
        5: 'pentagon',
        6: 'hexagon',
      };
      final seenAnswers = <String>{};
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'identify_polygons', i);
        final spec = _spec(q);
        expect(q.correctAnswer, expectedByCount[spec.kind.sideCount]);
        expect(q.answerFormat, AnswerFormat.string);
        _expectThreeDistinctDistractors(q);
        seenAnswers.add(q.correctAnswer);
      }
      expect(
        seenAnswers,
        containsAll(<String>[
          'triangle',
          'quadrilateral',
          'pentagon',
          'hexagon',
        ]),
      );
    });
  });
}
