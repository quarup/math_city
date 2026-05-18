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

  group('two_way_table_construct', () {
    test(
      'diagram is a 2×2 two-way table with distinct cells; correctAnswer '
      'equals exactly one cell value',
      () {
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'two_way_table_construct', i);
          expect(q.diagram, isA<TwoWayTableSpec>());
          final spec = q.diagram! as TwoWayTableSpec;
          expect(spec.rowLabels, hasLength(2));
          expect(spec.colLabels, hasLength(2));
          expect(spec.counts, hasLength(2));
          for (final row in spec.counts) {
            expect(row, hasLength(2));
          }
          // All 4 cells distinct (so the answer points to exactly one).
          final cells = [
            spec.counts[0][0],
            spec.counts[0][1],
            spec.counts[1][0],
            spec.counts[1][1],
          ];
          expect(cells.toSet(), hasLength(4));
          final correct = int.parse(q.correctAnswer);
          expect(cells, contains(correct));
          _expectThreeDistinctDistractors(q);
        }
      },
    );
  });

  group('two_way_relative_frequency', () {
    test(
      'correctAnswer equals one cell divided by a row OR column total, in '
      'canonical fraction form; answerFormat is fraction',
      () {
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'two_way_relative_frequency', i);
          expect(q.diagram, isA<TwoWayTableSpec>());
          final spec = q.diagram! as TwoWayTableSpec;
          expect(q.answerFormat, AnswerFormat.fraction);

          final cells = spec.counts;
          final rowTotals = [
            cells[0][0] + cells[0][1],
            cells[1][0] + cells[1][1],
          ];
          final colTotals = [
            cells[0][0] + cells[1][0],
            cells[0][1] + cells[1][1],
          ];

          // Find ANY (cell, denom) such that cell/denom == correctAnswer.
          var found = false;
          for (var r = 0; r < 2 && !found; r++) {
            for (var c = 0; c < 2 && !found; c++) {
              final cell = cells[r][c];
              for (final denom in [rowTotals[r], colTotals[c]]) {
                if (Fraction(cell, denom).toCanonical() == q.correctAnswer) {
                  found = true;
                  break;
                }
              }
            }
          }
          expect(found, isTrue, reason: q.prompt);
          _expectThreeDistinctDistractors(q);
        }
      },
    );
  });
}
