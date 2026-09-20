import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/answer_check.dart';
import 'package:math_city/domain/questions/fraction.dart';
import 'package:math_city/domain/questions/generator_registry.dart';

/// "Name the fraction you can see" concepts: a bar shaded 2/4 is shaded
/// 1/2, so a kid who types the simpler name has read the picture right
/// and must be graded correct (with the result screen's equivalence
/// nudge). Regression for the keypad rejecting 1/2 for 2/4.
const _namingConcepts = [
  'partition_halves_fourths',
  'partition_thirds',
  'unit_fraction_intro',
  'fraction_on_number_line',
];

const _iterations = 200;

void main() {
  late GeneratorRegistry registry;
  setUp(() => registry = GeneratorRegistry.defaultRegistry());

  for (final id in _namingConcepts) {
    group(id, () {
      test('accepts equivalent fractions, canonically or not', () {
        for (var i = 0; i < _iterations; i++) {
          final q = registry.generate(id, random: Random(i));
          final correct = Fraction.tryParse(q.correctAnswer)!;

          expect(
            checkAnswer(q, q.correctAnswer),
            AnswerOutcome.canonical,
            reason: '$id seed $i: depicted form must grade canonical',
          );

          // Simplest name for the same amount (1/2 for a 2/4 bar).
          final reduced = correct.reduce().toCanonical();
          expect(
            checkAnswer(q, reduced),
            isNot(AnswerOutcome.wrong),
            reason: '$id seed $i: $reduced == ${q.correctAnswer}',
          );

          // Scaled-up name for the same amount (4/8 for a 2/4 bar).
          final scaled = '${correct.numerator * 2}/${correct.denominator * 2}';
          expect(
            checkAnswer(q, scaled),
            AnswerOutcome.equivalentNonCanonical,
            reason: '$id seed $i: $scaled == ${q.correctAnswer}',
          );
        }
      });

      test("no distractor shares the answer's value", () {
        for (var i = 0; i < _iterations; i++) {
          final q = registry.generate(id, random: Random(i));
          for (final d in q.distractors) {
            expect(
              checkAnswer(q, d),
              AnswerOutcome.wrong,
              reason: '$id seed $i: choice "$d" also grades correct',
            );
          }
        }
      });
    });
  }
}
