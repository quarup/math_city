import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/generator_registry.dart';
import 'package:math_city/domain/questions/generators/place_value_extra_generators.dart';

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

  group('read_numerals_0_20', () {
    test('words match correctAnswer; range 0..20', () {
      final re = RegExp(r'^Which number is “(.+)”\?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'read_numerals_0_20', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final n = int.parse(q.correctAnswer);
        expect(n, inInclusiveRange(0, 20));
        expect(m!.group(1), numberToWords(n));
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('write_numerals_0_20', () {
    test('digit matches correctAnswer (word form); range 0..20', () {
      final re = RegExp(r'^How do you write the number (\d+) in words\?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'write_numerals_0_20', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull);
        final n = int.parse(m!.group(1)!);
        expect(n, inInclusiveRange(0, 20));
        expect(q.correctAnswer, numberToWords(n));
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('interpret_remainder_word', () {
    test('answer matches one of the three remainder flavors', () {
      final flavorsSeen = <String>{};
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'interpret_remainder_word', i);
        if (q.prompt.contains('FULL boxes')) flavorsSeen.add('drop');
        if (q.prompt.contains('vans are NEEDED')) flavorsSeen.add('roundUp');
        if (q.prompt.contains('LEFT OVER')) flavorsSeen.add('remainder');
        _expectThreeDistinctDistractors(q);
      }
      expect(flavorsSeen, hasLength(3));
    });
  });

  group('fraction_word_problems', () {
    test('correct answer parses as fraction; equals shown arithmetic', () {
      final reAdd = RegExp(r'eats (\d+)/(\d+) of a pizza\. Then \w+ eats (\d+)/(\d+) more');
      final reSub = RegExp(r'has (\d+)/(\d+) of a pizza\. \w+ eats (\d+)/(\d+) of the pizza');
      var sawAdd = false;
      var sawSub = false;
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'fraction_word_problems', i);
        final mA = reAdd.firstMatch(q.prompt);
        final mS = reSub.firstMatch(q.prompt);
        expect(mA != null || mS != null, isTrue, reason: q.prompt);
        late int aN;
        late int aD;
        late int bN;
        late int bD;
        late int expected;
        if (mA != null) {
          sawAdd = true;
          aN = int.parse(mA.group(1)!);
          aD = int.parse(mA.group(2)!);
          bN = int.parse(mA.group(3)!);
          bD = int.parse(mA.group(4)!);
          expected = aN + bN;
        } else {
          sawSub = true;
          aN = int.parse(mS!.group(1)!);
          aD = int.parse(mS.group(2)!);
          bN = int.parse(mS.group(3)!);
          bD = int.parse(mS.group(4)!);
          expected = aN - bN;
        }
        expect(aD, bD);
        expect(q.correctAnswer, '$expected/$aD');
        _expectThreeDistinctDistractors(q);
      }
      expect(sawAdd && sawSub, isTrue);
    });
  });

  group('multistep_ratio_word', () {
    test('answer is a positive int; distractors clean', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'multistep_ratio_word', i);
        final answer = int.parse(q.correctAnswer);
        expect(answer, greaterThan(0));
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('rationals_four_op_word', () {
    test('answer parses as int (possibly negative)', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'rationals_four_op_word', i);
        // Strip the U+2212 minus sign if present.
        final s = q.correctAnswer.replaceAll('−', '-');
        final answer = int.parse(s);
        expect(answer, isA<int>());
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('word_problem_two_step_eq', () {
    test('px + q = r recovery: answer = (r-q)/p', () {
      final re = RegExp(r'apples at \$(\d+) each, plus a \$(\d+) delivery fee. The total cost is \$(\d+)\.');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'word_problem_two_step_eq', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final p = int.parse(m!.group(1)!);
        final qVal = int.parse(m.group(2)!);
        final r = int.parse(m.group(3)!);
        expect((r - qVal) % p, 0);
        expect(int.parse(q.correctAnswer), (r - qVal) ~/ p);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('system_word_problem', () {
    test('larger/smaller recovered from sum & diff', () {
      final re = RegExp(r'add to (\d+)\. Their difference is (\d+)\. What is the (larger|smaller) number\?');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'system_word_problem', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final sum = int.parse(m!.group(1)!);
        final diff = int.parse(m.group(2)!);
        final askLarger = m.group(3) == 'larger';
        final larger = (sum + diff) ~/ 2;
        final smaller = (sum - diff) ~/ 2;
        expect((sum + diff) % 2, 0);
        expect(int.parse(q.correctAnswer), askLarger ? larger : smaller);
        _expectThreeDistinctDistractors(q);
      }
    });
  });
}
