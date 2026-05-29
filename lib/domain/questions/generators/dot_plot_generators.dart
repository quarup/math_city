import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/fraction.dart';
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
  final modeV = occurred.reduce(
    (a, b) => (counts[a] ?? 0) >= (counts[b] ?? 0) ? a : b,
  );
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

// ─────────────────────────────────────────────────────────────────────────
// Fractional line plots (G4–G5)
// ─────────────────────────────────────────────────────────────────────────

class _FractionalTheme {
  const _FractionalTheme({
    required this.title,
    required this.axisLabel,
    required this.itemPlural, // "pencils"
    required this.measureNoun, // "length"
    required this.measureUnit, // "inches"
  });

  final String title;
  final String axisLabel;
  final String itemPlural;
  final String measureNoun;
  final String measureUnit;
}

final _fractionalThemes = <_FractionalTheme>[
  const _FractionalTheme(
    title: 'Pencil lengths',
    axisLabel: 'Inches',
    itemPlural: 'pencils',
    measureNoun: 'length',
    measureUnit: 'inches',
  ),
  const _FractionalTheme(
    title: 'Ribbon lengths',
    axisLabel: 'Inches',
    itemPlural: 'ribbons',
    measureNoun: 'length',
    measureUnit: 'inches',
  ),
  const _FractionalTheme(
    title: 'Leaf lengths',
    axisLabel: 'Inches',
    itemPlural: 'leaves',
    measureNoun: 'length',
    measureUnit: 'inches',
  ),
];

/// Build a randomized fractional dot-plot dataset:
///   - denom ∈ {2, 4} (halves or quarters; eighths get visually crowded)
///   - display range 1..maxDisplay (no zero values)
///   - n measurements
/// Returns the chosen theme + internal values (numerators with shared denom)
/// + minX/maxX in internal units.
({_FractionalTheme theme, int denom, List<int> values, int minX, int maxX})
_buildFractionalDataset(Random rand) {
  final theme = _fractionalThemes[rand.nextInt(_fractionalThemes.length)];
  final denom = rand.nextBool() ? 2 : 4;
  final maxDisplay = rand.nextInt(2) + 3; // 3..4 inches
  final minInternal = denom; // skip 0 — value ≥ 1 display unit
  final maxInternal = maxDisplay * denom;
  final n = rand.nextInt(5) + 8; // 8..12 measurements
  final values = List<int>.generate(
    n,
    (_) => rand.nextInt(maxInternal - minInternal + 1) + minInternal,
  );
  return (
    theme: theme,
    denom: denom,
    values: values,
    minX: 0,
    maxX: maxInternal,
  );
}

/// Internal-unit value → "1 1/4"-style string via [Fraction.toMixed].
String _formatInternal(int internal, int denom) =>
    Fraction(internal, denom).toMixed();

// ─────────────────────────────────────────────────────────────────────────
// line_plot_fractional (Grade 4)
// ─────────────────────────────────────────────────────────────────────────

