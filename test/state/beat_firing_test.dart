import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/chapter_one.dart';
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
  // These are engine tests: skip the chapter-one script, which would
  // otherwise send only its three letters (see chapter_one_flow_test).
  await db.setGuideStep(player.id, kChapterOneDone);
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
);

Set<String> _openIds(ProviderContainer c) =>
    c.read(openBeatsProvider).asData!.value.map((b) => b.beat.id).toSet();

Set<String> _completedIds(ProviderContainer c) => c
    .read(openBeatsProvider)
    .asData!
    .value
    .where((b) => b.completed)
    .map((b) => b.beat.id)
    .toSet();

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
    final st = states[beatId]?.state;
    if (st == 'onScreen' || st == 'bubble') return;
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
      'recordBeatFired sets on-screen, counts fires, stamps coins',
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
        expect(states['demand_clinic']!.lifetimeCoinsAtLastFire, 10);
        expect(await db.firedBeatIds(p.id), {'demand_clinic'});

        await db.recordBeatFired(p.id, 'demand_clinic', 40);
        states = await db.storyBeatStatesForPlayer(p.id);
        expect(states['demand_clinic']!.fireCount, 2);
        expect(states['demand_clinic']!.lifetimeCoinsAtLastFire, 40);
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
      await container.refresh(openBeatsProvider.future);

      expect(_openIds(container), contains('demand_first_home'));
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

      // Now build a home: the (already-fired) demand stops being eligible and
      // flips to its 'completed' ✓ flash; the praise trickles out once the
      // new-beat spacing window elapses.
      await _place(db, city.id, pid, 'single_home', 1);
      await actions.fireBeats();
      final states = await db.storyBeatStatesForPlayer(pid);
      expect(states['demand_first_home']!.state, 'completed');

      await _drainUntil(db, pid, actions, 'praise_first_home');
      await container.refresh(openBeatsProvider.future);
      expect(_openIds(container), contains('praise_first_home'));
      expect(await db.firedBeatIds(pid), contains('praise_first_home'));
    });

    test('completed flash is surfaced and retireable', () async {
      final (db, pid, container) = await _setup();
      addTearDown(container.dispose);
      final city = await db.cityForPlayer(pid);
      final actions = container.read(cityActionsProvider);
      await _place(db, city.id, pid, 'mayors_office', 0);
      await actions.fireBeats();

      // Build the home: the demand's trigger no longer holds, so fireBeats
      // transitions it to the 'completed' ✓ flash.
      await _place(db, city.id, pid, 'single_home', 1);
      await actions.fireBeats();
      await container.refresh(openBeatsProvider.future);
      expect(_completedIds(container), contains('demand_first_home'));

      // The overlay calls retireCompletedBeat once its hold elapses; that
      // takes the bubble off-screen and leaves the row in 'acked'.
      await actions.retireCompletedBeat('demand_first_home');
      final states = await db.storyBeatStatesForPlayer(pid);
      expect(states['demand_first_home']!.state, 'acked');
      await container.refresh(openBeatsProvider.future);
      expect(_openIds(container), isNot(contains('demand_first_home')));
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
      'a re-fireable demand respects coin spacing after dismissal',
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

        // Dismiss it, then re-evaluate with no new coins earned: spacing (600)
        // not met, so it must NOT re-fire.
        await db.setBeatState(pid, 'demand_more_parks', 'dismissed');
        await actions.fireBeats();
        states = await db.storyBeatStatesForPlayer(pid);
        expect(states['demand_more_parks']!.state, 'dismissed');
        expect(states['demand_more_parks']!.fireCount, 1);

        // Earn 700 coins (past the 600 spacing) and re-evaluate: re-fires
        // (other eligible beats are already on screen, so parks is next up).
        await db.addLifetimeCoins(pid, 700);
        await _drainUntil(db, pid, actions, 'demand_more_parks');
        states = await db.storyBeatStatesForPlayer(pid);
        expect(states['demand_more_parks']!.state, 'onScreen');
        expect(states['demand_more_parks']!.fireCount, 2);
      },
    );

    test("a fresh city's first letter is the first-home ask", () async {
      final (db, pid, container) = await _setup();
      addTearDown(container.dispose);
      // The office is seeded at creation, so the very first evaluation
      // fires exactly one letter: Mrs. Pomeroy asking for a home.
      await container.read(cityActionsProvider).fireBeats();
      expect(await db.firedBeatIds(pid), {'demand_first_home'});
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
      'a letter never expires: shown, it stays open until fulfilled',
      () async {
        final (db, pid, container) = await _setup();
        addTearDown(container.dispose);
        final actions = container.read(cityActionsProvider);
        await actions.fireBeats();
        await container.refresh(openBeatsProvider.future);
        final before = container
            .read(openBeatsProvider)
            .asData!
            .value
            .firstWhere((b) => b.beat.id == 'demand_first_home');
        expect(before.shown, isFalse);

        // Showing the letter stamps it shown; it stays open.
        await actions.markBeatRead('demand_first_home');
        await container.refresh(openBeatsProvider.future);
        final after = container
            .read(openBeatsProvider)
            .asData!
            .value
            .firstWhere((b) => b.beat.id == 'demand_first_home');
        expect(after.shown, isTrue);

        // Many rounds later it is still open — no rotation, no read-hide.
        for (var i = 0; i < 40; i++) {
          await db.incrementRoundsPlayed(pid);
        }
        await actions.fireBeats();
        await container.refresh(openBeatsProvider.future);
        expect(_openIds(container), contains('demand_first_home'));
        expect(
          (await db.storyBeatStatesForPlayer(pid))['demand_first_home']!.state,
          'onScreen',
        );
      },
    );

    test(
      'a demand does not fire while its building is under construction',
      () async {
        final (db, pid, container) = await _setup();
        addTearDown(container.dispose);
        final city = await db.cityForPlayer(pid);
        final actions = container.read(cityActionsProvider);
        // The office is seeded at creation; a home site is already open.
        await db.startBuildingSite(
          cityId: city.id,
          playerId: pid,
          buildingTypeId: 'single_home',
          gridX: 5,
          gridY: 5,
        );
        await actions.fireBeats();
        expect(
          await db.firedBeatIds(pid),
          isNot(contains('demand_first_home')),
        );
      },
    );

    test('a recurring ask completes once its building is placed', () async {
      final (db, pid, container) = await _setup();
      addTearDown(container.dispose);
      final city = await db.cityForPlayer(pid);
      final actions = container.read(cityActionsProvider);
      await _place(db, city.id, pid, 'single_home', 5);
      // The park ask has no "park absent" clause (it recurs), so only a
      // park placed after it fired can answer it.
      await actions.debugFireBeat('demand_more_parks');
      await actions.fireBeats();
      var states = await db.storyBeatStatesForPlayer(pid);
      expect(states['demand_more_parks']!.state, 'onScreen');

      await _place(db, city.id, pid, 'park', 8);
      await actions.fireBeats();
      states = await db.storyBeatStatesForPlayer(pid);
      expect(states['demand_more_parks']!.state, 'completed');
    });

    test('the mayors office is seeded at creation and on reset', () async {
      final (db, pid, container) = await _setup();
      addTearDown(container.dispose);
      final city = await db.cityForPlayer(pid);
      final placed = await db.placementsForCity(city.id);
      expect(placed.map((p) => p.buildingTypeId), ['mayors_office']);
      expect((placed.single.gridX, placed.single.gridY), (1, 1));

      // ensureMayorsOffice is idempotent.
      await container.read(cityActionsProvider).ensureMayorsOffice();
      expect((await db.placementsForCity(city.id)).length, 1);
    });
  });
}
