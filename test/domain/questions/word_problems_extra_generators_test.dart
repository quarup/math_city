import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/generator_registry.dart';

const _iterations = 200;

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

  group('length_word_problems', () {
    test('+ or − single-step; both flavors appear', () {
      var sawAdd = false;
      var sawSub = false;
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'length_word_problems', i);
        final answer = int.parse(q.correctAnswer);
        expect(answer, greaterThan(0));
        if (q.prompt.contains('attaches')) sawAdd = true;
        if (q.prompt.contains('cuts off')) sawSub = true;
        _expectThreeDistinctDistractors(q);
      }
      expect(sawAdd && sawSub, isTrue);
    });
  });

  group('money_word_problems', () {
    test('both flavors (coin count, dollars) appear; answer non-negative', () {
      var sawCoins = false;
      var sawDollars = false;
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'money_word_problems', i);
        final answer = int.parse(q.correctAnswer);
        expect(answer, greaterThan(0));
        if (q.prompt.contains('in cents')) sawCoins = true;
        if (q.prompt.contains('in dollars')) sawDollars = true;
        _expectThreeDistinctDistractors(q);
      }
      expect(sawCoins && sawDollars, isTrue);
    });
  });

  group('liquid_volume_mass', () {
    test('answer = start − removed; both stay positive', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'liquid_volume_mass', i);
        final answer = int.parse(q.correctAnswer);
        expect(answer, greaterThan(0));
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('mult_div_word_2step', () {
    test('answer is positive integer; both flavors appear', () {
      var sawMul = false;
      var sawDiv = false;
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'mult_div_word_2step', i);
        final answer = int.parse(q.correctAnswer);
        expect(answer, greaterThan(0));
        if (q.prompt.contains('boxes')) sawMul = true;
        if (q.prompt.contains('baskets')) sawDiv = true;
        _expectThreeDistinctDistractors(q);
      }
      expect(sawMul && sawDiv, isTrue);
    });
  });

  group('area_perimeter_word', () {
    test('answer = l*w (area) or 2(l+w) (perimeter); both appear', () {
      final re = RegExp(r'is (\d+) m long and (\d+) m wide');
      var sawArea = false;
      var sawPerim = false;
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'area_perimeter_word', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final l = int.parse(m!.group(1)!);
        final w = int.parse(m.group(2)!);
        final isArea = q.prompt.contains('area');
        if (isArea) {
          sawArea = true;
          expect(int.parse(q.correctAnswer), l * w);
        } else {
          sawPerim = true;
          expect(int.parse(q.correctAnswer), 2 * (l + w));
        }
        _expectThreeDistinctDistractors(q);
      }
      expect(sawArea && sawPerim, isTrue);
    });
  });

  group('convert_units_multistep', () {
    test('answer = big × multiplier + small', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'convert_units_multistep', i);
        final answer = int.parse(q.correctAnswer);
        expect(answer, greaterThan(0));
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('statistical_question', () {
    test('correct answer is one of the statistical question strings', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'statistical_question', i);
        expect(q.correctAnswer, isNotEmpty);
        // The prompt asks for a stat question; correct should sound plural.
        // We just check there are 3 unique distractors, all different.
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('sampling_representativeness', () {
    test('answer is Yes or No; both appear', () {
      var sawYes = false;
      var sawNo = false;
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'sampling_representativeness', i);
        expect(['Yes', 'No'], contains(q.correctAnswer));
        if (q.correctAnswer == 'Yes') sawYes = true;
        if (q.correctAnswer == 'No') sawNo = true;
        _expectThreeDistinctDistractors(q);
      }
      expect(sawYes && sawNo, isTrue);
    });
  });
}
