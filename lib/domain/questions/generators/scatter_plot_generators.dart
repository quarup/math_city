import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// Scatter-plot generators (Grade 8, `stats` category).
///
/// Both generators use the `ScatterPlot` widget — a coordinate-plot
/// variant with lighter grid, optional axis labels, and no per-point
/// letter labels.
///
/// `scatter_plot_construct` (G8): a small table of (x, y) pairs is shown
/// in the prompt; the diagram is a scatter plot with all but one point
/// plotted. The student picks the missing point from 4 coordinate-string
/// MC options.
///
/// `scatter_plot_describe` (G8): the diagram is a scatter plot whose
/// points follow one of four patterns (positive linear, negative linear,
/// no association, nonlinear); the student picks the matching name.

const _minus = '−'; // U+2212

String _coord(int x, int y) {
  String fmt(int n) => n >= 0 ? '$n' : '$_minus${-n}';
  return '(${fmt(x)}, ${fmt(y)})';
}

// ─────────────────────────────────────────────────────────────────────────
// scatter_plot_construct (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// Show a 5-row table of (x, y) pairs in the prompt + a scatter plot
/// with 4 of the 5 points already plotted. Ask which point is missing.
/// All x-values distinct in [1, 10]; all y-values distinct in [1, 10] so
/// the swap-distractor `(y, x)` is a genuinely different point.
GeneratedQuestion scatterPlotConstruct(Random rand) {
  // Pick 5 distinct x-values and 5 distinct y-values in [1, 10], pair
  // them up by shuffling y against x. Re-roll if any pair has x == y
  // (which would make the swap-distractor identical to the answer).
  late List<List<int>> pairs;
  for (var attempt = 0; attempt < 30; attempt++) {
    final xs = (List.generate(10, (i) => i + 1)..shuffle(rand)).take(5).toList()
      ..sort();
    final ys = (List.generate(
      10,
      (i) => i + 1,
    )..shuffle(rand)).take(5).toList();
    pairs = [
      for (var i = 0; i < 5; i++) [xs[i], ys[i]],
    ];
    if (pairs.every((p) => p[0] != p[1])) break;
  }

  final missingIdx = rand.nextInt(5);
  final missing = pairs[missingIdx];
  final mx = missing[0];
  final my = missing[1];

  final plotted = [
    for (var i = 0; i < 5; i++)
      if (i != missingIdx) ScatterPlotPoint(x: pairs[i][0], y: pairs[i][1]),
  ];

  // Distractors:
  //   - (y, x) — swapped coordinates (must be off the existing plotted
  //     points and not the missing point itself; guaranteed by x != y)
  //   - (x + 1, y) — off-by-one in x
  //   - (x, y + 1) — off-by-one in y (or y - 1 if y == 10 to stay in [1, 10])
  final candidates = <List<int>>[
    [my, mx],
    [mx + 1, my],
    if (my < 10) [mx, my + 1] else [mx, my - 1],
    [mx - 1, my],
    if (my > 1) [mx, my - 1],
  ];

  // Pick the first 3 distinct candidates that don't collide with the
  // correct answer or with each other or with plotted points (since a
  // plotted point can't be the "missing" answer).
  final plottedKeys = {
    for (final p in plotted) '${p.x},${p.y}',
  };
  final correctKey = '$mx,$my';
  final seen = <String>{correctKey, ...plottedKeys};
  final distractorPairs = <List<int>>[];
  for (final c in candidates) {
    if (distractorPairs.length >= 3) break;
    final key = '${c[0]},${c[1]}';
    if (seen.add(key)) distractorPairs.add(c);
  }
  // Fallback: walk a small neighbourhood if any of the misconception
  // candidates collide and we end up short of 3.
  for (final dx in <int>[2, -2, 1, -1]) {
    if (distractorPairs.length >= 3) break;
    for (final dy in <int>[2, -2, 1, -1]) {
      if (distractorPairs.length >= 3) break;
      final c = [mx + dx, my + dy];
      if (c[0] < 0 || c[1] < 0) continue;
      final key = '${c[0]},${c[1]}';
      if (seen.add(key)) distractorPairs.add(c);
    }
  }

  final tableRows = pairs.map((p) => '(${p[0]}, ${p[1]})').join('; ');

  return GeneratedQuestion(
    conceptId: 'scatter_plot_construct',
    prompt:
        'These ordered pairs should all be plotted: $tableRows. '
        'Which point is missing from the diagram?',
    diagram: ScatterPlotSpec(
      minX: 0,
      maxX: 11,
      minY: 0,
      maxY: 11,
      points: plotted,
    ),
    correctAnswer: _coord(mx, my),
    distractors: distractorPairs.map((p) => _coord(p[0], p[1])).toList(),
    explanation: [
      "Read the listed pairs and find the one whose dot isn't on the plot yet.",
      "It's ${_coord(mx, my)}.",
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// scatter_plot_describe (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// "What pattern does this scatter plot show?" 4-choice MC over Positive
/// association / Negative association / No association / Nonlinear. The
/// generator picks a pattern uniformly, then synthesises 8 points that
/// visibly follow it (with small jitter).
GeneratedQuestion scatterPlotDescribe(Random rand) {
  const patterns = <String>[
    'Positive association',
    'Negative association',
    'No association',
    'Nonlinear',
  ];
  final pattern = patterns[rand.nextInt(patterns.length)];
  const xs = [1, 2, 3, 4, 6, 8, 10, 11];
  final points = <ScatterPlotPoint>[];

  for (final x in xs) {
    int y;
    switch (pattern) {
      case 'Positive association':
        // y ≈ x + small jitter
        y = (x + rand.nextInt(3) - 1).clamp(1, 11);
      case 'Negative association':
        // y ≈ 12 - x + small jitter
        y = (12 - x + rand.nextInt(3) - 1).clamp(1, 11);
      case 'No association':
        // y is random independent of x
        y = rand.nextInt(11) + 1; // 1..11
      case 'Nonlinear':
        // V-shape: y ≈ |x - 6| + 1 + jitter
        y = ((x - 6).abs() + 1 + rand.nextInt(2)).clamp(1, 11);
      default:
        throw StateError('unknown pattern $pattern');
    }
    points.add(ScatterPlotPoint(x: x, y: y));
  }

  return GeneratedQuestion(
    conceptId: 'scatter_plot_describe',
    prompt: 'What pattern does this scatter plot show?',
    diagram: ScatterPlotSpec(
      minX: 0,
      maxX: 12,
      minY: 0,
      maxY: 12,
      points: points,
    ),
    correctAnswer: pattern,
    distractors: patterns.where((p) => p != pattern).toList(),
    explanation: [_explanationFor(pattern)],
    answerFormat: AnswerFormat.string,
  );
}

String _explanationFor(String pattern) {
  switch (pattern) {
    case 'Positive association':
      return 'As x increases, y also tends to increase — points climb '
          'from lower-left to upper-right.';
    case 'Negative association':
      return 'As x increases, y tends to decrease — points fall from '
          'upper-left to lower-right.';
    case 'No association':
      return "y doesn't change in a clear direction as x increases — "
          'points scatter without a trend.';
    case 'Nonlinear':
      return 'Points follow a curve rather than a straight line.';
  }
  return '';
}
