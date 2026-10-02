import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/spoken_text.dart';

void main() {
  group('hasReadableWords', () {
    test('a prompt with any real word is readable', () {
      expect(hasReadableWords('Which is the shortest?'), isTrue);
      expect(hasReadableWords('Add.'), isTrue);
      expect(hasReadableWords('What time is it?'), isTrue);
      expect(hasReadableWords('Solve for x: 2x + 11 = 15'), isTrue);
    });

    test('bare sums and digit strings are not', () {
      expect(hasReadableWords('31 − 14 = ?'), isFalse);
      expect(hasReadableWords('8, 9, ___'), isFalse);
      expect(hasReadableWords('3/4 × 3/4 = ?'), isFalse);
      // A lone variable is not a word.
      expect(hasReadableWords('4x = 24'), isFalse);
      expect(hasReadableWords('12'), isFalse);
    });
  });

  group('spokenForm', () {
    test('leaves plain prose alone', () {
      const prose =
          'Arjun has 39 apples. How many apples does Arjun have left?';
      expect(
        spokenForm(prose),
        'Arjun has 39 apples. How many apples does Arjun have left',
      );
    });

    test('blanks, operators and the question mark', () {
      expect(spokenForm('8, 9, ___'), '8, 9, blank');
      expect(spokenForm('31 − 14 = ?'), '31 minus 14 equals what');
      expect(spokenForm('3 + 4 = ?'), '3 plus 4 equals what');
      expect(spokenForm('5 ÷ 1/4 = ?'), '5 divided by 1 quarter equals what');
      expect(spokenForm('10:15 at night is ___'), '10:15 at night is blank');
    });

    test('fractions and mixed numbers', () {
      expect(
        spokenForm('3/4 × 3/4 = ?'),
        '3 quarters times 3 quarters equals what',
      );
      expect(
        spokenForm('Which is bigger: 6/7 or 4/7?'),
        'Which is bigger: 6 sevenths or 4 sevenths',
      );
      expect(spokenForm('1/2 + 1/3'), '1 half plus 1 third');
      expect(spokenForm('2 3/4'), '2 and 3 quarters');
      expect(spokenForm('7/13'), '7 over 13');
    });

    test('negative numbers and coordinates', () {
      expect(
        spokenForm('Which point is at (3, −1)?'),
        'Which point is at 3, negative 1',
      );
      expect(
        spokenForm('What is the opposite of 14?'),
        'What is the opposite of 14',
      );
      expect(
        spokenForm('Which is the greatest: 4, −4.5, 0, −2.5?'),
        'Which is the greatest: 4, negative 4.5, 0, negative 2.5',
      );
      expect(spokenForm('What is |6|?'), 'What is the absolute value of 6');
    });

    test('money, percent, degrees', () {
      expect(spokenForm(r'$20.15'), '20 dollars and 15 cents');
      expect(spokenForm(r'$1'), '1 dollar');
      expect(spokenForm('85¢'), '85 cents');
      expect(
        spokenForm(r'You pay with $1 for an item that costs 85¢.'),
        'You pay with 1 dollar for an item that costs 85 cents.',
      );
      expect(spokenForm('What is 98% of 300?'), 'What is 98 percent of 300');
      expect(spokenForm('61° and 81°'), '61 degrees and 81 degrees');
    });

    test('powers and roots', () {
      expect(spokenForm('What is 5²?'), 'What is 5 squared');
      expect(
        spokenForm('Simplify: (8⁶)²'),
        'Simplify: 8 to the power of 6 squared',
      );
      expect(spokenForm('What is √121?'), 'What is the square root of 121');
      expect(spokenForm('What is ∛125?'), 'What is the cube root of 125');
      expect(spokenForm('x³ = 27'), 'x cubed equals 27');
    });

    test('ratios, times and remainders', () {
      expect(spokenForm('Complete: 4:3 = ?:9'), 'Complete: 4 to 3 equals ?:9');
      expect(spokenForm('What time is it? 7:05'), 'What time is it 7:05');
      expect(spokenForm('(Answer like 3R1.)'), 'Answer like 3 remainder 1.');
    });

    test('silent punctuation tokens vanish', () {
      expect(spokenForm('• y = 2x − 1'), 'y equals 2x minus 1');
      expect(spokenForm('{(5, 7), (6, 1)}'), '5, 7, 6, 1');
    });

    test('token map points back at the screen text', () {
      final s = spokenFormOf('8, 9, ___');
      expect(s.text, '8, 9, blank');
      expect(s.tokens.map((t) => t.display), ['8,', '9,', '___']);
      final blank = s.tokenAt(s.text.indexOf('blank'));
      expect(blank!.display, '___');
      expect(blank.displayStart, 6);
      expect(blank.displayEnd, 9);
      // An offset inside the first token resolves to it; a gap to nothing.
      expect(s.tokenAt(1)!.display, '8,');
      expect(s.tokenAt(2), isNull);
    });

    test('silent tokens keep their place without stealing offsets', () {
      final s = spokenFormOf('• y = 2x');
      expect(s.tokens.first.spoken, '');
      expect(s.tokenAt(0)!.display, 'y');
      expect(s.tokenAt(s.text.indexOf('equals'))!.display, '=');
    });
  });
}
