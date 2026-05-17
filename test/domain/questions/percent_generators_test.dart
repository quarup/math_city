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

void main() {
  late GeneratorRegistry registry;
  setUp(() => registry = GeneratorRegistry.defaultRegistry());

  group('percent_intro', () {
    test('answer matches the diagram shadedCount; never trivial 0/50/100', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'percent_intro', i);
        expect(q.prompt, 'What percent is shaded?');
        final diagram = q.diagram;
        expect(diagram, isA<PercentGridSpec>());
        final shaded = (diagram! as PercentGridSpec).shadedCount;
        expect(shaded, inInclusiveRange(1, 99));
        expect(shaded, isNot(50));
        expect(q.correctAnswer, '$shaded');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('percent_of_quantity', () {
    test('answer is always a whole number; arithmetic is exact', () {
      final re = RegExp(r'^What is (\d+)% of (\d+)\?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'percent_of_quantity', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final percent = int.parse(m!.group(1)!);
        final quantity = int.parse(m.group(2)!);
        // Must produce an integer with no remainder.
        expect(
          percent * quantity % 100,
          0,
          reason: 'non-integer answer in ${q.prompt}',
        );
        final expected = percent * quantity ~/ 100;
        expect(q.correctAnswer, '$expected');
        expect(percent, inInclusiveRange(1, 99));
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('find_whole_from_part_percent', () {
    test('answer = whole; part is consistent with percent and whole', () {
      final re = RegExp(r'^(\d+) is (\d+)% of what number\?$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'find_whole_from_part_percent', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final part = int.parse(m!.group(1)!);
        final percent = int.parse(m.group(2)!);
        final whole = int.parse(q.correctAnswer);
        // part = percent% × whole.
        expect(
          percent * whole % 100,
          0,
          reason: 'non-integer part in ${q.prompt}',
        );
        expect(
          percent * whole ~/ 100,
          part,
          reason: 'part/percent/whole inconsistent in ${q.prompt}',
        );
        expect(percent, inInclusiveRange(1, 99));
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('percent_change', () {
    test('answer is the percent change; arithmetic is consistent', () {
      final re = RegExp(
        r'^A value goes from (\d+) to (\d+)\. What percent (increase|decrease)\?$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'percent_change', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final original = int.parse(m!.group(1)!);
        final updated = int.parse(m.group(2)!);
        final dir = m.group(3)!;
        final percent = int.parse(q.correctAnswer);
        final delta = (updated - original).abs();
        expect(
          original * percent % 100,
          0,
          reason: 'non-integer change: ${q.prompt}',
        );
        expect(
          original * percent ~/ 100,
          delta,
          reason: 'percent does not match magnitude in ${q.prompt}',
        );
        if (dir == 'increase') {
          expect(updated, greaterThan(original));
        } else {
          expect(updated, lessThan(original));
        }
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('simple_interest', () {
    test('I = P × R × T / 100; principal is a multiple of 100', () {
      final re = RegExp(
        r'^\$(\d+) earns (\d+)% simple interest per year for (\d+) years?\..*\(in dollars\)$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'simple_interest', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final principal = int.parse(m!.group(1)!);
        final rate = int.parse(m.group(2)!);
        final years = int.parse(m.group(3)!);
        expect(principal % 100, 0);
        expect(rate, inInclusiveRange(2, 10));
        expect(years, inInclusiveRange(1, 5));
        expect(q.correctAnswer, '${principal * rate * years ~/ 100}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('commission', () {
    test('commission = sale × rate / 100; always an integer dollar amount', () {
      final re = RegExp(
        r'^A salesperson earns (\d+)% commission on a \$(\d+) sale\..*\(in dollars\)$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'commission', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final rate = int.parse(m!.group(1)!);
        final sale = int.parse(m.group(2)!);
        expect(
          rate * sale % 100,
          0,
          reason: 'non-integer commission in ${q.prompt}',
        );
        expect(q.correctAnswer, '${rate * sale ~/ 100}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('markup_markdown', () {
    test('new price = original ± original×rate/100; correct direction', () {
      final reUp = RegExp(
        r'^A store buys an item for \$(\d+) and marks it up (\d+)%.*\(in dollars\)$',
      );
      final reDown = RegExp(
        r'^An item costs \$(\d+)\. After a (\d+)% markdown,.*\(in dollars\)$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'markup_markdown', i);
        final mUp = reUp.firstMatch(q.prompt);
        final mDown = reDown.firstMatch(q.prompt);
        expect(mUp != null || mDown != null, isTrue, reason: q.prompt);
        final isUp = mUp != null;
        final m = mUp ?? mDown!;
        final original = int.parse(m.group(1)!);
        final rate = int.parse(m.group(2)!);
        expect(
          original * rate % 100,
          0,
          reason: 'non-integer delta in ${q.prompt}',
        );
        final delta = original * rate ~/ 100;
        final expected = isUp ? original + delta : original - delta;
        expect(q.correctAnswer, '$expected');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('sales_tax_tip', () {
    test('extra = bill × rate / 100; always an integer dollar amount', () {
      final reTip = RegExp(
        r'^A meal cost \$(\d+)\. With a (\d+)% tip,.*\(in dollars\)$',
      );
      final reTax = RegExp(
        r'^A purchase costs \$(\d+)\. With (\d+)% sales tax,.*\(in dollars\)$',
      );
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'sales_tax_tip', i);
        final m = reTip.firstMatch(q.prompt) ?? reTax.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final bill = int.parse(m!.group(1)!);
        final rate = int.parse(m.group(2)!);
        expect(
          bill * rate % 100,
          0,
          reason: 'non-integer extra in ${q.prompt}',
        );
        expect(q.correctAnswer, '${bill * rate ~/ 100}');
        _expectThreeDistinctDistractors(q);
      }
    });
  });
}
