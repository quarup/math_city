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
            final m =
                RegExp(r'right after (\d+)\?').firstMatch(q.prompt);
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
          final m =
              RegExp(r'one (more|less) than (\d+)\?').firstMatch(q.prompt);
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
          final m = RegExp(r'(greater|smaller): (\d+) or (\d+)\?')
              .firstMatch(q.prompt);
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
