import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:math_city/domain/avatar/adventurer_config.dart';
import 'package:math_city/domain/city/building_registry.dart';
import 'package:math_city/domain/city/city_map_registry.dart';
import 'package:math_city/domain/concepts/concept.dart' as dom;
import 'package:math_city/domain/concepts/concept_registry.dart' as dom;
import 'package:math_city/domain/questions/dataset_question.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// ---------------------------------------------------------------------------
// Table definitions
// ---------------------------------------------------------------------------

class Players extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  IntColumn get gradeLevel => integer()();

  /// 🧱 spending balance — decremented on placements, map unlocks, events.
  IntColumn get brickBalance => integer().withDefault(const Constant(0))();

  /// 🧱 lifetime earned — never decreases; available as a gate input on
  /// `BuildingType.unlockRule.minLifetimeBricks`.
  IntColumn get lifetimeBricksEarned =>
      integer().withDefault(const Constant(0))();

  /// 🔬 spending balance — decremented when the player spends research to
  /// move a building type from "available" into `BuildingTypesResearched`.
  IntColumn get researchBalance => integer().withDefault(const Constant(0))();

  /// 🔬 lifetime earned — never decreases; bookkeeping.
  IntColumn get lifetimeResearchEarned =>
      integer().withDefault(const Constant(0))();

  /// The game's "round" clock: a monotonic count of questions this player has
  /// answered. Persists across sessions and never decreases. Drives building
  /// age (a placement stamps the current value into `placedAtRound`, and age =
  /// current value − that stamp) and round-based bubble rotation.
  IntColumn get roundsPlayed => integer().withDefault(const Constant(0))();

  DateTimeColumn get createdAt => dateTime()();
  // Stored as JSON string; null = default avatar.
  TextColumn get avatarConfig => text().nullable()();
}

extension PlayerAvatarExt on Player {
  AdventurerConfig get avatar => avatarConfig != null
      ? AdventurerConfig.fromJsonString(avatarConfig!)
      : const AdventurerConfig();
}

class ConceptProficiencies extends Table {
  IntColumn get playerId => integer().references(Players, #id)();
  TextColumn get conceptId => text()();
  RealColumn get proficiency => real()();
  IntColumn get questionsAnswered => integer().withDefault(const Constant(0))();
  IntColumn get questionsCorrect => integer().withDefault(const Constant(0))();
  DateTimeColumn get lastUpdatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {playerId, conceptId};
}

/// Per-player set of concept IDs the DAG drip-feed has introduced. The
/// wheel only spins concepts in this set (further filtered by the in-memory
/// generator registry — concepts without registered generators are skipped).
class IntroducedConcepts extends Table {
  IntColumn get playerId => integer().references(Players, #id)();
  TextColumn get conceptId => text()();
  DateTimeColumn get introducedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {playerId, conceptId};
}

/// Read-only catalog of sub-concepts. Seeded from
/// `lib/domain/concepts/concept_registry.dart` on first launch / migration;
/// mirrored in the schema so future features (statistics roll-ups, progress
/// screen) can JOIN against it without depending on the in-memory list.
@DataClassName('CatalogConcept')
class Concepts extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get shortLabel => text()();
  TextColumn get categoryId => text()();
  IntColumn get primaryGrade => integer()();

  /// Comma-separated list of prereq concept IDs. Empty string = root node.
  TextColumn get prereqIdsCsv => text().withDefault(const Constant(''))();
  TextColumn get sourceStrategy => text()();
  TextColumn get diagramRequirement => text()();
  IntColumn get categoryRowOrder => integer()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

/// Bundled dataset-sourced questions (DeepMind, GSM8K, etc.). Seeded once
/// from `assets/data/dataset_questions/*.json` on first launch and on
/// schema migration; thereafter read at runtime by `QuestionSource` to
/// mix with algorithmic generator output.
@DataClassName('DatasetQuestionRow')
class DatasetQuestions extends Table {
  TextColumn get id => text()();
  TextColumn get conceptId => text()();
  TextColumn get prompt => text()();
  TextColumn get correctAnswer => text()();

  /// JSON-encoded `List<String>` of exactly three wrong answers.
  TextColumn get distractorsJson => text()();

