/// AND-combination of optional gate conditions for whether a story beat
/// should be visible on screen. Empty rule = always visible.
class TriggerRule {
  const TriggerRule({
    this.buildingsPresent = const <String>{},
    this.buildingsAbsent = const <String>{},
    this.minPopulation,
    this.minBuildingAgeForId,
    this.requiredBeatsFired = const <String>{},
    this.minBricksEarnedSinceLastBeat,
  });

  static const open = TriggerRule();

  final Set<String> buildingsPresent;
  final Set<String> buildingsAbsent;
  final int? minPopulation;

  /// Pair of `(buildingTypeId, minRounds)`: at least one placement of the
  /// given type must have been on the map for ≥ `minRounds` answered
  /// questions before the beat can fire. Null means no age requirement.
  final ({String buildingTypeId, int minRounds})? minBuildingAgeForId;

  final Set<String> requiredBeatsFired;

  /// Spacing: at least N bricks must have been earned since this beat last
  /// fired before it can fire again. Null means no spacing requirement.
  /// First-fire is always allowed regardless of this value.
  final int? minBricksEarnedSinceLastBeat;

  bool evaluate(TriggerContext ctx) {
    if (!ctx.placedBuildingTypeIds.containsAll(buildingsPresent)) return false;
    for (final id in buildingsAbsent) {
      if (ctx.placedBuildingTypeIds.contains(id)) return false;
    }
    if (minPopulation != null && ctx.population < minPopulation!) return false;
    if (minBuildingAgeForId != null) {
      final required = minBuildingAgeForId!;
      final age = ctx.maxBuildingAgeByTypeId[required.buildingTypeId] ?? 0;
      if (age < required.minRounds) return false;
    }
    if (!ctx.firedBeatIds.containsAll(requiredBeatsFired)) return false;
    if (minBricksEarnedSinceLastBeat != null) {
      final since = ctx.bricksEarnedSinceBeatLastFired;
      // First-fire (no prior fire => null) is always allowed.
      if (since != null && since < minBricksEarnedSinceLastBeat!) return false;
    }
    return true;
  }
}

/// Snapshot the [TriggerRule] evaluates against. Built per-beat at evaluation
/// time so the `bricksEarnedSinceBeatLastFired` field can be beat-specific.
class TriggerContext {
  const TriggerContext({
    required this.placedBuildingTypeIds,
    required this.population,
    required this.maxBuildingAgeByTypeId,
    required this.firedBeatIds,
    required this.bricksEarnedSinceBeatLastFired,
  });

  final Set<String> placedBuildingTypeIds;
  final int population;

  /// For each placed building type, the age (in rounds) of its *oldest*
  /// placement. A type absent from this map is treated as age 0.
  final Map<String, int> maxBuildingAgeByTypeId;

  final Set<String> firedBeatIds;

  /// Bricks earned since this specific beat last fired, or `null` if it has
  /// never fired.
  final int? bricksEarnedSinceBeatLastFired;
}
