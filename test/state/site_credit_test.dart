import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/construction_site.dart';
import 'package:math_city/state/city_provider.dart';
import 'package:math_city/state/introduced_concepts_provider.dart';
import 'package:math_city/state/player_provider.dart';
import 'package:math_city/state/proficiency_provider.dart';

Future<(AppDatabase, int, ProviderContainer)> _setup() async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  final db = AppDatabase(NativeDatabase.memory());
  final p = await db.createPlayer(
    name: 'tester',
    gradeLevel: 0,
    avatarConfigJson: '{}',
  );
  final container = ProviderContainer(
    overrides: [appDatabaseProvider.overrideWithValue(db)],
  );
  container.read(activePlayerIdProvider.notifier).selected = p.id;
  await container.read(activePlayerProvider.future);
  await container.read(introducedConceptsProvider.future);
  await container.read(proficiencyProvider.future);
  return (db, p.id, container);
}

Future<int> _startHome(ProviderContainer c, {int col = 0}) async {
  final home = findBuildingTypeById('single_home')!;
  final start = await c
      .read(cityActionsProvider)
      .startSite(BuildingGoal(type: home, col: col, row: 0));
  expect(start.ok, isTrue, reason: '${start.rejection}');
  return start.siteId!;
}

void main() {
  group('CityActions.cancelSite', () {
    test('refunds every paid coin as credit and drops the site', () async {
      final (db, pid, c) = await _setup();
      addTearDown(c.dispose);
      final siteId = await _startHome(c);
      await db.setSitePaidCoins(siteId, 42);

      final refund = await c.read(cityActionsProvider).cancelSite(siteId);

      expect(refund, 42);
      expect(await db.siteById(siteId), isNull);
      expect((await db.getPlayerById(pid)).creditBalance, 42);
    });

    test('an unpaid site cancels for nothing', () async {
      final (db, pid, c) = await _setup();
      addTearDown(c.dispose);
      final siteId = await _startHome(c);

      expect(await c.read(cityActionsProvider).cancelSite(siteId), 0);
      expect(await db.siteById(siteId), isNull);
      expect((await db.getPlayerById(pid)).creditBalance, 0);
    });

    test('a site that no longer exists returns null', () async {
      final (_, _, c) = await _setup();
      addTearDown(c.dispose);
      expect(await c.read(cityActionsProvider).cancelSite(999), isNull);
    });
  });

  group('CityActions.applyCredit', () {
    test('pays what the site needs and keeps the rest', () async {
      final (db, pid, c) = await _setup();
      addTearDown(c.dispose);
      final siteId = await _startHome(c);
      await db.setSitePaidCoins(siteId, 50); // price 60 → needs 10
      await db.addCredit(pid, 30);

      final result = await c.read(cityActionsProvider).applyCredit(siteId);

      expect(result, isNotNull);
      expect(result!.accepted, 10);
      expect(result.opened, isTrue);
      expect(await db.siteById(siteId), isNull, reason: 'opened → row gone');
      final city = await db.cityForPlayer(pid);
      expect(
        (await db.placementsForCity(city.id)).map((p) => p.buildingTypeId),
        contains('single_home'),
      );
      expect((await db.getPlayerById(pid)).creditBalance, 20);
    });

    test('pays all the credit when it is less than the site needs', () async {
      final (db, pid, c) = await _setup();
      addTearDown(c.dispose);
      final siteId = await _startHome(c);
      await db.addCredit(pid, 25);

      final result = await c.read(cityActionsProvider).applyCredit(siteId);

      expect(result!.accepted, 25);
      expect(result.opened, isFalse);
      expect((await db.siteById(siteId))!.paidCoins, 25);
      expect((await db.getPlayerById(pid)).creditBalance, 0);
    });

    test('no credit → nothing happens', () async {
      final (db, _, c) = await _setup();
      addTearDown(c.dispose);
      final siteId = await _startHome(c);
      expect(await c.read(cityActionsProvider).applyCredit(siteId), isNull);
      expect((await db.siteById(siteId))!.paidCoins, 0);
    });

    test('cancel then use credit moves the coins between sites', () async {
      final (db, pid, c) = await _setup();
      addTearDown(c.dispose);
      final first = await _startHome(c);
      await db.setSitePaidCoins(first, 42);
      await c.read(cityActionsProvider).cancelSite(first);
      final second = await _startHome(c, col: 4);

      final result = await c.read(cityActionsProvider).applyCredit(second);

      expect(result!.accepted, 42);
      expect((await db.siteById(second))!.paidCoins, 42);
      expect((await db.getPlayerById(pid)).creditBalance, 0);
    });
  });
}
