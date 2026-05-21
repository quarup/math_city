import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Drift lazy-seeds dataset_questions on first read', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final byConcept = await db.allDatasetQuestionsByConcept();

    // The 12 sub-concepts that DeepMind arithmetic.add_or_sub ingestion
    // currently fills. If the ingester adds new buckets this test will
    // flag it.
    expect(byConcept.keys.toSet(), {
      'add_within_5',
      'sub_within_5',
      'add_within_10',
      'sub_within_10',
      'add_within_20',
      'sub_within_20',
      'add_within_100',
      'sub_within_100',
      'add_within_1000',
      'sub_within_1000',
      'add_2digit_carry',
      'sub_2digit_borrow',
    });

    // Each bucket has at least one item, and items round-trip cleanly
    // (distractors and explanation come back as List<String>).
    for (final entry in byConcept.entries) {
      expect(entry.value, isNotEmpty, reason: '${entry.key} bucket is empty');
      final first = entry.value.first;
      expect(first.conceptId, entry.key);
      expect(first.distractors, hasLength(3));
      expect(first.explanation, isNotEmpty);
      expect(first.source, 'deepmind_mathematics_dataset');
    }
  });

  test(
    'loadBundledDatasetQuestions: binding-present path loads items',
    () async {
      // Sanity: when AssetManifest is unavailable (the default for pure-Dart
      // tests that don't init TestWidgetsFlutterBinding), the helper degrades
      // to an empty list rather than throwing — keeping NativeDatabase-only
      // unit tests from crashing on migration.
      //
      // This test ALSO has the binding, so to simulate the missing case we
      // just rely on the contract being documented; the regression that
      // matters in practice is exercised by every other test file under
      // test/state/ which constructs AppDatabase without the binding.
      final items = await loadBundledDatasetQuestions();
      expect(items, isNotEmpty); // binding present here → real items load
    },
  );
}
