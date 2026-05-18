import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// Box-plot reading generators (Grade 6–7, `stats` category).
///
/// `box_plot` (G6) shows one five-number summary and asks one of:
/// median, Q1, Q3, IQR, range. `compare_two_distributions` (G7) shows
/// two stacked box plots and asks which has the larger median / IQR /
/// range.

// ─────────────────────────────────────────────────────────────────────────
// Themed contexts
// ─────────────────────────────────────────────────────────────────────────

class _BoxPlotTheme {
  const _BoxPlotTheme({
    required this.title,
    required this.axisLabel,
    required this.minX,
    required this.maxX,
    required this.tickStep,
  });

  final String title;
  final String axisLabel;
  final int minX;
  final int maxX;
  final int tickStep;
}

const _themes = <_BoxPlotTheme>[
  _BoxPlotTheme(
    title: 'Math test scores',
    axisLabel: 'Score',
    minX: 0,
    maxX: 100,
    tickStep: 10,
  ),
  _BoxPlotTheme(
    title: 'Student heights',
    axisLabel: 'Inches',
    minX: 50,
    maxX: 75,
    tickStep: 5,
  ),
  _BoxPlotTheme(
    title: 'Hours of sleep',
    axisLabel: 'Hours',
    minX: 4,
    maxX: 12,
    tickStep: 1,
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

/// Pick a strict five-number summary (all 5 values distinct, in order)
/// within `[lo, hi]`. Guarantees min < Q1 < median < Q3 < max so all
/// derived stats (IQR, range) are well-defined and ≥ 1.
({int min, int q1, int median, int q3, int max}) _pickSummary(
  Random rand,
  int lo,
  int hi, {
  String label = 'summary',
}) {
  for (var attempt = 0; attempt < 100; attempt++) {
    final pool = List<int>.generate(hi - lo + 1, (i) => i + lo)..shuffle(rand);
    final picks = pool.take(5).toList()..sort();
    // Strict inequality between adjacent picks (no ties).
    if (picks[0] < picks[1] &&
        picks[1] < picks[2] &&
        picks[2] < picks[3] &&
        picks[3] < picks[4]) {
      return (
        min: picks[0],
        q1: picks[1],
        median: picks[2],
        q3: picks[3],
        max: picks[4],
      );
    }
  }
  throw StateError('could not pick a strict summary for $label in [$lo, $hi]');
}

// ─────────────────────────────────────────────────────────────────────────
// box_plot (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "What is the median?" — one box plot, one stat asked. Question type
/// drawn uniformly from {median, Q1, Q3, IQR, range}; the displayed
/// summary always has all five values distinct so every stat is ≥ 1
/// and unambiguous.
GeneratedQuestion boxPlotReading(Random rand) {
  final theme = _themes[rand.nextInt(_themes.length)];
  final s = _pickSummary(rand, theme.minX, theme.maxX, label: 'box_plot');
  final summary = BoxPlotSummary(
    label: '',
    min: s.min,
    q1: s.q1,
    median: s.median,
    q3: s.q3,
    max: s.max,
  );

  const kinds = <String>['median', 'Q1', 'Q3', 'IQR', 'range'];
  final kind = kinds[rand.nextInt(kinds.length)];
  late int correct;
  late String prompt;
  late List<String> explanation;
  late List<String> candidates;

  switch (kind) {
    case 'median':
      correct = s.median;
      prompt = 'What is the median?';
      explanation = [
        'The median is the vertical line inside the box: $correct.',
      ];
      candidates = ['${s.q1}', '${s.q3}', '${s.min}', '${s.max}'];
    case 'Q1':
      correct = s.q1;
      prompt = 'What is the first quartile (Q1)?';
      explanation = [
        'Q1 is the LEFT edge of the box: $correct.',
      ];
      candidates = ['${s.median}', '${s.q3}', '${s.min}', '${s.max}'];
    case 'Q3':
      correct = s.q3;
      prompt = 'What is the third quartile (Q3)?';
      explanation = [
        'Q3 is the RIGHT edge of the box: $correct.',
      ];
      candidates = ['${s.median}', '${s.q1}', '${s.min}', '${s.max}'];
    case 'IQR':
      correct = s.q3 - s.q1;
      prompt = 'What is the interquartile range (IQR)?';
      explanation = [
        'IQR = Q3 − Q1 = ${s.q3} − ${s.q1} = $correct.',
      ];
      candidates = [
        '${s.max - s.min}', // range instead of IQR
        '${s.q3 + s.q1}', // added instead of subtracted
        '${s.median - s.q1}', // half-IQR (lower side)
        '${s.q3 - s.median}', // half-IQR (upper side)
      ];
    case 'range':
      correct = s.max - s.min;
      prompt = 'What is the range?';
      explanation = [
        'Range = max − min = ${s.max} − ${s.min} = $correct.',
      ];
      candidates = [
        '${s.q3 - s.q1}', // IQR instead of range
        '${s.max + s.min}', // added instead of subtracted
        '${s.max}', // forgot to subtract
        '${s.min}',
      ];
    default:
      throw StateError('unreachable: kind=$kind');
  }

  return GeneratedQuestion(
    conceptId: 'box_plot',
    prompt: prompt,
    diagram: BoxPlotSpec(
      title: theme.title,
      axisLabel: theme.axisLabel,
      summaries: [summary],
      minX: theme.minX,
      maxX: theme.maxX,
      tickStep: theme.tickStep,
    ),
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, candidates),
    explanation: explanation,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// compare_two_distributions (Grade 7)
// ─────────────────────────────────────────────────────────────────────────

/// "Which group has the larger median?" — two stacked box plots A and B.
/// Asked metric drawn from {median, IQR, range}; re-rolls until A and B
/// differ on that metric (so the answer is unambiguous).
GeneratedQuestion compareTwoDistributions(Random rand) {
  GeneratedQuestion attempt(int depth) {
    if (depth > 30) return compareTwoDistributions(rand);
    final theme = _themes[rand.nextInt(_themes.length)];
    final sa = _pickSummary(rand, theme.minX, theme.maxX, label: 'A');
    final sb = _pickSummary(rand, theme.minX, theme.maxX, label: 'B');

    const kinds = <String>['median', 'IQR', 'range'];
    final kind = kinds[rand.nextInt(kinds.length)];
    late int aMetric;
    late int bMetric;
    late String prompt;
    switch (kind) {
      case 'median':
        aMetric = sa.median;
        bMetric = sb.median;
        prompt = 'Which group has the larger median?';
      case 'IQR':
        aMetric = sa.q3 - sa.q1;
        bMetric = sb.q3 - sb.q1;
        prompt = 'Which group has the larger IQR?';
      case 'range':
        aMetric = sa.max - sa.min;
        bMetric = sb.max - sb.min;
        prompt = 'Which group has the larger range?';
      default:
        throw StateError('unreachable: kind=$kind');
    }
    if (aMetric == bMetric) return attempt(depth + 1);

    final correctLabel = aMetric > bMetric ? 'A' : 'B';
    final wrongLabel = correctLabel == 'A' ? 'B' : 'A';

    return GeneratedQuestion(
      conceptId: 'compare_two_distributions',
      prompt: prompt,
      diagram: BoxPlotSpec(
        title: theme.title,
        axisLabel: theme.axisLabel,
        summaries: [
          BoxPlotSummary(
            label: 'A',
            min: sa.min,
            q1: sa.q1,
            median: sa.median,
            q3: sa.q3,
            max: sa.max,
          ),
          BoxPlotSummary(
            label: 'B',
            min: sb.min,
            q1: sb.q1,
            median: sb.median,
            q3: sb.q3,
            max: sb.max,
          ),
        ],
        minX: theme.minX,
        maxX: theme.maxX,
        tickStep: theme.tickStep,
      ),
      correctAnswer: correctLabel,
      // Distractors: the other group, plus "Both are the same" and
      // "Cannot tell from a box plot" — the standard confusable choices.
      distractors: [
        wrongLabel,
        'Both are the same',
        'Cannot tell from a box plot',
      ],
      explanation: [
        'Group A: $aMetric. Group B: $bMetric.',
        'Larger is $correctLabel.',
      ],
      answerFormat: AnswerFormat.string,
    );
  }

  return attempt(0);
}
