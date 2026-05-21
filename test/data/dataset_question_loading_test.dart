import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/data/database.dart';
import 'package:math_city/domain/questions/generated_question.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Drift lazy-seeds dataset_questions on first read', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    final byConcept = await db.allDatasetQuestionsByConcept();

    // The sub-concepts currently filled by bundled ingestion. If an
    // ingester adds or removes a bucket this test will flag it.
    //
    // DeepMind: 12 from `arithmetic.add_or_sub` (Chunk 80) + 5 from
    // `arithmetic.mul` (Chunk 88) + 3 from `numbers.place_value` (Chunk
    // 88) + 4 from `numbers.round_number` (Chunk 88) + 1 from
    // `measurement.time` (Chunk 88) + 4 gap-fill buckets from
    // `comparison.{closest, kth_biggest, sort}` + `polynomials.evaluate`
    // (this chunk) = 29 buckets.
    // GSM8K: 4 buckets (Chunk 86).
    const deepMindBuckets = {
      // arithmetic.add_or_sub (Chunk 80)
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
      // arithmetic.mul (Chunk 88)
      'mult_facts_within_100',
      'mult_1digit_by_multiple_of_10',
      'mult_4digit_by_1digit',
      'mult_2digit_by_2digit',
      'mult_multidigit_standard_alg',
      // numbers.place_value (Chunk 88)
      'place_value_2digit',
      'place_value_3digit',
      'place_value_multidigit',
      // numbers.round_number (Chunk 88)
      'round_to_10',
      'round_to_100',
      'round_multidigit_any_place',
      'round_decimals',
      // measurement.time (Chunk 88)
      'elapsed_time',
      // Gap-fills (this chunk)
      'closest_to_target',
      'kth_value_in_list',
      'sort_rationals',
      'function_evaluate_at_point',
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

  test('sort_rationals items round-trip with AnswerFormat.commaList',
      () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final byConcept = await db.allDatasetQuestionsByConcept();
    final sortItems = byConcept['sort_rationals'];
    expect(sortItems, isNotNull);
    expect(sortItems, isNotEmpty);
    for (final item in sortItems!) {
      expect(item.answerFormat, AnswerFormat.commaList);
      // Sort answers are comma-separated, length ≥ 3 (we drop 2-value
      // sorts at ingest as they overlap with compare_pair).
      expect(item.correctAnswer.split(',').length, greaterThanOrEqualTo(3));
    }
  });

  test('integer-default dataset items keep AnswerFormat.integer', () async {
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);
    final byConcept = await db.allDatasetQuestionsByConcept();
    final addItems = byConcept['add_within_100'];
    expect(addItems, isNotNull);
    expect(addItems!.first.answerFormat, AnswerFormat.integer);
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
