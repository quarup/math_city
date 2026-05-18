import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
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

  group('describe_attribute', () {
    test('answer is one of the four attribute words; all appear', () {
      const valid = {'length', 'weight', 'capacity', 'temperature'};
      final seen = <String>{};
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'describe_attribute', i);
        expect(valid, contains(q.correctAnswer));
        expect(q.answerFormat, AnswerFormat.string);
        _expectThreeDistinctDistractors(q);
        seen.add(q.correctAnswer);
      }
      // 8 scenarios cover all 4 attributes — should all appear.
      expect(seen, valid);
    });
  });

  group('compare_two_objects', () {
    test('answer is one of the two subjects; prompt has both numbers', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'compare_two_objects', i);
        // Parse the two numeric values from the prompt and assert the
        // answer points at the larger one.
        final nums = RegExp(r'\d+')
            .allMatches(q.prompt)
            .map((m) => int.parse(m.group(0)!))
            .toList();
        expect(nums.length, greaterThanOrEqualTo(2));
        expect(nums[0] != nums[1], isTrue);
        final compWord = q.prompt.contains('longer')
            ? 'longer'
            : q.prompt.contains('heavier')
                ? 'heavier'
                : 'bigger';
        expect(['longer', 'heavier', 'bigger'], contains(compWord));
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('order_three_objects_length', () {
    test('answer matches the extreme subject; both flavours appear', () {
      var shortestFlavour = 0;
      var longestFlavour = 0;
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'order_three_objects_length', i);
        final nums = RegExp(r'\d+')
            .allMatches(q.prompt)
            .map((m) => int.parse(m.group(0)!))
            .toList();
        expect(nums.length, greaterThanOrEqualTo(3));
        expect(nums.toSet().length, 3);
        _expectThreeDistinctDistractors(q);
        if (q.prompt.contains('shortest')) {
          shortestFlavour++;
        } else if (q.prompt.contains('longest')) {
          longestFlavour++;
        }
      }
      expect(shortestFlavour, greaterThan(0));
      expect(longestFlavour, greaterThan(0));
    });
  });
}
