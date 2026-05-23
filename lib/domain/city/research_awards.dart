/// Proficiency thresholds at which a sub-concept's progress earns the player
/// a 🔬 research credit. Each threshold is a per-concept one-shot — the
/// first time `p` crosses it on a given concept, +1 🔬 is awarded; later
/// re-crossings (after a dip below) are ignored, recorded by row presence in
/// the `ConceptBandMilestones` Drift table.
///
/// **The number of bands is configurable here.** Adding a third threshold
/// (e.g. `[0.4, 0.65, 0.9]`) needs no schema migration — `bandIndex` in the
/// Drift table is just an int into this list.
///
/// See `plan.md` *Domain Specs / Research-currency earning* for the design.
const List<double> researchAwardThresholds = [0.5, 0.85];

/// Returns the list of band indices the player has *newly* crossed by moving
/// from `oldP` up to `newP`, given the set of bands already awarded for this
/// concept. Result is sorted ascending and contains only indices not in
/// `alreadyAwardedBandIndices`.
///
/// "Crossing" means `oldP < threshold <= newP`. A no-op update (`oldP ==
/// newP`) yields an empty list. A downward update yields an empty list.
List<int> newlyCrossedBands({
  required double oldP,
  required double newP,
  required Set<int> alreadyAwardedBandIndices,
}) {
  if (newP <= oldP) return const <int>[];
  final crossed = <int>[];
  for (var i = 0; i < researchAwardThresholds.length; i++) {
    if (alreadyAwardedBandIndices.contains(i)) continue;
    final t = researchAwardThresholds[i];
    if (oldP < t && newP >= t) crossed.add(i);
  }
  return crossed;
}
