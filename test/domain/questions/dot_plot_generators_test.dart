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

  group('line_plot_whole', () {
    test(
      'answer equals the count of the asked value in the dot-plot data; '
      'the asked value is always present (answer ≥ 1); themes vary',
      () {
        final themesSeen = <String>{};
        // "How many plants are V inches tall?" — extract V.
        final promptRe = RegExp(r' (\d+) ');
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'line_plot_whole', i);
          final m = promptRe.firstMatch(q.prompt);
          expect(m, isNotNull, reason: q.prompt);
          final askedV = int.parse(m!.group(1)!);

          expect(q.diagram, isA<DotPlotSpec>());
          final spec = q.diagram! as DotPlotSpec;
          expect(spec.minX, 1);
          expect(spec.maxX, 8);
          expect(spec.values.length, inInclusiveRange(10, 15));
          for (final v in spec.values) {
            expect(v, inInclusiveRange(spec.minX, spec.maxX));
          }

          final countAtAsked = spec.values.where((v) => v == askedV).length;
          expect(int.parse(q.correctAnswer), countAtAsked);
          expect(countAtAsked, greaterThanOrEqualTo(1),
              reason: 'asked value should always be present');

          themesSeen.add(spec.title);
          _expectThreeDistinctDistractors(q);
        }
        expect(themesSeen.length, greaterThanOrEqualTo(2));
      },
    );
  });

  group('dot_plot', () {
    test(
      'answer equals the count of values ≥ asked threshold; never 0 and '
      'never the full N; the strictly-greater-than count is offered as a '
      'misconception distractor when distinct',
      () {
        final promptRe = RegExp(r'at least (\d+) ');
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'dot_plot', i);
          final m = promptRe.firstMatch(q.prompt);
          expect(m, isNotNull, reason: q.prompt);
          final askedV = int.parse(m!.group(1)!);

          expect(q.diagram, isA<DotPlotSpec>());
          final spec = q.diagram! as DotPlotSpec;
          expect(spec.minX, 1);
          expect(spec.maxX, 9);
          final n = spec.values.length;
          expect(n, inInclusiveRange(10, 15));
          for (final v in spec.values) {
            expect(v, inInclusiveRange(spec.minX, spec.maxX));
          }

          final atLeast = spec.values.where((v) => v >= askedV).length;
          expect(int.parse(q.correctAnswer), atLeast);
          // Question is non-trivial: not 0, not everyone.
          expect(atLeast, inInclusiveRange(1, n - 1));

          // The "strictly greater" misconception should appear among the
          // distractors whenever its value is distinct from `atLeast`.
          final strictly = spec.values.where((v) => v > askedV).length;
          if (strictly != atLeast) {
            expect(q.distractors, contains('$strictly'));
          }

          _expectThreeDistinctDistractors(q);
        }
      },
    );
  });
}
