import 'package:flutter_test/flutter_test.dart';
import 'package:math_dash/domain/questions/question.dart';

void main() {
  group('Question.allChoices', () {
    const q = Question(
      conceptId: 'add_1digit',
      prompt: '3 + 4 = ?',
      correctAnswer: '7',
      distractors: ['6', '8', '9'],
      explanation: '3 + 4 = 7',
    );

    test('returns exactly 4 choices', () {
      expect(q.allChoices, hasLength(4));
    });

    test('includes the correct answer', () {
      expect(q.allChoices, contains('7'));
    });

    test('includes all three distractors', () {
      expect(q.allChoices, containsAll(['6', '8', '9']));
    });
  });
}
