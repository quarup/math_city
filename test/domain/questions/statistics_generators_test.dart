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

List<int> _parseList(String s) =>
    s.split(',').map((x) => int.parse(x.trim())).toList();

void main() {
  late GeneratorRegistry registry;
  setUp(() => registry = GeneratorRegistry.defaultRegistry());

  group('mean', () {
    test('answer = sum ÷ count; always integer', () {
      final re = RegExp(r'^Find the mean: (.+)$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'mean', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final xs = _parseList(m!.group(1)!);
        final sum = xs.reduce((a, b) => a + b);
        expect(sum % xs.length, 0, reason: 'non-integer mean in ${q.prompt}');
        expect(q.correctAnswer, '${sum ~/ xs.length}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('median', () {
    test('answer = middle element of sorted list; odd count only', () {
      final re = RegExp(r'^Find the median: (.+)$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'median', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final xs = _parseList(m!.group(1)!);
        expect(xs.length.isOdd, isTrue, reason: q.prompt);
        final sorted = [...xs]..sort();
        expect(q.correctAnswer, '${sorted[xs.length ~/ 2]}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('mode', () {
    test('answer is the unique most-frequent value', () {
      final re = RegExp(r'^Find the mode: (.+)$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'mode', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final xs = _parseList(m!.group(1)!);
        final counts = <int, int>{};
        for (final x in xs) {
          counts[x] = (counts[x] ?? 0) + 1;
        }
        final maxCount = counts.values.reduce((a, b) => a > b ? a : b);
        final modes = counts.entries.where((e) => e.value == maxCount).toList();
        expect(modes, hasLength(1), reason: 'tied mode in ${q.prompt}');
        expect(q.correctAnswer, '${modes.single.key}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('iqr', () {
    test('answer = Q3 − Q1; always 7 distinct values', () {
      final re = RegExp(r'^Find the IQR: (.+)$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'iqr', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final xs = _parseList(m!.group(1)!);
        expect(xs.length, 7);
        expect(xs.toSet(), hasLength(7), reason: 'duplicates in ${q.prompt}');
        final sorted = [...xs]..sort();
        final q1 = sorted[1];
        final q3 = sorted[5];
        expect(q.correctAnswer, '${q3 - q1}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('mad', () {
    test('answer = average of absolute deviations from the mean', () {
      final re = RegExp(r'^Find the mean absolute deviation: (.+)$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'mad', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final xs = _parseList(m!.group(1)!);
        expect(xs.length, 4);
        final sum = xs.reduce((a, b) => a + b);
        expect(sum % xs.length, 0, reason: 'non-integer mean in ${q.prompt}');
        final mean = sum ~/ xs.length;
        final sumAbsDev = xs
            .map((v) => (v - mean).abs())
            .reduce((a, b) => a + b);
        expect(
          sumAbsDev % xs.length,
          0,
          reason: 'non-integer MAD in ${q.prompt}',
        );
        expect(q.correctAnswer, '${sumAbsDev ~/ xs.length}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('range_data', () {
    test('answer = max − min', () {
      final re = RegExp(r'^Find the range: (.+)$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'range_data', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final xs = _parseList(m!.group(1)!);
        final maxV = xs.reduce((a, b) => a > b ? a : b);
        final minV = xs.reduce((a, b) => a < b ? a : b);
        expect(q.correctAnswer, '${maxV - minV}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });
}
