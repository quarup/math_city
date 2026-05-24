import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/state/city_provider.dart';
import 'package:math_city/state/player_provider.dart';

Future<(AppDatabase, int, ProviderContainer)> _setup() async {
  final db = AppDatabase(NativeDatabase.memory());
  final player = await db.createPlayer(
    name: 'Pop',
    gradeLevel: 2,
    avatarConfigJson: '{}',
  );
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
  container.read(activePlayerIdProvider.notifier).selected = player.id;
  await container.read(activePlayerProvider.future);
  return (db, player.id, container);
}

Future<void> _placeHome(AppDatabase db, int cityId, int playerId, int x) =>
    db.placeBuilding(
      cityId: cityId,
      playerId: playerId,
      buildingTypeId: 'single_home',
      gridX: x,
      gridY: 0,
      brickCost: 0,
    );

void main() {
  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  test('setCityPopulation persists the value', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final player = await db.createPlayer(
      name: 'Pop',
      gradeLevel: 2,
      avatarConfigJson: '{}',
    );
    final city = await db.cityForPlayer(player.id);
    expect(city.population, 0);

    await db.setCityPopulation(city.id, 42);

    expect((await db.cityForPlayer(player.id)).population, 42);
  });

  test('tickPopulation grows toward capacity then holds there', () async {
    final (db, playerId, container) = await _setup();
    addTearDown(container.dispose);
    final city = await db.cityForPlayer(playerId);

    // Two single homes (4 residents each) -> capacity 8, under the service
    // free allowance, so nothing else caps it.
    await _placeHome(db, city.id, playerId, 0);
    await _placeHome(db, city.id, playerId, 1);

    final actions = container.read(cityActionsProvider);
    for (var i = 0; i < 30; i++) {
      await actions.tickPopulation();
    }

    expect((await db.cityForPlayer(playerId)).population, 8);
  });

  test('a tick is monotonic up to capacity and never overshoots', () async {
    final (db, playerId, container) = await _setup();
    addTearDown(container.dispose);
    final city = await db.cityForPlayer(playerId);
    await _placeHome(db, city.id, playerId, 0); // capacity 4

    final actions = container.read(cityActionsProvider);
    var prev = 0;
    for (var i = 0; i < 10; i++) {
      await actions.tickPopulation();
      final pop = (await db.cityForPlayer(playerId)).population;
      expect(pop, greaterThanOrEqualTo(prev));
      expect(pop, lessThanOrEqualTo(4));
      prev = pop;
    }
    expect(prev, 4);
  });

  test('placing a building steps the population immediately', () async {
    final (db, playerId, container) = await _setup();
    addTearDown(container.dispose);
    expect((await db.cityForPlayer(playerId)).population, 0);

    // placeBuilding ticks population as a side effect.
    final home = findBuildingTypeById('single_home')!;
    await container.read(cityActionsProvider).placeBuilding(home, 0, 0);

    expect((await db.cityForPlayer(playerId)).population, greaterThan(0));
  });

  test('tickPopulation is a no-op with no buildings', () async {
    final (db, playerId, container) = await _setup();
    addTearDown(container.dispose);

    await container.read(cityActionsProvider).tickPopulation();

    expect((await db.cityForPlayer(playerId)).population, 0);
  });
}
