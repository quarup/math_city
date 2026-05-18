import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';
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

        final unlock = await container
            .read(proficiencyProvider.notifier)
            .recordAnswer('add_within_5', correct: true);

        expect(unlock, isNotNull);
        expect(unlock!.masteredConcept?.id, 'add_within_5');
        // After Chunk 64 the starter pack is {count_to_10,
        // teen_numbers_as_ten_plus, add_within_5, describe_attribute} —
        // counting, place_value, add_sub, and measurement each
        // contribute a row-0 G0 concept. Mastering add_within_5 makes
        // both sub_within_5 and add_within_10 eligible (each has
        // add_within_5 as its sole prereq). The active-category
        // tiebreak prefers add_sub (now at 0 active concepts post-
        // mastery) over the other three (each at >=1 active); within
        // add_sub the lowest row order wins, so the pick is
        // sub_within_5.
        expect(unlock.newConcept.id, 'sub_within_5');

        // The newly-unlocked concept is now persisted as introduced.
        final introduced = await db.introducedConceptIdsForPlayer(pid);
        expect(introduced, contains('sub_within_5'));
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

        final unlock = await container
            .read(proficiencyProvider.notifier)
            .recordAnswer('add_within_5', correct: false);

        expect(unlock, isNull);

        // No new concept introduced beyond the 4-concept starter pack.
        final introduced = await db.introducedConceptIdsForPlayer(pid);
        expect(introduced, hasLength(4));
        expect(introduced, isNot(contains('sub_within_5')));
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

        final unlock = await container
            .read(proficiencyProvider.notifier)
            .recordAnswer('add_within_5', correct: true);

        expect(unlock, isNull);
      },
    );

    test(
      'second correct answer once already-mastered returns no event',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final pid = await _seedPlayer(db);
        // Already mastered.
        await db.upsertProficiency(pid, 'add_within_5', 0.92, correct: true);

        final container = await _setupContainer(db, pid);
        addTearDown(container.dispose);
        await container.read(proficiencyProvider.future);

        final unlock = await container
            .read(proficiencyProvider.notifier)
            .recordAnswer('add_within_5', correct: true);

        // Already mastered before this answer → no unlock event fires.
        expect(unlock, isNull);
      },
    );
  });

  group('Starter pack', () {
    test(
      'a fresh player gets four introduced concepts on first read',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final pid = await _seedPlayer(db);

        final container = await _setupContainer(db, pid);
        addTearDown(container.dispose);

        final introduced = await container.read(
          introducedConceptsProvider.future,
        );
        expect(introduced, hasLength(4));
        // Starter pack pulls the four easiest implemented G0 concepts
        // sorted by (grade, categoryRowOrder). After Chunk 64, six
        // categories ship a row-0 G0 concept; the first four wins by
        // category display order: counting (count_to_10), place_value
        // (teen_numbers_as_ten_plus), add_sub (add_within_5),
        // measurement (describe_attribute). The 5th and 6th K-grade
        // roots — geometry (identify_shape_2d) and stats
        // (classify_count_categories) — get pushed out and drip-feed
        // later via the DAG engine.
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
        expect(persisted, hasLength(4));
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

        expect(await db.introducedConceptIdsForPlayer(pid), hasLength(4));
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
        expect(reseeded, hasLength(4));
      },
    );

    test('does not touch player stars or avatar', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final pid = await _seedPlayer(db);
      await db.updatePlayerStars(
        pid,
        currentStars: 42,
        lifetimeStarsEarned: 99,
      );

      await db.resetSkillsForPlayer(pid);

      final p = await db.getPlayerById(pid);
      expect(p.currentStars, 42);
      expect(p.lifetimeStarsEarned, 99);
    });
  });
}

// Suppress unused-import warning when only one symbol is referenced.
// ignore: unused_element
const _x = Value<int>(0);
