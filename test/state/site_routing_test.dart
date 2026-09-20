import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/construction_site.dart';
import 'package:math_city/domain/city/land_blocks.dart';
import 'package:math_city/state/city_provider.dart';
import 'package:math_city/state/game_session_provider.dart';
import 'package:math_city/state/introduced_concepts_provider.dart';
import 'package:math_city/state/player_provider.dart';
import 'package:math_city/state/proficiency_provider.dart';

const _concept = 'add_within_5';

Future<(AppDatabase, int, ProviderContainer)> _setup() async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase(NativeDatabase.memory());
  final p = await db.createPlayer(
    name: 'tester',
    gradeLevel: 0,
    avatarConfigJson: '{}',
  );
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
  container.read(activePlayerIdProvider.notifier).selected = p.id;
  await container.read(activePlayerProvider.future);
  await container.read(introducedConceptsProvider.future);
  await container.read(proficiencyProvider.future);
  return (db, p.id, container);
}

Future<int> _startHome(ProviderContainer c, {int col = 0}) async {
  final home = findBuildingTypeById('single_home')!;
  final start = await c
      .read(cityActionsProvider)
      .startSite(BuildingGoal(type: home, col: col, row: 0));
  expect(start.ok, isTrue, reason: '${start.rejection}');
  return start.siteId!;
}

