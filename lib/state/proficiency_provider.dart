import 'dart:async';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/domain/city/construction_site.dart';
import 'package:math_city/domain/concepts/concept.dart';
import 'package:math_city/domain/concepts/concept_registry.dart';
import 'package:math_city/domain/concepts/dag_engine.dart';
import 'package:math_city/domain/concepts/wheel_selection.dart';
import 'package:math_city/domain/economy/band_crossings.dart';
import 'package:math_city/domain/economy/coin_economy.dart';
import 'package:math_city/domain/economy/expected_seconds.dart';
import 'package:math_city/domain/economy/question_block.dart';
import 'package:math_city/domain/proficiency/proficiency_band.dart';
import 'package:math_city/state/city_provider.dart';
import 'package:math_city/state/game_session_provider.dart';
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

  /// Records an answer: updates proficiency, advances the round clock, moves
  /// the answer streak, pays coins (answer + any band-crossing bonus) into
  /// the active construction site and runs the drip-feed. Returns everything
  /// the UI needs to animate as one [AnswerReward]. All persistence happens
  /// here, before the caller sees the reward, so a payout can't be lost to a
  /// mid-animation exit.
  ///
  /// Coins have no wallet to land in (city_builder.md §8.3): they go to the
  /// site in `activeSiteIdProvider`, which opens when its bar fills. With no
  /// active site — or one that already opened earlier in the block — the
  /// lifetime counter still moves but the coins go nowhere.
  ///
  /// Unlock events fire only on *correct* answers: the drip-feed tops the
  /// active frontier back up to `kActivePoolTarget` after a mastery (or a
  /// retirement) shrinks it, and a wrong answer can't cause either. Band-
  /// crossing bonuses likewise only fire on upward moves.
  Future<AnswerReward> recordAnswer(
    String conceptId, {
    required bool correct,
    required bool usesKeypad,
  }) async {
    final player = await ref.read(activePlayerProvider.future);
    final db = ref.read(appDatabaseProvider);

    // One answered question = one round. Advance the clock first so the
    // population tick + beat evaluation below see the new value (building age
    // and bubble rotation both key off it).
    await db.incrementRoundsPlayed(player.id);

    final concept = findConceptById(conceptId)!;
    final engine = ref.read(dagEngineProvider);
    final effectiveGrade = engine.effectiveGradeFor(player.gradeLevel);
    final introduced = await db.introducedConceptIdsForPlayer(player.id);
    final current =
        state.asData?.value[conceptId] ??
        startingProficiency(
          conceptGrade: concept.primaryGrade,
          playerGrade: effectiveGrade,
          introduced: introduced.contains(conceptId),
        );
    final updated = updateProficiency(current, correct: correct);

    await db.upsertProficiency(
      player.id,
      conceptId,
      updated,
      correct: correct,
    );

    // Streak: one step up per correct answer (capped), reset on a miss. Pay
    // is computed at the *new* level, so the first correct after a miss
    // earns 20%.
    final streak = nextStreakCount(player.streakCount, correct: correct);
    await db.setPlayerStreakCount(player.id, streak);

    final seconds = expectedSecondsFor(conceptId);
    var coins = 0;
    final bonuses = <BandCrossingBonus>[];
    PayInResult? sitePayIn;
    final cityActions = ref.read(cityActionsProvider);
    if (correct) {
      coins = coinsForCorrectAnswer(
        expectedSeconds: seconds,
        usesKeypad: usesKeypad,
        streakCount: streak,
      );
      // Band-crossing bonus: paid once per concept per threshold.
      // `newlyCrossedBands` only returns crossings the player hasn't yet
      // been paid for (per `ConceptBandMilestones`), so re-crossings after
      // a dip don't double-pay.
      final awarded = await db.awardedBandIndicesFor(player.id, conceptId);
      final crossed = newlyCrossedBands(
        oldP: current,
        newP: updated,
        alreadyAwardedBandIndices: awarded,
      );
      for (final bandIndex in crossed) {
        await db.recordBandMilestone(player.id, conceptId, bandIndex);
        bonuses.add(
          BandCrossingBonus(
            conceptId: conceptId,
            band: bandReachedAt(bandIndex),
            coins: bandCrossingBonus(seconds),
          ),
        );
      }
      final total = coins + bonuses.fold<int>(0, (sum, b) => sum + b.coins);
      await db.addLifetimeCoins(player.id, total);
      final siteId = ref.read(activeSiteIdProvider);
      if (siteId != null) {
        sitePayIn = await cityActions.payIntoSite(siteId, total);
      }
    }

    var unlocks = const <UnlockEvent>[];
    final crossedMastery = current < 0.85 && updated >= 0.85;
    if (correct) {
      // Drip-feed top-up against the *post-update* state. A no-op while the
      // active frontier is full; after a mastery or a retirement it refills
      // to `kActivePoolTarget`, one unlock per new concept.
      final freshProf = await db.proficiencyMapForPlayer(player.id);
      final picks = engine.topUp(
        introduced: introduced,
        profMap: freshProf,
        playerGrade: player.gradeLevel,
      );
      if (picks.isNotEmpty) {
        await ref
            .read(introducedConceptsProvider.notifier)
            .introduceAll(picks.map((c) => c.id));
        unlocks = [
          for (final c in picks)
            UnlockEvent(
              newConcept: c,
              masteredConcept: crossedMastery ? concept : null,
            ),
        ];
      }
    }

    // Playing math grows your city: nudge the population one tick toward the
    // capacity its buildings support, then re-evaluate story beats (population
    // and coin-spacing gates can newly pass). No-op until the player has
    // placed something.
    await cityActions.tickPopulation();
    await cityActions.fireBeats();

    // The round clock, streak and lifetime coins all moved. Refetch the
    // active player so every reader (unlock catalog, home-screen chips) sees
    // what this answer produced.
    ref
      ..invalidate(activePlayerProvider)
      ..invalidate(allPlayersProvider)
      ..invalidateSelf();
    return AnswerReward(
      correct: correct,
      coins: coins,
      streakCount: streak,
      bandBonuses: bonuses,
      unlocks: unlocks,
      sitePayIn: sitePayIn,
    );
  }
}

