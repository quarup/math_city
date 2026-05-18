import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// Bar-graph reading generators (Grade 2–3, `stats` category).
///
/// All three reuse a small pool of themed contexts (favorite fruit/color/
/// pet/sport + a city-builder construction-materials theme) so the chart
/// looks like a real survey or count rather than abstract category labels.
///
/// Convention: every chart has exactly 4 bars, picked from the chosen
/// theme. `bar_graph_read` / `bar_graph_compare` use scale = 1 so each
/// gridline is one unit; `scaled_bar_graph_read` uses scale ∈ {2, 5, 10}
/// and every bar value is an exact multiple of the scale.

// ─────────────────────────────────────────────────────────────────────────
// Themed contexts
// ─────────────────────────────────────────────────────────────────────────

class _ChartTheme {
  const _ChartTheme({
    required this.title,
    required this.categories,
    required this.singularUnit,
  });

  /// Header above the chart, e.g. "Favorite fruit".
  final String title;

  /// Four plural category labels (what each bar represents).
  final List<String> categories;

  /// What a single tick of the y-axis counts — used in the prompt:
  /// "How many *kids* like apples?" or "How many *bricks*?".
  final String singularUnit;
}

const _themes = <_ChartTheme>[
  _ChartTheme(
    title: 'Favorite fruit',
    categories: ['apples', 'bananas', 'grapes', 'oranges'],
    singularUnit: 'kids',
  ),
  _ChartTheme(
    title: 'Favorite color',
    categories: ['red', 'blue', 'green', 'yellow'],
    singularUnit: 'kids',
  ),
  _ChartTheme(
    title: 'Favorite pet',
    categories: ['dogs', 'cats', 'fish', 'birds'],
    singularUnit: 'kids',
  ),
  _ChartTheme(
    title: 'Favorite sport',
    categories: ['soccer', 'basketball', 'swimming', 'tennis'],
    singularUnit: 'kids',
  ),
  _ChartTheme(
    title: 'Materials at the site',
    categories: ['bricks', 'paint cans', 'cones', 'signs'],
    singularUnit: 'items',
  ),
];

// ─────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────

/// Round `n` up to the next multiple of `step` (≥ 1). Used to pick a
/// nicely-sized y-axis top from the tallest bar.
int _roundUpTo(int n, int step) {
  if (n % step == 0) return n;
  return n + (step - n % step);
}

