import 'dart:math';

import 'package:math_city/domain/questions/dataset_question.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/generator_registry.dart';

/// Unified entry point that produces one [GeneratedQuestion] for a given
/// concept by drawing from either the algorithmic generator registry or
/// the bundled dataset pool, mixed by a weighted-by-pool-size policy.
///
/// **Mix policy.** For a concept that has *both* a generator and a dataset
/// pool of size `n`, the per-question probability of choosing dataset is
/// `0.5 * min(1, n / poolSaturationSize)` — pools at saturation (≥
/// [poolSaturationSize] items) get the full 50/50 mix; smaller pools are
/// down-weighted so K–G1 concepts that only have a handful of dataset
/// items (e.g. `add_within_5` with 1) don't surface the same one over and
/// over.
///
/// When only one side is available, that side serves every question. When
/// neither is available, [generate] throws (matching [GeneratorRegistry]'s
/// behaviour for unknown concepts) so callers can rely on
/// [isImplemented] for gating.
class QuestionSource {
  QuestionSource({
    required this.registry,
    required Map<String, List<DatasetQuestion>> datasetByConcept,
  }) : _datasetByConcept = Map.unmodifiable(datasetByConcept);

  /// Pool size at which the dataset share saturates at 50%. A pool of
  /// [poolSaturationSize] or more yields a 50/50 mix; a pool of `k <
  /// poolSaturationSize` yields a `0.5 * k / poolSaturationSize` dataset
  /// share.
  ///
  /// **The pool is the union across every ingested dataset for the
  /// concept** — e.g. when GSM8K and DeepMind both contribute items to
  /// `add_within_20`, the saturation check sees the combined count, not
  /// per-dataset counts. This makes the policy stable as new datasets
  /// land: more sources only reduce per-item repetition, never inflate
  /// the dataset share past 50%.
  ///
  /// Tunable as we learn from playtest data; surfaced as a constant so
  /// the policy stays inspectable.
  static const int poolSaturationSize = 50;

  final GeneratorRegistry registry;
  final Map<String, List<DatasetQuestion>> _datasetByConcept;

  /// True if [conceptId] can produce a question via either a generator,
  /// the bundled dataset pool, or both.
  bool isImplemented(String conceptId) =>
      registry.isImplemented(conceptId) ||
      _datasetByConcept.containsKey(conceptId);

  /// Union of every concept ID that has at least one playable question.
  Iterable<String> get implementedConceptIds => <String>{
    ...registry.implementedConceptIds,
    ..._datasetByConcept.keys,
  };

  /// Number of bundled dataset items available for [conceptId]; zero
  /// means dataset items will never be picked for it.
  int datasetPoolSize(String conceptId) =>
      _datasetByConcept[conceptId]?.length ?? 0;

  GeneratedQuestion generate(String conceptId, {Random? random}) {
    final rand = random ?? Random();
    final pool = _datasetByConcept[conceptId];
    final hasGen = registry.isImplemented(conceptId);

    if (pool == null || pool.isEmpty) {
      return registry.generate(conceptId, random: rand);
    }
    if (!hasGen) {
      return _datasetItemToGenerated(_pick(pool, rand));
    }

    final pDataset =
        0.5 * min(1.0, pool.length / poolSaturationSize.toDouble());
    if (rand.nextDouble() < pDataset) {
      return _datasetItemToGenerated(_pick(pool, rand));
    }
    return registry.generate(conceptId, random: rand);
  }

  DatasetQuestion _pick(List<DatasetQuestion> pool, Random rand) =>
      pool[rand.nextInt(pool.length)];

  GeneratedQuestion _datasetItemToGenerated(DatasetQuestion q) =>
      GeneratedQuestion(
        conceptId: q.conceptId,
        prompt: q.prompt,
        correctAnswer: q.correctAnswer,
        distractors: q.distractors,
        explanation: q.explanation.isEmpty
            ? ['The correct answer is ${q.correctAnswer}.']
            : q.explanation,
      );
}
