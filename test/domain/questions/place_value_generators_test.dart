import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/generator_registry.dart';
import 'package:math_city/domain/questions/generators/place_value_generators.dart';

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

  group('formatWithCommas', () {
    test('1–3 digit numbers: no commas', () {
      expect(formatWithCommas(0), '0');
      expect(formatWithCommas(7), '7');
      expect(formatWithCommas(99), '99');
      expect(formatWithCommas(999), '999');
    });

    test('4+ digit numbers: thousands separators', () {
      expect(formatWithCommas(1000), '1,000');
      expect(formatWithCommas(12547), '12,547');
      expect(formatWithCommas(100000), '100,000');
      expect(formatWithCommas(1234567), '1,234,567');
    });
  });

  group('place_value_2digit', () {
    test('n ∈ [10, 99]; correct digit matches the named place', () {
      final re = RegExp(
        r'^What digit is in the (ones|tens) place of (\d+)\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'place_value_2digit', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final placeName = m!.group(1)!;
        final n = int.parse(m.group(2)!);
        expect(n, inInclusiveRange(10, 99));
        final expectedDigit = placeName == 'ones' ? n % 10 : (n ~/ 10) % 10;
        expect(int.parse(q.correctAnswer), expectedDigit);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('place_value_3digit', () {
    test('n ∈ [100, 999]; correct digit matches the named place', () {
      final re = RegExp(
        r'^What digit is in the (ones|tens|hundreds) place of (\d+)\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'place_value_3digit', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final placeName = m!.group(1)!;
        final n = int.parse(m.group(2)!);
        expect(n, inInclusiveRange(100, 999));
        final expected = switch (placeName) {
          'ones' => n % 10,
          'tens' => (n ~/ 10) % 10,
          'hundreds' => (n ~/ 100) % 10,
          _ => -1,
        };
        expect(int.parse(q.correctAnswer), expected);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('place_value_multidigit', () {
    test('n is 4–7 digits with commas; correct digit matches named place', () {
      // Matches any place name from ones through millions. Single-line
      // regex literal — splitting it triggered the adjacent-strings lint.
      final re = RegExp(
        r'^What digit is in the (ones|tens|hundreds|thousands|ten thousands|hundred thousands|millions) place of ([\d,]+)\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'place_value_multidigit', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final place = m!.group(1)!;
        final n = int.parse(m.group(2)!.replaceAll(',', ''));
        expect(n, inInclusiveRange(1000, 9999999));
        final placeIndex = const {
          'ones': 0,
          'tens': 1,
          'hundreds': 2,
          'thousands': 3,
          'ten thousands': 4,
          'hundred thousands': 5,
          'millions': 6,
        }[place]!;
        final expected = (n ~/ _pow10(placeIndex)) % 10;
        expect(int.parse(q.correctAnswer), expected);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('round_to_10', () {
    test('n ∈ [11, 99] not multiple of 10; correct = nearest 10', () {
      final re = RegExp(r'^Round (\d+) to the nearest 10\.$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'round_to_10', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final n = int.parse(m!.group(1)!);
        expect(n, inInclusiveRange(11, 99));
        expect(n % 10, isNot(0));
        final correct = int.parse(q.correctAnswer);
        expect(correct % 10, 0);
        // Closer to correct than to other multiples of 10.
        expect((n - correct).abs(), lessThanOrEqualTo(5));
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('round_to_100', () {
    test('n ∈ [101, 999] not multiple of 100; correct = nearest 100', () {
      final re = RegExp(r'^Round (\d+) to the nearest 100\.$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'round_to_100', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final n = int.parse(m!.group(1)!);
        expect(n, inInclusiveRange(101, 999));
        expect(n % 100, isNot(0));
        // Correct may be "1,000" (comma-formatted) when n rounds up to 1000.
        final correct = int.parse(q.correctAnswer.replaceAll(',', ''));
        expect(correct % 100, 0);
        expect((n - correct).abs(), lessThanOrEqualTo(50));
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('round_multidigit_any_place', () {
    test('n is 4–6 digits; correct is multiple of named place', () {
      // Place label can be 10, 100, 1,000, 10,000, or 100,000.
      final re = RegExp(
        r'^Round ([\d,]+) to the nearest ([\d,]+)\.$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'round_multidigit_any_place', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final n = int.parse(m!.group(1)!.replaceAll(',', ''));
        final factor = int.parse(m.group(2)!.replaceAll(',', ''));
        expect(n, inInclusiveRange(1000, 999999));
        expect([10, 100, 1000, 10000, 100000], contains(factor));
        expect(n % factor, isNot(0));
        final correct = int.parse(q.correctAnswer.replaceAll(',', ''));
        expect(correct % factor, 0);
        expect((n - correct).abs(), lessThanOrEqualTo(factor ~/ 2));
        _expectThreeDistinctDistractors(q);
      }
    });
  });
}

/// Local copy of the private power-of-10 helper for test arithmetic.
int _pow10(int p) {
  var v = 1;
  for (var i = 0; i < p; i++) {
    v *= 10;
  }
  return v;
}
