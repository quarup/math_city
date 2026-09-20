import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:math_city/domain/avatar/adventurer_config.dart';
import 'package:math_city/domain/city/city_map_registry.dart';
import 'package:math_city/domain/city/land_blocks.dart';
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

  /// Coins lifetime earned — never decreases; literally "total seconds
  /// studied". Gate input on `BuildingType.unlockRule.minLifetimeCoins`.
  /// There is no spending balance: a coin only exists inside a construction
  /// site (see `ConstructionSites`; city_builder.md §8.3).
  IntColumn get lifetimeCoinsEarned =>
      integer().withDefault(const Constant(0))();

  /// Coins refunded by cancelled construction sites, waiting to be put into
  /// another site with *Use credit* (city_builder.md §8.11, revised
  /// 2026-09-20). Only ever filled by a refund — never by play — so it stays
  /// at 0 for a player who never cancels, and the UI hides it then.
  IntColumn get creditBalance => integer().withDefault(const Constant(0))();

  /// Consecutive correct answers: +1 per correct, reset to 0 on a wrong one.
  /// Uncapped (shown as "N in a row!"); coin pay tops out at `kStreakCap`.
  /// Global per player and persistent across sessions — the opening ramp
  /// doubles as a tutorial.
  IntColumn get streakCount => integer().withDefault(const Constant(0))();

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
  IntColumn get population => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
}

/// One row per owned 4×4 land block in a city. Land is a *set of blocks* on an
/// effectively-infinite plane (see `lib/domain/city/land_blocks.dart`): the
/// center block is `(0,0)` and the starting 3×3 (rings 0–1) is seeded free at
/// city creation, the rest bought with coins. A block is owned iff a row
/// exists.
class OwnedLandBlocks extends Table {
  IntColumn get cityId => integer().references(Cities, #id)();
  IntColumn get blockX => integer()();
  IntColumn get blockY => integer()();

  /// Composite key: a block is owned at most once per city, and the index it
  /// creates is exactly the lookup `ownedBlocksForCity` needs.
  @override
  Set<Column<Object>> get primaryKey => {cityId, blockX, blockY};
}

/// One row per placed building. `placedAtRound` is the player's round clock
/// ([Players.roundsPlayed]) at the moment of placement (not a wall-clock date)
/// so the "building age" beat trigger can use it without timezone surprises.
class BuildingPlacements extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cityId => integer().references(Cities, #id)();
  TextColumn get buildingTypeId => text()();
  IntColumn get gridX => integer()();
  IntColumn get gridY => integer()();
  IntColumn get placedAtRound => integer()();
}

/// One row per open construction site (city_builder.md §8): the thing the
/// player is paying down by answering questions. Everything with a price is
/// a site — a building (new build or upgrade) or a land block — so
/// [goalKind] says which columns apply. A row exists from placement until
/// the site opens (its coins become a `BuildingPlacements` /
/// `OwnedLandBlocks` row and this row is deleted). There is deliberately no
/// status column: v1 has no cancel, so a site's only exits are *moved* and
/// *opened*. Domain rules live in `lib/domain/city/construction_site.dart`;
/// `lib/data/construction_sites.dart` maps rows to that value type.
@DataClassName('ConstructionSiteRow')
class ConstructionSites extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get cityId => integer().references(Cities, #id)();

  /// `'building'` or `'land'`.
  TextColumn get goalKind => text()();

  // Building goals.
  TextColumn get buildingTypeId => text().nullable()();
  IntColumn get gridX => integer().nullable()();
  IntColumn get gridY => integer().nullable()();

  /// For an upgrade: the `BuildingPlacements.id` this site replaces when it
  /// opens (the old building keeps standing until then).
  IntColumn get upgradesFromPlacementId => integer().nullable()();

  // Land goals.
  IntColumn get blockX => integer().nullable()();
  IntColumn get blockY => integer().nullable()();

  IntColumn get paidCoins => integer().withDefault(const Constant(0))();

  /// The player's round clock when the site was started.
  IntColumn get startedAtRound => integer()();
}

/// Award log for the band-crossing coin bonus (see
/// `lib/domain/economy/band_crossings.dart`). Presence of a row means the
/// bonus has already been paid for that (player, concept, band-index)
/// triple — so re-crossings after a dip don't double-pay.
class ConceptBandMilestones extends Table {
  IntColumn get playerId => integer().references(Players, #id)();
  TextColumn get conceptId => text()();
  IntColumn get bandIndex => integer()();
  DateTimeColumn get awardedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {playerId, conceptId, bandIndex};
}

/// App-wide settings (not per-player). Single-row table keyed on `id = 1`;
/// the row is auto-created on first read. Added in v10 for the
/// text-to-speech toggle and reserved as the home for any future
/// app-level preferences.
class AppSettings extends Table {
  IntColumn get id => integer()();

