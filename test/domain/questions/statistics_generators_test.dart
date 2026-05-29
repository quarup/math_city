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

  group('mean', () {
    test('answer = sum ÷ count from DotPlot values; always integer', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'mean', i);
        final xs = (q.diagram! as DotPlotSpec).values;
        final sum = xs.reduce((a, b) => a + b);
        expect(sum % xs.length, 0, reason: 'non-integer mean in values $xs');
        expect(q.correctAnswer, '${sum ~/ xs.length}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('median', () {
    test('answer = middle element of sorted DotPlot values; odd count', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'median', i);
        final xs = (q.diagram! as DotPlotSpec).values;
        expect(xs.length.isOdd, isTrue);
        final sorted = [...xs]..sort();
        expect(q.correctAnswer, '${sorted[xs.length ~/ 2]}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('mode', () {
    test('answer is the unique most-frequent value in the DotPlot', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'mode', i);
        final xs = (q.diagram! as DotPlotSpec).values;
        final counts = <int, int>{};
        for (final x in xs) {
          counts[x] = (counts[x] ?? 0) + 1;
        }
        final maxCount = counts.values.reduce((a, b) => a > b ? a : b);
        final modes = counts.entries.where((e) => e.value == maxCount).toList();
        expect(modes, hasLength(1));
        expect(q.correctAnswer, '${modes.single.key}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('iqr', () {
    test('answer = Q3 − Q1; always 7 distinct values', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'iqr', i);
        final xs = (q.diagram! as DotPlotSpec).values;
        expect(xs.length, 7);
        expect(xs.toSet(), hasLength(7));
        final sorted = [...xs]..sort();
        final q1 = sorted[1];
        final q3 = sorted[5];
        expect(q.correctAnswer, '${q3 - q1}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('mad', () {
    test('answer = average of absolute deviations from the mean', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'mad', i);
        final xs = (q.diagram! as DotPlotSpec).values;
        expect(xs.length, 4);
        final sum = xs.reduce((a, b) => a + b);
        expect(sum % xs.length, 0);
        final mean = sum ~/ xs.length;
        final sumAbsDev = xs
            .map((v) => (v - mean).abs())
            .reduce((a, b) => a + b);
        expect(sumAbsDev % xs.length, 0);
        expect(q.correctAnswer, '${sumAbsDev ~/ xs.length}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('range_data', () {
    test('answer = max − min from the DotPlot values', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'range_data', i);
        final xs = (q.diagram! as DotPlotSpec).values;
        final maxV = xs.reduce((a, b) => a > b ? a : b);
        final minV = xs.reduce((a, b) => a < b ? a : b);
        expect(q.correctAnswer, '${maxV - minV}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });
}
