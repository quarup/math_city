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
    name: 'Bea',
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

Future<void> _place(
  AppDatabase db,
  int cityId,
  int pid,
  String typeId,
  int x,
) => db.placeBuilding(
  cityId: cityId,
  playerId: pid,
  buildingTypeId: typeId,
  gridX: x,
  gridY: 0,
  brickCost: 0,
);

Set<String> _onScreenIds(ProviderContainer c) =>
    c.read(onScreenBeatsProvider).asData!.value.map((b) => b.id).toSet();

void main() {
  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('story-beat DB helpers', () {
    test(
      'recordBeatFired sets on-screen, counts fires, stamps bricks',
      () async {
        final db = AppDatabase(NativeDatabase.memory());
        final p = await db.createPlayer(
          name: 'x',
          gradeLevel: 1,
          avatarConfigJson: '{}',
        );

        await db.recordBeatFired(p.id, 'demand_clinic', 10);
        var states = await db.storyBeatStatesForPlayer(p.id);
        expect(states['demand_clinic']!.state, 'onScreen');
        expect(states['demand_clinic']!.fireCount, 1);
        expect(states['demand_clinic']!.lifetimeBricksAtLastFire, 10);
        expect(await db.firedBeatIds(p.id), {'demand_clinic'});

        await db.recordBeatFired(p.id, 'demand_clinic', 40);
        states = await db.storyBeatStatesForPlayer(p.id);
        expect(states['demand_clinic']!.fireCount, 2);
        expect(states['demand_clinic']!.lifetimeBricksAtLastFire, 40);
      },
    );

    test('setBeatState transitions the bubble', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await db.createPlayer(
        name: 'x',
        gradeLevel: 1,
        avatarConfigJson: '{}',
      );
      await db.recordBeatFired(p.id, 'praise_grocery', 0);
      await db.setBeatState(p.id, 'praise_grocery', 'dismissed');
      final states = await db.storyBeatStatesForPlayer(p.id);
      expect(states['praise_grocery']!.state, 'dismissed');
      // Still counts as "ever fired".
      expect(await db.firedBeatIds(p.id), contains('praise_grocery'));
    });
  });

  group('fireBeats orchestration', () {
    test('placing the mayors office fires the first-home demand', () async {
      final (db, pid, container) = await _setup();
      addTearDown(container.dispose);

      // placeBuilding calls fireBeats as a side effect.
      await container
          .read(cityActionsProvider)
          .placeBuilding(findBuildingTypeById('mayors_office')!, 0, 0);
      await container.refresh(onScreenBeatsProvider.future);

      expect(_onScreenIds(container), contains('demand_first_home'));
      expect(await db.firedBeatIds(pid), contains('demand_first_home'));
    });

    test('a beat already on screen is not re-fired', () async {
      final (db, pid, container) = await _setup();
      addTearDown(container.dispose);
      final city = await db.cityForPlayer(pid);
      await _place(db, city.id, pid, 'mayors_office', 0);

      final actions = container.read(cityActionsProvider);
      await actions.fireBeats();
      await actions.fireBeats();
      await actions.fireBeats();

      final states = await db.storyBeatStatesForPlayer(pid);
      expect(states['demand_first_home']!.fireCount, 1);
    });

    test('placing a home clears the demand and fires the praise', () async {
      final (db, pid, container) = await _setup();
      addTearDown(container.dispose);
      final city = await db.cityForPlayer(pid);
      await _place(db, city.id, pid, 'mayors_office', 0);
      await container.read(cityActionsProvider).fireBeats();
      expect(await db.firedBeatIds(pid), contains('demand_first_home'));

      // Now build a home: praise fires; the (already-fired) demand stops being
      // eligible but keeps its recorded fire.
      await _place(db, city.id, pid, 'single_home', 1);
      await container.read(cityActionsProvider).fireBeats();

      await container.refresh(onScreenBeatsProvider.future);
      final onScreen = _onScreenIds(container);
      expect(onScreen, contains('praise_first_home'));
      expect(await db.firedBeatIds(pid), contains('praise_first_home'));
    });

    test(
      'a re-fireable demand respects brick spacing after dismissal',
      () async {
        final (db, pid, container) = await _setup();
        addTearDown(container.dispose);
        final city = await db.cityForPlayer(pid);
        await _place(db, city.id, pid, 'single_home', 0);

        final actions = container.read(cityActionsProvider);
        await actions.fireBeats();
        expect(await db.firedBeatIds(pid), contains('demand_more_parks'));

        // Dismiss it, then re-evaluate with no new bricks earned: spacing (150)
        // not met, so it must NOT re-fire.
        await db.setBeatState(pid, 'demand_more_parks', 'dismissed');
        await actions.fireBeats();
        var states = await db.storyBeatStatesForPlayer(pid);
        expect(states['demand_more_parks']!.state, 'dismissed');
        expect(states['demand_more_parks']!.fireCount, 1);

        // Earn 200 bricks (past the 150 spacing) and re-evaluate: re-fires.
        await db.incrementPlayerBricks(pid, 200);
        await actions.fireBeats();
        states = await db.storyBeatStatesForPlayer(pid);
        expect(states['demand_more_parks']!.state, 'onScreen');
        expect(states['demand_more_parks']!.fireCount, 2);
      },
    );

    test('fireBeats is a no-op on an empty city', () async {
      final (db, pid, container) = await _setup();
      addTearDown(container.dispose);
      await container.read(cityActionsProvider).fireBeats();
      expect(await db.firedBeatIds(pid), isEmpty);
    });
  });
}
