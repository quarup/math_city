import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/generator_registry.dart';

const _iterations = 300;
const _minus = '−'; // U+2212

GeneratedQuestion _gen(GeneratorRegistry r, String id, [int seed = 13]) =>
    r.generate(id, random: Random(seed));

int _parseSigned(String s) {
  if (s.startsWith(_minus)) return -int.parse(s.substring(_minus.length));
  return int.parse(s);
}

void _expectThreeDistinctDistractors(GeneratedQuestion q) {
  expect(q.distractors, hasLength(3));
  expect(q.distractors.toSet(), hasLength(3));
  expect(q.distractors, isNot(contains(q.correctAnswer)));
}

/// Match a kid-textbook coordinate string `(x, y)` with optional U+2212
/// for negatives. Returns [x, y] when parsed; null otherwise.
List<int>? _parseCoord(String s) {
  final m = RegExp(r'^\((−?\d+), (−?\d+)\)$').firstMatch(s);
  if (m == null) return null;
  return [_parseSigned(m.group(1)!), _parseSigned(m.group(2)!)];
}

void main() {
  late GeneratorRegistry registry;
  setUp(() => registry = GeneratorRegistry.defaultRegistry());

  group('plot_first_quadrant', () {
    test(
      'correct label refers to the diagram point at the prompted (x, y)',
      () {
        final promptRe = RegExp(r'^Which point is at \((\d+), (\d+)\)\?$');
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'plot_first_quadrant', i);
          final m = promptRe.firstMatch(q.prompt);
          expect(m, isNotNull, reason: q.prompt);
          final x = int.parse(m!.group(1)!);
          final y = int.parse(m.group(2)!);

          expect(q.diagram, isA<CoordinatePlaneSpec>());
          final spec = q.diagram! as CoordinatePlaneSpec;
          expect(spec.minX, 0);
          expect(spec.maxX, 10);
          expect(spec.minY, 0);
          expect(spec.maxY, 10);
          expect(spec.points, hasLength(4));

          // Exactly one point should be at (x, y), and its label is the
          // correct answer.
          final atTarget = spec.points
              .where((p) => p.x == x && p.y == y)
              .toList();
          expect(atTarget, hasLength(1), reason: q.prompt);
          expect(q.correctAnswer, atTarget.single.label);

          // All four labels are A..D, distinct.
          final labels = spec.points.map((p) => p.label).whereType<String>();
          expect(labels.toSet(), {'A', 'B', 'C', 'D'});
          _expectThreeDistinctDistractors(q);
        }
      },
    );
  });

  group('read_first_quadrant', () {
    test('correctAnswer is the (x, y) of the lone labelled point', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'read_first_quadrant', i);
        expect(q.prompt, 'What are the coordinates of point A?');
        expect(q.diagram, isA<CoordinatePlaneSpec>());
        final spec = q.diagram! as CoordinatePlaneSpec;
        expect(spec.minX, 0);
        expect(spec.points, hasLength(1));
        final p = spec.points.single;
        expect(p.label, 'A');
        // Q1 sanity: target lies inside the visible range and the
        // coordinate string follows kid-textbook convention.
        expect(p.x, inInclusiveRange(0, 10));
        expect(p.y, inInclusiveRange(0, 10));
        expect(q.correctAnswer, '(${p.x}, ${p.y})');
        // Each distractor parses as a coordinate string.
        for (final d in q.distractors) {
          expect(_parseCoord(d), isNotNull, reason: 'distractor: $d');
        }
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('plot_four_quadrants', () {
    test(
      'correct label refers to the diagram point at the prompted (x, y); '
      'all four quadrants are exercised across seeds',
      () {
        final promptRe = RegExp(
          r'^Which point is at \((−?\d+), (−?\d+)\)\?$',
        );
        final quadrantsSeen = <int>{};
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'plot_four_quadrants', i);
          final m = promptRe.firstMatch(q.prompt);
          expect(m, isNotNull, reason: q.prompt);
          final x = _parseSigned(m!.group(1)!);
          final y = _parseSigned(m.group(2)!);
          expect(x, isNot(0), reason: 'no axis points: ${q.prompt}');
          expect(y, isNot(0), reason: 'no axis points: ${q.prompt}');

          expect(q.diagram, isA<CoordinatePlaneSpec>());
          final spec = q.diagram! as CoordinatePlaneSpec;
          expect(spec.minX, -5);
          expect(spec.maxX, 5);
          expect(spec.minY, -5);
          expect(spec.maxY, 5);
          expect(spec.points, hasLength(4));

          final atTarget = spec.points
              .where((p) => p.x == x && p.y == y)
              .toList();
          expect(atTarget, hasLength(1), reason: q.prompt);
          expect(q.correctAnswer, atTarget.single.label);

          quadrantsSeen.add(
            (x > 0 ? 1 : 0) | (y > 0 ? 2 : 0),
          );
          _expectThreeDistinctDistractors(q);
        }
        // Sanity: all four quadrants represented across many seeds.
        expect(quadrantsSeen, {0, 1, 2, 3});
      },
    );
  });
}
