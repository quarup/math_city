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

  group('histogram', () {
    test(
      'answer equals the count of the bin named in the prompt; counts are '
      'distinct so distractors (other bin counts) are unambiguous; bin '
      'boundaries match binStart/binWidth',
      () {
        final promptRe = RegExp(r'(\d+) and (\d+)\?$');
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'histogram', i);
          final m = promptRe.firstMatch(q.prompt);
          expect(m, isNotNull, reason: q.prompt);
          final lo = int.parse(m!.group(1)!);
          final hi = int.parse(m.group(2)!);

          expect(q.diagram, isA<HistogramSpec>());
          final spec = q.diagram! as HistogramSpec;
          expect(hi - lo, spec.binWidth);
          expect((lo - spec.binStart) % spec.binWidth, 0);
          final binIdx = (lo - spec.binStart) ~/ spec.binWidth;
          expect(binIdx, inInclusiveRange(0, spec.counts.length - 1));
          expect(int.parse(q.correctAnswer), spec.counts[binIdx]);

          // Counts are pairwise distinct (so wrong-bar distractors don't
          // collide with the correct answer).
          expect(spec.counts.toSet(), hasLength(spec.counts.length));
          // All counts fit inside maxY and y-axis grid divides evenly.
          for (final c in spec.counts) {
            expect(c, inInclusiveRange(1, spec.maxY));
          }
          expect(spec.maxY % spec.scale, 0);
          _expectThreeDistinctDistractors(q);
        }
      },
    );
  });

  group('describe_distribution', () {
    test(
      'answer is one of {Symmetric, Skewed left, Skewed right, Uniform}; '
      'distractors are the other three; the chosen shape is recognisable '
      'in the counts; all four shapes appear across seeds',
      () {
        const shapes = {'Symmetric', 'Skewed left', 'Skewed right', 'Uniform'};
        final shapesSeen = <String>{};
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'describe_distribution', i);
          expect(
            q.prompt,
            'Which best describes the shape of this distribution?',
          );
          expect(q.correctAnswer, isIn(shapes));
          expect(q.answerFormat, AnswerFormat.string);
          // Distractors are exactly the other 3 shape names.
          expect(
            q.distractors.toSet(),
            shapes.difference({q.correctAnswer}),
          );

          expect(q.diagram, isA<HistogramSpec>());
          final spec = q.diagram! as HistogramSpec;
          final c = spec.counts;
          final n = c.length;
          // Loose shape-recognition checks — exact bin sequences vary by
          // jitter, but qualitative invariants hold.
          switch (q.correctAnswer) {
            case 'Uniform':
              // All bins equal (no jitter on the uniform shape).
              expect(c.toSet(), hasLength(1));
            case 'Symmetric':
              // Peak is somewhere in the middle (not first or last bin).
              final maxIdx = _argMax(c);
              expect(maxIdx, inExclusiveRange(0, n - 1));
            case 'Skewed right':
              // First bin is the tallest; last bin is among the shortest.
              expect(c.first, c.reduce(max));
              expect(c.last, lessThanOrEqualTo(c[n ~/ 2]));
            case 'Skewed left':
              // Last bin is the tallest; first bin is among the shortest.
              expect(c.last, c.reduce(max));
              expect(c.first, lessThanOrEqualTo(c[n ~/ 2]));
          }
          shapesSeen.add(q.correctAnswer);
        }
        expect(shapesSeen, shapes);
      },
    );
  });
}

int _argMax(List<int> xs) {
  var idx = 0;
  for (var i = 1; i < xs.length; i++) {
    if (xs[i] > xs[idx]) idx = i;
  }
  return idx;
}
