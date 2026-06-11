import 'package:math_city/domain/city/building_type.dart';
import 'package:math_city/domain/city/category.dart';

/// Population growth model v1 (pure-Dart). Two pure functions:
///
/// - [populationCapacity] — how many residents the city can support *right
///   now*, derived from its placed buildings (housing, gating-service caps,
///   a desirability multiplier).
/// - [stepPopulation] — advances the live population one tick toward that
///   ceiling (grows under it, shrinks over it).
///
/// No Drift, no Flutter — the whole model is unit-tested. **Every magic number
/// here is a placeholder** picked to make the mechanic legible during Phase 7;
/// real tuning happens in Phase 8/9 from playtest data (see prd.md *City
/// Builder*).

/// Service IDs that gate growth: the city can't house more residents than its
/// thinnest gating service supports. `school` (a soft amenity) is deliberately
/// not gating in v1. `water` joined as the fourth hard gate per the
/// city_builder.md 2026-05-31 decision (wired with the water_tower arc).
const gatingServiceIds = {'power', 'clinic', 'waste', 'water'};

/// Residents each gating service tolerates with zero providers — a hamlet
/// survives without infrastructure. Keeps a brand-new city (homes, no
/// services) from being pinned at zero before the player can build services.
const serviceFreeAllowance = 20;

/// Multiplier growth per distinct variety building type placed (a livelier mix
/// of shops / parks / services makes the city more desirable, so it packs in a
/// little denser than raw housing alone).
const varietyBonusPerType = 0.05;

/// Ceiling on the variety multiplier so a maxed-out mix can't run away.
const maxVarietyMultiplier = 1.5;

/// When amenity (commercial + entertainment) buildings outnumber housing
/// buildings by more than this factor, the city reads as lopsided ("all malls,
/// no homes") and takes a desirability penalty.
const lopsidedAmenityToHousingRatio = 2;

/// Desirability multiplier applied when the city is lopsided (see above).
const lopsidednessPenalty = 0.8;

/// Fraction of the gap to capacity the population closes each tick.
const defaultGrowthRate = 0.25;

/// The resident ceiling the city can currently support. Pure function of the
/// placed buildings — pass one [BuildingType] per placement (repeats allowed
/// for multiple instances of the same type).
int populationCapacity(Iterable<BuildingType> placed) {
  var housing = 0;
  var housingCount = 0;
  var amenityCount = 0;
  final serviceTotals = <String, int>{};
  final varietyTypeIds = <String>{};

  for (final b in placed) {
    housing += b.populationContribution;
    if (b.populationContribution > 0) housingCount++;
    if (b.category == BuildingCategory.commercial ||
        b.category == BuildingCategory.entertainment) {
      amenityCount++;
    }
    if (b.varietyContribution) varietyTypeIds.add(b.id);
    b.serviceProvision.forEach((id, cap) {
      serviceTotals[id] = (serviceTotals[id] ?? 0) + cap;
    });
  }

  // No homes, no residents — short-circuit before the multiplier (which would
  // otherwise divide by a zero housing count in the lopsidedness check).
  if (housing == 0) return 0;

  // Gating-service ceiling: the thinnest gating service the city has, each
  // granting its free allowance on top of placed providers.
  var serviceCeiling = housing;
  for (final id in gatingServiceIds) {
    final cap = serviceFreeAllowance + (serviceTotals[id] ?? 0);
    if (cap < serviceCeiling) serviceCeiling = cap;
  }

  final base = housing < serviceCeiling ? housing : serviceCeiling;

  // Desirability multiplier: variety bonus (capped), minus a lopsidedness
  // penalty when amenities dwarf housing.
  var multiplier = 1 + varietyBonusPerType * varietyTypeIds.length;
  if (multiplier > maxVarietyMultiplier) multiplier = maxVarietyMultiplier;
  if (amenityCount > lopsidedAmenityToHousingRatio * housingCount) {
    multiplier *= lopsidednessPenalty;
  }

  return (base * multiplier).round();
}

/// Advances [current] one tick toward [capacity], closing [rate] of the gap
/// (rounded up, so it always moves by at least 1 and lands on the target
/// exactly rather than overshooting). Grows when under capacity, shrinks when
/// over, holds when equal.
int stepPopulation(
  int current,
  int capacity, {
  double rate = defaultGrowthRate,
}) {
  assert(rate > 0 && rate <= 1, 'rate must be in (0, 1]');
  if (current == capacity) return current;
  if (current < capacity) {
    final next = current + ((capacity - current) * rate).ceil();
    return next > capacity ? capacity : next;
  }
  final next = current - ((current - capacity) * rate).ceil();
  return next < capacity ? capacity : next;
}
