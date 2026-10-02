import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/concepts/concept_registry.dart';
import 'package:math_city/domain/concepts/dag_engine.dart';
import 'package:math_city/domain/economy/question_block.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';
import 'package:math_city/domain/questions/generated_question.dart';

void main() {
  QuestionBlock block({int size = 3}) => QuestionBlock(
    conceptId: 'add_within_10',
    band: ProficiencyBand.challenging,
    size: size,
  );

  group('QuestionBlock', () {
    test('starts empty and counts up to completion', () {
      final b = block();
      expect(b.answered, 0);
      expect(b.remaining, 3);
      expect(b.currentIndex, 1);
      expect(b.isComplete, isFalse);
      expect(b.streakCount, isNull);

      b.record(const AnswerReward(correct: true, coins: 1, streakCount: 1));
      expect(b.answered, 1);
      expect(b.currentIndex, 2);
      b
        ..record(const AnswerReward(correct: false, coins: 0, streakCount: 0))
        ..record(const AnswerReward(correct: true, coins: 1, streakCount: 1));
      expect(b.isComplete, isTrue);
      expect(b.remaining, 0);
      expect(b.correctCount, 2);
      expect(b.streakCount, 1);
    });

    test('tallies answer coins, bonuses, and the total separately', () {
      final b = block()
        ..record(const AnswerReward(correct: true, coins: 4, streakCount: 1))
        ..record(
          const AnswerReward(
            correct: true,
            coins: 8,
            streakCount: 2,
            bandBonuses: [
              BandCrossingBonus(
                conceptId: 'add_within_10',
                band: ProficiencyBand.comfortable,
                coins: 10,
              ),
            ],
          ),
        );
      expect(b.answerCoins, 12);
      expect(b.bonusCoins, 10);
      expect(b.coinsEarned, 22);
      expect(b.bandBonuses, hasLength(1));
      expect(b.bandBonuses.single.band, ProficiencyBand.comfortable);
    });

    test('collects drip-feed unlocks', () {
      final b = block();
      final next = findConceptById('add_within_20')!;
      b
        ..record(
          AnswerReward(
            correct: true,
            coins: 5,
            streakCount: 5,
            unlocks: [UnlockEvent(newConcept: next)],
          ),
        )
        ..record(const AnswerReward(correct: true, coins: 5, streakCount: 5));
      expect(b.unlocks.map((u) => u.newConcept.id), ['add_within_20']);
    });

    test('AnswerReward.totalCoins folds in the bonus', () {
      const r = AnswerReward(
        correct: true,
        coins: 3,
        streakCount: 2,
        bandBonuses: [
          BandCrossingBonus(
            conceptId: 'x',
            band: ProficiencyBand.mastered,
            coins: 20,
          ),
        ],
      );
      expect(r.bonusCoins, 20);
      expect(r.totalCoins, 23);
    });

    test('refuses a size below one', () {
      expect(() => block(size: 0), throwsA(isA<AssertionError>()));
    });
  });

  group('unique questions', () {
    GeneratedQuestion q(String prompt, String answer) => GeneratedQuestion(
      conceptId: 'add_within_5',
      prompt: prompt,
      correctAnswer: answer,
      distractors: const ['9', '8', '7'],
      explanation: const [],
    );
    QuestionBlock block(int size) => QuestionBlock(
      conceptId: 'add_within_5',
      band: ProficiencyBand.challenging,
      size: size,
    );
    const right = AnswerReward(correct: true, coins: 1, streakCount: 1);

    test('never hands out the same prompt and answer twice', () {
      final b = block(3);
      final pool = [
        q('1 + 1 = ?', '2'),
        q('1 + 1 = ?', '2'),
        q('2 + 1 = ?', '3'),
      ];
      var i = 0;
      expect(b.drawUnique(() => pool[i++ % 3])!.prompt, '1 + 1 = ?');
      expect(b.drawUnique(() => pool[i++ % 3])!.prompt, '2 + 1 = ?');
    });

    test('a repeated prompt with a different answer is a new question', () {
      final b = block(2);
      expect(
        b.drawUnique(() => q('What fraction is shaded?', '1/2')),
        isNotNull,
      );
      expect(
        b.drawUnique(() => q('What fraction is shaded?', '1/3')),
        isNotNull,
      );
    });

    test('runs out → null, and endEarly shortens the block to complete', () {
      final b = block(4);
      final only = q('1 + 1 = ?', '2');
      expect(b.drawUnique(() => only), isNotNull);
      b.record(right);
      expect(b.drawUnique(() => only), isNull);
      b.endEarly();
      expect(b.size, 1);
      expect(b.isComplete, isTrue);
      expect(b.isOver, isTrue);
    });
  });
}
