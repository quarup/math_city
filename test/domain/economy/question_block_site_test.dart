import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/construction_site.dart';
import 'package:math_city/domain/economy/question_block.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';

void main() {
  final home = findBuildingTypeById('single_home')!;
  ConstructionSite site(int paid) => ConstructionSite(
    goal: BuildingGoal(type: home, col: 0, row: 0),
    startedAtRound: 0,
    paidCoins: paid,
  );
  QuestionBlock block(int size) => QuestionBlock(
    conceptId: 'add_within_5',
    band: ProficiencyBand.comfortable,
    size: size,
  );

  test('no site payments → no site', () {
    final b = block(1)
      ..record(const AnswerReward(correct: true, coins: 5, streakCount: 1));
    expect(b.siteAfter, isNull);
    expect(b.siteCoins, 0);
    expect(b.siteOpened, isFalse);
  });

  test('tracks the site before and after the block', () {
    var s = site(20);
    final b = block(3);
    final r1 = s.payIn(10);
    s = r1.site;
    b
      ..record(
        AnswerReward(correct: true, coins: 10, streakCount: 1, sitePayIn: r1),
      )
      ..record(const AnswerReward(correct: false, coins: 0, streakCount: 0));
    final r2 = s.payIn(15);
    b.record(
      AnswerReward(correct: true, coins: 15, streakCount: 1, sitePayIn: r2),
    );

    expect(b.siteAfter!.paidCoins, 45);
    expect(b.siteCoins, 25);
    expect(b.sitePaidBefore, 20);
    expect(b.siteOpened, isFalse);
  });

  test('the block that fills the bar reports the site opened', () {
    final b = block(2);
    final r1 = site(50).payIn(8);
    b.record(
      AnswerReward(correct: true, coins: 8, streakCount: 1, sitePayIn: r1),
    );
    final r2 = r1.site.payIn(10); // 58 + 10 → capped at 60
    b.record(
      AnswerReward(correct: true, coins: 10, streakCount: 2, sitePayIn: r2),
    );
    expect(b.siteOpened, isTrue);
    expect(b.siteCoins, 10);
    expect(b.sitePaidBefore, 50);
    expect(b.siteAfter!.isFull, isTrue);
  });
}
