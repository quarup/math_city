import 'package:math_city/domain/city/city_map.dart';

/// Phase 7 ships exactly one map — the beginner. Phases 8/9 add the rest.
const cityMapRegistry = <CityMap>[
  CityMap(
    id: 'beginner',
    name: 'Beginner town',
    theme: CityMapTheme.beginner,
    baseGridWidth: 12,
    baseGridHeight: 12,
    brickUnlockCost: 0,
    terrainSeed: 0,
  ),
];

/// The map every player starts with — auto-spawned at player creation.
const String beginnerCityMapId = 'beginner';
CityMap get beginnerCityMap => cityMapRegistry.first;

CityMap? findCityMapById(String id) {
  for (final m in cityMapRegistry) {
    if (m.id == id) return m;
  }
  return null;
}
