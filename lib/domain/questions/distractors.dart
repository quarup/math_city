import 'dart:math';

import 'package:math_city/domain/questions/fraction.dart';

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

/// Picks three fraction-string distractors for [correct], skipping any
/// candidate that is mathematically equivalent to it. Candidates are tried
/// in order, then random ±1 numerator/denominator perturbations of
/// [correct] are appended as fallbacks until three unique non-equivalent
/// strings have been collected.
///
/// The strings returned are the candidates' *original* surface forms
/// (typically un-reduced) — generators emit a canonical reduced answer
/// while their distractors stay in the "computational" un-reduced shape
/// that kids actually write down before simplifying.
///
/// Value-distinctness matters beyond aesthetics: questions graded by
/// value (`AnswerShape.any`) would accept an equivalent distractor as a
/// second right answer.
List<String> fractionDistractors(
  Fraction correct,
  List<String> candidates,
  Random rand,
) {
  final out = <String>[];
  final seen = <String>{correct.toCanonical()};
  bool tryAdd(String s) {
    if (seen.contains(s)) return false;
    // Reject invalid mixed notation like "1 10/6" or "2 3/3" — forms the
    // curriculum tells kids never to write.
    final mixed = RegExp(r'^-?\d+\s+(\d+)/(\d+)$').firstMatch(s);
    if (mixed != null &&
        int.parse(mixed.group(1)!) >= int.parse(mixed.group(2)!)) {
      return false;
    }
    final f = Fraction.tryParse(s);
    if (f != null && f.equalsByValue(correct)) return false;
    // No two distractors may share a VALUE (e.g. 0/3 and 0/1) — a kid
    // with one wrong idea would get two choices for it.
    if (f != null) {
      for (final o in out) {
        final of = Fraction.tryParse(o);
        if (of != null && of.equalsByValue(f)) return false;
      }
    }
    seen.add(s);
    out.add(s);
    return true;
  }

  for (final c in candidates) {
    if (out.length >= 3) break;
    tryAdd(c);
  }
  // Fallback perturbations: keep the correct denominator and drift the
  // top — an off-by-one top is at least a believable slip, while a
  // drifted denominator (2/13, x/1) read as filler no kid would write.
  for (var i = 0; i < 40 && out.length < 3; i++) {
    final dn = rand.nextInt(5) - 2; // -2..2
    final n2 = correct.numerator + dn;
    if (n2 <= 0) continue;
    tryAdd('$n2/${correct.denominator}');
  }
  while (out.length < 3) {
    // Extreme fallback: just emit unique tiny fractions.
    out.add('${out.length + 1}/${out.length + 2}');
  }
  return out.take(3).toList();
}
