import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/city/beat_registry.dart';
import 'package:math_city/domain/city/building_registry.dart';

void main() {
  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  test('resetCityForPlayer wipes city state and re-seeds the baseline',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    final player = await db.createPlayer(
      name: 'Reset',
      gradeLevel: 2,
      avatarConfigJson: '{}',
    );
    final city = await db.cityForPlayer(player.id);
    final preResearched = preResearchedBuildings.map((b) => b.id).toSet();

    // Dirty every kind of city-builder state.
    await db.incrementPlayerBricks(player.id, 500);
    await db.incrementPlayerResearch(player.id, 50);
    await db.placeBuilding(
      cityId: city.id,
      playerId: player.id,
      buildingTypeId: 'single_home',
      gridX: 1,
      gridY: 1,
      brickCost: 10,
    );
    await db.researchBuilding(
      playerId: player.id,
      buildingTypeId: 'park',
      researchCost: 1,
    );
    await db.recordBeatFired(player.id, beatRegistry.first.id, 500);
    await db.recordBandMilestone(player.id, 'add_within_5', 0);
    await db.setCityPopulation(city.id, 42);

    await db.resetCityForPlayer(player.id);

    final after = await db.getPlayerById(player.id);
    expect(after.brickBalance, 0);
    expect(after.lifetimeBricksEarned, 0);
    expect(after.researchBalance, 0);
    expect(after.lifetimeResearchEarned, 0);
    expect(await db.placementsForCity(city.id), isEmpty);
    expect(await db.researchedBuildingTypeIds(player.id), preResearched);
    expect(await db.storyBeatStatesForPlayer(player.id), isEmpty);
    expect(await db.awardedBandIndicesFor(player.id, 'add_within_5'), isEmpty);
    expect((await db.cityForPlayer(player.id)).population, 0);

    await db.close();
  });
}
