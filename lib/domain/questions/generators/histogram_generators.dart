import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// Histogram generators (Grade 6, `stats` category).
///
/// `histogram` asks "how many fall in the [lo, hi) bin?" — analogous to
/// `bar_graph_read` but with a continuous-axis histogram. `describe_
/// distribution` asks for the qualitative *shape*: symmetric, skewed
/// left, skewed right, or uniform.

// ─────────────────────────────────────────────────────────────────────────
// Themed contexts
// ─────────────────────────────────────────────────────────────────────────

class _HistogramTheme {
  const _HistogramTheme({
    required this.title,
    required this.axisLabel,
    required this.binStart,
    required this.binWidth,
    required this.binCount,
    required this.itemPlural,
    required this.measurePhrase,
  });

  /// Header above the plot, e.g. "Math test scores".
  final String title;

  /// x-axis caption, e.g. "Score".
  final String axisLabel;

  final int binStart;
  final int binWidth;
  final int binCount;

  /// Subject in the count question, e.g. "students".
  final String itemPlural;

  /// What's being measured, used inline in the prompt:
  /// "How many students *scored between* 70 and 80?"
  final String measurePhrase;
}

const _themes = <_HistogramTheme>[
  _HistogramTheme(
    title: 'Math test scores',
    axisLabel: 'Score',
    binStart: 50,
    binWidth: 10,
    binCount: 5,
    itemPlural: 'students',
    measurePhrase: 'scored between',
  ),
  _HistogramTheme(
    title: 'Student heights',
    axisLabel: 'Inches',
    binStart: 52,
    binWidth: 2,
    binCount: 5,
    itemPlural: 'students',
    measurePhrase: 'are between',
  ),
  _HistogramTheme(
    title: 'Daily high temperatures',
    axisLabel: '°F',
    binStart: 60,
    binWidth: 5,
    binCount: 5,
    itemPlural: 'days',
    measurePhrase: 'had a high between',
  ),
];

// ─────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────

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

int _roundUpTo(int n, int step) {
  if (n % step == 0) return n;
  return n + (step - n % step);
}

// ─────────────────────────────────────────────────────────────────────────
// histogram (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "How many students scored between 70 and 80?" Pick one bin uniformly,
/// answer = its count. Bin counts in [1, 12]; pairwise distinct so the
/// "read the wrong bin" misconception distractors are unambiguous.
GeneratedQuestion histogramReading(Random rand) {
  final theme = _themes[rand.nextInt(_themes.length)];

  // Pick distinct bin counts in 1..12.
  final pool = List.generate(12, (i) => i + 1)..shuffle(rand);
  final counts = pool.take(theme.binCount).toList();

  final askedBin = rand.nextInt(theme.binCount);
  final correct = counts[askedBin];
  final lo = theme.binStart + askedBin * theme.binWidth;
  final hi = lo + theme.binWidth;

  // Misconception distractors: counts of the OTHER bins (kid read the
  // wrong column).
  final otherCounts = [
    for (var i = 0; i < theme.binCount; i++)
      if (i != askedBin) '${counts[i]}',
  ];

  final maxC = counts.reduce(max);
  final scale = maxC <= 6 ? 1 : 2;
  final maxY = _roundUpTo(maxC + 1, scale);

  return GeneratedQuestion(
    conceptId: 'histogram',
    prompt:
        'How many ${theme.itemPlural} ${theme.measurePhrase} '
        '$lo and $hi?',
    diagram: HistogramSpec(
      title: theme.title,
      axisLabel: theme.axisLabel,
      counts: counts,
      binStart: theme.binStart,
      binWidth: theme.binWidth,
      scale: scale,
      maxY: maxY,
    ),
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, otherCounts),
    explanation: [
      'Find the bar whose left edge is $lo and right edge is $hi.',
      'Read its height: $correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// describe_distribution (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "Which best describes this distribution?" — symmetric, skewed left,
/// skewed right, or uniform. Picks one shape, generates bin counts that
/// match, presents 4-choice MC.
GeneratedQuestion describeDistribution(Random rand) {
  const shapes = <String>[
    'Symmetric',
    'Skewed left',
    'Skewed right',
    'Uniform',
  ];
  final correctShape = shapes[rand.nextInt(shapes.length)];

  final theme = _themes[rand.nextInt(_themes.length)];
  final binCount = theme.binCount; // 5 bins for all current themes

  final counts = _buildShapedCounts(correctShape, binCount, rand);

  final maxC = counts.reduce(max);
  final scale = maxC <= 6 ? 1 : 2;
  final maxY = _roundUpTo(maxC + 1, scale);

  return GeneratedQuestion(
    conceptId: 'describe_distribution',
    prompt: 'Which best describes the shape of this distribution?',
    diagram: HistogramSpec(
      title: theme.title,
      axisLabel: theme.axisLabel,
      counts: counts,
      binStart: theme.binStart,
      binWidth: theme.binWidth,
      scale: scale,
      maxY: maxY,
    ),
    correctAnswer: correctShape,
    distractors: shapes.where((s) => s != correctShape).toList(),
    explanation: [
      _explanationFor(correctShape),
    ],
    answerFormat: AnswerFormat.string,
  );
}

/// Build a [binCount]-long list of bin counts that visibly matches the
/// given [shape]. Counts stay in [1, 12] to keep the histogram readable.
List<int> _buildShapedCounts(String shape, int binCount, Random rand) {
  switch (shape) {
    case 'Symmetric':
      // Mound: low → high → low. Centre value 7..10, drop ~3 per step.
      // For binCount = 5: [c-4, c-2, c, c-2, c-4] with small jitter.
      final centre = rand.nextInt(4) + 7; // 7..10
      final base = [centre - 4, centre - 2, centre, centre - 2, centre - 4];
      return _jitter(base, 1, rand);
    case 'Skewed right':
      // Tail extends right: tall on left, dropping rightward.
      // [10, 7, 4, 2, 1] with jitter.
      return _jitter(const [10, 7, 4, 2, 1], 1, rand);
    case 'Skewed left':
      // Mirror: tall on right.
      return _jitter(const [1, 2, 4, 7, 10], 1, rand);
    case 'Uniform':
      // All bins roughly equal — base ∈ 4..6, jitter ±0 so they stay equal.
      // (Jitter would defeat the shape; uniform IS exact equality.)
      final base = rand.nextInt(3) + 4; // 4..6
      return List<int>.filled(binCount, base);
  }
  throw StateError('unknown shape $shape');
}

/// Add ±0..[jitterMax] to each count, clamped to [1, 12]. Used to keep
/// shapes recognisable without making every histogram look identical.
List<int> _jitter(List<int> base, int jitterMax, Random rand) {
  return [
    for (final c in base)
      (c + rand.nextInt(2 * jitterMax + 1) - jitterMax).clamp(1, 12),
  ];
}

String _explanationFor(String shape) {
  switch (shape) {
    case 'Symmetric':
      return 'Counts rise to a peak in the middle and fall off equally on '
          'both sides.';
    case 'Skewed right':
      return 'Most data is on the left; a long tail trails off to the '
          'right.';
    case 'Skewed left':
      return 'Most data is on the right; a long tail trails off to the '
          'left.';
    case 'Uniform':
      return 'All bins have about the same count — no peak, no tail.';
  }
  return '';
}
