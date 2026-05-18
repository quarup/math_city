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

  group('box_plot', () {
    test(
      'one summary; five-number-summary in strict order; correctAnswer '
      'matches the asked stat (median/Q1/Q3/IQR/range); all 5 kinds '
      'appear across seeds',
      () {
        final kindsSeen = <String>{};
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'box_plot', i);
          expect(q.diagram, isA<BoxPlotSpec>());
          final spec = q.diagram! as BoxPlotSpec;
          expect(spec.summaries, hasLength(1));
          final s = spec.summaries.single;
          // Strict order so every derived stat is ≥ 1.
          expect(s.min, lessThan(s.q1));
          expect(s.q1, lessThan(s.median));
          expect(s.median, lessThan(s.q3));
          expect(s.q3, lessThan(s.max));

          final correct = int.parse(q.correctAnswer);
          // Identify the asked kind from the prompt and check.
          final p = q.prompt;
          if (p.contains('median')) {
            expect(correct, s.median);
            kindsSeen.add('median');
          } else if (p.contains('Q1') || p.contains('first quartile')) {
            expect(correct, s.q1);
            kindsSeen.add('Q1');
          } else if (p.contains('Q3') || p.contains('third quartile')) {
            expect(correct, s.q3);
            kindsSeen.add('Q3');
          } else if (p.contains('IQR') || p.contains('interquartile')) {
            expect(correct, s.q3 - s.q1);
            kindsSeen.add('IQR');
          } else if (p.contains('range')) {
            expect(correct, s.max - s.min);
            kindsSeen.add('range');
          } else {
            fail('Unrecognised prompt: $p');
          }
          _expectThreeDistinctDistractors(q);
        }
        expect(
          kindsSeen,
          {'median', 'Q1', 'Q3', 'IQR', 'range'},
        );
      },
    );
  });

  group('compare_two_distributions', () {
    test(
      'two summaries labelled A/B; correctAnswer ∈ {A, B}; asked metric '
      'always differs between groups; distractors are {other label, '
      '"Both are the same", "Cannot tell from a box plot"}',
      () {
        final kindsSeen = <String>{};
        final winnersSeen = <String>{};
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'compare_two_distributions', i);
          expect(q.diagram, isA<BoxPlotSpec>());
          final spec = q.diagram! as BoxPlotSpec;
          expect(spec.summaries, hasLength(2));
          final a = spec.summaries[0];
          final b = spec.summaries[1];
          expect(a.label, 'A');
          expect(b.label, 'B');
          expect(q.answerFormat, AnswerFormat.string);
          expect(q.correctAnswer, isIn(const ['A', 'B']));

          // Identify the asked kind, compute A/B metric, confirm winner.
          final p = q.prompt;
          int aM;
          int bM;
          if (p.contains('median')) {
            aM = a.median;
            bM = b.median;
            kindsSeen.add('median');
          } else if (p.contains('IQR')) {
            aM = a.q3 - a.q1;
            bM = b.q3 - b.q1;
            kindsSeen.add('IQR');
          } else if (p.contains('range')) {
            aM = a.max - a.min;
            bM = b.max - b.min;
            kindsSeen.add('range');
          } else {
            fail('Unrecognised prompt: $p');
          }
          expect(aM, isNot(bM), reason: 'metrics must differ');
          final winner = aM > bM ? 'A' : 'B';
          expect(q.correctAnswer, winner);
          winnersSeen.add(winner);

          // Distractors are the other label + the two standard
          // confusable choices.
          final other = winner == 'A' ? 'B' : 'A';
          expect(
            q.distractors.toSet(),
            {other, 'Both are the same', 'Cannot tell from a box plot'},
          );
        }
        expect(kindsSeen, {'median', 'IQR', 'range'});
        expect(winnersSeen, {'A', 'B'});
      },
    );
  });
}
