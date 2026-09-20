import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/concepts/wheel_selection.dart';
import 'package:math_city/state/introduced_concepts_provider.dart';
import 'package:math_city/state/player_provider.dart';
import 'package:math_city/state/proficiency_provider.dart';

Future<int> _seedPlayer(AppDatabase db) async {
  // Grade-K player so K-grade starter-pack expectations below stay valid
  // under graded-init proficiency (G0 concepts at challenging band, not
  // already-mastered).
  final p = await db.createPlayer(
    name: 'tester',
    gradeLevel: 0,
    avatarConfigJson: '{}',
  );
  return p.id;
}

Future<ProviderContainer> _setupContainer(AppDatabase db, int playerId) async {
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
  container.read(activePlayerIdProvider.notifier).selected = playerId;
  // Wait for activePlayerProvider to resolve.
  await container.read(activePlayerProvider.future);
  // Trigger the introduced-concepts starter-pack init.
  await container.read(introducedConceptsProvider.future);
  return container;
}

void main() {
  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('Proficiency answer + drip-feed unlock', () {
    test(
      'correct answer crossing mastery triggers UnlockEvent',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final pid = await _seedPlayer(db);

        // Seed proficiency for add_within_5 just below mastery (0.84).
        // After one correct answer (α=0.1, target=1) it becomes
        // 0.84 + 0.1 * (1 - 0.84) = 0.856 → mastered.
        await db.upsertProficiency(pid, 'add_within_5', 0.84, correct: true);

        final container = await _setupContainer(db, pid);
        addTearDown(container.dispose);
        // Force the proficiency provider to load the seeded value.
        await container.read(proficiencyProvider.future);

        final unlocks =
            (await container
                    .read(proficiencyProvider.notifier)
                    .recordAnswer(
                      'add_within_5',
                      correct: true,
                      usesKeypad: false,
                    ))
                .unlocks;

        // The starter pack filled the active frontier to kActivePoolTarget;
        // mastering one concept leaves it one short, so the top-up
        // introduces exactly one new K concept, credited to the mastery.
        expect(unlocks, hasLength(1));
        final unlock = unlocks.single;
        expect(unlock.masteredConcept?.id, 'add_within_5');
        expect(unlock.newConcept.primaryGrade, 0);

        // The newly-unlocked concept is now persisted as introduced.
        final introduced = await db.introducedConceptIdsForPlayer(pid);
        expect(introduced, contains(unlock.newConcept.id));
        expect(introduced, hasLength(kActivePoolTarget + 1));
      },
    );

    test(
      'wrong answer never returns an UnlockEvent — even at 0.84 proficiency',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final pid = await _seedPlayer(db);
        await db.upsertProficiency(pid, 'add_within_5', 0.84, correct: true);

        final container = await _setupContainer(db, pid);
        addTearDown(container.dispose);
        await container.read(proficiencyProvider.future);

        final unlocks =
            (await container
                    .read(proficiencyProvider.notifier)
                    .recordAnswer(
                      'add_within_5',
                      correct: false,
                      usesKeypad: false,
                    ))
                .unlocks;

        expect(unlocks, isEmpty);

        // No new concept introduced beyond the starter pack.
        final introduced = await db.introducedConceptIdsForPlayer(pid);
        expect(introduced, hasLength(kActivePoolTarget));
      },
    );

    test(
      'correct answer that does not cross mastery returns no event',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final pid = await _seedPlayer(db);
        // Way below mastery.
        await db.upsertProficiency(pid, 'add_within_5', 0.5, correct: true);

        final container = await _setupContainer(db, pid);
        addTearDown(container.dispose);
        await container.read(proficiencyProvider.future);

        final unlocks =
            (await container
                    .read(proficiencyProvider.notifier)
                    .recordAnswer(
                      'add_within_5',
                      correct: true,
                      usesKeypad: false,
                    ))
                .unlocks;

        expect(unlocks, isEmpty);
      },
    );

    test(
      'a correct answer on an already-mastered concept refills a short pool '
      'without crediting a mastery',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final pid = await _seedPlayer(db);
        // Already mastered.
        await db.upsertProficiency(pid, 'add_within_5', 0.92, correct: true);

        final container = await _setupContainer(db, pid);
        addTearDown(container.dispose);
        await container.read(proficiencyProvider.future);

        final unlocks =
            (await container
                    .read(proficiencyProvider.notifier)
                    .recordAnswer(
                      'add_within_5',
                      correct: true,
                      usesKeypad: false,
                    ))
                .unlocks;

        // The seeded mastery left the frontier one short of the target (no
        // top-up ran when it was seeded), so this answer refills it — but no
        // band was crossed, so nothing is credited as "mastered".
        expect(unlocks, hasLength(1));
        expect(unlocks.single.masteredConcept, isNull);
      },
    );
  });

  group('Starter pack', () {
    test(
      'a fresh player gets a full active pool on first read',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final pid = await _seedPlayer(db);

        final container = await _setupContainer(db, pid);
        addTearDown(container.dispose);

        final introduced = await container.read(
          introducedConceptsProvider.future,
        );
        expect(introduced, hasLength(kActivePoolTarget));
        // Starter pack pulls the easiest implemented G0 concepts sorted by
        // (grade, categoryRowOrder); the four row-0 roots below lead it.
        expect(
          introduced,
          containsAll([
            'count_to_10',
            'teen_numbers_as_ten_plus',
            'add_within_5',
            'describe_attribute',
          ]),
        );

        // Persisted to DB.
        final persisted = await db.introducedConceptIdsForPlayer(pid);
        expect(persisted, hasLength(kActivePoolTarget));
      },
    );
  });

  group('resetSkillsForPlayer', () {
    test(
      'wipes proficiency + introduced rows; next read re-seeds starter pack',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final pid = await _seedPlayer(db);

        // Build initial state: starter pack + a recorded proficiency.
        final container = await _setupContainer(db, pid);
        addTearDown(container.dispose);
        await container.read(introducedConceptsProvider.future);
        await db.upsertProficiency(pid, 'add_within_5', 0.92, correct: true);

        expect(
          await db.introducedConceptIdsForPlayer(pid),
          hasLength(kActivePoolTarget),
        );
        expect(
          (await db.proficiencyMapForPlayer(pid)).keys,
          contains('add_within_5'),
        );

        await db.resetSkillsForPlayer(pid);

        expect(await db.introducedConceptIdsForPlayer(pid), isEmpty);
        expect(await db.proficiencyMapForPlayer(pid), isEmpty);

        // Reading the provider again re-seeds the starter pack (DAG drip-
        // feed bootstraps from empty introduced).
        container
          ..invalidate(introducedConceptsProvider)
          ..invalidate(proficiencyProvider);
        final reseeded = await container.read(
          introducedConceptsProvider.future,
        );
        expect(reseeded, hasLength(kActivePoolTarget));
      },
    );

    test('does not touch player bricks or avatar', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final pid = await _seedPlayer(db);
      await db.setLifetimeCoins(pid, 99);

      await db.resetSkillsForPlayer(pid);

      final p = await db.getPlayerById(pid);
      expect(p.lifetimeCoinsEarned, 99);
    });
  });
}

// Suppress unused-import warning when only one symbol is referenced.
// ignore: unused_element
const _x = Value<int>(0);
