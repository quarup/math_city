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

List<int>? _parseCoord(String s) {
  final m = RegExp(r'^\((\d+), (\d+)\)$').firstMatch(s);
  if (m == null) return null;
  return [int.parse(m.group(1)!), int.parse(m.group(2)!)];
}

void main() {
  late GeneratorRegistry registry;
  setUp(() => registry = GeneratorRegistry.defaultRegistry());

  group('scatter_plot_construct', () {
    test(
      'plot has 4 of 5 table points; correctAnswer is the missing pair; '
      'all 5 table pairs appear in the prompt; coord strings parse',
      () {
        final tableRe = RegExp(r'pairs should all be plotted: (.+)\. Which');
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'scatter_plot_construct', i);
          final tm = tableRe.firstMatch(q.prompt);
          expect(tm, isNotNull, reason: q.prompt);
          final tableStr = tm!.group(1)!;
          // Parse 5 pairs from "(x, y); (x, y); ..."
          final tablePairs = tableStr.split('; ').map((s) {
            final p = _parseCoord(s);
            expect(p, isNotNull, reason: 'unparseable: $s');
            return p!;
          }).toList();
          expect(tablePairs, hasLength(5));

          expect(q.diagram, isA<ScatterPlotSpec>());
          final spec = q.diagram! as ScatterPlotSpec;
          expect(spec.points, hasLength(4));

          // Plotted points are a strict subset of table pairs.
          final tableKeys = {for (final p in tablePairs) '${p[0]},${p[1]}'};
          final plottedKeys = {
            for (final p in spec.points) '${p.x},${p.y}',
          };
          expect(plottedKeys.length, 4);
          expect(plottedKeys.every(tableKeys.contains), isTrue);

          // The single missing pair = correctAnswer.
          final missing = tableKeys.difference(plottedKeys).single;
          final missingParts = missing.split(',').map(int.parse).toList();
          expect(q.correctAnswer, '(${missingParts[0]}, ${missingParts[1]})');
          _expectThreeDistinctDistractors(q);
        }
      },
    );
  });

  group('scatter_plot_describe', () {
    test(
      'correctAnswer is one of the 4 pattern names; distractors are the '
      'other 3; the chosen pattern is visibly recognisable in the data; '
      'all 4 patterns appear across seeds',
      () {
        const patterns = {
          'Positive association',
          'Negative association',
          'No association',
          'Nonlinear',
        };
        final patternsSeen = <String>{};
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'scatter_plot_describe', i);
          expect(q.prompt, 'What pattern does this scatter plot show?');
          expect(q.correctAnswer, isIn(patterns));
          expect(q.distractors.toSet(),
              patterns.difference({q.correctAnswer}));
          expect(q.diagram, isA<ScatterPlotSpec>());
          final spec = q.diagram! as ScatterPlotSpec;
          expect(spec.points, hasLength(8));

          // Loose pattern-recognition checks: count strictly-increasing
          // adjacent steps in the x-sorted point list. Real data has
          // jitter so we tolerate noise but require a clear directional
          // signal for the linear patterns.
          final pts = [...spec.points]
            ..sort((a, b) => a.x.compareTo(b.x));
          var ups = 0;
          var downs = 0;
          for (var i = 1; i < pts.length; i++) {
            if (pts[i].y > pts[i - 1].y) ups++;
            if (pts[i].y < pts[i - 1].y) downs++;
          }
          switch (q.correctAnswer) {
            case 'Positive association':
              expect(ups, greaterThan(downs),
                  reason: 'positive needs net upward trend');
            case 'Negative association':
              expect(downs, greaterThan(ups),
                  reason: 'negative needs net downward trend');
            case 'No association':
              // No strong invariant — just confirm not all-same y
              expect(pts.map((p) => p.y).toSet().length,
                  greaterThanOrEqualTo(2));
            case 'Nonlinear':
              // V-shape generator yields a minimum around x=6 — first half
              // mostly decreasing, second half mostly increasing.
              final midIdx = pts.length ~/ 2;
              final firstHalf = pts.sublist(0, midIdx);
              final secondHalf = pts.sublist(midIdx);
              // First half: end-point y should be ≤ start-point y
              // (heading toward the minimum).
              expect(firstHalf.last.y, lessThanOrEqualTo(firstHalf.first.y));
              // Second half: end ≥ start (climbing away from minimum).
              expect(
                secondHalf.last.y,
                greaterThanOrEqualTo(secondHalf.first.y),
              );
          }
          patternsSeen.add(q.correctAnswer);
        }
        expect(patternsSeen, patterns);
      },
    );
  });
}
