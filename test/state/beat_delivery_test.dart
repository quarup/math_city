import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/city/beat_registry.dart';
import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/chapter_one.dart';
import 'package:math_city/domain/city/construction_site.dart';
import 'package:math_city/domain/city/population_model.dart';
import 'package:math_city/domain/city/story_beat.dart';
import 'package:math_city/domain/city/trigger_rule.dart';
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
  await db.setGuideStep(player.id, kChapterOneDone);
  await container.read(activePlayerProvider.future);
  return (db, player.id, container);
}

Future<void> _place(AppDatabase db, int cityId, int pid, String type, int x) =>
    db.placeBuilding(
      cityId: cityId,
      playerId: pid,
      buildingTypeId: type,
      gridX: x,
      gridY: 0,
    );

void main() {
  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('delivery', () {
    test('by kind: demands letters, warnings the Times, milestones pinned', () {
      expect(
        findBeatById('demand_school')!.staticDelivery,
        BeatDelivery.letter,
      );
      expect(findBeatById('warn_lopsided')!.staticDelivery, BeatDelivery.times);
      expect(
        findBeatById('milestone_big_city')!.staticDelivery,
        BeatDelivery.times,
      );
      expect(findBeatById('milestone_pop_50')!.oneShot, isTrue);
    });

    test('an opening sends the thank-you reply at once, as a letter', () async {
      final (db, pid, container) = await _setup();
      addTearDown(container.dispose);
      final actions = container.read(cityActionsProvider);
      final start = await actions.startSite(
        BuildingGoal(
          type: findBuildingTypeById('single_home')!,
          col: 5,
          row: 5,
        ),
      );
      // Fill the site in one go: it opens, and praise_first_home fires
      // immediately (no spacing), open and unshown.
      await actions.payIntoSite(start.siteId!, 60);
      final open = await container.read(openBeatsProvider.future);
      final reply = open.firstWhere((b) => b.beat.id == 'praise_first_home');
      expect(reply.delivery, BeatDelivery.letter);
      expect(reply.shown, isFalse);
    });

    test('a second opening of the same type sends no second reply', () async {
      final (db, pid, container) = await _setup();
      addTearDown(container.dispose);
      final actions = container.read(cityActionsProvider);
      for (final col in [5, 8]) {
        final start = await actions.startSite(
          BuildingGoal(
            type: findBuildingTypeById('single_home')!,
            col: col,
            row: 5,
          ),
        );
        await actions.payIntoSite(start.siteId!, 60);
      }
      final states = await db.storyBeatStatesForPlayer(pid);
      expect(states['praise_first_home']!.fireCount, 1);
    });

    test('engine-fired praise is a bubble', () async {
      final (db, pid, container) = await _setup();
      addTearDown(container.dispose);
      final actions = container.read(cityActionsProvider);
      final city = await db.cityForPlayer(pid);
      // A home placed directly (no opening → no reply): the engine finds
      // praise_first_home eligible and fires it as ambient praise.
      await _place(db, city.id, pid, 'single_home', 5);
      for (var i = 0; i < 40; i++) {
        await actions.fireBeats();
        final st = (await db.storyBeatStatesForPlayer(
          pid,
        ))['praise_first_home'];
        if (st != null) {
          expect(st.state, 'bubble');
          final open = await container.read(openBeatsProvider.future);
          expect(
            open.firstWhere((b) => b.beat.id == 'praise_first_home').delivery,
            BeatDelivery.bubble,
          );
          return;
        }
        await db.incrementRoundsPlayed(pid);
      }
      fail('praise_first_home never fired');
    });
  });

  group('the Times', () {
    test('cityBalance flags a lopsided town and a stalled one', () {
      final home = findBuildingTypeById('single_home')!;
      final shop = findBuildingTypeById('coffee_shop')!;
      final park = findBuildingTypeById('park')!;
      final stall = findBuildingTypeById('market_stall')!;
      expect(cityBalance([home], 4).lopsided, isFalse);
      expect(cityBalance([home, shop, park, stall], 4).lopsided, isTrue);
      expect(cityBalance(const [], 0).lopsided, isFalse);
      // Six apartments (96 residents) with no services: capacity is capped
      // at the free allowance (20), below the housing — growth is stalled
      // once the population sits at that cap.
      final apt = findBuildingTypeById('apartment')!;
      final six = List.filled(6, apt);
      final capacity = populationCapacity(six);
      expect(capacity, lessThan(96));
      expect(cityBalance(six, capacity).growthStalled, isTrue);
      expect(cityBalance(six, capacity - 5).growthStalled, isFalse);
    });

    test('the ratio warnings fire only on their flag', () {
      final lopsided = findBeatById('warn_lopsided')!;
      TriggerContext ctx({bool lop = false}) => TriggerContext(
        placedBuildingTypeIds: const {'single_home'},
        population: 0,
        maxBuildingAgeByTypeId: const {},
        firedBeatIds: const {},
        coinsEarnedSinceBeatLastFired: null,
        lopsided: lop,
      );
      expect(lopsided.triggerRule.evaluate(ctx()), isFalse);
      expect(lopsided.triggerRule.evaluate(ctx(lop: true)), isTrue);
    });

    test('a one-shot milestone never fires twice', () async {
      final (db, pid, container) = await _setup();
      addTearDown(container.dispose);
      final actions = container.read(cityActionsProvider);
      final city = await db.cityForPlayer(pid);
      await _place(db, city.id, pid, 'single_home', 5);
      await actions.debugSetPopulation(60);
      var fired = false;
      for (var i = 0; i < 60 && !fired; i++) {
        await actions.fireBeats();
        fired = (await db.firedBeatIds(pid)).contains('milestone_pop_50');
        await db.incrementRoundsPlayed(pid);
      }
      expect(fired, isTrue);
      final open = await container.read(openBeatsProvider.future);
      expect(
        open.firstWhere((b) => b.beat.id == 'milestone_pop_50').delivery,
        BeatDelivery.times,
      );
      // Retire it and keep playing: it stays fired once.
      await actions.retireCompletedBeat('milestone_pop_50');
      await db.addLifetimeCoins(pid, 5000);
      for (var i = 0; i < 30; i++) {
        await actions.fireBeats();
        await db.incrementRoundsPlayed(pid);
      }
      expect(
        (await db.storyBeatStatesForPlayer(pid))['milestone_pop_50']!.fireCount,
        1,
      );
    });
  });
}
