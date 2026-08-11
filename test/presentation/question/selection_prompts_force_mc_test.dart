import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/generator_registry.dart';
import 'package:math_city/presentation/question/question_screen.dart';

/// A prompt that says "which of these" is asking the player to pick from the
/// choices on screen. At the comfortable band the choices are replaced by a
/// number pad — and then the phrase refers to nothing, while every value the
/// player might reasonably type is graded against the single stored answer.
///
/// Regression for #93 / #94: `factors_of_n` asked "Which of these is a factor
/// of 24?" on a keypad. 24 has eight factors; seven of them were marked wrong.
/// `multiples_of_n` was worse — the right answers are unbounded.
///
/// Generators opt out with `multipleChoiceOnly: true`.
final _selectionPhrase = RegExp(r'\bwhich of (these|the following)\b');

void main() {
  test('prompts that refer to the choices are never keypad-answered', () {
    final registry = GeneratorRegistry.defaultRegistry();
    final offenders = <String, String>{};

    for (final id in registry.implementedConceptIds) {
      // Several seeds: some generators only take the selection-phrasing
      // branch on a subset of rolls.
      for (var seed = 0; seed < 40; seed++) {
        final q = registry.generate(id, random: Random(seed));
        if (!_selectionPhrase.hasMatch(q.prompt.toLowerCase())) continue;
        if (q.multipleChoiceOnly) continue;
        if (!formatSupportsKeypad(q.answerFormat)) continue;
        offenders.putIfAbsent(id, () => q.prompt);
        break;
      }
    }

    final detail = offenders.entries
        .map((e) => '  ${e.key} -> "${e.value}"')
        .join('\n');

    expect(
      offenders,
      isEmpty,
      reason:
          'These prompts refer to on-screen choices but would be answered on '
          'the number pad. Set multipleChoiceOnly: true.\n$detail',
    );
  });
}
