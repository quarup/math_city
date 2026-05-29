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

  group('experimental_probability', () {
    test('answer = reduce(successes / trials)', () {
      // Anchor on the two specific "$num times" slots — trials before
      // the first "times" and successes before the second.
      final re = RegExp(
        r'(\d+) times.*?(\d+) times\.',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'experimental_probability', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final trials = int.parse(m!.group(1)!);
        final successes = int.parse(m.group(2)!);
        final expected = Fraction(successes, trials).reduce().toCanonical();
        expect(q.correctAnswer, expected, reason: q.prompt);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('sample_space_list', () {
    test('answer is a positive whole number; distractors distinct', () {
      // No common regex for the prompt — just sanity-check the contract.
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'sample_space_list', i);
        final ans = int.parse(q.correctAnswer);
        expect(ans, greaterThan(0));
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('theoretical_vs_experimental', () {
    test('answer matches the asked-for probability shape', () {
      // Device → theoretical reduced canonical form. Anchored to the
      // four scenarios in the generator.
      const theoretical = <String, String>{
        'heads': '1/2',
        'a 4': '1/6',
        'red': '1/4',
        'blue': '1/5',
      };
      // Match either "$preamble $question" where question starts with
      // "What is the THEORETICAL/EXPERIMENTAL probability of $resultShort?"
      // Extract trials, observed, and the question shape.
      final re = RegExp(
        r'(\d+) times and .+? (\d+) times\. '
        r'What is the (theoretical|experimental) probability of (.+)\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'theoretical_vs_experimental', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final trials = int.parse(m!.group(1)!);
        final observed = int.parse(m.group(2)!);
        final shape = m.group(3)!;
        final resultShort = m.group(4)!;
        final expectedTheoretical = theoretical[resultShort];
        expect(
          expectedTheoretical,
          isNotNull,
          reason: 'unknown resultShort: $resultShort',
        );
        if (shape == 'theoretical') {
          expect(q.correctAnswer, expectedTheoretical);
        } else {
          final reduced = Fraction(observed, trials).reduce().toCanonical();
          expect(q.correctAnswer, reduced);
          // Pedagogical guarantee: experimental ≠ theoretical so the
          // two shapes don't collapse to the same answer.
          expect(q.correctAnswer, isNot(expectedTheoretical));
        }
        expect(q.answerFormat, AnswerFormat.fraction);
        expect(q.answerShape, AnswerShape.exactString);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('probability_simple_event', () {
    test('answer = reduce(favourable / total) — both framings', () {
      final bagRe = RegExp(
        r'^A bag has (\d+) (\S+) marbles and (\d+) \S+ marbles\. '
        r'You pick one at random\. What is P\((\S+)\)\?$',
      );
      final spinnerRe = RegExp(
        r'^The spinner shown has (\d+) equal sectors\. '
        r'If you spin it once, what is P\((\S+)\)\?$',
      );
      var sawBag = false;
      var sawSpinner = false;
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'probability_simple_event', i);
        final bagM = bagRe.firstMatch(q.prompt);
        final spinM = spinnerRe.firstMatch(q.prompt);
        if (bagM != null) {
          sawBag = true;
          final a = int.parse(bagM.group(1)!);
          final favourable = bagM.group(2)!;
          final b = int.parse(bagM.group(3)!);
          final asked = bagM.group(4)!;
          expect(asked, favourable);
          expect(q.diagram, isNull);
          final expected = Fraction(a, a + b).reduce().toCanonical();
          expect(q.correctAnswer, expected);
        } else if (spinM != null) {
          sawSpinner = true;
          final total = int.parse(spinM.group(1)!);
          final asked = spinM.group(2)!;
          final spec = q.diagram! as SpinnerSpec;
          expect(spec.sectors.length, total);
          final favCount = spec.sectors.where((c) => c == asked).length;
          final expected = Fraction(favCount, total).reduce().toCanonical();
          expect(q.correctAnswer, expected);
        } else {
          fail('prompt matched neither framing: ${q.prompt}');
        }
        expect(q.answerFormat, AnswerFormat.fraction);
        expect(q.answerShape, AnswerShape.exactString);
        _expectThreeDistinctDistractors(q);
      }
      expect(sawBag, isTrue, reason: 'should sometimes use bag framing');
      expect(
        sawSpinner,
        isTrue,
        reason: 'should sometimes use spinner framing',
      );
    });
  });
}
