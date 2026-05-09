import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/domain/concepts/concept.dart';
import 'package:math_city/domain/concepts/concept_registry.dart';
import 'package:math_city/domain/concepts/dag_engine.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';
import 'package:math_city/state/introduced_concepts_provider.dart';
import 'package:math_city/state/player_provider.dart';

// ---------------------------------------------------------------------------
// Proficiency map — conceptId → p value for the active player.
// Backed by Drift; rebuilt when the active player changes.
// ---------------------------------------------------------------------------

class ProficiencyNotifier extends AsyncNotifier<Map<String, double>> {
  @override
  Future<Map<String, double>> build() async {
    final player = await ref.watch(activePlayerProvider.future);
    final db = ref.watch(appDatabaseProvider);
    return db.proficiencyMapForPlayer(player.id);
  }

  /// Records an answer and returns an [UnlockEvent] if the answer triggered
  /// a mastery transition that the drip-feed converted into a new concept
  /// introduction. Returns null otherwise.
  ///
  /// Per plan.md Phase 5: unlock events fire only on *correct* answers
  /// (mastery is unreachable from a wrong answer anyway because the EMA
  /// update moves p toward 0). The unlock UI is thus naturally suppressed
  /// when the player gets a question wrong.
  Future<UnlockEvent?> recordAnswer(
    String conceptId, {
    required bool correct,
  }) async {
    final player = await ref.read(activePlayerProvider.future);
    final db = ref.read(appDatabaseProvider);

    final concept = findConceptById(conceptId)!;
    final engine = ref.read(dagEngineProvider);
    final effectiveGrade = engine.effectiveGradeFor(player.gradeLevel);
    final current =
        state.asData?.value[conceptId] ??
        initialProficiency(concept.primaryGrade, effectiveGrade);
    final updated = updateProficiency(current, correct: correct);

    await db.upsertProficiency(
      player.id,
      conceptId,
      updated,
      correct: correct,
    );

    UnlockEvent? unlock;
    final crossedMastery = current < 0.85 && updated >= 0.85;
    if (correct && crossedMastery) {
      // Run drip-feed against the *post-update* state.
      final freshProf = await db.proficiencyMapForPlayer(player.id);
      final introduced = await db.introducedConceptIdsForPlayer(player.id);
      final next = engine.pickNext(
        introduced: introduced,
        profMap: freshProf,
        playerGrade: player.gradeLevel,
      );
      if (next != null) {
        await ref
            .read(introducedConceptsProvider.notifier)
            .introduce(next.id);
        unlock = UnlockEvent(
          newConcept: next,
          masteredConcept: concept,
        );
      }
    }

    ref.invalidateSelf();
    return unlock;
  }
}

final proficiencyProvider =
    AsyncNotifierProvider<ProficiencyNotifier, Map<String, double>>(
      ProficiencyNotifier.new,
    );

// ---------------------------------------------------------------------------
// Wheel concepts — introduced ∩ generator-registered, in challenging or
// comfortable band, sized between [kMinWheelSegments] and [kMaxWheelSegments].
//
// Below the max, every eligible concept is on the wheel (sorted ascending
// by difficulty for a stable layout). At or above the max, we randomly
// sample [kMaxWheelSegments] each round so the player gets variety
// without a 12-segment wheel becoming unreadable on a phone.
// ---------------------------------------------------------------------------

const int kMaxWheelSegments = 8;
const int kMinWheelSegments = 4;

final wheelConceptsProvider = FutureProvider<List<Concept>>((ref) async {
  final profMap = await ref.watch(proficiencyProvider.future);
  final introduced = await ref.watch(introducedConceptsProvider.future);
  final registry = ref.watch(generatorRegistryProvider);
  final player = await ref.watch(activePlayerProvider.future);
  final engine = ref.watch(dagEngineProvider);
  final effectiveGrade = engine.effectiveGradeFor(player.gradeLevel);

  bool eligible(Concept c) {
    if (!introduced.contains(c.id)) return false;
    if (!registry.isImplemented(c.id)) return false;
    final p =
        profMap[c.id] ?? initialProficiency(c.primaryGrade, effectiveGrade);
    final band = bandForProficiency(p);
    return band == ProficiencyBand.challenging ||
        band == ProficiencyBand.comfortable;
  }

  final concepts = allConcepts.where(eligible).toList()
    ..sort(compareConceptDifficulty);

  // Fallback: if no concepts qualify (e.g. all introduced are mastered),
  // surface the full introduced+implemented set so the wheel still spins.
  if (concepts.isEmpty) {
    return allConcepts
        .where((c) =>
            introduced.contains(c.id) && registry.isImplemented(c.id))
        .toList()
      ..sort(compareConceptDifficulty);
  }

  // ≤ kMaxWheelSegments: surface them all in difficulty order.
  if (concepts.length <= kMaxWheelSegments) return concepts;

  // > kMaxWheelSegments: random-sample kMaxWheelSegments each round so the
  // player sees variety. The provider rebuilds whenever proficiency or the
  // introduced set changes — i.e., once per answered question — which is
  // also when we want a fresh sample.
  final shuffled = List<Concept>.of(concepts)..shuffle(Random());
  return shuffled.take(kMaxWheelSegments).toList()
    ..sort(compareConceptDifficulty);
});

// ---------------------------------------------------------------------------
// Helper — resolves the band for a concept given the current proficiency map
// and the player's grade level.  Used by SpinScreen when navigating to the
// question screen.
// ---------------------------------------------------------------------------

ProficiencyBand bandForConcept(
  String conceptId,
  Map<String, double> profMap,
  int playerGrade,
) {
  final concept = findConceptById(conceptId)!;
  final p =
      profMap[conceptId] ??
      initialProficiency(concept.primaryGrade, playerGrade);
  return bandForProficiency(p);
}
