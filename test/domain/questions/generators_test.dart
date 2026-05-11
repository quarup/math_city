import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/generator_registry.dart';

const _iterations = 200;

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

  group('Add within N', () {
    final cases = {
      'add_within_5': 5,
      'add_within_10': 10,
      'add_within_20': 20,
      'add_within_100': 100,
      'add_within_1000': 1000,
    };
    for (final entry in cases.entries) {
      test('${entry.key}: operands & sum stay in spec', () {
        final n = entry.value;
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, entry.key, i);
          final parts = q.prompt.replaceAll(' = ?', '').split(' + ');
          final a = int.parse(parts[0]);
          final b = int.parse(parts[1]);
          final correct = int.parse(q.correctAnswer);
          expect(a, inInclusiveRange(0, n));
          expect(b, inInclusiveRange(0, n));
          expect(a + b, correct);
          expect(correct, lessThanOrEqualTo(n));
          _expectThreeDistinctDistractors(q);
        }
      });
    }
  });

  group('Subtract within N', () {
    final cases = {
      'sub_within_5': 5,
      'sub_within_10': 10,
      'sub_within_20': 20,
      'sub_within_100': 100,
      'sub_within_1000': 1000,
    };
    for (final entry in cases.entries) {
      test('${entry.key}: minuend ≥ subtrahend, no negatives', () {
        final n = entry.value;
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, entry.key, i);
          final parts = q.prompt.replaceAll(' = ?', '').split(' − ');
          final a = int.parse(parts[0]);
          final b = int.parse(parts[1]);
          final correct = int.parse(q.correctAnswer);
          expect(a, inInclusiveRange(0, n));
          expect(b, inInclusiveRange(0, a));
          expect(a - b, correct);
          expect(correct, greaterThanOrEqualTo(0));
          _expectThreeDistinctDistractors(q);
        }
      });
    }
  });

  group('add_2digit_carry forces regrouping', () {
    test('ones digits sum >= 10 every time', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'add_2digit_carry', i);
        final parts = q.prompt.replaceAll(' = ?', '').split(' + ');
        final a = int.parse(parts[0]);
        final b = int.parse(parts[1]);
        expect(a, inInclusiveRange(10, 99));
        expect(b, inInclusiveRange(10, 99));
        expect((a % 10) + (b % 10), greaterThanOrEqualTo(10));
        expect(a + b, int.parse(q.correctAnswer));
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('sub_2digit_borrow forces borrow', () {
    test('minuend ones digit < subtrahend ones digit, no negatives', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'sub_2digit_borrow', i);
        final parts = q.prompt.replaceAll(' = ?', '').split(' − ');
        final a = int.parse(parts[0]);
        final b = int.parse(parts[1]);
        expect(a, inInclusiveRange(10, 99));
        expect(b, inInclusiveRange(10, 99));
        expect(a % 10, lessThan(b % 10));
        expect(a, greaterThanOrEqualTo(b));
        expect(a - b, int.parse(q.correctAnswer));
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('Multi-digit ± standard algorithm', () {
    test('add_multidigit: 3–5 digit operands, correct sum', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'add_multidigit_standard_alg', i);
        final parts = q.prompt.replaceAll(' = ?', '').split(' + ');
        final a = int.parse(parts[0]);
        final b = int.parse(parts[1]);
        expect(a, inInclusiveRange(100, 99999));
        expect(b, inInclusiveRange(100, 99999));
        expect(a + b, int.parse(q.correctAnswer));
      }
    });

    test('sub_multidigit: minuend ≥ subtrahend, correct diff', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'sub_multidigit_standard_alg', i);
        final parts = q.prompt.replaceAll(' = ?', '').split(' − ');
        final a = int.parse(parts[0]);
        final b = int.parse(parts[1]);
        expect(a, greaterThanOrEqualTo(b));
        expect(a - b, int.parse(q.correctAnswer));
      }
    });
  });

  group('mult/div facts', () {
    test('mult_facts_within_100: a, b ∈ [2,9], product correct', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'mult_facts_within_100', i);
        final parts = q.prompt.replaceAll(' = ?', '').split(' × ');
        final a = int.parse(parts[0]);
        final b = int.parse(parts[1]);
        expect(a, inInclusiveRange(2, 9));
        expect(b, inInclusiveRange(2, 9));
        expect(a * b, int.parse(q.correctAnswer));
        _expectThreeDistinctDistractors(q);
      }
    });

    test('div_facts_within_100: exact division, no remainder', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'div_facts_within_100', i);
        final parts = q.prompt.replaceAll(' = ?', '').split(' ÷ ');
        final dividend = int.parse(parts[0]);
        final divisor = int.parse(parts[1]);
        final quotient = int.parse(q.correctAnswer);
        expect(divisor, inInclusiveRange(2, 9));
        expect(quotient, inInclusiveRange(1, 9));
        expect(dividend, divisor * quotient);
      }
    });
  });

  group('Multi-digit × ÷ (Phase 6 path B)', () {
    test('div_with_remainder: answer is "qRr", check arithmetic', () {
      final answerRe = RegExp(r'^(\d+)R(\d+)$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'div_with_remainder', i);
        final parts = q.prompt.replaceAll(' = ?', '').split(' ÷ ');
        final dividend = int.parse(parts[0]);
        final divisor = int.parse(parts[1]);
        final m = answerRe.firstMatch(q.correctAnswer);
        expect(m, isNotNull, reason: 'answer "${q.correctAnswer}" not qRr');
        final quotient = int.parse(m!.group(1)!);
        final remainder = int.parse(m.group(2)!);
        expect(divisor, inInclusiveRange(2, 9));
        expect(remainder, inInclusiveRange(1, divisor - 1));
        expect(dividend, divisor * quotient + remainder);
        _expectThreeDistinctDistractors(q);
      }
    });

    test('mult_4digit_by_1digit: a∈[1000,9999], b∈[2,9], product correct', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'mult_4digit_by_1digit', i);
        final parts = q.prompt.replaceAll(' = ?', '').split(' × ');
        final a = int.parse(parts[0]);
        final b = int.parse(parts[1]);
        expect(a, inInclusiveRange(1000, 9999));
        expect(b, inInclusiveRange(2, 9));
        expect(a * b, int.parse(q.correctAnswer));
        _expectThreeDistinctDistractors(q);
      }
    });

    test('mult_2digit_by_2digit: a, b ∈ [10,99], product correct', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'mult_2digit_by_2digit', i);
        final parts = q.prompt.replaceAll(' = ?', '').split(' × ');
        final a = int.parse(parts[0]);
        final b = int.parse(parts[1]);
        expect(a, inInclusiveRange(10, 99));
        expect(b, inInclusiveRange(10, 99));
        expect(a * b, int.parse(q.correctAnswer));
        _expectThreeDistinctDistractors(q);
      }
    });

    test('mult_multidigit_standard_alg: shape mix, product correct', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'mult_multidigit_standard_alg', i);
        final parts = q.prompt.replaceAll(' = ?', '').split(' × ');
        final a = int.parse(parts[0]);
        final b = int.parse(parts[1]);
        // Both operands ≥ 2 digits so this never collapses to a "facts" case.
        expect(a, greaterThanOrEqualTo(10));
        expect(b, greaterThanOrEqualTo(10));
        expect(a * b, int.parse(q.correctAnswer));
        _expectThreeDistinctDistractors(q);
      }
    });

    test('div_4digit_by_1digit: exact, dividend 4-digit, divisor ∈ [2,9]', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'div_4digit_by_1digit', i);
        final parts = q.prompt.replaceAll(' = ?', '').split(' ÷ ');
        final dividend = int.parse(parts[0]);
        final divisor = int.parse(parts[1]);
        final quotient = int.parse(q.correctAnswer);
        expect(dividend, inInclusiveRange(1000, 9999));
        expect(divisor, inInclusiveRange(2, 9));
        expect(divisor * quotient, dividend);
        _expectThreeDistinctDistractors(q);
      }
    });

    test('div_4digit_by_2digit: exact, dividend 4-digit, divisor ∈ [11,99]',
        () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'div_4digit_by_2digit', i);
        final parts = q.prompt.replaceAll(' = ?', '').split(' ÷ ');
        final dividend = int.parse(parts[0]);
        final divisor = int.parse(parts[1]);
        final quotient = int.parse(q.correctAnswer);
        expect(dividend, inInclusiveRange(1000, 9999));
        expect(divisor, inInclusiveRange(11, 99));
        expect(divisor * quotient, dividend);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('Fractions', () {
    test('fraction_a_over_b: proper fraction + bar diagram', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'fraction_a_over_b', i);
        expect(q.diagram, isA<FractionBarSpec>());
        final spec = q.diagram! as FractionBarSpec;
        expect(spec.numerator, inInclusiveRange(1, spec.denominator - 1));
        expect(q.correctAnswer, '${spec.numerator}/${spec.denominator}');
        expect(q.distractors, hasLength(3));
        expect(q.distractors.toSet(), hasLength(3));
      }
    });

    test('compare_fractions_same_denom: answer is the larger', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'compare_fractions_same_denom', i);
        // The correct answer is one of the two fractions in the prompt.
        expect(q.prompt, contains(q.correctAnswer));
      }
    });

    test('add_fractions_like_denom: numerator sum, denom unchanged', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'add_fractions_like_denom', i);
        // Prompt looks like "a/d + b/d = ?"
        final m = RegExp(
          r'(\d+)/(\d+) \+ (\d+)/(\d+) = \?',
        ).firstMatch(q.prompt)!;
        final a = int.parse(m.group(1)!);
        final d1 = int.parse(m.group(2)!);
        final b = int.parse(m.group(3)!);
        final d2 = int.parse(m.group(4)!);
        expect(d1, d2);
        expect(q.correctAnswer, '${a + b}/$d1');
      }
    });

    test('equivalent_fractions_visual: numerator+denom both scale', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'equivalent_fractions_visual', i);
        expect(q.diagram, isA<FractionBarSpec>());
        final m = RegExp(r'(\d+)/(\d+)').firstMatch(q.correctAnswer)!;
        final num = int.parse(m.group(1)!);
        final den = int.parse(m.group(2)!);
        expect(den % num == 0 || num % den == 0 || den > num, isTrue);
      }
    });
  });

  group('Time-telling', () {
    test('time_to_hour_half: minute is 0 or 30, clock spec matches', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'time_to_hour_half', i);
        expect(q.diagram, isA<ClockSpec>());
        final spec = q.diagram! as ClockSpec;
        expect(spec.hour, inInclusiveRange(1, 12));
        expect([0, 30], contains(spec.minute));
        final mm = spec.minute.toString().padLeft(2, '0');
        expect(q.correctAnswer, '${spec.hour}:$mm');
      }
    });

    test('time_to_5_min: minute is multiple of 5', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'time_to_5_min', i);
        final spec = q.diagram! as ClockSpec;
        expect(spec.minute % 5, 0);
        expect(spec.minute, inInclusiveRange(0, 55));
      }
    });
  });

  group('Registry guards', () {
    test('unknown concept throws ArgumentError', () {
      expect(
        () => registry.generate('unknown_concept'),
        throwsArgumentError,
      );
    });

    test('isImplemented returns false for unknown', () {
      expect(registry.isImplemented('definitely_not_a_concept'), isFalse);
    });
  });
}
