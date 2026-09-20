import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';

void main() {
  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  Future<(AppDatabase, Player, City)> freshCity() async {
    final db = AppDatabase(NativeDatabase.memory());
    final player = await db.createPlayer(
      name: 'Pat',
      gradeLevel: 3,
      avatarConfigJson: '{}',
    );
    final city = await db.cityForPlayer(player.id);
    return (db, player, city);
  }

  group('addOwnedLandBlock', () {
    test('records ownership without touching coins', () async {
      final (db, player, city) = await freshCity();
      await db.addLifetimeCoins(player.id, 100);

      await db.addOwnedLandBlock(cityId: city.id, blockX: 2, blockY: 0);

      final owned = await db.ownedBlocksForCity(city.id);
      expect(owned.contains((2, 0)), isTrue);
      expect(owned, hasLength(10)); // 9 starting + 1 bought

      final after = await db.getPlayerById(player.id);
      expect(after.lifetimeCoinsEarned, 100);
    });

    test(
      'adding the same block twice is rejected by the primary key',
      () async {
        final (db, _, city) = await freshCity();
        await db.addOwnedLandBlock(cityId: city.id, blockX: 2, blockY: 0);
        expect(
          () => db.addOwnedLandBlock(cityId: city.id, blockX: 2, blockY: 0),
          throwsA(anything),
        );
      },
    );
  });
}
