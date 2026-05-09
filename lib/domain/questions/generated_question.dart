import 'package:math_dash/domain/questions/diagram_spec.dart';

/// A single question presented to the player.
///
/// All values are pure data (no Flutter imports). Answer values are stored
/// as their rendered string form — generators are responsible for
/// formatting (e.g. fractions as "1/2", times as "3:30").
class GeneratedQuestion {
  const GeneratedQuestion({
    required this.conceptId,
    required this.prompt,
    required this.correctAnswer,
    required this.distractors,
    required this.explanation,
    this.diagram,
  });

  final String conceptId;

  /// Question text shown to the player. May contain literal numbers; the
  /// diagram (if any) carries the visual representation.
  final String prompt;

  /// Optional diagram rendered above/alongside the prompt.
  final DiagramSpec? diagram;

  final String correctAnswer;

  /// Exactly three wrong answers; none equals [correctAnswer].
  final List<String> distractors;

  /// 1–4 step-by-step lines shown on the result screen when the player
  /// answers incorrectly. Lines are rendered top-to-bottom.
  final List<String> explanation;

  /// All four choices unsorted — callers should shuffle before displaying.
  List<String> get allChoices => [correctAnswer, ...distractors];
}
