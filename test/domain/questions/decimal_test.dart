import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/decimal.dart';

void main() {
  group('Decimal construction & canonicalisation', () {
    test('strips trailing zeros from the fractional part', () {
      expect(Decimal(150, 2).toCanonical(), '1.5');
      expect(Decimal(100, 2).toCanonical(), '1');
      expect(Decimal(20, 1).toCanonical(), '2');
      expect(Decimal(125, 2).toCanonical(), '1.25');
    });

    test('post-canonicalisation: same value → same fields', () {
      final a = Decimal(150, 2);
      final b = Decimal(15, 1);
      expect(a.scaled, b.scaled);
      expect(a.scale, b.scale);
      expect(a.equalsByValue(b), isTrue);
    });

    test('zero canonicalises to (0, 0)', () {
      final z = Decimal(0, 3);
      expect(z.scaled, 0);
      expect(z.scale, 0);
      expect(z.toCanonical(), '0');
    });

    test('negative values render with leading minus', () {
      expect(Decimal(-25, 2).toCanonical(), '-0.25');
      expect(Decimal(-150, 2).toCanonical(), '-1.5');
      expect(Decimal(-7, 0).toCanonical(), '-7');
    });

    test('preserves leading zeros in the fractional part', () {
      expect(Decimal(7, 2).toCanonical(), '0.07');
      expect(Decimal(7, 3).toCanonical(), '0.007');
      expect(Decimal(105, 3).toCanonical(), '0.105');
    });
  });

  group('Decimal.tryParse', () {
    test('whole numbers', () {
      expect(Decimal.tryParse('42')!.equalsByValue(Decimal(42, 0)), isTrue);
      expect(Decimal.tryParse('-3')!.equalsByValue(Decimal(-3, 0)), isTrue);
    });

    test('standard decimals', () {
      expect(Decimal.tryParse('1.5')!.equalsByValue(Decimal(15, 1)), isTrue);
      expect(Decimal.tryParse('0.25')!.equalsByValue(Decimal(25, 2)), isTrue);
      expect(Decimal.tryParse('-2.50')!.equalsByValue(Decimal(-25, 1)), isTrue);
    });

    test('trailing zeros parse to same canonical value', () {
      expect(
        Decimal.tryParse('1.50')!.equalsByValue(Decimal.tryParse('1.5')!),
        isTrue,
      );
      expect(
        Decimal.tryParse('1.500')!.equalsByValue(Decimal.tryParse('1.5')!),
        isTrue,
      );
    });

    test('leading-decimal-point form', () {
      expect(Decimal.tryParse('.5')!.equalsByValue(Decimal(5, 1)), isTrue);
      expect(Decimal.tryParse('-.25')!.equalsByValue(Decimal(-25, 2)), isTrue);
    });

    test('unicode minus sign accepted', () {
      expect(Decimal.tryParse('−3.5')!.equalsByValue(Decimal(-35, 1)), isTrue);
    });

    test('whitespace tolerated at the ends', () {
      expect(
        Decimal.tryParse('  1.5  ')!.equalsByValue(Decimal(15, 1)),
        isTrue,
      );
    });

    test('garbage rejected', () {
      expect(Decimal.tryParse(''), isNull);
      expect(Decimal.tryParse('abc'), isNull);
      expect(Decimal.tryParse('-'), isNull);
      expect(Decimal.tryParse('.'), isNull);
      expect(Decimal.tryParse('1.2.3'), isNull);
      expect(Decimal.tryParse('1 . 5'), isNull);
    });
  });

  group('Decimal arithmetic (exact, no floating-point drift)', () {
    test('0.1 + 0.2 = 0.3 exactly', () {
      final r = Decimal(1, 1) + Decimal(2, 1);
      expect(r.toCanonical(), '0.3');
    });

    test('mixed-scale addition aligns correctly', () {
      // 1.25 + 0.4 = 1.65
      expect((Decimal(125, 2) + Decimal(4, 1)).toCanonical(), '1.65');
      // 1.5 + 0.05 = 1.55
      expect((Decimal(15, 1) + Decimal(5, 2)).toCanonical(), '1.55');
    });

    test('subtraction', () {
      expect((Decimal(3, 1) - Decimal(1, 1)).toCanonical(), '0.2');
      expect((Decimal(25, 2) - Decimal(1, 1)).toCanonical(), '0.15');
    });

    test('multiplication: scales add, trailing zeros drop', () {
      // 0.5 × 0.4 = 0.20 → canonical 0.2
      expect((Decimal(5, 1) * Decimal(4, 1)).toCanonical(), '0.2');
      // 0.3 × 0.3 = 0.09 (leading zero kept)
      expect((Decimal(3, 1) * Decimal(3, 1)).toCanonical(), '0.09');
      // 0.7 × 0.07 = 0.049
      expect((Decimal(7, 1) * Decimal(7, 2)).toCanonical(), '0.049');
    });
  });

  group('Decimal.compareTo & equalsByValue', () {
    test('compare across scales', () {
      expect(
        Decimal.tryParse('0.5')!.compareTo(Decimal.tryParse('0.45')!),
        greaterThan(0),
      );
      expect(
        Decimal.tryParse('0.45')!.compareTo(Decimal.tryParse('0.5')!),
        lessThan(0),
      );
      expect(Decimal.tryParse('1.50')!.compareTo(Decimal.tryParse('1.5')!), 0);
    });

    test('equalsByValue is reflexive and ignores trailing zeros', () {
      final a = Decimal.tryParse('1.50')!;
      final b = Decimal.tryParse('1.5')!;
      expect(a.equalsByValue(b), isTrue);
      expect(b.equalsByValue(a), isTrue);
    });

    test('negative compare', () {
      expect(
        Decimal.tryParse('-0.5')!.compareTo(Decimal.tryParse('0.1')!),
        lessThan(0),
      );
    });
  });
}