/// "How many pencils are 3 1/4 inches long?" — count dots above one
/// fractional tick on a line plot. Same shape as `line_plot_whole` but
/// values land on halves or quarters; the asked value is one that
/// actually occurs (so the answer is always ≥ 1).
GeneratedQuestion lineplotFractional(Random rand) {
  final d = _buildFractionalDataset(rand);
  final counts = _countByValue(d.values);
  final occurred = counts.keys.toList()..sort();
  final askedInternal = occurred[rand.nextInt(occurred.length)];
  final correct = counts[askedInternal]!;
  final askedDisplay = _formatInternal(askedInternal, d.denom);

  // Misconception distractors:
  //   - count at the nearest neighbour subticks (off by 1/denom)
  //   - total count (kid summed instead of read one column)
  //   - the modal count (kid read the tallest stack)
  final modeV = occurred.reduce(
    (a, b) => (counts[a] ?? 0) >= (counts[b] ?? 0) ? a : b,
  );
  final candidates = <String>[
    '${counts[askedInternal - 1] ?? 0}',
    '${counts[askedInternal + 1] ?? 0}',
    '${counts[modeV]}',
    '${d.values.length}',
  ];

  return GeneratedQuestion(
    conceptId: 'line_plot_fractional',
    prompt:
        'How many ${d.theme.itemPlural} are '
        '$askedDisplay ${d.theme.measureUnit} long?',
    diagram: DotPlotSpec(
      title: d.theme.title,
      axisLabel: d.theme.axisLabel,
      values: d.values,
      minX: d.minX,
      maxX: d.maxX,
      denominator: d.denom,
    ),
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, candidates),
    explanation: [
      'Find $askedDisplay on the axis.',
      'Count the dots stacked above it: $correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// line_plot_fraction_word (Grade 4)
// ─────────────────────────────────────────────────────────────────────────

/// "What is the total length of all pencils that are 3 1/4 inches?"
/// — read the count above one tick, multiply by the tick's fractional
/// value, give the total as a mixed number. Re-rolls until the asked
/// value occurs ≥ 2 times so the multiplication is non-trivial.
GeneratedQuestion lineplotFractionWord(Random rand) {
  GeneratedQuestion attempt(int depth) {
    if (depth > 30) {
      // Pathological — fall back to line_plot_fractional shape (still a
      // valid line plot, just easier). Shouldn't happen in practice.
      return lineplotFractional(rand);
    }
    final d = _buildFractionalDataset(rand);
    final counts = _countByValue(d.values);
    // Asked value must (a) occur ≥ 2 times so the multiplication is
    // non-trivial, and (b) be a true fraction (not a whole-inch tick) —
    // otherwise the "just gave the count" distractor can collide with the
    // correct total (count × 1 == count, count × 2 == 2N can collide with
    // count "2" when count=2, etc.).
    final repeats =
        counts.entries
            .where((e) => e.value >= 2 && e.key % d.denom != 0)
            .map((e) => e.key)
            .toList()
          ..sort();
    if (repeats.isEmpty) return attempt(depth + 1);

    final askedInternal = repeats[rand.nextInt(repeats.length)];
    final count = counts[askedInternal]!;
    final askedDisplay = _formatInternal(askedInternal, d.denom);
    // Total = count × value (in internal units), formatted as mixed.
    final totalInternal = count * askedInternal;
    final correct = _formatInternal(totalInternal, d.denom);

    // Misconception distractors:
    //   - just the count (kid stopped after counting dots)
    //   - just the value (kid stopped after reading the tick)
    //   - (count + 1) × value (off-by-one count)
    //   - (count − 1) × value (other off-by-one)
    //   - count × (value with one extra subdivision) — confused with neighbour
    final candidates = <String>[
      '$count',
      askedDisplay,
      _formatInternal((count + 1) * askedInternal, d.denom),
      if (count >= 2) _formatInternal((count - 1) * askedInternal, d.denom),
      _formatInternal(count * (askedInternal + 1), d.denom),
    ];

    return GeneratedQuestion(
      conceptId: 'line_plot_fraction_word',
      prompt:
          'What is the total ${d.theme.measureNoun} of all '
          '${d.theme.itemPlural} that are $askedDisplay '
          '${d.theme.measureUnit}?',
      diagram: DotPlotSpec(
        title: d.theme.title,
        axisLabel: d.theme.axisLabel,
        values: d.values,
        minX: d.minX,
        maxX: d.maxX,
        denominator: d.denom,
      ),
      correctAnswer: correct,
      distractors: _distinctStringDistractors(correct, candidates),
      explanation: [
        'Count the dots above $askedDisplay: $count.',
        'Total = $count × $askedDisplay = $correct ${d.theme.measureUnit}.',
      ],
      answerFormat: AnswerFormat.mixedNumber,
    );
  }

  return attempt(0);
}

// ─────────────────────────────────────────────────────────────────────────
// line_plot_5th_grade_ops (Grade 5)
// ─────────────────────────────────────────────────────────────────────────

/// "What is the difference between the longest and shortest ribbon?"
/// — read the max and min from the line plot, subtract. Re-rolls until
/// the range (max − min) is ≥ 1 display unit so the subtraction is
/// substantive.
GeneratedQuestion lineplot5thGradeOps(Random rand) {
  GeneratedQuestion attempt(int depth) {
    if (depth > 30) return lineplotFractional(rand);
    final d = _buildFractionalDataset(rand);
    final maxV = d.values.reduce(max);
    final minV = d.values.reduce(min);
    if (maxV - minV < d.denom) return attempt(depth + 1); // ≥ 1 inch gap

    final maxDisplay = _formatInternal(maxV, d.denom);
    final minDisplay = _formatInternal(minV, d.denom);
    final rangeInternal = maxV - minV;
    final correct = _formatInternal(rangeInternal, d.denom);

    // Misconception distractors:
    //   - max + min (added instead of subtracted)
    //   - max alone (didn't subtract)
    //   - min alone (didn't subtract)
    //   - max − second-smallest (used the wrong "shortest")
    //   - off-by-one subdivision either way (counted ticks wrong)
    final sortedAscending = [...d.values]..sort();
    final secondSmallest = sortedAscending.firstWhere(
      (v) => v > minV,
      orElse: () => minV,
    );
    final candidates = <String>[
      _formatInternal(maxV + minV, d.denom),
      maxDisplay,
      minDisplay,
      if (secondSmallest != minV)
        _formatInternal(maxV - secondSmallest, d.denom),
      _formatInternal(rangeInternal + 1, d.denom),
      if (rangeInternal > 1) _formatInternal(rangeInternal - 1, d.denom),
    ];

    return GeneratedQuestion(
      conceptId: 'line_plot_5th_grade_ops',
      prompt:
          'What is the difference between the longest and shortest '
          '${_singularize(d.theme.itemPlural)} ${d.theme.measureNoun}?',
      diagram: DotPlotSpec(
        title: d.theme.title,
        axisLabel: d.theme.axisLabel,
        values: d.values,
        minX: d.minX,
        maxX: d.maxX,
        denominator: d.denom,
      ),
      correctAnswer: correct,
      distractors: _distinctStringDistractors(correct, candidates),
      explanation: [
        'Longest is $maxDisplay; shortest is $minDisplay.',
        'Difference: $maxDisplay − $minDisplay = $correct.',
      ],
      answerFormat: AnswerFormat.mixedNumber,
    );
  }

  return attempt(0);
}

/// "pencils" → "pencil"; "leaves" → "leaf"; "ribbons" → "ribbon".
String _singularize(String plural) {
  if (plural == 'leaves') return 'leaf';
  if (plural.endsWith('s')) return plural.substring(0, plural.length - 1);
  return plural;
}

/// Three unique string distractors (any shape) that differ from
/// [correct]. Generators are responsible for supplying enough candidates
/// that at least 3 survive deduplication — this helper throws if not,
/// because silently padding with junk strings would ship a real bug.
List<String> _distinctStringDistractors(
  String correct,
  List<String> candidates,
) {
  final out = <String>[];
  final seen = <String>{correct};
  for (final c in candidates) {
    if (out.length >= 3) break;
    if (seen.add(c)) out.add(c);
  }
  if (out.length < 3) {
    throw StateError(
      'distractor pool exhausted: correct="$correct" '
      'candidates=$candidates remaining=${3 - out.length}',
    );
  }
  return out;
}
