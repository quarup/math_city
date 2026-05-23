/// AND-combination of optional gate conditions for whether a building type is
/// *available to research*. All non-null fields must be satisfied
/// simultaneously. A rule with every field null is trivially true (used for
/// the mayor's office and other ungated starter buildings).
class UnlockRule {
  const UnlockRule({
    this.minLifetimeBricks,
    this.requiredBuildingsPlaced = const <String>{},
    this.minPopulation,
    this.requiredBeatsFired = const <String>{},
  });

  /// Empty rule — always satisfied. Use for ungated starter buildings.
  static const open = UnlockRule();

  final int? minLifetimeBricks;
  final Set<String> requiredBuildingsPlaced;
  final int? minPopulation;
  final Set<String> requiredBeatsFired;

  bool evaluate(UnlockContext ctx) {
    if (minLifetimeBricks != null &&
        ctx.lifetimeBricksEarned < minLifetimeBricks!) {
      return false;
    }
    if (minPopulation != null && ctx.population < minPopulation!) {
      return false;
    }
    if (!ctx.placedBuildingTypeIds.containsAll(requiredBuildingsPlaced)) {
      return false;
    }
    if (!ctx.firedBeatIds.containsAll(requiredBeatsFired)) {
      return false;
    }
    return true;
  }
}

/// Snapshot of the player + city state that an [UnlockRule] evaluates against.
class UnlockContext {
  const UnlockContext({
    required this.lifetimeBricksEarned,
    required this.population,
    required this.placedBuildingTypeIds,
    required this.firedBeatIds,
  });

  final int lifetimeBricksEarned;
  final int population;

  /// The set of `BuildingType.id` values currently placed on the city map
  /// (de-duplicated — if 5 single homes are placed, this set contains
  /// `'single_home'` once).
  final Set<String> placedBuildingTypeIds;

  /// The set of `StoryBeat.id` values that have fired at least once for this
  /// player. Beats that re-fire (e.g. "we want more parks") only need to
  /// have fired *once* to satisfy `requiredBeatsFired`.
  final Set<String> firedBeatIds;
}