final proficiencyProvider =
    AsyncNotifierProvider<ProficiencyNotifier, Map<String, double>>(
      ProficiencyNotifier.new,
    );

// ---------------------------------------------------------------------------
// Wheel concepts — `selectWheelConcepts` over the player's playable concepts
// (introduced ∩ generator-registered), split into the frontier tier
// (challenging / comfortable) and the review tier (mastered, not outgrown).
// Always `kWheelSegments` when the tiers allow, with at least `kMinRotation`
// segments changed since the wheel the player last saw.
//
// The provider rebuilds whenever proficiency or the introduced set changes —
// once per answered question — so the sample the summary screen's "Spin
// again" lands on is always fresh against `lastWheelProvider`.
// ---------------------------------------------------------------------------

/// Concept IDs on the wheel the player most recently saw. `SpinScreen`
/// records it when it builds a wheel; `wheelConceptsProvider` reads (never
/// watches) it so the next wheel rotates against it. Session-only state.
class LastWheelNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void record(Iterable<String> conceptIds) => state = conceptIds.toSet();
}

final lastWheelProvider = NotifierProvider<LastWheelNotifier, Set<String>>(
  LastWheelNotifier.new,
);

final wheelConceptsProvider = FutureProvider<List<Concept>>((ref) async {
  final profMap = await ref.watch(proficiencyProvider.future);
  final introduced = await ref.watch(introducedConceptsProvider.future);
  final registry = ref.watch(generatorRegistryProvider);
  final player = await ref.watch(activePlayerProvider.future);
  final engine = ref.watch(dagEngineProvider);
  final effectiveGrade = engine.effectiveGradeFor(player.gradeLevel);

  bool playable(Concept c) =>
      introduced.contains(c.id) && registry.isImplemented(c.id);

  WheelTier tierOf(Concept c) {
    final band = bandForProficiency(
      profMap[c.id] ??
          startingProficiency(
            conceptGrade: c.primaryGrade,
            playerGrade: effectiveGrade,
            introduced: true,
          ),
    );
    final retired = isRetiredFromWheel(
      conceptGrade: c.primaryGrade,
      playerGrade: effectiveGrade,
      band: band,
    );
    return wheelTierFor(band: band, retired: retired);
  }

  final frontier = <Concept>[];
  final review = <Concept>[];
  for (final c in allConcepts) {
    if (!playable(c)) continue;
    switch (tierOf(c)) {
      case WheelTier.frontier:
        frontier.add(c);
      case WheelTier.review:
        review.add(c);
      case WheelTier.off:
        break;
    }
  }

  // Fallback: everything introduced is outgrown. Keep the wheel spinning on
  // whatever is playable rather than showing nothing.
  if (frontier.isEmpty && review.isEmpty) {
    return allConcepts.where(playable).toList()..sort(compareConceptDifficulty);
  }

  return selectWheelConcepts(
    frontier: frontier,
    review: review,
    previous: ref.read(lastWheelProvider),
    random: Random(),
  );
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
  // A concept the wheel offered is by definition introduced.
  final p =
      profMap[conceptId] ??
      startingProficiency(
        conceptGrade: concept.primaryGrade,
        playerGrade: playerGrade,
        introduced: true,
      );
  return bandForProficiency(p);
}
