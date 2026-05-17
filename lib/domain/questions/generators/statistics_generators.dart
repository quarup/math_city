import 'dart:math';

import 'package:math_city/domain/questions/generated_question.dart';

/// Statistics generators (Grade 6 — `statistics` category).
///
/// All four answers are integers. The data list is shown verbatim in the
/// prompt as a comma-separated sequence — no diagram widget needed for
/// the basic measures (those come later via `BarChart`, `DotPlot`, etc.).

// ─────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────

/// Three distinct whole-number-string distractors that differ from
/// [correct]. Seeds with [candidates] then walks outward.
List<String> _wholeDistractors(
  int correct,
  List<String> candidates,
  Random rand,
) {
  final out = <String>[];
  final seen = <String>{'$correct'};
  for (final c in candidates) {
    if (out.length >= 3) break;
    if (seen.add(c)) out.add(c);
  }
  for (var i = 1; out.length < 3 && i < 30; i++) {
    for (final delta in <int>[i, -i]) {
      final v = correct + delta;
      if (v < 0) continue;
      final s = '$v';
      if (seen.add(s)) out.add(s);
      if (out.length >= 3) break;
    }
  }
  return out.take(3).toList();
}

String _formatList(List<int> xs) => xs.join(', ');

// ─────────────────────────────────────────────────────────────────────────
// mean (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "Find the mean: 4, 6, 8, 10" → 7. Picks the mean first (1..20) and
/// the count (4..6), then generates a list with that mean by perturbing
/// the values symmetrically — guarantees an integer result.
GeneratedQuestion meanGenerator(Random rand) {
  final mean = rand.nextInt(20) + 1; // 1..20
  final n = rand.nextInt(3) + 4; // 4..6 values
  // Pick perturbations that sum to 0, then offset each value by `mean`.
  final perturbations = <int>[];
  for (var i = 0; i < n; i++) {
    perturbations.add((rand.nextInt(7)) - 3); // -3..3
  }
  // Force sum to 0 by adjusting the last value.
  final adjust = -perturbations.take(n - 1).fold<int>(0, (a, b) => a + b);
  perturbations[n - 1] = adjust;
  // Build values; re-roll if any goes below 1 or above 50.
  final values = perturbations.map((d) => mean + d).toList();
  if (values.any((v) => v < 1 || v > 50)) return meanGenerator(rand);
  // Shuffle so the list isn't sorted (which would give it away).
  values.shuffle(rand);

  final correct = '$mean';
  final candidates = <String>[
    '${values.reduce((a, b) => a + b)}', // forgot to divide
    '${values.reduce((a, b) => a + b) ~/ (n + 1)}', // wrong count
    '${values.reduce((a, b) => a + b) - n}',
  ];

  return GeneratedQuestion(
    conceptId: 'mean',
    prompt: 'Find the mean: ${_formatList(values)}',
    correctAnswer: correct,
    distractors: _wholeDistractors(mean, candidates, rand),
    explanation: [
      'Sum: ${values.reduce((a, b) => a + b)}.',
      'Divide by how many: $n values.',
      '${values.reduce((a, b) => a + b)} ÷ $n = $mean.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// median (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "Find the median: 3, 7, 2, 8, 5" → 5. Always odd count so the
/// median is the exact middle value (no averaging step needed).
GeneratedQuestion medianGenerator(Random rand) {
  final n = [5, 7][rand.nextInt(2)]; // 5 or 7 values
  // Generate distinct values 1..30, then take the n.
  final pool = List.generate(30, (i) => i + 1)..shuffle(rand);
  final values = pool.take(n).toList();
  final sorted = [...values]..sort();
  final median = sorted[n ~/ 2];
  final correct = '$median';

  final candidates = <String>[
    // Misconception: took the middle of the *original* (unsorted) list.
    '${values[n ~/ 2]}',
    // Misconception: took the min or max.
    '${sorted.first}',
    '${sorted.last}',
    // Misconception: took the mean.
    '${values.reduce((a, b) => a + b) ~/ n}',
  ];

  return GeneratedQuestion(
    conceptId: 'median',
    prompt: 'Find the median: ${_formatList(values)}',
    correctAnswer: correct,
    distractors: _wholeDistractors(median, candidates, rand),
    explanation: [
      'Sort the values: ${_formatList(sorted)}.',
      'Middle of $n values is position ${n ~/ 2 + 1}.',
      'Median = $median.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// mode (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "Find the mode: 2, 3, 3, 5, 7" → 3. Generates a list with exactly
/// one most-frequent value (no ties).
GeneratedQuestion modeGenerator(Random rand) {
  final modeVal = rand.nextInt(19) + 1; // 1..19
  final repeats = rand.nextInt(2) + 2; // 2 or 3 occurrences of mode
  final others = rand.nextInt(2) + 3; // 3 or 4 other distinct values
  // Pick `others` distinct values from 1..20 excluding modeVal.
  final pool = List.generate(20, (i) => i + 1)
    ..remove(modeVal)
    ..shuffle(rand);
  final otherValues = pool.take(others).toList();
  // Build the list: `repeats` copies of mode + the other distinct values.
  final values = <int>[
    ...List.filled(repeats, modeVal),
    ...otherValues,
  ]..shuffle(rand);

  final correct = '$modeVal';
  final candidates = <String>[
    // Misconception: gave the mean.
    '${values.reduce((a, b) => a + b) ~/ values.length}',
    // Misconception: gave one of the other values.
    '${otherValues.first}',
    '${otherValues.last}',
  ];

  return GeneratedQuestion(
    conceptId: 'mode',
    prompt: 'Find the mode: ${_formatList(values)}',
    correctAnswer: correct,
    distractors: _wholeDistractors(modeVal, candidates, rand),
    explanation: [
      'Mode = value that appears most often.',
      '$modeVal appears $repeats times — more than any other.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// iqr (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "Find the IQR: 2, 5, 7, 9, 11, 14, 18" → 9. Fixed at n=7 so the
/// lower half is exactly 3 values (Q1 = middle of {a,b,c} = b) and the
/// upper half is exactly 3 (Q3 = middle of {e,f,g} = f). Both Q1 and
/// Q3 are always integers; IQR = Q3 − Q1.
GeneratedQuestion iqrGenerator(Random rand) {
  const n = 7;
  final pool = List.generate(50, (i) => i + 1)..shuffle(rand);
  final values = pool.take(n).toList();
  final sorted = [...values]..sort();
  final q1 = sorted[1]; // median of lower half {sorted[0..2]}
  final q3 = sorted[5]; // median of upper half {sorted[4..6]}
  final iqr = q3 - q1;
  final correct = '$iqr';

  final candidates = <String>[
    // Misconception: gave the full range instead.
    '${sorted.last - sorted.first}',
    // Misconception: used the wrong quartile pair.
    '${sorted[5] - sorted[0]}',
    '${sorted[6] - sorted[1]}',
    // Misconception: gave the median.
    '${sorted[3]}',
  ];

  return GeneratedQuestion(
    conceptId: 'iqr',
    prompt: 'Find the IQR: ${_formatList(values)}',
    correctAnswer: correct,
    distractors: _wholeDistractors(iqr, candidates, rand),
    explanation: [
      'Sort: ${_formatList(sorted)}.',
      'Median is ${sorted[3]} — splits the list in two halves.',
      'Q1 = $q1 (middle of lower half); Q3 = $q3 (middle of upper half).',
      'IQR = Q3 − Q1 = $q3 − $q1 = $iqr.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// mad (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "Find the mean absolute deviation: 8, 10, 14, 16" → 3.
/// Generated as `{mean − 2d, mean − d, mean + d, mean + 2d}` so all
/// values are distinct, the mean is exactly `mean`, and MAD = 1.5·d.
/// Uses d ∈ {2, 4} only, giving integer MAD of 3 or 6.
GeneratedQuestion madGenerator(Random rand) {
  final d = rand.nextBool() ? 2 : 4; // → MAD = 3 or 6
  final mean = rand.nextInt(11) + (2 * d) + 1; // mean ≥ 2d+1 so values ≥ 1
  final values = <int>[mean - 2 * d, mean - d, mean + d, mean + 2 * d]
    ..shuffle(rand);
  const n = 4;
  final mad = (3 * d) ~/ 2; // == 1.5·d when d is even
  final absDevs = values.map((v) => (v - mean).abs()).toList();
  final sumAbsDevs = absDevs.reduce((a, b) => a + b);
  final correct = '$mad';

  final candidates = <String>[
    // Misconception: gave the mean instead.
    '$mean',
    // Misconception: forgot to take absolute values (sum of devs = 0).
    '0',
    // Misconception: gave the range.
    '${4 * d}',
    // Misconception: gave 2d (one of the deviations).
    '${2 * d}',
  ];

  return GeneratedQuestion(
    conceptId: 'mad',
    prompt: 'Find the mean absolute deviation: ${_formatList(values)}',
    correctAnswer: correct,
    distractors: _wholeDistractors(mad, candidates, rand),
    explanation: [
      'Mean = $mean.',
      'Absolute deviations: ${absDevs.join(", ")}.',
      'Total $sumAbsDevs ÷ $n = $mad.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// range_data (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "Find the range: 4, 7, 1, 9, 3" → 8. Range = max − min.
GeneratedQuestion rangeDataGenerator(Random rand) {
  final n = rand.nextInt(3) + 5; // 5..7
  final pool = List.generate(50, (i) => i + 1)..shuffle(rand);
  final values = pool.take(n).toList();
  final maxV = values.reduce((a, b) => a > b ? a : b);
  final minV = values.reduce((a, b) => a < b ? a : b);
  final range = maxV - minV;
  final correct = '$range';

  final candidates = <String>[
    // Misconception: max + min.
    '${maxV + minV}',
    // Misconception: just the max.
    '$maxV',
    // Misconception: just the min.
    '$minV',
  ];

  return GeneratedQuestion(
    conceptId: 'range_data',
    prompt: 'Find the range: ${_formatList(values)}',
    correctAnswer: correct,
    distractors: _wholeDistractors(range, candidates, rand),
    explanation: [
      'Range = highest value − lowest value.',
      '$maxV − $minV = $range.',
    ],
  );
}