  /// JSON-encoded `List<String>` of 1–4 explanation lines.
  TextColumn get explanationJson => text()();

  TextColumn get source => text()();
  TextColumn get sourceModule => text()();
  TextColumn get license => text()();

  /// `AnswerFormat` enum name (e.g. `"integer"`, `"commaList"`). Carried
  /// into `DatasetQuestion.answerFormat` (and thence into the runtime
  /// `GeneratedQuestion`) at read time.
  TextColumn get answerFormat =>
      text().withDefault(const Constant('integer'))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

// ---------------------------------------------------------------------------
// City-builder tables (Phase 7)
// ---------------------------------------------------------------------------

/// Per-player city instance. A player may own multiple cities (one per
/// `CityMap` they've unlocked); the beginner map's row is auto-created at
/// player creation. Static map metadata lives in
/// `lib/domain/city/city_map_registry.dart`, not here.
class Cities extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get playerId => integer().references(Players, #id)();
  TextColumn get cityMapId => text()();
  IntColumn get gridWidth => integer()();
  IntColumn get gridHeight => integer()();
  IntColumn get population => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

/// One row per placed building. `placedAtRound` is the player's round clock
/// ([Players.roundsPlayed]) at the moment of placement (not a wall-clock date)
/// so the "building age" beat trigger can use it without timezone surprises.
class BuildingPlacements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cityId => integer().references(Cities, #id)();
  TextColumn get buildingTypeId => text()();
  IntColumn get currentTier => integer().withDefault(const Constant(0))();
  IntColumn get gridX => integer()();
  IntColumn get gridY => integer()();
  IntColumn get placedAtRound => integer()();
}

/// Building types the player has spent 🔬 to unlock. Presence => the type
/// appears in the build menu (subject to 🧱 cost per placement).
class BuildingTypesResearched extends Table {
  IntColumn get playerId => integer().references(Players, #id)();
  TextColumn get buildingTypeId => text()();
  DateTimeColumn get researchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {playerId, buildingTypeId};
}

/// Award log for the 🔬 research-currency earning rule (see
/// `lib/domain/city/research_awards.dart`). Presence of a row means +1 🔬
/// has already been awarded for that (player, concept, band-index) triple
/// — so re-crossings after a dip don't double-award.
class ConceptBandMilestones extends Table {
  IntColumn get playerId => integer().references(Players, #id)();
  TextColumn get conceptId => text()();
  IntColumn get bandIndex => integer()();
  DateTimeColumn get awardedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {playerId, conceptId, bandIndex};
}

/// Per-player story-beat state. State enum stored as text. Bubble state
/// survives across sessions per prd.md.
class StoryBeatStates extends Table {
  IntColumn get playerId => integer().references(Players, #id)();
  TextColumn get beatId => text()();
  TextColumn get state =>
      text()(); // 'onScreen' | 'completed' | 'dismissed' | 'acked'
  IntColumn get lastFiredAtRound => integer().nullable()();
  IntColumn get fireCount => integer().withDefault(const Constant(0))();
  IntColumn get lifetimeBricksAtLastFire => integer().nullable()();

  /// Round clock at which the player read this bubble (tapped through to its
  /// full text), or null if still unread. A read bubble stays on screen for a
  /// few more rounds of math play before retiring — see the city provider's
  /// read-hide window. Reset to null whenever the beat (re-)fires.
  IntColumn get ackedAtRound => integer().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {playerId, beatId};
}

// ---------------------------------------------------------------------------
// Database class
// ---------------------------------------------------------------------------

@DriftDatabase(
  tables: [
    Players,
    ConceptProficiencies,
    IntroducedConcepts,
    Concepts,
    DatasetQuestions,
    Cities,
    BuildingPlacements,
    BuildingTypesResearched,
    ConceptBandMilestones,
    StoryBeatStates,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 9;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedConceptCatalog();
      // Dataset-question seeding is deliberately deferred to the first
      // call of [allDatasetQuestionsByConcept] — see note there.
    },
    onUpgrade: (m, from, to) async {
      // v4: replaced 6-row hardcoded registry with the curriculum.md catalog
      // and added introduced_concepts.
      // v5: bundled-dataset Questions table; seeded lazily on first read.
      // v6: added answerFormat column to dataset_questions so commaList
      //   (sort) and other non-integer dataset items can surface their
      //   format to checkAnswer + the keypad/MC gate.
      // v7: Phase 7 city-builder spine — currency split on Players
      //   (brick / research balances + lifetime counters), plus the new
      //   city-builder tables. Static catalogs (BuildingType, StoryBeat,
      //   CityMap) live in code under lib/domain/city/ — not Drift rows.
      // v8: added Players.roundsPlayed — the persistent round clock that
      //   drives building-age beat triggers + round-based bubble rotation.
      // v9: added StoryBeatStates.ackedAtRound — stamps when the player reads
      //   a bubble so it lingers a few rounds before retiring instead of
      //   vanishing on tap.
      // Wipe is acceptable while we have no real users; proper additive
      // migrations land in Phase 11. See plan.md.
      await customStatement('DROP TABLE IF EXISTS story_beat_states');
      await customStatement('DROP TABLE IF EXISTS concept_band_milestones');
      await customStatement('DROP TABLE IF EXISTS building_types_researched');
      await customStatement('DROP TABLE IF EXISTS building_placements');
      await customStatement('DROP TABLE IF EXISTS cities');
      await customStatement('DROP TABLE IF EXISTS dataset_questions');
      await customStatement('DROP TABLE IF EXISTS introduced_concepts');
      await customStatement('DROP TABLE IF EXISTS concepts');
      await customStatement('DROP TABLE IF EXISTS concept_proficiencies');
      await customStatement('DROP TABLE IF EXISTS players');
      await m.createAll();
      await _seedConceptCatalog();
    },
  );

  Future<void> _seedConceptCatalog() async {
    await batch((b) {
      b.insertAll(
        concepts,
        dom.allConcepts.map(_conceptToCompanion).toList(),
      );
    });
  }

  Future<void> _seedDatasetQuestionsIfEmpty() async {
    final existing =
        await (selectOnly(datasetQuestions)
              ..addColumns([datasetQuestions.id])
              ..limit(1))
            .get();
    if (existing.isNotEmpty) return;
    final items = await loadBundledDatasetQuestions();
    if (items.isEmpty) return;
    await batch((b) {
      b.insertAll(
        datasetQuestions,
        items.map(_datasetQuestionToCompanion).toList(),
      );
    });
  }

  /// Returns every bundled dataset question grouped by concept ID. On
  /// first call (table empty), reads `assets/data/dataset_questions/*.json`
  /// into the persisted table; thereafter reads from the table directly.
  ///
  /// Lazy seeding (rather than seeding during migration) keeps `flutter
  /// test`'s `pumpAndSettle` happy: the asset-bundle platform channel
  /// doesn't dispatch inside the pump loop, so any migration-time
  /// `rootBundle.loadString` would hang. By moving the asset I/O to the
  /// first dataset query, widget tests that never touch dataset questions
  /// don't pay the cost.
  Future<Map<String, List<DatasetQuestion>>>
  allDatasetQuestionsByConcept() async {
    await _seedDatasetQuestionsIfEmpty();
    final rows = await select(datasetQuestions).get();
    final out = <String, List<DatasetQuestion>>{};
    for (final r in rows) {
      out
          .putIfAbsent(r.conceptId, () => <DatasetQuestion>[])
          .add(_rowToDatasetQuestion(r));
    }
    return out;
  }

  // ---- Player helpers ----

  Future<List<Player>> getAllPlayers() => select(players).get();

  Future<Player> getPlayerById(int id) =>
      (select(players)..where((t) => t.id.equals(id))).getSingle();

  Future<Player> createPlayer({
    required String name,
    required int gradeLevel,
    required String avatarConfigJson,
  }) async {
    final id = await into(players).insert(
      PlayersCompanion.insert(
        name: name,
        gradeLevel: gradeLevel,
        avatarConfig: Value(avatarConfigJson),
        createdAt: DateTime.now(),
      ),
    );

    // Seed Phase 7 city-builder state for the new player:
    // (a) one City row tied to the beginner map (more maps unlock later
    //     and each gets its own City row), and
    // (b) pre-researched entries for every building type that's free to
    //     research and ungated (the mayor's office in v1).
    await into(cities).insert(
      CitiesCompanion.insert(
        playerId: id,
        cityMapId: beginnerCityMap.id,
        gridWidth: beginnerCityMap.baseGridWidth,
        gridHeight: beginnerCityMap.baseGridHeight,
        createdAt: DateTime.now(),
      ),
    );
    final now = DateTime.now();
    for (final b in preResearchedBuildings) {
      await into(buildingTypesResearched).insert(
        BuildingTypesResearchedCompanion.insert(
          playerId: id,
          buildingTypeId: b.id,
          researchedAt: now,
        ),
      );
    }

    return getPlayerById(id);
  }

  Future<void> updatePlayer(
    int playerId, {
    String? name,
    int? gradeLevel,
    String? avatarConfigJson,
  }) => (update(players)..where((t) => t.id.equals(playerId))).write(
    PlayersCompanion(
      name: name != null ? Value(name) : const Value.absent(),
      gradeLevel: gradeLevel != null ? Value(gradeLevel) : const Value.absent(),
      avatarConfig: avatarConfigJson != null
          ? Value(avatarConfigJson)
          : const Value.absent(),
    ),
  );

  /// Sets a player's brick balances directly. Used by the spending UI; for
  /// per-correct-answer increments use [incrementPlayerBricks].
  Future<void> updatePlayerBricks(
    int playerId, {
    required int brickBalance,
    required int lifetimeBricksEarned,
  }) => (update(players)..where((t) => t.id.equals(playerId))).write(
    PlayersCompanion(
      brickBalance: Value(brickBalance),
      lifetimeBricksEarned: Value(lifetimeBricksEarned),
    ),
  );

  /// Adds `by` 🧱 to the player's spending and lifetime brick balances.
  /// Use this on every correct answer. Negative values (refunds) are
  /// allowed on `brickBalance` only; lifetime stays monotone.
  Future<void> incrementPlayerBricks(int playerId, int by) async {
    final p = await getPlayerById(playerId);
    await (update(players)..where((t) => t.id.equals(playerId))).write(
      PlayersCompanion(
        brickBalance: Value(p.brickBalance + by),
        lifetimeBricksEarned: Value(
          p.lifetimeBricksEarned + (by > 0 ? by : 0),
        ),
      ),
    );
  }

  /// Adds `by` 🔬 to the player's spending and lifetime research balances.
  /// Negative values are allowed on `researchBalance` only (e.g. spending);
  /// lifetime stays monotone.
  Future<void> incrementPlayerResearch(int playerId, int by) async {
    final p = await getPlayerById(playerId);
    await (update(players)..where((t) => t.id.equals(playerId))).write(
      PlayersCompanion(
        researchBalance: Value(p.researchBalance + by),
        lifetimeResearchEarned: Value(
          p.lifetimeResearchEarned + (by > 0 ? by : 0),
        ),
      ),
    );
  }

  /// Advances the player's round clock by one (one answered question = one
  /// round) and returns the new value. Call once per answered question; a
  /// fresh placement stamps the returned value into `placedAtRound`.
  Future<int> incrementRoundsPlayed(int playerId) async {
    final p = await getPlayerById(playerId);
    final next = p.roundsPlayed + 1;
    await (update(players)..where((t) => t.id.equals(playerId))).write(
      PlayersCompanion(roundsPlayed: Value(next)),
    );
    return next;
  }

  // ---- Concept band milestones (research-award log) ----

  /// Returns the set of band indices already awarded for this
  /// (player, concept) pair. Used by the research-award rule to filter out
  /// re-crossings after a dip.
  Future<Set<int>> awardedBandIndicesFor(
    int playerId,
    String conceptId,
  ) async {
    final rows =
        await (select(conceptBandMilestones)..where(
              (t) =>
                  t.playerId.equals(playerId) & t.conceptId.equals(conceptId),
            ))
            .get();
    return rows.map((r) => r.bandIndex).toSet();
  }

  /// Records a band milestone. Idempotent: re-recording the same triple is
  /// a no-op (composite primary key prevents duplicates).
  Future<void> recordBandMilestone(
    int playerId,
    String conceptId,
    int bandIndex,
  ) => into(conceptBandMilestones).insertOnConflictUpdate(
    ConceptBandMilestonesCompanion.insert(
      playerId: playerId,
      conceptId: conceptId,
      bandIndex: bandIndex,
      awardedAt: DateTime.now(),
    ),
  );

  // ---- City helpers (Phase 7) ----

  /// The player's `City` row for [cityMapId] (the beginner map by default).
  /// Auto-created at player creation, so this always resolves for a real
  /// player.
  Future<City> cityForPlayer(
    int playerId, {
    String cityMapId = beginnerCityMapId,
  }) =>
      (select(cities)..where(
            (t) => t.playerId.equals(playerId) & t.cityMapId.equals(cityMapId),
          ))
          .getSingle();

  /// Every building placed in [cityId].
  Future<List<BuildingPlacement>> placementsForCity(int cityId) =>
      (select(buildingPlacements)..where((t) => t.cityId.equals(cityId))).get();

  /// Persists the live resident count for [cityId]. The value is computed by
  /// the pure population model (`lib/domain/city/population_model.dart`); this
  /// just writes it.
  Future<void> setCityPopulation(int cityId, int population) =>
      (update(cities)..where((t) => t.id.equals(cityId))).write(
        CitiesCompanion(population: Value(population)),
      );

  /// Debug-only: wipes a player's city-builder state back to the
  /// just-created baseline — clears placements, researched buildings (then
  /// re-seeds the pre-researched set), beat states, and band-milestone
  /// awards; sets population to 0; and zeroes both currency balances and
  /// their lifetime counters. Driven by the kDebugMode-only city debug sheet.
  Future<void> resetCityForPlayer(int playerId) => transaction(() async {
    final city = await cityForPlayer(playerId);
    await (delete(
      buildingPlacements,
    )..where((t) => t.cityId.equals(city.id))).go();
    await (delete(
      buildingTypesResearched,
    )..where((t) => t.playerId.equals(playerId))).go();
    await (delete(
      storyBeatStates,
    )..where((t) => t.playerId.equals(playerId))).go();
    await (delete(
      conceptBandMilestones,
    )..where((t) => t.playerId.equals(playerId))).go();
    await setCityPopulation(city.id, 0);
    await (update(players)..where((t) => t.id.equals(playerId))).write(
      const PlayersCompanion(
        brickBalance: Value(0),
        lifetimeBricksEarned: Value(0),
        researchBalance: Value(0),
        lifetimeResearchEarned: Value(0),
      ),
    );
    final now = DateTime.now();
    for (final b in preResearchedBuildings) {
      await into(buildingTypesResearched).insert(
        BuildingTypesResearchedCompanion.insert(
          playerId: playerId,
          buildingTypeId: b.id,
          researchedAt: now,
        ),
      );
    }
  });

  /// IDs of the building types the player has unlocked (spent 🔬 on, or
  /// pre-researched). Presence => the type appears in the build menu.
  Future<Set<String>> researchedBuildingTypeIds(int playerId) async {
    final rows = await (select(
      buildingTypesResearched,
    )..where((t) => t.playerId.equals(playerId))).get();
    return rows.map((r) => r.buildingTypeId).toSet();
  }

  /// Unlocks [buildingTypeId]: records a `BuildingTypesResearched` row and
  /// spends [researchCost] 🔬 from the player. Idempotent — if the type is
  /// already researched this is a no-op (so the spend never double-charges).
  /// The caller must have verified the player can afford the cost.
  Future<void> researchBuilding({
    required int playerId,
    required String buildingTypeId,
    required int researchCost,
  }) async {
    final already = await researchedBuildingTypeIds(playerId);
    if (already.contains(buildingTypeId)) return;
    await into(buildingTypesResearched).insert(
      BuildingTypesResearchedCompanion.insert(
        playerId: playerId,
        buildingTypeId: buildingTypeId,
        researchedAt: DateTime.now(),
      ),
    );
    if (researchCost > 0) {
      await incrementPlayerResearch(playerId, -researchCost);
    }
  }

  // ---- Story-beat state helpers ----

  /// Per-beat state for [playerId], keyed by beatId. A beat with no row has
  /// never fired.
  Future<Map<String, StoryBeatState>> storyBeatStatesForPlayer(
    int playerId,
  ) async {
    final rows = await (select(
      storyBeatStates,
    )..where((t) => t.playerId.equals(playerId))).get();
    return {for (final r in rows) r.beatId: r};
  }

  /// IDs of beats that have fired at least once for [playerId]. Feeds the
  /// `requiredBeatsFired` gate on story-beat triggers.
  Future<Set<String>> firedBeatIds(int playerId) async {
    final rows =
        await (select(storyBeatStates)..where(
              (t) =>
                  t.playerId.equals(playerId) &
                  t.fireCount.isBiggerThanValue(0),
            ))
            .get();
    return rows.map((r) => r.beatId).toSet();
  }

  /// IDs of beats the player has opened (read) at least once — i.e. rows with
  /// a non-null `ackedAtRound`. Feeds the `requiredBeatsRead` gate on building
  /// unlock rules, so a building's card only appears after the player reads the
  /// demand beat that asks for it.
  Future<Set<String>> readBeatIds(int playerId) async {
    final rows =
        await (select(storyBeatStates)..where(
              (t) => t.playerId.equals(playerId) & t.ackedAtRound.isNotNull(),
            ))
            .get();
    return rows.map((r) => r.beatId).toSet();
  }

  /// Fires [beatId] for [playerId]: puts it on screen, bumps its fire count,
  /// stamps the player's lifetime bricks at this fire so brick-based spacing
  /// (`minBricksEarnedSinceLastBeat`) can be evaluated on the next eligibility
  /// pass, and records the round it fired at ([atRound]) so the overlay can
  /// rotate the bubble off screen after a few rounds.
  Future<void> recordBeatFired(
    int playerId,
    String beatId,
    int lifetimeBricksAtFire, [
    int atRound = 0,
  ]) async {
    final existing =
        await (select(storyBeatStates)..where(
              (t) => t.playerId.equals(playerId) & t.beatId.equals(beatId),
            ))
            .getSingleOrNull();
    await into(storyBeatStates).insertOnConflictUpdate(
      StoryBeatStatesCompanion.insert(
        playerId: playerId,
        beatId: beatId,
        state: 'onScreen',
        fireCount: Value((existing?.fireCount ?? 0) + 1),
        lifetimeBricksAtLastFire: Value(lifetimeBricksAtFire),
        lastFiredAtRound: Value(atRound),
        // A fresh fire is unread, even if a prior fire had been read.
        ackedAtRound: const Value(null),
      ),
    );
  }

  /// Transitions an existing beat's bubble state ('onScreen' → 'dismissed' /
  /// 'acked'). No-op if the beat has never fired.
  Future<void> setBeatState(int playerId, String beatId, String state) =>
      (update(storyBeatStates)..where(
            (t) => t.playerId.equals(playerId) & t.beatId.equals(beatId),
          ))
          .write(StoryBeatStatesCompanion(state: Value(state)));

  /// Stamps the round at which the player read [beatId]'s bubble, without
  /// taking it off screen. The bubble lingers for the city provider's
  /// read-hide window before it retires. No-op if the beat has never fired.
  Future<void> markBeatRead(int playerId, String beatId, int atRound) =>
      (update(storyBeatStates)..where(
            (t) => t.playerId.equals(playerId) & t.beatId.equals(beatId),
          ))
          .write(StoryBeatStatesCompanion(ackedAtRound: Value(atRound)));

  /// Flips an on-screen demand/warning into its post-fulfilment 'completed'
  /// form: the player did the thing the bubble nudged them toward, so the UI
  /// shows a brief ✓ flash and then retires it. No-op if the beat has never
  /// fired.
  Future<void> markBeatCompleted(int playerId, String beatId) =>
      (update(storyBeatStates)..where(
            (t) => t.playerId.equals(playerId) & t.beatId.equals(beatId),
          ))
          .write(const StoryBeatStatesCompanion(state: Value('completed')));

  /// Places one building: inserts the placement row and spends [brickCost]
  /// from the player's balance (lifetime stays monotone via
  /// [incrementPlayerBricks]). The caller must have already verified tile
  /// vacancy and affordability.
  ///
  /// `placedAtRound` is stamped with the player's current round clock
  /// ([Players.roundsPlayed]) so the "building age" beat trigger measures age
  /// in answered questions since placement (age = current clock − this stamp).
  Future<void> placeBuilding({
    required int cityId,
    required int playerId,
    required String buildingTypeId,
    required int gridX,
    required int gridY,
    required int brickCost,
  }) async {
    final player = await getPlayerById(playerId);
    await into(buildingPlacements).insert(
      BuildingPlacementsCompanion.insert(
        cityId: cityId,
        buildingTypeId: buildingTypeId,
        gridX: gridX,
        gridY: gridY,
        placedAtRound: player.roundsPlayed,
      ),
    );
    if (brickCost > 0) await incrementPlayerBricks(playerId, -brickCost);
  }

  /// Moves an existing placement to `(gridX, gridY)`. Used for unique
  /// buildings (mayor's office) where placing a second one moves the first
  /// instead. `placedAtRound` is preserved so beat triggers keyed on building
  /// age stay accurate.
  Future<void> moveBuildingPlacement({
    required int placementId,
    required int gridX,
    required int gridY,
  }) async {
    await (update(
      buildingPlacements,
    )..where((t) => t.id.equals(placementId))).write(
      BuildingPlacementsCompanion(
        gridX: Value(gridX),
        gridY: Value(gridY),
      ),
    );
  }

  // ---- Proficiency helpers ----

  /// Returns a map of conceptId → proficiency for [playerId].
  /// Only concepts that have been answered at least once are included.
  Future<Map<String, double>> proficiencyMapForPlayer(int playerId) async {
    final rows = await (select(
      conceptProficiencies,
    )..where((t) => t.playerId.equals(playerId))).get();
    return {for (final r in rows) r.conceptId: r.proficiency};
  }

  /// Inserts or updates a proficiency record, incrementing answer counters.
  /// Returns the new proficiency value persisted.
  Future<void> upsertProficiency(
    int playerId,
    String conceptId,
    double proficiency, {
    required bool correct,
  }) async {
    final existing =
        await (select(conceptProficiencies)..where(
              (t) =>
                  t.playerId.equals(playerId) & t.conceptId.equals(conceptId),
            ))
            .getSingleOrNull();

    final answered = (existing?.questionsAnswered ?? 0) + 1;
    final corrects = (existing?.questionsCorrect ?? 0) + (correct ? 1 : 0);

    await into(conceptProficiencies).insertOnConflictUpdate(
      ConceptProficienciesCompanion.insert(
        playerId: playerId,
        conceptId: conceptId,
        proficiency: proficiency,
        questionsAnswered: Value(answered),
        questionsCorrect: Value(corrects),
        lastUpdatedAt: DateTime.now(),
      ),
    );
  }

  // ---- Introduced-concept helpers ----

  Future<Set<String>> introducedConceptIdsForPlayer(int playerId) async {
    final rows = await (select(
      introducedConcepts,
    )..where((t) => t.playerId.equals(playerId))).get();
    return rows.map((r) => r.conceptId).toSet();
  }

  Future<void> introduceConcept(int playerId, String conceptId) =>
      into(introducedConcepts).insertOnConflictUpdate(
        IntroducedConceptsCompanion.insert(
          playerId: playerId,
          conceptId: conceptId,
          introducedAt: DateTime.now(),
        ),
      );

  /// Wipes a player's recorded proficiencies AND introduced-concept set,
  /// returning them to the "fresh player" state. The next read of
  /// [introducedConceptIdsForPlayer] will be empty, which causes the
  /// drip-feed to seed a new starter pack at the player's *current* grade.
  ///
  /// 🧱 and 🔬 balances (current and lifetime) are intentionally NOT touched
  /// — those represent earned currency, not curriculum state.
  ///
  /// Called when a player's grade is changed so the wheel recalibrates
  /// to the new grade rather than continuing to surface stale lower-grade
  /// content from the prior grade's introduced set.
  Future<void> resetSkillsForPlayer(int playerId) async {
    await (delete(
      conceptProficiencies,
    )..where((t) => t.playerId.equals(playerId))).go();
    await (delete(
      introducedConcepts,
    )..where((t) => t.playerId.equals(playerId))).go();
  }
}

// ---------------------------------------------------------------------------
// Catalog seeding helpers
// ---------------------------------------------------------------------------

ConceptsCompanion _conceptToCompanion(dom.Concept c) =>
    ConceptsCompanion.insert(
      id: c.id,
      name: c.name,
      shortLabel: c.shortLabel,
      categoryId: c.categoryId,
      primaryGrade: c.primaryGrade,
      prereqIdsCsv: Value(c.prereqIds.join(',')),
      sourceStrategy: _sourceToString(c.source),
      diagramRequirement: _diagramToString(c.diagramRequirement),
      categoryRowOrder: c.categoryRowOrder,
    );

String _sourceToString(dom.ConceptSource s) => switch (s) {
  dom.ConceptSource.algorithmic => 'algorithmic',
  dom.ConceptSource.algorithmicWithDiagram => 'algorithmic_with_diagram',
  dom.ConceptSource.dataset => 'dataset',
  dom.ConceptSource.algorithmicPlusDataset => 'algorithmic+dataset',
  dom.ConceptSource.algorithmicWithDiagramPlusDataset =>
    'algorithmic_with_diagram+dataset',
  dom.ConceptSource.deferred => 'deferred',
};

String _diagramToString(dom.DiagramRequirement d) => switch (d) {
  dom.DiagramNone() => 'none',
  dom.DiagramOptional() => 'optional',
  dom.DiagramRequired(:final kind) => 'required:$kind',
};

// ---------------------------------------------------------------------------
// Dataset-question seeding helpers
// ---------------------------------------------------------------------------

const String _datasetAssetPrefix = 'assets/data/dataset_questions/';

/// Reads every `assets/data/dataset_questions/*.json` from the asset
/// bundle and returns the parsed [DatasetQuestion]s. Used by the Drift
/// onCreate/onUpgrade flow to seed the persisted Questions table on first
/// run.
///
/// Returns an empty list when the asset bundle is not available (e.g.
/// pure-Dart unit tests that spin up the database without
/// `TestWidgetsFlutterBinding`). The seeded table is then empty and
/// `QuestionSource` degrades to generator-only.
Future<List<DatasetQuestion>> loadBundledDatasetQuestions() async {
  final List<String> paths;
  try {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    paths =
        manifest
            .listAssets()
            .where(
              (k) => k.startsWith(_datasetAssetPrefix) && k.endsWith('.json'),
            )
            .toList()
          ..sort();
  }
  // Intentional broad catch: AssetManifest throws different exception
  // types depending on what's missing (FlutterError for missing manifest,
  // Exception for missing binding). Both should degrade to empty.
  // ignore: avoid_catches_without_on_clauses
  catch (_) {
    return const [];
  }

  final out = <DatasetQuestion>[];
  for (final path in paths) {
    final raw = await rootBundle.loadString(path);
    final decoded = json.decode(raw) as Map<String, dynamic>;
    final items = decoded['items'] as List<dynamic>;
    for (final item in items) {
      out.add(DatasetQuestion.fromJson(item as Map<String, dynamic>));
    }
  }
  return out;
}

DatasetQuestionsCompanion _datasetQuestionToCompanion(DatasetQuestion q) =>
    DatasetQuestionsCompanion.insert(
      id: q.id,
      conceptId: q.conceptId,
      prompt: q.prompt,
      correctAnswer: q.correctAnswer,
      distractorsJson: json.encode(q.distractors),
      explanationJson: json.encode(q.explanation),
      source: q.source,
      sourceModule: q.sourceModule,
      license: q.license,
      answerFormat: Value(answerFormatToString(q.answerFormat)),
    );

DatasetQuestion _rowToDatasetQuestion(DatasetQuestionRow r) => DatasetQuestion(
  id: r.id,
  conceptId: r.conceptId,
  prompt: r.prompt,
  correctAnswer: r.correctAnswer,
  distractors: (json.decode(r.distractorsJson) as List<dynamic>).cast<String>(),
  explanation: (json.decode(r.explanationJson) as List<dynamic>).cast<String>(),
  source: r.source,
  sourceModule: r.sourceModule,
  license: r.license,
  answerFormat: answerFormatFromString(r.answerFormat),
);

// ---------------------------------------------------------------------------
// Factory — opens the SQLite file in the app's documents directory.
// ---------------------------------------------------------------------------

AppDatabase openAppDatabase() => AppDatabase(
  LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'math_city.sqlite'));
    return NativeDatabase.createInBackground(file);
  }),
);
