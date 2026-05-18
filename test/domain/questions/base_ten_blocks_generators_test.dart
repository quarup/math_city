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

BaseTenBlocksSpec _spec(GeneratedQuestion q) =>
    q.diagram! as BaseTenBlocksSpec;

void main() {
  late GeneratorRegistry registry;
  setUp(() => registry = GeneratorRegistry.defaultRegistry());

  group('teen_numbers_as_ten_plus', () {
    test(
        'always 1 ten + 1..9 ones; answer = ones; total in prompt is 11..19',
        () {
      final seenOnes = <int>{};
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'teen_numbers_as_ten_plus', i);
        final spec = _spec(q);
        expect(spec.tens, 1);
        expect(spec.hundreds, 0);
        expect(spec.ones, inInclusiveRange(1, 9));
        final ones = spec.ones;
        expect(int.parse(q.correctAnswer), ones);
        // The prompt mentions the total — must be 11..19.
        final total = 10 + ones;
        expect(q.prompt, contains('$total'));
        _expectThreeDistinctDistractors(q);
        seenOnes.add(ones);
      }
      // At least 7 distinct ones-counts in 300 iterations.
      expect(seenOnes.length, greaterThanOrEqualTo(7));
    });
  });
}
