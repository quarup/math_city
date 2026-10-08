import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/beat_registry.dart';
import 'package:math_city/domain/city/citizen.dart';
import 'package:math_city/domain/city/story_beat.dart';
import 'package:math_city/domain/city/trigger_rule.dart';

void main() {
  group('cast', () {
    test('ten citizens with unique ids and stable faces', () {
      expect(castRegistry.length, 10);
      expect(castRegistry.map((c) => c.id).toSet().length, 10);
      // A seeded face is the same on every build.
      expect(
        findCitizenById('pomeroy')!.face,
        findCitizenById('pomeroy')!.face,
      );
    });

    test('every beat resolves to a citizen', () {
      for (final beat in beatRegistry) {
        expect(citizenForBeat(beat), isNotNull, reason: beat.id);
      }
    });

    test('warnings come from Mr. Grumbold, homes from Mrs. Pomeroy', () {
      final warning = beatRegistry.firstWhere(
        (b) => b.kind == BeatKind.warning,
      );
      expect(citizenForBeat(warning).id, 'grumbold');
      expect(citizenForBeat(findBeatById('demand_first_home')!).id, 'pomeroy');
      expect(citizenForBeat(findBeatById('demand_grocery')!).id, 'alvarez');
    });
  });

  group('Times asks', () {
    // Capacity asks read as news but behave as demands: Build it! / Later
    // on the page, a badged card, cleared when the building goes up.
    const asks = {
      'demand_waste': 'waste_management',
      'demand_water': 'water_tower',
      'demand_power_station': 'power_station',
      'demand_water_treatment': 'water_treatment',
      'demand_hospital': 'hospital',
    };
    test('are demands delivered as front pages that name their building', () {
      for (final entry in asks.entries) {
        final beat = findBeatById(entry.key)!;
        expect(beat.kind, BeatKind.demand, reason: beat.id);
        expect(beat.staticDelivery, BeatDelivery.times, reason: beat.id);
        expect(beatTargetBuilding(beat)?.id, entry.value, reason: beat.id);
      }
    });

    test('only the two balance warnings are still warnings', () {
      expect(
        beatRegistry.where((b) => b.kind == BeatKind.warning).map((b) => b.id),
        unorderedEquals(['warn_lopsided', 'warn_growth_stalled']),
      );
    });
  });

  group('beatTargetBuilding', () {
    test('every demand beat names the building it asks for', () {
      for (final beat in beatRegistry.where(
        (b) => b.kind == BeatKind.demand && b.event == null,
      )) {
        expect(beatTargetBuilding(beat), isNotNull, reason: beat.id);
      }
      // An event letter is about a party, not a building.
      expect(beatTargetBuilding(findBeatById('event_block_party')!), isNull);
    });

    test('the first-home letter is about the single home', () {
      expect(
        beatTargetBuilding(findBeatById('demand_first_home')!)!.id,
        'single_home',
      );
      expect(beatTargetBuilding(findBeatById('praise_school')!)!.id, 'school');
    });
  });

  group('under construction counts as present', () {
    const rule = TriggerRule(
      buildingsPresent: {'mayors_office'},
      buildingsAbsent: {'single_home'},
    );
    TriggerContext ctx({Set<String> sites = const {}}) => TriggerContext(
      placedBuildingTypeIds: const {'mayors_office'},
      population: 0,
      maxBuildingAgeByTypeId: const {},
      firedBeatIds: const {},
      coinsEarnedSinceBeatLastFired: null,
      underConstructionTypeIds: sites,
    );

    test('fires with no site, not while the home is being built', () {
      expect(rule.evaluate(ctx()), isTrue);
      expect(rule.evaluate(ctx(sites: {'single_home'})), isFalse);
    });
  });
}
