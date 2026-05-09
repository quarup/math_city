import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/distractors.dart';

void main() {
  final rand = Random(7);

  group('integerDistractors', () {
    test('returns exactly 3 unique distractors', () {
      for (var correct = 0; correct < 100; correct++) {
        final ds = integerDistractors(correct, rand);
        expect(ds, hasLength(3));
        expect(ds.toSet(), hasLength(3));
      }
    });

    test('none equal the correct answer', () {
      for (var correct = 0; correct < 100; correct++) {
        final ds = integerDistractors(correct, rand);
        expect(ds, isNot(contains(correct.toString())));
      }
    });

    test('all distractors parse as non-negative integers', () {
      for (var correct = 0; correct < 100; correct++) {
        final ds = integerDistractors(correct, rand);
        for (final d in ds) {
          final v = int.parse(d);
          expect(v, greaterThanOrEqualTo(0));
        }
      }
    });

    test('survives small correct values (0, 1)', () {
      for (final correct in [0, 1, 2]) {
        for (var i = 0; i < 50; i++) {
          final ds = integerDistractors(correct, rand);
          expect(ds, hasLength(3));
          expect(ds.toSet(), hasLength(3));
        }
      }
    });
  });

  group('integerDistractorsWith (misconception)', () {
    test('includes the misconception when valid', () {
      const correct = 12;
      const misconception = 24;
      final ds = integerDistractorsWith(
        correct,
        Random(1),
        misconception: misconception,
      );
      expect(ds, contains(misconception.toString()));
      expect(ds, hasLength(3));
      expect(ds.toSet(), hasLength(3));
      expect(ds, isNot(contains(correct.toString())));
    });

    test(
      'falls back to base when misconception equals correct or is negative',
      () {
        final ds = integerDistractorsWith(
          5,
          Random(2),
          misconception: 5,
        );
        expect(ds, hasLength(3));
        expect(ds, isNot(contains('5')));

        final ds2 = integerDistractorsWith(
          5,
          Random(3),
          misconception: -7,
        );
        expect(ds2, hasLength(3));
      },
    );
  });

  group('stringDistractorsFromPool', () {
    test('returns 3 unique pool entries that differ from correct', () {
      final ds = stringDistractorsFromPool(
        'apple',
        ['banana', 'apple', 'cherry', 'date', 'elderberry'],
        Random(4),
      );
      expect(ds, hasLength(3));
      expect(ds.toSet(), hasLength(3));
      expect(ds, isNot(contains('apple')));
    });

    test('throws when pool is too small', () {
      expect(
        () => stringDistractorsFromPool(
          'apple',
          ['apple', 'banana', 'cherry'],
          Random(5),
        ),
        throwsStateError,
      );
    });
  });
}
