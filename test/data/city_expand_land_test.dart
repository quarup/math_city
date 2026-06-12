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

  group('expandCityLand', () {
    test('grows the grid, shifts placements, and spends bricks', () async {
      final (db, player, city) = await freshCity();
      await db.incrementPlayerBricks(player.id, 100);
      await db.placeBuilding(
        cityId: city.id,
        playerId: player.id,
        buildingTypeId: 'mayors_office',
        gridX: 4,
        gridY: 6,
        brickCost: 0,
      );

      await db.expandCityLand(
        cityId: city.id,
        playerId: player.id,
        newGridWidth: 16,
        newGridHeight: 16,
        shiftX: 2,
        shiftY: 2,
        brickCost: 60,
      );

      final after = await db.cityForPlayer(player.id);
      expect(after.gridWidth, 16);
      expect(after.gridHeight, 16);

      final placement = (await db.placementsForCity(city.id)).single;
      expect(placement.gridX, 6); // 4 + 2
      expect(placement.gridY, 8); // 6 + 2

      final playerAfter = await db.getPlayerById(player.id);
      expect(playerAfter.brickBalance, 40); // 100 - 60
      expect(playerAfter.lifetimeBricksEarned, 100); // unchanged by spend
    });

    test('shifts every placement, not just one', () async {
      final (db, player, city) = await freshCity();
      for (var i = 0; i < 3; i++) {
        await db.placeBuilding(
          cityId: city.id,
          playerId: player.id,
          buildingTypeId: 'single_home',
          gridX: i,
          gridY: i + 1,
          brickCost: 0,
        );
      }

      await db.expandCityLand(
        cityId: city.id,
        playerId: player.id,
        newGridWidth: 16,
        newGridHeight: 16,
        shiftX: 2,
        shiftY: 2,
        brickCost: 0,
      );

      final rows = await db.placementsForCity(city.id);
      expect(rows.map((r) => r.gridX).toList()..sort(), [2, 3, 4]);
      expect(rows.map((r) => r.gridY).toList()..sort(), [3, 4, 5]);
    });

    test('zero shift on a capped axis leaves that coordinate alone', () async {
      final (db, player, city) = await freshCity();
      await db.placeBuilding(
        cityId: city.id,
        playerId: player.id,
        buildingTypeId: 'single_home',
        gridX: 5,
        gridY: 5,
        brickCost: 0,
      );

      await db.expandCityLand(
        cityId: city.id,
        playerId: player.id,
        newGridWidth: 12,
        newGridHeight: 16,
        shiftX: 0,
        shiftY: 2,
        brickCost: 0,
      );

      final placement = (await db.placementsForCity(city.id)).single;
      expect(placement.gridX, 5);
      expect(placement.gridY, 7);
    });
  });
}
