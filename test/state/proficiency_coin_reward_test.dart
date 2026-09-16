import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/economy/coin_economy.dart';
import 'package:math_city/domain/economy/expected_seconds.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';
import 'package:math_city/state/introduced_concepts_provider.dart';
import 'package:math_city/state/player_provider.dart';
import 'package:math_city/state/proficiency_provider.dart';

Future<int> _seedPlayer(AppDatabase db) async {
  final p = await db.createPlayer(
    name: 'tester',
    gradeLevel: 0,
    avatarConfigJson: '{}',
  );
  return p.id;
}

Future<ProviderContainer> _setupContainer(AppDatabase db, int pid) async {
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
  container.read(activePlayerIdProvider.notifier).selected = pid;
  await container.read(activePlayerProvider.future);
  await container.read(introducedConceptsProvider.future);
  await container.read(proficiencyProvider.future);
  return container;
}

void main() {
  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  const concept = 'add_within_5';
  final seconds = expectedSecondsFor(concept);

  group('recordAnswer pays coins and moves the streak', () {
    test(
      'first correct answer of a fresh player pays at streak level 1',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final pid = await _seedPlayer(db);
        final container = await _setupContainer(db, pid);
        addTearDown(container.dispose);

        final reward = await container
            .read(proficiencyProvider.notifier)
            .recordAnswer(concept, correct: true, usesKeypad: false);

        expect(reward.correct, isTrue);
        expect(reward.streakCount, 1);
        expect(
          reward.coins,
          coinsForCorrectAnswer(
            expectedSeconds: seconds,
            usesKeypad: false,
            streakCount: 1,
          ),
        );
        expect(reward.bandBonuses, isEmpty);
        final player = await db.getPlayerById(pid);
        expect(player.streakCount, 1);
        expect(player.coinBalance, reward.coins);
        expect(player.lifetimeCoinsEarned, reward.coins);
      },
    );

    test('consecutive corrects climb the streak and the pay ramps', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final pid = await _seedPlayer(db);
      final container = await _setupContainer(db, pid);
      addTearDown(container.dispose);
      final notifier = container.read(proficiencyProvider.notifier);

      // Use a concept that can't cross a band in a few answers (p starts at
      // 0.4 for an at-grade concept; five corrects reach ~0.65 — that DOES
      // cross 0.5, so account for the bonus separately below).
      var totalAnswerCoins = 0;
      var bonus = 0;
      for (var i = 1; i <= 7; i++) {
        final r = await notifier.recordAnswer(
          concept,
          correct: true,
          usesKeypad: true,
        );
        expect(r.streakCount, i);
        expect(
          r.coins,
          coinsForCorrectAnswer(
            expectedSeconds: seconds,
            usesKeypad: true,
            streakCount: i,
          ),
        );
        totalAnswerCoins += r.coins;
        bonus += r.bonusCoins;
      }
      final player = await db.getPlayerById(pid);
      expect(player.streakCount, 7); // uncapped; pay capped from the 5th on
      expect(player.coinBalance, totalAnswerCoins + bonus);
    });

    test('a wrong answer pays nothing and resets the streak', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final pid = await _seedPlayer(db);
      await db.setPlayerStreakCount(pid, 4);
      await db.incrementPlayerCoins(pid, 100);
      final container = await _setupContainer(db, pid);
      addTearDown(container.dispose);

      final reward = await container
          .read(proficiencyProvider.notifier)
          .recordAnswer(concept, correct: false, usesKeypad: false);

      expect(reward.correct, isFalse);
      expect(reward.coins, 0);
      expect(reward.totalCoins, 0);
      expect(reward.streakCount, 0);
      final player = await db.getPlayerById(pid);
      expect(player.streakCount, 0);
      expect(player.coinBalance, 100);
    });

    test('the streak persists across sessions (containers)', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final pid = await _seedPlayer(db);
      final c1 = await _setupContainer(db, pid);
      await c1
          .read(proficiencyProvider.notifier)
          .recordAnswer(concept, correct: true, usesKeypad: false);
      await c1
          .read(proficiencyProvider.notifier)
          .recordAnswer(concept, correct: true, usesKeypad: false);
      c1.dispose();

      final c2 = await _setupContainer(db, pid);
      addTearDown(c2.dispose);
      final r = await c2
          .read(proficiencyProvider.notifier)
          .recordAnswer(concept, correct: true, usesKeypad: false);
      expect(r.streakCount, 3);
    });
  });

  group('band-crossing bonus', () {
    test('crossing p=0.5 the first time pays 2× expected seconds', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final pid = await _seedPlayer(db);
      // Seed p=0.47 BEFORE container setup so the provider's initial
      // build() picks it up. One correct answer (α=0.1) lands at
      // 0.47 + 0.1*(1-0.47) = 0.523 ≥ 0.5.
      await db.upsertProficiency(pid, concept, 0.47, correct: true);
      final container = await _setupContainer(db, pid);
      addTearDown(container.dispose);

      final reward = await container
          .read(proficiencyProvider.notifier)
          .recordAnswer(concept, correct: true, usesKeypad: false);

      expect(reward.bandBonuses, hasLength(1));
      final bonus = reward.bandBonuses.single;
      expect(bonus.conceptId, concept);
      expect(bonus.band, ProficiencyBand.comfortable);
      expect(bonus.coins, bandCrossingBonus(seconds));
      expect(reward.totalCoins, reward.coins + bonus.coins);

      final player = await db.getPlayerById(pid);
      expect(player.coinBalance, reward.totalCoins);
      expect(await db.awardedBandIndicesFor(pid, concept), {0});
    });

    test('no crossing, no bonus', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final pid = await _seedPlayer(db);
      // p=0.44 — one correct lands at 0.496, still below 0.5.
      await db.upsertProficiency(pid, concept, 0.44, correct: true);
      final container = await _setupContainer(db, pid);
      addTearDown(container.dispose);

      final reward = await container
          .read(proficiencyProvider.notifier)
          .recordAnswer(concept, correct: true, usesKeypad: false);

      expect(reward.bandBonuses, isEmpty);
      expect(await db.awardedBandIndicesFor(pid, concept), isEmpty);
    });

    test('re-crossing an already-paid band does NOT pay again', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final pid = await _seedPlayer(db);
      // Crossed 0.5 in a past session, dipped to 0.47, climbs back now.
      await db.recordBandMilestone(pid, concept, 0);
      await db.upsertProficiency(pid, concept, 0.47, correct: true);
      final container = await _setupContainer(db, pid);
      addTearDown(container.dispose);

      final reward = await container
          .read(proficiencyProvider.notifier)
          .recordAnswer(concept, correct: true, usesKeypad: false);

      expect(reward.bandBonuses, isEmpty);
      final player = await db.getPlayerById(pid);
      expect(player.coinBalance, reward.coins);
    });

    test('crossing mastery pays the bonus AND fires the drip-feed', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final pid = await _seedPlayer(db);
      // p=0.84 — one correct lands at 0.856 ≥ 0.85. Band 0 already paid.
      await db.recordBandMilestone(pid, concept, 0);
      await db.upsertProficiency(pid, concept, 0.84, correct: true);
      final container = await _setupContainer(db, pid);
      addTearDown(container.dispose);

      final reward = await container
          .read(proficiencyProvider.notifier)
          .recordAnswer(concept, correct: true, usesKeypad: false);

      expect(reward.bandBonuses.single.band, ProficiencyBand.mastered);
      expect(reward.unlocks, isNotEmpty);
      expect(await db.awardedBandIndicesFor(pid, concept), {0, 1});
    });

    test('a wrong answer never pays a bonus', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final pid = await _seedPlayer(db);
      await db.upsertProficiency(pid, concept, 0.51, correct: true);
      final container = await _setupContainer(db, pid);
      addTearDown(container.dispose);

      final reward = await container
          .read(proficiencyProvider.notifier)
          .recordAnswer(concept, correct: false, usesKeypad: false);

      expect(reward.bandBonuses, isEmpty);
      expect(await db.awardedBandIndicesFor(pid, concept), isEmpty);
    });
  });
}
