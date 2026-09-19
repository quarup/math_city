/// Upgrade ladders — which building arcs can be *upgraded in place* and paid
/// for the difference (city_builder.md §8.6). An upgrade is a construction
/// site whose target is the next rung and whose price is
/// `target.coinCost − source.coinCost`; the old building stands and counts
/// until the new one opens.
///
/// Pure Dart: no Flutter / Flame / Drift imports.
library;

import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/building_type.dart';

/// Every ladder, bottom rung first. A building appears in at most one ladder
/// and every consecutive pair is a strictly price-monotonic step with a
/// footprint that never shrinks (both enforced by `upgrade_ladders_test`).
///
/// - Housing spine (§8.6): `duplex`, `townhouse_row`, `farmhouse` are side
///   rungs — buildable from scratch, never upgrade targets.
/// - Two entertainment ladders end in the two landmark parks (§8.6 asked for
///   one "ending in `zoo` / `amusement_park`"; they sit on different arcs, so
///   one green ladder and one sports ladder): parks grow into a botanical
///   garden and then a zoo; a sports field grows into a stadium and then an
///   amusement park.
const upgradeLadders = <List<String>>[
  [
    'single_home',
    'apartment',
    'mid_rise_apartment',
    'high_rise',
    'luxury_condo',
  ],
  ['power_plant', 'power_station', 'solar_farm'],
  ['water_tower', 'water_treatment'],
  ['clinic', 'hospital'],
  ['school', 'high_school'],
  ['mayors_office', 'town_hall', 'city_hall'],
  ['park', 'botanical_garden', 'zoo'],
  ['sports_field', 'stadium', 'amusement_park'],
];

/// The ladder containing [typeId], or null if it is not a ladder rung.
List<String>? ladderOf(String typeId) {
  for (final ladder in upgradeLadders) {
    if (ladder.contains(typeId)) return ladder;
  }
  return null;
}

/// The rung directly above [typeId] (the catalog shows it at the delta price
/// next to a placed building), or null at the top of a ladder / off-ladder.
BuildingType? nextRung(String typeId) {
  final ladder = ladderOf(typeId);
  if (ladder == null) return null;
  final i = ladder.indexOf(typeId);
  if (i + 1 >= ladder.length) return null;
  return findBuildingTypeById(ladder[i + 1]);
}

/// Whether [target] is the rung directly above [source].
bool isUpgradeStep({required String source, required String target}) =>
    nextRung(source)?.id == target;

/// Coins a site upgrading [source] into [target] is paid down to:
/// `target.coinCost − source.coinCost` (§8.6). Only meaningful for a declared
/// ladder step, where the difference is always positive.
int upgradeDeltaPrice({
  required BuildingType source,
  required BuildingType target,
}) {
  assert(
    isUpgradeStep(source: source.id, target: target.id),
    '${target.id} is not the rung above ${source.id}',
  );
  return target.coinCost - source.coinCost;
}

/// Every rung *below* [typeId] on its ladder (nearest first). An opened
/// upgrade removes its source, so unlock rules keyed on
/// `requiredBuildingsPlaced` (e.g. `single_home` needs `mayors_office`) must
/// treat a placed rung as also satisfying its ancestors — a city hall is
/// still a mayor's office. See [placedWithLadderAncestors].
List<String> ladderAncestors(String typeId) {
  final ladder = ladderOf(typeId);
  if (ladder == null) return const <String>[];
  final i = ladder.indexOf(typeId);
  return ladder.sublist(0, i).reversed.toList();
}

/// [placedTypeIds] plus the ladder ancestors of every placed rung. Feed the
/// result to `UnlockContext.placedBuildingTypeIds` so upgrading a building
/// away never re-locks what it had unlocked.
Set<String> placedWithLadderAncestors(Iterable<String> placedTypeIds) => {
  for (final id in placedTypeIds) ...[id, ...ladderAncestors(id)],
};
