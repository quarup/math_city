import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/construction_sites.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/chapter_one.dart';
import 'package:math_city/domain/city/construction_site.dart';
import 'package:math_city/domain/city/population_model.dart';
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

Future<int> _place(AppDatabase db, int cityId, int pid, String type, int x) =>
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

  group('EventGoal (domain)', () {
    final park = findBuildingTypeById('park')!;
    final goal = EventGoal(
      eventId: kBlockPartyId,
      venuePlacementId: 3,
      venueType: park,
      col: 4,
      row: 4,
    );

    test('priced at the party price on the venue footprint', () {
      expect(goal.price, kBlockPartyPrice);
      expect(goal.footprint.width, park.footprint.$1);
      expect(goal.footprint.tiles(), contains((4, 4)));
    });

    test('one party at a time, and only at a public space', () {
      final owned = {(0, 0)};
      expect(
        checkStartSite(goal: goal, openSites: const [], ownedBlocks: owned),
        isNull,
      );
      expect(
        checkStartSite(
          goal: goal,
          openSites: [ConstructionSite(goal: goal, startedAtRound: 0)],
          ownedBlocks: owned,
        ),
        SiteStartRejection.eventAlreadyOpen,
      );
      final atHome = EventGoal(
        eventId: kBlockPartyId,
        venuePlacementId: 9,
        venueType: findBuildingTypeById('single_home')!,
        col: 0,
        row: 0,
      );
      expect(
        checkStartSite(goal: atHome, openSites: const [], ownedBlocks: owned),
        SiteStartRejection.venueNotPublic,
      );
    });
  });

  group('the block party (state)', () {
    test('the organiser writes when homes sit half-empty', () async {
      final (db, pid, container) = await _setup();
      addTearDown(container.dispose);
      final city = await db.cityForPlayer(pid);
      final actions = container.read(cityActionsProvider);
      await _place(db, city.id, pid, 'single_home', 4);
      await _place(db, city.id, pid, 'apartment', 6);
      await _place(db, city.id, pid, 'park', 9);
      // Capacity 20, population 0: a gap worth a party.
      var fired = false;
      for (var i = 0; i < 40 && !fired; i++) {
        await actions.fireBeats();
        fired = (await db.firedBeatIds(pid)).contains('event_block_party');
        await db.incrementRoundsPlayed(pid);
      }
      expect(fired, isTrue);
    });

    test('no party without a public space or without a gap', () async {
      final (db, pid, container) = await _setup();
      addTearDown(container.dispose);
      final city = await db.cityForPlayer(pid);
      final actions = container.read(cityActionsProvider);
      await _place(db, city.id, pid, 'single_home', 4);
      await _place(db, city.id, pid, 'apartment', 6);
      for (var i = 0; i < 30; i++) {
        await actions.fireBeats();
        await db.incrementRoundsPlayed(pid);
      }
      expect(await db.firedBeatIds(pid), isNot(contains('event_block_party')));

      // Now a park, but the town is already full.
      await _place(db, city.id, pid, 'park', 9);
      await db.setCityPopulation(city.id, 20);
      for (var i = 0; i < 30; i++) {
        await actions.fireBeats();
        await db.incrementRoundsPlayed(pid);
      }
      expect(await db.firedBeatIds(pid), isNot(contains('event_block_party')));
    });

    test('paying the party off fills the town and sends the reply', () async {
      final (db, pid, container) = await _setup();
      addTearDown(container.dispose);
      final city = await db.cityForPlayer(pid);
      final actions = container.read(cityActionsProvider);
      await _place(db, city.id, pid, 'single_home', 4);
      await _place(db, city.id, pid, 'apartment', 6);
      final parkId = await _place(db, city.id, pid, 'park', 9);
      final placements = await db.placementsForCity(city.id);
      final venue = partyVenueFor(placements)!;
      expect(venue.id, parkId);

      final start = await actions.startSite(
        EventGoal(
          eventId: kBlockPartyId,
          venuePlacementId: venue.id,
          venueType: findBuildingTypeById('park')!,
          col: venue.gridX,
          row: venue.gridY,
        ),
      );
      expect(start.ok, isTrue);
      final sites = sitesFromRows(
        await db.sitesForCity(city.id),
        placements,
      );
      expect(sites.single.name, 'Block party');
      expect(sites.single.site.price, kBlockPartyPrice);

      await actions.payIntoSite(start.siteId!, kBlockPartyPrice);
      expect(await db.sitesForCity(city.id), isEmpty);
      final placed = [
        for (final p in await db.placementsForCity(city.id))
          findBuildingTypeById(p.buildingTypeId)!,
      ];
      expect(
        (await db.cityForPlayer(pid)).population,
        populationCapacity(placed),
      );
      final open = await container.read(openBeatsProvider.future);
      expect(open.map((b) => b.beat.id), contains('praise_block_party'));
    });

    test('an event site row round-trips and survives the venue', () async {
      final (db, pid, container) = await _setup();
      addTearDown(container.dispose);
      final city = await db.cityForPlayer(pid);
      final parkId = await _place(db, city.id, pid, 'park', 9);
      await db.startEventSite(
        cityId: city.id,
        playerId: pid,
        eventId: kBlockPartyId,
        venuePlacementId: parkId,
      );
      final placements = await db.placementsForCity(city.id);
      final site = sitesFromRows(
        await db.sitesForCity(city.id),
        placements,
      ).single;
      expect(site.goal, isA<EventGoal>());
      expect((site.goal as EventGoal).venuePlacementId, parkId);
      // Without its venue the row maps to nothing.
      expect(sitesFromRows(await db.sitesForCity(city.id), const []), isEmpty);
    });
  });
}
