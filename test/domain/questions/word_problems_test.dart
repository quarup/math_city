import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/generator_registry.dart';
import 'package:math_city/domain/questions/word_problems/word_problem_framework.dart';

const _iterations = 300;

GeneratedQuestion _gen(GeneratorRegistry r, [int seed = 13]) =>
    r.generate('add_word_problems_within_100', random: Random(seed));

void main() {
  late GeneratorRegistry registry;
  setUp(() => registry = GeneratorRegistry.defaultRegistry());

  group('Pools', () {
    test('name pool has 25 entries, all unique, none empty', () {
      expect(wordProblemNames, hasLength(25));
      expect(wordProblemNames.toSet(), hasLength(25));
      for (final name in wordProblemNames) {
        expect(name.trim(), isNotEmpty);
        expect(name, equals(name.trim()));
      }
    });

    test('item pool has 20 entries, all unique, all plural-ish', () {
      expect(wordProblemItems, hasLength(20));
      expect(wordProblemItems.toSet(), hasLength(20));
      for (final item in wordProblemItems) {
        expect(item.trim(), isNotEmpty);
        expect(item, equals(item.trim()));
      }
    });

    test('city-builder themed items are present', () {
      for (final themed in const [
        'bricks',
        'paint cans',
        'traffic cones',
        'road signs',
      ]) {
        expect(wordProblemItems, contains(themed));
      }
    });

    test('edible item pool is a subset of the full pool', () {
      expect(edibleWordProblemItems, isNotEmpty);
      for (final e in edibleWordProblemItems) {
        expect(wordProblemItems, contains(e));
      }
    });

    test('v1 add+sub contexts: 6 entries, unique ids, action template has '
        'all three placeholders', () {
      expect(addSubContextsV1, hasLength(6));
      expect(
        addSubContextsV1.map((c) => c.id).toSet(),
        hasLength(6),
      );
      for (final c in addSubContextsV1) {
        expect(c.action, contains('{Name}'));
        expect(c.action, contains('{b}'));
        expect(c.action, contains('{items}'));
      }
    });

    test('v1 contexts: 3 add and 3 sub', () {
      final ops = addSubContextsV1.map((c) => c.op).toList();
      expect(ops.where((o) => o == WordProblemOp.add).length, 3);
      expect(ops.where((o) => o == WordProblemOp.sub).length, 3);
    });

    test('only the eats context requires edible items', () {
      for (final c in addSubContextsV1) {
        expect(
          c.requiresEdibleItems,
          c.id == 'eats',
          reason: 'context ${c.id}',
        );
      }
    });
  });

  group('composeWordProblem', () {
    test('addition: substitutes Name, b, items and ends with "have now"', () {
      final out = composeWordProblem(
        name: 'Maria',
        items: 'apples',
        a: 5,
        b: 7,
        context: const WordProblemContext(
          id: 'test_add',
          op: WordProblemOp.add,
          action: '{Name} finds {b} more {items}.',
        ),
      );
      expect(
        out,
        'Maria has 5 apples. Maria finds 7 more apples. '
        'How many apples does Maria have now?',
      );
    });

    test('subtraction: ends with "have left"', () {
      final out = composeWordProblem(
        name: 'Diego',
        items: 'bricks',
        a: 12,
        b: 5,
        context: const WordProblemContext(
          id: 'test_sub',
          op: WordProblemOp.sub,
          action: '{Name} loses {b} of the {items}.',
        ),
      );
      expect(
        out,
        'Diego has 12 bricks. Diego loses 5 of the bricks. '
        'How many bricks does Diego have left?',
      );
    });

    test('renders cleanly for each v1 context', () {
      for (final ctx in addSubContextsV1) {
        // Always pick an edible to satisfy the eats context too.
        final out = composeWordProblem(
          name: 'Diego',
          items: 'apples',
          a: 12,
          b: 8,
          context: ctx,
        );
        expect(out, isNot(contains('{')));
        expect(out, contains('Diego'));
        expect(out, contains('apples'));
        expect(out, contains('12'));
        expect(out, contains('8'));
        final closing =
            ctx.op == WordProblemOp.add ? 'have now?' : 'have left?';
        expect(out, endsWith('How many apples does Diego $closing'));
      }
    });
  });

  group('add_word_problems_within_100 (add+sub)', () {
    test('conceptId, prompt structure, arithmetic, distractors', () {
      // Match the prompt: "<name> has <a> <items>. ... How many <items> "
      // "does <name> have (now|left)?"
      final promptRe = RegExp(
        r'^(.+) has (\d+) (.+)\. .+ How many \3 does \1 have (now|left)\?$',
      );

      for (var i = 0; i < _iterations; i++) {
        final q = _gen(registry, i);

        expect(q.conceptId, 'add_word_problems_within_100');
        expect(q.diagram, isNull);

        final m = promptRe.firstMatch(q.prompt);
        expect(m, isNotNull, reason: 'prompt did not match: ${q.prompt}');
        final name = m!.group(1)!;
        final a = int.parse(m.group(2)!);
        final items = m.group(3)!;
        final closing = m.group(4)!;

        // Name + items must be from the pool.
        expect(wordProblemNames, contains(name));
        expect(wordProblemItems, contains(items));

        // Two integers in the prompt: a (setup) and b (action).
        final integers = RegExp(r'\d+').allMatches(q.prompt).toList();
        expect(integers, hasLength(2));
        final b = int.parse(integers[1].group(0)!);

        final isAdd = closing == 'now';
        if (isAdd) {
          expect(a, inInclusiveRange(2, 98));
          expect(b, inInclusiveRange(2, 100 - a));
          expect(int.parse(q.correctAnswer), a + b);
        } else {
          expect(a, inInclusiveRange(4, 100));
          expect(b, inInclusiveRange(2, a - 2));
          expect(int.parse(q.correctAnswer), a - b);
        }

        // Result is always plural-friendly (≥ 2).
        expect(int.parse(q.correctAnswer), greaterThanOrEqualTo(2));

        // Distractors.
        expect(q.distractors, hasLength(3));
        expect(q.distractors.toSet(), hasLength(3));
        expect(q.distractors, isNot(contains(q.correctAnswer)));

        // Explanation: 3 lines, last line contains the name + total + items.
        expect(q.explanation, hasLength(3));
        expect(q.explanation.last, contains(name));
        expect(q.explanation.last, contains(q.correctAnswer));
        expect(q.explanation.last, contains(items));
      }
    });

    test('eats context is always paired with an edible item', () {
      var sawEats = false;
      // Non-greedy to avoid over-capturing past the first sentence boundary.
      final setupRe = RegExp(r'^(.+?) has (\d+) (.+?)\. ');
      for (var i = 0; i < 2000; i++) {
        final q = _gen(registry, i);
        if (!q.prompt.contains(' eats ')) continue;
        sawEats = true;
        final m = setupRe.firstMatch(q.prompt)!;
        final items = m.group(3)!;
        expect(
          edibleWordProblemItems,
          contains(items),
          reason: 'eats context picked non-edible: $items',
        );
      }
      expect(sawEats, isTrue, reason: 'eats context never sampled in 2000');
    });

    test('pool coverage: every name + item + context appears across 2000 '
        'iterations', () {
      final namesSeen = <String>{};
      final itemsSeen = <String>{};
      // Distinguishing phrases per context.
      var sawCollects = false;
      var sawIsGiven = false;
      var sawBuys = false;
      var sawGivesAway = false;
      var sawEats = false;
      var sawLoses = false;
      var sawAddShape = false;
      var sawSubShape = false;

      for (var i = 0; i < 2000; i++) {
        final q = _gen(registry, i);
        for (final n in wordProblemNames) {
          if (q.prompt.startsWith('$n has ')) {
            namesSeen.add(n);
            break;
          }
        }
        for (final item in wordProblemItems) {
          if (q.prompt.contains(' $item.') ||
              q.prompt.contains(' $item ')) {
            itemsSeen.add(item);
            break;
          }
        }
        if (q.prompt.contains(' finds ')) sawCollects = true;
        if (q.prompt.contains('A friend gives ')) sawIsGiven = true;
        if (q.prompt.contains(' buys ')) sawBuys = true;
        if (q.prompt.contains(' gives ') &&
            q.prompt.contains(' to a friend.')) {
          sawGivesAway = true;
        }
        if (q.prompt.contains(' eats ')) sawEats = true;
        if (q.prompt.contains(' loses ')) sawLoses = true;
        if (q.prompt.endsWith('have now?')) sawAddShape = true;
        if (q.prompt.endsWith('have left?')) sawSubShape = true;
      }

      expect(namesSeen, hasLength(wordProblemNames.length));
      expect(itemsSeen, hasLength(wordProblemItems.length));
      expect(sawCollects, isTrue);
      expect(sawIsGiven, isTrue);
      expect(sawBuys, isTrue);
      expect(sawGivesAway, isTrue);
      expect(sawEats, isTrue);
      expect(sawLoses, isTrue);
      expect(sawAddShape, isTrue);
      expect(sawSubShape, isTrue);
    });
  });

  group('mult_compare_word', () {
    GeneratedQuestion gen(int seed) =>
        registry.generate('mult_compare_word', random: Random(seed));

    test('correct = k × n; k ∈ [2,9], n ∈ [2,11]; distinct names', () {
      final promptRe = RegExp(
        r'^(\S+) has (\d+) times as many (.+?) as (\S+)\. '
        r'\4 has (\d+) \3\. How many \3 does \1 have\?$',
      );

      for (var i = 0; i < _iterations; i++) {
        final q = gen(i);
        expect(q.conceptId, 'mult_compare_word');
        expect(q.diagram, isNull);

        final m = promptRe.firstMatch(q.prompt);
        expect(m, isNotNull, reason: 'prompt did not match: ${q.prompt}');
        final name1 = m!.group(1)!;
        final k = int.parse(m.group(2)!);
        final items = m.group(3)!;
        final name2 = m.group(4)!;
        final n = int.parse(m.group(5)!);

        expect(wordProblemNames, contains(name1));
        expect(wordProblemNames, contains(name2));
        expect(name1, isNot(name2));
        expect(wordProblemItems, contains(items));
        expect(k, inInclusiveRange(2, 9));
        expect(n, inInclusiveRange(2, 11));
        expect(int.parse(q.correctAnswer), k * n);
        expect(int.parse(q.correctAnswer), lessThanOrEqualTo(99));

        expect(q.distractors, hasLength(3));
        expect(q.distractors.toSet(), hasLength(3));
        expect(q.distractors, isNot(contains(q.correctAnswer)));
      }
    });
  });
}
