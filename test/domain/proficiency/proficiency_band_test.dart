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

  group('isRetiredFromWheel', () {
    test('two grades below and comfortable → retired', () {
      expect(
        isRetiredFromWheel(
          conceptGrade: 1,
          playerGrade: 3,
          band: ProficiencyBand.comfortable,
        ),
        isTrue,
      );
    });

    test('far below and mastered → retired too', () {
      expect(
        isRetiredFromWheel(
          conceptGrade: 0,
          playerGrade: 5,
          band: ProficiencyBand.mastered,
        ),
        isTrue,
      );
    });

    test('two grades below but still challenging → stays (shaky old material '
        'resurfaces)', () {
      expect(
        isRetiredFromWheel(
          conceptGrade: 1,
          playerGrade: 3,
          band: ProficiencyBand.challenging,
        ),
        isFalse,
      );
    });

    test('only one grade below → stays even when comfortable', () {
      expect(
        isRetiredFromWheel(
          conceptGrade: 2,
          playerGrade: 3,
          band: ProficiencyBand.comfortable,
        ),
        isFalse,
      );
    });

    test('at or above grade → never retired', () {
      for (final band in ProficiencyBand.values) {
        expect(
          isRetiredFromWheel(conceptGrade: 3, playerGrade: 3, band: band),
          isFalse,
        );
        expect(
          isRetiredFromWheel(conceptGrade: 4, playerGrade: 3, band: band),
          isFalse,
        );
      }
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

  group('keypadUnlocked', () {
    bool unlocked({
      ProficiencyBand band = ProficiencyBand.comfortable,
      int correct = kCorrectAnswersBeforeKeypad,
      int rounds = kKeypadWarmUpRounds,
    }) => keypadUnlocked(
      band: band,
      correctAnswers: correct,
      roundsPlayed: rounds,
    );

    test('comfortable, proven in MC, past the warm-up → keypad', () {
      expect(unlocked(), isTrue);
    });

    test('a concept that starts comfortable still needs MC answers first', () {
      expect(
        bandForProficiency(initialProficiency(1, 2)),
        ProficiencyBand.comfortable,
      );
      expect(unlocked(correct: 0), isFalse);
      expect(unlocked(correct: kCorrectAnswersBeforeKeypad - 1), isFalse);
    });

    test('nothing is typed during the opening warm-up', () {
      expect(unlocked(correct: 100, rounds: 0), isFalse);
      expect(unlocked(correct: 100, rounds: kKeypadWarmUpRounds - 1), isFalse);
    });

    test('only the comfortable band types', () {
      for (final band in [
        ProficiencyBand.notYet,
        ProficiencyBand.challenging,
        ProficiencyBand.mastered,
      ]) {
        expect(unlocked(band: band, correct: 100, rounds: 1000), isFalse);
      }
    });
  });
}
