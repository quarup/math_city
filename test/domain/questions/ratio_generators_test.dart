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

  group('ratio_intro', () {
    test('answer is "a:b" matching the counts in the prompt', () {
      // Greedy: pull a (\d+) and b (\d+) by position.
      final re = RegExp(r'has (\d+) (.+) and (\d+) (.+)\. What is the');
      final ansRe = RegExp(r'^(\d+):(\d+)$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'ratio_intro', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final a = int.parse(m!.group(1)!);
        final b = int.parse(m.group(3)!);
        final ansMatch = ansRe.firstMatch(q.correctAnswer);
        expect(ansMatch, isNotNull, reason: q.correctAnswer);
        expect(int.parse(ansMatch!.group(1)!), a);
        expect(int.parse(ansMatch.group(2)!), b);
        expect(q.answerFormat, AnswerFormat.string);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('ratio_language', () {
    test('answer is "a/b" notation of the ratio shown as "a:b"', () {
      final promptRe = RegExp(
        r'^Which is the same as the ratio (\d+):(\d+)\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'ratio_language', i);
        final m = promptRe.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final a = int.parse(m!.group(1)!);
        final b = int.parse(m.group(2)!);
        expect(q.correctAnswer, '$a/$b');
        expect(q.answerFormat, AnswerFormat.fraction);
        expect(q.answerShape, AnswerShape.exactString);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('equivalent_ratios', () {
    test('answer × original = scaled (cross-multiplication holds)', () {
      final leftBlank = RegExp(r'^Complete: (\d+):(\d+) = \?:(\d+)$');
      final rightBlank = RegExp(r'^Complete: (\d+):(\d+) = (\d+):\?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'equivalent_ratios', i);
        final mL = leftBlank.firstMatch(q.prompt);
        final mR = rightBlank.firstMatch(q.prompt);
        expect(mL != null || mR != null, isTrue, reason: q.prompt);
        final m = (mL ?? mR)!;
        final a = int.parse(m.group(1)!);
        final b = int.parse(m.group(2)!);
        final knownScaled = int.parse(m.group(3)!);
        final answer = int.parse(q.correctAnswer);
        if (mL != null) {
          // a / b = answer / knownScaled  ⇔  a × knownScaled = b × answer
          expect(
            a * knownScaled,
            b * answer,
            reason: 'cross-mult failed: ${q.prompt}',
          );
        } else {
          // a / b = knownScaled / answer  ⇔  a × answer = b × knownScaled
          expect(
            a * answer,
            b * knownScaled,
            reason: 'cross-mult failed: ${q.prompt}',
          );
        }
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('unit_rate', () {
    test('answer = total ÷ divisor; arithmetic exact', () {
      final re = RegExp(r'^(\d+) \S+ in (\d+) \S+\. What is the unit rate');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'unit_rate', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final total = int.parse(m!.group(1)!);
        final divisor = int.parse(m.group(2)!);
        expect(total % divisor, 0);
        expect(q.correctAnswer, '${total ~/ divisor}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('constant_speed', () {
    test('distance = rate × time; correct value for each blank variant', () {
      final dist = RegExp(
        r'^A car travels at (\d+) mph for (\d+) hours\. How far',
      );
      final time = RegExp(
        r'^A car travels (\d+) miles at (\d+) mph\. How many hours',
      );
      final rate = RegExp(
        r'^A car travels (\d+) miles in (\d+) hours\. What is its speed',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'constant_speed', i);
        if (dist.hasMatch(q.prompt)) {
          final m = dist.firstMatch(q.prompt)!;
          expect(
            q.correctAnswer,
            '${int.parse(m.group(1)!) * int.parse(m.group(2)!)}',
          );
        } else if (time.hasMatch(q.prompt)) {
          final m = time.firstMatch(q.prompt)!;
          expect(
            q.correctAnswer,
            '${int.parse(m.group(1)!) ~/ int.parse(m.group(2)!)}',
          );
        } else if (rate.hasMatch(q.prompt)) {
          final m = rate.firstMatch(q.prompt)!;
          expect(
            q.correctAnswer,
            '${int.parse(m.group(1)!) ~/ int.parse(m.group(2)!)}',
          );
        } else {
          fail('unrecognised prompt shape: ${q.prompt}');
        }
        _expectThreeDistinctDistractors(q);
      }
    });
  });
}
