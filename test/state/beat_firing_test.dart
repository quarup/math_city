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

/// Beats now trickle out one per [kNewBeatSpacingRounds] rounds, so reaching a
/// beat that isn't first in registry order takes several rounds of play. Steps
/// the round clock + re-evaluates until [beatId] is on screen.
Future<void> _drainUntil(
  AppDatabase db,
  int pid,
  CityActions actions,
  String beatId, {
  int maxRounds = 200,
}) async {
  for (var i = 0; i < maxRounds; i++) {
    await actions.fireBeats();
    final states = await db.storyBeatStatesForPlayer(pid);
    if (states[beatId]?.state == 'onScreen') return;
    await db.incrementRoundsPlayed(pid);
  }
  fail('beat "$beatId" never fired within $maxRounds rounds');
}

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
      final actions = container.read(cityActionsProvider);
      await _place(db, city.id, pid, 'mayors_office', 0);
      await actions.fireBeats();
      expect(await db.firedBeatIds(pid), contains('demand_first_home'));

      // Now build a home: the (already-fired) demand stops being eligible but
      // keeps its recorded fire; the praise trickles out once the new-beat
      // spacing window elapses.
      await _place(db, city.id, pid, 'single_home', 1);
      await _drainUntil(db, pid, actions, 'praise_first_home');

      await container.refresh(onScreenBeatsProvider.future);
      expect(_onScreenIds(container), contains('praise_first_home'));
      expect(await db.firedBeatIds(pid), contains('praise_first_home'));
    });

    test('newly-eligible beats trickle out a few rounds apart', () async {
      final (db, pid, container) = await _setup();
      addTearDown(container.dispose);
      final city = await db.cityForPlayer(pid);
      final actions = container.read(cityActionsProvider);

      // A single home makes several beats eligible at once (praise + service
      // demands). Only one should fire immediately — not the whole burst.
      await _place(db, city.id, pid, 'single_home', 0);
      await actions.fireBeats();
      expect((await db.firedBeatIds(pid)).length, 1);

      // No second beat appears until the spacing window elapses.
      for (var i = 0; i < kNewBeatSpacingRounds - 1; i++) {
        await db.incrementRoundsPlayed(pid);
        await actions.fireBeats();
      }
      expect((await db.firedBeatIds(pid)).length, 1);

      // One more round crosses the window: a second beat fires.
      await db.incrementRoundsPlayed(pid);
      await actions.fireBeats();
      expect((await db.firedBeatIds(pid)).length, 2);
    });

    test(
      'a re-fireable demand respects brick spacing after dismissal',
      () async {
        final (db, pid, container) = await _setup();
        addTearDown(container.dispose);
        final city = await db.cityForPlayer(pid);
        await _place(db, city.id, pid, 'single_home', 0);

        final actions = container.read(cityActionsProvider);
        // Parks is far down the registry; let beats trickle until it fires.
        await _drainUntil(db, pid, actions, 'demand_more_parks');
        var states = await db.storyBeatStatesForPlayer(pid);
        expect(states['demand_more_parks']!.fireCount, 1);

        // Dismiss it, then re-evaluate with no new bricks earned: spacing (150)
        // not met, so it must NOT re-fire.
        await db.setBeatState(pid, 'demand_more_parks', 'dismissed');
        await actions.fireBeats();
        states = await db.storyBeatStatesForPlayer(pid);
        expect(states['demand_more_parks']!.state, 'dismissed');
        expect(states['demand_more_parks']!.fireCount, 1);

        // Earn 200 bricks (past the 150 spacing) and re-evaluate: re-fires
        // (other eligible beats are already on screen, so parks is next up).
        await db.incrementPlayerBricks(pid, 200);
        await _drainUntil(db, pid, actions, 'demand_more_parks');
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

    test('incrementRoundsPlayed advances and persists the clock', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await db.createPlayer(
        name: 'x',
        gradeLevel: 1,
        avatarConfigJson: '{}',
      );
      expect((await db.getPlayerById(p.id)).roundsPlayed, 0);
      expect(await db.incrementRoundsPlayed(p.id), 1);
      expect(await db.incrementRoundsPlayed(p.id), 2);
      expect((await db.getPlayerById(p.id)).roundsPlayed, 2);
    });

    test('an age-gated beat fires once its building is old enough', () async {
      final (db, pid, container) = await _setup();
      addTearDown(container.dispose);
      final city = await db.cityForPlayer(pid);
      final actions = container.read(cityActionsProvider);

      // Mayor's office at round 0, then a home (praise_first_home is a prereq
      // of the age-gated milestone).
      await _place(db, city.id, pid, 'mayors_office', 0);
      await _place(db, city.id, pid, 'single_home', 1);

      // Below the 10-round age gate the milestone can't fire, even as other
      // beats trickle out round by round.
      for (var r = 0; r < 9; r++) {
        await actions.fireBeats();
        await db.incrementRoundsPlayed(pid);
      }
      expect(await db.firedBeatIds(pid), contains('praise_first_home'));
      expect(
        await db.firedBeatIds(pid),
        isNot(contains('praise_established_town')),
      );

      // Past 10 rounds old: it becomes eligible and trickles out.
      await _drainUntil(db, pid, actions, 'praise_established_town');
      expect(await db.firedBeatIds(pid), contains('praise_established_town'));
    });

    test('debugAdvanceRounds advances the clock past an age gate', () async {
      final (db, pid, container) = await _setup();
      addTearDown(container.dispose);
      final city = await db.cityForPlayer(pid);
      final actions = container.read(cityActionsProvider);

      await _place(db, city.id, pid, 'mayors_office', 0);
      await _place(db, city.id, pid, 'single_home', 1);
      await actions.fireBeats(); // fires praise_first_home (a milestone prereq)

      // Jump the clock past the 10-round age gate without grinding math; the
      // milestone is now eligible and trickles out with the rest.
      await actions.debugAdvanceRounds(10);
      expect((await db.getPlayerById(pid)).roundsPlayed, 10);
      await _drainUntil(db, pid, actions, 'praise_established_town');
      expect(await db.firedBeatIds(pid), contains('praise_established_town'));
    });

    test(
      'an un-acknowledged bubble rotates off screen after the window',
      () async {
        final (db, pid, container) = await _setup();
        addTearDown(container.dispose);
        final city = await db.cityForPlayer(pid);
        final actions = container.read(cityActionsProvider);

        await _place(db, city.id, pid, 'mayors_office', 0);
        await actions.fireBeats();
        await container.refresh(onScreenBeatsProvider.future);
        expect(_onScreenIds(container), contains('demand_first_home'));

        // Let the rotation window elapse without acking the bubble.
        for (var i = 0; i < kBubbleRotationRounds; i++) {
          await db.incrementRoundsPlayed(pid);
        }
        await actions.fireBeats();
        await container.refresh(onScreenBeatsProvider.future);

        // Hidden from the overlay, but still recorded as fired (state
        // unchanged, so it won't re-fire and clutter the screen again).
        expect(_onScreenIds(container), isNot(contains('demand_first_home')));
        expect(await db.firedBeatIds(pid), contains('demand_first_home'));
        final states = await db.storyBeatStatesForPlayer(pid);
        expect(states['demand_first_home']!.state, 'onScreen');
      },
    );

    test('reading a beat keeps it on screen, then retires it', () async {
      final (db, pid, container) = await _setup();
      addTearDown(container.dispose);
      final city = await db.cityForPlayer(pid);
      await _place(db, city.id, pid, 'mayors_office', 0);

      final actions = container.read(cityActionsProvider);
      await actions.fireBeats();
      await container.refresh(onScreenBeatsProvider.future);
      expect(_onScreenIds(container), contains('demand_first_home'));

      // Reading it does NOT take it off screen — it lingers, still 'onScreen'.
      await actions.markBeatRead('demand_first_home');
      await container.refresh(onScreenBeatsProvider.future);
      expect(_onScreenIds(container), contains('demand_first_home'));
      var states = await db.storyBeatStatesForPlayer(pid);
      expect(states['demand_first_home']!.state, 'onScreen');

      // After a few rounds of math play it retires off screen and becomes
      // re-fireable ('acked'), still recorded as ever-fired.
      for (var i = 0; i < kReadHideRounds; i++) {
        await db.incrementRoundsPlayed(pid);
      }
      await actions.fireBeats();
      await container.refresh(onScreenBeatsProvider.future);
      expect(_onScreenIds(container), isNot(contains('demand_first_home')));
      states = await db.storyBeatStatesForPlayer(pid);
      expect(states['demand_first_home']!.state, 'acked');
      expect(await db.firedBeatIds(pid), contains('demand_first_home'));
    });
  });
}
