import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:math_city/domain/concepts/concept.dart';
import 'package:math_city/domain/concepts/dag_engine.dart';
import 'package:math_city/domain/questions/generated_question.dart';
import 'package:math_city/domain/questions/generator_registry.dart';

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
      _c(id: 'add_5', grade: 0, category: 'add_sub'),
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

    test('starter pack: 4 easiest implemented at the frontier', () {
      final reg = _registryFor(['add_5', 'sub_5', 'add_10', 'add_20']);
      final engine = DripFeedEngine(registry: reg, catalog: synthetic);
      // Grade-1 player: G0 concepts sit 1 below (comfortable), G1 is at-grade
      // (challenging). All four are at the frontier; result sorted by
      // (grade ascending, then categoryRowOrder ascending).
      // synthetic rows: add_5=0, sub_5=1, add_10=2, add_20=7
      final pack = engine.pickStarterPack(1);
      expect(
        pack.map((c) => c.id).toList(),
        ['add_5', 'sub_5', 'add_10', 'add_20'],
      );
    });

    test('starter pack excludes content well below player grade', () {
      // frac_a_b (G3) is registered so the implemented ceiling is G3 and
      // effectiveGradeFor(2) is a no-op (2 < 3 → 2).
      final reg = _registryFor([
        'add_5',
        'sub_5',
        'add_10',
        'add_20',
        'frac_a_b',
      ]);
      final engine = DripFeedEngine(registry: reg, catalog: synthetic);
      // Grade-2 player: G0 concepts (add_5, sub_5, add_10) sit ≥2 below →
      // initial p=0.95, mastered, off the wheel. frac_a_b (G3) is above
      // grade → notYet, off the wheel. Only add_20 (G1, one below) remains
      // at the frontier.
      final pack = engine.pickStarterPack(2);
      expect(pack.map((c) => c.id).toList(), ['add_20']);
    });

    test('starter pack respects player grade', () {
      final reg = _registryFor([
        'add_5',
        'sub_5',
        'frac_a_b',
        'mult_facts',
      ]);
      final engine = DripFeedEngine(registry: reg, catalog: synthetic);
      // Grade 0 player: only G0 implemented concepts are eligible. G3
      // concepts are above-grade (notYet, off wheel).
      final pack = engine.pickStarterPack(0);
      expect(pack.map((c) => c.id).toList(), ['add_5', 'sub_5']);
    });

    test(
      'starter pack falls back to easiest at-or-below grade when nothing '
      'in-band is implemented',
      () {
        // Grade-2 player would normally need G1 or G2 frontier concepts.
        // Only add_5 (G0, ≥2 below = mastered) is implemented here, so
        // the in-band filter yields nothing and the fallback kicks in.
        final reg = _registryFor(['add_5']);
        final engine = DripFeedEngine(registry: reg, catalog: synthetic);
        final pack = engine.pickStarterPack(2);
        expect(pack.map((c) => c.id), ['add_5']);
      },
    );

    test('pickNext returns null when nothing is eligible', () {
      final reg = _registryFor([]);
      final engine = DripFeedEngine(registry: reg, catalog: synthetic);
      final next = engine.pickNext(
        introduced: const {},
        profMap: const {},
        playerGrade: 0,
      );
      expect(next, isNull);
    });

    test('pickNext gates by mastered prereqs', () {
      final reg = _registryFor(['add_5', 'add_10']);
      final engine = DripFeedEngine(registry: reg, catalog: synthetic);
      // add_5 is introduced but not mastered → add_10 should NOT be eligible.
      final next = engine.pickNext(
        introduced: {'add_5'},
        profMap: const {'add_5': 0.5},
        playerGrade: 0,
      );
      expect(next, isNull);
    });

    test('pickNext returns child once prereq is mastered', () {
      final reg = _registryFor(['add_5', 'add_10']);
      final engine = DripFeedEngine(registry: reg, catalog: synthetic);
      final next = engine.pickNext(
        introduced: {'add_5'},
        profMap: const {'add_5': 0.9},
        playerGrade: 0,
      );
      expect(next?.id, 'add_10');
    });

    test(
      'pickNext auto-satisfies prereqs that are well below the player grade',
      () {
        // High-grade player should not have to manually master grade-K
        // concepts before grade-1 ones unlock. add_10 has prereq add_5;
        // for a grade-2 player, add_5 starts at p=0.95 (mastered) via
        // initialProficiency, so add_10's prereq is satisfied without any
        // recorded proficiency for add_5.
        //
        // frac_a_b (G3) is registered so the implemented ceiling is G3 and
        // effectiveGradeFor(2) is a no-op.
        final reg = _registryFor(['add_10', 'frac_a_b']);
        final engine = DripFeedEngine(registry: reg, catalog: synthetic);
        final next = engine.pickNext(
          introduced: const {},
          profMap: const {},
          playerGrade: 2,
        );
        // Both add_10 and frac_a_b are eligible (no prereqs / mastered
        // prereqs). Lowest-grade wins: add_10 (G0) over frac_a_b (G3).
        expect(next?.id, 'add_10');
      },
    );

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
          playerGrade: 0,
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
        playerGrade: 0,
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
        playerGrade: 0,
      );
      expect(next, isNull);
    });
  });

  group('DripFeedEngine — real catalog', () {
    test(
      'starter pack on the real catalog gives 4 K-grade add_sub roots',
      () {
        final engine = DripFeedEngine(
          registry: GeneratorRegistry.defaultRegistry(),
        );
        final pack = engine.pickStarterPack(0);
        expect(pack, hasLength(4));
        // First four by (grade, row order) at K-grade are
        // add_within_5 (row 0), sub_within_5 (row 1),
        // add_within_10 (row 2), sub_within_10 (row 3).
        expect(
          pack.map((c) => c.id).toList(),
          ['add_within_5', 'sub_within_5', 'add_within_10', 'sub_within_10'],
        );
      },
    );

    test(
      'high-grade player on partial catalog sees frontier content, not K',
      () {
        // The implemented catalog currently tops out at G4. A grade-8
        // player should see G3/G4 frontier content (the closest implemented
        // material to their stated grade), NOT K-level add/sub.
        final engine = DripFeedEngine(
          registry: GeneratorRegistry.defaultRegistry(),
        );
        final pack = engine.pickStarterPack(8);
        expect(pack, isNotEmpty);
        // No K-grade or grade-1 concepts should appear.
        for (final c in pack) {
          expect(
            c.primaryGrade,
            greaterThanOrEqualTo(3),
            reason:
                'grade-8 player should never see G0–G2 in the starter pack '
                'when the catalog has G3+ implemented; '
                'got ${c.id} (G${c.primaryGrade})',
          );
        }
      },
    );

    test('effectiveGradeFor clamps stated grade to catalog ceiling', () {
      final engine = DripFeedEngine(
        registry: GeneratorRegistry.defaultRegistry(),
      );
      // The implemented ceiling is currently G8 (solve_linear_eq_one_solution
      // landed in the equations chunk). Clamping is min(stated, ceiling).
      // G9+ should still clamp down to 8.
      expect(engine.effectiveGradeFor(9), 8);
      expect(engine.effectiveGradeFor(8), 8);
      expect(engine.effectiveGradeFor(4), 4);
      expect(engine.effectiveGradeFor(2), 2);
      expect(engine.effectiveGradeFor(0), 0);
    });

    test(
      'mastery of add_within_5 unlocks add_within_10 next on real catalog',
      () {
        final engine = DripFeedEngine(
          registry: GeneratorRegistry.defaultRegistry(),
        );
        final next = engine.pickNext(
          introduced: {'add_within_5', 'sub_within_5'},
          profMap: const {'add_within_5': 0.9, 'sub_within_5': 0.4},
          playerGrade: 0,
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
          playerGrade: 0,
        ),
      );
      expect(results.map((c) => c?.id).toSet(), hasLength(1));
    });
  });
}

final _extraStatsCatalog = <Concept>[
  _c(id: 'stats_root', grade: 0, category: 'stats'),
];

// Reference to suppress unused-import warning when we add randomness later.
// ignore: unused_element
final _seed = Random(0);
