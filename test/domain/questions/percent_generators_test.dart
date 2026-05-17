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

  group('percent_intro', () {
    test('answer matches the diagram shadedCount; never trivial 0/50/100', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'percent_intro', i);
        expect(q.prompt, 'What percent is shaded?');
        final diagram = q.diagram;
        expect(diagram, isA<PercentGridSpec>());
        final shaded = (diagram! as PercentGridSpec).shadedCount;
        expect(shaded, inInclusiveRange(1, 99));
        expect(shaded, isNot(50));
        expect(q.correctAnswer, '$shaded');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('percent_of_quantity', () {
    test('answer is always a whole number; arithmetic is exact', () {
      final re = RegExp(r'^What is (\d+)% of (\d+)\?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'percent_of_quantity', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final percent = int.parse(m!.group(1)!);
        final quantity = int.parse(m.group(2)!);
        // Must produce an integer with no remainder.
        expect(
          percent * quantity % 100,
          0,
          reason: 'non-integer answer in ${q.prompt}',
        );
        final expected = percent * quantity ~/ 100;
        expect(q.correctAnswer, '$expected');
        expect(percent, inInclusiveRange(1, 99));
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('find_whole_from_part_percent', () {
    test('answer = whole; part is consistent with percent and whole', () {
      final re = RegExp(r'^(\d+) is (\d+)% of what number\?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'find_whole_from_part_percent', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final part = int.parse(m!.group(1)!);
        final percent = int.parse(m.group(2)!);
        final whole = int.parse(q.correctAnswer);
        // part = percent% × whole.
        expect(
          percent * whole % 100,
          0,
          reason: 'non-integer part in ${q.prompt}',
        );
        expect(
          percent * whole ~/ 100,
          part,
          reason: 'part/percent/whole inconsistent in ${q.prompt}',
        );
        expect(percent, inInclusiveRange(1, 99));
        _expectThreeDistinctDistractors(q);
      }
    });
  });
}
