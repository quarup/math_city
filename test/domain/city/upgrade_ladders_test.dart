import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/building_type.dart';
import 'package:math_city/domain/city/upgrade_ladders.dart';

BuildingType _type(String id) => findBuildingTypeById(id)!;

void main() {
  group('upgradeLadders', () {
    test('every rung is a registered building', () {
      for (final ladder in upgradeLadders) {
        for (final id in ladder) {
          expect(findBuildingTypeById(id), isNotNull, reason: id);
        }
      }
    });

    test('a building sits on at most one ladder, once', () {
      final seen = <String>{};
      for (final ladder in upgradeLadders) {
        for (final id in ladder) {
          expect(seen.add(id), isTrue, reason: '$id appears twice');
        }
      }
    });

    test('every ladder has at least two rungs', () {
      for (final ladder in upgradeLadders) {
        expect(ladder.length, greaterThanOrEqualTo(2), reason: '$ladder');
      }
    });

    test('every declared ladder is strictly price-monotonic', () {
      for (final ladder in upgradeLadders) {
        for (var i = 0; i + 1 < ladder.length; i++) {
          final a = _type(ladder[i]);
          final b = _type(ladder[i + 1]);
          expect(
            b.coinCost,
            greaterThan(a.coinCost),
            reason: '${a.id} (${a.coinCost}) → ${b.id} (${b.coinCost})',
          );
        }
      }
    });

    test('footprints never shrink up a ladder', () {
      for (final ladder in upgradeLadders) {
        for (var i = 0; i + 1 < ladder.length; i++) {
          final a = _type(ladder[i]);
          final b = _type(ladder[i + 1]);
          final areaA = a.footprint.$1 * a.footprint.$2;
          final areaB = b.footprint.$1 * b.footprint.$2;
          expect(
            areaB,
            greaterThanOrEqualTo(areaA),
            reason: '${a.id} → ${b.id}',
          );
        }
      }
    });

    test('rungs stay in one category', () {
      for (final ladder in upgradeLadders) {
        final cats = ladder.map((id) => _type(id).category).toSet();
        expect(cats.length, 1, reason: '$ladder');
      }
    });

    test('housing is two ladders and a landmark (city_builder.md §10.6)', () {
      expect(ladderOf('single_home'), [
        'single_home',
        'duplex',
        'townhouse_row',
      ]);
      expect(ladderOf('apartment'), [
        'apartment',
        'mid_rise_apartment',
        'high_rise',
      ]);
      expect(ladderOf('luxury_condo'), isNull);
      expect(ladderOf('farmhouse'), isNull);
    });

    test('the civic chain is upgrade-only; roots and others are not', () {
      expect(isUpgradeOnly('town_hall'), isTrue);
      expect(isUpgradeOnly('city_hall'), isTrue);
      expect(isUpgradeOnly('mayors_office'), isFalse);
      expect(isUpgradeOnly('high_rise'), isFalse);
      expect(isUpgradeOnly('bakery'), isFalse);
      expect(rungBelow('high_rise'), 'mid_rise_apartment');
      expect(rungBelow('apartment'), isNull);
      expect(rungBelow('zoo'), 'botanical_garden');
    });

    test('the entertainment ladders end in the zoo and the amusement park', () {
      expect(ladderOf('park')!.last, 'zoo');
      expect(ladderOf('sports_field')!.last, 'amusement_park');
    });
  });

  group('nextRung / isUpgradeStep', () {
    test('walks one rung up', () {
      expect(nextRung('single_home')!.id, 'duplex');
      expect(nextRung('apartment')!.id, 'mid_rise_apartment');
      expect(nextRung('mayors_office')!.id, 'town_hall');
      expect(nextRung('park')!.id, 'community_garden');
    });

    test('null at the top and off-ladder', () {
      expect(nextRung('high_rise'), isNull);
      expect(nextRung('luxury_condo'), isNull);
      expect(nextRung('bakery'), isNull);
      expect(nextRung('no_such_building'), isNull);
    });

    test('only the adjacent rung is a step', () {
      expect(isUpgradeStep(source: 'single_home', target: 'duplex'), isTrue);
      expect(
        isUpgradeStep(source: 'single_home', target: 'townhouse_row'),
        isFalse,
      );
      expect(
        isUpgradeStep(source: 'single_home', target: 'apartment'),
        isFalse,
      );
      expect(isUpgradeStep(source: 'bakery', target: 'restaurant'), isFalse);
    });
  });

  group('upgradeDeltaPrice', () {
    test('matches the §10.6 housing tables', () {
      int delta(String s, String t) =>
          upgradeDeltaPrice(source: _type(s), target: _type(t));
      expect(delta('single_home', 'duplex'), 60);
      expect(delta('duplex', 'townhouse_row'), 180);
      expect(delta('apartment', 'mid_rise_apartment'), 600);
      expect(delta('mid_rise_apartment', 'high_rise'), 780);
    });

    test('walking a whole ladder costs the top rung, not the sum', () {
      for (final ladder in upgradeLadders) {
        var total = _type(ladder.first).coinCost;
        for (var i = 0; i + 1 < ladder.length; i++) {
          total += upgradeDeltaPrice(
            source: _type(ladder[i]),
            target: _type(ladder[i + 1]),
          );
        }
        expect(total, _type(ladder.last).coinCost, reason: ladder.join(' → '));
      }
    });
  });

  group('ladder ancestors', () {
    test('lists the rungs below, nearest first', () {
      expect(ladderAncestors('city_hall'), ['town_hall', 'mayors_office']);
      expect(ladderAncestors('mayors_office'), isEmpty);
      expect(ladderAncestors('bakery'), isEmpty);
    });

    test('an upgraded-away source still satisfies unlock rules', () {
      // A town hall replaced the mayor's office; `single_home` still needs
      // 'mayors_office' placed, so the expanded set must contain it.
      final placed = placedWithLadderAncestors({'town_hall', 'single_home'});
      expect(
        placed,
        containsAll({'town_hall', 'mayors_office', 'single_home'}),
      );
      expect(placed.length, 3);
    });
  });
}
