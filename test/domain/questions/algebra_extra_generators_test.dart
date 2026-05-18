import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
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

  group('missing_addend_within_20', () {
    test('answer fills the blank in ? + a = sum (or a + ? = sum)', () {
      final reL = RegExp(r'^___ \+ (\d+) = (\d+)$');
      final reR = RegExp(r'^(\d+) \+ ___ = (\d+)$');
      var sawL = false;
      var sawR = false;
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'missing_addend_within_20', i);
        final answer = int.parse(q.correctAnswer);
        final mL = reL.firstMatch(q.prompt);
        final mR = reR.firstMatch(q.prompt);
        expect(mL != null || mR != null, isTrue, reason: q.prompt);
        if (mL != null) {
          sawL = true;
          final a = int.parse(mL.group(1)!);
          final sum = int.parse(mL.group(2)!);
          expect(answer + a, sum);
        } else {
          sawR = true;
          final a = int.parse(mR!.group(1)!);
          final sum = int.parse(mR.group(2)!);
          expect(a + answer, sum);
        }
        _expectThreeDistinctDistractors(q);
      }
      expect(sawL && sawR, isTrue);
    });
  });

  group('missing_factor', () {
    test('"multiplied by k, gives p" → answer × k = p', () {
      final re = RegExp(
        r'multiplied by (\d+), gives (\d+)\?',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'missing_factor', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull);
        final k = int.parse(m!.group(1)!);
        final p = int.parse(m.group(2)!);
        final answer = int.parse(q.correctAnswer);
        expect(answer * k, p);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('numerical_pattern_rule', () {
    test('"Add N each time" matches the actual step', () {
      final reSeq = RegExp(r'pattern: (\d+), (\d+), (\d+), (\d+)\.');
      final reAnswer = RegExp(r'^Add (\d+) each time$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'numerical_pattern_rule', i);
        final mSeq = reSeq.firstMatch(q.prompt);
        expect(mSeq, isNotNull);
        final t0 = int.parse(mSeq!.group(1)!);
        final t1 = int.parse(mSeq.group(2)!);
        final step = t1 - t0;
        final mA = reAnswer.firstMatch(q.correctAnswer);
        expect(mA, isNotNull, reason: q.correctAnswer);
        expect(int.parse(mA!.group(1)!), step);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('signed_quantities_context', () {
    test('answer parses as signed int matching context polarity', () {
      var sawNeg = false;
      var sawPos = false;
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'signed_quantities_context', i);
        final raw = q.correctAnswer.replaceAll('−', '-').replaceAll('+', '');
        final answer = int.parse(raw);
        if (answer < 0) sawNeg = true;
        if (answer > 0) sawPos = true;
        expect(answer, isNot(0));
        _expectThreeDistinctDistractors(q);
      }
      expect(sawNeg && sawPos, isTrue);
    });
  });

  group('write_expression_from_words', () {
    test('valid expression chosen out of distractor pool', () {
      const validShapes = [
        'n + ',
        'n − ',
        '·n',
        'n ÷ ',
      ];
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'write_expression_from_words', i);
        // Correct answer must look like one of the expected shapes.
        expect(
          validShapes.any(q.correctAnswer.contains),
          isTrue,
          reason: q.correctAnswer,
        );
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('identify_parts_expression', () {
    test('answer matches one of {coefficient, constant, terms=2}', () {
      final reExpr = RegExp(r'(\d+)x \+ (\d+)');
      final reTerms = RegExp('^How many terms');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'identify_parts_expression', i);
        final mE = reExpr.firstMatch(q.prompt);
        expect(mE, isNotNull, reason: q.prompt);
        final a = int.parse(mE!.group(1)!);
        final b = int.parse(mE.group(2)!);
        final answer = int.parse(q.correctAnswer);
        final isTermsQ = reTerms.hasMatch(q.prompt);
        if (isTermsQ) {
          expect(answer, 2);
        } else if (q.prompt.contains('coefficient')) {
          expect(answer, a);
        } else if (q.prompt.contains('constant')) {
          expect(answer, b);
        } else {
          fail('unexpected prompt shape: ${q.prompt}');
        }
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('convert_units_within_system', () {
    test('answer = n × multiplier', () {
      final re = RegExp(r'How many (\w+) are in (\d+) (\w+)\?');
      const factor = {
        'inches': 12,
        'feet': 3,
        'minutes': 60,
        'seconds': 60,
        'ounces': 16,
        'centimeters': 100,
        'meters': 1000,
      };
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'convert_units_within_system', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final smallUnit = m!.group(1)!;
        final n = int.parse(m.group(2)!);
        expect(factor.containsKey(smallUnit), isTrue);
        expect(int.parse(q.correctAnswer), n * factor[smallUnit]!);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('volume_prism_fractional_edges', () {
    test('volume = w*h/d', () {
      final re = RegExp(
        r'length 1/(\d+) m, width (\d+) m, and height (\d+) m',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'volume_prism_fractional_edges', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull);
        final d = int.parse(m!.group(1)!);
        final w = int.parse(m.group(2)!);
        final h = int.parse(m.group(3)!);
        expect((w * h) % d, 0);
        expect(int.parse(q.correctAnswer), (w * h) ~/ d);
        _expectThreeDistinctDistractors(q);
      }
    });
  });
}