  /// Text-to-speech for question prompts and story beats. On by default
  /// (see prd.md accessibility goals); persists across sessions.
  BoolColumn get ttsEnabled => boolean().withDefault(const Constant(true))();

  /// Fingerprint of the bundled dataset JSONs at last seed. When an app
  /// update ships changed dataset files, the mismatch triggers a
  /// drop-and-reseed of `dataset_questions` — without this, only-if-empty
  /// seeding meant every dataset fix silently no-shipped to existing
  /// installs.
  TextColumn get datasetFingerprint => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
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

  /// Player's lifetime coins when this beat last fired — feeds the
  /// coin-spacing trigger (`minCoinsEarnedSinceLastBeat`).
  IntColumn get lifetimeCoinsAtLastFire => integer().nullable()();

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
    OwnedLandBlocks,
    BuildingPlacements,
    ConstructionSites,
    ConceptBandMilestones,
    StoryBeatStates,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 17;

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
      // v10: AppSettings (single-row, app-wide) — home for the text-to-
      //   speech toggle. Purely additive; ran as a conditional step so
      //   v9→v10 preserves player data (the pre-v10 wipe block only runs
      //   when coming from a pre-v9 schema).
      // v11: land model changed from a fixed gridWidth×gridHeight rectangle to
      //   a set of owned 4×4 blocks (OwnedLandBlocks); the grid columns were
      //   dropped. Wiped (not migrated) — pre-launch, no real users. See
      //   plan.md.
      // v12: bundled add/sub dataset prompts were re-canonicalised to
      //   "43 − 7 = ?" (they used to carry DeepMind's prose). The seeded
      //   rows are a cache of the asset files, so the table is dropped and
      //   re-seeded on next read; nothing else is touched.
      if (from < 9) {
        // Wipe is acceptable while we have no real users; proper additive
        // migrations land in Phase 11. See plan.md.
        await customStatement('DROP TABLE IF EXISTS story_beat_states');
        await customStatement('DROP TABLE IF EXISTS concept_band_milestones');
        await customStatement(
          'DROP TABLE IF EXISTS building_types_researched',
        );
        await customStatement('DROP TABLE IF EXISTS building_placements');
        await customStatement('DROP TABLE IF EXISTS cities');
        await customStatement('DROP TABLE IF EXISTS dataset_questions');
        await customStatement('DROP TABLE IF EXISTS introduced_concepts');
        await customStatement('DROP TABLE IF EXISTS concepts');
        await customStatement('DROP TABLE IF EXISTS concept_proficiencies');
        await customStatement('DROP TABLE IF EXISTS players');
        await m.createAll();
        await _seedConceptCatalog();
      }
      if (from < 10) {
        await m.createTable(appSettings);
      }
      if (from < 11) {
        // Land became a set of owned blocks. Wipe the city-builder tables and
        // recreate them (now without grid columns, plus owned_land_blocks),
        // then re-seed a fresh starting city per existing player — players (and
        // their currency) are kept; only city layout resets. Mirrors the pre-v9
        // wipe precedent, acceptable while we have no real users.
        await customStatement('DROP TABLE IF EXISTS owned_land_blocks');
        await customStatement('DROP TABLE IF EXISTS story_beat_states');
        await customStatement('DROP TABLE IF EXISTS concept_band_milestones');
        await customStatement('DROP TABLE IF EXISTS building_types_researched');
        await customStatement('DROP TABLE IF EXISTS building_placements');
        await customStatement('DROP TABLE IF EXISTS cities');
        await m.createAll();
        for (final player in await getAllPlayers()) {
          await _seedCityBuilderState(player.id);
        }
      }
      if (from < 12) {
        // Bundled content changed; the table is only a cache of the asset
        // files, so drop it and let the lazy seeder refill it.
        await customStatement('DROP TABLE IF EXISTS dataset_questions');
        await m.createTable(datasetQuestions);
      }
      if (from < 13) {
        // v13: AppSettings.datasetFingerprint — the seeder now re-seeds
        // whenever the bundled JSON changes (fingerprint mismatch), so
        // dataset fixes no longer need a schema bump to reach existing
        // installs. The old rows carry a NULL fingerprint, which never
        // matches, so the next read refreshes them automatically.
        await m.addColumn(appSettings, appSettings.datasetFingerprint);
      }
      if (from < 14) {
        // v14: single-currency coin economy (plan.md, 2026-09-08). Players
        //   columns renamed (brick → coin), the research pair dropped,
        //   streakCount added; building_types_researched dropped (a building
        //   whose unlock rule passes is now bought directly). Renaming
        //   columns means a table rebuild anyway, and we're pre-launch, so
        //   this wipes and recreates everything — the same precedent as
        //   v9/v11. AppSettings is kept (it holds the TTS toggle).
        await customStatement('DROP TABLE IF EXISTS story_beat_states');
        await customStatement('DROP TABLE IF EXISTS concept_band_milestones');
        await customStatement('DROP TABLE IF EXISTS building_types_researched');
        await customStatement('DROP TABLE IF EXISTS building_placements');
        await customStatement('DROP TABLE IF EXISTS owned_land_blocks');
        await customStatement('DROP TABLE IF EXISTS cities');
        await customStatement('DROP TABLE IF EXISTS dataset_questions');
        await customStatement('DROP TABLE IF EXISTS introduced_concepts');
        await customStatement('DROP TABLE IF EXISTS concepts');
        await customStatement('DROP TABLE IF EXISTS concept_proficiencies');
        await customStatement('DROP TABLE IF EXISTS players');
        await m.createAll();
        await _seedConceptCatalog();
      }
      if (from < 15) {
        // v15: the streak is shown as an uncapped "N in a row" count rather
        // than a 0..5 pay level, so the column is renamed to say what it
        // holds. Pure rename — values carry over.
        await m.renameColumn(players, 'streak_level', players.streakCount);
      }
      if (from < 16) {
        // v16: the construction loop (city_builder.md §8, plan.md Phase 10).
        //   Players.coinBalance dropped — there is no wallet, a coin only
        //   exists inside a ConstructionSites row (new table);
        //   BuildingPlacements.currentTier retired (upgrades are distinct
        //   placements carrying an upgradesFrom link). Dropping columns
        //   means a rebuild, and we're pre-launch, so this wipes and
        //   recreates everything — the v9/v11/v14 precedent. AppSettings is
        //   kept (it holds the TTS toggle).
        await customStatement('DROP TABLE IF EXISTS construction_sites');
        await customStatement('DROP TABLE IF EXISTS story_beat_states');
        await customStatement('DROP TABLE IF EXISTS concept_band_milestones');
        await customStatement('DROP TABLE IF EXISTS building_placements');
        await customStatement('DROP TABLE IF EXISTS owned_land_blocks');
        await customStatement('DROP TABLE IF EXISTS cities');
        await customStatement('DROP TABLE IF EXISTS dataset_questions');
        await customStatement('DROP TABLE IF EXISTS introduced_concepts');
        await customStatement('DROP TABLE IF EXISTS concepts');
        await customStatement('DROP TABLE IF EXISTS concept_proficiencies');
        await customStatement('DROP TABLE IF EXISTS players');
        await m.createAll();
        await _seedConceptCatalog();
      }
      if (from < 17) {
        // v17: credit from cancelled sites (city_builder.md §8.11). A new
        // defaulted column — additive, nothing is wiped.
        await m.addColumn(players, players.creditBalance);
      }
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

