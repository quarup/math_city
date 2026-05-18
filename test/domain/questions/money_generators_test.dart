import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/diagram_spec.dart';
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

MoneySpec _spec(GeneratedQuestion q) => q.diagram! as MoneySpec;

void main() {
  late GeneratorRegistry registry;
  setUp(() => registry = GeneratorRegistry.defaultRegistry());

  group('coins_id_value', () {
    test("single coin shown; answer = that coin's value in cents", () {
      const valid = {1, 5, 10, 25};
      final seenValues = <int>{};
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'coins_id_value', i);
        final spec = _spec(q);
        expect(spec.items, hasLength(1));
        expect(spec.items.single.isCoin, isTrue);
        final value = spec.items.single.cents;
        expect(valid, contains(value));
        expect(int.parse(q.correctAnswer), value);
        seenValues.add(value);
        _expectThreeDistinctDistractors(q);
      }
      // All four coin denominations should appear across seeds.
      expect(seenValues, valid);
    });
  });

  group('count_coins', () {
    test('all coins; total = sum of values, in [10, 99]', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'count_coins', i);
        final spec = _spec(q);
        for (final c in spec.items) {
          expect(c.isCoin, isTrue);
        }
        final sum = spec.items.fold(0, (acc, c) => acc + c.cents);
        expect(int.parse(q.correctAnswer), sum);
        expect(sum, inInclusiveRange(10, 99));
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('count_bills_coins', () {
    test(r'mixed; correct formatted as $N.NN', () {
      final re = RegExp(r'^\$(\d+)\.(\d{2})$|^\$(\d+)$|^(\d+)¢$');
      final hasBill = <bool>{};
      final hasCoin = <bool>{};
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'count_bills_coins', i);
        final spec = _spec(q);
        final sum = spec.items.fold(0, (acc, d) => acc + d.cents);
        // Verify the correct answer string represents the sum.
        final m = re.firstMatch(q.correctAnswer);
        expect(m, isNotNull, reason: q.correctAnswer);
        int valueCents;
        if (m!.group(1) != null) {
          valueCents = int.parse(m.group(1)!) * 100 + int.parse(m.group(2)!);
        } else if (m.group(3) != null) {
          valueCents = int.parse(m.group(3)!) * 100;
        } else {
          valueCents = int.parse(m.group(4)!);
        }
        expect(valueCents, sum);
        hasBill.add(spec.items.any((d) => !d.isCoin));
        hasCoin.add(spec.items.any((d) => d.isCoin));
        _expectThreeDistinctDistractors(q);
      }
      // Every instance has both bills and coins.
      expect(hasBill, {true});
      expect(hasCoin, {true});
    });
  });

  group('change_from_purchase', () {
    test(r'answer = pay − cost; pay ∈ {$1,$5,$10,$20}', () {
      // Cost can be a `$N.NN` (or `$N`) string OR a bare `NN¢` cents-only
      // string when the cost is under a dollar.
      final re = RegExp(
        r'You pay with \$(\d+) for an item that costs '
        r'(?:\$[\d.]+|\d+¢)\. How much change',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'change_from_purchase', i);
        final spec = _spec(q);
        expect(spec.items, hasLength(1));
        expect(spec.items.single.isCoin, isFalse);
        expect([1, 5, 10, 20], contains(spec.items.single.cents ~/ 100));
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        _expectThreeDistinctDistractors(q);
      }
    });
  });
}
