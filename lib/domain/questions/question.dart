/// A single question presented to the player.
class Question {
  const Question({
    required this.conceptId,
    required this.prompt,
    required this.correctAnswer,
    required this.distractors,
    required this.explanation,
  });

  final String conceptId;
  final String prompt;
  final String correctAnswer;

  /// Exactly three wrong answers; none equals [correctAnswer].
  final List<String> distractors;

  /// Shown on the result screen when the player answers incorrectly.
  final String explanation;

  /// All four choices unsorted — callers should shuffle before displaying.
  List<String> get allChoices => [correctAnswer, ...distractors];
}
