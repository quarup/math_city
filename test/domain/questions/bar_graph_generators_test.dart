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

  group('bar_graph_read', () {
    test(
      'answer equals the value of the bar named in the prompt; '
      'scale = 1; all values land within maxY; themes & ask-indices vary',
      () {
        final themesSeen = <String>{};
        final askedSeen = <String>{};
        final promptRe = RegExp(r'^How many \w+ like ([\w ]+)\?$');
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'bar_graph_read', i);
          final m = promptRe.firstMatch(q.prompt);
          expect(m, isNotNull, reason: q.prompt);
          final askedLabel = m!.group(1)!;

          expect(q.diagram, isA<BarChartSpec>());
          final spec = q.diagram! as BarChartSpec;
          expect(spec.scale, 1);
          expect(spec.labels, hasLength(4));
          expect(spec.values, hasLength(4));
          // Values are pairwise distinct.
          expect(spec.values.toSet(), hasLength(4));
          // Every value fits inside the y-axis and is non-negative.
          for (final v in spec.values) {
            expect(v, inInclusiveRange(1, spec.maxY));
          }

          // The asked label IS one of the bar labels and its bar value
          // equals the correctAnswer.
          final askIdx = spec.labels.indexOf(askedLabel);
          expect(askIdx, isNonNegative, reason: 'unknown label "$askedLabel"');
          expect(int.parse(q.correctAnswer), spec.values[askIdx]);

          themesSeen.add(spec.title);
          askedSeen.add(askedLabel);
          _expectThreeDistinctDistractors(q);
        }
        // Sanity: at least 3 of the 5 themes show up across many seeds,
        // and asks land on more than one position.
        expect(themesSeen.length, greaterThanOrEqualTo(3));
        expect(askedSeen.length, greaterThanOrEqualTo(4));
      },
    );
  });

  group('bar_graph_compare', () {
    test(
      'answer equals the (positive) difference between the two bars named '
      'in the prompt; the gap is always ≥ 2',
      () {
        final promptRe = RegExp(
          r'^How many more \w+ like ([\w ]+) than ([\w ]+)\?$',
        );
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'bar_graph_compare', i);
          final m = promptRe.firstMatch(q.prompt);
          expect(m, isNotNull, reason: q.prompt);
          final hiLabel = m!.group(1)!;
          final loLabel = m.group(2)!;
          expect(hiLabel, isNot(loLabel));

          expect(q.diagram, isA<BarChartSpec>());
          final spec = q.diagram! as BarChartSpec;
          expect(spec.scale, 1);
          expect(spec.labels, hasLength(4));
          expect(spec.values, hasLength(4));

          final hiIdx = spec.labels.indexOf(hiLabel);
          final loIdx = spec.labels.indexOf(loLabel);
          expect(hiIdx, isNonNegative);
          expect(loIdx, isNonNegative);
          final hiV = spec.values[hiIdx];
          final loV = spec.values[loIdx];
          expect(hiV, greaterThan(loV));
          final diff = hiV - loV;
          expect(diff, greaterThanOrEqualTo(2));
          expect(int.parse(q.correctAnswer), diff);
          _expectThreeDistinctDistractors(q);
        }
      },
    );
  });

  group('scaled_bar_graph_read', () {
    test(
      'scale ∈ {2, 5, 10}; every bar value is a multiple of the scale; '
      'answer equals the bar value of the prompted category; all three '
      'scales appear across seeds',
      () {
        final promptRe = RegExp(r'^How many \w+ like ([\w ]+)\?$');
        final scalesSeen = <int>{};
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'scaled_bar_graph_read', i);
          final m = promptRe.firstMatch(q.prompt);
          expect(m, isNotNull, reason: q.prompt);
          final askedLabel = m!.group(1)!;

          expect(q.diagram, isA<BarChartSpec>());
          final spec = q.diagram! as BarChartSpec;
          expect(spec.scale, isIn(const [2, 5, 10]));
          expect(spec.labels, hasLength(4));
          expect(spec.values, hasLength(4));
          expect(spec.values.toSet(), hasLength(4));
          for (final v in spec.values) {
            expect(
              v % spec.scale,
              0,
              reason: 'value $v not divisible by scale ${spec.scale}',
            );
            expect(v, inInclusiveRange(spec.scale, spec.maxY));
          }
          // maxY itself is a multiple of scale (BarChartSpec asserts this,
          // but make it visible in the test too).
          expect(spec.maxY % spec.scale, 0);

          final askIdx = spec.labels.indexOf(askedLabel);
          expect(askIdx, isNonNegative);
          expect(int.parse(q.correctAnswer), spec.values[askIdx]);

          // Misconception distractor: the "forgot to scale" gridline count
          // should appear as a distractor candidate (the value ÷ scale).
          final gridlineOnly = '${spec.values[askIdx] ~/ spec.scale}';
          if (gridlineOnly != q.correctAnswer) {
            expect(q.distractors, contains(gridlineOnly));
          }

          scalesSeen.add(spec.scale);
          _expectThreeDistinctDistractors(q);
        }
        expect(scalesSeen, {2, 5, 10});
      },
    );
  });
}
