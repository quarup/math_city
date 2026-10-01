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

    test('taxis only appear once the town has 40 people', () {
      final random = math.Random(5);
      var early = 0;
      var late = 0;
      for (var i = 0; i < 1000; i++) {
        if (drawCivilianKind(random, const [], population: 20).id == 'taxi') {
          early++;
        }
        if (drawCivilianKind(random, const [], population: 60).id == 'taxi') {
          late++;
        }
      }
      expect(early, 0);
      expect(late, greaterThan(0));
    });

    test('a farmhouse makes pickups common', () {
      final random = math.Random(5);
      var pickups = 0;
      for (var i = 0; i < 2000; i++) {
        if (drawCivilianKind(random, const ['farmhouse']).id == 'pickup') {
          pickups++;
        }
      }
      expect(pickups, greaterThan(350)); // 3 of 10 by weight
    });
  });

  test('every kind is registered once', () {
    final ids = vehicleKinds.map((k) => k.id).toList();
    expect(ids.toSet().length, ids.length);
    expect(vehicleKindById('bus').length, 0.9);
  });

  group('leaving town (2026-10-01)', () {
    test('town services stay inside the fence, civilians come and go', () {
      for (final id in [
        'school_bus',
        'ice_cream_truck',
        'garbage_truck',
        'police_car',
        'fire_truck',
        'ambulance',
      ]) {
        expect(vehicleKindById(id).leavesTown, isFalse, reason: id);
      }
      for (final id in [
        'hatchback',
        'sedan',
        'taxi',
        'bus',
        'delivery_truck',
      ]) {
        expect(vehicleKindById(id).leavesTown, isTrue, reason: id);
      }
    });

    test('commuters are drawn from the civilian kinds that leave town', () {
      final r = math.Random(3);
      for (var i = 0; i < 50; i++) {
        final kind = drawCommuterKind(r);
        expect(kind.leavesTown, isTrue);
        expect(kind.isGated, isFalse);
      }
      expect(kCommutersPerExit, greaterThan(0));
    });
  });

  group('time of day (2026-10-01)', () {
    const buildings = [
      'school',
      'park',
      'post_office',
      'waste_management',
      'police_station',
    ];

    StreetLifePlan at(double hour) => planStreetLife(
      population: 200,
      roadTiles: 100,
      buildingIds: buildings,
      hour: hour,
    );

    test('without an hour the plan is the full daytime budget', () {
      final full = planStreetLife(
        population: 200,
        roadTiles: 100,
        buildingIds: buildings,
      );
      expect(at(8).pedestrians, full.pedestrians);
      expect(at(12).civilians, full.civilians);
    });

    test('nobody walks in the middle of the night', () {
      for (final h in [23.0, 0.0, 2.5, 5.0]) {
        expect(at(h).pedestrians, 0, reason: 'hour $h');
      }
      expect(at(8).pedestrians, greaterThan(0));
      expect(at(17).pedestrians, greaterThan(at(14).pedestrians));
      expect(at(21).pedestrians, lessThan(at(19).pedestrians));
    });

    test('the school bus keeps school hours, the ice cream truck the day', () {
      expect(vehicleKindById('school_bus').isOutAt(9), isTrue);
      expect(vehicleKindById('school_bus').isOutAt(18), isFalse);
      expect(vehicleKindById('ice_cream_truck').isOutAt(14), isTrue);
      expect(vehicleKindById('ice_cream_truck').isOutAt(9), isFalse);
      expect(vehicleKindById('ice_cream_truck').isOutAt(22), isFalse);
      expect(vehicleKindById('garbage_truck').isOutAt(2), isFalse);
      expect(vehicleKindById('mail_van').isOutAt(20), isFalse);
    });

    test('gated kinds outside their hours stay in', () {
      final day = at(12).gated;
      final night = at(1).gated;
      for (final id in night.keys) {
        expect(vehicleKindById(id).hours, isNull, reason: id);
      }
      expect(night.length, lessThanOrEqualTo(day.length));
      expect(night.containsKey('school_bus'), isFalse);
    });

    test('emergency vehicles are out at any hour', () {
      for (final id in ['police_car', 'ambulance', 'fire_truck']) {
        expect(vehicleKindById(id).isOutAt(3), isTrue, reason: id);
      }
    });

    test('some cars are still out at night, more sparsely', () {
      expect(at(2).civilians, greaterThan(0));
      expect(at(2).civilians, lessThan(at(12).civilians));
      expect(commutersPerExitAt(12), kCommutersPerExit);
      expect(commutersPerExitAt(2), inInclusiveRange(1, kCommutersPerExit - 1));
    });
  });
}
