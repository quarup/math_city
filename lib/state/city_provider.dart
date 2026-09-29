import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/data/construction_sites.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/city/beat_engine.dart';
import 'package:math_city/domain/city/beat_registry.dart';
import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/building_type.dart';
import 'package:math_city/domain/city/chapter_one.dart';
import 'package:math_city/domain/city/citizen.dart';
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
  final arrivedBeats = await db.firedBeatIds(playerId);

  // A building's card only appears once the demand letter that asks for it
  // has arrived (`requiredBeatsRead` — arrival is the gate, city_builder.md
  // §10.2), on top of any placement/population gates. Population is stepped
  // by `tickPopulation`; letters arrive through `fireBeats`.
  // An opened upgrade removes its source, so a placed rung also stands in
  // for every rung below it — a town hall is still a mayor's office.
  final placedIds = placements.map((p) => p.buildingTypeId).toSet();
  final ctx = UnlockContext(
    lifetimeCoinsEarned: player.lifetimeCoinsEarned,
    population: city.population,
    placedBuildingTypeIds: placedWithLadderAncestors(placedIds),
    readBeatIds: arrivedBeats,
  );
  const engine = BuildingDagEngine();
  // A placed unique building (the mayor's office) has no card: there is
  // nothing more to place, and Move lives on its info card. Upgrade-only
  // rungs (town hall, city hall) come from letters and the office's info
  // card, never a card of their own.
  return engine
      .availableToBuy(ctx)
      .where((b) => !(b.unique && placedIds.contains(b.id)))
      .where((b) => !isUpgradeOnly(b.id))
      .toList();
});

/// Minimum rounds between two *new* beats appearing. When a single build makes
/// several beats eligible at once, they trickle out one every
/// [kNewBeatSpacingRounds] rounds instead of bursting all at once. The
/// first-ever fire is always allowed. Counts rounds *played*, so nothing
/// accrues while the app is closed (city_builder.md §10.3).
const kNewBeatSpacingRounds = 5;

/// A fired beat that has not retired: its letter is either waiting to be
/// shown ([shown] false — the city screen interrupts with it at rest), or has
/// been shown and stays open on its badged catalog card until the request
/// is fulfilled. [completed] marks a demand/warning whose request has just
/// been satisfied; the screen retires those (a thank-you reply follows in
/// §10.2 step 4).
class OpenBeat {
  const OpenBeat({
    required this.beat,
    required this.shown,
    required this.completed,
    required this.firedAtRound,
    required this.delivery,
  });

  final StoryBeat beat;
  final bool shown;
  final bool completed;
  final int firedAtRound;

  /// How this fire reaches the player: a letter (demands, replies), a
  /// pedestrian bubble (engine-fired praise), or a Times front page.
  final BeatDelivery delivery;
}

/// Every open beat for the active player, oldest fire first. Letters never
/// expire (city_builder.md §10.3): a beat stays here from the round it fires
/// until its request is fulfilled and it retires.
final openBeatsProvider = FutureProvider<List<OpenBeat>>((ref) async {
  final playerId = ref.watch(activePlayerIdProvider);
  if (playerId == null) return const <OpenBeat>[];
  final db = ref.read(appDatabaseProvider);
  final states = await db.storyBeatStatesForPlayer(playerId);
  final beats = <OpenBeat>[];
  for (final entry in states.entries) {
    final st = entry.value;
    if (st.state != 'onScreen' &&
        st.state != 'completed' &&
        st.state != 'bubble') {
      continue;
    }
    final beat = findBeatById(entry.key);
    if (beat == null) continue;
    beats.add(
      OpenBeat(
        beat: beat,
        shown: st.ackedAtRound != null,
        completed: st.state == 'completed',
        firedAtRound: st.lastFiredAtRound ?? 0,
        delivery: st.state == 'bubble'
            ? BeatDelivery.bubble
            : beat.staticDelivery,
      ),
    );
  }
  beats.sort((a, b) => a.firedAtRound.compareTo(b.firedAtRound));
  return beats;
});

