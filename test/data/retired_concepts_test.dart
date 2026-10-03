import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';

/// A saved row for a concept the catalog no longer has (e.g. the US coin
/// concepts retired 2026-10-03) stays on disk but never reaches the app.
void main() {
  setUp(() => driftRuntimeOptions.dontWarnAboutMultipleDatabases = true);

  test('reads skip progress on retired concept IDs', () async {
    final db = AppDatabase(NativeDatabase.memory());
    final player = await db.createPlayer(
      name: 'Alex',
      gradeLevel: 2,
      avatarConfigJson: '{}',
    );
    for (final id in ['count_coins', 'add_within_10']) {
      await db.introduceConcept(player.id, id);
      await db.upsertProficiency(player.id, id, 0.8, correct: true);
    }

    expect(await db.introducedConceptIdsForPlayer(player.id), {
      'add_within_10',
    });
    expect((await db.proficiencyMapForPlayer(player.id)).keys, [
      'add_within_10',
    ]);
    expect((await db.correctAnswerCountsForPlayer(player.id)).keys, [
      'add_within_10',
    ]);
    // Still saved, in case the ID ever comes back.
    expect(await db.select(db.conceptProficiencies).get(), hasLength(2));
    await db.close();
  });
}
