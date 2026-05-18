import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// Dot-plot / line-plot reading generators (`stats` category).
///
/// `line_plot_whole` (G2) asks "How many measured X?" — a literal read of
/// the dot stack above one tick. `dot_plot` (G6) asks "How many measured
/// at least X?" — a threshold filter across the whole dot plot.
///
/// Both reuse the same themed pool below; each theme carries plural-form
/// item + a prompt template so the question reads naturally.

// ─────────────────────────────────────────────────────────────────────────
// Themed contexts
// ─────────────────────────────────────────────────────────────────────────

class _DotPlotTheme {
  const _DotPlotTheme({
    required this.title,
    required this.axisLabel,
    required this.exactPrompt,
    required this.atLeastPrompt,
  });

  /// Header above the plot.
  final String title;

  /// Caption under the x-axis (the units of measurement).
  final String axisLabel;

  /// Returns "How many plants are 6 inches tall?" given `v`.
  final String Function(int v) exactPrompt;

  /// Returns "How many plants are at least 6 inches tall?" given `v`.
  final String Function(int v) atLeastPrompt;
}

final _themes = <_DotPlotTheme>[
  _DotPlotTheme(
    title: 'Plant heights',
    axisLabel: 'Inches',
    exactPrompt: (v) => 'How many plants are $v inches tall?',
    atLeastPrompt: (v) => 'How many plants are at least $v inches tall?',
  ),
  _DotPlotTheme(
    title: 'Books read',
    axisLabel: 'Books',
    exactPrompt: (v) => 'How many kids read $v books?',
    atLeastPrompt: (v) => 'How many kids read at least $v books?',
  ),
  _DotPlotTheme(
    title: 'Pets per family',
    axisLabel: 'Pets',
    exactPrompt: (v) => 'How many families have $v pets?',
    atLeastPrompt: (v) => 'How many families have at least $v pets?',
  ),
];

// ─────────────────────────────────────────────────────────────────────────
// Shared helpers
// ─────────────────────────────────────────────────────────────────────────

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

Map<int, int> _countByValue(List<int> values) {
  final counts = <int, int>{};
  for (final v in values) {
    counts[v] = (counts[v] ?? 0) + 1;
  }
  return counts;
}

// ─────────────────────────────────────────────────────────────────────────
// line_plot_whole (Grade 2)
// ─────────────────────────────────────────────────────────────────────────

/// "How many plants are 6 inches tall?" — count the dots above one
/// integer tick. Range 1..8, 10..15 measurements; the asked value is
/// guaranteed to occur in the data (so the answer is never 0).
GeneratedQuestion lineplotWhole(Random rand) {
  final theme = _themes[rand.nextInt(_themes.length)];
  const minX = 1;
  const maxX = 8;
  final n = rand.nextInt(6) + 10; // 10..15 measurements
  final values = List<int>.generate(n, (_) => rand.nextInt(maxX) + minX);
  final counts = _countByValue(values);

  // Pick the asked value from those that actually occur (so the answer
  // is ≥ 1, which makes for an interesting question).
  final occurred = counts.keys.toList()..sort();
  final askedV = occurred[rand.nextInt(occurred.length)];
  final correct = counts[askedV]!;

  // Misconception distractors:
  //   - count at neighbouring values (kid read the wrong column)
  //   - total count (kid summed instead of read the single column)
  //   - count at the modal value (kid read the tallest stack)
  final modeV = occurred
      .reduce((a, b) => (counts[a] ?? 0) >= (counts[b] ?? 0) ? a : b);
  final candidates = <String>[
    '${counts[askedV - 1] ?? 0}',
    '${counts[askedV + 1] ?? 0}',
    '${counts[modeV]}',
    '$n',
  ];

  return GeneratedQuestion(
    conceptId: 'line_plot_whole',
    prompt: theme.exactPrompt(askedV),
    diagram: DotPlotSpec(
      title: theme.title,
      axisLabel: theme.axisLabel,
      values: values,
      minX: minX,
      maxX: maxX,
    ),
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, candidates),
    explanation: [
      'Find $askedV on the axis.',
      'Count the dots stacked above it: $correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// dot_plot (Grade 6)
// ─────────────────────────────────────────────────────────────────────────

/// "How many plants are at least 6 inches tall?" — count the dots from
/// the asked tick rightward. Same range and dataset size as the G2 case;
/// re-rolls until 1 ≤ correct ≤ n − 1 so the answer isn't trivially 0
/// (everyone shorter) or n (everyone taller).
GeneratedQuestion dotPlot(Random rand) {
  GeneratedQuestion attempt() {
    final theme = _themes[rand.nextInt(_themes.length)];
    const minX = 1;
    const maxX = 9;
    final n = rand.nextInt(6) + 10; // 10..15
    final values = List<int>.generate(n, (_) => rand.nextInt(maxX) + minX);
    final counts = _countByValue(values);

    // Pick a threshold inside [minX+1, maxX] so "at least askedV" excludes
    // at least the leftmost integer.
    final askedV = rand.nextInt(maxX - minX) + minX + 1;
    final atLeast = values.where((v) => v >= askedV).length;
    if (atLeast < 1 || atLeast > n - 1) return dotPlot(rand);

    // Misconception distractors:
    //   - strictly-greater-than (off by one — forgot "at least")
    //   - "at most askedV" (read the wrong direction)
    //   - "exactly askedV" (read just one column)
    //   - total count
    final strictlyGreater = values.where((v) => v > askedV).length;
    final atMost = values.where((v) => v <= askedV).length;
    final exact = counts[askedV] ?? 0;
    final candidates = <String>[
      '$strictlyGreater',
      '$atMost',
      '$exact',
      '$n',
    ];

    return GeneratedQuestion(
      conceptId: 'dot_plot',
      prompt: theme.atLeastPrompt(askedV),
      diagram: DotPlotSpec(
        title: theme.title,
        axisLabel: theme.axisLabel,
        values: values,
        minX: minX,
        maxX: maxX,
      ),
      correctAnswer: '$atLeast',
      distractors: _distinctIntStrings(atLeast, candidates),
      explanation: [
        '"At least $askedV" means $askedV or more.',
        'Count all dots from $askedV rightward: $atLeast.',
      ],
    );
  }

  return attempt();
}
