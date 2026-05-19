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
    test('LengthBars carries 2 distinct values; answer is the larger', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'compare_two_objects', i);
        final spec = q.diagram;
        expect(spec, isA<LengthBarsSpec>());
        final bars = (spec! as LengthBarsSpec).bars;
        expect(bars, hasLength(2));
        expect(bars[0].length != bars[1].length, isTrue);
        final compWord = q.prompt.contains('longer')
            ? 'longer'
            : q.prompt.contains('heavier')
            ? 'heavier'
            : 'bigger';
        expect(['longer', 'heavier', 'bigger'], contains(compWord));
        // The answer is whichever bar has the larger length.
        final larger = bars[0].length > bars[1].length ? bars[0] : bars[1];
        expect(q.correctAnswer, larger.label);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('order_three_objects_length', () {
    test('LengthBars carries 3 distinct values; answer matches flavour', () {
      var shortestFlavour = 0;
      var longestFlavour = 0;
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'order_three_objects_length', i);
        final spec = q.diagram;
        expect(spec, isA<LengthBarsSpec>());
        final bars = (spec! as LengthBarsSpec).bars;
        expect(bars, hasLength(3));
        expect(bars.map((b) => b.length).toSet().length, 3);
        _expectThreeDistinctDistractors(q);
        final sorted = [...bars]..sort((a, b) => a.length.compareTo(b.length));
        if (q.prompt.contains('shortest')) {
          shortestFlavour++;
          expect(q.correctAnswer, sorted.first.label);
        } else if (q.prompt.contains('longest')) {
          longestFlavour++;
          expect(q.correctAnswer, sorted.last.label);
        }
      }
      expect(shortestFlavour, greaterThan(0));
      expect(longestFlavour, greaterThan(0));
    });
  });
}
