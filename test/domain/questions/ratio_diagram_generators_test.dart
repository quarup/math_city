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

  group('ratio_table', () {
    test('tape units = a:b; answer = b*k; prompt mentions a*k', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'ratio_table', i);
        final spec = q.diagram! as TapeDiagramSpec;
        expect(spec.topUnits, inInclusiveRange(2, 5));
        expect(spec.bottomUnits, inInclusiveRange(2, 5));
        expect(spec.topUnits, isNot(spec.bottomUnits));
        // Parse 2 numbers from prompt: a, a*k.
        final nums =
            RegExp(r'-?\d+').allMatches(q.prompt).map((m) => int.parse(m.group(0)!)).toList();
        expect(nums.length, greaterThanOrEqualTo(3));
        final a = spec.topUnits;
        final b = spec.bottomUnits;
        expect(nums[0], a);
        expect(nums[1], b);
        final aTimesK = nums[2];
        expect(aTimesK % a, 0, reason: 'a*k should be divisible by a');
        final k = aTimesK ~/ a;
        expect(int.parse(q.correctAnswer), b * k);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('double_number_line', () {
    test('top/bottom values align as multiples of a, b; answer = 4·b', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'double_number_line', i);
        final spec = q.diagram! as DoubleNumberLineSpec;
        expect(spec.topValues, hasLength(4));
        expect(spec.bottomValues, hasLength(4));
        // First values are 0; subsequent values progress in steps of a/b.
        expect(spec.topValues[0], 0);
        expect(spec.bottomValues[0], 0);
        final a = spec.topValues[1];
        final b = spec.bottomValues[1];
        expect(spec.topValues, [0, a, 2 * a, 3 * a]);
        expect(spec.bottomValues, [0, b, 2 * b, 3 * b]);
        expect(int.parse(q.correctAnswer), 4 * b);
        _expectThreeDistinctDistractors(q);
      }
    });
  });
}
