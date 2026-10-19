import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/presentation/widgets/math_text.dart';

void main() {
  group('parseMathSegments', () {
    test('plain text stays one plain segment', () {
      final segs = parseMathSegments('What is 3² + 4?');
      expect(segs, hasLength(1));
      expect((segs.single as PlainSegment).text, 'What is 3² + 4?');
    });

    test('square root of an integer', () {
      final segs = parseMathSegments('What is √16?');
      expect(segs, hasLength(3));
      final radical = segs[1] as RadicalSegment;
      expect(radical.radicand, '16');
      expect(radical.index, isNull);
      expect((segs[0] as PlainSegment).text, 'What is ');
      expect((segs[2] as PlainSegment).text, '?');
    });

    test('cube root carries index 3', () {
      final segs = parseMathSegments('What is ∛27?');
      final radical = segs[1] as RadicalSegment;
      expect(radical.radicand, '27');
      expect(radical.index, '3');
    });

    test('parenthesized radicand drops the outer parens', () {
      final segs = parseMathSegments('diagonal = √(l² + w² + h²) = 7.');
      final radical = segs[1] as RadicalSegment;
      expect(radical.radicand, 'l² + w² + h²');
      expect((segs[2] as PlainSegment).text, ' = 7.');
    });

    test('multiple radicals in one string', () {
      final segs = parseMathSegments('√4 < √7 < √9');
      expect(segs.whereType<RadicalSegment>().map((r) => r.radicand), [
        '4',
        '7',
        '9',
      ]);
    });

    test('radicand stops before a sentence-ending period', () {
      final segs = parseMathSegments('Estimate √7.');
      final radical = segs.whereType<RadicalSegment>().single;
      expect(radical.radicand, '7');
      expect((segs.last as PlainSegment).text, '.');
    });

    test('decimal radicand is kept whole', () {
      final segs = parseMathSegments('√2.25 = 1.5');
      final radical = segs.whereType<RadicalSegment>().single;
      expect(radical.radicand, '2.25');
    });

    test('bare radical sign with no radicand stays literal text', () {
      final segs = parseMathSegments('the √ symbol');
      expect(segs, hasLength(1));
      expect((segs.single as PlainSegment).text, 'the √ symbol');
    });

    test('a blank becomes a box segment', () {
      final segs = parseMathSegments('7 + ___ = 12');
      expect(segs, hasLength(3));
      final blank = segs[1] as BlankSegment;
      expect((blank.start, blank.end), (4, 7));
      expect((segs[2] as PlainSegment).start, 7);
    });

    test('a blank numerator stacks, with the other fractions', () {
      final segs = parseMathSegments('2/3 = ___/6');
      final fractions = segs.whereType<FractionSegment>().toList();
      expect(fractions.map((f) => (f.numerator, f.denominator)), [
        ('2', '3'),
        (null, '6'),
      ]);
      expect((fractions[1].start, fractions[1].end), (6, 11));
    });

    test('fractions stay inline without a blank numerator', () {
      final segs = parseMathSegments('3/4 × 3/4 = ?');
      expect(segs.single, isA<PlainSegment>());
    });

    test('a decimal over a number is not a fraction', () {
      final segs = parseMathSegments('___/6 vs 1.5/2');
      expect(segs.whereType<FractionSegment>(), hasLength(1));
    });
  });
}
