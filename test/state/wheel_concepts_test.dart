import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/state/player_provider.dart';
import 'package:math_city/state/proficiency_provider.dart';

const _allCatalogIds = [
  'add_within_5',
  'sub_within_5',
  'add_within_10',
  'sub_within_10',
  'add_within_20',
  'sub_within_20',
  'add_within_100',
  'sub_within_100',
  'add_2digit_carry',
  'sub_2digit_borrow',
  'add_within_1000',
  'sub_within_1000',
  'add_multidigit_standard_alg',
  'sub_multidigit_standard_alg',
  'mult_facts_within_100',
  'div_facts_within_100',
  'fraction_a_over_b',
  'compare_fractions_same_denom',
  'equivalent_fractions_visual',
  'add_fractions_like_denom',
  'time_to_hour_half',
  'time_to_5_min',
];

Future<int> _seedFrontierPlayer(AppDatabase db) async {
  // Grade-1 player: K (1 below = comfortable) + G1 (at-grade = challenging)
  // gives ≥4 implemented frontier concepts so the starter pack reaches its
  // default size of 4. Tests 2 and 3 below override proficiency directly,
  // so they don't depend on the player's grade.
  final p = await db.createPlayer(
    name: 'frontier_tester',
    gradeLevel: 1,
    avatarConfigJson: '{}',
  );
  return p.id;
}

Future<ProviderContainer> _setupContainer(AppDatabase db, int playerId) async {
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
  container.read(activePlayerIdProvider.notifier).selected = playerId;
  await container.read(activePlayerProvider.future);
  return container;
}

void main() {
  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('wheelConceptsProvider', () {
    test('starter wheel has 4 concepts for a fresh player', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final pid = await _seedFrontierPlayer(db);

      final container = await _setupContainer(db, pid);
      addTearDown(container.dispose);

      final wheel = await container.read(wheelConceptsProvider.future);
      expect(wheel, hasLength(4));
    });

    test(
      'wheel caps at 8 segments and surfaces a different sample over rounds',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final pid = await _seedFrontierPlayer(db);

        // Manually seed 12 introduced concepts, all in the challenging band
        // (proficiency = 0.4) so they all qualify.
        for (final id in _allCatalogIds.take(12)) {
          await db.introduceConcept(pid, id);
          await db.upsertProficiency(pid, id, 0.4, correct: true);
        }

        final container = await _setupContainer(db, pid);
        addTearDown(container.dispose);

        // Read wheel many times; collect the sets we see.
        final samples = <Set<String>>{};
        for (var i = 0; i < 30; i++) {
          // Force the provider to re-evaluate by cycling proficiency on a
          // single concept (simulates "answered a round").
          await db.upsertProficiency(
            pid,
            'add_within_5',
            0.4 + (i % 2) * 0.001,
            correct: true,
          );
          container.invalidate(proficiencyProvider);
          final wheel = await container.read(wheelConceptsProvider.future);
          expect(wheel, hasLength(8));
          samples.add(wheel.map((c) => c.id).toSet());
        }

        // With 12 candidates and an 8-cap, we should see at least 2
        // distinct samples across 30 reads (probability of always picking
        // the same 8 by chance is astronomically low).
        expect(
          samples.length,
          greaterThan(1),
          reason: 'wheel should random-sample when count > kMaxWheelSegments',
        );
      },
    );

    test('wheel surfaces all eligible when count is between 4 and 8', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final pid = await _seedFrontierPlayer(db);

      // Introduce 6 concepts (between min=4 and max=8).
      for (final id in _allCatalogIds.take(6)) {
        await db.introduceConcept(pid, id);
        await db.upsertProficiency(pid, id, 0.4, correct: true);
      }

      final container = await _setupContainer(db, pid);
      addTearDown(container.dispose);

      final wheel = await container.read(wheelConceptsProvider.future);
      expect(wheel, hasLength(6));
    });
  });
}

// Suppress unused-import warning for the broad `drift/drift.dart` import.
// ignore: unused_element
const _x = Value<int>(0);
