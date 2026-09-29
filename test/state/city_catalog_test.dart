import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/construction_sites.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/state/city_provider.dart';
import 'package:math_city/state/player_provider.dart';

Future<ProviderContainer> _container(AppDatabase db, int pid) async {
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
  container.read(activePlayerIdProvider.notifier).selected = pid;
  await container.read(activePlayerProvider.future);
  return container;
}

Future<(AppDatabase, Player)> _playerWithMayor() async {
  final db = AppDatabase(NativeDatabase.memory());
  final player = await db.createPlayer(
    name: 'Sam',
    gradeLevel: 2,
    avatarConfigJson: '{}',
  );
  final city = await db.cityForPlayer(player.id);
  await db.placeBuilding(
    cityId: city.id,
    playerId: player.id,
    buildingTypeId: 'mayors_office',
    gridX: 5,
    gridY: 5,
  );
  return (db, player);
}

void main() {
  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('cityCatalogProvider', () {
    test(
      'a fresh player has an empty catalog: the office is already placed',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final player = await db.createPlayer(
          name: 'Sam',
          gradeLevel: 2,
          avatarConfigJson: '{}',
        );
        final container = await _container(db, player.id);
        addTearDown(container.dispose);

        final catalog = await container.read(cityCatalogProvider.future);
        expect(catalog, isEmpty);
      },
    );

    test('the debug unlock-all switch shows the whole registry', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final player = await db.createPlayer(
        name: 'Sam',
        gradeLevel: 2,
        avatarConfigJson: '{}',
      );
      final container = await _container(db, player.id);
      addTearDown(container.dispose);

      container.read(debugUnlockAllProvider.notifier).set(on: true);
      final all = await container.read(cityCatalogProvider.future);
      // Everything except the placed office (unique) and the upgrade-only
      // civic rungs, which never get a card.
      expect(all.map((b) => b.id), isNot(contains('mayors_office')));
      expect(all.map((b) => b.id), isNot(contains('town_hall')));
      expect(all.length, buildingRegistry.length - 3);

      container.read(debugUnlockAllProvider.notifier).set(on: false);
      final back = await container.read(cityCatalogProvider.future);
      expect(back, isEmpty);
    });

    test(
      'placing the mayor alone does not unlock the gated buildings',
      () async {
        final (db, player) = await _playerWithMayor();
        final container = await _container(db, player.id);
        addTearDown(container.dispose);

        // No demand letter has arrived yet, so nothing shows (the placed
        // mayor's office is unique and has no card).
        final catalog = await container.read(cityCatalogProvider.future);
        expect(catalog, isEmpty);
      },
    );

    test(
      "a demand letter's arrival reveals just that building, buildable at once",
      () async {
        final (db, player) = await _playerWithMayor();
        // The first-home demand fires: arrival is the gate, no read needed.
        await db.recordBeatFired(player.id, 'demand_first_home', 0);

        final container = await _container(db, player.id);
        addTearDown(container.dispose);

        final catalog = await container.read(cityCatalogProvider.future);
        expect(catalog.map((b) => b.id), ['single_home']);
        // No research step: the card carries its coin price directly.
        expect(catalog.last.coinCost, 60);
      },
    );

    test('a lifetime-coins gate holds the card back until it is met', () async {
      final (db, player) = await _playerWithMayor();
      final city = await db.cityForPlayer(player.id);
      // high_rise needs mid_rise_apartment + pop≥60 + 1 h of lifetime study
      // + its demand read. Satisfy everything except the coins.
      await db.placeBuilding(
        cityId: city.id,
        playerId: player.id,
        buildingTypeId: 'mid_rise_apartment',
        gridX: 1,
        gridY: 1,
      );
      await db.setCityPopulation(city.id, 100);
      await db.recordBeatFired(player.id, 'demand_high_rise', 0);
      await db.markBeatRead(player.id, 'demand_high_rise', 0);

      final container = await _container(db, player.id);
      addTearDown(container.dispose);

      var catalog = await container.read(cityCatalogProvider.future);
      expect(catalog.map((b) => b.id), isNot(contains('high_rise')));

      await db.addLifetimeCoins(player.id, 3600);
      container.invalidate(activePlayerProvider);
      catalog = await container.read(cityCatalogProvider.future);
      expect(catalog.map((b) => b.id), contains('high_rise'));
    });
  });

  group('upgrades (city_builder.md §10.6)', () {
    test('an office grown into a town hall gets no office card back', () async {
      final (db, player) = await _playerWithMayor();
      final city = await db.cityForPlayer(player.id);
      // Opening a town-hall upgrade removes the office; mimic that.
      final officeIds = (await db.placementsForCity(city.id))
          .where((p) => p.buildingTypeId == 'mayors_office')
          .map((p) => p.id)
          .toList();
      final siteId = await db.startBuildingSite(
        cityId: city.id,
        playerId: player.id,
        buildingTypeId: 'town_hall',
        gridX: 5,
        gridY: 5,
        upgradesFromPlacementId: officeIds.first,
      );
      await db.openSite(siteId, playerId: player.id);
      final container = await _container(db, player.id);
      addTearDown(container.dispose);
      final catalog = await container.read(cityCatalogProvider.future);
      expect(catalog.map((b) => b.id), isNot(contains('mayors_office')));
    });

    test('upgrade-only rungs never get a card', () async {
      final (db, player) = await _playerWithMayor();
      final city = await db.cityForPlayer(player.id);
      await db.placeBuilding(
        cityId: city.id,
        playerId: player.id,
        buildingTypeId: 'single_home',
        gridX: 5,
        gridY: 5,
      );
      await db.setCityPopulation(city.id, 50);
      await db.recordBeatFired(player.id, 'demand_town_hall', 0);
      final container = await _container(db, player.id);
      addTearDown(container.dispose);
      final catalog = await container.read(cityCatalogProvider.future);
      expect(catalog.map((b) => b.id), isNot(contains('town_hall')));
    });

    test(
      'upgradeSourcesFor lists the rung below, oldest first, not growing',
      () async {
        final (db, player) = await _playerWithMayor();
        final city = await db.cityForPlayer(player.id);
        Future<int> home(int x) async {
          final id = await db.placeBuilding(
            cityId: city.id,
            playerId: player.id,
            buildingTypeId: 'single_home',
            gridX: x,
            gridY: 5,
          );
          await db.incrementRoundsPlayed(player.id);
          return id;
        }

        final first = await home(4);
        final second = await home(6);
        final third = await home(8);
        // The second home is already growing into a duplex.
        await db.startBuildingSite(
          cityId: city.id,
          playerId: player.id,
          buildingTypeId: 'duplex',
          gridX: 6,
          gridY: 8,
          upgradesFromPlacementId: second,
        );
        final placements = await db.placementsForCity(city.id);
        final sites = sitesFromRows(await db.sitesForCity(city.id), placements);
        final sources = upgradeSourcesFor('duplex', placements, sites);
        expect(sources.map((p) => p.id), [first, third]);
        expect(upgradeSourcesFor('apartment', placements, sites), isEmpty);
        final offices = upgradeSourcesFor('town_hall', placements, sites);
        expect(offices, isNotEmpty);
        expect(
          offices.every((p) => p.buildingTypeId == 'mayors_office'),
          isTrue,
        );
      },
    );
  });
}
