import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/construction_site.dart';
import 'package:math_city/state/city_provider.dart';
import 'package:math_city/state/game_session_provider.dart';
import 'package:math_city/state/player_provider.dart';

AppDatabase _testDb() {
  // Each test gets an isolated in-memory DB; multiple instances intentional.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

void main() {
  // The active site is where a session's coins go; every screen that shows
  // the `paid / price` bar (spin, question, summary) reads it from here.
  group('activeSiteProvider', () {
    late AppDatabase db;
    late ProviderContainer container;
    late int playerId;

    setUp(() async {
      db = _testDb();
      final player = await db.createPlayer(
        name: 'Sam',
        gradeLevel: 2,
        avatarConfigJson: '{}',
      );
      playerId = player.id;
      container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(db)],
      );
      container.read(activePlayerIdProvider.notifier).selected = playerId;
      await container.read(activePlayerProvider.future);
    });
    tearDown(() => container.dispose());

    test('null until a site is selected', () async {
      expect(await container.read(activeSiteProvider.future), isNull);
    });

    test('resolves the selected site with its paid-in coins', () async {
      final home = findBuildingTypeById('single_home')!;
      final start = await container
          .read(cityActionsProvider)
          .startSite(BuildingGoal(type: home, col: 0, row: 0));
      expect(start.ok, isTrue);
      container.read(activeSiteIdProvider.notifier).selected = start.siteId;

      final before = await container.read(activeSiteProvider.future);
      expect(before!.id, start.siteId);
      expect(before.site.paidCoins, 0);
      expect(before.site.price, home.coinCost);

      await container.read(cityActionsProvider).payIntoSite(start.siteId!, 20);
      final after = await container.read(activeSiteProvider.future);
      expect(after!.site.paidCoins, 20);
    });

    test('null again once the site has opened', () async {
      final home = findBuildingTypeById('single_home')!;
      final start = await container
          .read(cityActionsProvider)
          .startSite(BuildingGoal(type: home, col: 0, row: 0));
      container.read(activeSiteIdProvider.notifier).selected = start.siteId;
      await container
          .read(cityActionsProvider)
          .payIntoSite(start.siteId!, home.coinCost);
      expect(await container.read(activeSiteProvider.future), isNull);
    });
  });
}
