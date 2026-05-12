import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/answer_check.dart';
import 'package:math_city/domain/questions/generated_question.dart';

GeneratedQuestion _q(
  String correct, {
  AnswerFormat fmt = AnswerFormat.integer,
  AnswerShape shape = AnswerShape.any,
}) => GeneratedQuestion(
  conceptId: 'test',
  prompt: 'test',
  correctAnswer: correct,
  distractors: const ['a', 'b', 'c'],
  explanation: const [],
  answerFormat: fmt,
  answerShape: shape,
);

void main() {
  group('integer format', () {
    test('exact match → canonical', () {
      expect(checkAnswer(_q('42'), '42'), AnswerOutcome.canonical);
    });

    test('mismatch → wrong', () {
      expect(checkAnswer(_q('42'), '43'), AnswerOutcome.wrong);
    });

    test('whitespace tolerated', () {
      expect(checkAnswer(_q('42'), '  42 '), AnswerOutcome.canonical);
    });
  });

  group('fraction format', () {
    test('canonical match', () {
      expect(
        checkAnswer(_q('1/2', fmt: AnswerFormat.fraction), '1/2'),
        AnswerOutcome.canonical,
      );
    });

    test('equivalent non-canonical → accepted-with-nudge', () {
      expect(
        checkAnswer(_q('1/2', fmt: AnswerFormat.fraction), '2/4'),
        AnswerOutcome.equivalentNonCanonical,
      );
      expect(
        checkAnswer(_q('1/2', fmt: AnswerFormat.fraction), '4/8'),
        AnswerOutcome.equivalentNonCanonical,
      );
    });

    test('non-equivalent → wrong', () {
      expect(
        checkAnswer(_q('1/2', fmt: AnswerFormat.fraction), '1/3'),
        AnswerOutcome.wrong,
      );
    });

    test('garbage input → wrong', () {
      expect(
        checkAnswer(_q('1/2', fmt: AnswerFormat.fraction), 'banana'),
        AnswerOutcome.wrong,
      );
    });

    test('whole-as-int accepted as fraction', () {
      // Correct canonical "1"; player types "2/2".
      expect(
        checkAnswer(_q('1', fmt: AnswerFormat.fraction), '2/2'),
        AnswerOutcome.equivalentNonCanonical,
      );
    });

    test('AnswerShape.exactString rejects equivalents', () {
      expect(
        checkAnswer(
          _q(
            '1/2',
            fmt: AnswerFormat.fraction,
            shape: AnswerShape.exactString,
          ),
          '2/4',
        ),
        AnswerOutcome.wrong,
      );
      // Canonical still passes.
      expect(
        checkAnswer(
          _q(
            '1/2',
            fmt: AnswerFormat.fraction,
            shape: AnswerShape.exactString,
          ),
          '1/2',
        ),
        AnswerOutcome.canonical,
      );
    });
  });

  group('mixedNumber format', () {
    test('5/4 accepts "1 1/4"', () {
      expect(
        checkAnswer(
          _q('1 1/4', fmt: AnswerFormat.mixedNumber),
          '5/4',
        ),
        AnswerOutcome.equivalentNonCanonical,
      );
    });

    test('"1 1/4" canonical → canonical outcome', () {
      expect(
        checkAnswer(
          _q('1 1/4', fmt: AnswerFormat.mixedNumber),
          '1 1/4',
        ),
        AnswerOutcome.canonical,
      );
    });

    test('AnswerShape.mixedForm rejects improper-shape input', () {
      expect(
        checkAnswer(
          _q(
            '1 1/4',
            fmt: AnswerFormat.mixedNumber,
            shape: AnswerShape.mixedForm,
          ),
          '5/4',
        ),
        AnswerOutcome.wrong,
      );
    });

    test('AnswerShape.mixedForm accepts simplified mixed equivalent', () {
      // Canonical "3 2/4" — player types "3 1/2" (simplified mixed).
      expect(
        checkAnswer(
          _q(
            '3 2/4',
            fmt: AnswerFormat.mixedNumber,
            shape: AnswerShape.mixedForm,
          ),
          '3 1/2',
        ),
        AnswerOutcome.equivalentNonCanonical,
      );
    });

    test('AnswerShape.improperFraction accepts simplified improper', () {
      // Canonical "14/4" — player types "7/2" (simplified improper).
      expect(
        checkAnswer(
          _q(
            '14/4',
            fmt: AnswerFormat.fraction,
            shape: AnswerShape.improperFraction,
          ),
          '7/2',
        ),
        AnswerOutcome.equivalentNonCanonical,
      );
    });

    test('AnswerShape.improperFraction rejects mixed-shape input', () {
      expect(
        checkAnswer(
          _q(
            '14/4',
            fmt: AnswerFormat.fraction,
            shape: AnswerShape.improperFraction,
          ),
          '3 1/2',
        ),
        AnswerOutcome.wrong,
      );
    });
  });

  group('string format', () {
    test('exact match only', () {
      expect(
        checkAnswer(_q('3/4', fmt: AnswerFormat.string), '3/4'),
        AnswerOutcome.canonical,
      );
      expect(
        checkAnswer(_q('3/4', fmt: AnswerFormat.string), '6/8'),
        AnswerOutcome.wrong,
      );
    });
  });
}
