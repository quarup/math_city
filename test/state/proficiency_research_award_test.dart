import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';
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

  group('🔬 research awarded on band crossings', () {
    test('crossing p=0.5 the first time awards +1 🔬', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final pid = await _seedPlayer(db);

      // Seed p=0.47 BEFORE container setup so the provider's initial
      // build() picks it up. One correct answer (α=0.1) lands at
      // 0.47 + 0.1*(1-0.47) = 0.523 ≥ 0.5. Awards +1 🔬.
      await db.upsertProficiency(pid, 'add_within_5', 0.47, correct: true);

      final container = await _setupContainer(db, pid);
      addTearDown(container.dispose);

      await container
          .read(proficiencyProvider.notifier)
          .recordAnswer('add_within_5', correct: true);

      final player = await db.getPlayerById(pid);
      expect(player.researchBalance, 1);
      expect(player.lifetimeResearchEarned, 1);

      final awarded = await db.awardedBandIndicesFor(pid, 'add_within_5');
      expect(awarded, {0});
    });

    test(
      'correct answer that does NOT cross any threshold awards nothing',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final pid = await _seedPlayer(db);

        // Seed p=0.44 — one correct (α=0.1) lands at 0.496. Still below 0.5;
        // no crossing, no award.
        await db.upsertProficiency(pid, 'add_within_5', 0.44, correct: true);

        final container = await _setupContainer(db, pid);
        addTearDown(container.dispose);

        await container
            .read(proficiencyProvider.notifier)
            .recordAnswer('add_within_5', correct: true);

        final player = await db.getPlayerById(pid);
        expect(player.researchBalance, 0);
        expect(player.lifetimeResearchEarned, 0);
        expect(
          await db.awardedBandIndicesFor(pid, 'add_within_5'),
          isEmpty,
        );
      },
    );

    test('re-crossing an already-awarded band does NOT award again', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final pid = await _seedPlayer(db);

      // Pre-record band 0 milestone — player crossed 0.5 in a past
      // session. Now they've dipped back to 0.47 (still below 0.5) and
      // climb back across via one correct answer.
      await db.recordBandMilestone(pid, 'add_within_5', 0);
      await db.upsertProficiency(pid, 'add_within_5', 0.47, correct: true);

      final container = await _setupContainer(db, pid);
      addTearDown(container.dispose);

      await container
          .read(proficiencyProvider.notifier)
          .recordAnswer('add_within_5', correct: true);

      final player = await db.getPlayerById(pid);
      expect(player.researchBalance, 0);
      expect(player.lifetimeResearchEarned, 0);
    });

    test('crossing the upper (mastery) threshold awards +1 🔬', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final pid = await _seedPlayer(db);

      // Seed p=0.84 — one correct lands at 0.856 ≥ 0.85. Pre-mark band 0
      // as already awarded so the only NEW crossing is band 1.
      await db.recordBandMilestone(pid, 'add_within_5', 0);
      await db.upsertProficiency(pid, 'add_within_5', 0.84, correct: true);

      final container = await _setupContainer(db, pid);
      addTearDown(container.dispose);

      await container
          .read(proficiencyProvider.notifier)
          .recordAnswer('add_within_5', correct: true);

      final player = await db.getPlayerById(pid);
      expect(player.researchBalance, 1);
      expect(player.lifetimeResearchEarned, 1);
      expect(
        await db.awardedBandIndicesFor(pid, 'add_within_5'),
        {0, 1},
      );
    });

    // A single EMA step from any starting p can never cross both award
    // thresholds at once (gap 0.5→0.85 = 0.35 > max step 0.1·(1−0.5) =
    // 0.05). The multi-band path is covered exhaustively by the pure-Dart
    // `newlyCrossedBands` unit tests; not worth a contrived integration
    // case here.

    test('wrong-answer downward move does not award', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final pid = await _seedPlayer(db);

      // p=0.51 (already in comfortable band but never awarded because the
      // upsert bypassed the award path).
      await db.upsertProficiency(pid, 'add_within_5', 0.51, correct: true);

      final container = await _setupContainer(db, pid);
      addTearDown(container.dispose);

      // Wrong answer: 0.51 + 0.1*(0 - 0.51) = 0.459. Downward. No award.
      await container
          .read(proficiencyProvider.notifier)
          .recordAnswer('add_within_5', correct: false);

      final player = await db.getPlayerById(pid);
      expect(player.researchBalance, 0);
      expect(
        await db.awardedBandIndicesFor(pid, 'add_within_5'),
        isEmpty,
      );
    });
  });
}
