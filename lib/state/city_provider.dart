import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/city/beat_engine.dart';
import 'package:math_city/domain/city/beat_registry.dart';
import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/building_type.dart';
import 'package:math_city/domain/city/dag_engine.dart';
import 'package:math_city/domain/city/population_model.dart';
import 'package:math_city/domain/city/story_beat.dart';
import 'package:math_city/domain/city/trigger_rule.dart';
import 'package:math_city/domain/city/unlock_rule.dart';
import 'package:math_city/state/player_provider.dart';

/// The active player's beginner-map `City` row. Auto-created at player
/// creation, so it resolves for any real player.
final activeCityProvider = FutureProvider<City>((ref) async {
  final playerId = ref.watch(activePlayerIdProvider);
  if (playerId == null) throw StateError('No active player');
  final db = ref.read(appDatabaseProvider);
  return db.cityForPlayer(playerId);
});

/// Every building currently placed in the active city.
final placementsProvider = FutureProvider<List<BuildingPlacement>>((ref) async {
  final city = await ref.watch(activeCityProvider.future);
  final db = ref.read(appDatabaseProvider);
  return db.placementsForCity(city.id);
});

/// One row in the build-mode catalog. Researched entries are placeable;
/// unresearched ones are *available to research* (their unlock rule passes
/// against the current city state) and render as locked cards the player can
/// spend 🔬 to unlock.
class CatalogEntry {
  const CatalogEntry({required this.building, required this.researched});

  final BuildingType building;
  final bool researched;
}

/// The build-mode catalog: every researched building plus every building
/// that's currently available to research, in registry order (stable display;
/// a card flips from locked to placeable in place when researched). Drives the
/// bottom catalog bar on the city screen.
final cityCatalogProvider = FutureProvider<List<CatalogEntry>>((ref) async {
  final playerId = ref.watch(activePlayerIdProvider);
  if (playerId == null) throw StateError('No active player');
  final db = ref.read(appDatabaseProvider);
  final player = await ref.watch(activePlayerProvider.future);
  final city = await ref.watch(activeCityProvider.future);
  final placements = await ref.watch(placementsProvider.future);
  final researchedIds = await db.researchedBuildingTypeIds(playerId);
  final firedBeats = await db.firedBeatIds(playerId);

  // Population (stepped by `tickPopulation`) and fired beats (recorded by
  // `fireBeats`) are both live now — v1's buildings only gate on placed
  // buildings, but richer Phase 8/9 unlock rules can use either.
  final ctx = UnlockContext(
    lifetimeBricksEarned: player.lifetimeBricksEarned,
    population: city.population,
    placedBuildingTypeIds: placements.map((p) => p.buildingTypeId).toSet(),
    firedBeatIds: firedBeats,
  );
  const engine = BuildingDagEngine();
  final availableIds = engine.availableToResearch(ctx).map((b) => b.id).toSet();

  final entries = <CatalogEntry>[];
  for (final b in buildingRegistry) {
    if (researchedIds.contains(b.id)) {
      entries.add(CatalogEntry(building: b, researched: true));
    } else if (availableIds.contains(b.id)) {
      entries.add(CatalogEntry(building: b, researched: false));
    }
  }
  return entries;
});

/// Number of rounds (answered questions) an *un-read* bubble stays on screen
/// before it rotates off. Keeps stale bubbles from piling up; the beat row
/// stays `onScreen` (so it won't re-fire) but drops out of this list once it's
/// older than the window. Phase-7 placeholder — tuned in Phase 8/9.
const kBubbleRotationRounds = 8;

/// Number of rounds of math play a bubble the player has *read* lingers on
/// screen before it retires. Reading no longer dismisses a bubble instantly —
/// it hangs around a few rounds so it doesn't blink out the moment the card
/// closes — see [CityActions.fireBeats].
const kReadHideRounds = 3;

/// Minimum rounds between two *new* beats appearing. When a single build makes
/// several beats eligible at once, they trickle out one every
/// [kNewBeatSpacingRounds] rounds instead of bursting all at once. The
/// first-ever fire is always allowed. Phase-7 placeholder — tuned in 8/9.
const kNewBeatSpacingRounds = 5;