  /// True once this process has verified the seeded table matches the
  /// bundled assets — the fingerprint check costs an asset read, so it
  /// runs at most once per app session.
  bool _datasetFingerprintVerified = false;

  /// Test hook: forget that this session already verified the dataset
  /// fingerprint, so the next read re-checks it (simulates an app
  /// restart after an update shipped changed dataset JSONs).
  @visibleForTesting
  void resetDatasetFingerprintCheck() {
    _datasetFingerprintVerified = false;
  }

  Future<void> _seedDatasetQuestionsIfStale() async {
    final existing =
        await (selectOnly(datasetQuestions)
              ..addColumns([datasetQuestions.id])
              ..limit(1))
            .get();
    final hasRows = existing.isNotEmpty;
    if (hasRows && _datasetFingerprintVerified) return;

    // One pass over the asset bytes serves both the fingerprint check
    // and (only when stale) the JSON parse — loading the files twice
    // measurably slowed the first read.
    final bundle = await _loadDatasetAssetBytes();
    if (bundle == null) {
      // No asset bundle (pure-Dart unit tests) — nothing to seed from.
      return;
    }
    final fingerprint = _fingerprintOf(bundle);
    _datasetFingerprintVerified = true;
    if (hasRows) {
      final stored = (await _getOrCreateAppSettings()).datasetFingerprint;
      if (stored == fingerprint) return;
    }

    final items = _parseDatasetBytes(bundle);
    if (items.isEmpty) return;
    await delete(datasetQuestions).go();
    await batch((b) {
      b.insertAll(
        datasetQuestions,
        items.map(_datasetQuestionToCompanion).toList(),
      );
    });
    await _getOrCreateAppSettings();
    await (update(appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(datasetFingerprint: Value(fingerprint)),
    );
  }

  /// Returns every bundled dataset question grouped by concept ID. On
  /// first call each session, verifies the persisted table against the
  /// bundled `assets/data/dataset_questions/*.json` (fingerprint match)
  /// and re-seeds when the bundle changed; thereafter reads from the
  /// table directly.
  ///
  /// Lazy seeding (rather than seeding during migration) keeps `flutter
  /// test`'s `pumpAndSettle` happy: the asset-bundle platform channel
  /// doesn't dispatch inside the pump loop, so any migration-time
  /// `rootBundle.loadString` would hang. By moving the asset I/O to the
  /// first dataset query, widget tests that never touch dataset questions
  /// don't pay the cost.
  Future<Map<String, List<DatasetQuestion>>>
  allDatasetQuestionsByConcept() async {
    await _seedDatasetQuestionsIfStale();
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

    await _seedCityBuilderState(id);
    return getPlayerById(id);
  }

  /// Seeds a player's city-builder baseline: one City row tied to the
  /// beginner map (more maps unlock later and each gets its own City row),
  /// with its starting 3×3 owned land. The build catalog needs no seeding —
  /// the mayor's office has an open unlock rule, so it's buyable from turn
  /// one. Used both at player creation and by the v11 migration.
  Future<void> _seedCityBuilderState(int playerId) async {
    final cityId = await into(cities).insert(
      CitiesCompanion.insert(
        playerId: playerId,
        cityMapId: beginnerCityMap.id,
        createdAt: DateTime.now(),
      ),
    );
    await _seedStartingLand(cityId);
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

  /// Sets a player's lifetime coin counter directly (tests / debug). For
  /// per-answer payouts use [addLifetimeCoins].
  Future<void> setLifetimeCoins(int playerId, int lifetimeCoinsEarned) =>
      (update(players)..where((t) => t.id.equals(playerId))).write(
        PlayersCompanion(lifetimeCoinsEarned: Value(lifetimeCoinsEarned)),
      );

  /// Adds [by] coins to the player's lifetime counter. Call on every
  /// payout; the coins themselves go into a construction site
  /// ([setSitePaidCoins]) — there is no spending balance.
  Future<void> addLifetimeCoins(int playerId, int by) async {
    assert(by >= 0, 'lifetime coins never decrease');
    final p = await getPlayerById(playerId);
    await (update(players)..where((t) => t.id.equals(playerId))).write(
      PlayersCompanion(lifetimeCoinsEarned: Value(p.lifetimeCoinsEarned + by)),
    );
  }

  /// Moves the player's credit by [by] (negative when credit is spent into
  /// a site). Credit never goes below zero.
  Future<void> addCredit(int playerId, int by) async {
    final p = await getPlayerById(playerId);
    final next = p.creditBalance + by;
    assert(next >= 0, 'credit never goes negative');
    await (update(players)..where((t) => t.id.equals(playerId))).write(
      PlayersCompanion(creditBalance: Value(next)),
    );
  }

  /// Persists the player's consecutive-correct count (see
  /// `coin_economy.dart` `nextStreakCount`).
  Future<void> setPlayerStreakCount(int playerId, int count) =>
      (update(players)..where((t) => t.id.equals(playerId))).write(
        PlayersCompanion(streakCount: Value(count)),
      );

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

  // ---- Concept band milestones (band-crossing bonus log) ----

  /// Returns the set of band indices already paid for this
  /// (player, concept) pair. Used by the band-crossing bonus rule to filter
  /// out re-crossings after a dip.
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

  /// Seeds the starting 3×3 land (rings 0–1) for a freshly created [cityId].
  Future<void> _seedStartingLand(int cityId) async {
    await batch((b) {
      b.insertAll(ownedLandBlocks, [
        for (final (bx, by) in startingOwnedBlocks())
          OwnedLandBlocksCompanion.insert(
            cityId: cityId,
            blockX: bx,
            blockY: by,
          ),
      ]);
    });
  }

  /// The set of owned 4×4 blocks (block coords) for [cityId].
  Future<Set<(int, int)>> ownedBlocksForCity(int cityId) async {
    final rows = await (select(
      ownedLandBlocks,
    )..where((t) => t.cityId.equals(cityId))).get();
    return {for (final r in rows) (r.blockX, r.blockY)};
  }

  /// Records ownership of land block `(blockX, blockY)` for [cityId]. Land
  /// is paid for through a construction site ([openSite] calls this when a
  /// land site fills); the caller has verified the block is on the frontier.
  Future<void> addOwnedLandBlock({
    required int cityId,
    required int blockX,
    required int blockY,
  }) => into(ownedLandBlocks).insert(
    OwnedLandBlocksCompanion.insert(
      cityId: cityId,
      blockX: blockX,
      blockY: blockY,
    ),
  );

  /// Debug-only: wipes a player's city-builder state back to the
  /// just-created baseline — clears placements, construction sites, beat
  /// states, and band-milestone awards; sets population to 0; and zeroes
  /// the lifetime coin counter and the streak. Driven by the kDebugMode-only
  /// city debug sheet.
  Future<void> resetCityForPlayer(int playerId) => transaction(() async {
    final city = await cityForPlayer(playerId);
    await (delete(
      constructionSites,
    )..where((t) => t.cityId.equals(city.id))).go();
    await (delete(
      buildingPlacements,
    )..where((t) => t.cityId.equals(city.id))).go();
    await (delete(
      ownedLandBlocks,
    )..where((t) => t.cityId.equals(city.id))).go();
    await _seedStartingLand(city.id);
    await (delete(
      storyBeatStates,
    )..where((t) => t.playerId.equals(playerId))).go();
    await (delete(
      conceptBandMilestones,
    )..where((t) => t.playerId.equals(playerId))).go();
    await setCityPopulation(city.id, 0);
    await (update(players)..where((t) => t.id.equals(playerId))).write(
      const PlayersCompanion(
        lifetimeCoinsEarned: Value(0),
        creditBalance: Value(0),
        streakCount: Value(0),
      ),
    );
  });

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
  /// stamps the player's lifetime coins at this fire so coin-based spacing
  /// (`minCoinsEarnedSinceLastBeat`) can be evaluated on the next eligibility
  /// pass, and records the round it fired at ([atRound]) so the overlay can
  /// rotate the bubble off screen after a few rounds.
  Future<void> recordBeatFired(
    int playerId,
    String beatId,
    int lifetimeCoinsAtFire, [
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
        lifetimeCoinsAtLastFire: Value(lifetimeCoinsAtFire),
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

  /// Places one building: inserts the placement row. No coins change hands
  /// here — a priced building is paid for through a construction site and
  /// placed by [openSite] when the site fills; this is the free path (the
  /// mayor's office) and the site-opening primitive. The caller has already
  /// verified tile vacancy.
  ///
  /// `placedAtRound` is stamped with the player's current round clock
  /// ([Players.roundsPlayed]) so the "building age" beat trigger measures age
  /// in answered questions since placement (age = current clock − this stamp).
  /// Inserts the placement and returns its new row id (used to immediately
  /// select the just-placed building for repositioning — see plan.md Phase 9).
  Future<int> placeBuilding({
    required int cityId,
    required int playerId,
    required String buildingTypeId,
    required int gridX,
    required int gridY,
  }) async {
    final player = await getPlayerById(playerId);
    return into(buildingPlacements).insert(
      BuildingPlacementsCompanion.insert(
        cityId: cityId,
        buildingTypeId: buildingTypeId,
        gridX: gridX,
        gridY: gridY,
        placedAtRound: player.roundsPlayed,
      ),
    );
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

  // ---- Construction sites (Phase 10) ----

  /// Every open site in [cityId], oldest first.
  Future<List<ConstructionSiteRow>> sitesForCity(int cityId) =>
      (select(constructionSites)
            ..where((t) => t.cityId.equals(cityId))
            ..orderBy([(t) => OrderingTerm.asc(t.id)]))
          .get();

  Future<ConstructionSiteRow?> siteById(int siteId) => (select(
    constructionSites,
  )..where((t) => t.id.equals(siteId))).getSingleOrNull();

  /// Starts a building site at `(gridX, gridY)` — a new build, or an upgrade
  /// of [upgradesFromPlacementId]. Returns the new row id. Stamps the
  /// player's round clock; the site's price is derived from the building
  /// registry, never stored.
  Future<int> startBuildingSite({
    required int cityId,
    required int playerId,
    required String buildingTypeId,
    required int gridX,
    required int gridY,
    int? upgradesFromPlacementId,
  }) async {
    final player = await getPlayerById(playerId);
    return into(constructionSites).insert(
      ConstructionSitesCompanion.insert(
        cityId: cityId,
        goalKind: 'building',
        buildingTypeId: Value(buildingTypeId),
        gridX: Value(gridX),
        gridY: Value(gridY),
        upgradesFromPlacementId: Value(upgradesFromPlacementId),
        startedAtRound: player.roundsPlayed,
      ),
    );
  }

  /// Starts a land site for block `(blockX, blockY)`. Returns the row id.
  Future<int> startLandSite({
    required int cityId,
    required int playerId,
    required int blockX,
    required int blockY,
  }) async {
    final player = await getPlayerById(playerId);
    return into(constructionSites).insert(
      ConstructionSitesCompanion.insert(
        cityId: cityId,
        goalKind: 'land',
        blockX: Value(blockX),
        blockY: Value(blockY),
        startedAtRound: player.roundsPlayed,
      ),
    );
  }

  /// Moves a building site's anchor. Paid-in coins and the upgrade link are
  /// untouched — sites move like buildings (city_builder.md §8.5).
  Future<void> moveSite({
    required int siteId,
    required int gridX,
    required int gridY,
  }) => (update(constructionSites)..where((t) => t.id.equals(siteId))).write(
    ConstructionSitesCompanion(gridX: Value(gridX), gridY: Value(gridY)),
  );

  /// Persists a site's paid-in total. The caller computed it with the
  /// domain's `ConstructionSite.payIn`, which caps it at the price.
  Future<void> setSitePaidCoins(int siteId, int paidCoins) =>
      (update(constructionSites)..where((t) => t.id.equals(siteId))).write(
        ConstructionSitesCompanion(paidCoins: Value(paidCoins)),
      );

  /// Cancels a site: the row goes and every coin paid into it comes back to
  /// the player as credit, in full. Transactional. Returns the refund, or
  /// null if the site no longer exists.
  Future<int?> cancelSite(int siteId, {required int playerId}) =>
      transaction(() async {
        final site = await siteById(siteId);
        if (site == null) return null;
        await (delete(
          constructionSites,
        )..where((t) => t.id.equals(siteId))).go();
        if (site.paidCoins > 0) await addCredit(playerId, site.paidCoins);
        return site.paidCoins;
      });

  /// Opens a full site: a building site becomes a placement (removing the
  /// placement it upgraded, if any); a land site becomes an owned block. The
  /// site row is deleted. Transactional. Returns the new placement's id for
  /// a building site, null for land. The caller has checked the site is
  /// full — the row carries no price.
  Future<int?> openSite(int siteId, {required int playerId}) =>
      transaction(() async {
        final site = await siteById(siteId);
        if (site == null) return null;
        int? placementId;
        if (site.goalKind == 'building') {
          placementId = await placeBuilding(
            cityId: site.cityId,
            playerId: playerId,
            buildingTypeId: site.buildingTypeId!,
            gridX: site.gridX!,
            gridY: site.gridY!,
          );
          final source = site.upgradesFromPlacementId;
          if (source != null) {
            await (delete(
              buildingPlacements,
            )..where((t) => t.id.equals(source))).go();
          }
        } else {
          await addOwnedLandBlock(
            cityId: site.cityId,
            blockX: site.blockX!,
            blockY: site.blockY!,
          );
        }
        await (delete(
          constructionSites,
        )..where((t) => t.id.equals(siteId))).go();
        return placementId;
      });

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

  // ---- App-wide settings ----

  /// Reads (and lazily creates) the app-wide settings row. Returns the
  /// row with default values on first call.
  Future<AppSetting> _getOrCreateAppSettings() async {
    final existing = await (select(
      appSettings,
    )..where((t) => t.id.equals(1))).getSingleOrNull();
    if (existing != null) return existing;
    await into(appSettings).insert(
      const AppSettingsCompanion(id: Value(1)),
    );
    return (select(appSettings)..where((t) => t.id.equals(1))).getSingle();
  }

  /// Whether text-to-speech is enabled. Defaults to true on first launch.
  Future<bool> getTtsEnabled() async =>
      (await _getOrCreateAppSettings()).ttsEnabled;

  /// Persists the text-to-speech toggle state.
  Future<void> setTtsEnabled({required bool enabled}) async {
    await _getOrCreateAppSettings();
    await (update(appSettings)..where((t) => t.id.equals(1))).write(
      AppSettingsCompanion(ttsEnabled: Value(enabled)),
    );
  }

  /// Wipes a player's recorded proficiencies AND introduced-concept set,
  /// returning them to the "fresh player" state. The next read of
  /// [introducedConceptIdsForPlayer] will be empty, which causes the
  /// drip-feed to seed a new starter pack at the player's *current* grade.
  ///
  /// Coin balances (current and lifetime) and the streak are intentionally
  /// NOT touched — those represent earned currency, not curriculum state.
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
  final paths = await _datasetAssetPaths();
  if (paths == null) return const [];

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

/// Sorted asset paths of the bundled dataset JSONs, or null when the
/// asset bundle is unavailable (pure-Dart unit tests without a binding).
Future<List<String>?> _datasetAssetPaths() async {
  try {
    final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
    return manifest
        .listAssets()
        .where(
          (k) => k.startsWith(_datasetAssetPrefix) && k.endsWith('.json'),
        )
        .toList()
      ..sort();
  }
  // Intentional broad catch: AssetManifest throws different exception
  // types depending on what's missing (FlutterError for missing manifest,
  // Exception for missing binding). Both should degrade to null.
  // ignore: avoid_catches_without_on_clauses
  catch (_) {
    return null;
  }
}

/// The bundled dataset files' raw bytes, keyed by sorted asset path.
/// Null when the asset bundle is unavailable.
Future<Map<String, Uint8List>?> _loadDatasetAssetBytes() async {
  final paths = await _datasetAssetPaths();
  if (paths == null) return null;
  final out = <String, Uint8List>{};
  for (final path in paths) {
    final data = await rootBundle.load(path);
    out[path] = data.buffer.asUint8List(
      data.offsetInBytes,
      data.lengthInBytes,
    );
  }
  return out;
}

/// FNV-1a 64-bit fingerprint over the bundled dataset files (names and
/// bytes, in sorted-path order). Any content change — even same-length
/// edits — yields a different value, which is what triggers a re-seed
/// of the `dataset_questions` cache after an app update.
String _fingerprintOf(Map<String, Uint8List> bundle) {
  // Mobile-only app; the 64-bit constant is fine off the web.
  // ignore: avoid_js_rounded_ints
  var hash = 0xcbf29ce484222325; // FNV-1a 64-bit offset basis
  const prime = 0x100000001b3; // FNV prime; multiply wraps on the VM
  for (final entry in bundle.entries) {
    final path = entry.key;
    for (var i = 0; i < path.length; i++) {
      hash = (hash ^ (path.codeUnitAt(i) & 0xff)) * prime;
    }
    final bytes = entry.value;
    for (var i = 0; i < bytes.length; i++) {
      hash = (hash ^ bytes[i]) * prime;
    }
  }
  return hash.toRadixString(16);
}

List<DatasetQuestion> _parseDatasetBytes(Map<String, Uint8List> bundle) {
  final out = <DatasetQuestion>[];
  for (final bytes in bundle.values) {
    final decoded = json.decode(utf8.decode(bytes)) as Map<String, dynamic>;
    final items = decoded['items'] as List<dynamic>;
    for (final item in items) {
      out.add(DatasetQuestion.fromJson(item as Map<String, dynamic>));
    }
  }
  return out;
}

/// Fingerprint of the bundled dataset JSONs, or null when the asset
/// bundle is unavailable. Exposed for tests.
@visibleForTesting
Future<String?> bundledDatasetFingerprint() async {
  final bundle = await _loadDatasetAssetBytes();
  return bundle == null ? null : _fingerprintOf(bundle);
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
