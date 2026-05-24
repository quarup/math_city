import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/city/beat_registry.dart';
import 'package:math_city/domain/city/building_registry.dart';

void main() {
  test('beat ids are unique', () {
    final ids = beatRegistry.map((b) => b.id).toList();
    expect(ids.toSet().length, ids.length);
  });

  test(
    'every building a trigger references exists in the building registry',
    () {
      for (final beat in beatRegistry) {
        final rule = beat.triggerRule;
        final refs = <String>{
          ...rule.buildingsPresent,
          ...rule.buildingsAbsent,
          if (rule.minBuildingAgeForId != null)
            rule.minBuildingAgeForId!.buildingTypeId,
        };
        for (final id in refs) {
          expect(
            findBuildingTypeById(id),
            isNotNull,
            reason: 'beat "${beat.id}" references unknown building "$id"',
          );
        }
      }
    },
  );

  test('every requiredBeatsFired references a real beat', () {
    for (final beat in beatRegistry) {
      for (final id in beat.triggerRule.requiredBeatsFired) {
        expect(
          findBeatById(id),
          isNotNull,
          reason: 'beat "${beat.id}" requires unknown beat "$id"',
        );
      }
    }
  });

  test('every beat has non-empty emoji, label, and text', () {
    for (final beat in beatRegistry) {
      expect(beat.emoji, isNotEmpty, reason: beat.id);
      expect(beat.shortLabel, isNotEmpty, reason: beat.id);
      expect(beat.longText, isNotEmpty, reason: beat.id);
    }
  });

  test('findBeatById round-trips and returns null for unknown ids', () {
    expect(findBeatById('demand_clinic')?.id, 'demand_clinic');
    expect(findBeatById('not_a_beat'), isNull);
  });
}
