import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_dash/domain/concepts/concept.dart';
import 'package:math_dash/domain/concepts/concept_registry.dart' as catalog;
import 'package:math_dash/domain/concepts/dag_engine.dart';
import 'package:math_dash/domain/questions/generated_question.dart';
import 'package:math_dash/domain/questions/generator_registry.dart';

GeneratedQuestion _stub(String id) => GeneratedQuestion(
  conceptId: id,
  prompt: 'stub',
  correctAnswer: '0',
  distractors: const ['1', '2', '3'],
  explanation: const ['stub'],
);

GeneratorRegistry _registryFor(Iterable<String> ids) =>
    GeneratorRegistry.fromMap({for (final id in ids) id: (_) => _stub(id)});

Concept _c({
  required String id,
  required int grade,
  required String category,
  List<String> prereqs = const [],
  int row = 0,
}) => Concept(
  id: id,
  name: id,
  shortLabel: id,
  categoryId: category,
  primaryGrade: grade,
  prereqIds: prereqs,
  source: ConceptSource.algorithmic,
  diagramRequirement: const DiagramNone(),
  categoryRowOrder: row,
);

void main() {
  group('DripFeedEngine — synthetic catalog', () {
    final synthetic = <Concept>[
      _c(id: 'add_5', grade: 0, category: 'add_sub', row: 0),
      _c(
        id: 'add_10',
        grade: 0,
        category: 'add_sub',
        prereqs: ['add_5'],
        row: 2,
      ),
      _c(
        id: 'add_20',
        grade: 1,
        category: 'add_sub',
        prereqs: ['add_10'],
        row: 7,
      ),
      _c(id: 'sub_5', grade: 0, category: 'add_sub', row: 1),
      _c(id: 'frac_a_b', grade: 3, category: 'fractions', row: 3),
      _c(id: 'mult_facts', grade: 3, category: 'mult_div', row: 3),
    ];

    test('starter pack picks 2 easiest implemented K-grade roots', () {
      final reg = _registryFor(['add_5', 'sub_5']);
      final engine = DripFeedEngine(registry: reg, catalog: synthetic);
      final pack = engine.pickStarterPack(0);
      final ids = pack.map((c) => c.id).toList();
      // (grade ascending, then categoryRowOrder ascending)
      expect(ids, ['add_5', 'sub_5']);
    });

    test('starter pack respects player grade', () {
      final reg = _registryFor([
        'add_5',
        'sub_5',
        'frac_a_b',
        'mult_facts',
      ]);
      final engine = DripFeedEngine(registry: reg, catalog: synthetic);
      // Grade 0 player: only K-grade roots eligible.
      final pack = engine.pickStarterPack(0);
      expect(pack.map((c) => c.id).toList(), ['add_5', 'sub_5']);
    });

    test('starter pack only includes implemented concepts', () {
      // Simulate that sub_5 has no generator yet.
      final reg = _registryFor(['add_5']);
      final engine = DripFeedEngine(registry: reg, catalog: synthetic);
      final pack = engine.pickStarterPack(2);
      expect(pack.map((c) => c.id), contains('add_5'));
      expect(pack.map((c) => c.id), isNot(contains('sub_5')));
    });

    test('pickNext returns null when nothing is eligible', () {
      final reg = _registryFor([]);
      final engine = DripFeedEngine(registry: reg, catalog: synthetic);
      final next = engine.pickNext(introduced: const {}, profMap: const {});
      expect(next, isNull);
    });

    test('pickNext gates by mastered prereqs', () {
      final reg = _registryFor(['add_5', 'add_10']);
      final engine = DripFeedEngine(registry: reg, catalog: synthetic);
      // add_5 is introduced but not mastered → add_10 should NOT be eligible.
      final next = engine.pickNext(
        introduced: {'add_5'},
        profMap: const {'add_5': 0.5},
      );
      expect(next, isNull);
    });

    test('pickNext returns child once prereq is mastered', () {
      final reg = _registryFor(['add_5', 'add_10']);
      final engine = DripFeedEngine(registry: reg, catalog: synthetic);
      final next = engine.pickNext(
        introduced: {'add_5'},
        profMap: const {'add_5': 0.9},
      );
      expect(next?.id, 'add_10');
    });

    test(
      'pickNext prefers a category with fewer active concepts (tiebreak)',
      () {
        // Both eligible at grade 0: sub_5 (add_sub) and a synthetic stats node.
        final extra = [..._extraStatsCatalog, ...synthetic];
        final reg = _registryFor(['stats_root', 'sub_5']);
        final engine = DripFeedEngine(registry: reg, catalog: extra);
        // Player has add_sub already active (introduced add_5, not mastered)
        // and zero in stats. The engine should prefer stats_root.
        final next = engine.pickNext(
          introduced: {'add_5'},
          profMap: const {'add_5': 0.4},
        );
        expect(next?.id, 'stats_root');
      },
    );

    test('pickNext skips already-introduced concepts', () {
      final reg = _registryFor(['add_5', 'sub_5']);
      final engine = DripFeedEngine(registry: reg, catalog: synthetic);
      final next = engine.pickNext(
        introduced: {'add_5'},
        profMap: const {'add_5': 0.95},
      );
      expect(next?.id, 'sub_5'); // add_5 is already in
    });

    test('pickNext skips concepts without registered generators', () {
      // No generators at all → nothing implemented.
      final reg = _registryFor([]);
      final engine = DripFeedEngine(registry: reg, catalog: synthetic);
      final next = engine.pickNext(
        introduced: const {},
        profMap: const {},
      );
      expect(next, isNull);
    });
  });

  group('DripFeedEngine — real catalog', () {
    test(
      'starter pack on the real catalog gives 2 implemented add_sub roots',
      () {
        final engine = DripFeedEngine(
          registry: GeneratorRegistry.defaultRegistry(),
        );
        final pack = engine.pickStarterPack(0);
        expect(pack, hasLength(2));
        // First two by (grade, row order) at K-grade are add_within_5 (row 0)
        // and sub_within_5 (row 1).
        expect(
          pack.map((c) => c.id).toList(),
          ['add_within_5', 'sub_within_5'],
        );
      },
    );

    test(
      'mastery of add_within_5 unlocks add_within_10 next on real catalog',
      () {
        final engine = DripFeedEngine(
          registry: GeneratorRegistry.defaultRegistry(),
        );
        final next = engine.pickNext(
          introduced: {'add_within_5', 'sub_within_5'},
          profMap: const {'add_within_5': 0.9, 'sub_within_5': 0.4},
        );
        // sub_within_5 isn't mastered, so its child sub_within_10 isn't
        // eligible. add_within_5 is mastered, so add_within_10 (its child)
        // should be the pick.
        expect(next?.id, 'add_within_10');
      },
    );

    // Sanity: deterministic given same input.
    test('pickNext is deterministic', () {
      final engine = DripFeedEngine(
        registry: GeneratorRegistry.defaultRegistry(),
      );
      final results = List.generate(
        5,
        (_) => engine.pickNext(
          introduced: {'add_within_5', 'sub_within_5'},
          profMap: const {'add_within_5': 0.9},
        ),
      );
      expect(results.map((c) => c?.id).toSet(), hasLength(1));
    });
  });
}

final _extraStatsCatalog = <Concept>[
  _c(id: 'stats_root', grade: 0, category: 'stats', row: 0),
];

// Reference to suppress unused-import warning when we add randomness later.
// ignore: unused_element
final _seed = Random(0);
