import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/decimal.dart';
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

void _expectDistractorsNotValueEquivalent(GeneratedQuestion q) {
  final correct = Decimal.tryParse(q.correctAnswer);
  if (correct == null) return; // string-format compare; skip
  for (final d in q.distractors) {
    final parsed = Decimal.tryParse(d);
    if (parsed == null) continue;
    expect(
      parsed.equalsByValue(correct),
      isFalse,
      reason: 'distractor "$d" is value-equivalent to "${q.correctAnswer}"',
    );
  }
}

void main() {
  late GeneratorRegistry registry;
  setUp(() => registry = GeneratorRegistry.defaultRegistry());

  group('decimal_notation_tenths', () {
    test('answer is 0.N for N ∈ [1, 9]', () {
      final re = RegExp(r'^Write (\d) tenths as a decimal\.$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'decimal_notation_tenths', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final n = int.parse(m!.group(1)!);
        expect(n, inInclusiveRange(1, 9));
        expect(q.correctAnswer, '0.$n');
        expect(q.answerFormat, AnswerFormat.decimal);
        _expectThreeDistinctDistractors(q);
        _expectDistractorsNotValueEquivalent(q);
      }
    });
  });

  group('decimal_notation_hundredths', () {
    test('answer matches N/100 canonical for N ∈ [1, 99]', () {
      final re = RegExp(r'^Write (\d+) hundredths as a decimal\.$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'decimal_notation_hundredths', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final n = int.parse(m!.group(1)!);
        expect(n, inInclusiveRange(1, 99));
        final expected = Decimal(n, 2).toCanonical();
        expect(q.correctAnswer, expected);
        expect(q.answerFormat, AnswerFormat.decimal);
        _expectThreeDistinctDistractors(q);
        _expectDistractorsNotValueEquivalent(q);
      }
    });

    test(
      'single-digit N yields a leading-zero hundredths form (e.g. 0.07)',
      () {
        // Burn through seeds until we observe the N < 10 case at least once,
        // and confirm the answer starts with "0.0".
        var sawSmall = false;
        for (var i = 0; i < 500 && !sawSmall; i++) {
          final q = _gen(registry, 'decimal_notation_hundredths', i);
          final n = int.parse(
            RegExp(r'(\d+)').firstMatch(q.prompt)!.group(1)!,
          );
          if (n < 10) {
            sawSmall = true;
            expect(q.correctAnswer, '0.0$n');
          }
        }
        expect(sawSmall, isTrue);
      },
    );
  });

  group('compare_decimals_hundredths', () {
    test('correct answer is one of the two operands and is the larger', () {
      final re = RegExp(
        r'^Which is bigger: (-?\d+(?:\.\d+)?) or (-?\d+(?:\.\d+)?)\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'compare_decimals_hundredths', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final aStr = m!.group(1)!;
        final bStr = m.group(2)!;
        final a = Decimal.tryParse(aStr)!;
        final b = Decimal.tryParse(bStr)!;
        expect(a.compareTo(b), isNot(0), reason: 'tie not allowed');
        final largerStr = a.compareTo(b) > 0 ? aStr : bStr;
        expect(q.correctAnswer, largerStr);
        _expectThreeDistinctDistractors(q);
      }
    });

    test('observed at least once: misconception-bait operand pair', () {
      // Bait pair = different scales (one tenths, one hundredths) where the
      // longer-looking string is actually smaller, e.g. "0.4 vs 0.45" or
      // "0.4 vs 0.39".
      var sawBait = false;
      final re = RegExp(
        r'^Which is bigger: (-?\d+(?:\.\d+)?) or (-?\d+(?:\.\d+)?)\?$',
      );
      for (var i = 0; i < 500 && !sawBait; i++) {
        final q = _gen(registry, 'compare_decimals_hundredths', i);
        final m = re.firstMatch(q.prompt)!;
        final aStr = m.group(1)!;
        final bStr = m.group(2)!;
        if (Decimal.tryParse(aStr)!.scale != Decimal.tryParse(bStr)!.scale) {
          sawBait = true;
        }
      }
      expect(sawBait, isTrue);
    });
  });

  group('add_decimals', () {
    test('a + b equals the correct answer (parsed)', () {
      final re = RegExp(r'^(-?\d+(?:\.\d+)?) \+ (-?\d+(?:\.\d+)?) = \?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'add_decimals', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final a = Decimal.tryParse(m!.group(1)!)!;
        final b = Decimal.tryParse(m.group(2)!)!;
        final expected = (a + b).toCanonical();
        expect(q.correctAnswer, expected);
        expect(q.answerFormat, AnswerFormat.decimal);
        _expectThreeDistinctDistractors(q);
        _expectDistractorsNotValueEquivalent(q);
      }
    });

    test('operands stay within [0.01, 9.99]', () {
      final re = RegExp(r'^(-?\d+(?:\.\d+)?) \+ (-?\d+(?:\.\d+)?) = \?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'add_decimals', i);
        final m = re.firstMatch(q.prompt)!;
        for (final s in [m.group(1)!, m.group(2)!]) {
          final d = Decimal.tryParse(s)!;
          expect(d.scale, inInclusiveRange(0, 2));
          // 0 < d <= 9.99
          final asHundredths = Decimal(
            d.scaled,
            d.scale,
          ).compareTo(Decimal(0, 0));
          expect(asHundredths, greaterThan(0));
        }
      }
    });
  });

  group('sub_decimals', () {
    test('a − b equals the correct answer; result ≥ 0', () {
      // Unicode minus inside the regex.
      final re = RegExp(
        '^'
        r'(-?\d+(?:\.\d+)?)'
        ' − '
        r'(-?\d+(?:\.\d+)?)'
        r' = \?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'sub_decimals', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final a = Decimal.tryParse(m!.group(1)!)!;
        final b = Decimal.tryParse(m.group(2)!)!;
        final diff = a - b;
        expect(
          diff.compareTo(Decimal(0, 0)),
          greaterThanOrEqualTo(0),
          reason: 'negative result in $a − $b',
        );
        expect(q.correctAnswer, diff.toCanonical());
        _expectThreeDistinctDistractors(q);
        _expectDistractorsNotValueEquivalent(q);
      }
    });
  });

  group('mult_decimal_by_whole', () {
    test('product correct; one operand is whole, the other is decimal', () {
      final re = RegExp(r'^(\S+) × (\S+) = \?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'mult_decimal_by_whole', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final a = Decimal.tryParse(m!.group(1)!)!;
        final b = Decimal.tryParse(m.group(2)!)!;
        // Exactly one should be whole (scale 0).
        expect(
          (a.scale == 0) != (b.scale == 0),
          isTrue,
          reason: 'expected exactly one whole operand: ${q.prompt}',
        );
        expect(q.correctAnswer, (a * b).toCanonical());
        _expectThreeDistinctDistractors(q);
        _expectDistractorsNotValueEquivalent(q);
      }
    });

    test('whole operand ∈ [2, 9]', () {
      final re = RegExp(r'^(\S+) × (\S+) = \?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'mult_decimal_by_whole', i);
        final m = re.firstMatch(q.prompt)!;
        final a = Decimal.tryParse(m.group(1)!)!;
        final b = Decimal.tryParse(m.group(2)!)!;
        final whole = a.scale == 0 ? a.scaled : b.scaled;
        expect(whole, inInclusiveRange(2, 9));
      }
    });
  });

  group('mult_decimals', () {
    test('product correct; both operands decimal', () {
      final re = RegExp(r'^(\S+) × (\S+) = \?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'mult_decimals', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final a = Decimal.tryParse(m!.group(1)!)!;
        final b = Decimal.tryParse(m.group(2)!)!;
        expect(a.scale, greaterThan(0), reason: q.prompt);
        expect(b.scale, greaterThan(0), reason: q.prompt);
        expect(q.correctAnswer, (a * b).toCanonical());
        _expectThreeDistinctDistractors(q);
        _expectDistractorsNotValueEquivalent(q);
      }
    });
  });
}
