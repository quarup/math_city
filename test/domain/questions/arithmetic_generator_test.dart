import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_dash/domain/concepts/concept_registry.dart';
import 'package:math_dash/domain/questions/arithmetic_generator.dart';

void main() {
  group('ArithmeticGenerator', () {
    // Fixed seed so failures are reproducible.
    final gen = ArithmeticGenerator(random: Random(42));
    const iterations = 500;

    group('add_1digit', () {
      test('operands and sum are in spec range', () {
        for (var i = 0; i < iterations; i++) {
          final q = gen.generateForConcept(add1Digit.id);

          // Parse "a + b = ?" — operands are single-digit so no ambiguity.
          final parts = q.prompt.replaceAll(' = ?', '').split(' + ');
          final a = int.parse(parts[0]);
          final b = int.parse(parts[1]);
          final correct = int.parse(q.correctAnswer);

          expect(a, inInclusiveRange(0, 9));
          expect(b, inInclusiveRange(0, 9));
          expect(correct, a + b);
          expect(correct, inInclusiveRange(0, 18));
        }
      });

      test('distractors are valid', () {
        for (var i = 0; i < iterations; i++) {
          final q = gen.generateForConcept(add1Digit.id);
          final correct = int.parse(q.correctAnswer);

          expect(q.distractors, hasLength(3));
          expect(
            q.distractors.toSet(),
            hasLength(3),
            reason: 'distractors must be unique',
          );
          for (final d in q.distractors) {
            final v = int.parse(d);
            expect(v, isNot(correct), reason: 'must differ from answer');
            expect(v, greaterThanOrEqualTo(0), reason: 'must be non-negative');
          }
        }
      });
    });

    group('sub_1digit', () {
      test('operands and difference are in spec range', () {
        for (var i = 0; i < iterations; i++) {
          final q = gen.generateForConcept(sub1Digit.id);

          // Parse "a − b = ?" (U+2212 minus sign)
          final parts = q.prompt.replaceAll(' = ?', '').split(' − ');
          final a = int.parse(parts[0]);
          final b = int.parse(parts[1]);
          final correct = int.parse(q.correctAnswer);

          expect(a, greaterThanOrEqualTo(b), reason: 'no negative results');
          expect(b, inInclusiveRange(0, 9));
          expect(a, inInclusiveRange(0, 18));
          expect(correct, a - b);
          expect(correct, greaterThanOrEqualTo(0));
        }
      });

      test('distractors are valid', () {
        for (var i = 0; i < iterations; i++) {
          final q = gen.generateForConcept(sub1Digit.id);
          final correct = int.parse(q.correctAnswer);

          expect(q.distractors, hasLength(3));
          expect(
            q.distractors.toSet(),
            hasLength(3),
            reason: 'distractors must be unique',
          );
          for (final d in q.distractors) {
            final v = int.parse(d);
            expect(v, isNot(correct), reason: 'must differ from answer');
            expect(v, greaterThanOrEqualTo(0), reason: 'must be non-negative');
          }
        }
      });
    });

    test('unknown concept throws ArgumentError', () {
      expect(
        () => gen.generateForConcept('unknown_concept'),
        throwsArgumentError,
      );
    });
  });
}
