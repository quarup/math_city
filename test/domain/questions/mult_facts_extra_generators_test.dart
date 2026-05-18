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

  group('mult_facts_N (per-row of the × table)', () {
    final cases = <String, int>{
      'mult_facts_2': 2,
      'mult_facts_3': 3,
      'mult_facts_4': 4,
      'mult_facts_5': 5,
      'mult_facts_6': 6,
      'mult_facts_7': 7,
      'mult_facts_8': 8,
      'mult_facts_9': 9,
      'mult_facts_10': 10,
    };
    final factorRe = RegExp(r'^(\d+) × (\d+) = \?$');
    for (final entry in cases.entries) {
      test('${entry.key}: one factor is ${entry.value}, b ∈ [2, 9]', () {
        var seenSwap = false;
        var seenNoSwap = false;
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, entry.key, i);
          final m = factorRe.firstMatch(q.prompt);
          expect(m, isNotNull, reason: 'prompt: ${q.prompt}');
          final lhs = int.parse(m!.group(1)!);
          final rhs = int.parse(m.group(2)!);
          // Exactly one of the factors is N.
          final isLhs = lhs == entry.value;
          final isRhs = rhs == entry.value;
          expect(
            isLhs ^ isRhs || (isLhs && isRhs),
            isTrue,
            reason: 'neither factor equals ${entry.value}: ${q.prompt}',
          );
          if (isLhs && !isRhs) seenNoSwap = true;
          if (isRhs && !isLhs) seenSwap = true;
          final other = isLhs ? rhs : lhs;
          expect(other, inInclusiveRange(2, 9));
          expect(lhs * rhs, int.parse(q.correctAnswer));
          _expectThreeDistinctDistractors(q);
        }
        // Both orientations should appear across the seed range.
        expect(seenSwap && seenNoSwap, isTrue);
      });
    }
  });

  group('mult_1digit_by_multiple_of_10', () {
    test('a × (multiple of 10), answer correct', () {
      final re = RegExp(r'^(\d+) × (\d+) = \?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'mult_1digit_by_multiple_of_10', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull);
        final a = int.parse(m!.group(1)!);
        final b = int.parse(m.group(2)!);
        expect(a, inInclusiveRange(2, 9));
        expect(b % 10, 0);
        expect(b, inInclusiveRange(20, 90));
        expect(a * b, int.parse(q.correctAnswer));
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('commutative_mult', () {
    test('"if a × b = c, then b × a = ?" → c', () {
      final re = RegExp(r'If (\d+) × (\d+) = (\d+), then (\d+) × (\d+) = \?');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'commutative_mult', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull);
        final a = int.parse(m!.group(1)!);
        final b = int.parse(m.group(2)!);
        final c = int.parse(m.group(3)!);
        final bSwap = int.parse(m.group(4)!);
        final aSwap = int.parse(m.group(5)!);
        expect(a, isNot(b)); // factors distinct
        expect(a * b, c);
        expect(bSwap, b);
        expect(aSwap, a);
        expect(int.parse(q.correctAnswer), c);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('associative_mult', () {
    test('"if (...) = p, then (...) = ?" → p, regrouped', () {
      final re = RegExp(
        r'If (.+) = (\d+), then (.+) = \?',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'associative_mult', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull);
        final lhs = m!.group(1)!;
        final p = int.parse(m.group(2)!);
        final rhs = m.group(3)!;
        // Both sides must mention factors that re-group to the same product.
        // Easy way to validate: replace × with * and eval each side.
        int eval(String expr) {
          // expr is something like '(2 × 3) × 5' or '2 × (3 × 5)'.
          final stripped = expr.replaceAll(RegExp('[() ]'), '');
          final parts = stripped.split('×').map(int.parse).toList();
          return parts.fold<int>(1, (acc, x) => acc * x);
        }

        expect(eval(lhs), p);
        expect(eval(rhs), p);
        expect(lhs, isNot(rhs)); // different grouping shape
        expect(int.parse(q.correctAnswer), p);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('div_as_unknown_factor', () {
    test('"___ × b = c" or "b × ___ = c" → c ÷ b', () {
      final reA = RegExp(r'^___ × (\d+) = (\d+)$');
      final reB = RegExp(r'^(\d+) × ___ = (\d+)$');
      var seenA = false;
      var seenB = false;
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'div_as_unknown_factor', i);
        final answer = int.parse(q.correctAnswer);
        final mA = reA.firstMatch(q.prompt);
        final mB = reB.firstMatch(q.prompt);
        expect(mA != null || mB != null, isTrue, reason: q.prompt);
        if (mA != null) {
          seenA = true;
          final known = int.parse(mA.group(1)!);
          final product = int.parse(mA.group(2)!);
          expect(answer * known, product);
        } else {
          seenB = true;
          final known = int.parse(mB!.group(1)!);
          final product = int.parse(mB.group(2)!);
          expect(known * answer, product);
        }
        _expectThreeDistinctDistractors(q);
      }
      expect(seenA && seenB, isTrue);
    });
  });

  group('arithmetic_patterns_in_tables', () {
    test('terms differ by a constant step, answer = last + step', () {
      final re = RegExp(
        r'What comes next\? (\d+), (\d+), (\d+), (\d+), \?',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'arithmetic_patterns_in_tables', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull);
        final t = [
          int.parse(m!.group(1)!),
          int.parse(m.group(2)!),
          int.parse(m.group(3)!),
          int.parse(m.group(4)!),
        ];
        final step = t[1] - t[0];
        expect(step, inInclusiveRange(2, 10));
        expect(t[2] - t[1], step);
        expect(t[3] - t[2], step);
        expect(int.parse(q.correctAnswer), t[3] + step);
        _expectThreeDistinctDistractors(q);
      }
    });
  });
}
