/// Heuristic: is this prompt a word problem (worth reading aloud) or a
/// bare number equation (better left silent)?
///
/// We auto-speak word problems on the question screen so early readers
/// hear the story without the player having to tap. We deliberately do
/// NOT auto-speak equations like "3 + 4 = ?" — symbol-to-speech mapping
/// on a raw expression sounds robotic and isn't helpful for kids who can
/// already read digits.
///
/// Heuristic: count "real" words (≥3 alphabetic characters, ignoring a
/// short stop-word list of math-prompt fillers). Three or more such
/// words ⇒ word problem.
///
/// We tune the threshold from real generator output rather than chasing
/// a perfect classifier — false positives (a number equation read aloud)
/// are mildly annoying, false negatives (a word problem left silent) are
/// the worse failure mode for the accessibility goal, so we lean slightly
/// permissive.
bool isWordProblem(String prompt) {
  const stopWords = <String>{
    // Math-prompt fillers that don't signal narrative content.
    'is', 'the', 'a', 'an', 'of', 'and', 'or', 'to', 'in', 'on', 'at',
    'by', 'for', 'as', 'it',
  };
  final words = RegExp("[A-Za-z']+")
      .allMatches(prompt)
      .map((m) => m.group(0)!.toLowerCase())
      .where((w) => w.length >= 3 && !stopWords.contains(w))
      .toList();
  return words.length >= 3;
}
