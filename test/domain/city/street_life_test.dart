import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/street_life.dart';

void main() {
  group('planStreetLife', () {
    test('the starter ring is empty until someone moves in', () {
      final plan = planStreetLife(
        population: 0,
        roadTiles: 8,
        buildingIds: const ['mayors_office'],
      );
      expect(plan.pedestrians, 0);
      expect(plan.cars, 0);
    });

    test('the first home puts one car and two walkers out', () {
      final plan = planStreetLife(
        population: 4,
        roadTiles: 8,
        buildingIds: const ['mayors_office', 'single_home'],
      );
      expect(plan.cars, 1);
      expect(plan.civilians, 1);
      expect(plan.pedestrians, 2);
    });

    test('a small town: 3 cars, 7 walkers', () {
      final plan = planStreetLife(
        population: 20,
        roadTiles: 26,
        buildingIds: const [],
      );
      expect(plan.cars, 3);
      expect(plan.pedestrians, 7);
    });

    test('scales with the road network, never capped', () {
      final plan = planStreetLife(
        population: 5000,
        roadTiles: 1000,
        buildingIds: const [],
      );
      expect(plan.cars, 150);
      expect(plan.pedestrians, 300);
    });

    test('population bounds the total when roads outnumber people', () {
      final plan = planStreetLife(
        population: 6,
        roadTiles: 100,
        buildingIds: const [],
      );
      expect(plan.cars + plan.pedestrians, lessThanOrEqualTo(6));
    });

    test('service buildings put their vehicles on the road first', () {
      final plan = planStreetLife(
        population: 400,
        roadTiles: 120,
        buildingIds: const [
          'police_station',
          'clinic',
          'hospital',
          'bus_depot',
          'bus_depot',
          'bus_depot',
          'farmhouse',
        ],
      );
      expect(plan.gated['police_car'], 1);
      expect(plan.gated['ambulance'], 2);
      expect(plan.gated['bus'], 2); // capped
      expect(plan.gated['tractor'], 1);
      expect(plan.gated.containsKey('fire_truck'), isFalse);
      expect(plan.cars, 18);
      expect(plan.civilians, 18 - 6);
    });

    test('gated vehicles never exceed the car budget', () {
      final plan = planStreetLife(
        population: 4,
        roadTiles: 8,
        buildingIds: const ['police_station', 'fire_station', 'bus_depot'],
      );
      expect(plan.cars, 1);
      expect(plan.gated, {'police_car': 1});
      expect(plan.civilians, 0);
    });
  });

  group('drawCivilianKind', () {
    test('only draws ungated kinds, roughly by weight', () {
      final random = math.Random(5);
      final seen = <String, int>{};
      for (var i = 0; i < 2000; i++) {
        final k = drawCivilianKind(random, const []);
        expect(k.isGated, isFalse);
        seen[k.id] = (seen[k.id] ?? 0) + 1;
      }
      expect(seen['hatchback'], greaterThan(seen['van']!));
      expect(seen['hatchback'], greaterThan(seen['suv']!));
    });

    test('a farmhouse makes pickups common', () {
      final random = math.Random(5);
      var pickups = 0;
      for (var i = 0; i < 2000; i++) {
        if (drawCivilianKind(random, const ['farmhouse']).id == 'pickup') {
          pickups++;
        }
      }
      expect(pickups, greaterThan(400)); // 3 of 10 by weight
    });
  });

  test('every kind is registered once', () {
    final ids = vehicleKinds.map((k) => k.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(vehicleKindById('bus').length, 0.9);
  });
}
