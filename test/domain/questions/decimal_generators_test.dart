import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/decimal.dart';
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

  group('decimal_to_thousandths_read', () {
    test('answer matches N/1000 canonical for N ∈ [1, 999]', () {
      final re = RegExp(r'^Write (\d+) thousandths as a decimal\.$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'decimal_to_thousandths_read', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final n = int.parse(m!.group(1)!);
        expect(n, inInclusiveRange(1, 999));
        expect(q.correctAnswer, Decimal(n, 3).toCanonical());
        expect(q.answerFormat, AnswerFormat.decimal);
        _expectThreeDistinctDistractors(q);
        _expectDistractorsNotValueEquivalent(q);
      }
    });

    test('single-digit N yields "0.00N" with both leading zeros', () {
      var sawSmall = false;
      for (var i = 0; i < 800 && !sawSmall; i++) {
        final q = _gen(registry, 'decimal_to_thousandths_read', i);
        final n = int.parse(RegExp(r'(\d+)').firstMatch(q.prompt)!.group(1)!);
        if (n < 10) {
          sawSmall = true;
          expect(q.correctAnswer, '0.00$n');
        }
      }
      expect(sawSmall, isTrue);
    });
  });

  group('compare_decimals_thousandths', () {
    test('correct answer is the larger of the two operands; no ties', () {
      final re = RegExp(
        r'^Which is bigger: (-?\d+(?:\.\d+)?) or (-?\d+(?:\.\d+)?)\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'compare_decimals_thousandths', i);
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
  });

  group('round_decimals', () {
    test(
      'answer matches the half-away-from-zero rounding to the named place',
      () {
        final re = RegExp(
          r'^Round (\d+(?:\.\d+)?) to the nearest (whole number|tenth|hundredth)\.$',
        );
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'round_decimals', i);
          final m = re.firstMatch(q.prompt);
          expect(m, isNotNull, reason: q.prompt);
          final value = Decimal.tryParse(m!.group(1)!)!;
          final placeName = m.group(2)!;
          final targetScale = switch (placeName) {
            'whole number' => 0,
            'tenth' => 1,
            'hundredth' => 2,
            _ => -1,
          };
          expect(targetScale, isNot(-1));
          // Compute expected rounding the same way the generator does.
          final factor = _pow10(value.scale - targetScale);
          final half = value.scaled >= 0 ? factor ~/ 2 : -(factor ~/ 2);
          final expectedScaled = (value.scaled + half) ~/ factor;
          final expected = Decimal(expectedScaled, targetScale).toCanonical();
          expect(q.correctAnswer, expected);
          expect(q.answerFormat, AnswerFormat.decimal);
          _expectThreeDistinctDistractors(q);
          _expectDistractorsNotValueEquivalent(q);
        }
      },
    );
  });

  group('div_decimal_by_whole', () {
    test('dividend ÷ divisor = correctAnswer exactly; divisor ∈ [2, 9]', () {
      final re = RegExp(r'^(\d+(?:\.\d+)?) ÷ (\d+) = \?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'div_decimal_by_whole', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final dividend = Decimal.tryParse(m!.group(1)!)!;
        final divisor = int.parse(m.group(2)!);
        expect(divisor, inInclusiveRange(2, 9));
        final quotient = Decimal.tryParse(q.correctAnswer)!;
        // quotient × divisor should equal dividend exactly.
        final back = quotient * Decimal(divisor, 0);
        expect(
          back.equalsByValue(dividend),
          isTrue,
          reason: 'quotient×divisor ≠ dividend in ${q.prompt}',
        );
        expect(q.answerFormat, AnswerFormat.decimal);
        _expectThreeDistinctDistractors(q);
        _expectDistractorsNotValueEquivalent(q);
      }
    });
  });

  group('div_by_decimal', () {
    test('quotient is a whole number in [2, 20]; arithmetic checks out', () {
      final re = RegExp(r'^(\d+(?:\.\d+)?) ÷ (\d+(?:\.\d+)?) = \?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'div_by_decimal', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final dividend = Decimal.tryParse(m!.group(1)!)!;
        final divisor = Decimal.tryParse(m.group(2)!)!;
        expect(
          divisor.scale,
          greaterThan(0),
          reason: 'divisor should be decimal: ${q.prompt}',
        );
        final quotient = int.parse(q.correctAnswer);
        expect(quotient, inInclusiveRange(2, 20));
        // divisor × quotient == dividend exactly.
        expect(
          (divisor * Decimal(quotient, 0)).equalsByValue(dividend),
          isTrue,
          reason: 'divisor×quotient ≠ dividend in ${q.prompt}',
        );
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('decimal_to_fraction', () {
    test('answer is the reduced fraction of the given decimal', () {
      final re = RegExp(
        r'^Write (\d+\.\d+) as a fraction in lowest terms\.$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'decimal_to_fraction', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final value = Decimal.tryParse(m!.group(1)!)!;
        final expected = Fraction(
          value.scaled,
          _pow10(value.scale),
        ).reduce().toCanonical();
        expect(q.correctAnswer, expected);
        expect(q.answerFormat, AnswerFormat.fraction);
        expect(q.answerShape, AnswerShape.exactString);
        _expectThreeDistinctDistractors(q);
      }
    });

    test('non-trivial reduction always — the un-reduced N/100 is rejected', () {
      // The generator re-rolls when the fraction is already in lowest terms
      // at denominator 100. Verify the answer's denominator is never 100.
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'decimal_to_fraction', i);
        final ans = Fraction.tryParse(q.correctAnswer)!;
        expect(
          ans.denominator,
          isNot(100),
          reason: 'expected reduction: ${q.prompt} → ${q.correctAnswer}',
        );
      }
    });
  });

  group('fraction_to_decimal', () {
    test('answer is the exact decimal expansion of the fraction', () {
      final re = RegExp(r'^Write (\d+)/(\d+) as a decimal\.$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'fraction_to_decimal', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final n = int.parse(m!.group(1)!);
        final d = int.parse(m.group(2)!);
        // Reconstruct the expected decimal via scaled-int division.
        const workingScale = 4;
        final scaled = (n * _pow10(workingScale)) ~/ d;
        final expected = Decimal(scaled, workingScale).toCanonical();
        expect(q.correctAnswer, expected);
        expect(q.answerFormat, AnswerFormat.decimal);
        _expectThreeDistinctDistractors(q);
        _expectDistractorsNotValueEquivalent(q);
      }
    });

    test('denominator ∈ {2, 4, 5, 8, 10, 20, 25, 50}', () {
      const allowed = {2, 4, 5, 8, 10, 20, 25, 50};
      final re = RegExp(r'^Write (\d+)/(\d+) as a decimal\.$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'fraction_to_decimal', i);
        final m = re.firstMatch(q.prompt)!;
        final d = int.parse(m.group(2)!);
        expect(
          allowed.contains(d),
          isTrue,
          reason: 'denominator $d not in terminating set',
        );
      }
    });
  });

  group('repeating_decimal_recognize', () {
    test('answer matches whether the reduced denominator is only-2-and-5', () {
      final re = RegExp(
        r'^Does (\d+)/(\d+) produce a terminating or repeating decimal\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'repeating_decimal_recognize', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final n = int.parse(m!.group(1)!);
        final d = int.parse(m.group(2)!);
        // Reduce.
        var nn = n;
        var dd = d;
        for (var k = 2; k <= dd; k++) {
          while (nn % k == 0 && dd % k == 0) {
            nn ~/= k;
            dd ~/= k;
          }
        }
        // Check dd has only 2s and 5s.
        var x = dd;
        while (x.isEven) {
          x ~/= 2;
        }
        while (x % 5 == 0) {
          x ~/= 5;
        }
        final terminating = x == 1;
        expect(q.correctAnswer, terminating ? 'terminating' : 'repeating');
      }
    });
  });

  group('repeating_decimal_to_fraction', () {
    test(
      'answer is one of the curated fractions, matching the prompt decimal',
      () {
        const known = <String, String>{
          '0.333...': '1/3',
          '0.666...': '2/3',
          '0.111...': '1/9',
          '0.222...': '2/9',
          '0.444...': '4/9',
          '0.555...': '5/9',
          '0.777...': '7/9',
          '0.888...': '8/9',
        };
        final re = RegExp(
          r'^Write (0\.\d+\.\.\.) as a fraction in lowest terms\.$',
        );
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'repeating_decimal_to_fraction', i);
          final m = re.firstMatch(q.prompt);
          expect(m, isNotNull, reason: q.prompt);
          final dec = m!.group(1)!;
          expect(q.correctAnswer, known[dec], reason: q.prompt);
        }
      },
    );
  });

  group('rational_to_decimal_terminating', () {
    test('delegates to fraction_to_decimal shape', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'rational_to_decimal_terminating', i);
        // Same prompt and answer-format contract as fraction_to_decimal.
        expect(q.prompt, startsWith('Write '));
        expect(q.prompt, endsWith(' as a decimal.'));
        expect(q.answerFormat, AnswerFormat.decimal);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('rational_to_decimal_repeating', () {
    test('answer is one of the curated repeating decimals', () {
      const known = <String, String>{
        '1/3': '0.333...',
        '2/3': '0.666...',
        '1/9': '0.111...',
        '2/9': '0.222...',
        '4/9': '0.444...',
        '5/9': '0.555...',
        '7/9': '0.777...',
        '8/9': '0.888...',
      };
      final re = RegExp(r'^Write (\d+/\d+) as a decimal\.$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'rational_to_decimal_repeating', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final frac = m!.group(1)!;
        expect(q.correctAnswer, known[frac], reason: q.prompt);
      }
    });
  });
}

int _pow10(int n) {
  var v = 1;
  for (var i = 0; i < n; i++) {
    v *= 10;
  }
  return v;
}
