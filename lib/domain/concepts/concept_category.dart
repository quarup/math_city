/// A top-level rollup category for sub-concepts (display grouping only).
///
/// Mirrors `curriculum.md` §2 — the 12 K–8 math categories.
class ConceptCategory {
  const ConceptCategory({
    required this.id,
    required this.displayName,
    required this.displayOrder,
  });

  final String id;
  final String displayName;

  /// Ordering on the progress screen (lower = earlier).
  final int displayOrder;
}

const allCategories = <ConceptCategory>[
  ConceptCategory(
    id: 'counting',
    displayName: 'Counting & Number Sense',
    displayOrder: 0,
  ),
  ConceptCategory(
    id: 'place_value',
    displayName: 'Place Value & Number Properties',
    displayOrder: 1,
  ),
  ConceptCategory(
    id: 'add_sub',
    displayName: 'Addition & Subtraction',
    displayOrder: 2,
  ),
  ConceptCategory(
    id: 'mult_div',
    displayName: 'Multiplication & Division',
    displayOrder: 3,
  ),
  ConceptCategory(
    id: 'fractions',
    displayName: 'Fractions',
    displayOrder: 4,
  ),
  ConceptCategory(
    id: 'decimals_percent',
    displayName: 'Decimals & Percentages',
    displayOrder: 5,
  ),
  ConceptCategory(
    id: 'ratios',
    displayName: 'Ratios & Proportions',
    displayOrder: 6,
  ),
  ConceptCategory(
    id: 'measurement',
    displayName: 'Measurement, Time & Money',
    displayOrder: 7,
  ),
  ConceptCategory(
    id: 'geometry',
    displayName: 'Geometry & Shapes',
    displayOrder: 8,
  ),
  ConceptCategory(
    id: 'rationals',
    displayName: 'Integers & Rational Numbers',
    displayOrder: 9,
  ),
  ConceptCategory(
    id: 'prealgebra',
    displayName: 'Pre-Algebra',
    displayOrder: 10,
  ),
  ConceptCategory(
    id: 'stats',
    displayName: 'Data, Statistics & Probability',
    displayOrder: 11,
  ),
];

ConceptCategory? findCategoryById(String id) =>
    allCategories.where((c) => c.id == id).firstOrNull;
