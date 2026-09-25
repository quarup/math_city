import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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
    test("a fresh player can buy only the mayor's office", () async {
      final db = AppDatabase(NativeDatabase.memory());
      final player = await db.createPlayer(
        name: 'Sam',
        gradeLevel: 2,
        avatarConfigJson: '{}',
      );
      final container = await _container(db, player.id);
      addTearDown(container.dispose);

      final catalog = await container.read(cityCatalogProvider.future);
      expect(catalog.map((b) => b.id), ['mayors_office']);
    });

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
      expect(all.length, buildingRegistry.length);

      container.read(debugUnlockAllProvider.notifier).set(on: false);
      final back = await container.read(cityCatalogProvider.future);
      expect(back.map((b) => b.id), ['mayors_office']);
    });

    test(
      'placing the mayor alone does not unlock the gated buildings',
      () async {
        final (db, player) = await _playerWithMayor();
        final container = await _container(db, player.id);
        addTearDown(container.dispose);

        // No demand beat read yet, so nothing past the mayor shows.
        final catalog = await container.read(cityCatalogProvider.future);
        expect(catalog.map((b) => b.id), ['mayors_office']);
      },
    );

    test(
      'reading a demand beat reveals just that building, buyable at once',
      () async {
        final (db, player) = await _playerWithMayor();
        // The first-home demand fires, then the player opens (reads) it.
        await db.recordBeatFired(player.id, 'demand_first_home', 0);
        await db.markBeatRead(player.id, 'demand_first_home', 0);

        final container = await _container(db, player.id);
        addTearDown(container.dispose);

        final catalog = await container.read(cityCatalogProvider.future);
        expect(catalog.map((b) => b.id), ['mayors_office', 'single_home']);
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
}
