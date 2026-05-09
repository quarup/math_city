import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';

void main() {
  group('bandForProficiency', () {
    test('p < 0.20 → notYet', () {
      expect(bandForProficiency(0), ProficiencyBand.notYet);
      expect(bandForProficiency(0.19), ProficiencyBand.notYet);
    });

    test('0.20 ≤ p < 0.50 → challenging', () {
      expect(bandForProficiency(0.20), ProficiencyBand.challenging);
      expect(bandForProficiency(0.35), ProficiencyBand.challenging);
      expect(bandForProficiency(0.499), ProficiencyBand.challenging);
    });

    test('0.50 ≤ p < 0.85 → comfortable', () {
      expect(bandForProficiency(0.50), ProficiencyBand.comfortable);
      expect(bandForProficiency(0.67), ProficiencyBand.comfortable);
      expect(bandForProficiency(0.849), ProficiencyBand.comfortable);
    });

    test('p ≥ 0.85 → mastered', () {
      expect(bandForProficiency(0.85), ProficiencyBand.mastered);
      expect(bandForProficiency(1), ProficiencyBand.mastered);
    });

    test('boundary: exactly 0.20', () {
      expect(bandForProficiency(0.20), ProficiencyBand.challenging);
    });

    test('boundary: exactly 0.50', () {
      expect(bandForProficiency(0.50), ProficiencyBand.comfortable);
    });

    test('boundary: exactly 0.85', () {
      expect(bandForProficiency(0.85), ProficiencyBand.mastered);
    });
  });

  group('starsForBand', () {
    test('challenging → 5 stars', () {
      expect(starsForBand(ProficiencyBand.challenging), 5);
    });

    test('comfortable → 3 stars', () {
      expect(starsForBand(ProficiencyBand.comfortable), 3);
    });

    test('notYet → 0 stars', () {
      expect(starsForBand(ProficiencyBand.notYet), 0);
    });

    test('mastered → 0 stars', () {
      expect(starsForBand(ProficiencyBand.mastered), 0);
    });
  });

  group('updateProficiency', () {
    const alpha = 0.1;

    test('correct answer increases p', () {
      const p = 0.4;
      final result = updateProficiency(p, correct: true);
      expect(result, closeTo(p + alpha * (1.0 - p), 1e-10));
      expect(result, greaterThan(p));
    });

    test('wrong answer decreases p', () {
      const p = 0.4;
      final result = updateProficiency(p, correct: false);
      expect(result, closeTo(p + alpha * (0.0 - p), 1e-10));
      expect(result, lessThan(p));
    });

    test('p=1.0 stays at 1.0 after correct', () {
      expect(updateProficiency(1, correct: true), 1);
    });

    test('p=0.0 stays at 0.0 after wrong', () {
      expect(updateProficiency(0, correct: false), 0);
    });

    test('result is always clamped to [0, 1]', () {
      for (var i = 0; i <= 10; i++) {
        final p = i / 10.0;
        final afterCorrect = updateProficiency(p, correct: true);
        final afterWrong = updateProficiency(p, correct: false);
        expect(afterCorrect, inInclusiveRange(0.0, 1.0));
        expect(afterWrong, inInclusiveRange(0.0, 1.0));
      }
    });

    test('repeated correct answers converge toward 1.0', () {
      var p = 0.4;
      for (var i = 0; i < 100; i++) {
        p = updateProficiency(p, correct: true);
      }
      expect(p, greaterThan(0.99));
    });

    test('repeated wrong answers converge toward 0.0', () {
      var p = 0.6;
      for (var i = 0; i < 100; i++) {
        p = updateProficiency(p, correct: false);
      }
      expect(p, lessThan(0.01));
    });
  });

  group('initialProficiency', () {
    test('at the player grade → 0.4 (challenging band)', () {
      expect(initialProficiency(0, 0), 0.4);
      expect(initialProficiency(2, 2), 0.4);
      expect(initialProficiency(8, 8), 0.4);
    });

    test('1 grade below player → 0.7 (comfortable band)', () {
      expect(initialProficiency(1, 2), 0.7);
      expect(initialProficiency(7, 8), 0.7);
    });

    test('≥2 grades below player → 0.95 (mastered band)', () {
      expect(initialProficiency(0, 2), 0.95);
      expect(initialProficiency(1, 5), 0.95);
      expect(initialProficiency(0, 8), 0.95);
    });

    test('above player grade → 0.05 (notYet band)', () {
      expect(initialProficiency(3, 2), 0.05);
      expect(initialProficiency(4, 1), 0.05);
      expect(initialProficiency(8, 0), 0.05);
    });

    test('initial values map to expected bands', () {
      expect(bandForProficiency(0.4), ProficiencyBand.challenging);
      expect(bandForProficiency(0.7), ProficiencyBand.comfortable);
      expect(bandForProficiency(0.95), ProficiencyBand.mastered);
      expect(bandForProficiency(0.05), ProficiencyBand.notYet);
    });
  });
}
