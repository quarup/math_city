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

RulerSpec _spec(GeneratedQuestion q) => q.diagram! as RulerSpec;

void main() {
  late GeneratorRegistry registry;
  setUp(() => registry = GeneratorRegistry.defaultRegistry());

  group('measure_with_ruler_inches', () {
    test('answer = markedLength on a whole-inch ruler', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'measure_with_ruler_inches', i);
        final spec = _spec(q);
        expect(spec.subdivisions, 1);
        expect(spec.unitLabel, 'in');
        expect(spec.markedLength, inInclusiveRange(1, 8));
        expect(spec.markedLength, lessThanOrEqualTo(spec.totalLength));
        expect(q.correctAnswer, '${spec.markedLength}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

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

  group('measure_to_half_quarter_inch', () {
    test('answer = markedLength / subdivisions in mixed form', () {
      final subsSeen = <int>{};
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'measure_to_half_quarter_inch', i);
        final spec = _spec(q);
        expect([2, 4], contains(spec.subdivisions));
        expect(
          spec.markedLength % spec.subdivisions,
          isNot(0),
          reason: 'must land on a fractional tick',
        );
        subsSeen.add(spec.subdivisions);

        // Parse correctAnswer ("W A/B" or "A/B") and confirm value.
        final whole = spec.markedLength ~/ spec.subdivisions;
        final num = spec.markedLength % spec.subdivisions;
        final reduced = Fraction(num, spec.subdivisions).reduce();
        final expected = whole == 0
            ? '${reduced.numerator}/${reduced.denominator}'
            : '$whole ${reduced.numerator}/${reduced.denominator}';
        expect(q.correctAnswer, expected);
        _expectThreeDistinctDistractors(q);
      }
      expect(subsSeen, {2, 4});
    });
  });
}
