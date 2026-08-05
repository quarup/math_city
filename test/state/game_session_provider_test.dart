import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/state/game_session_provider.dart';
import 'package:math_city/state/player_provider.dart';

AppDatabase _testDb() {
  // Each test gets an isolated in-memory DB; multiple instances intentional.
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

void main() {
  group('TotalBricksNotifier', () {
    late ProviderContainer container;

    setUp(
      () => container = ProviderContainer(
        overrides: [appDatabaseProvider.overrideWithValue(_testDb())],
      ),
    );
    tearDown(() => container.dispose());

    test('starts at zero', () {
      expect(container.read(totalBricksProvider), 0);
    });

    test('add increments the total', () {
      container.read(totalBricksProvider.notifier).add(3);
      expect(container.read(totalBricksProvider), 3);
    });

    test('multiple adds accumulate', () {
      container.read(totalBricksProvider.notifier).add(3);
      container.read(totalBricksProvider.notifier).add(5);
      container.read(totalBricksProvider.notifier).add(1);
      expect(container.read(totalBricksProvider), 9);
    });
  });

  // Regression: bricks earned in the math loop were persisted but only
  // `allPlayersProvider` was invalidated, so the city screen — which reads
  // `brickBalance` off `activePlayerProvider` — kept serving the balance
  // cached at player-select time (0 for a new account) and nothing was
  // affordable. See CityActions.placeBuilding / _CurrencyBar.
  group('earning bricks refreshes the city screen', () {
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

    // `add` persists off the main path (unawaited) and invalidates once the
    // write lands, so let the event queue drain before asserting.
    Future<void> settle() async {
      await pumpEventQueue();
      await container.read(activePlayerProvider.future);
    }

    test('activePlayerProvider reflects the new balance', () async {
      expect(container.read(activePlayerProvider).value!.brickBalance, 0);

      container.read(totalBricksProvider.notifier).add(7);
      await settle();

      expect(container.read(activePlayerProvider).value!.brickBalance, 7);
    });

    test('lifetime bricks keep climbing across rounds', () async {
      for (var i = 0; i < 3; i++) {
        container.read(totalBricksProvider.notifier).add(4);
        await settle();
      }

      final player = await db.getPlayerById(playerId);
      expect(player.brickBalance, 12);
      expect(player.lifetimeBricksEarned, 12);
      expect(container.read(totalBricksProvider), 12);
    });

    test('a spend after an earn nets out correctly', () async {
      container.read(totalBricksProvider.notifier).add(10);
      await settle();

      await db.incrementPlayerBricks(playerId, -6);
      container.invalidate(activePlayerProvider);
      await settle();

      expect(container.read(totalBricksProvider), 4);
      final player = await db.getPlayerById(playerId);
      expect(player.brickBalance, 4);
      // Lifetime is monotone — spending must not claw it back.
      expect(player.lifetimeBricksEarned, 10);
    });
  });
}
