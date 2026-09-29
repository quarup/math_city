/// AND-combination of optional gate conditions for whether a building type is
/// *available to buy*. All non-null fields must be satisfied simultaneously.
/// A rule with every field null is trivially true (used for the mayor's
/// office and other ungated starter buildings). Once the rule passes the
/// building appears in the build catalog and can be bought straight away for
/// its coin price.
class UnlockRule {
  const UnlockRule({
    this.minLifetimeCoins,
    this.requiredBuildingsPlaced = const <String>{},
    this.minPopulation,
    this.requiredBeatsRead = const <String>{},
  });

  /// Empty rule — always satisfied. Use for ungated starter buildings.
  static const open = UnlockRule();

  /// Lifetime coins earned to date. Coins are study-seconds, so this reads
  /// as "unlocks after ~N minutes of total study".
  final int? minLifetimeCoins;
  final Set<String> requiredBuildingsPlaced;
  final int? minPopulation;

  /// Story beats whose letter must have *arrived* before this building shows
  /// in the catalog. This is how a "we want a clinic!" demand letter gates
  /// the clinic card: the building stays hidden until the citizen actually
  /// asks for it. (Arrival is the gate — letters interrupt on arrival and
  /// never expire, so reading is no longer a separate step; city_builder.md
  /// §10.2. The field name predates that change.)
  final Set<String> requiredBeatsRead;

  bool evaluate(UnlockContext ctx) {
    if (minLifetimeCoins != null &&
        ctx.lifetimeCoinsEarned < minLifetimeCoins!) {
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
    required this.lifetimeCoinsEarned,
    required this.population,
    required this.placedBuildingTypeIds,
    required this.readBeatIds,
  });

  final int lifetimeCoinsEarned;
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
