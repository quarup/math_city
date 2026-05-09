import 'package:drift/drift.dart' hide isNull, isNotNull;
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
        // First DAG child of add_within_5 should be add_within_10.
        expect(unlock.newConcept.id, 'add_within_10');

        // The newly-unlocked concept is now persisted as introduced.
        final introduced = await db.introducedConceptIdsForPlayer(pid);
        expect(introduced, contains('add_within_10'));
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

        // No new concept introduced (only the starter pack).
        final introduced = await db.introducedConceptIdsForPlayer(pid);
        expect(introduced, isNot(contains('add_within_10')));
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
      'a fresh player gets two introduced concepts on first read',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final pid = await _seedPlayer(db);

        final container = await _setupContainer(db, pid);
        addTearDown(container.dispose);

        final introduced = await container.read(
          introducedConceptsProvider.future,
        );
        expect(introduced, hasLength(2));
        expect(introduced, contains('add_within_5'));
        expect(introduced, contains('sub_within_5'));

        // Persisted to DB.
        final persisted = await db.introducedConceptIdsForPlayer(pid);
        expect(persisted, hasLength(2));
      },
    );
  });
}

// Suppress unused-import warning when only one symbol is referenced.
// ignore: unused_element
const _x = Value<int>(0);
