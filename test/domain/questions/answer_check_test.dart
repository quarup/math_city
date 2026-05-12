import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/answer_check.dart';
import 'package:math_city/domain/questions/generated_question.dart';

GeneratedQuestion _q(
  String correct, {
  AnswerFormat fmt = AnswerFormat.integer,
  bool requiresCanonical = false,
}) => GeneratedQuestion(
  conceptId: 'test',
  prompt: 'test',
  correctAnswer: correct,
  distractors: const ['a', 'b', 'c'],
  explanation: const [],
  answerFormat: fmt,
  requiresCanonicalForm: requiresCanonical,
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

    test('requiresCanonicalForm rejects equivalents', () {
      expect(
        checkAnswer(
          _q('1/2', fmt: AnswerFormat.fraction, requiresCanonical: true),
          '2/4',
        ),
        AnswerOutcome.wrong,
      );
      // Canonical still passes.
      expect(
        checkAnswer(
          _q('1/2', fmt: AnswerFormat.fraction, requiresCanonical: true),
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

    test('requiresCanonicalForm: rejects improper when mixed expected', () {
      expect(
        checkAnswer(
          _q(
            '1 1/4',
            fmt: AnswerFormat.mixedNumber,
            requiresCanonical: true,
          ),
          '5/4',
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
