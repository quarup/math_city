import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/data/construction_sites.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/city/beat_engine.dart';
import 'package:math_city/domain/city/beat_registry.dart';
import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/building_type.dart';
import 'package:math_city/domain/city/construction_site.dart';
import 'package:math_city/domain/city/dag_engine.dart';
import 'package:math_city/domain/city/population_model.dart';
import 'package:math_city/domain/city/story_beat.dart';
import 'package:math_city/domain/city/trigger_rule.dart';
import 'package:math_city/domain/city/unlock_rule.dart';
import 'package:math_city/domain/city/upgrade_ladders.dart';
import 'package:math_city/state/game_session_provider.dart';
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

/// The set of owned 4×4 land blocks (block coords) for the active city. Drives
/// the terrain the board paints and which blocks are placeable / buyable.
final ownedBlocksProvider = FutureProvider<Set<(int, int)>>((ref) async {
  final city = await ref.watch(activeCityProvider.future);
  final db = ref.read(appDatabaseProvider);
  return db.ownedBlocksForCity(city.id);
});

/// Every open construction site in the active city (city_builder.md §8),
/// oldest first. Sites contribute nothing to population or unlock rules
/// until they open.
final sitesProvider = FutureProvider<List<CitySite>>((ref) async {
  final city = await ref.watch(activeCityProvider.future);
  final placements = await ref.watch(placementsProvider.future);
  final db = ref.read(appDatabaseProvider);
  return sitesFromRows(await db.sitesForCity(city.id), placements);
});

/// kDebugMode-only: when true the catalog shows every building regardless of
/// its unlock rule, so late-game content (and the vehicles its buildings
/// unlock) can be exercised without playing up to it. Session-only — never
/// persisted, off again on the next launch.
final NotifierProvider<DebugUnlockAll, bool> debugUnlockAllProvider =
    NotifierProvider<DebugUnlockAll, bool>(DebugUnlockAll.new);

class DebugUnlockAll extends Notifier<bool> {
  @override
  bool build() => false;

  void set({required bool on}) {
    assert(kDebugMode, 'debug helper called in a non-debug build');
    state = on;
  }
}

