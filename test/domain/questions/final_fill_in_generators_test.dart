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

  group('compare_groups_by_count', () {
    test('answer matches the group with the larger count', () {
      var aWins = 0;
      var bWins = 0;
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'compare_groups_by_count', i);
        final spec = q.diagram! as PictureGraphSpec;
        expect(spec.rowLabels, ['Group A', 'Group B']);
        expect(spec.values, hasLength(2));
        final a = spec.values[0];
        final b = spec.values[1];
        expect(a != b, isTrue);
        final expected = a > b ? 'Group A' : 'Group B';
        expect(q.correctAnswer, expected);
        if (expected == 'Group A') aWins++;
        if (expected == 'Group B') bWins++;
        _expectThreeDistinctDistractors(q);
      }
      expect(aWins, greaterThan(0));
      expect(bWins, greaterThan(0));
    });
  });

  group('measure_length_units', () {
    test('answer = markedLength on the rendered Ruler', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'measure_length_units', i);
        final spec = q.diagram! as RulerSpec;
        expect(spec.markedLength, inInclusiveRange(2, 8));
        expect(spec.unitLabel, 'blocks');
        expect(int.parse(q.correctAnswer), spec.markedLength);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('volume_composite', () {
    test('answer = V1 + V2 drawn from the prompt', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'volume_composite', i);
        expect((q.diagram! as ShapeSpec).kind, ShapeKind.cube);
        final nums = RegExp(
          r'\d+',
        ).allMatches(q.prompt).map((m) => int.parse(m.group(0)!)).toList();
        // First three numbers = "first" prism, next three = "second"
        // prism. Check both come from the prompt before "1" / "2"
        // ordinals — that gets parsed as a number too. Filter to the
        // dimension nums (skip ordinal 1, 2 if present).
        // Simpler: assume the 6 dimension numbers occupy the last 6
        // positions in the prompt — works because the prompt phrasing
        // is consistent.
        expect(nums.length, greaterThanOrEqualTo(6));
        final dims = nums.sublist(nums.length - 6);
        final v1 = dims[0] * dims[1] * dims[2];
        final v2 = dims[3] * dims[4] * dims[5];
        expect(int.parse(q.correctAnswer), v1 + v2);
        _expectThreeDistinctDistractors(q);
      }
    });
  });
}
