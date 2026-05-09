import 'dart:math';

import 'package:math_dash/domain/concepts/concept.dart';
import 'package:math_dash/domain/concepts/concept_category.dart';
import 'package:math_dash/domain/concepts/concept_registry.dart';
import 'package:math_dash/domain/questions/generator_registry.dart';

/// Threshold at which a concept counts as `mastered` (matches
/// proficiency_band.dart). Duplicated here to keep the domain layer
/// self-contained without a circular import.
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

  /// Picks the starter pack for a brand-new player: up to [size] concepts
  /// at-or-below [playerGrade], sorted by difficulty.
  ///
  /// Prereqs are ignored here on purpose — a fresh player needs *something*
  /// on the wheel from round one, even if it would normally be "downstream"
  /// in the DAG. Subsequent unlocks via [pickNext] do honor the DAG.
  List<Concept> pickStarterPack(int playerGrade, {int size = 2}) {
    final eligible = catalog
        .where(
          (c) =>
              c.primaryGrade <= playerGrade &&
              registry.isImplemented(c.id),
        )
        .toList()
      ..sort(compareConceptDifficulty);
    return eligible.take(size).toList();
  }

  /// Picks the next concept to introduce after a mastery event, or null
  /// if nothing is currently eligible.
  ///
  /// [introduced]: concept IDs the player has been introduced to.
  /// [profMap]: proficiency per concept (0.0–1.0). Concepts not in the
  ///   map are treated as not-mastered.
  Concept? pickNext({
    required Set<String> introduced,
    required Map<String, double> profMap,
  }) {
    bool isMasteredId(String id) =>
        (profMap[id] ?? 0) >= _masteryThreshold;

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