/// Story beats currently showing as bubbles in the active city, newest fires
/// included. The UI caps how many it draws (~5) and handles tap-to-expand.
/// A beat shows while it's in the `onScreen` state and either: hasn't been read
/// and fired within the last [kBubbleRotationRounds] rounds, or was read within
/// the last [kReadHideRounds] rounds. Older bubbles drop out of this list.
final onScreenBeatsProvider = FutureProvider<List<StoryBeat>>((ref) async {
  final playerId = ref.watch(activePlayerIdProvider);
  if (playerId == null) return const <StoryBeat>[];
  final db = ref.read(appDatabaseProvider);
  final player = await db.getPlayerById(playerId);
  final states = await db.storyBeatStatesForPlayer(playerId);
  final beats = <StoryBeat>[];
  for (final entry in states.entries) {
    final st = entry.value;
    if (st.state != 'onScreen') continue;
    final ackedAt = st.ackedAtRound;
    if (ackedAt != null) {
      // Read by the player: keep it up for a few rounds of math play, then let
      // it slip off (fireBeats retires it to 'acked' around the same time).
      if (player.roundsPlayed - ackedAt >= kReadHideRounds) continue;
    } else {
      final firedAt = st.lastFiredAtRound;
      if (firedAt != null &&
          player.roundsPlayed - firedAt >= kBubbleRotationRounds) {
        continue; // rotated off after sitting un-read too long
      }
    }
    final beat = findBeatById(entry.key);
    if (beat != null) beats.add(beat);
  }
  return beats;
});

/// Side-effecting city operations. Kept off the widget so the placement
/// orchestration (spend 🧱 → insert row → invalidate) lives in one place.
final cityActionsProvider = Provider<CityActions>(CityActions.new);

class CityActions {
  CityActions(this._ref);

  final Ref _ref;

  /// Spends the building's `brickCost` and records the placement at
  /// `(col, row)`. No-op if there's no active player. Invalidates the
  /// placement, player, and player-list providers so every screen refreshes.
  Future<void> placeBuilding(BuildingType type, int col, int row) async {
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return;
    final db = _ref.read(appDatabaseProvider);
    final city = await _ref.read(activeCityProvider.future);
    await db.placeBuilding(
      cityId: city.id,
      playerId: playerId,
      buildingTypeId: type.id,
      gridX: col,
      gridY: row,
      brickCost: type.brickCost,
    );
    _ref
      ..invalidate(placementsProvider)
      ..invalidate(activePlayerProvider)
      ..invalidate(allPlayersProvider);
    // A new building changes the city's capacity — step the population toward
    // it so placing something gives immediate (if small) feedback — then
    // re-evaluate beats (e.g. a placement clears a demand / triggers praise).
    await tickPopulation();
    await fireBeats();
  }

  /// Re-evaluates every story beat against the current city + player state and
  /// fires (puts on screen) any that are newly eligible — i.e. eligible and
  /// not already showing. Called on each placement and each answered question.
  /// No-op when there's no active player or nothing newly fires.
  ///
  /// Building-age triggers (`minBuildingAgeForId`) are evaluated against the
  /// player's round clock: each placed type's age is the round clock minus the
  /// earliest `placedAtRound` among its placements (its *oldest* instance).
  Future<void> fireBeats() async {
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return;
    final db = _ref.read(appDatabaseProvider);
    final player = await db.getPlayerById(playerId);
    final city = await db.cityForPlayer(playerId);
    final placements = await db.placementsForCity(city.id);
    var states = await db.storyBeatStatesForPlayer(playerId);

    // Retire bubbles the player read more than [kReadHideRounds] rounds ago:
    // flip them out of `onScreen` so they stop showing and can re-fire later if
    // their trigger comes back around. Reload state if anything changed.
    var retired = false;
    for (final entry in states.entries) {
      final st = entry.value;
      final ackedAt = st.ackedAtRound;
      if (st.state == 'onScreen' &&
          ackedAt != null &&
          player.roundsPlayed - ackedAt >= kReadHideRounds) {
        await db.setBeatState(playerId, entry.key, 'acked');
        retired = true;
      }
    }
    if (retired) states = await db.storyBeatStatesForPlayer(playerId);

    final placedIds = placements.map((p) => p.buildingTypeId).toSet();
    final firedIds = <String>{
      for (final e in states.entries)
        if (e.value.fireCount > 0) e.key,
    };

    // Age of each type's oldest placement, in rounds (answered questions).
    final ageByType = <String, int>{};
    for (final p in placements) {
      final age = player.roundsPlayed - p.placedAtRound;
      final prev = ageByType[p.buildingTypeId];
      if (prev == null || age > prev) ageByType[p.buildingTypeId] = age;
    }

    TriggerContext contextFor(StoryBeat beat) {
      final st = states[beat.id];
      final lastBricks = st?.lifetimeBricksAtLastFire;
      return TriggerContext(
        placedBuildingTypeIds: placedIds,
        population: city.population,
        maxBuildingAgeByTypeId: ageByType,
        firedBeatIds: firedIds,
        bricksEarnedSinceBeatLastFired: lastBricks == null
            ? null
            : player.lifetimeBricksEarned - lastBricks,
      );
    }

    // New beats trickle out a few rounds apart instead of bursting all at once
    // when a single build makes several eligible. Gate against the most recent
    // fire of ANY beat; the first-ever fire is always allowed.
    int? lastFireRound;
    for (final st in states.values) {
      final r = st.lastFiredAtRound;
      if (r != null && (lastFireRound == null || r > lastFireRound)) {
        lastFireRound = r;
      }
    }
    final canFireNew =
        lastFireRound == null ||
        player.roundsPlayed - lastFireRound >= kNewBeatSpacingRounds;

    const engine = BeatEngine();
    var fired = false;
    if (canFireNew) {
      for (final beat in engine.eligibleBeats(contextFor: contextFor)) {
        // Already showing? Leave it (don't re-fire or bump the count).
        if (states[beat.id]?.state == 'onScreen') continue;
        await db.recordBeatFired(
          playerId,
          beat.id,
          player.lifetimeBricksEarned,
          player.roundsPlayed,
        );
        fired = true;
        // Fire just one new beat per pass; the rest wait their turn so the
        // player isn't flooded with bubbles in a single round.
        break;
      }
    }
    // Firing a beat changes the fired-beat set some unlock rules gate on.
    if (fired) _ref.invalidate(cityCatalogProvider);
    // The round clock may have advanced (rotating a stale bubble off) or a
    // read bubble retired even when nothing newly fired — always refresh it.
    _ref.invalidate(onScreenBeatsProvider);
  }

