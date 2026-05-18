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

  group('line_plot_fractional', () {
    test(
      'denom ∈ {2, 4}; asked value has count ≥ 1 and matches answer; '
      'all values land in [0, maxX] internal units and are valid for '
      'the spec; both denominators appear across seeds',
      () {
        final denomsSeen = <int>{};
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'line_plot_fractional', i);
          expect(q.diagram, isA<DotPlotSpec>());
          final spec = q.diagram! as DotPlotSpec;
          expect(spec.denominator, isIn(const [2, 4]));
          denomsSeen.add(spec.denominator);
          for (final v in spec.values) {
            expect(v, inInclusiveRange(spec.minX, spec.maxX));
          }
          // The asked display string appears verbatim in the prompt.
          // Reconstruct the asked internal value from the count in the
          // correctAnswer: count = how many values in spec.values equal V,
          // where V is the asked tick. There must be exactly one V that
          // matches.
          final correctCount = int.parse(q.correctAnswer);
          expect(correctCount, greaterThanOrEqualTo(1));
          final candidates = <int>[
            for (var v = spec.minX; v <= spec.maxX; v++)
              if (spec.values.where((x) => x == v).length == correctCount)
                v,
          ];
          // At least one tick has that count (the asked one). Confirm one
          // such tick's display appears in the prompt.
          final matched = candidates.any((v) {
            final s = Fraction(v, spec.denominator).toMixed();
            return q.prompt.contains(' $s ');
          });
          expect(matched, isTrue, reason: q.prompt);
          _expectThreeDistinctDistractors(q);
        }
        expect(denomsSeen, {2, 4});
      },
    );
  });

  group('line_plot_fraction_word', () {
    test(
      'asked value is always a true fraction (not whole-inch); count ≥ 2; '
      'correctAnswer equals count × value as a mixed number; distractors '
      'are 3 distinct strings (no _distinctStringDistractors throw)',
      () {
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'line_plot_fraction_word', i);
          expect(q.diagram, isA<DotPlotSpec>());
          final spec = q.diagram! as DotPlotSpec;
          expect(q.answerFormat, AnswerFormat.mixedNumber);

          // Find the asked tick: it's the one whose mixed-number display
          // appears in the prompt and whose count in the data, when
          // multiplied by the tick's value, equals correctAnswer.
          final correctMixed = q.correctAnswer;
          var found = false;
          for (var v = spec.minX; v <= spec.maxX; v++) {
            if (v % spec.denominator == 0) continue; // skip whole-inch
            final count = spec.values.where((x) => x == v).length;
            if (count < 2) continue;
            final expected = Fraction(
              count * v,
              spec.denominator,
            ).toMixed();
            if (expected != correctMixed) continue;
            final display = Fraction(v, spec.denominator).toMixed();
            if (q.prompt.contains(display)) {
              found = true;
              break;
            }
          }
          expect(found, isTrue, reason: q.prompt);
          _expectThreeDistinctDistractors(q);
        }
      },
    );
  });

  group('line_plot_5th_grade_ops', () {
    test(
      'correctAnswer equals (max − min) of the line-plot data, formatted '
      'as a mixed number; the gap is always ≥ 1 inch (denom internal '
      'units); distractors are 3 distinct strings',
      () {
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'line_plot_5th_grade_ops', i);
          expect(q.diagram, isA<DotPlotSpec>());
          final spec = q.diagram! as DotPlotSpec;
          expect(q.answerFormat, AnswerFormat.mixedNumber);

          final maxV = spec.values.reduce((a, b) => a > b ? a : b);
          final minV = spec.values.reduce((a, b) => a < b ? a : b);
          final range = maxV - minV;
          expect(range, greaterThanOrEqualTo(spec.denominator));
          final expected = Fraction(range, spec.denominator).toMixed();
          expect(q.correctAnswer, expected);
          _expectThreeDistinctDistractors(q);
        }
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
