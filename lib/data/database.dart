import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:math_dash/domain/avatar/avatar_config.dart';
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
  IntColumn get totalStars => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  // Stored as JSON string; null = default avatar.
  TextColumn get avatarConfig => text().nullable()();
}

extension PlayerAvatarExt on Player {
  AvatarConfig get avatar => avatarConfig != null
      ? AvatarConfig.fromJsonString(avatarConfig!)
      : const AvatarConfig();
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

// ---------------------------------------------------------------------------
// Database class
// ---------------------------------------------------------------------------

@DriftDatabase(tables: [Players, ConceptProficiencies])
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(players, players.avatarConfig);
      }
    },
  );

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
      gradeLevel:
          gradeLevel != null ? Value(gradeLevel) : const Value.absent(),
      avatarConfig: avatarConfigJson != null
          ? Value(avatarConfigJson)
          : const Value.absent(),
    ),
  );

  Future<void> updatePlayerStars(int playerId, int totalStars) =>
      (update(players)..where((t) => t.id.equals(playerId))).write(
        PlayersCompanion(totalStars: Value(totalStars)),
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
}

// ---------------------------------------------------------------------------
// Factory — opens the SQLite file in the app's documents directory.
// ---------------------------------------------------------------------------

AppDatabase openAppDatabase() => AppDatabase(
  LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'math_dash.sqlite'));
    return NativeDatabase.createInBackground(file);
  }),
);
