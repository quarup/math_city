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

  group('two_pattern_relationships', () {
    test('correct point is on the named pattern', () {
      final re = RegExp(
        r'Pattern A adds (\d+) each step; Pattern B adds (\d+) each step\. '
        r'What is the point on Pattern (\w+) at step (\d+)\?',
      );
      final reAnswer = RegExp(r'^\((\d+), (\d+)\)$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'two_pattern_relationships', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final stepA = int.parse(m!.group(1)!);
        final stepB = int.parse(m.group(2)!);
        final pattern = m.group(3)!;
        final askStep = int.parse(m.group(4)!);
        final step = pattern == 'A' ? stepA : stepB;
        final mA = reAnswer.firstMatch(q.correctAnswer);
        expect(mA, isNotNull);
        expect(int.parse(mA!.group(1)!), askStep);
        expect(int.parse(mA.group(2)!), askStep * step);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('graph_proportional_slope', () {
    test('correct slope is non-zero integer', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'graph_proportional_slope', i);
        final k = int.parse(q.correctAnswer);
        expect(k, isNot(0));
        expect(k.abs(), inInclusiveRange(2, 5));
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('qualitative_graph_features', () {
    test('correct label matches one of the three classes', () {
      const opts = ['Increasing', 'Decreasing', 'Constant'];
      final seen = <String>{};
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'qualitative_graph_features', i);
        expect(opts, contains(q.correctAnswer));
        seen.add(q.correctAnswer);
        _expectThreeDistinctDistractors(q);
      }
      expect(seen.length, 3);
    });
  });

  group('interpret_slope_intercept_data', () {
    test('answer = m * askX + b', () {
      final re = RegExp(
        r'y = (\d+)x \+ (\d+)\. Predict y when x = (\d+)\.',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'interpret_slope_intercept_data', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final slope = int.parse(m!.group(1)!);
        final b = int.parse(m.group(2)!);
        final x = int.parse(m.group(3)!);
        expect(int.parse(q.correctAnswer), slope * x + b);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('simulate_compound', () {
    test('correct = happened/trials in canonical form', () {
      final re = RegExp(r'flipped (\d+) times\. Both came up heads (\d+) times');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'simulate_compound', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final trials = int.parse(m!.group(1)!);
        final happened = int.parse(m.group(2)!);
        expect(q.correctAnswer, '$happened/$trials');
        _expectThreeDistinctDistractors(q);
      }
    });
  });
}
