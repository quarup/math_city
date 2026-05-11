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

    test('v1 addition contexts: 3 entries, unique ids, action template has '
        'all three placeholders', () {
      expect(additionContextsV1, hasLength(3));
      expect(
        additionContextsV1.map((c) => c.id).toSet(),
        hasLength(3),
      );
      for (final c in additionContextsV1) {
        expect(c.action, contains('{Name}'));
        expect(c.action, contains('{b}'));
        expect(c.action, contains('{items}'));
      }
    });
  });

  group('composeAdditionWordProblem', () {
    test('substitutes Name, b, items in every slot', () {
      final out = composeAdditionWordProblem(
        name: 'Maria',
        items: 'apples',
        a: 5,
        b: 7,
        context: const AdditionContext(
          id: 'test',
          action: '{Name} finds {b} more {items}.',
        ),
      );
      expect(
        out,
        'Maria has 5 apples. Maria finds 7 more apples. '
        'How many apples does Maria have now?',
      );
    });

    test('renders cleanly for each v1 context', () {
      for (final ctx in additionContextsV1) {
        final out = composeAdditionWordProblem(
          name: 'Diego',
          items: 'bricks',
          a: 12,
          b: 8,
          context: ctx,
        );
        expect(out, isNot(contains('{')));
        expect(out, contains('Diego'));
        expect(out, contains('bricks'));
        expect(out, contains('12'));
        expect(out, contains('8'));
        expect(out, endsWith('How many bricks does Diego have now?'));
      }
    });
  });

  group('add_word_problems_within_100', () {
    test('conceptId, prompt structure, arithmetic, distractors', () {
      // Match the prompt: "<name> has <a> <items>. ... How many <items> "
      // "does <name> have now?"
      final promptRe = RegExp(
        r'^(.+) has (\d+) (.+)\. .+ How many \3 does \1 have now\?$',
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

        // Name + items must be from the pool.
        expect(wordProblemNames, contains(name));
        expect(wordProblemItems, contains(items));

        // a ∈ [2, 98].
        expect(a, inInclusiveRange(2, 98));

        // The action sentence sits between the setup and the question.
        // Extract b from the only other integer in the prompt.
        final integers = RegExp(r'\d+').allMatches(q.prompt).toList();
        expect(integers, hasLength(2));
        final b = int.parse(integers[1].group(0)!);
        expect(b, inInclusiveRange(2, 100 - a));

        // Correct answer.
        final correct = int.parse(q.correctAnswer);
        expect(correct, a + b);
        expect(correct, inInclusiveRange(4, 100));

        // Distractors.
        expect(q.distractors, hasLength(3));
        expect(q.distractors.toSet(), hasLength(3));
        expect(q.distractors, isNot(contains(q.correctAnswer)));

        // Explanation: 3 lines, last line contains the name + total + items.
        expect(q.explanation, hasLength(3));
        expect(q.explanation.last, contains(name));
        expect(q.explanation.last, contains('$correct'));
        expect(q.explanation.last, contains(items));
      }
    });

    test('pool coverage: every name + item + context appears across 1000 '
        'iterations', () {
      final namesSeen = <String>{};
      final itemsSeen = <String>{};
      // We can't read context id from the prompt directly, but each context
      // uses a distinguishing phrase: "finds", "A friend gives", "buys".
      var sawCollects = false;
      var sawIsGiven = false;
      var sawBuys = false;

      for (var i = 0; i < 1000; i++) {
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
      }

      expect(namesSeen, hasLength(wordProblemNames.length));
      expect(itemsSeen, hasLength(wordProblemItems.length));
      expect(sawCollects, isTrue);
      expect(sawIsGiven, isTrue);
      expect(sawBuys, isTrue);
    });
  });
}
