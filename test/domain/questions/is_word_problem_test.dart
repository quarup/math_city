import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/is_word_problem.dart';

void main() {
  group('isWordProblem', () {
    test('bare integer equation is NOT a word problem', () {
      expect(isWordProblem('3 + 4 = ?'), isFalse);
      expect(isWordProblem('12 - 7'), isFalse);
      expect(isWordProblem('25 × 4 = ?'), isFalse);
      expect(isWordProblem('100 / 5'), isFalse);
    });

    test('fraction / decimal / time equations are NOT word problems', () {
      expect(isWordProblem('1/2 + 1/3 = ?'), isFalse);
      expect(isWordProblem('2.5 + 1.75'), isFalse);
      expect(isWordProblem('3:30 + 0:45'), isFalse);
    });

    test(
      'short numeric prompts with one filler word are NOT word problems',
      () {
        // Single short label / unit isn't enough to flip the classifier.
        expect(isWordProblem('What is 3 + 4?'), isFalse);
        expect(isWordProblem('Simplify 6/8'), isFalse);
      },
    );

    test('classic narrative word problems ARE word problems', () {
      expect(
        isWordProblem('Sam has 5 apples and gives 2 to Jo. How many left?'),
        isTrue,
      );
      expect(
        isWordProblem(
          'A train leaves at 3 pm travelling 60 mph. How far in 2 hours?',
        ),
        isTrue,
      );
      expect(
        isWordProblem('There are 12 cookies shared among 4 friends equally.'),
        isTrue,
      );
    });

    test('stop words alone do not qualify as content', () {
      // "Is the a an" — four stop words, no real content.
      expect(isWordProblem('Is the a an'), isFalse);
    });

    test('empty / whitespace-only prompts are not word problems', () {
      expect(isWordProblem(''), isFalse);
      expect(isWordProblem('   '), isFalse);
    });
  });
}
