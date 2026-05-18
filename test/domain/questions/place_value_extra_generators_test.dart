import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/generator_registry.dart';
import 'package:math_city/domain/questions/generators/place_value_extra_generators.dart';

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

  group('numberToWords helper', () {
    test('common values render to expected English', () {
      expect(numberToWords(0), 'zero');
      expect(numberToWords(7), 'seven');
      expect(numberToWords(13), 'thirteen');
      expect(numberToWords(40), 'forty');
      expect(numberToWords(42), 'forty-two');
      expect(numberToWords(100), 'one hundred');
      expect(numberToWords(305), 'three hundred five');
      expect(numberToWords(423), 'four hundred twenty-three');
      expect(numberToWords(1000), 'one thousand');
      expect(numberToWords(1001), 'one thousand one');
      expect(numberToWords(12345), 'twelve thousand three hundred forty-five');
      expect(
        numberToWords(123456),
        'one hundred twenty-three thousand four hundred fifty-six',
      );
    });
  });

  group('decompose_10', () {
    test('10 = a + ___ or 10 = ___ + a, answer = 10 - a', () {
      var seenLeft = false;
      var seenRight = false;
      final reLeft = RegExp(r'^10 = ___ \+ (\d+)$');
      final reRight = RegExp(r'^10 = (\d+) \+ ___$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'decompose_10', i);
        final answer = int.parse(q.correctAnswer);
        final mL = reLeft.firstMatch(q.prompt);
        final mR = reRight.firstMatch(q.prompt);
        expect(mL != null || mR != null, isTrue, reason: q.prompt);
        if (mL != null) {
          seenLeft = true;
          expect(answer + int.parse(mL.group(1)!), 10);
        } else {
          seenRight = true;
          expect(int.parse(mR!.group(1)!) + answer, 10);
        }
        _expectThreeDistinctDistractors(q);
      }
      expect(seenLeft && seenRight, isTrue);
    });
  });

  group('associative_add', () {
    test('both groupings evaluate to the same shown sum', () {
      final re = RegExp(r'^If (.+) = (\d+), then (.+) = \?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'associative_add', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull);
        final lhs = m!.group(1)!;
        final sum = int.parse(m.group(2)!);
        final rhs = m.group(3)!;
        int eval(String expr) {
          final stripped = expr.replaceAll(RegExp('[() ]'), '');
          final parts = stripped.split('+').map(int.parse).toList();
          return parts.fold<int>(0, (acc, x) => acc + x);
        }

        expect(eval(lhs), sum);
        expect(eval(rhs), sum);
        expect(lhs, isNot(rhs));
        expect(int.parse(q.correctAnswer), sum);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('add_2digit_multiple_of_10', () {
    test('a + b where b is a multiple of 10; sum ≤ 99', () {
      final re = RegExp(r'^(\d+) \+ (\d+) = \?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'add_2digit_multiple_of_10', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull);
        final a = int.parse(m!.group(1)!);
        final b = int.parse(m.group(2)!);
        expect(a, inInclusiveRange(10, 98));
        expect(b % 10, 0);
        expect(b, inInclusiveRange(10, 80));
        expect(a + b, lessThanOrEqualTo(99));
        expect(int.parse(q.correctAnswer), a + b);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('add_up_to_4_2digit', () {
    test('3 or 4 addends, each in [10, 50], sum matches answer', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'add_up_to_4_2digit', i);
        final lhs = q.prompt.replaceAll(' = ?', '');
        final addends = lhs.split(' + ').map(int.parse).toList();
        expect(addends.length, inInclusiveRange(3, 4));
        for (final a in addends) {
          expect(a, inInclusiveRange(10, 50));
        }
        expect(addends.reduce((a, b) => a + b), int.parse(q.correctAnswer));
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('add_sub_fluency_within_20', () {
    test('mix of + and −; answers stay within 20', () {
      final reAdd = RegExp(r'^(\d+) \+ (\d+) = \?$');
      final reSub = RegExp(r'^(\d+) − (\d+) = \?$');
      var seenAdd = false;
      var seenSub = false;
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'add_sub_fluency_within_20', i);
        final mA = reAdd.firstMatch(q.prompt);
        final mS = reSub.firstMatch(q.prompt);
        expect(mA != null || mS != null, isTrue, reason: q.prompt);
        final answer = int.parse(q.correctAnswer);
        if (mA != null) {
          seenAdd = true;
          final a = int.parse(mA.group(1)!);
          final b = int.parse(mA.group(2)!);
          expect(a + b, answer);
          expect(answer, lessThanOrEqualTo(18));
        } else {
          seenSub = true;
          final a = int.parse(mS!.group(1)!);
          final b = int.parse(mS.group(2)!);
          expect(a - b, answer);
          expect(answer, greaterThanOrEqualTo(1));
          expect(a, lessThanOrEqualTo(18));
        }
        _expectThreeDistinctDistractors(q);
      }
      expect(seenAdd && seenSub, isTrue);
    });
  });

  group('read_write_3digit', () {
    test('words match correctAnswer; distractors are digit strings', () {
      final re = RegExp(r'^Which number is “(.+)”\?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'read_write_3digit', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final words = m!.group(1)!;
        final n = int.parse(q.correctAnswer);
        expect(n, inInclusiveRange(100, 999));
        expect(n % 100, isNot(0));
        expect(words, numberToWords(n));
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('compare_3digit', () {
    test('answer is the greater (or smaller) of two distinct 3-digit ints', () {
      final re = RegExp(
        r'^Which number is (greater|smaller): (\d+) or (\d+)\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'compare_3digit', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull);
        final isGreater = m!.group(1) == 'greater';
        final a = int.parse(m.group(2)!);
        final b = int.parse(m.group(3)!);
        expect(a, isNot(b));
        expect(a, inInclusiveRange(100, 999));
        expect(b, inInclusiveRange(100, 999));
        final expected = isGreater ? max(a, b) : min(a, b);
        expect(int.parse(q.correctAnswer), expected);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('read_write_multidigit', () {
    test('words match correctAnswer; n is 4-6 digits, non-thousand-mult', () {
      final re = RegExp(r'^Which number is “(.+)”\?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'read_write_multidigit', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final words = m!.group(1)!;
        final n = int.parse(q.correctAnswer);
        expect(n, inInclusiveRange(1000, 999999));
        expect(n % 1000, isNot(0));
        expect(words, numberToWords(n));
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('compare_multidigit', () {
    test('answer is the greater/smaller of two distinct 4-6 digit ints', () {
      final re = RegExp(
        r'^Which number is (greater|smaller): ([\d,]+) or ([\d,]+)\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'compare_multidigit', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull);
        final isGreater = m!.group(1) == 'greater';
        final a = int.parse(m.group(2)!.replaceAll(',', ''));
        final b = int.parse(m.group(3)!.replaceAll(',', ''));
        expect(a, isNot(b));
        expect(a, inInclusiveRange(1000, 999999));
        expect(b, inInclusiveRange(1000, 999999));
        final expected = isGreater ? max(a, b) : min(a, b);
        expect(int.parse(q.correctAnswer), expected);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('place_value_relationship_10x', () {
    test('how many <small> in n <big>; answer = 10n', () {
      final re = RegExp(r'^How many (.+) are in (\d+) (.+)\?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'place_value_relationship_10x', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull);
        final n = int.parse(m!.group(2)!);
        expect(n, inInclusiveRange(2, 9));
        expect(int.parse(q.correctAnswer), 10 * n);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('powers_of_10', () {
    test('10^exp = correct, exp ∈ [1, 6]', () {
      final re = RegExp(r'^10\^(\d+) = \?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'powers_of_10', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull);
        final exp = int.parse(m!.group(1)!);
        expect(exp, inInclusiveRange(1, 6));
        var expected = 1;
        for (var k = 0; k < exp; k++) {
          expected *= 10;
        }
        expect(int.parse(q.correctAnswer), expected);
        _expectThreeDistinctDistractors(q);
      }
    });
  });
}
