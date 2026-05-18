import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';
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

  group('partition_halves_fourths', () {
    test('denom ∈ {2, 4}; correct == numerator/denom from diagram', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'partition_halves_fourths', i);
        final spec = q.diagram! as FractionBarSpec;
        expect([2, 4], contains(spec.denominator));
        expect(spec.numerator, inInclusiveRange(1, spec.denominator - 1));
        expect(q.correctAnswer, '${spec.numerator}/${spec.denominator}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('partition_thirds', () {
    test('denom = 3; numerator ∈ {1, 2}', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'partition_thirds', i);
        final spec = q.diagram! as FractionBarSpec;
        expect(spec.denominator, 3);
        expect(spec.numerator, inInclusiveRange(1, 2));
        expect(q.correctAnswer, '${spec.numerator}/3');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('unit_fraction_intro', () {
    test('numerator = 1; denom ∈ {2..8}', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'unit_fraction_intro', i);
        final spec = q.diagram! as FractionBarSpec;
        expect(spec.numerator, 1);
        expect([2, 3, 4, 5, 6, 8], contains(spec.denominator));
        expect(q.correctAnswer, '1/${spec.denominator}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('number_line_add_sub', () {
    test('answer matches hop end; both + and − appear', () {
      var sawAdd = false;
      var sawSub = false;
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'number_line_add_sub', i);
        final spec = q.diagram! as NumberLineSpec;
        expect(spec.markedPoints, hasLength(1));
        expect(spec.hops, hasLength(1));
        final hop = spec.hops.first;
        if (hop.label!.startsWith('+')) {
          sawAdd = true;
        } else {
          sawSub = true;
        }
        expect(int.parse(q.correctAnswer), hop.to);
        _expectThreeDistinctDistractors(q);
      }
      expect(sawAdd && sawSub, isTrue);
    });
  });

  group('decimal_on_number_line', () {
    test('marked point matches correctAnswer as decimal', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'decimal_on_number_line', i);
        final spec = q.diagram! as NumberLineSpec;
        expect(spec.markedPoints, hasLength(1));
        final v = spec.markedPoints.first;
        // Compare as doubles since correctAnswer is a decimal string.
        final answerD = double.parse(q.correctAnswer);
        expect((answerD - v.toDouble()).abs(), lessThan(1e-9));
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('integers_on_number_line', () {
    test('marked point matches correctAnswer as signed int', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'integers_on_number_line', i);
        final spec = q.diagram! as NumberLineSpec;
        expect(spec.markedPoints, hasLength(1));
        final v = spec.markedPoints.first.toInt();
        final raw = q.correctAnswer.replaceAll('−', '-');
        expect(int.parse(raw), v);
        expect(v, isNot(0));
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('area_rectangle_count_squares', () {
    test('answer = rows × cols of the diagram', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'area_rectangle_count_squares', i);
        final spec = q.diagram! as AreaGridSpec;
        expect(int.parse(q.correctAnswer), spec.rows * spec.cols);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('partition_into_rows_columns', () {
    test('prompt rows and cols match diagram and product', () {
      final re = RegExp(r'into (\d+) rows and (\d+) columns');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'partition_into_rows_columns', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull);
        final rows = int.parse(m!.group(1)!);
        final cols = int.parse(m.group(2)!);
        final spec = q.diagram! as AreaGridSpec;
        expect(spec.rows, rows);
        expect(spec.cols, cols);
        expect(int.parse(q.correctAnswer), rows * cols);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('inference_from_sample', () {
    test('answer = inSample × (population / sampleSize)', () {
      final re = RegExp(
        r'sample of (\d+) students.*? (\d+) reported.*? (\d+) students',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'inference_from_sample', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final sampleSize = int.parse(m!.group(1)!);
        final inSample = int.parse(m.group(2)!);
        final population = int.parse(m.group(3)!);
        expect(population % sampleSize, 0);
        final mult = population ~/ sampleSize;
        expect(int.parse(q.correctAnswer), inSample * mult);
        _expectThreeDistinctDistractors(q);
      }
    });
  });
}
