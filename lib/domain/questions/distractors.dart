import 'dart:math';

/// Universal distractor strategies for integer answers (curriculum.md §5.3).
///
/// Returns exactly three distinct, non-negative distractors that differ
/// from [correct]. Falls back to small positives if the candidate set
/// runs out (only happens for tiny answers like 0 or 1).
List<String> integerDistractors(int correct, Random rand) {
  final candidates = <int>{
    correct + 1,
    if (correct - 1 >= 0) correct - 1,
  };

  // Random ±5 jitter for variety.
  for (var i = 0; i < 40 && candidates.length < 8; i++) {
    final offset = rand.nextInt(5) + 1;
    final sign = rand.nextBool() ? 1 : -1;
    final v = correct + sign * offset;
    if (v >= 0) candidates.add(v);
  }

  candidates.remove(correct);

  // Fallback: small positives.
  for (var fallback = 0; candidates.length < 3; fallback++) {
    if (fallback != correct) candidates.add(fallback);
  }

  final list = candidates.toList()..shuffle(rand);
  return list.take(3).map((n) => n.toString()).toList();
}

/// Picks three integer distractors but biases the first slot toward a
/// topic-specific [misconception] when it's a valid distractor.
///
/// Used by generators that have a known "common wrong answer" they want
/// to surface (e.g. fraction-add: added denominators). The misconception
/// is dropped if it matches [correct] or is negative.
List<String> integerDistractorsWith(
  int correct,
  Random rand, {
  required int misconception,
}) {
  final base = integerDistractors(correct, rand);
  if (misconception == correct || misconception < 0) return base;
  // Replace first slot with the misconception, keep two from the base set
  // while preserving uniqueness.
  final mc = misconception.toString();
  final rest = base.where((s) => s != mc).take(2).toList();
  while (rest.length < 2) {
    // Extreme fallback (correct=0 or 1): take a new one.
    final extra = integerDistractors(correct, rand);
    for (final s in extra) {
      if (s != mc && !rest.contains(s)) {
        rest.add(s);
        if (rest.length == 2) break;
      }
    }
  }
  final result = [mc, ...rest]..shuffle(rand);
  return result;
}

/// Picks three string distractors from a candidate pool that differ from
/// [correct]. Useful for time-of-day or fraction-string answers.
List<String> stringDistractorsFromPool(
  String correct,
  List<String> pool,
  Random rand,
) {
  final unique = pool.where((s) => s != correct).toSet().toList()
    ..shuffle(rand);
  if (unique.length < 3) {
    throw StateError(
      'distractor pool too small: ${unique.length} unique != correct',
    );
  }
  return unique.take(3).toList();
}
