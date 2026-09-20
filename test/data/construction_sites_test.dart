import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/construction_sites.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/city/construction_site.dart';

void main() {
  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  Future<(AppDatabase, Player, City)> freshCity() async {
    final db = AppDatabase(NativeDatabase.memory());
    final player = await db.createPlayer(
      name: 'Pat',
      gradeLevel: 3,
      avatarConfigJson: '{}',
    );
    final city = await db.cityForPlayer(player.id);
    return (db, player, city);
  }

  group('building sites', () {
    test('start → row with no coins, stamped with the round clock', () async {
      final (db, player, city) = await freshCity();
      await db.incrementRoundsPlayed(player.id);
      final id = await db.startBuildingSite(
        cityId: city.id,
        playerId: player.id,
        buildingTypeId: 'single_home',
        gridX: 2,
        gridY: 3,
      );
      final rows = await db.sitesForCity(city.id);
      expect(rows.single.id, id);
      expect(rows.single.goalKind, 'building');
      expect(rows.single.paidCoins, 0);
      expect(rows.single.startedAtRound, 1);
      expect(await db.placementsForCity(city.id), isEmpty);
    });

    test('maps to the domain value with the registry price', () async {
      final (db, player, city) = await freshCity();
      await db.startBuildingSite(
        cityId: city.id,
        playerId: player.id,
        buildingTypeId: 'apartment',
        gridX: 2,
        gridY: 3,
      );
      await db.setSitePaidCoins((await db.sitesForCity(city.id)).single.id, 40);
      final sites = sitesFromRows(await db.sitesForCity(city.id), const []);
      final site = sites.single.site;
      expect(site.price, 120);
      expect(site.paidCoins, 40);
      expect(site.stage, 1);
      expect(sites.single.name, 'Apartment');
      final goal = site.goal as BuildingGoal;
      expect((goal.col, goal.row), (2, 3));
    });

    test('move keeps the coins', () async {
      final (db, player, city) = await freshCity();
      final id = await db.startBuildingSite(
        cityId: city.id,
        playerId: player.id,
        buildingTypeId: 'single_home',
        gridX: 0,
        gridY: 0,
      );
      await db.setSitePaidCoins(id, 30);
      await db.moveSite(siteId: id, gridX: 5, gridY: 6);
      final row = (await db.siteById(id))!;
      expect((row.gridX, row.gridY), (5, 6));
      expect(row.paidCoins, 30);
    });

    test('open → placement at the site anchor, row deleted', () async {
      final (db, player, city) = await freshCity();
      await db.incrementRoundsPlayed(player.id);
      final id = await db.startBuildingSite(
        cityId: city.id,
        playerId: player.id,
        buildingTypeId: 'single_home',
        gridX: 2,
        gridY: 3,
      );
      await db.incrementRoundsPlayed(player.id);
      final placementId = await db.openSite(id, playerId: player.id);
      final placed = (await db.placementsForCity(city.id)).single;
      expect(placed.id, placementId);
      expect(placed.buildingTypeId, 'single_home');
      expect((placed.gridX, placed.gridY), (2, 3));
      expect(placed.placedAtRound, 2);
      expect(await db.sitesForCity(city.id), isEmpty);
    });

    test(
      'an upgrade site prices the delta and removes its source on open',
      () async {
        final (db, player, city) = await freshCity();
        final homeId = await db.placeBuilding(
          cityId: city.id,
          playerId: player.id,
          buildingTypeId: 'single_home',
          gridX: 0,
          gridY: 0,
        );
        final siteId = await db.startBuildingSite(
          cityId: city.id,
          playerId: player.id,
          buildingTypeId: 'apartment',
          gridX: 4,
          gridY: 4,
          upgradesFromPlacementId: homeId,
        );
        final placements = await db.placementsForCity(city.id);
        final site = sitesFromRows(
          await db.sitesForCity(city.id),
          placements,
        ).single.site;
        expect(site.price, 60);
        final goal = site.goal as BuildingGoal;
        expect(goal.upgrade!.sourcePlacementId, homeId);
        expect(goal.netPopulationOnOpen, 12);

        // The home stands until the apartment opens.
        expect(placements.single.buildingTypeId, 'single_home');
        await db.openSite(siteId, playerId: player.id);
        final after = await db.placementsForCity(city.id);
        expect(after.map((p) => p.buildingTypeId), ['apartment']);
      },
    );

    test('an upgrade whose source vanished is skipped by the mapper', () async {
      final (db, player, city) = await freshCity();
      await db.startBuildingSite(
        cityId: city.id,
        playerId: player.id,
        buildingTypeId: 'apartment',
        gridX: 4,
        gridY: 4,
        upgradesFromPlacementId: 999,
      );
      expect(sitesFromRows(await db.sitesForCity(city.id), const []), isEmpty);
    });

    test('opening an unknown site is a no-op', () async {
      final (db, player, _) = await freshCity();
      expect(await db.openSite(42, playerId: player.id), isNull);
    });
  });

  group('land sites', () {
    test('start, map, open → owned block', () async {
      final (db, player, city) = await freshCity();
      final id = await db.startLandSite(
        cityId: city.id,
        playerId: player.id,
        blockX: 2,
        blockY: 0,
      );
      final sites = sitesFromRows(await db.sitesForCity(city.id), const []);
      expect(sites.single.goal, isA<LandBlockGoal>());
      expect(sites.single.site.price, 1200);
      expect(sites.single.name, 'New land');

      expect(await db.openSite(id, playerId: player.id), isNull);
      expect((await db.ownedBlocksForCity(city.id)).contains((2, 0)), isTrue);
      expect(await db.sitesForCity(city.id), isEmpty);
    });
  });
}
