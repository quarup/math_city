import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/generator_registry.dart';

const _iterations = 300;
const _minus = '−'; // U+2212

GeneratedQuestion _gen(GeneratorRegistry r, String id, [int seed = 13]) =>
    r.generate(id, random: Random(seed));

int _parseSigned(String s) {
  if (s.startsWith(_minus)) return -int.parse(s.substring(_minus.length));
  return int.parse(s);
}

void _expectThreeDistinctDistractors(GeneratedQuestion q) {
  expect(q.distractors, hasLength(3));
  expect(q.distractors.toSet(), hasLength(3));
  expect(q.distractors, isNot(contains(q.correctAnswer)));
}

void main() {
  late GeneratorRegistry registry;
  setUp(() => registry = GeneratorRegistry.defaultRegistry());

  group('slope_from_two_points', () {
    test('answer = Δy / Δx for prompted points', () {
      final re = RegExp(
        '^What is the slope of the line through '
        r'\((−?\d+), (−?\d+)\) and \((−?\d+), (−?\d+)\)\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'slope_from_two_points', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final x1 = _parseSigned(m!.group(1)!);
        final y1 = _parseSigned(m.group(2)!);
        final x2 = _parseSigned(m.group(3)!);
        final y2 = _parseSigned(m.group(4)!);
        expect(x2, greaterThan(x1), reason: 'x2 should exceed x1');
        final dx = x2 - x1;
        final dy = y2 - y1;
        expect(dy % dx, 0, reason: 'slope must be integer in v1: ${q.prompt}');
        final slope = dy ~/ dx;
        expect(_parseSigned(q.correctAnswer), slope);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('linear_function_construct', () {
    test('answer is "y = mx + b" form satisfying both prompted points', () {
      final promptRe = RegExp(
        '^Find the equation of the line through '
        r'\((−?\d+), (−?\d+)\) and \((−?\d+), (−?\d+)\)\.$',
      );
      // m may be "x" (m=1), "−x" (m=-1), or "${m}x" with signed integer.
      final ansRe = RegExp(
        r'^y = (−?\d*)x(?: ([+−]) (\d+))?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'linear_function_construct', i);
        final pm = promptRe.firstMatch(q.prompt);
        expect(pm, isNotNull, reason: q.prompt);
        final x1 = _parseSigned(pm!.group(1)!);
        final y1 = _parseSigned(pm.group(2)!);
        final x2 = _parseSigned(pm.group(3)!);
        final y2 = _parseSigned(pm.group(4)!);

        final am = ansRe.firstMatch(q.correctAnswer);
        expect(am, isNotNull, reason: q.correctAnswer);
        final mStr = am!.group(1)!;
        final slope = switch (mStr) {
          '' => 1,
          _minus => -1,
          final s => _parseSigned(s),
        };
        final intercept = am.group(2) == null
            ? 0
            : (am.group(2) == '+'
                  ? int.parse(am.group(3)!)
                  : -int.parse(am.group(3)!));

        expect(slope * x1 + intercept, y1, reason: q.prompt);
        expect(slope * x2 + intercept, y2, reason: q.prompt);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('function_definition_check', () {
    test('"Yes" iff no x is repeated; "No" iff some x repeats', () {
      final re = RegExp(r'^Is this a function\? \{(.+)\}$');
      final pairRe = RegExp(r'\((−?\d+), (−?\d+)\)');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'function_definition_check', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final body = m!.group(1)!;
        final pairs = pairRe.allMatches(body).map((mm) {
          return [
            _parseSigned(mm.group(1)!),
            _parseSigned(mm.group(2)!),
          ];
        }).toList();
        expect(pairs.length, anyOf(3, 4));
        final xs = pairs.map((p) => p[0]).toList();
        final xsUnique = xs.toSet().length == xs.length;
        expect(q.correctAnswer, xsUnique ? 'Yes' : 'No', reason: q.prompt);
        _expectThreeDistinctDistractors(q);
      }
    });

    test('both Yes and No appear across many seeds', () {
      // Sanity that the generator emits both classes — not a one-sided bug.
      final answers = <String>{};
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'function_definition_check', i);
        answers.add(q.correctAnswer);
      }
      expect(answers, containsAll(<String>['Yes', 'No']));
    });
  });
}
