import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:math_city/domain/concepts/dag_engine.dart';
import 'package:math_city/domain/questions/generator_registry.dart';
import 'package:math_city/domain/questions/question_source.dart';
import 'package:math_city/state/player_provider.dart';

/// Singleton generator registry. Plain provider (override in tests if
/// you want a different generator set).
final generatorRegistryProvider = Provider<GeneratorRegistry>(
  (_) => GeneratorRegistry.defaultRegistry(),
);

/// Drip-feed engine instance bound to the active generator registry.
final dagEngineProvider = Provider<DripFeedEngine>(
  (ref) => DripFeedEngine(registry: ref.watch(generatorRegistryProvider)),
);

/// Unified question source: mixes generator-produced items with bundled
/// dataset items per the [QuestionSource] mix policy.
///
/// Async because the dataset pool is read from Drift on first access (the
/// table is itself populated from bundled JSON during the database's
/// onCreate/onUpgrade flow). After the first resolution the result is
/// cached for the lifetime of the provider container.
final questionSourceProvider = FutureProvider<QuestionSource>((ref) async {
  final registry = ref.watch(generatorRegistryProvider);
  final db = ref.watch(appDatabaseProvider);
  final datasetByConcept = await db.allDatasetQuestionsByConcept();
  return QuestionSource(
    registry: registry,
    datasetByConcept: datasetByConcept,
  );
});

/// Set of concept IDs the active player has been *introduced* to (the
/// drip-feed has surfaced them onto the wheel).
///
/// Lazily populates a 2-concept starter pack the first time it's read for
/// a player whose introduced set is empty.
class IntroducedConceptsNotifier extends AsyncNotifier<Set<String>> {
  @override
  Future<Set<String>> build() async {
    final player = await ref.watch(activePlayerProvider.future);
    final db = ref.watch(appDatabaseProvider);
    final engine = ref.watch(dagEngineProvider);

    var introduced = await db.introducedConceptIdsForPlayer(player.id);
    if (introduced.isEmpty) {
      // Starter pack: 2 easiest implemented concepts at-or-below grade.
      final starterPack = engine.pickStarterPack(player.gradeLevel);
      for (final c in starterPack) {
        await db.introduceConcept(player.id, c.id);
      }
      introduced = starterPack.map((c) => c.id).toSet();
    }
    return introduced;
  }

  /// Adds [conceptId] to the introduced set (drip-feed unlock). Persists
  /// to DB and updates in-memory state synchronously.
  Future<void> introduce(String conceptId) async {
    final player = await ref.read(activePlayerProvider.future);
    final db = ref.read(appDatabaseProvider);
    await db.introduceConcept(player.id, conceptId);
    final current = state.asData?.value ?? const <String>{};
    state = AsyncData({...current, conceptId});
  }
}

final introducedConceptsProvider =
    AsyncNotifierProvider<IntroducedConceptsNotifier, Set<String>>(
      IntroducedConceptsNotifier.new,
    );
