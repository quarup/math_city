import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/city/city_map_registry.dart';
import 'package:math_city/domain/city/land_blocks.dart';

void main() {
  setUp(() {
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  group('createPlayer auto-creates city-builder state', () {
    test('inserts a beginner City row for the new player', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final player = await db.createPlayer(
        name: 'Alex',
        gradeLevel: 2,
        avatarConfigJson: '{}',
      );

      final cities = await (db.select(
        db.cities,
      )..where((t) => t.playerId.equals(player.id))).get();
      expect(cities, hasLength(1));
      expect(cities.first.cityMapId, beginnerCityMap.id);
      expect(cities.first.population, 0);
    });

    test('seeds the starting 3×3 owned land blocks', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final player = await db.createPlayer(
        name: 'Robin',
        gradeLevel: 2,
        avatarConfigJson: '{}',
      );
      final city = await db.cityForPlayer(player.id);

      final owned = await db.ownedBlocksForCity(city.id);
      expect(owned, startingOwnedBlocks());
      expect(owned, hasLength(9));
    });

    test('two players each get their own beginner city', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final a = await db.createPlayer(
        name: 'A',
        gradeLevel: 1,
        avatarConfigJson: '{}',
      );
      final b = await db.createPlayer(
        name: 'B',
        gradeLevel: 1,
        avatarConfigJson: '{}',
      );

      final allCities = await db.select(db.cities).get();
      expect(allCities, hasLength(2));
      expect(
        allCities.map((c) => c.playerId).toSet(),
        {a.id, b.id},
      );
    });

    test('Players default coins and streak to zero', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await db.createPlayer(
        name: 'Z',
        gradeLevel: 3,
        avatarConfigJson: '{}',
      );
      expect(p.lifetimeCoinsEarned, 0);
      expect(p.streakCount, 0);
    });
  });

  group('addLifetimeCoins', () {
    test('bumps the lifetime counter monotonically', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await db.createPlayer(
        name: 'R',
        gradeLevel: 2,
        avatarConfigJson: '{}',
      );

      await db.addLifetimeCoins(p.id, 30);
      var fetched = await db.getPlayerById(p.id);
      expect(fetched.lifetimeCoinsEarned, 30);

      await db.addLifetimeCoins(p.id, 20);
      fetched = await db.getPlayerById(p.id);
      expect(fetched.lifetimeCoinsEarned, 50);
    });
  });

  group('setPlayerStreakCount', () {
    test('persists the streak across reads', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await db.createPlayer(
        name: 'S',
        gradeLevel: 2,
        avatarConfigJson: '{}',
      );
      await db.setPlayerStreakCount(p.id, 3);
      expect((await db.getPlayerById(p.id)).streakCount, 3);
      await db.setPlayerStreakCount(p.id, 0);
      expect((await db.getPlayerById(p.id)).streakCount, 0);
    });
  });

  group('recordBandMilestone', () {
    test('writes a row; idempotent on duplicate', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await db.createPlayer(
        name: 'M',
        gradeLevel: 2,
        avatarConfigJson: '{}',
      );

      await db.recordBandMilestone(p.id, 'add_within_10', 0);
      var awarded = await db.awardedBandIndicesFor(p.id, 'add_within_10');
      expect(awarded, {0});

      // Second write with the same triple should not error and should not
      // change the set.
      await db.recordBandMilestone(p.id, 'add_within_10', 0);
      awarded = await db.awardedBandIndicesFor(p.id, 'add_within_10');
      expect(awarded, {0});

      // Second band on the same concept stacks.
      await db.recordBandMilestone(p.id, 'add_within_10', 1);
      awarded = await db.awardedBandIndicesFor(p.id, 'add_within_10');
      expect(awarded, {0, 1});

      // Different concept is independent.
      final other = await db.awardedBandIndicesFor(p.id, 'sub_within_10');
      expect(other, isEmpty);
    });
  });
}
