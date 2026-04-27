/// A discrete math concept tracked for proficiency
/// (e.g. "single-digit addition").
class Concept {
  const Concept({
    required this.id,
    required this.name,
    required this.shortLabel,
    required this.gradeLevel,
    required this.description,
  });

  /// Stable identifier; persisted in proficiency records and on the wheel.
  final String id;

  final String name;

  /// Compact label for wheel segments.
  final String shortLabel;

  /// Earliest grade where this concept is typically introduced.
  /// Used to seed initial proficiency for new players.
  final int gradeLevel;

  final String description;
}
