import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_dash/data/database.dart';
import 'package:math_dash/state/introduced_concepts_provider.dart';
import 'package:math_dash/state/player_provider.dart';
import 'package:math_dash/state/proficiency_provider.dart';

Future<int> _seedPlayer(AppDatabase db) async {
  final p = await db.createPlayer(
    name: 'tester',
    gradeLevel: 2,
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
        // The starter pack of 4 already includes all add_within_5's DAG
        // children (sub_within_5, add_within_10, sub_within_10), so the
        // drip-feed picks the lowest-grade root concept that *isn't* yet
        // introduced — `time_to_hour_half` (G1, no prereqs).
        expect(unlock.newConcept.id, 'time_to_hour_half');

        // The newly-unlocked concept is now persisted as introduced.
        final introduced = await db.introducedConceptIdsForPlayer(pid);
        expect(introduced, contains('time_to_hour_half'));
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
        expect(introduced, isNot(contains('time_to_hour_half')));
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
        expect(
          introduced,
          containsAll([
            'add_within_5',
            'sub_within_5',
            'add_within_10',
            'sub_within_10',
          ]),
        );

        // Persisted to DB.
        final persisted = await db.introducedConceptIdsForPlayer(pid);
        expect(persisted, hasLength(4));
      },
    );
  });
}

// Suppress unused-import warning when only one symbol is referenced.
// ignore: unused_element
const _x = Value<int>(0);
