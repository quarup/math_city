import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/city/beat_registry.dart';

void main() {
  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  test(
    'resetCityForPlayer wipes city state and re-seeds the baseline',
    () async {
      final db = AppDatabase(NativeDatabase.memory());
      final player = await db.createPlayer(
        name: 'Reset',
        gradeLevel: 2,
        avatarConfigJson: '{}',
      );
      final city = await db.cityForPlayer(player.id);

      // Dirty every kind of city-builder state.
      await db.addLifetimeCoins(player.id, 500);
      await db.setPlayerStreakCount(player.id, 4);
      await db.placeBuilding(
        cityId: city.id,
        playerId: player.id,
        buildingTypeId: 'single_home',
        gridX: 1,
        gridY: 1,
      );
      await db.startBuildingSite(
        cityId: city.id,
        playerId: player.id,
        buildingTypeId: 'apartment',
        gridX: 4,
        gridY: 4,
      );
      await db.recordBeatFired(player.id, beatRegistry.first.id, 500);
      await db.recordBandMilestone(player.id, 'add_within_5', 0);
      await db.setCityPopulation(city.id, 42);

      await db.resetCityForPlayer(player.id);

      final after = await db.getPlayerById(player.id);
      expect(after.lifetimeCoinsEarned, 0);
      expect(after.streakCount, 0);
      expect(await db.placementsForCity(city.id), isEmpty);
      expect(await db.sitesForCity(city.id), isEmpty);
      expect(await db.storyBeatStatesForPlayer(player.id), isEmpty);
      expect(
        await db.awardedBandIndicesFor(player.id, 'add_within_5'),
        isEmpty,
      );
      expect((await db.cityForPlayer(player.id)).population, 0);

      await db.close();
    },
  );
}
