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
      expect(city.cityMapId, isNotEmpty);
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
      );

      final rows = await db.placementsForCity(city.id);
      expect(rows, hasLength(1));
      expect(rows.first.buildingTypeId, 'mayors_office');
      expect(rows.first.gridX, 4);
      expect(rows.first.gridY, 6);
      expect(rows.first.placedAtRound, 0);
    });

    test('placing never touches the lifetime coin counter', () async {
      final (db, player, city) = await freshCity();
      await db.addLifetimeCoins(player.id, 25);

      await db.placeBuilding(
        cityId: city.id,
        playerId: player.id,
        buildingTypeId: 'apartment',
        gridX: 1,
        gridY: 1,
      );

      final after = await db.getPlayerById(player.id);
      expect(after.lifetimeCoinsEarned, 25);
    });

    test('moveBuildingPlacement relocates an existing row in place', () async {
      final (db, player, city) = await freshCity();
      await db.placeBuilding(
        cityId: city.id,
        playerId: player.id,
        buildingTypeId: 'mayors_office',
        gridX: 2,
        gridY: 3,
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

    test('placedAtRound stamps the players current round clock', () async {
      final (db, player, city) = await freshCity();
      // The clock advances per answered question, not per placement, so
      // simulate three placements at three different rounds.
      for (var i = 0; i < 3; i++) {
        await db.incrementRoundsPlayed(player.id); // clock now 1, 2, 3
        await db.placeBuilding(
          cityId: city.id,
          playerId: player.id,
          buildingTypeId: 'mayors_office',
          gridX: i,
          gridY: 0,
        );
      }
      final rows = await db.placementsForCity(city.id);
      expect(
        rows.map((r) => r.placedAtRound).toList()..sort(),
        [1, 2, 3],
      );
    });
  });
}
