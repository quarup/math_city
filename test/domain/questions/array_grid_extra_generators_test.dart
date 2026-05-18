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

  group('count_objects_to_10', () {
    test('correct ∈ [2, 10]; diagram is AreaGrid', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'count_objects_to_10', i);
        final n = int.parse(q.correctAnswer);
        expect(n, inInclusiveRange(2, 10));
        expect(q.diagram, isA<AreaGridSpec>());
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('count_objects_to_20', () {
    test('correct ∈ [11, 20]', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'count_objects_to_20', i);
        final n = int.parse(q.correctAnswer);
        expect(n, inInclusiveRange(11, 20));
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('equal_groups_intro', () {
    test('rows × cols = correctAnswer', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'equal_groups_intro', i);
        final spec = q.diagram! as AreaGridSpec;
        expect(int.parse(q.correctAnswer), spec.rows * spec.cols);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('array_repeated_addition', () {
    test('answer parses as rows copies of cols', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'array_repeated_addition', i);
        final spec = q.diagram! as AreaGridSpec;
        final parts = q.correctAnswer.split(' + ').map(int.parse).toList();
        expect(parts.length, spec.rows);
        for (final p in parts) {
          expect(p, spec.cols);
        }
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('mult_meaning_groups', () {
    test('correct = rows × cols string', () {
      final re = RegExp(r'^(\d+) × (\d+)$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'mult_meaning_groups', i);
        final spec = q.diagram! as AreaGridSpec;
        final m = re.firstMatch(q.correctAnswer);
        expect(m, isNotNull);
        expect(int.parse(m!.group(1)!), spec.rows);
        expect(int.parse(m.group(2)!), spec.cols);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('div_meaning_share', () {
    test('answer × groups = total', () {
      final re = RegExp(r'^(\d+) objects.*?(\d+) groups');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'div_meaning_share', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull);
        final total = int.parse(m!.group(1)!);
        final groups = int.parse(m.group(2)!);
        final perGroup = int.parse(q.correctAnswer);
        expect(perGroup * groups, total);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('div_meaning_grouping', () {
    test('answer × per-group = total', () {
      final re = RegExp(r'^(\d+) objects.*?groups of (\d+)');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'div_meaning_grouping', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull);
        final total = int.parse(m!.group(1)!);
        final perGroup = int.parse(m.group(2)!);
        final groups = int.parse(q.correctAnswer);
        expect(groups * perGroup, total);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('distributive_mult_over_add', () {
    test('a × c parsed from prompt; answer = a × c', () {
      final re = RegExp(r'^(\d+) × (\d+) = (\d+) × \((\d+) \+ (\d+)\)');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'distributive_mult_over_add', i);
        final m = re.firstMatch(q.prompt);
        expect(m, isNotNull, reason: q.prompt);
        final a = int.parse(m!.group(1)!);
        final c = int.parse(m.group(2)!);
        final x = int.parse(m.group(4)!);
        final y = int.parse(m.group(5)!);
        expect(x + y, c);
        expect(int.parse(q.correctAnswer), a * c);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('time_to_minute', () {
    test('clock spec matches correct hh:mm', () {
      final re = RegExp(r'^(\d+):(\d{2})$');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'time_to_minute', i);
        final spec = q.diagram! as ClockSpec;
        final m = re.firstMatch(q.correctAnswer);
        expect(m, isNotNull);
        expect(int.parse(m!.group(1)!), spec.hour);
        expect(int.parse(m.group(2)!), spec.minute);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('elapsed_time', () {
    test('answer is hh:mm string; diagram clock matches start', () {
      final re = RegExp(r'^(\d+):(\d{2})$');
      final startRe = RegExp(r'It is (\d+):(\d{2})\.');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'elapsed_time', i);
        final spec = q.diagram! as ClockSpec;
        expect(re.hasMatch(q.correctAnswer), isTrue);
        final sm = startRe.firstMatch(q.prompt);
        expect(sm, isNotNull);
        expect(int.parse(sm!.group(1)!), spec.hour);
        expect(int.parse(sm.group(2)!), spec.minute);
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('fraction_denom_10_100', () {
    test('denom = 10; numerator ∈ [1, 9]', () {
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'fraction_denom_10_100', i);
        final spec = q.diagram! as FractionBarSpec;
        expect(spec.denominator, 10);
        expect(spec.numerator, inInclusiveRange(1, 9));
        expect(q.correctAnswer, '${spec.numerator}/10');
        _expectThreeDistinctDistractors(q);
      }
    });
  });

  group('approximate_irrational', () {
    test('answer is "lo and hi" with lo² ≤ n < hi²', () {
      final re = RegExp(r'^(\d+) and (\d+)$');
      final reN = RegExp(r'√(\d+)');
      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, 'approximate_irrational', i);
        final m = re.firstMatch(q.correctAnswer);
        final mN = reN.firstMatch(q.prompt);
        expect(m, isNotNull);
        expect(mN, isNotNull);
        final lo = int.parse(m!.group(1)!);
        final hi = int.parse(m.group(2)!);
        final n = int.parse(mN!.group(1)!);
        expect(hi - lo, 1);
        expect(lo * lo, lessThan(n));
        expect(hi * hi, greaterThan(n));
        _expectThreeDistinctDistractors(q);
      }
    });
  });
}
