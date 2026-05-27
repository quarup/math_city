import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';
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

void main() {
  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('cityCatalogProvider', () {
    test('fresh player sees only the researched mayor (nothing to research '
        'until it is placed)', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final player = await db.createPlayer(
        name: 'Sam',
        gradeLevel: 2,
        avatarConfigJson: '{}',
      );
      final container = await _container(db, player.id);
      addTearDown(container.dispose);

      final catalog = await container.read(cityCatalogProvider.future);
      expect(catalog, hasLength(1));
      expect(catalog.single.building.id, 'mayors_office');
      expect(catalog.single.researched, isTrue);
    });

    test(
      'placing the mayor alone does not unlock the gated buildings',
      () async {
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
          brickCost: 0,
        );

        final container = await _container(db, player.id);
        addTearDown(container.dispose);

        // No demand beat read yet, so nothing past the mayor shows.
        final catalog = await container.read(cityCatalogProvider.future);
        expect(catalog.map((e) => e.building.id), ['mayors_office']);
      },
    );

    test(
      'reading a demand beat reveals just that building as a locked card',
      () async {
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
          brickCost: 0,
        );
        // The first-home demand fires, then the player opens (reads) it.
        await db.recordBeatFired(player.id, 'demand_first_home', 0);
        await db.markBeatRead(player.id, 'demand_first_home', 0);

        final container = await _container(db, player.id);
        addTearDown(container.dispose);

        final catalog = await container.read(cityCatalogProvider.future);
        final byId = {for (final e in catalog) e.building.id: e};

        // Mayor stays researched; the single home now appears, unresearched.
        expect(byId['mayors_office']!.researched, isTrue);
        expect(byId['single_home']!.researched, isFalse);
        // The clinic's demand hasn't been read, so its card stays hidden.
        expect(byId.containsKey('clinic'), isFalse);
      },
    );

    test('a researched building flips to a placeable entry', () async {
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
        brickCost: 0,
      );
      await db.incrementPlayerResearch(player.id, 1);
      await db.researchBuilding(
        playerId: player.id,
        buildingTypeId: 'clinic',
        researchCost: 1,
      );

      final container = await _container(db, player.id);
      addTearDown(container.dispose);

      final catalog = await container.read(cityCatalogProvider.future);
      final clinic = catalog.firstWhere((e) => e.building.id == 'clinic');
      expect(clinic.researched, isTrue);
    });
  });
}
