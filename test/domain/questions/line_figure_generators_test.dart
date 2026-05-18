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

  group('identify_lines_rays_segments', () {
    test('all three names appear; answer matches the kind', () {
      const valid = {
        LineFigureKind.line: 'line',
        LineFigureKind.ray: 'ray',
        LineFigureKind.segment: 'line segment',
      };
      final seen = <String>{};
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'identify_lines_rays_segments', i);
        final spec = q.diagram! as LineFigureSpec;
        expect(valid.containsKey(spec.kind), isTrue);
        expect(q.correctAnswer, valid[spec.kind]);
        expect(q.answerFormat, AnswerFormat.string);
        _expectThreeDistinctDistractors(q);
        seen.add(q.correctAnswer);
      }
      expect(seen, containsAll(<String>['line', 'ray', 'line segment']));
    });
  });

  group('parallel_perpendicular_lines', () {
    test('all three relations appear; answer matches the kind', () {
      const valid = {
        LineFigureKind.parallelLines: 'parallel',
        LineFigureKind.perpendicularLines: 'perpendicular',
        LineFigureKind.intersectingLines: 'intersecting',
      };
      final seen = <String>{};
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'parallel_perpendicular_lines', i);
        final spec = q.diagram! as LineFigureSpec;
        expect(valid.containsKey(spec.kind), isTrue);
        expect(q.correctAnswer, valid[spec.kind]);
        _expectThreeDistinctDistractors(q);
        seen.add(q.correctAnswer);
      }
      expect(
        seen,
        containsAll(<String>['parallel', 'perpendicular', 'intersecting']),
      );
    });
  });

  group('classify_2d_by_lines_angles', () {
    test('answer is Yes/No; both appear; matches the shape', () {
      final seen = <String>{};
      var rightAnglesFlavour = 0;
      var equalSidesFlavour = 0;
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'classify_2d_by_lines_angles', i);
        final spec = q.diagram! as ShapeSpec;
        expect(spec.kind.sideCount, 4, reason: 'should be a quadrilateral');
        expect(['Yes', 'No'], contains(q.correctAnswer));
        _expectThreeDistinctDistractors(q);
        seen.add(q.correctAnswer);
        if (q.prompt.contains('right angles')) {
          rightAnglesFlavour++;
          final expectYes =
              spec.kind == ShapeKind.square || spec.kind == ShapeKind.rectangle;
          expect(q.correctAnswer, expectYes ? 'Yes' : 'No');
        } else if (q.prompt.contains('same length')) {
          equalSidesFlavour++;
          final expectYes =
              spec.kind == ShapeKind.square || spec.kind == ShapeKind.rhombus;
          expect(q.correctAnswer, expectYes ? 'Yes' : 'No');
        }
      }
      expect(seen, containsAll(<String>['Yes', 'No']));
      expect(rightAnglesFlavour, greaterThan(0));
      expect(equalSidesFlavour, greaterThan(0));
    });
  });
}
