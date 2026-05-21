import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Drift lazy-seeds dataset_questions on first read', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final byConcept = await db.allDatasetQuestionsByConcept();

    // The sub-concepts currently filled by bundled ingestion. If an
    // ingester adds or removes a bucket this test will flag it.
    //
    // 12 from DeepMind `arithmetic.add_or_sub` (Chunk 80) + 4 from GSM8K
    // (Chunk 86).
    const deepMindBuckets = {
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
    };
    const gsm8kBuckets = {
      'mult_div_word_2step',
      'mult_compare_word',
      'add_sub_2step_word_problems',
      'fraction_word_problems',
    };
    expect(byConcept.keys.toSet(), {...deepMindBuckets, ...gsm8kBuckets});

    // Each bucket has at least one item, and items round-trip cleanly
    // (distractors and explanation come back as List<String>). The
    // `source` field is scoped per bucket since DeepMind and GSM8K both
    // populate the table.
    for (final entry in byConcept.entries) {
      expect(entry.value, isNotEmpty, reason: '${entry.key} bucket is empty');
      final first = entry.value.first;
      expect(first.conceptId, entry.key);
      expect(first.distractors, hasLength(3));
      expect(first.explanation, isNotEmpty);
      final expectedSource = deepMindBuckets.contains(entry.key)
          ? 'deepmind_mathematics_dataset'
          : 'gsm8k';
      expect(
        first.source,
        expectedSource,
        reason: 'wrong source in ${entry.key}',
      );
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
