/// Street life budget: which vehicle kinds exist, which buildings unlock
/// them, and how many walkers and cars a city gets (city_builder.md §9.5).
///
/// Every count is a *density* of the road network bounded by population —
/// no absolute caps, the map grows without limit. Gated kinds (bus, police
/// car, …) take car slots first, one per gating building; the rest of the
/// car slots are civilians drawn from a weighted pool. The game layer keeps
/// existing movers across replans and only spawns or trims the difference.
///
/// Pure Dart — no Flutter / Flame.
library;

import 'dart:math' as math;

/// One sprite set under `assets/vehicles/<id>_h0..7.png`.
class VehicleKind {
  const VehicleKind({
    required this.id,
    required this.length,
    required this.width,
    this.weight = 0,
    this.gates = const [],
    this.maxCount = 1,
    this.speed = 1,
    this.bonusGate,
    this.bonusWeight = 0,
  });

  final String id;

  /// Ground footprint in tiles (the sheet's `--length` and the width the
  /// cutter reported); drives the contact shadow.
  final double length;
  final double width;

  /// Civilian pool weight; 0 means the kind only appears through [gates].
  final int weight;

  /// Building ids that unlock it: one vehicle per placed gating building,
  /// up to [maxCount].
  final List<String> gates;
  final int maxCount;

  /// Speed multiplier on the base car speed.
  final double speed;

  /// A building that raises the pool weight to [bonusWeight] when placed.
  final String? bonusGate;
  final int bonusWeight;

  bool get isGated => gates.isNotEmpty;
}

/// Every kind with cut sprites, in gated-priority order (emergency first,
/// then transit, then services), civilians last.
const List<VehicleKind> vehicleKinds = [
  VehicleKind(
    id: 'police_car',
    length: 0.46,
    width: 0.22,
    gates: ['police_station'],
    speed: 1.2,
  ),
  VehicleKind(
    id: 'ambulance',
    length: 0.55,
    width: 0.26,
    gates: ['clinic', 'hospital'],
    maxCount: 2,
    speed: 1.2,
  ),
  VehicleKind(
    id: 'fire_truck',
    length: 0.8,
    width: 0.33,
    gates: ['fire_station'],
    speed: 0.9,
  ),
  VehicleKind(
    id: 'bus',
    length: 0.9,
    width: 0.31,
    gates: ['bus_depot'],
    maxCount: 2,
    speed: 0.75,
  ),
  VehicleKind(
    id: 'school_bus',
    length: 0.8,
    width: 0.33,
    gates: ['school', 'high_school'],
    maxCount: 2,
    speed: 0.75,
  ),
  VehicleKind(
    id: 'mail_van',
    length: 0.45,
    width: 0.2,
    gates: ['post_office'],
    speed: 0.9,
  ),
  VehicleKind(
    id: 'delivery_truck',
    length: 0.6,
    width: 0.3,
    gates: ['supermarket', 'grocery', 'shopping_mall'],
    speed: 0.8,
  ),
  VehicleKind(
    id: 'tractor',
    length: 0.4,
    width: 0.21,
    gates: ['farmhouse', 'farmers_market'],
    speed: 0.55,
  ),
  VehicleKind(id: 'hatchback', length: 0.42, width: 0.22, weight: 4),
  VehicleKind(id: 'suv', length: 0.48, width: 0.24, weight: 2),
  VehicleKind(id: 'van', length: 0.5, width: 0.25, weight: 1, speed: 0.9),
  VehicleKind(
    id: 'pickup',
    length: 0.5,
    width: 0.24,
    weight: 1,
    bonusGate: 'farmhouse',
    bonusWeight: 3,
  ),
];

final Map<String, VehicleKind> _kindsById = {
  for (final k in vehicleKinds) k.id: k,
};

VehicleKind vehicleKindById(String id) => _kindsById[id]!;

/// How many movers a city gets and which gated vehicles are on the road.
class StreetLifePlan {
  const StreetLifePlan({
    required this.pedestrians,
    required this.gated,
    required this.civilians,
  });

  static const empty = StreetLifePlan(pedestrians: 0, gated: {}, civilians: 0);

  final int pedestrians;

  /// Kind id → count, for kinds unlocked by buildings.
  final Map<String, int> gated;

  /// Car slots left for the civilian pool.
  final int civilians;

  int get cars => civilians + gated.values.fold(0, (a, b) => a + b);
}

/// Movers per road tile: one per ~2 tiles all told, of which cars at most
/// 0.15 per tile and walkers at most 0.3.
const double kMoverDensity = 0.45;
const double kCarDensity = 0.15;
const double kWalkerDensity = 0.3;

/// The §9.5 budget: `M = min(P, ⌊0.45·R⌋)`, cars `min(⌊M/3⌋, ⌊0.15·R⌋)`
/// with gated kinds first, walkers `min(M − cars, ⌊0.3·R⌋)`.
StreetLifePlan planStreetLife({
  required int population,
  required int roadTiles,
  required Iterable<String> buildingIds,
}) {
  final movers = math.min(population, (kMoverDensity * roadTiles).floor());
  if (movers <= 0) return StreetLifePlan.empty;
  final cars = math.min(movers ~/ 3, (kCarDensity * roadTiles).floor());
  final counts = <String, int>{};
  for (final id in buildingIds) {
    counts[id] = (counts[id] ?? 0) + 1;
  }
  final gated = <String, int>{};
  var used = 0;
  for (final kind in vehicleKinds) {
    if (!kind.isGated || used >= cars) continue;
    var n = 0;
    for (final g in kind.gates) {
      n += counts[g] ?? 0;
    }
    n = math.min(math.min(n, kind.maxCount), cars - used);
    if (n > 0) {
      gated[kind.id] = n;
      used += n;
    }
  }
  return StreetLifePlan(
    pedestrians: math.min(movers - cars, (kWalkerDensity * roadTiles).floor()),
    gated: gated,
    civilians: cars - used,
  );
}

/// A civilian kind drawn from the weighted pool for this city.
VehicleKind drawCivilianKind(math.Random random, Iterable<String> buildingIds) {
  final placed = buildingIds.toSet();
  final pool = <(VehicleKind, int)>[];
  var total = 0;
  for (final kind in vehicleKinds) {
    if (kind.isGated) continue;
    final w = kind.bonusGate != null && placed.contains(kind.bonusGate)
        ? kind.bonusWeight
        : kind.weight;
    if (w <= 0) continue;
    pool.add((kind, w));
    total += w;
  }
  var pick = random.nextInt(total);
  for (final (kind, w) in pool) {
    if (pick < w) return kind;
    pick -= w;
  }
  return pool.last.$1;
}
