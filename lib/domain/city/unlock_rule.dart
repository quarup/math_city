/// AND-combination of optional gate conditions for whether a building type is
/// *available to research*. All non-null fields must be satisfied
/// simultaneously. A rule with every field null is trivially true (used for
/// the mayor's office and other ungated starter buildings).
class UnlockRule {
  const UnlockRule({
    this.minLifetimeBricks,
    this.requiredBuildingsPlaced = const <String>{},
    this.minPopulation,
    this.requiredBeatsRead = const <String>{},
  });

  /// Empty rule — always satisfied. Use for ungated starter buildings.
  static const open = UnlockRule();

  final int? minLifetimeBricks;
  final Set<String> requiredBuildingsPlaced;
  final int? minPopulation;

  /// Story beats the player must have *opened* (tapped to read) before this
  /// building shows as available-to-research. This is how a "we want a clinic!"
  /// demand bubble gates the clinic card: the building stays hidden until the
  /// citizen actually asks for it and the player reads the ask.
  final Set<String> requiredBeatsRead;

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
    if (!ctx.readBeatIds.containsAll(requiredBeatsRead)) {
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
    required this.readBeatIds,
  });

  final int lifetimeBricksEarned;
  final int population;

  /// The set of `BuildingType.id` values currently placed on the city map
  /// (de-duplicated — if 5 single homes are placed, this set contains
  /// `'single_home'` once).
  final Set<String> placedBuildingTypeIds;

  /// The set of `StoryBeat.id` values the player has opened (read) at least
  /// once. A beat that re-fires only needs to have been read *once* to satisfy
  /// `requiredBeatsRead`.
  final Set<String> readBeatIds;
}
