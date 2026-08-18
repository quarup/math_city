import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/generator_registry.dart';

/// The number pad caps input at 8 characters and renders each distinct
/// non-digit character of the answer as one key in a single un-wrapped
/// row. So a keypad-eligible [AnswerFormat] is a promise on two counts:
/// the answer fits in 8 characters, and it needs at most a couple of
/// symbol keys.
///
/// A generator that returns prose ("Add 2 each time") while leaving
/// `answerFormat` at its `integer` default breaks the promise twice over:
/// the pad is offered at the comfortable band, and the extra-chars row
/// fills with the answer's letters and overflows off-screen.
const _maxPadLength = 8;
const _maxExtraKeys = 2;

void main() {
  test('keypad-eligible answers are actually typeable on the pad', () {
    final registry = GeneratorRegistry.defaultRegistry();
    final offenders = <String, String>{};

    for (final id in registry.implementedConceptIds) {
      // Several seeds per concept: some generators only reach a
      // text-shaped answer on a subset of branches.
      for (var seed = 0; seed < 40; seed++) {
        final q = registry.generate(id, random: Random(seed));
        // multipleChoiceOnly questions never reach the pad regardless of
        // format — mirrors QuestionScreen's keypad gate.
        if (q.multipleChoiceOnly || !_keypadEligible(q.answerFormat)) continue;
        final why = _untypeableReason(q.correctAnswer);
        if (why != null) {
          offenders.putIfAbsent(id, () => '${q.correctAnswer}  ($why)');
          break;
        }
      }
    }

    final detail = offenders.entries
        .map((e) => '  ${e.key} -> "${e.value}"')
        .join('\n');

    expect(
      offenders,
      isEmpty,
      reason:
          'These concepts declare a keypad-eligible answerFormat but produce '
          'an answer the pad cannot type. Set answerFormat: '
          'AnswerFormat.string on the generator.\n$detail',
    );
  });
}

/// Returns why [answer] can't be entered on the pad, or null if it can.
String? _untypeableReason(String answer) {
  if (answer.length > _maxPadLength) {
    return '${answer.length} chars > $_maxPadLength';
  }
  final extras = answer
      .split('')
      .where((c) => !'0123456789'.contains(c))
      .toSet();
  if (extras.length > _maxExtraKeys) {
    return '${extras.length} extra-char keys > $_maxExtraKeys';
  }
  // A run of two or more letters is a word, not notation. Single letters
  // are fine — `4R5` (quotient-remainder) and `−20` each need one key.
  if (RegExp('[A-Za-z]{2}').hasMatch(answer)) {
    return 'contains a word';
  }
  return null;
}

bool _keypadEligible(AnswerFormat fmt) => switch (fmt) {
  AnswerFormat.integer ||
  AnswerFormat.fraction ||
  AnswerFormat.mixedNumber ||
  AnswerFormat.decimal => true,
  AnswerFormat.string || AnswerFormat.commaList => false,
};
