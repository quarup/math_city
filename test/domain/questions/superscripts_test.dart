import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/questions/superscripts.dart';

void main() {
  group('sup', () {
    test('single and multi-digit ints', () {
      expect(sup(5), '⁵');
      expect(sup(23), '²³');
      expect(sup(107), '¹⁰⁷');
    });

    test('negative ints use superscript minus', () {
      expect(sup(-4), '⁻⁴');
    });

    test('symbolic exponent-rule strings', () {
      expect(sup('m+n'), 'ᵐ⁺ⁿ');
      expect(sup('m-n'), 'ᵐ⁻ⁿ');
      expect(sup('mn'), 'ᵐⁿ');
    });
  });
}
