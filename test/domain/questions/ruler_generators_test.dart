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

RulerSpec _spec(GeneratedQuestion q) => q.diagram! as RulerSpec;

void main() {
  late GeneratorRegistry registry;
  setUp(() => registry = GeneratorRegistry.defaultRegistry());

  group('measure_with_ruler_cm', () {
    test('answer = markedLength on a whole-cm ruler', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'measure_with_ruler_cm', i);
        final spec = _spec(q);
        expect(spec.subdivisions, 1);
        expect(spec.unitLabel, 'cm');
        expect(spec.markedLength, inInclusiveRange(2, 14));
        expect(q.correctAnswer, '${spec.markedLength}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('measure_to_half_cm', () {
    test('the bar ends on a half tick; answer is the mixed number', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'measure_to_half_cm', i);
        final spec = _spec(q);
        expect(spec.unitLabel, 'cm');
        expect(spec.subdivisions, 2);
        expect(spec.markedLength.isOdd, isTrue, reason: 'on a half tick');
        expect(q.correctAnswer, '${spec.markedLength ~/ 2} 1/2');
        _expectThreeDistinctDistractors(q);
      }
    });
  });
}
