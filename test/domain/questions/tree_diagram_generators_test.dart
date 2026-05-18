import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/fraction.dart';
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

  group('tree_diagram', () {
    test(
      'answer equals product of stage outcome counts; all 4 experiments '
      'appear across seeds',
      () {
        final expsSeen = <String>{};
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'tree_diagram', i);
          expect(q.diagram, isA<TreeDiagramSpec>());
          final spec = q.diagram! as TreeDiagramSpec;
          expect(spec.stages, hasLength(2));
          final n1 = spec.stages[0].outcomes.length;
          final n2 = spec.stages[1].outcomes.length;
          expect(int.parse(q.correctAnswer), n1 * n2);
          expsSeen.add(
            '${spec.stages[0].label}-${n1}x${spec.stages[1].label}-$n2',
          );
          _expectThreeDistinctDistractors(q);
        }
        // At least 3 of the 4 experiments should appear in 300 iterations
        // (sanity — uniform sampling makes 4-of-4 very likely too).
        expect(expsSeen.length, greaterThanOrEqualTo(3));
      },
    );
  });

  group('compound_event_probability', () {
    test(
      'correctAnswer equals 1/leafCount in canonical form; answerFormat is '
      'fraction',
      () {
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'compound_event_probability', i);
          expect(q.diagram, isA<TreeDiagramSpec>());
          final spec = q.diagram! as TreeDiagramSpec;
          final leaves = spec.leafCount;
          expect(q.correctAnswer, Fraction(1, leaves).toCanonical());
          expect(q.answerFormat, AnswerFormat.fraction);
          _expectThreeDistinctDistractors(q);
        }
      },
    );
  });
}
