import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/building_type.dart';
import 'package:math_city/domain/city/unlock_rule.dart';

/// Pure-Dart engine that decides which building types are *available to
/// research* given a snapshot of the player + city state. **Note:** being
/// available-to-research does NOT auto-unlock the building. The player must
/// still spend the type's `researchCost` to add it to
/// `BuildingTypeResearched`; that's what makes it appear in the build menu.
///
/// Distinct from `lib/domain/concepts/dag_engine.dart` — that one drives the
/// math-concept drip-feed for the wheel; this one drives the building DAG.
class BuildingDagEngine {
  const BuildingDagEngine();

  /// All building types whose `unlockRule` is satisfied by `ctx`.
  /// Returned in registry order; deduplicated by id (which is implicit since
  /// the registry contains each id once).
  List<BuildingType> availableToResearch(UnlockContext ctx) {
    return buildingRegistry.where((b) => b.unlockRule.evaluate(ctx)).toList();
  }

  /// Set of building-type IDs that are available to research but the player
  /// hasn't yet spent research on (i.e. not present in [alreadyResearched]).
  /// This is what the research-panel UI lists.
  Set<String> notYetResearched(
    UnlockContext ctx, {
    required Set<String> alreadyResearched,
  }) {
    final result = <String>{};
    for (final b in availableToResearch(ctx)) {
      if (!alreadyResearched.contains(b.id)) result.add(b.id);
    }
    return result;
  }
}
