import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';

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

  group('city query helpers', () {
    test('cityForPlayer returns the auto-created beginner city', () async {
      final (db, player, city) = await freshCity();
      expect(city.playerId, player.id);
      expect(city.gridWidth, 12);
      expect(city.gridHeight, 12);
    });

    test('researchedBuildingTypeIds includes pre-researched mayor', () async {
      final (db, player, _) = await freshCity();
      final ids = await db.researchedBuildingTypeIds(player.id);
      expect(ids, {'mayors_office'});
    });

    test('placementsForCity is empty for a fresh city', () async {
      final (db, _, city) = await freshCity();
      expect(await db.placementsForCity(city.id), isEmpty);
    });
  });

  group('placeBuilding', () {
    test('inserts a placement row at the given tile', () async {
      final (db, player, city) = await freshCity();
      await db.placeBuilding(
        cityId: city.id,
        playerId: player.id,
        buildingTypeId: 'mayors_office',
        gridX: 4,
        gridY: 6,
        brickCost: 0,
      );

      final rows = await db.placementsForCity(city.id);
      expect(rows, hasLength(1));
      expect(rows.first.buildingTypeId, 'mayors_office');
      expect(rows.first.gridX, 4);
      expect(rows.first.gridY, 6);
      expect(rows.first.placedAtRound, 0);
    });

    test('spends bricks, keeping lifetime monotone', () async {
      final (db, player, city) = await freshCity();
      // Give the player some bricks to spend.
      await db.incrementPlayerBricks(player.id, 25);

      await db.placeBuilding(
        cityId: city.id,
        playerId: player.id,
        buildingTypeId: 'apartment',
        gridX: 1,
        gridY: 1,
        brickCost: 10,
      );

      final after = await db.getPlayerById(player.id);
      expect(after.brickBalance, 15); // 25 - 10
      expect(after.lifetimeBricksEarned, 25); // unchanged by spend
    });

    test('free placements do not touch the brick balance', () async {
      final (db, player, city) = await freshCity();
      await db.incrementPlayerBricks(player.id, 5);

      await db.placeBuilding(
        cityId: city.id,
        playerId: player.id,
        buildingTypeId: 'mayors_office',
        gridX: 0,
        gridY: 0,
        brickCost: 0,
      );

      final after = await db.getPlayerById(player.id);
      expect(after.brickBalance, 5);
    });

    test('moveBuildingPlacement relocates an existing row in place', () async {
      final (db, player, city) = await freshCity();
      await db.placeBuilding(
        cityId: city.id,
        playerId: player.id,
        buildingTypeId: 'mayors_office',
        gridX: 2,
        gridY: 3,
        brickCost: 0,
      );
      final original = (await db.placementsForCity(city.id)).single;

      await db.moveBuildingPlacement(
        placementId: original.id,
        gridX: 7,
        gridY: 8,
      );

      final rows = await db.placementsForCity(city.id);
      expect(rows, hasLength(1));
      expect(rows.first.id, original.id); // same row, not a new insert
      expect(rows.first.gridX, 7);
      expect(rows.first.gridY, 8);
      expect(rows.first.placedAtRound, original.placedAtRound); // preserved
    });

    test('placedAtRound increments with the placement count', () async {
      final (db, player, city) = await freshCity();
      for (var i = 0; i < 3; i++) {
        await db.placeBuilding(
          cityId: city.id,
          playerId: player.id,
          buildingTypeId: 'mayors_office',
          gridX: i,
          gridY: 0,
          brickCost: 0,
        );
      }
      final rows = await db.placementsForCity(city.id);
      expect(rows.map((r) => r.placedAtRound).toList(), containsAll([0, 1, 2]));
    });
  });

  group('researchBuilding', () {
    test('records the type and spends research, lifetime monotone', () async {
      final (db, player, _) = await freshCity();
      await db.incrementPlayerResearch(player.id, 3);

      await db.researchBuilding(
        playerId: player.id,
        buildingTypeId: 'clinic',
        researchCost: 1,
      );

      expect(await db.researchedBuildingTypeIds(player.id), {
        'mayors_office',
        'clinic',
      });
      final after = await db.getPlayerById(player.id);
      expect(after.researchBalance, 2); // 3 - 1
      expect(after.lifetimeResearchEarned, 3); // unchanged by spend
    });

    test('is idempotent — re-researching does not double-charge', () async {
      final (db, player, _) = await freshCity();
      await db.incrementPlayerResearch(player.id, 3);

      await db.researchBuilding(
        playerId: player.id,
        buildingTypeId: 'clinic',
        researchCost: 1,
      );
      await db.researchBuilding(
        playerId: player.id,
        buildingTypeId: 'clinic',
        researchCost: 1,
      );

      final after = await db.getPlayerById(player.id);
      expect(after.researchBalance, 2); // charged once, not twice
    });
  });
}
