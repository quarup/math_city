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

ProtractorSpec _spec(GeneratedQuestion q) => q.diagram! as ProtractorSpec;

void main() {
  late GeneratorRegistry registry;
  setUp(() => registry = GeneratorRegistry.defaultRegistry());

  group('measure_angle_protractor', () {
    test('angle ∈ [15, 165], step 5, not 90; answer = angleDeg', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'measure_angle_protractor', i);
        final spec = _spec(q);
        expect(spec.angleDeg, inInclusiveRange(15, 165));
        expect(spec.angleDeg % 5, 0);
        expect(spec.angleDeg, isNot(90));
        expect(spec.showAngleLabel, isFalse);
        expect(int.parse(q.correctAnswer), spec.angleDeg);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('draw_angle_protractor', () {
    test('label shown inside wedge; answer = angleDeg', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'draw_angle_protractor', i);
        final spec = _spec(q);
        expect(spec.angleDeg, inInclusiveRange(15, 165));
        expect(spec.angleDeg % 5, 0);
        expect(spec.angleDeg, isNot(90));
        expect(spec.showAngleLabel, isTrue);
        expect(int.parse(q.correctAnswer), spec.angleDeg);
        _expectThreeDistinctDistractors(q);
      }
    });
  });
}
