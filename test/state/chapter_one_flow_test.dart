import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/chapter_one.dart';
import 'package:math_city/domain/city/construction_site.dart';
import 'package:math_city/state/city_provider.dart';
import 'package:math_city/state/player_provider.dart';

Future<(AppDatabase, int, ProviderContainer)> _setup() async {
  final db = AppDatabase(NativeDatabase.memory());
  final player = await db.createPlayer(
    name: 'Bea',
    gradeLevel: 1,
    avatarConfigJson: '{}',
  );
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
  container.read(activePlayerIdProvider.notifier).selected = player.id;
  await container.read(activePlayerProvider.future);
  return (db, player.id, container);
}

Future<Set<String>> _open(AppDatabase db, int pid) async {
  final states = await db.storyBeatStatesForPlayer(pid);
  return {
    for (final e in states.entries)
      if (e.value.state == 'onScreen') e.key,
  };
}

void main() {
  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  test('a new player starts chapter one; migrated players skip it', () async {
    final (db, pid, container) = await _setup();
    addTearDown(container.dispose);
    expect((await db.getPlayerById(pid)).guideStep, 0);
    expect((await db.getPlayerById(pid)).guideHints, 0);
  });

  test('the script sends home, school, park, then the hand-over', () async {
    final (db, pid, container) = await _setup();
    addTearDown(container.dispose);
    final actions = container.read(cityActionsProvider);
    final city = await db.cityForPlayer(pid);

    await actions.fireBeats();
    expect(await _open(db, pid), {'demand_first_home'});
    expect((await db.getPlayerById(pid)).guideStep, 0);

    // Starting the home's site fulfils the ask (under construction counts
    // as present); opening it advances the step and the school letter
    // arrives at once — no spacing, no other engine beats.
    await actions.startSite(
      BuildingGoal(type: findBuildingTypeById('single_home')!, col: 5, row: 5),
    );
    await actions.fireBeats();
    expect(await _open(db, pid), isEmpty);
    await db.placeBuilding(
      cityId: city.id,
      playerId: pid,
      buildingTypeId: 'single_home',
      gridX: 5,
      gridY: 5,
    );
    await actions.fireBeats();
    expect(await _open(db, pid), {'demand_school'});
    expect((await db.getPlayerById(pid)).guideStep, 1);

    await db.placeBuilding(
      cityId: city.id,
      playerId: pid,
      buildingTypeId: 'school',
      gridX: 8,
      gridY: 8,
    );
    await actions.fireBeats();
    // The school ask is fulfilled (completed), the park ask is open.
    expect(await _open(db, pid), {'demand_more_parks'});
    expect((await db.getPlayerById(pid)).guideStep, 2);

    await db.placeBuilding(
      cityId: city.id,
      playerId: pid,
      buildingTypeId: 'park',
      gridX: 0,
      gridY: 8,
    );
    await actions.fireBeats();
    final open = await _open(db, pid);
    expect(open, contains(kHandoverBeatId));
    expect((await db.getPlayerById(pid)).guideStep, kChapterOneDone);

    // Free play: the engine now runs (spacing applies; nothing more fires
    // this round since the hand-over just did).
    await actions.fireBeats();
    expect((await db.getPlayerById(pid)).guideStep, kChapterOneDone);
  });

  test('a cancelled site brings the letter back', () async {
    final (db, pid, container) = await _setup();
    addTearDown(container.dispose);
    final actions = container.read(cityActionsProvider);
    await actions.fireBeats();
    final start = await actions.startSite(
      BuildingGoal(type: findBuildingTypeById('single_home')!, col: 5, row: 5),
    );
    await actions.fireBeats();
    expect(await _open(db, pid), isEmpty);
    await actions.cancelSite(start.siteId!);
    await actions.fireBeats();
    expect(await _open(db, pid), {'demand_first_home'});
  });

  test('skipGuide ends the chapter and hands over to the engine', () async {
    final (db, pid, container) = await _setup();
    addTearDown(container.dispose);
    final actions = container.read(cityActionsProvider);
    await actions.skipGuide();
    expect((await db.getPlayerById(pid)).guideStep, kChapterOneDone);
    // The engine fired the first eligible beat: the same first-home ask.
    expect(await _open(db, pid), {'demand_first_home'});
  });

  test('markHintSeen sets bits once', () async {
    final (db, pid, container) = await _setup();
    addTearDown(container.dispose);
    final actions = container.read(cityActionsProvider);
    await actions.markHintSeen(GuideHint.fling);
    await actions.markHintSeen(GuideHint.fling);
    final hints = (await db.getPlayerById(pid)).guideHints;
    expect(GuideHint.fling.seenIn(hints), isTrue);
    expect(GuideHint.placeHere.seenIn(hints), isFalse);
  });

  test('reset puts the player back at the start of chapter one', () async {
    final (db, pid, container) = await _setup();
    addTearDown(container.dispose);
    await container.read(cityActionsProvider).skipGuide();
    await db.resetCityForPlayer(pid);
    expect((await db.getPlayerById(pid)).guideStep, 0);
  });
}
