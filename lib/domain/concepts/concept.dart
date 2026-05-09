/// Question-source strategy for a concept (mirrors curriculum.md §3 column).
enum ConceptSource {
  algorithmic,
  algorithmicWithDiagram,
  dataset,
  algorithmicPlusDataset,
  deferred,
}

/// Diagram requirement for a concept.
sealed class DiagramRequirement {
  const DiagramRequirement();
}

class DiagramNone extends DiagramRequirement {
  const DiagramNone();
}

class DiagramOptional extends DiagramRequirement {
  const DiagramOptional();
}

class DiagramRequired extends DiagramRequirement {
  const DiagramRequired(this.kind);

  /// The diagram-widget kind, e.g. 'fraction_bar', 'number_line', 'clock'.
  final String kind;
}

/// A discrete sub-concept tracked for proficiency (e.g. "add within 10").
///
/// Mirrors a row in `curriculum.md` §3.x. The `id` matches the curriculum
/// catalog ID exactly.
class Concept {
  const Concept({
    required this.id,
    required this.name,
    required this.shortLabel,
    required this.categoryId,
    required this.primaryGrade,
    required this.prereqIds,
    required this.source,
    required this.diagramRequirement,
    required this.categoryRowOrder,
  });

  /// Stable curriculum identifier (snake_case).
  final String id;

  /// Display name shown on the question screen.
  final String name;

  /// Compact label for wheel segments.
  final String shortLabel;

  /// Top-level category ID (e.g. 'add_sub', 'fractions').
  final String categoryId;

  /// Primary grade (K=0, 1–8). Used to seed initial proficiency.
  final int primaryGrade;

  /// DAG predecessor IDs. Empty = root node.
  final List<String> prereqIds;

  final ConceptSource source;

  final DiagramRequirement diagramRequirement;

  /// Position within the concept's category in `curriculum.md` (0-based).
  /// Drives the within-category difficulty tiebreaker for the drip-feed.
  final int categoryRowOrder;
}
