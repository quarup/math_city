import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/presentation/question/question_screen.dart';

void main() {
  group('formatSupportsKeypad', () {
    test('numeric formats allow keypad input', () {
      expect(formatSupportsKeypad(AnswerFormat.integer), isTrue);
      expect(formatSupportsKeypad(AnswerFormat.fraction), isTrue);
      expect(formatSupportsKeypad(AnswerFormat.mixedNumber), isTrue);
      expect(formatSupportsKeypad(AnswerFormat.decimal), isTrue);
    });

    test('text-shaped formats force MC even at the comfortable band', () {
      // string answers (e.g. "3:30 PM") and commaList sort answers can't
      // fit the digit-only pad with its small extra-chars row and 8-char
      // input cap — the gate must keep them on MC.
      expect(formatSupportsKeypad(AnswerFormat.string), isFalse);
      expect(formatSupportsKeypad(AnswerFormat.commaList), isFalse);
    });
  });
}