/// The buildings an upgrade to [targetTypeId] could grow out of
/// (city_builder.md §10.6): every placement of the rung below without an
/// open growth site, oldest first — the letter names the first. Empty for
/// a root or off-ladder target.
List<BuildingPlacement> upgradeSourcesFor(
  String targetTypeId,
  List<BuildingPlacement> placements,
  List<CitySite> sites,
) {
  final below = rungBelow(targetTypeId);
  if (below == null) return const [];
  final growing = <int>{
    for (final s in sites)
      if (s.goal case BuildingGoal(:final upgrade?)) upgrade.sourcePlacementId,
  };
  return placements
      .where((p) => p.buildingTypeId == below && !growing.contains(p.id))
      .toList()
    ..sort((a, b) {
      final byAge = a.placedAtRound.compareTo(b.placedAtRound);
      return byAge != 0 ? byAge : a.id.compareTo(b.id);
    });
}

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
    // A unique type already standing (the seeded mayor's office) moves
    // rather than doubling.
    if (type.unique) {
      final existing = (await db.placementsForCity(
        city.id,
      )).where((p) => p.buildingTypeId == type.id).firstOrNull;
      if (existing != null) {
        await moveBuilding(existing.id, col, row);
        await _afterCityChange();
        return existing.id;
      }
    }
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
  Future<void> _afterCityChange({String? justOpened}) async {
    _ref
      ..invalidate(placementsProvider)
      ..invalidate(ownedBlocksProvider)
      ..invalidate(sitesProvider)
      ..invalidate(cityCatalogProvider)
      ..invalidate(activePlayerProvider)
      ..invalidate(allPlayersProvider);
    await tickPopulation();
    await fireBeats(justOpened: justOpened);
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
      await _afterCityChange(justOpened: _openedTypeOf(site.goal));
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
      await _afterCityChange(justOpened: _openedTypeOf(site.goal));
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
  Future<void> fireBeats({String? justOpened}) async {
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return;
    final db = _ref.read(appDatabaseProvider);
    final player = await db.getPlayerById(playerId);
    final city = await db.cityForPlayer(playerId);
    final placements = await db.placementsForCity(city.id);
    var states = await db.storyBeatStatesForPlayer(playerId);

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

    // The §4.3 imbalance flags the Times warnings narrate.
    final balance = cityBalance(
      [for (final p in placements) ?findBuildingTypeById(p.buildingTypeId)],
      city.population,
    );

    // Buildings with an open site count as present for demands
    // (city_builder.md §10.3): no letter asks for what is already on the way.
    final underConstruction = <String>{
      for (final row in await db.sitesForCity(city.id))
        if (row.buildingTypeId != null) row.buildingTypeId!,
    };

    // [ignoreSpacing] evaluates the rule as if the beat had never fired:
    // the fulfilment check below must not count a beat's own coin-spacing
    // clause (which fails right after it fires) as "no longer wanted".
    TriggerContext contextFor(StoryBeat beat, {bool ignoreSpacing = false}) {
      final st = states[beat.id];
      final lastBricks = st?.lifetimeCoinsAtLastFire;
      return TriggerContext(
        placedBuildingTypeIds: placedIds,
        underConstructionTypeIds: underConstruction,
        population: city.population,
        maxBuildingAgeByTypeId: ageByType,
        firedBeatIds: firedIds,
        lopsided: balance.lopsided,
        growthStalled: balance.growthStalled,
        coinsEarnedSinceBeatLastFired: lastBricks == null || ignoreSpacing
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
      if (beat.triggerRule.evaluate(contextFor(beat, ignoreSpacing: true)) &&
          !_askAnswered(beat, st, placements, underConstruction)) {
        continue;
      }
      await db.markBeatCompleted(playerId, beat.id);
      completed = true;
    }
    if (completed) states = await db.storyBeatStatesForPlayer(playerId);

    // A building just opened: the praise beat that answers it is the
    // citizen's thank-you reply (city_builder.md §10.2), sent at once —
    // first opening only, no spacing — so it follows the celebration.
    if (justOpened != null) {
      for (final beat in beatRegistry) {
        if (beat.kind != BeatKind.praise || beat.scripted) continue;
        if (beat.staticDelivery != BeatDelivery.letter) continue;
        final rule = beat.triggerRule;
        if (rule.buildingsPresent.length != 1 ||
            !rule.buildingsPresent.contains(justOpened) ||
            rule.minBuildingAgeForId != null) {
          continue;
        }
        if ((states[beat.id]?.fireCount ?? 0) > 0) continue;
        if (!rule.evaluate(contextFor(beat, ignoreSpacing: true))) continue;
        await db.recordBeatFired(
          playerId,
          beat.id,
          player.lifetimeCoinsEarned,
          player.roundsPlayed,
        );
        firedIds.add(beat.id);
      }
      states = await db.storyBeatStatesForPlayer(playerId);
    }

    // Chapter one (city_builder.md §10.4): the script sends the letters,
    // not the engine, and each arrives the moment the previous building
    // opens — no spacing.
    if (player.guideStep < kChapterOneDone) {
      await _runChapterOne(
        db: db,
        playerId: playerId,
        guideStep: player.guideStep,
        placedIds: placedIds,
        underConstruction: underConstruction,
        states: states,
        lifetimeCoins: player.lifetimeCoinsEarned,
        roundsPlayed: player.roundsPlayed,
      );
      _ref
        ..invalidate(cityCatalogProvider)
        ..invalidate(openBeatsProvider)
        ..invalidate(activePlayerProvider)
        ..invalidate(allPlayersProvider);
      return;
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
        final current = states[beat.id]?.state;
        if (current == 'onScreen' || current == 'bubble') continue;
        // Engine-fired praise is ambient: a bubble over a passing walker.
        // Replies (the first praise for a just-opened building) fire above.
        final asBubble =
            beat.kind == BeatKind.praise &&
            beat.staticDelivery == BeatDelivery.letter;
        await db.recordBeatFired(
          playerId,
          beat.id,
          player.lifetimeCoinsEarned,
          player.roundsPlayed,
          asBubble ? 'bubble' : 'onScreen',
        );
        fired = true;
        // Fire just one new beat per pass; the rest wait their turn so the
        // player isn't flooded with bubbles in a single round.
        break;
      }
    }
    // A letter's arrival is what reveals its building's card.
    if (fired) _ref.invalidate(cityCatalogProvider);
    _ref.invalidate(openBeatsProvider);
  }

  /// The building type a site's opening places, or null for land.
  String? _openedTypeOf(SiteGoal goal) => switch (goal) {
    BuildingGoal(:final type) => type.id,
    LandBlockGoal() => null,
  };

  /// Whether a demand whose trigger still passes has nevertheless been
  /// answered: its building was started, or placed since the letter fired.
  /// Covers recurring asks (more parks) whose trigger never turns false.
  bool _askAnswered(
    StoryBeat beat,
    StoryBeatState st,
    List<BuildingPlacement> placements,
    Set<String> underConstruction,
  ) {
    if (beat.kind != BeatKind.demand) return false;
    final target = beatTargetBuilding(beat);
    if (target == null) return false;
    if (underConstruction.contains(target.id)) return true;
    final firedAt = st.lastFiredAtRound ?? 0;
    return placements.any(
      (p) => p.buildingTypeId == target.id && p.placedAtRound >= firedAt,
    );
  }

  /// The chapter-one script (city_builder.md §10.4). Advances the step past
  /// every scripted building already standing, fires the step's letter if it
  /// hasn't arrived (or arrived, was fulfilled, and the building then went
  /// away — a cancelled site), and at the end sends the hand-over letter and
  /// marks the chapter done.
  Future<void> _runChapterOne({
    required AppDatabase db,
    required int playerId,
    required int guideStep,
    required Set<String> placedIds,
    required Set<String> underConstruction,
    required Map<String, StoryBeatState> states,
    required int lifetimeCoins,
    required int roundsPlayed,
  }) async {
    var step = chapterOneStepFor(guideStep, placedIds);
    if (step < kHandoverStep) {
      final beatId = chapterOneLetters[step];
      final building = chapterOneBuildings[step];
      final st = states[beatId];
      // (The step only lands here while the building is absent, so a
      // fulfilled-then-cancelled site re-sends the letter.)
      final needsLetter =
          st == null ||
          (st.state != 'onScreen' && !underConstruction.contains(building));
      if (needsLetter) {
        await db.recordBeatFired(playerId, beatId, lifetimeCoins, roundsPlayed);
      }
    } else if (states[kHandoverBeatId] == null) {
      await db.recordBeatFired(
        playerId,
        kHandoverBeatId,
        lifetimeCoins,
        roundsPlayed,
      );
      step = kChapterOneDone;
    } else {
      step = kChapterOneDone;
    }
    if (step != guideStep) await db.setGuideStep(playerId, step);
  }

  /// Ends chapter one early (the parent-facing *Skip the guide*): marks it
  /// done and lets the engine take over at once.
  Future<void> skipGuide() async {
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return;
    final db = _ref.read(appDatabaseProvider);
    await db.setGuideStep(playerId, kChapterOneDone);
    _ref
      ..invalidate(activePlayerProvider)
      ..invalidate(allPlayersProvider);
    await fireBeats();
  }

  /// Records that a one-time gesture hint (the animated hand) has been
  /// shown, so it never plays again for this player.
  Future<void> markHintSeen(GuideHint hint) async {
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return;
    final db = _ref.read(appDatabaseProvider);
    final player = await db.getPlayerById(playerId);
    if (hint.seenIn(player.guideHints)) return;
    await db.setGuideHints(playerId, player.guideHints | hint.bit);
    _ref
      ..invalidate(activePlayerProvider)
      ..invalidate(allPlayersProvider);
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

  /// Records that [beatId]'s letter has been shown to the player, so the
  /// city screen never interrupts with it again; the beat stays open on its
  /// badged catalog card until fulfilled. No-op when there's no active
  /// player.
  Future<void> markBeatRead(String beatId) async {
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return;
    final db = _ref.read(appDatabaseProvider);
    final player = await db.getPlayerById(playerId);
    await db.markBeatRead(playerId, beatId, player.roundsPlayed);
    _ref.invalidate(openBeatsProvider);
  }

  /// Retires a beat whose request has been fulfilled ('completed' → 'acked')
  /// so it leaves the open set; the trigger may re-fire later if it ever
  /// becomes eligible again. No-op when there's no active player.
  Future<void> retireCompletedBeat(String beatId) async {
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return;
    final db = _ref.read(appDatabaseProvider);
    await db.setBeatState(playerId, beatId, 'acked');
    _ref.invalidate(openBeatsProvider);
  }

  /// Repairs a city created before the mayor's office was seeded at
  /// creation (city_builder.md §10.4): places it at the centre if missing.
  /// Idempotent; the city screen calls it once on load.
  Future<void> ensureMayorsOffice() async {
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return;
    final db = _ref.read(appDatabaseProvider);
    final city = await db.cityForPlayer(playerId);
    final before = await db.placementsForCity(city.id);
    if (before.any((p) => p.buildingTypeId == 'mayors_office')) return;
    await db.placeMayorsOffice(cityId: city.id, playerId: playerId);
    await _afterCityChange();
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
  /// the aged-mayor milestone at 10 rounds) and beat spacing can be exercised
  /// directly. Population is left to its own slider so the two controls stay
  /// independent.
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

  /// Force-fires [beatId] (its letter arrives) regardless of whether its
  /// trigger currently passes.
  Future<void> debugFireBeat(String beatId) async {
    assert(kDebugMode, 'debug helper called in a non-debug build');
    final playerId = _ref.read(activePlayerIdProvider);
    if (playerId == null) return;
    final db = _ref.read(appDatabaseProvider);
    final player = await db.getPlayerById(playerId);
    // Praise fires the way the engine would (a bubble); replies come only
    // from a real opening.
    final beat = findBeatById(beatId);
    final asBubble =
        beat?.kind == BeatKind.praise &&
        beat?.staticDelivery == BeatDelivery.letter;
    await db.recordBeatFired(
      playerId,
      beatId,
      player.lifetimeCoinsEarned,
      player.roundsPlayed,
      asBubble ? 'bubble' : 'onScreen',
    );
    _ref
      ..invalidate(openBeatsProvider)
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
      ..invalidate(openBeatsProvider)
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