/// The build-mode catalog: every building whose unlock rule currently passes,
/// in registry order (stable display). Placing one starts a construction site
/// at its coin price — there is no purchase and no affordability check.
/// Drives the bottom catalog bar on the city screen.
final cityCatalogProvider = FutureProvider<List<BuildingType>>((ref) async {
  final playerId = ref.watch(activePlayerIdProvider);
  if (playerId == null) throw StateError('No active player');
  if (kDebugMode && ref.watch(debugUnlockAllProvider)) {
    return buildingRegistry.toList();
  }
  final db = ref.read(appDatabaseProvider);
  final player = await ref.watch(activePlayerProvider.future);
  final city = await ref.watch(activeCityProvider.future);
  final placements = await ref.watch(placementsProvider.future);
  final readBeats = await db.readBeatIds(playerId);

  // A building's card only appears once the player has opened the demand beat
  // that asks for it (`requiredBeatsRead`), on top of any placement/population
  // gates. Population is stepped by `tickPopulation`; read beats by
  // `markBeatRead`.
  // An opened upgrade removes its source, so a placed rung also stands in
  // for every rung below it — a town hall is still a mayor's office.
  final ctx = UnlockContext(
    lifetimeCoinsEarned: player.lifetimeCoinsEarned,
    population: city.population,
    placedBuildingTypeIds: placedWithLadderAncestors(
      placements.map((p) => p.buildingTypeId),
    ),
    readBeatIds: readBeats,
  );
  const engine = BuildingDagEngine();
  return engine.availableToBuy(ctx);
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

/// A beat currently on screen, plus whether it's in its post-completion ✓
/// flash. Completed bubbles render differently (praise-green ring + ✓ badge)
/// and the overlay auto-retires them after a short wall-clock delay.
class OnScreenBeat {
  const OnScreenBeat({required this.beat, required this.completed});

  final StoryBeat beat;
  final bool completed;
}

/// Story beats currently showing as bubbles in the active city, newest fires
/// included. The UI caps how many it draws (~5) and handles tap-to-expand.
/// A beat shows while it's in the `onScreen` state and either: hasn't been read
/// and fired within the last [kBubbleRotationRounds] rounds, or was read within
/// the last [kReadHideRounds] rounds. Older bubbles drop out of this list.
/// `'completed'` beats are always surfaced — the overlay retires them on a
/// short timer.
final onScreenBeatsProvider = FutureProvider<List<OnScreenBeat>>((ref) async {
  final playerId = ref.watch(activePlayerIdProvider);
  if (playerId == null) return const <OnScreenBeat>[];
  final db = ref.read(appDatabaseProvider);
  final player = await db.getPlayerById(playerId);
  final states = await db.storyBeatStatesForPlayer(playerId);
  final beats = <OnScreenBeat>[];
  for (final entry in states.entries) {
    final st = entry.value;
    if (st.state == 'completed') {
      final beat = findBeatById(entry.key);
      if (beat != null) beats.add(OnScreenBeat(beat: beat, completed: true));
      continue;
    }
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
    if (beat != null) beats.add(OnScreenBeat(beat: beat, completed: false));
  }
  return beats;
});

/// Side-effecting city operations. Kept off the widget so the placement
/// orchestration (spend coins → insert row → invalidate) lives in one place.
final cityActionsProvider = Provider<CityActions>(CityActions.new);

class CityActions {
  CityActions(this._ref);

  final Ref _ref;

  /// Records a finished building at `(col, row)` — the free path (the
  /// mayor's office). Priced buildings go through [startSite] and are placed
  /// by [payIntoSite] when the site fills. Returns the new placement's id (so
  /// the caller can keep it selected for repositioning), or null if there's
  /// no active player.
  Future<int?> placeBuilding(BuildingType type, int col, int row) async {
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return null;
    final db = _ref.read(appDatabaseProvider);
    final city = await _ref.read(activeCityProvider.future);
    final id = await db.placeBuilding(
      cityId: city.id,
      playerId: playerId,
      buildingTypeId: type.id,
      gridX: col,
      gridY: row,
    );
    await _afterCityChange();
    return id;
  }

  /// A building opened or land was added: refresh what depends on it, step
  /// the population toward the new capacity so the change gives immediate
  /// feedback, then re-evaluate beats (a placement clears a demand /
  /// triggers praise).
  Future<void> _afterCityChange() async {
    _ref
      ..invalidate(placementsProvider)
      ..invalidate(ownedBlocksProvider)
      ..invalidate(sitesProvider)
      ..invalidate(cityCatalogProvider)
      ..invalidate(activePlayerProvider)
      ..invalidate(allPlayersProvider);
    await tickPopulation();
    await fireBeats();
  }

  /// Starts a construction site for [goal] (city_builder.md §8.2 step 2):
  /// no coins change hands. Re-checks the domain rules ([checkStartSite])
  /// against persisted state and returns the rejection if any. A free goal
  /// (the mayor's office) opens at once, so no site row is created for it.
  /// On success returns the new site id — or, for a free goal, the new
  /// placement id in [SiteStart.placementId].
  Future<SiteStart> startSite(SiteGoal goal) async {
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return const SiteStart.noPlayer();
    final db = _ref.read(appDatabaseProvider);
    final city = await db.cityForPlayer(playerId);
    final placements = await db.placementsForCity(city.id);
    final open = sitesFromRows(await db.sitesForCity(city.id), placements);
    final rejection = checkStartSite(
      goal: goal,
      openSites: open.map((s) => s.site),
      ownedBlocks: await db.ownedBlocksForCity(city.id),
    );
    if (rejection != null) return SiteStart.rejected(rejection, open);

    if (goal.price == 0 && goal is BuildingGoal) {
      final id = await placeBuilding(goal.type, goal.col, goal.row);
      return SiteStart.opened(placementId: id);
    }
    final int siteId;
    switch (goal) {
      case BuildingGoal():
        siteId = await db.startBuildingSite(
          cityId: city.id,
          playerId: playerId,
          buildingTypeId: goal.type.id,
          gridX: goal.col,
          gridY: goal.row,
          upgradesFromPlacementId: goal.upgrade?.sourcePlacementId,
        );
      case LandBlockGoal():
        siteId = await db.startLandSite(
          cityId: city.id,
          playerId: playerId,
          blockX: goal.blockX,
          blockY: goal.blockY,
        );
    }
    _ref.invalidate(sitesProvider);
    return SiteStart.started(siteId: siteId);
  }

  /// Moves a building site's footprint to `(col, row)`; its coins stay.
  Future<void> moveSite(int siteId, int col, int row) async {
    final db = _ref.read(appDatabaseProvider);
    await db.moveSite(siteId: siteId, gridX: col, gridY: row);
    _ref.invalidate(sitesProvider);
  }

  /// Pays [coins] into site [siteId] and opens it if the bar reaches the
  /// price (the building is placed / the land is owned, the site row goes).
  /// Returns what happened, or null if the site no longer exists (it opened
  /// earlier in the block, say) — the caller then has nowhere to put the
  /// coins, which is the §8.11 overflow case; the lifetime counter already
  /// counted them.
  Future<PayInResult?> payIntoSite(int siteId, int coins) async {
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return null;
    final db = _ref.read(appDatabaseProvider);
    final row = await db.siteById(siteId);
    if (row == null) return null;
    final site = siteFromRow(row, await db.placementsForCity(row.cityId));
    if (site == null) return null;
    final result = site.payIn(coins);
    await db.setSitePaidCoins(siteId, result.site.paidCoins);
    if (result.site.isFull) {
      await db.openSite(siteId, playerId: playerId);
      await _afterCityChange();
    } else {
      _ref.invalidate(sitesProvider);
    }
    return result;
  }

  /// Cancels site [siteId] (city_builder.md §8.11, revised 2026-09-20): the
  /// row goes and every coin paid into it comes back as credit, in full —
  /// a change of mind costs nothing, the coins just move. Returns the
  /// refund, or null if the site no longer exists.
  Future<int?> cancelSite(int siteId) async {
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return null;
    final db = _ref.read(appDatabaseProvider);
    final refund = await db.cancelSite(siteId, playerId: playerId);
    if (refund == null) return null;
    if (_ref.read(activeSiteIdProvider) == siteId) {
      _ref.read(activeSiteIdProvider.notifier).selected = null;
    }
    _ref
      ..invalidate(sitesProvider)
      ..invalidate(activePlayerProvider)
      ..invalidate(allPlayersProvider);
    return refund;
  }

  /// Puts as much of the player's credit as site [siteId] still needs into
  /// it, opening it when that fills the bar (the same path a block's coins
  /// take). Leftover credit stays. Returns what happened, or null when
  /// there was no credit, nothing left to pay, or no such site.
  Future<PayInResult?> applyCredit(int siteId) async {
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return null;
    final db = _ref.read(appDatabaseProvider);
    final credit = (await db.getPlayerById(playerId)).creditBalance;
    if (credit <= 0) return null;
    final row = await db.siteById(siteId);
    if (row == null) return null;
    final site = siteFromRow(row, await db.placementsForCity(row.cityId));
    if (site == null) return null;
    final amount = credit < site.remaining ? credit : site.remaining;
    if (amount <= 0) return null;
    final result = site.payIn(amount);
    await db.setSitePaidCoins(siteId, result.site.paidCoins);
    await db.addCredit(playerId, -amount);
    if (result.site.isFull) {
      await db.openSite(siteId, playerId: playerId);
      await _afterCityChange();
    } else {
      _ref
        ..invalidate(sitesProvider)
        ..invalidate(activePlayerProvider)
        ..invalidate(allPlayersProvider);
    }
    return result;
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
      final lastBricks = st?.lifetimeCoinsAtLastFire;
      return TriggerContext(
        placedBuildingTypeIds: placedIds,
        population: city.population,
        maxBuildingAgeByTypeId: ageByType,
        firedBeatIds: firedIds,
        coinsEarnedSinceBeatLastFired: lastBricks == null
            ? null
            : player.lifetimeCoinsEarned - lastBricks,
      );
    }

    // Player-satisfied demands/warnings (the building they nudged toward now
    // exists, etc.) flip to 'completed' so the overlay shows a brief ✓ flash
    // before retiring. Praise beats don't fulfil — leave them on the normal
    // read/rotation path. Reload state if anything changed.
    var completed = false;
    for (final entry in states.entries) {
      final st = entry.value;
      if (st.state != 'onScreen') continue;
      final beat = findBeatById(entry.key);
      if (beat == null) continue;
      if (beat.kind != BeatKind.demand && beat.kind != BeatKind.warning) {
        continue;
      }
      if (beat.triggerRule.evaluate(contextFor(beat))) continue;
      await db.markBeatCompleted(playerId, beat.id);
      completed = true;
    }
    if (completed) states = await db.storyBeatStatesForPlayer(playerId);

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
          player.lifetimeCoinsEarned,
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

  /// Marks an on-screen citizen bubble as read (opened) by the player. The
  /// bubble does NOT vanish immediately — it lingers for [kReadHideRounds] more
  /// rounds of math play before [fireBeats] retires it off screen (after which
  /// it can re-fire once its trigger passes again, subject to its coin-spacing
  /// cooldown). Opening a demand beat is also what unlocks the building it asks
  /// for, so this refreshes the catalog too. No-op when there's no active
  /// player.
  Future<void> markBeatRead(String beatId) async {
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return;
    final db = _ref.read(appDatabaseProvider);
    final player = await db.getPlayerById(playerId);
    await db.markBeatRead(playerId, beatId, player.roundsPlayed);
    _ref
      ..invalidate(onScreenBeatsProvider)
      ..invalidate(cityCatalogProvider);
  }

  /// Retires a beat that's been showing in its post-completion ✓ flash —
  /// called by the overlay after the wall-clock hold elapses (or the player
  /// taps the ✓ sticker). Transitions 'completed' → 'acked' so it stops
  /// showing and the trigger may re-fire later if it ever becomes eligible
  /// again. No-op when there's no active player.
  Future<void> retireCompletedBeat(String beatId) async {
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return;
    final db = _ref.read(appDatabaseProvider);
    await db.setBeatState(playerId, beatId, 'acked');
    _ref.invalidate(onScreenBeatsProvider);
  }

  // ---- Debug-only helpers (kDebugMode; driven by the city debug sheet) ----
  // These let a developer exercise the city mechanics without grinding math
  // questions for currency. Tree-shaken out of release with the UI that calls
  // them; each also asserts it isn't reached in a non-debug build.

  /// Pays [amount] coins into site [siteId] (or, when null, the oldest open
  /// site) exactly as earning would: the lifetime counter bumps too, so
  /// lifetime-gated unlock rules advance. No-op with no open site.
  Future<void> debugPayCoins(int amount, {int? siteId}) async {
    assert(kDebugMode, 'debug helper called in a non-debug build');
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return;
    final db = _ref.read(appDatabaseProvider);
    final target =
        siteId ??
        (await db.sitesForCity(
          (await db.cityForPlayer(playerId)).id,
        )).firstOrNull?.id;
    if (target == null) return;
    await db.addLifetimeCoins(playerId, amount);
    await payIntoSite(target, amount);
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
      player.lifetimeCoinsEarned,
      player.roundsPlayed,
    );
    _ref
      ..invalidate(onScreenBeatsProvider)
      ..invalidate(cityCatalogProvider);
  }

  /// Wipes the city back to a brand-new-player baseline (placements, beats,
  /// milestones, population, coins, and the streak). See
  /// [AppDatabase.resetCityForPlayer].
  Future<void> debugResetCity() async {
    assert(kDebugMode, 'debug helper called in a non-debug build');
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return;
    await _ref.read(appDatabaseProvider).resetCityForPlayer(playerId);
    _ref
      ..invalidate(placementsProvider)
      ..invalidate(ownedBlocksProvider)
      ..invalidate(sitesProvider)
      ..invalidate(activeCityProvider)
      ..invalidate(cityCatalogProvider)
      ..invalidate(onScreenBeatsProvider)
      ..invalidate(activePlayerProvider)
      ..invalidate(allPlayersProvider);
  }
}

/// Outcome of [CityActions.startSite].
class SiteStart {
  const SiteStart.started({required this.siteId})
    : placementId = null,
      rejection = null,
      openSites = const [];

  /// A free goal opened on the spot — there is no site, just a placement.
  const SiteStart.opened({required this.placementId})
    : siteId = null,
      rejection = null,
      openSites = const [];

  const SiteStart.rejected(this.rejection, this.openSites)
    : siteId = null,
      placementId = null;

  const SiteStart.noPlayer()
    : siteId = null,
      placementId = null,
      rejection = null,
      openSites = const [];

  final int? siteId;
  final int? placementId;
  final SiteStartRejection? rejection;

  /// The sites that were open when a start was refused — the nudge names
  /// them (city_builder.md §8.5).
  final List<CitySite> openSites;

  bool get ok => rejection == null && (siteId != null || placementId != null);
}