  /// Advances the active city's population one tick toward the capacity its
  /// current buildings support (see `population_model.dart`). Called on each
  /// placement and on each answered question, so the city grows as the player
  /// builds and plays math. No-op when there's no active player or the
  /// population is already at capacity. Reads straight from the DB (not the
  /// providers) so it always sees the latest persisted state.
  Future<void> tickPopulation() async {
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return;
    final db = _ref.read(appDatabaseProvider);
    final city = await db.cityForPlayer(playerId);
    final placements = await db.placementsForCity(city.id);
    final placed = <BuildingType>[];
    for (final p in placements) {
      final b = findBuildingTypeById(p.buildingTypeId);
      if (b != null) placed.add(b);
    }
    final next = stepPopulation(city.population, populationCapacity(placed));
    if (next != city.population) {
      await db.setCityPopulation(city.id, next);
      // The catalog gates some unlocks on population, so it rebuilds off this.
      _ref.invalidate(activeCityProvider);
    }
  }

  /// Spends [type]'s `researchCost` 🔬 and adds it to the player's catalog.
  /// Invalidates the catalog (so the card flips from locked to placeable) and
  /// the player (so the 🔬 balance updates). No-op if there's no active player.
  /// The caller must have verified affordability.
  Future<void> researchBuilding(BuildingType type) async {
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return;
    final db = _ref.read(appDatabaseProvider);
    await db.researchBuilding(
      playerId: playerId,
      buildingTypeId: type.id,
      researchCost: type.researchCost,
    );
    _ref
      ..invalidate(cityCatalogProvider)
      ..invalidate(activePlayerProvider)
      ..invalidate(allPlayersProvider);
  }

  /// Moves an existing placement to `(col, row)`. Used for `unique`
  /// building types so a second "place" relocates the first instance
  /// instead of stacking a duplicate.
  Future<void> moveBuilding(int placementId, int col, int row) async {
    final db = _ref.read(appDatabaseProvider);
    await db.moveBuildingPlacement(
      placementId: placementId,
      gridX: col,
      gridY: row,
    );
    _ref.invalidate(placementsProvider);
  }

  /// Marks an on-screen citizen bubble as read by the player. The bubble does
  /// NOT vanish immediately — it lingers for [kReadHideRounds] more rounds of
  /// math play before [fireBeats] retires it off screen (after which it can
  /// re-fire once its trigger passes again, subject to its brick-spacing
  /// cooldown). No-op when there's no active player.
  Future<void> markBeatRead(String beatId) async {
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return;
    final db = _ref.read(appDatabaseProvider);
    final player = await db.getPlayerById(playerId);
    await db.markBeatRead(playerId, beatId, player.roundsPlayed);
    _ref.invalidate(onScreenBeatsProvider);
  }

