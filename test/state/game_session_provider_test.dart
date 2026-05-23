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
}
