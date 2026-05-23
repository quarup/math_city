import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/city/city_map_registry.dart';

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
      expect(cities.first.gridWidth, beginnerCityMap.baseGridWidth);
      expect(cities.first.gridHeight, beginnerCityMap.baseGridHeight);
      expect(cities.first.population, 0);
    });

    test("pre-researches the mayor's office for the new player", () async {
      final db = AppDatabase(NativeDatabase.memory());
      final player = await db.createPlayer(
        name: 'Sam',
        gradeLevel: 4,
        avatarConfigJson: '{}',
      );

      final rows = await (db.select(
        db.buildingTypesResearched,
      )..where((t) => t.playerId.equals(player.id))).get();
      expect(rows.map((r) => r.buildingTypeId), ['mayors_office']);
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

    test('Players default 🧱 and 🔬 balances to zero', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await db.createPlayer(
        name: 'Z',
        gradeLevel: 3,
        avatarConfigJson: '{}',
      );
      expect(p.brickBalance, 0);
      expect(p.lifetimeBricksEarned, 0);
      expect(p.researchBalance, 0);
      expect(p.lifetimeResearchEarned, 0);
    });
  });

  group('incrementPlayerResearch', () {
    test('adds to spending balance and bumps lifetime monotonically', () async {
      final db = AppDatabase(NativeDatabase.memory());
      final p = await db.createPlayer(
        name: 'R',
        gradeLevel: 2,
        avatarConfigJson: '{}',
      );

      await db.incrementPlayerResearch(p.id, 3);
      var fetched = await db.getPlayerById(p.id);
      expect(fetched.researchBalance, 3);
      expect(fetched.lifetimeResearchEarned, 3);

      await db.incrementPlayerResearch(p.id, 2);
      fetched = await db.getPlayerById(p.id);
      expect(fetched.researchBalance, 5);
      expect(fetched.lifetimeResearchEarned, 5);

      // Spend 2 (negative delta) — balance drops; lifetime stays.
      await db.incrementPlayerResearch(p.id, -2);
      fetched = await db.getPlayerById(p.id);
      expect(fetched.researchBalance, 3);
      expect(fetched.lifetimeResearchEarned, 5);
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
