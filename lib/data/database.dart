import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:math_city/domain/avatar/adventurer_config.dart';
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
  IntColumn get currentStars => integer().withDefault(const Constant(0))();
  IntColumn get lifetimeStarsEarned =>
      integer().withDefault(const Constant(0))();
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

  @override
  Set<Column<Object>> get primaryKey => {id};
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
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 5;

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
      // Wipe is acceptable while we have no real users; proper additive
      // migrations land in Phase 11. See plan.md.
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

  Future<void> updatePlayerStars(
    int playerId, {
    required int currentStars,
    required int lifetimeStarsEarned,
  }) => (update(players)..where((t) => t.id.equals(playerId))).write(
    PlayersCompanion(
      currentStars: Value(currentStars),
      lifetimeStarsEarned: Value(lifetimeStarsEarned),
    ),
  );

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
  /// Stars (current and lifetime) are intentionally NOT touched — those
  /// represent earned currency, not curriculum state.
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