void main() {
  group('CityActions.startSite', () {
    test('a free goal opens on the spot — no site row', () async {
      final (db, pid, c) = await _setup();
      addTearDown(c.dispose);
      final mayor = findBuildingTypeById('mayors_office')!;
      final start = await c
          .read(cityActionsProvider)
          .startSite(BuildingGoal(type: mayor, col: 0, row: 0));
      expect(start.ok, isTrue);
      expect(start.siteId, isNull);
      expect(start.placementId, isNotNull);
      final city = await db.cityForPlayer(pid);
      expect(await db.sitesForCity(city.id), isEmpty);
      expect(
        (await db.placementsForCity(city.id)).single.buildingTypeId,
        'mayors_office',
      );
    });

    test('a fourth site is refused and the three are named', () async {
      final (_, _, c) = await _setup();
      addTearDown(c.dispose);
      for (var i = 0; i < kMaxOpenSites; i++) {
        await _startHome(c, col: i * 2);
      }
      final home = findBuildingTypeById('single_home')!;
      final start = await c
          .read(cityActionsProvider)
          .startSite(BuildingGoal(type: home, col: 8, row: 0));
      expect(start.ok, isFalse);
      expect(start.rejection, SiteStartRejection.tooManyOpenSites);
      expect(start.openSites, hasLength(3));
      expect(start.openSites.map((s) => s.name), everyElement('Single home'));
    });

    test('a land site opens into an owned block', () async {
      final (db, pid, c) = await _setup();
      addTearDown(c.dispose);
      final start = await c
          .read(cityActionsProvider)
          .startSite(const LandBlockGoal(blockX: 2, blockY: 0));
      expect(start.ok, isTrue);
      final result = await c
          .read(cityActionsProvider)
          .payIntoSite(start.siteId!, blockCost(2, 0));
      expect(result!.opened, isTrue);
      final owned = await c.read(ownedBlocksProvider.future);
      expect(owned.contains((2, 0)), isTrue);
      final city = await db.cityForPlayer(pid);
      expect(await db.sitesForCity(city.id), isEmpty);
    });

    test('an off-frontier block is refused', () async {
      final (_, _, c) = await _setup();
      addTearDown(c.dispose);
      final start = await c
          .read(cityActionsProvider)
          .startSite(const LandBlockGoal(blockX: 3, blockY: 3));
      expect(start.rejection, SiteStartRejection.blockNotPurchasable);
    });
  });

  group('recordAnswer routes coins into the active site', () {
    test('a correct answer pays the site and the lifetime counter', () async {
      final (db, pid, c) = await _setup();
      addTearDown(c.dispose);
      final siteId = await _startHome(c);
      c.read(activeSiteIdProvider.notifier).selected = siteId;

      final reward = await c
          .read(proficiencyProvider.notifier)
          .recordAnswer(_concept, correct: true, usesKeypad: false);

      expect(reward.sitePayIn, isNotNull);
      expect(reward.sitePayIn!.accepted, reward.totalCoins);
      expect(reward.sitePayIn!.opened, isFalse);
      final row = (await db.siteById(siteId))!;
      expect(row.paidCoins, reward.totalCoins);
      expect(
        (await db.getPlayerById(pid)).lifetimeCoinsEarned,
        reward.totalCoins,
      );
    });

    test('a wrong answer pays nothing into the site', () async {
      final (db, _, c) = await _setup();
      addTearDown(c.dispose);
      final siteId = await _startHome(c);
      await db.setSitePaidCoins(siteId, 30);
      c.read(activeSiteIdProvider.notifier).selected = siteId;

      final reward = await c
          .read(proficiencyProvider.notifier)
          .recordAnswer(_concept, correct: false, usesKeypad: false);

      expect(reward.sitePayIn, isNull);
      expect((await db.siteById(siteId))!.paidCoins, 30);
    });

    test(
      'with no active site the coins go nowhere but lifetime moves',
      () async {
        final (db, pid, c) = await _setup();
        addTearDown(c.dispose);
        final siteId = await _startHome(c);

        final reward = await c
            .read(proficiencyProvider.notifier)
            .recordAnswer(_concept, correct: true, usesKeypad: false);

        expect(reward.sitePayIn, isNull);
        expect((await db.siteById(siteId))!.paidCoins, 0);
        expect(
          (await db.getPlayerById(pid)).lifetimeCoinsEarned,
          reward.totalCoins,
        );
      },
    );

    test('the answer that fills the bar opens the building', () async {
      final (db, pid, c) = await _setup();
      addTearDown(c.dispose);
      final siteId = await _startHome(c);
      // One coin short: whatever the answer pays (≥ 1) opens it.
      await db.setSitePaidCoins(siteId, 59);
      c.read(activeSiteIdProvider.notifier).selected = siteId;

      final reward = await c
          .read(proficiencyProvider.notifier)
          .recordAnswer(_concept, correct: true, usesKeypad: false);

      expect(reward.sitePayIn!.opened, isTrue);
      expect(reward.sitePayIn!.accepted, 1);
      expect(reward.sitePayIn!.overflow, reward.totalCoins - 1);
      final city = await db.cityForPlayer(pid);
      expect(await db.sitesForCity(city.id), isEmpty);
      expect(
        (await db.placementsForCity(city.id)).single.buildingTypeId,
        'single_home',
      );
      // Lifetime counts the whole reward, overflow included.
      expect(
        (await db.getPlayerById(pid)).lifetimeCoinsEarned,
        reward.totalCoins,
      );
      // The active id now points at nothing; the next answer pays no site.
      expect(await c.read(activeSiteProvider.future), isNull);
      final next = await c
          .read(proficiencyProvider.notifier)
          .recordAnswer(_concept, correct: true, usesKeypad: false);
      expect(next.sitePayIn, isNull);
    });

    test(
      'three open sites survive a new container with coins intact',
      () async {
        final (db, pid, c1) = await _setup();
        final ids = [
          for (var i = 0; i < 3; i++) await _startHome(c1, col: i * 2),
        ];
        for (final (i, id) in ids.indexed) {
          await c1.read(cityActionsProvider).payIntoSite(id, 10 * (i + 1));
        }
        c1.dispose();

        final c2 = ProviderContainer(
          overrides: [appDatabaseProvider.overrideWithValue(db)],
        );
        addTearDown(c2.dispose);
        c2.read(activePlayerIdProvider.notifier).selected = pid;
        final sites = await c2.read(sitesProvider.future);
        expect(sites.map((s) => s.site.paidCoins), [10, 20, 30]);
      },
    );
  });
}
