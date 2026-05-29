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

  group('positional_words', () {
    test('answer matches scene.relation; all 4 positions appear', () {
      const valid = {'above', 'below', 'beside', 'inside'};
      const relationWord = {
        PositionRelation.above: 'above',
        PositionRelation.below: 'below',
        PositionRelation.beside: 'beside',
        PositionRelation.inside: 'inside',
      };
      final seen = <String>{};
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'positional_words', i);
        expect(valid, contains(q.correctAnswer));
        final spec = q.diagram;
        expect(spec, isA<PositionalSceneSpec>());
        final scene = spec! as PositionalSceneSpec;
        expect(q.correctAnswer, relationWord[scene.relation]);
        expect(scene.subjectLabel.isNotEmpty, isTrue);
        expect(scene.referenceLabel.isNotEmpty, isTrue);
        _expectThreeDistinctDistractors(q);
        seen.add(q.correctAnswer);
      }
      expect(seen, valid);
    });
  });

  group('partition_circle_rect_halves', () {
    test('answer is Yes iff denominator is 2; both Yes and No appear', () {
      var yesCount = 0;
      var noCount = 0;
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'partition_circle_rect_halves', i);
        final spec = q.diagram! as FractionBarSpec;
        expect([2, 3, 4, 6], contains(spec.denominator));
        final isHalves = spec.denominator == 2;
        expect(q.correctAnswer, isHalves ? 'Yes' : 'No');
        _expectThreeDistinctDistractors(q);
        if (isHalves) {
          yesCount++;
        } else {
          noCount++;
        }
      }
      expect(yesCount, greaterThan(0));
      expect(noCount, greaterThan(0));
    });
  });

  group('estimate_length', () {
    test('answer comes from the scenario MC pool', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'estimate_length', i);
        expect(q.answerFormat, AnswerFormat.string);
        _expectThreeDistinctDistractors(q);
        // Each scenario answer is units-typed; assert a "unit" word
        // (inch/inches/foot/feet) appears in the correct answer.
        final hasUnit =
            q.correctAnswer.contains('inch') ||
            q.correctAnswer.contains('foot') ||
            q.correctAnswer.contains('feet');
        expect(
          hasUnit,
          isTrue,
          reason: 'correct answer "${q.correctAnswer}" must include units',
        );
      }
    });
  });
}