  // ---- Debug-only helpers (kDebugMode; driven by the city debug sheet) ----
  // These let a developer exercise the city mechanics without grinding math
  // questions for currency. Tree-shaken out of release with the UI that calls
  // them; each also asserts it isn't reached in a non-debug build.

  /// Grants [amount] 🧱. Lifetime bricks bump too (so brick-gated unlock
  /// rules also advance, exactly as earning would).
  Future<void> debugGrantBricks(int amount) async {
    assert(kDebugMode, 'debug helper called in a non-debug build');
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return;
    final db = _ref.read(appDatabaseProvider);
    await db.incrementPlayerBricks(playerId, amount);
    _ref
      ..invalidate(activePlayerProvider)
      ..invalidate(allPlayersProvider)
      ..invalidate(cityCatalogProvider);
  }

  /// Grants [amount] 🔬 (lifetime research bumps too).
  Future<void> debugGrantResearch(int amount) async {
    assert(kDebugMode, 'debug helper called in a non-debug build');
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return;
    await _ref
        .read(appDatabaseProvider)
        .incrementPlayerResearch(playerId, amount);
    _ref
      ..invalidate(activePlayerProvider)
      ..invalidate(allPlayersProvider)
      ..invalidate(cityCatalogProvider);
  }

  /// Sets the city's population directly (bypassing the growth model) so
  /// population-gated beats and unlock rules can be exercised without
  /// building up to the threshold. Re-evaluates beats afterward.
  Future<void> debugSetPopulation(int value) async {
    assert(kDebugMode, 'debug helper called in a non-debug build');
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return;
    final db = _ref.read(appDatabaseProvider);
    final city = await db.cityForPlayer(playerId);
    await db.setCityPopulation(city.id, value);
    _ref.invalidate(activeCityProvider);
    await fireBeats();
  }

  /// Researches every building type in the registry for free, bypassing both
  /// the 🔬 cost and the unlock DAG, so the whole catalog is placeable.
  Future<void> debugResearchAll() async {
    assert(kDebugMode, 'debug helper called in a non-debug build');
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return;
    final db = _ref.read(appDatabaseProvider);
    for (final b in buildingRegistry) {
      await db.researchBuilding(
        playerId: playerId,
        buildingTypeId: b.id,
        researchCost: 0,
      );
    }
    _ref.invalidate(cityCatalogProvider);
  }

  /// Advances the round clock by [by] (normally one answered question adds 1)
  /// without grinding math, then re-evaluates beats — so age-gated beats (e.g.
  /// the aged-mayor milestone at 10 rounds) and bubble rotation (off after
  /// [kBubbleRotationRounds]) can be exercised directly. Population is left to
  /// its own slider so the two controls stay independent.
  Future<void> debugAdvanceRounds(int by) async {
    assert(kDebugMode, 'debug helper called in a non-debug build');
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return;
    final db = _ref.read(appDatabaseProvider);
    for (var i = 0; i < by; i++) {
      await db.incrementRoundsPlayed(playerId);
    }
    _ref.invalidate(activePlayerProvider);
    await fireBeats();
  }

  /// Force-fires [beatId] (puts its bubble on screen) regardless of whether
  /// its trigger currently passes.
  Future<void> debugFireBeat(String beatId) async {
    assert(kDebugMode, 'debug helper called in a non-debug build');
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return;
    final db = _ref.read(appDatabaseProvider);
    final player = await db.getPlayerById(playerId);
    await db.recordBeatFired(
      playerId,
      beatId,
      player.lifetimeBricksEarned,
      player.roundsPlayed,
    );
    _ref
      ..invalidate(onScreenBeatsProvider)
      ..invalidate(cityCatalogProvider);
  }

  /// Wipes the city back to a brand-new-player baseline (placements,
  /// research, beats, milestones, population, and both currencies) and
  /// re-seeds the pre-researched set. See [AppDatabase.resetCityForPlayer].
  Future<void> debugResetCity() async {
    assert(kDebugMode, 'debug helper called in a non-debug build');
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return;
    await _ref.read(appDatabaseProvider).resetCityForPlayer(playerId);
    _ref
      ..invalidate(placementsProvider)
      ..invalidate(activeCityProvider)
      ..invalidate(cityCatalogProvider)
      ..invalidate(onScreenBeatsProvider)
      ..invalidate(activePlayerProvider)
      ..invalidate(allPlayersProvider);
  }
}
