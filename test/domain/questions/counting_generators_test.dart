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

  group('count_to_10 / 20 / 100', () {
    test(
      'answer = n + 1 where n is the prompt number; answer in correct range',
      () {
        for (final (cid, maxValue) in const [
          ('count_to_10', 10),
          ('count_to_20', 20),
          ('count_to_100_by_1', 100),
        ]) {
          for (var i = 0; i < _iterations; i++) {
            final q = _gen(registry, cid, i);
            final m = RegExp(r'right after (\d+)\?').firstMatch(q.prompt);
            expect(m, isNotNull, reason: '$cid prompt: ${q.prompt}');
            final n = int.parse(m!.group(1)!);
            expect(int.parse(q.correctAnswer), n + 1);
            expect(n + 1, inInclusiveRange(2, maxValue));
            _expectThreeDistinctDistractors(q);
          }
        }
      },
    );
  });

  group('one_more_one_less_within_20', () {
    test(
      'answer = n ± 1 based on prompt direction; both directions appear',
      () {
        final dirsSeen = <String>{};
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'one_more_one_less_within_20', i);
          final m = RegExp(
            r'one (more|less) than (\d+)\?',
          ).firstMatch(q.prompt);
          expect(m, isNotNull);
          final dir = m!.group(1)!;
          final n = int.parse(m.group(2)!);
          final correct = int.parse(q.correctAnswer);
          expect(correct, dir == 'more' ? n + 1 : n - 1);
          dirsSeen.add(dir);
          _expectThreeDistinctDistractors(q);
        }
        expect(dirsSeen, {'more', 'less'});
      },
    );
  });

  group('compare_numerals_1_10', () {
    test(
      'answer = max iff "greater"; = min iff "smaller"; both prompts appear',
      () {
        final dirsSeen = <String>{};
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, 'compare_numerals_1_10', i);
          final m = RegExp(
            r'(greater|smaller): (\d+) or (\d+)\?',
          ).firstMatch(q.prompt);
          expect(m, isNotNull);
          final dir = m!.group(1)!;
          final a = int.parse(m.group(2)!);
          final b = int.parse(m.group(3)!);
          final expected = dir == 'greater' ? max(a, b) : min(a, b);
          expect(int.parse(q.correctAnswer), expected);
          dirsSeen.add(dir);
          _expectThreeDistinctDistractors(q);
        }
        expect(dirsSeen, {'greater', 'smaller'});
      },
    );
  });

  group('count_to_100_by_10', () {
    test('answer = last shown + 10; multiples of 10', () {
      final re = RegExp(r'10s: (\d+), (\d+), (\d+), __');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'count_to_100_by_10', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull);
        final last = int.parse(m!.group(3)!);
        expect(int.parse(q.correctAnswer), last + 10);
        expect(int.parse(q.correctAnswer) % 10, 0);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('count_to_120', () {
    test('predecessor ∈ [100, 119]; answer ∈ [101, 120]', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'count_to_120', i);
        final m = RegExp(r'right after (\d+)\?').firstMatch(q.prompt);
        expect(m, isNotNull);
        final n = int.parse(m!.group(1)!);
        expect(n, inInclusiveRange(100, 119));
        expect(int.parse(q.correctAnswer), n + 1);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('count_forward_from_n', () {
    test('answer = start + count', () {
      final re = RegExp(r'Start at (\d+) and count forward (\d+) steps');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'count_forward_from_n', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull);
        final start = int.parse(m!.group(1)!);
        final count = int.parse(m.group(2)!);
        expect(int.parse(q.correctAnswer), start + count);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('ten_more_ten_less', () {
    test('answer = n ± 10; both directions appear', () {
      final dirsSeen = <String>{};
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'ten_more_ten_less', i);
        final m = RegExp(r'ten (more|less) than (\d+)').firstMatch(q.prompt);
        expect(m, isNotNull);
        final dir = m!.group(1)!;
        final n = int.parse(m.group(2)!);
        expect(int.parse(q.correctAnswer), dir == 'more' ? n + 10 : n - 10);
        dirsSeen.add(dir);
        _expectThreeDistinctDistractors(q);
      }
      expect(dirsSeen, {'more', 'less'});
    });
  });

  group('skip_count_5 / 10 / 100', () {
    test('answer = start + 2·step; sequence step matches', () {
      for (final (cid, step) in const [
        ('skip_count_5', 5),
        ('skip_count_10', 10),
        ('skip_count_100', 100),
      ]) {
        final re = RegExp(r'(\d+)s: (\d+), (\d+), __, (\d+)');
        for (var i = 0; i < _iterations; i++) {
          final q = _gen(registry, cid, i);
          final m = re.firstMatch(q.prompt);
          expect(m, isNotNull, reason: '$cid: ${q.prompt}');
          final promptStep = int.parse(m!.group(1)!);
          expect(promptStep, step);
          final s0 = int.parse(m.group(2)!);
          final s1 = int.parse(m.group(3)!);
          final s3 = int.parse(m.group(4)!);
          expect(s1, s0 + step);
          expect(s3, s0 + 3 * step);
          expect(int.parse(q.correctAnswer), s0 + 2 * step);
          _expectThreeDistinctDistractors(q);
        }
      }
    });
  });

  group('skip_count_2', () {
    test('answer = start + 4; prompt sequence matches', () {
      final seqRe = RegExp(r'2s: (\d+), (\d+), __, (\d+)');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'skip_count_2', i);
        final m = seqRe.firstMatch(q.prompt);
        expect(m, isNotNull);
        final s0 = int.parse(m!.group(1)!);
        final s1 = int.parse(m.group(2)!);
        final s3 = int.parse(m.group(3)!);
        expect(s1, s0 + 2);
        expect(s3, s0 + 6);
        expect(int.parse(q.correctAnswer), s0 + 4);
        _expectThreeDistinctDistractors(q);
      }
    });
  });
}
