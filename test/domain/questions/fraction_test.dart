import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/fraction.dart';

void main() {
  group('Fraction.tryParse', () {
    test('plain "a/b"', () {
      final f = Fraction.tryParse('3/4')!;
      expect(f.numerator, 3);
      expect(f.denominator, 4);
    });

    test('improper "7/4"', () {
      final f = Fraction.tryParse('7/4')!;
      expect(f.isImproper, isTrue);
    });

    test('mixed "1 3/4" → 7/4', () {
      final f = Fraction.tryParse('1 3/4')!;
      expect(f.equalsByValue(Fraction(7, 4)), isTrue);
    });

    test('negative mixed "-1 3/4" → -7/4', () {
      final f = Fraction.tryParse('-1 3/4')!;
      expect(f.equalsByValue(Fraction(-7, 4)), isTrue);
    });

    test('bare integer "5" → 5/1', () {
      final f = Fraction.tryParse('5')!;
      expect(f.numerator, 5);
      expect(f.denominator, 1);
      expect(f.isWhole, isTrue);
    });

    test('rejects garbage', () {
      expect(Fraction.tryParse(''), isNull);
      expect(Fraction.tryParse('abc'), isNull);
      expect(Fraction.tryParse('1/'), isNull);
      expect(Fraction.tryParse('1/0'), isNull);
      expect(Fraction.tryParse('1 2'), isNull);
    });

    test('trims surrounding whitespace', () {
      expect(Fraction.tryParse('  3/4 ')!.numerator, 3);
    });
  });

  group('Fraction.equalsByValue', () {
    test('1/2 == 2/4 == 4/8', () {
      expect(Fraction(1, 2).equalsByValue(Fraction(2, 4)), isTrue);
      expect(Fraction(2, 4).equalsByValue(Fraction(4, 8)), isTrue);
    });

    test('5/4 == "1 3/4 - 1/2" ... no — 5/4 == 10/8', () {
      expect(Fraction(5, 4).equalsByValue(Fraction(10, 8)), isTrue);
    });

    test('1/2 != 1/3', () {
      expect(Fraction(1, 2).equalsByValue(Fraction(1, 3)), isFalse);
    });

    test('handles negatives', () {
      expect(Fraction(-1, 2).equalsByValue(Fraction(1, -2)), isTrue);
      expect(Fraction(-1, 2).equalsByValue(Fraction(1, 2)), isFalse);
    });

    test('0/anything are all equal', () {
      expect(Fraction(0, 3).equalsByValue(Fraction(0, 5)), isTrue);
    });
  });

  group('Fraction.reduce / toCanonical', () {
    test('6/8 → 3/4', () {
      expect(Fraction(6, 8).toCanonical(), '3/4');
    });

    test('1/2 stays 1/2', () {
      expect(Fraction(1, 2).toCanonical(), '1/2');
    });

    test('whole numbers display without /1', () {
      expect(Fraction(4, 2).toCanonical(), '2');
      expect(Fraction(5, 1).toCanonical(), '5');
      expect(Fraction(0, 5).toCanonical(), '0');
    });

    test('keeps improper improper', () {
      expect(Fraction(7, 4).toCanonical(), '7/4');
      expect(Fraction(6, 4).toCanonical(), '3/2');
    });

    test('negative reduces correctly', () {
      expect(Fraction(-6, 8).toCanonical(), '-3/4');
      expect(Fraction(6, -8).toCanonical(), '-3/4');
    });
  });

  group('Fraction.toMixed', () {
    test('proper stays proper', () {
      expect(Fraction(3, 4).toMixed(), '3/4');
    });

    test('improper renders as mixed', () {
      expect(Fraction(7, 4).toMixed(), '1 3/4');
      expect(Fraction(11, 4).toMixed(), '2 3/4');
    });

    test('exact whole renders as integer', () {
      expect(Fraction(8, 4).toMixed(), '2');
      expect(Fraction(5, 1).toMixed(), '5');
    });

    test('negative mixed', () {
      expect(Fraction(-7, 4).toMixed(), '-1 3/4');
    });

    test('reduces before extracting whole part', () {
      // 14/8 = 7/4 = 1 3/4
      expect(Fraction(14, 8).toMixed(), '1 3/4');
    });
  });

  group('Fraction arithmetic', () {
    test('addition then reduce', () {
      final s = Fraction(1, 2) + Fraction(1, 3);
      expect(s.equalsByValue(Fraction(5, 6)), isTrue);
    });

    test('subtraction', () {
      final s = Fraction(3, 4) - Fraction(1, 4);
      expect(s.equalsByValue(Fraction(1, 2)), isTrue);
    });

    test('multiplication', () {
      final s = Fraction(2, 3) * Fraction(3, 4);
      expect(s.equalsByValue(Fraction(1, 2)), isTrue);
    });

    test('division', () {
      final s = Fraction(1, 2) / Fraction(1, 4);
      expect(s.equalsByValue(Fraction(2, 1)), isTrue);
    });
  });

  group('lcm', () {
    test('basic', () {
      expect(lcm(4, 6), 12);
      expect(lcm(3, 5), 15);
      expect(lcm(2, 4), 4);
    });
  });
}
