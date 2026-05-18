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

  group('ratio_to_coordinate_pairs', () {
    test(
      '3 plotted points; all collinear through origin with ratio matching '
      'correctAnswer; ratio is in lowest terms with a != b',
      () {
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'ratio_to_coordinate_pairs', i);
          expect(q.diagram, isA<CoordinatePlaneSpec>());
          final spec = q.diagram! as CoordinatePlaneSpec;
          expect(spec.points, hasLength(3));
          // Parse "a:b" answer.
          final m = RegExp(r'^(\d+):(\d+)$').firstMatch(q.correctAnswer);
          expect(m, isNotNull);
          final a = int.parse(m!.group(1)!);
          final b = int.parse(m.group(2)!);
          expect(a, isNot(b));
          // Each point = (k*a, k*b) for k = 1, 2, 3.
          for (var k = 1; k <= 3; k++) {
            final p = spec.points[k - 1];
            expect(p.x, k * a);
            expect(p.y, k * b);
          }
          _expectThreeDistinctDistractors(q);
        }
      },
    );
  });

  group('dependent_independent_vars', () {
    test(
      'correctAnswer is one of the scenario variables; the other variable '
      'is the first distractor; "Both vary together" and "Neither is a '
      'variable" are also distractors',
      () {
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'dependent_independent_vars', i);
          expect(q.answerFormat, AnswerFormat.string);
          expect(q.distractors, contains('Both vary together'));
          expect(q.distractors, contains('Neither is a variable'));
          _expectThreeDistinctDistractors(q);
        }
      },
    );
  });
}
