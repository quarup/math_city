import 'dart:math';

import 'package:math_city/domain/concepts/concept.dart';
import 'package:math_city/domain/concepts/concept_category.dart';
import 'package:math_city/domain/concepts/concept_registry.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';
import 'package:math_city/domain/questions/generator_registry.dart';

/// Threshold at which a concept counts as `mastered` (mirrors the cutoff
/// in proficiency_band.dart). Local const for readability at the call sites.
const double _masteryThreshold = 0.85;

/// Result of a successful drip-feed unlock. Surfaced to the UI to render
/// the "New concept unlocked!" card on the result screen.
class UnlockEvent {
  const UnlockEvent({
    required this.newConcept,
    this.masteredConcept,
  });

  /// The concept that the drip-feed just introduced.
  final Concept newConcept;

  /// The concept whose mastery triggered the unlock (informational; null
  /// for the starter-pack case).
  final Concept? masteredConcept;
}

/// Pure-Dart drip-feed engine: given a player's current proficiencies and
/// introduced set, picks the next concept to introduce per the policy in
/// plan.md Phase 5:
///   1. Lowest grade first.
///   2. Tiebreak by category: prefer the category with fewest active
///      (introduced-but-not-mastered) concepts.
///   3. Within the chosen category, lowest [Concept.categoryRowOrder].
///
/// Returns null if no implemented concept is currently eligible.
class DripFeedEngine {
  DripFeedEngine({
    required this.registry,
    Iterable<Concept>? catalog,
  }) : catalog = catalog ?? allConcepts;

  final GeneratorRegistry registry;
  final Iterable<Concept> catalog;

  /// Returns the player's *effective* grade — capped by the highest grade
  /// represented by an implemented concept in [catalog].
  ///
  /// The PRD targets K–8, but the implemented catalog grows phase-by-phase.
  /// Until grade-N content ships, a player who picks grade N at signup
  /// has no in-band frontier; without clamping, they'd see all lower-grade
  /// content as "already mastered" (initial p = 0.95) and the wheel would
  /// fall back to surfacing the easiest concepts. Clamping to the catalog
  /// ceiling makes a high-grade player behave as a frontier player against
  /// whatever's currently implemented — they see the hardest content we
  /// have, not the easiest.
  int effectiveGradeFor(int statedGrade) {
    var maxImplemented = 0;
    for (final c in catalog) {
      if (registry.isImplemented(c.id) && c.primaryGrade > maxImplemented) {
        maxImplemented = c.primaryGrade;
      }
    }
    return statedGrade < maxImplemented ? statedGrade : maxImplemented;
  }

  /// Picks the starter pack for a brand-new player: up to [size] concepts
  /// at the player's frontier (challenging or comfortable initial band),
  /// sorted by difficulty.
  ///
  /// Default of 4 keeps the wheel feeling like a real choice from round one
  /// (matches `kMinWheelSegments` in proficiency_provider.dart).
  ///
  /// Concepts well below [statedGrade] are excluded — their grade-aware
  /// initial proficiency puts them in the `mastered` band, so surfacing them
  /// would force a high-grade player to grind through K-level content.
  /// [statedGrade] is clamped via [effectiveGradeFor] so a player whose
  /// grade exceeds the implemented catalog still sees frontier content.
  ///
  /// Prereqs are ignored here on purpose — a fresh player needs *something*
  /// on the wheel from round one, even if it would normally be "downstream"
  /// in the DAG. Subsequent unlocks via [pickNext] do honor the DAG.
  List<Concept> pickStarterPack(int statedGrade, {int size = 4}) {
    final playerGrade = effectiveGradeFor(statedGrade);
    final eligible = catalog
        .where((c) {
          if (!registry.isImplemented(c.id)) return false;
          final p = initialProficiency(c.primaryGrade, playerGrade);
          final band = bandForProficiency(p);
          return band == ProficiencyBand.challenging ||
              band == ProficiencyBand.comfortable;
        })
        .toList()
      ..sort(compareConceptDifficulty);

    if (eligible.isNotEmpty) return eligible.take(size).toList();

    // Fallback: no in-band concepts. Surface the highest-grade implemented
    // concepts at-or-below grade so the wheel always has *something close
    // to* the frontier (not the easiest in the catalog).
    final fallback = catalog
        .where(
          (c) =>
              c.primaryGrade <= playerGrade &&
              registry.isImplemented(c.id),
        )
        .toList()
      // Sort highest-grade first, then by row order within grade.
      ..sort((a, b) {
        final byGrade = b.primaryGrade.compareTo(a.primaryGrade);
        if (byGrade != 0) return byGrade;
        return a.categoryRowOrder.compareTo(b.categoryRowOrder);
      });
    return fallback.take(size).toList();
  }

  /// Picks the next concept to introduce after a mastery event, or null
  /// if nothing is currently eligible.
  ///
  /// [introduced]: concept IDs the player has been introduced to.
  /// [profMap]: proficiency per concept (0.0–1.0). Concepts not in the
  ///   map fall back to grade-aware [initialProficiency] using
  ///   [playerGrade], so prereqs that are well below the player's grade
  ///   auto-satisfy as mastered (initial p = 0.95) without the player
  ///   ever needing to answer them.
  /// [playerGrade]: the player's stated grade level (K=0). Used for the
  ///   profMap fallback above and to skip concepts that would start in
  ///   the `notYet` band.
  Concept? pickNext({
    required Set<String> introduced,
    required Map<String, double> profMap,
    required int playerGrade,
  }) {
    final effectiveGrade = effectiveGradeFor(playerGrade);
    // Build a lookup over this engine's own catalog so the fallback works
    // for synthetic test catalogs as well as the real one.
    final byId = {for (final c in catalog) c.id: c};
    double profOf(String id) {
      final recorded = profMap[id];
      if (recorded != null) return recorded;
      final c = byId[id];
      if (c == null) return 0;
      return initialProficiency(c.primaryGrade, effectiveGrade);
    }

    bool isMasteredId(String id) => profOf(id) >= _masteryThreshold;

    final eligible = catalog
        .where(
          (c) =>
              !introduced.contains(c.id) &&
              registry.isImplemented(c.id) &&
              c.prereqIds.every(isMasteredId),
        )
        .toList();

    if (eligible.isEmpty) return null;

    // Step 1: lowest grade.
    final minGrade = eligible
        .map((c) => c.primaryGrade)
        .reduce(min);
    final tier1 =
        eligible.where((c) => c.primaryGrade == minGrade).toList();

    // Step 2: prefer the category with the fewest currently-active
    // (introduced-but-not-mastered) concepts. Tiebreak by category display
    // order so the choice is deterministic.
    int activeIn(String categoryId) => catalog
        .where(
          (c) =>
              c.categoryId == categoryId &&
              introduced.contains(c.id) &&
              !isMasteredId(c.id),
        )
        .length;

    final candidateCategoryIds =
        tier1.map((c) => c.categoryId).toSet().toList()
          ..sort((a, b) {
            final byActive = activeIn(a).compareTo(activeIn(b));
            if (byActive != 0) return byActive;
            final ca = findCategoryById(a)?.displayOrder ?? 1 << 30;
            final cb = findCategoryById(b)?.displayOrder ?? 1 << 30;
            return ca.compareTo(cb);
          });
    final chosenCategoryId = candidateCategoryIds.first;

    // Step 3: within-category, lowest categoryRowOrder.
    final inCategory = tier1
        .where((c) => c.categoryId == chosenCategoryId)
        .toList()
      ..sort((a, b) => a.categoryRowOrder.compareTo(b.categoryRowOrder));
    return inCategory.first;
  }
}
