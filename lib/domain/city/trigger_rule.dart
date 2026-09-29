/// AND-combination of optional gate conditions for whether a story beat
/// should be visible on screen. Empty rule = always visible.
class TriggerRule {
  const TriggerRule({
    this.buildingsPresent = const <String>{},
    this.buildingsAbsent = const <String>{},
    this.minPopulation,
    this.minBuildingAgeForId,
    this.requiredBeatsFired = const <String>{},
    this.minCoinsEarnedSinceLastBeat,
    this.requiresLopsided = false,
    this.requiresGrowthStalled = false,
    this.requiresPartyGap = false,
  });

  /// Fires only while new housing sits half-empty and there is a public
  /// space to party at (`TriggerContext.partyGap`, city_builder.md §10.7).
  final bool requiresPartyGap;

  static const open = TriggerRule();

  /// Fires only while amenities dwarf housing (`TriggerContext.lopsided`) —
  /// the §4.3 "so many shops and not enough homes" warning.
  final bool requiresLopsided;

  /// Fires only while the population sits at a capacity that is below what
  /// the homes alone could hold (`TriggerContext.growthStalled`) — a gating
  /// service is the bottleneck.
  final bool requiresGrowthStalled;

  final Set<String> buildingsPresent;
  final Set<String> buildingsAbsent;
  final int? minPopulation;

  /// Pair of `(buildingTypeId, minRounds)`: at least one placement of the
  /// given type must have been on the map for ≥ `minRounds` answered
  /// questions before the beat can fire. Null means no age requirement.
  final ({String buildingTypeId, int minRounds})? minBuildingAgeForId;

  final Set<String> requiredBeatsFired;

  /// Spacing: at least N coins (≈ seconds of study) must have been earned
  /// since this beat last fired before it can fire again. Null means no
  /// spacing requirement. First-fire is always allowed regardless of this
  /// value.
  final int? minCoinsEarnedSinceLastBeat;

  bool evaluate(TriggerContext ctx) {
    if (!ctx.placedBuildingTypeIds.containsAll(buildingsPresent)) return false;
    // A building with an open construction site counts as present for the
    // absence check (city_builder.md §10.3): no letter ever asks for
    // something already on the way.
    for (final id in buildingsAbsent) {
      if (ctx.placedBuildingTypeIds.contains(id)) return false;
      if (ctx.underConstructionTypeIds.contains(id)) return false;
    }
    if (minPopulation != null && ctx.population < minPopulation!) return false;
    if (minBuildingAgeForId != null) {
      final required = minBuildingAgeForId!;
      final age = ctx.maxBuildingAgeByTypeId[required.buildingTypeId] ?? 0;
      if (age < required.minRounds) return false;
    }
    if (!ctx.firedBeatIds.containsAll(requiredBeatsFired)) return false;
    if (requiresLopsided && !ctx.lopsided) return false;
    if (requiresGrowthStalled && !ctx.growthStalled) return false;
    if (requiresPartyGap && !ctx.partyGap) return false;
    if (minCoinsEarnedSinceLastBeat != null) {
      final since = ctx.coinsEarnedSinceBeatLastFired;
      // First-fire (no prior fire => null) is always allowed.
      if (since != null && since < minCoinsEarnedSinceLastBeat!) return false;
    }
    return true;
  }
}

/// Snapshot the [TriggerRule] evaluates against. Built per-beat at evaluation
/// time so the `coinsEarnedSinceBeatLastFired` field can be beat-specific.
class TriggerContext {
  const TriggerContext({
    required this.placedBuildingTypeIds,
    required this.population,
    required this.maxBuildingAgeByTypeId,
    required this.firedBeatIds,
    required this.coinsEarnedSinceBeatLastFired,
    this.underConstructionTypeIds = const <String>{},
    this.lopsided = false,
    this.growthStalled = false,
    this.partyGap = false,
  });

  /// Capacity minus population is at least max(8, a quarter of capacity)
  /// and the town has a public space: a block party would fill homes.
  final bool partyGap;

  /// Amenities outnumber homes past the growth model's ratio.
  final bool lopsided;

  /// Population has reached a capacity that a gating service, not housing,
  /// is holding down.
  final bool growthStalled;

  final Set<String> placedBuildingTypeIds;

  /// Building types with an open construction site in the city. Treated as
  /// present by `buildingsAbsent` so a demand never fires for a building the
  /// player is already paying down.
  final Set<String> underConstructionTypeIds;
  final int population;

  /// For each placed building type, the age (in rounds) of its *oldest*
  /// placement. A type absent from this map is treated as age 0.
  final Map<String, int> maxBuildingAgeByTypeId;

  final Set<String> firedBeatIds;

  /// Coins earned since this specific beat last fired, or `null` if it has
  /// never fired.
  final int? coinsEarnedSinceBeatLastFired;
}
