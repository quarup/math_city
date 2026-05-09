// Catalog of sub-concepts mirrored from `curriculum.md` §3.x tables.
//
// Phase 5 ships a curated subset (~22 implemented + select prereq/sibling
// concepts that anchor the DAG drip-feed). The full ~361-row K–8 catalog
// will be filled in during Phase 6 — see plan.md.
//
// `categoryRowOrder` reflects the row position in `curriculum.md` for the
// concept's category and is the within-category difficulty tiebreaker for
// the drip-feed engine. Gaps in the numbering (skipped concepts) are
// intentional and harmless — only the relative order matters.

import 'package:math_city/domain/concepts/concept.dart';

const List<Concept> allConcepts = [
  // ----------------------------------------------------------------------
  // Addition & Subtraction (`add_sub`) — curriculum.md §3.3
  // ----------------------------------------------------------------------
  Concept(
    id: 'add_within_5',
    name: 'Add within 5',
    shortLabel: '+ to 5',
    categoryId: 'add_sub',
    primaryGrade: 0,
    prereqIds: [],
    source: ConceptSource.algorithmic,
    diagramRequirement: DiagramOptional(),
    categoryRowOrder: 0,
  ),
  Concept(
    id: 'sub_within_5',
    name: 'Subtract within 5',
    shortLabel: '− from 5',
    categoryId: 'add_sub',
    primaryGrade: 0,
    prereqIds: ['add_within_5'],
    source: ConceptSource.algorithmic,
    diagramRequirement: DiagramOptional(),
    categoryRowOrder: 1,
  ),
  Concept(
    id: 'add_within_10',
    name: 'Add within 10',
    shortLabel: '+ to 10',
    categoryId: 'add_sub',
    primaryGrade: 0,
    prereqIds: ['add_within_5'],
    source: ConceptSource.algorithmic,
    diagramRequirement: DiagramOptional(),
    categoryRowOrder: 2,
  ),
  Concept(
    id: 'sub_within_10',
    name: 'Subtract within 10',
    shortLabel: '− from 10',
    categoryId: 'add_sub',
    primaryGrade: 0,
    prereqIds: ['sub_within_5', 'add_within_10'],
    source: ConceptSource.algorithmic,
    diagramRequirement: DiagramOptional(),
    categoryRowOrder: 3,
  ),
  Concept(
    id: 'add_within_20',
    name: 'Add within 20',
    shortLabel: '+ to 20',
    categoryId: 'add_sub',
    primaryGrade: 1,
    prereqIds: ['add_within_10'],
    source: ConceptSource.algorithmic,
    diagramRequirement: DiagramNone(),
    categoryRowOrder: 7,
  ),
  Concept(
    id: 'sub_within_20',
    name: 'Subtract within 20',
    shortLabel: '− from 20',
    categoryId: 'add_sub',
    primaryGrade: 1,
    prereqIds: ['sub_within_10'],
    source: ConceptSource.algorithmic,
    diagramRequirement: DiagramNone(),
    categoryRowOrder: 8,
  ),
  Concept(
    id: 'add_within_100',
    name: 'Add within 100',
    shortLabel: '+ to 100',
    categoryId: 'add_sub',
    primaryGrade: 2,
    prereqIds: ['add_within_20'],
    source: ConceptSource.algorithmic,
    diagramRequirement: DiagramNone(),
    categoryRowOrder: 16,
  ),
  Concept(
    id: 'sub_within_100',
    name: 'Subtract within 100',
    shortLabel: '− from 100',
    categoryId: 'add_sub',
    primaryGrade: 2,
    prereqIds: ['sub_within_20'],
    source: ConceptSource.algorithmic,
    diagramRequirement: DiagramNone(),
    categoryRowOrder: 17,
  ),
  Concept(
    id: 'add_2digit_carry',
    name: '2-digit + with regrouping',
    shortLabel: '+ 2d carry',
    categoryId: 'add_sub',
    primaryGrade: 2,
    prereqIds: ['add_within_100'],
    source: ConceptSource.algorithmic,
    diagramRequirement: DiagramNone(),
    categoryRowOrder: 18,
  ),
  Concept(
    id: 'sub_2digit_borrow',
    name: '2-digit − with regrouping',
    shortLabel: '− 2d borrow',
    categoryId: 'add_sub',
    primaryGrade: 2,
    prereqIds: ['sub_within_100'],
    source: ConceptSource.algorithmic,
    diagramRequirement: DiagramNone(),
    categoryRowOrder: 19,
  ),
  Concept(
    id: 'add_within_1000',
    name: 'Add within 1000',
    shortLabel: '+ to 1000',
    categoryId: 'add_sub',
    primaryGrade: 2,
    prereqIds: ['add_2digit_carry'],
    source: ConceptSource.algorithmic,
    diagramRequirement: DiagramNone(),
    categoryRowOrder: 21,
  ),
  Concept(
    id: 'sub_within_1000',
    name: 'Subtract within 1000',
    shortLabel: '− from 1000',
    categoryId: 'add_sub',
    primaryGrade: 2,
    prereqIds: ['sub_2digit_borrow'],
    source: ConceptSource.algorithmic,
    diagramRequirement: DiagramNone(),
    categoryRowOrder: 22,
  ),
  Concept(
    id: 'add_multidigit_standard_alg',
    name: 'Multi-digit addition',
    shortLabel: '+ multi',
    categoryId: 'add_sub',
    primaryGrade: 4,
    prereqIds: ['add_within_1000'],
    source: ConceptSource.algorithmic,
    diagramRequirement: DiagramNone(),
    categoryRowOrder: 26,
  ),
  Concept(
    id: 'sub_multidigit_standard_alg',
    name: 'Multi-digit subtraction',
    shortLabel: '− multi',
    categoryId: 'add_sub',
    primaryGrade: 4,
    prereqIds: ['sub_within_1000'],
    source: ConceptSource.algorithmic,
    diagramRequirement: DiagramNone(),
    categoryRowOrder: 27,
  ),

  // ----------------------------------------------------------------------
  // Multiplication & Division (`mult_div`) — curriculum.md §3.4
  // (Curriculum prereqs reference equal_groups_intro / skip_count_*; those
  // are not in the Phase 5 subset, so we link directly to add_within_100
  // as a stand-in. Will be tightened in Phase 6.)
  // ----------------------------------------------------------------------
  Concept(
    id: 'mult_facts_within_100',
    name: 'Multiplication facts to 100',
    shortLabel: '× facts',
    categoryId: 'mult_div',
    primaryGrade: 3,
    prereqIds: ['add_within_100'],
    source: ConceptSource.algorithmic,
    diagramRequirement: DiagramNone(),
    categoryRowOrder: 3,
  ),
  Concept(
    id: 'div_facts_within_100',
    name: 'Division facts to 100',
    shortLabel: '÷ facts',
    categoryId: 'mult_div',
    primaryGrade: 3,
    prereqIds: ['mult_facts_within_100'],
    source: ConceptSource.algorithmic,
    diagramRequirement: DiagramNone(),
    categoryRowOrder: 15,
  ),

  // ----------------------------------------------------------------------
  // Fractions (`fractions`) — curriculum.md §3.5
  // (Same simplification: skip partition_* and unit_fraction_intro for now.)
  // ----------------------------------------------------------------------
  Concept(
    id: 'fraction_a_over_b',
    name: 'What is a/b?',
    shortLabel: 'a/b',
    categoryId: 'fractions',
    primaryGrade: 3,
    prereqIds: [],
    source: ConceptSource.algorithmicWithDiagram,
    diagramRequirement: DiagramRequired('fraction_bar'),
    categoryRowOrder: 3,
  ),
  Concept(
    id: 'compare_fractions_same_denom',
    name: 'Compare fractions (same bottom)',
    shortLabel: 'cmp frac',
    categoryId: 'fractions',
    primaryGrade: 3,
    prereqIds: ['fraction_a_over_b'],
    source: ConceptSource.algorithmic,
    diagramRequirement: DiagramOptional(),
    categoryRowOrder: 7,
  ),
  Concept(
    id: 'equivalent_fractions_visual',
    name: 'Equivalent fractions',
    shortLabel: 'equiv frac',
    categoryId: 'fractions',
    primaryGrade: 3,
    prereqIds: ['fraction_a_over_b'],
    source: ConceptSource.algorithmicWithDiagram,
    diagramRequirement: DiagramRequired('fraction_bar'),
    categoryRowOrder: 5,
  ),
  Concept(
    id: 'add_fractions_like_denom',
    name: 'Add fractions (same bottom)',
    shortLabel: '+ frac',
    categoryId: 'fractions',
    primaryGrade: 4,
    prereqIds: ['fraction_a_over_b', 'add_within_20'],
    source: ConceptSource.algorithmic,
    diagramRequirement: DiagramOptional(),
    categoryRowOrder: 14,
  ),

  // ----------------------------------------------------------------------
  // Measurement, Time & Money (`measurement`) — curriculum.md §3.8
  // (skip_count_5 prereq dropped for time_to_5_min; will be tightened.)
  // ----------------------------------------------------------------------
  Concept(
    id: 'time_to_hour_half',
    name: 'Tell time to the half-hour',
    shortLabel: 'clock ½h',
    categoryId: 'measurement',
    primaryGrade: 1,
    prereqIds: [],
    source: ConceptSource.algorithmicWithDiagram,
    diagramRequirement: DiagramRequired('clock_analog'),
    categoryRowOrder: 10,
  ),
  Concept(
    id: 'time_to_5_min',
    name: 'Tell time to 5 minutes',
    shortLabel: 'clock 5m',
    categoryId: 'measurement',
    primaryGrade: 2,
    prereqIds: ['time_to_hour_half'],
    source: ConceptSource.algorithmicWithDiagram,
    diagramRequirement: DiagramRequired('clock_analog'),
    categoryRowOrder: 11,
  ),
];

/// Lookup helper. O(n) — n is small (~22), called rarely.
Concept? findConceptById(String id) =>
    allConcepts.where((c) => c.id == id).firstOrNull;

/// Returns the concepts whose primary grade is at or below [playerGrade].
Iterable<Concept> conceptsAtOrBelowGrade(int playerGrade) =>
    allConcepts.where((c) => c.primaryGrade <= playerGrade);

/// Difficulty queue order: ascending grade, then ascending category row order.
/// Used by the drip-feed engine to break ties within a player's frontier.
int compareConceptDifficulty(Concept a, Concept b) {
  final byGrade = a.primaryGrade.compareTo(b.primaryGrade);
  if (byGrade != 0) return byGrade;
  return a.categoryRowOrder.compareTo(b.categoryRowOrder);
}
