import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/presentation/question/question_screen.dart';

GeneratedQuestion _q(String correct, List<String> distractors) =>
    GeneratedQuestion(
      conceptId: 'test',
      prompt: 'test',
      correctAnswer: correct,
      distractors: distractors,
      explanation: const [],
    );

void main() {
  test('keys come from all choices, so the sign is not leaked', () {
    // integers_multiply_divide: positive answer, sign-flip distractor.
    // The − key must appear even though the answer is positive.
    expect(extraKeypadCharsFor(_q('9', ['−9', '8', '45'])), ['−']);
  });

  test('/ stays available when a fraction sum simplifies to a whole', () {
    // add_fractions_like_denom: answer 1, fraction distractors.
    expect(extraKeypadCharsFor(_q('1', ['5/7', '2/7', '6/7'])), ['/']);
  });

  test('digits-only questions keep a digits-only pad', () {
    expect(extraKeypadCharsFor(_q('9', ['8', '10', '11'])), isEmpty);
  });

  test('ASCII hyphen folds into the typeset minus (one key, not two)', () {
    expect(extraKeypadCharsFor(_q('−4.5', ['-2.5', '4.5', '2.5'])), [
      '−',
      '.',
    ]);
  });

  test('untypeable notation in choices is not surfaced as a key', () {
    expect(
      extraKeypadCharsFor(_q('19761', ['19,761', '21586', '19760'])),
      isEmpty,
    );
  });

  test('mixed-number choices expose the and-separator and slash', () {
    expect(extraKeypadCharsFor(_q('2 1/2', ['5/2', '2 1/4', '3'])), [
      '/',
      ' ',
    ]);
  });
}
