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
    this.leavesTown = false,
    this.hours,
    this.bonusGate,
    this.bonusWeight = 0,
    this.minPopulation = 0,
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

  /// Whether this kind drives out past the fence. Town services — the
  /// school bus, the ice cream truck, the garbage truck, the emergency
  /// vehicles — stay inside the perimeter; civilians, the bus and the
  /// delivery truck come and go on the roads that leave town.
  final bool leavesTown;

  /// The hours this kind is out, `(from, to)` on the 24-hour clock; null
  /// for kinds on the road at any hour (emergency vehicles, civilians,
  /// the delivery truck). The school bus keeps school hours, the ice cream
  /// truck the afternoon, the workers their shifts.
  final (double, double)? hours;

  bool isOutAt(double hour) => switch (hours) {
    null => true,
    (final from, final to) => hour >= from && hour < to,
  };

  /// A building that raises the pool weight to [bonusWeight] when placed.
  final String? bonusGate;
  final int bonusWeight;

  /// Civilian kinds below this population stay out of the pool.
  final int minPopulation;

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
    hours: (6, 22),
    leavesTown: true,
    length: 0.9,
    width: 0.31,
    gates: ['bus_depot'],
    maxCount: 2,
    speed: 0.75,
  ),
  VehicleKind(
    id: 'school_bus',
    hours: (7, 16),
    length: 0.8,
    width: 0.33,
    gates: ['school', 'high_school'],
    maxCount: 2,
    speed: 0.75,
  ),
  VehicleKind(
    id: 'mail_van',
    hours: (8, 17),
    length: 0.45,
    width: 0.2,
    gates: ['post_office'],
    speed: 0.9,
  ),
  VehicleKind(
    id: 'delivery_truck',
    leavesTown: true,
    length: 0.6,
    width: 0.3,
    gates: ['supermarket', 'grocery', 'shopping_mall'],
    speed: 0.8,
  ),
  VehicleKind(
    id: 'tractor',
    hours: (6, 18),
    length: 0.4,
    width: 0.21,
    gates: ['farmhouse', 'farmers_market'],
    speed: 0.55,
  ),
  VehicleKind(
    id: 'garbage_truck',
    hours: (6, 14),
    length: 0.7,
    width: 0.3,
    gates: ['waste_management', 'recycling_center'],
    speed: 0.7,
  ),
  VehicleKind(
    id: 'ice_cream_truck',
    hours: (11, 19),
    length: 0.5,
    width: 0.28,
    gates: ['park', 'playground', 'amusement_park'],
    speed: 0.7,
  ),
  VehicleKind(
    id: 'hatchback',
    length: 0.42,
    width: 0.22,
    weight: 4,
    leavesTown: true,
  ),
  VehicleKind(
    id: 'sedan',
    length: 0.46,
    width: 0.24,
    weight: 3,
    leavesTown: true,
  ),
  VehicleKind(
    id: 'taxi',
    leavesTown: true,
    length: 0.46,
    width: 0.21,
    weight: 1,
    minPopulation: 40,
    bonusGate: 'restaurant',
    bonusWeight: 2,
  ),
  VehicleKind(
    id: 'suv',
    length: 0.48,
    width: 0.24,
    weight: 2,
    leavesTown: true,
  ),
  VehicleKind(
    id: 'van',
    length: 0.5,
    width: 0.25,
    weight: 1,
    speed: 0.9,
    leavesTown: true,
  ),
  VehicleKind(
    id: 'pickup',
    leavesTown: true,
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

double _curve(List<(double, double)> keys, double hour) {
  final h = ((hour % 24) + 24) % 24;
  var i = 0;
  while (i + 2 < keys.length && keys[i + 1].$1 <= h) {
    i++;
  }
  final (h0, v0) = keys[i];
  final (h1, v1) = keys[i + 1];
  return v0 + (v1 - v0) * ((h - h0) / (h1 - h0));
}

/// How much of the daytime crowd is out walking at [hour], `0..1`: nobody
/// in the middle of the night, the full crowd at the morning and evening
/// peaks, a little thinner in between.
double pedestrianActivityAt(double hour) => _curve(const [
  (0, 0),
  (5.5, 0),
  (6.5, 0.3),
  (8, 1),
  (9.5, 0.7),
  (12, 0.9),
  (14, 0.7),
  (17, 1),
  (19, 0.6),
  (21, 0.15),
  (22, 0),
  (24, 0),
], hour);

/// How much of the daytime civilian traffic is on the road at [hour]: a
/// third of it through the night, all of it by day.
double civilianActivityAt(double hour) => _curve(const [
  (0, 0.3),
  (5, 0.3),
  (7, 0.8),
  (8, 1),
  (18, 1),
  (20, 0.6),
  (22, 0.35),
  (24, 0.3),
], hour);

/// The §9.5 budget: `M = min(P, ⌊0.45·R⌋)`, cars `min(⌊M/3⌋, ⌊0.15·R⌋)`
/// with gated kinds first, walkers `min(M − cars, ⌊0.3·R⌋)`.
///
/// With an [hour] the plan follows the time of day: kinds outside their
/// [VehicleKind.hours] stay in, the civilian slots thin out at night (never
/// below one car while the town has any) and the walkers follow
/// [pedestrianActivityAt] — none in the middle of the night. Without one
/// it is the full daytime budget.
StreetLifePlan planStreetLife({
  required int population,
  required int roadTiles,
  required Iterable<String> buildingIds,
  double? hour,
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
  final walkers = math.min(movers - cars, (kWalkerDensity * roadTiles).floor());
  final civilians = cars - used;
  if (hour == null) {
    return StreetLifePlan(
      pedestrians: walkers,
      gated: gated,
      civilians: civilians,
    );
  }
  return StreetLifePlan(
    pedestrians: (walkers * pedestrianActivityAt(hour)).round(),
    gated: {
      for (final entry in gated.entries)
        if (vehicleKindById(entry.key).isOutAt(hour)) entry.key: entry.value,
    },
    civilians: civilians == 0
        ? 0
        : math.max(1, (civilians * civilianActivityAt(hour)).round()),
  );
}

/// A civilian kind drawn from the weighted pool for this city.
VehicleKind drawCivilianKind(
  math.Random random,
  Iterable<String> buildingIds, {
  int population = 0,
}) {
  final placed = buildingIds.toSet();
  final pool = <(VehicleKind, int)>[];
  var total = 0;
  for (final kind in vehicleKinds) {
    if (kind.isGated || population < kind.minPopulation) continue;
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

/// Through traffic (2026-10-01): on top of the town's own fleet, this many
/// cars per road out of town drive in from the edge of the map, through
/// the town, and out again by whichever road they reach.
const int kCommutersPerExit = 6;

/// Through traffic per road at [hour]: the full number by day, sparser at
/// night, never none.
int commutersPerExitAt(double hour) => math.max(
  1,
  (kCommutersPerExit * civilianActivityAt(hour)).round(),
);

/// A civilian kind that leaves town, for the through traffic.
VehicleKind drawCommuterKind(math.Random random) {
  final pool = [
    for (final kind in vehicleKinds)
      if (kind.leavesTown && !kind.isGated) kind,
  ];
  return pool[random.nextInt(pool.length)];
}
