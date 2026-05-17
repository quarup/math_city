import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
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

void main() {
  late GeneratorRegistry registry;
  setUp(() => registry = GeneratorRegistry.defaultRegistry());

  group('factors_of_n', () {
    test('correct answer divides n; distractors do not', () {
      final re = RegExp(r'^Which of these is a factor of (\d+)\?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'factors_of_n', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final n = int.parse(m!.group(1)!);
        final correct = int.parse(q.correctAnswer);
        expect(n % correct, 0, reason: '$correct should divide $n');
        for (final d in q.distractors) {
          final v = int.parse(d);
          expect(n % v, isNot(0), reason: '$v should NOT divide $n');
        }
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('multiples_of_n', () {
    test('correct answer is a multiple of n; distractors are not', () {
      final re = RegExp(r'^Which of these is a multiple of (\d+)\?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'multiples_of_n', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final n = int.parse(m!.group(1)!);
        final correct = int.parse(q.correctAnswer);
        expect(correct % n, 0);
        for (final d in q.distractors) {
          final v = int.parse(d);
          expect(v % n, isNot(0), reason: '$v should NOT be a multiple of $n');
        }
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('gcf_two_numbers', () {
    test('answer is gcd(a, b)', () {
      final re = RegExp(r'^Find the GCF of (\d+) and (\d+)\.$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'gcf_two_numbers', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final a = int.parse(m!.group(1)!);
        final b = int.parse(m.group(2)!);
        final g = int.parse(q.correctAnswer);
        expect(a % g, 0);
        expect(b % g, 0);
        // Verify no larger common divisor.
        for (var d = g + 1; d <= a; d++) {
          if (a % d == 0 && b % d == 0) {
            fail('$d also divides both — gcf should be > $g');
          }
        }
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('lcm_two_numbers', () {
    test('answer is divisible by both a and b; no smaller common multiple', () {
      final re = RegExp(r'^Find the LCM of (\d+) and (\d+)\.$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'lcm_two_numbers', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final a = int.parse(m!.group(1)!);
        final b = int.parse(m.group(2)!);
        final lcm = int.parse(q.correctAnswer);
        expect(lcm % a, 0);
        expect(lcm % b, 0);
        for (var k = a; k < lcm; k++) {
          if (k % a == 0 && k % b == 0) {
            fail('$k is a smaller common multiple — lcm should be ≤ $k');
          }
        }
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('prime_or_composite', () {
    test('answer matches actual primality of n', () {
      final re = RegExp(r'^Is (\d+) prime or composite\?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'prime_or_composite', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final n = int.parse(m!.group(1)!);
        var isPrime = n > 1;
        for (var d = 2; d * d <= n; d++) {
          if (n % d == 0) {
            isPrime = false;
            break;
          }
        }
        expect(q.correctAnswer, isPrime ? 'prime' : 'composite');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('exponents_whole_number', () {
    test('answer = base^exp computed integer', () {
      final re = RegExp(r'^What is (\d+)\^(\d+)\?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'exponents_whole_number', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final base = int.parse(m!.group(1)!);
        final exp = int.parse(m.group(2)!);
        var v = 1;
        for (var k = 0; k < exp; k++) {
          v *= base;
        }
        expect(q.correctAnswer, '$v');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('order_of_operations_with_exp', () {
    test('answer evaluates with exponent-first precedence', () {
      final reAdd = RegExp(r'^(\d+) \+ (\d+)\^2 = \?$');
      final reMult = RegExp(r'^(\d+) × (\d+)\^2 = \?$');
      final reSub = RegExp(r'^(\d+) − (\d+)\^2 = \?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'order_of_operations_with_exp', i);
        int? expected;
        for (final (re, op) in [
          (reAdd, '+'),
          (reMult, '×'),
          (reSub, '−'),
        ]) {
          final m = re.firstMatch(q.prompt);
          if (m != null) {
            final a = int.parse(m.group(1)!);
            final b = int.parse(m.group(2)!);
            final sq = b * b;
            expected = switch (op) {
              '+' => a + sq,
              '×' => a * sq,
              _ => a - sq,
            };
            break;
          }
        }
        expect(expected, isNotNull, reason: q.prompt);
        expect(q.correctAnswer, '$expected');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('sqrt_perfect_squares', () {
    test('answer × answer = the number inside the √', () {
      final re = RegExp(r'^What is √(\d+)\?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'sqrt_perfect_squares', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final sq = int.parse(m!.group(1)!);
        final root = int.parse(q.correctAnswer);
        expect(root * root, sq);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('cbrt_perfect_cubes', () {
    test('answer cubed = the number inside the ∛', () {
      final re = RegExp(r'^What is ∛(\d+)\?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'cbrt_perfect_cubes', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final cube = int.parse(m!.group(1)!);
        final root = int.parse(q.correctAnswer);
        expect(root * root * root, cube);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('scientific_notation_read', () {
    test('answer = coefficient × 10^exp (integer)', () {
      final re = RegExp(
        r'^What is (\d+)\.(\d+) × 10\^(\d+) written as a whole number\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'scientific_notation_read', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final whole = int.parse(m!.group(1)!);
        final frac = int.parse(m.group(2)!);
        final exp = int.parse(m.group(3)!);
        final coeffTenths = whole * 10 + frac;
        var expected = coeffTenths;
        for (var k = 1; k < exp; k++) {
          expected *= 10;
        }
        expect(q.correctAnswer, '$expected');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('scientific_notation_write', () {
    test('answer parses back to the prompt value', () {
      final re = RegExp(r'^Write (\d+) in scientific notation\.$');
      final ansRe = RegExp(r'^(\d+)\.(\d+) × 10\^(\d+)$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'scientific_notation_write', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final value = int.parse(m!.group(1)!);
        final am = ansRe.firstMatch(q.correctAnswer);
        expect(am, isNotNull, reason: q.correctAnswer);
        final whole = int.parse(am!.group(1)!);
        final frac = int.parse(am.group(2)!);
        final exp = int.parse(am.group(3)!);
        var reconstructed = whole * 10 + frac;
        for (var k = 1; k < exp; k++) {
          reconstructed *= 10;
        }
        expect(reconstructed, value);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('integer_exponent_props', () {
    test('answer matches exponent rule for the prompt shape', () {
      final reMult = RegExp(r'^Simplify: (\d+)\^(\d+) × (\d+)\^(\d+)$');
      final reDiv = RegExp(r'^Simplify: (\d+)\^(\d+) ÷ (\d+)\^(\d+)$');
      final rePow = RegExp(r'^Simplify: \((\d+)\^(\d+)\)\^(\d+)$');
      final ansRe = RegExp(r'^(\d+)\^(\d+)$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'integer_exponent_props', i);
        final am = ansRe.firstMatch(q.correctAnswer);
        expect(am, isNotNull, reason: q.correctAnswer);
        final base = int.parse(am!.group(1)!);
        final newExp = int.parse(am.group(2)!);
        final mM = reMult.firstMatch(q.prompt);
        final mD = reDiv.firstMatch(q.prompt);
        final mP = rePow.firstMatch(q.prompt);
        if (mM != null) {
          expect(int.parse(mM.group(1)!), base);
          expect(int.parse(mM.group(3)!), base);
          final m = int.parse(mM.group(2)!);
          final n = int.parse(mM.group(4)!);
          expect(newExp, m + n);
        } else if (mD != null) {
          final m = int.parse(mD.group(2)!);
          final n = int.parse(mD.group(4)!);
          expect(newExp, m - n);
        } else if (mP != null) {
          final m = int.parse(mP.group(2)!);
          final n = int.parse(mP.group(3)!);
          expect(newExp, m * n);
        } else {
          fail('unrecognised prompt: ${q.prompt}');
        }
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('distributive_with_gcf', () {
    test('answer factors a+b as g(p+q) with gcd(p,q)=1 and g·p+g·q=a+b', () {
      final re = RegExp(r'^Factor out the GCF: (\d+) \+ (\d+)$');
      final ansRe = RegExp(r'^(\d+)\((\d+) \+ (\d+)\)$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'distributive_with_gcf', i);
        final pm = re.firstMatch(q.prompt);
        expect(pm, isNotNull, reason: q.prompt);
        final a = int.parse(pm!.group(1)!);
        final b = int.parse(pm.group(2)!);
        final am = ansRe.firstMatch(q.correctAnswer);
        expect(am, isNotNull, reason: q.correctAnswer);
        final g = int.parse(am!.group(1)!);
        final p = int.parse(am.group(2)!);
        final qInner = int.parse(am.group(3)!);
        // The answer factors must satisfy a = g·p and b = g·q.
        expect(g * p, a, reason: '$g × $p should equal $a');
        expect(g * qInner, b, reason: '$g × $qInner should equal $b');
        // gcd(p, q) must be 1 so g is truly the GREATEST common factor.
        var x = p;
        var y = qInner;
        while (y != 0) {
          final t = y;
          y = x % y;
          x = t;
        }
        expect(x, 1, reason: 'gcd($p, $qInner) should be 1');
        _expectThreeDistinctDistractors(q);
        expect(q.answerFormat, AnswerFormat.string);
      }
    });
  });

  group('absolute_value', () {
    test('answer = |v| where v is parsed from "|v|" in the prompt', () {
      final re = RegExp(r'^What is \|([−-]?\d+)\|\?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'absolute_value', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final vStr = m!.group(1)!;
        final v = vStr.startsWith('−')
            ? -int.parse(vStr.substring(1))
            : int.parse(vStr);
        expect(q.correctAnswer, '${v.abs()}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('opposites_and_zero', () {
    test('answer = −v', () {
      final re = RegExp(r'^What is the opposite of ([−-]?\d+)\?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'opposites_and_zero', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final vStr = m!.group(1)!;
        final v = vStr.startsWith('−')
            ? -int.parse(vStr.substring(1))
            : int.parse(vStr);
        final expected = -v;
        final expectedStr = expected >= 0 ? '$expected' : '−${-expected}';
        expect(q.correctAnswer, expectedStr);
      }
    });
  });
}
