import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
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

void main() {
  late GeneratorRegistry registry;
  setUp(() => registry = GeneratorRegistry.defaultRegistry());

  group('probability_zero_to_one', () {
    test('answer is a string from the scenario menu; distractors distinct', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'probability_zero_to_one', i);
        expect(q.correctAnswer, isNotEmpty);
        expect(q.answerFormat, AnswerFormat.string);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('probability_simple_event', () {
    test('answer = reduce(a / (a+b))', () {
      final re = RegExp(
        r'^A bag has (\d+) (\S+) marbles and (\d+) \S+ marbles\. '
        r'You pick one at random\. What is P\((\S+)\)\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'probability_simple_event', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final a = int.parse(m!.group(1)!);
        final favourable = m.group(2)!;
        final b = int.parse(m.group(3)!);
        final asked = m.group(4)!;
        expect(asked, favourable, reason: 'prompt asks for the favourable');
        final expected = Fraction(a, a + b).reduce().toCanonical();
        expect(q.correctAnswer, expected);
        expect(q.answerFormat, AnswerFormat.fraction);
        expect(q.answerShape, AnswerShape.exactString);
        _expectThreeDistinctDistractors(q);
      }
    });
  });
}