/// Three unique stringified-integer distractors that differ from
/// [correct]. Falls back to ±i bumps if the candidate pool dedupes
/// to fewer than 3.
List<String> _distinctIntStrings(int correct, List<String> candidates) {
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

// ─────────────────────────────────────────────────────────────────────────
// bar_graph_read (Grade 2)
// ─────────────────────────────────────────────────────────────────────────

/// "How many kids like apples?" with a 4-bar chart, scale = 1. Bar values
/// in [1, 10]; pairwise distinct so the wrong-bar misconception distractors
/// are unambiguous.
GeneratedQuestion barGraphRead(Random rand) {
  final theme = _themes[rand.nextInt(_themes.length)];

  // Pick 4 distinct values in 1..10.
  final pool = List.generate(10, (i) => i + 1)..shuffle(rand);
  final values = pool.take(4).toList();

  final askIndex = rand.nextInt(4);
  final askedLabel = theme.categories[askIndex];
  final correct = values[askIndex];

  // Misconception distractors: the OTHER three bar values (kid read the
  // wrong bar). _distinctIntStrings will fall back to ±i bumps if any
  // collide with `correct`, which can't happen here since values are
  // distinct.
  final otherValues = [
    for (var i = 0; i < 4; i++) if (i != askIndex) '${values[i]}',
  ];

  final maxV = values.reduce(max);
  final maxY = max(_roundUpTo(maxV, 2), maxV + 1);

  return GeneratedQuestion(
    conceptId: 'bar_graph_read',
    prompt: 'How many ${theme.singularUnit} like $askedLabel?',
    diagram: BarChartSpec(
      title: theme.title,
      labels: theme.categories,
      values: values,
      scale: 1,
      maxY: maxY,
    ),
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, otherValues),
    explanation: [
      'Find the bar labelled "$askedLabel".',
      'Read its height from the y-axis: $correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// bar_graph_compare (Grade 2)
// ─────────────────────────────────────────────────────────────────────────

/// "How many more X than Y?" Picks two distinct categories with a positive
/// difference of at least 2, scale = 1. Difference always ≥ 2 so the
/// answer isn't trivially 1.
GeneratedQuestion barGraphCompare(Random rand) {
  final theme = _themes[rand.nextInt(_themes.length)];

  // Re-roll until the two indices we'll compare differ by ≥ 2.
  late List<int> values;
  late int hi;
  late int lo;
  do {
    final pool = List.generate(10, (i) => i + 1)..shuffle(rand);
    values = pool.take(4).toList();
    hi = rand.nextInt(4);
    do {
      lo = rand.nextInt(4);
    } while (lo == hi);
    if (values[hi] < values[lo]) {
      final tmp = hi;
      hi = lo;
      lo = tmp;
    }
  } while (values[hi] - values[lo] < 2);

  final correct = values[hi] - values[lo];
  final hiLabel = theme.categories[hi];
  final loLabel = theme.categories[lo];

  // Misconception distractors:
  //   - sum instead of difference
  //   - one of the two bar values (gave just one count)
  //   - difference using a wrong pair from the other two bars
  final others = [
    for (var i = 0; i < 4; i++) if (i != hi && i != lo) values[i],
  ];
  final wrongDiff = (others[0] - others[1]).abs();
  final candidates = <String>[
    '${values[hi] + values[lo]}',
    '${values[hi]}',
    '${values[lo]}',
    '$wrongDiff',
    '${correct + 1}',
    '${correct - 1}',
  ];

  final maxV = values.reduce(max);
  final maxY = max(_roundUpTo(maxV, 2), maxV + 1);

  return GeneratedQuestion(
    conceptId: 'bar_graph_compare',
    prompt: 'How many more ${theme.singularUnit} like $hiLabel than $loLabel?',
    diagram: BarChartSpec(
      title: theme.title,
      labels: theme.categories,
      values: values,
      scale: 1,
      maxY: maxY,
    ),
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, candidates),
    explanation: [
      '$hiLabel: ${values[hi]}. $loLabel: ${values[lo]}.',
      'Subtract: ${values[hi]} − ${values[lo]} = $correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// scaled_bar_graph_read (Grade 3)
// ─────────────────────────────────────────────────────────────────────────

/// "How many kids like apples?" with a 4-bar chart whose y-axis ticks
/// every 2, 5, or 10 units. Each bar value is an exact multiple of the
/// scale and bars are pairwise distinct.
GeneratedQuestion scaledBarGraphRead(Random rand) {
  final theme = _themes[rand.nextInt(_themes.length)];
  final scale = const [2, 5, 10][rand.nextInt(3)];

  // Pick 4 distinct multipliers in 1..7, then bar values are
  // multiplier * scale. Bars therefore land in {scale, 2·scale, …, 7·scale}.
  final pool = List.generate(7, (i) => i + 1)..shuffle(rand);
  final multipliers = pool.take(4).toList();
  final values = multipliers.map((m) => m * scale).toList();

  final askIndex = rand.nextInt(4);
  final askedLabel = theme.categories[askIndex];
  final correct = values[askIndex];
  final correctMultiplier = multipliers[askIndex];

  // Misconception distractors:
  //   - forgot the scale: gave the gridline count (multiplier) only
  //   - wrong scale: used scale=1 (also covered by above) and value×scale²
  //   - other bar values (wrong-bar misconception)
  final candidates = <String>[
    '$correctMultiplier',
    '${correctMultiplier * scale * scale}',
    for (var i = 0; i < 4; i++) if (i != askIndex) '${values[i]}',
  ];

  final maxV = values.reduce(max);
  final maxY = _roundUpTo(maxV, scale);
  final paddedMaxY = maxY == maxV ? maxY + scale : maxY;

  return GeneratedQuestion(
    conceptId: 'scaled_bar_graph_read',
    prompt: 'How many ${theme.singularUnit} like $askedLabel?',
    diagram: BarChartSpec(
      title: theme.title,
      labels: theme.categories,
      values: values,
      scale: scale,
      maxY: paddedMaxY,
    ),
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, candidates),
    explanation: [
      'Find the bar labelled "$askedLabel".',
      'Each gridline is worth $scale.',
      'The bar reaches $correctMultiplier gridlines × $scale = $correct.',
    ],
  );
}
