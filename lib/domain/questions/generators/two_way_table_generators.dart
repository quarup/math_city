import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/fraction.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// Two-way-table generators (Grade 8, `stats` category).
///
/// `two_way_table_construct` shows a filled 2×2 frequency table and
/// asks for a specific cell's count by row+column description.
/// `two_way_relative_frequency` asks for a within-row (or within-column)
/// fraction — a relative frequency that requires reading two cells and
/// reducing the resulting fraction.

class _TableTheme {
  const _TableTheme({
    required this.title,
    required this.rowLabels,
    required this.colLabels,
    required this.rowSubject,
    required this.colVerb,
  });

  final String title;
  final List<String> rowLabels; // e.g. ["Boys", "Girls"]
  final List<String> colLabels; // e.g. ["Plays sport", "Doesn't"]
  final String rowSubject; // "students" — used in prompts
  final String colVerb; // "play a sport" — used in prompts (cap-sensitive)
}

const _themes = <_TableTheme>[
  _TableTheme(
    title: 'Students surveyed: do you play a sport?',
    rowLabels: ['Boys', 'Girls'],
    colLabels: ['Plays', "Doesn't play"],
    rowSubject: 'students',
    colVerb: 'play a sport',
  ),
  _TableTheme(
    title: 'Pet ownership',
    rowLabels: ['Adults', 'Kids'],
    colLabels: ['Has pet', 'No pet'],
    rowSubject: 'people',
    colVerb: 'have a pet',
  ),
  _TableTheme(
    title: 'Did students walk to school?',
    rowLabels: ['Grade 5', 'Grade 6'],
    colLabels: ['Walked', 'Did not walk'],
    rowSubject: 'students',
    colVerb: 'walked to school',
  ),
];

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

List<String> _distinctStrings(String correct, List<String> candidates) {
  final out = <String>[];
  final seen = <String>{correct};
  for (final c in candidates) {
    if (out.length >= 3) break;
    if (seen.add(c)) out.add(c);
  }
  if (out.length < 3) {
    throw StateError(
      'distractor pool exhausted: correct="$correct" candidates=$candidates',
    );
  }
  return out;
}

/// Build a 2×2 count matrix with all 4 cells distinct in [3, 20] so
/// wrong-cell distractors don't accidentally match the answer.
List<List<int>> _buildCounts(Random rand) {
  for (var attempt = 0; attempt < 30; attempt++) {
    final pool = List.generate(18, (i) => i + 3)..shuffle(rand);
    final picks = pool.take(4).toList();
    if (picks.toSet().length == 4) {
      return [
        [picks[0], picks[1]],
        [picks[2], picks[3]],
      ];
    }
  }
  throw StateError('could not pick 4 distinct counts');
}

// ─────────────────────────────────────────────────────────────────────────
// two_way_table_construct (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// "How many {row label} {column description}?" — read one cell of the
/// 2×2 table. The diagram shows the full table with row and column
/// totals; the kid has to identify the right cell.
GeneratedQuestion twoWayTableConstruct(Random rand) {
  final theme = _themes[rand.nextInt(_themes.length)];
  final counts = _buildCounts(rand);

  final r = rand.nextInt(2);
  final c = rand.nextInt(2);
  final correct = counts[r][c];

  // Build a prompt phrasing that picks "X who [col]" or "X who [don't
  // col]" from the column index. Reuse the theme's verb for column 0;
  // negate for column 1.
  final positive = c == 0;
  final colPhrase = positive
      ? 'who ${theme.colVerb}'
      : "who don't ${theme.colVerb}";

  // Misconception distractors: counts at other cells + row total + col
  // total + grand total.
  final rowTotal = counts[r][0] + counts[r][1];
  final colTotal = counts[0][c] + counts[1][c];
  final grand = counts[0][0] + counts[0][1] + counts[1][0] + counts[1][1];
  final candidates = <String>[
    for (var rr = 0; rr < 2; rr++)
      for (var cc = 0; cc < 2; cc++)
        if (!(rr == r && cc == c)) '${counts[rr][cc]}',
    '$rowTotal',
    '$colTotal',
    '$grand',
  ];

  return GeneratedQuestion(
    conceptId: 'two_way_table_construct',
    prompt:
        'How many ${theme.rowLabels[r].toLowerCase()} $colPhrase?',
    diagram: TwoWayTableSpec(
      title: theme.title,
      rowLabels: theme.rowLabels,
      colLabels: theme.colLabels,
      counts: counts,
    ),
    correctAnswer: '$correct',
    distractors: _distinctIntStrings(correct, candidates),
    explanation: [
      'Row ${theme.rowLabels[r]} × col ${theme.colLabels[c]} = $correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// two_way_relative_frequency (Grade 8)
// ─────────────────────────────────────────────────────────────────────────

/// "Of all {row}, what fraction {col}?" Reduces to numerator/denominator
/// where numerator = single cell, denominator = row total (or column
/// total — randomized 50/50).
GeneratedQuestion twoWayRelativeFrequency(Random rand) {
  final theme = _themes[rand.nextInt(_themes.length)];
  final counts = _buildCounts(rand);

  final r = rand.nextInt(2);
  final c = rand.nextInt(2);
  // 50% within-row, 50% within-column.
  final byRow = rand.nextBool();
  final numerator = counts[r][c];
  final denominator = byRow
      ? counts[r][0] + counts[r][1]
      : counts[0][c] + counts[1][c];

  final correctFrac = Fraction(numerator, denominator);
  final correct = correctFrac.toCanonical();

  // Misconception distractors: the OTHER axis fraction, numerator over
  // grand total, swapped fraction.
  final otherDenom = byRow
      ? counts[0][c] + counts[1][c]
      : counts[r][0] + counts[r][1];
  final grand = counts[0][0] + counts[0][1] + counts[1][0] + counts[1][1];
  final candidates = <String>[
    Fraction(numerator, otherDenom).toCanonical(),
    Fraction(numerator, grand).toCanonical(),
    Fraction(denominator, numerator + denominator).toCanonical(),
    Fraction(denominator - numerator, denominator).toCanonical(),
    Fraction(numerator + 1, denominator).toCanonical(),
  ];

  final positive = c == 0;
  final colPhrase = positive ? theme.colVerb : "don't ${theme.colVerb}";

  String prompt;
  if (byRow) {
    prompt =
        'Of all ${theme.rowLabels[r].toLowerCase()}, what fraction $colPhrase?';
  } else {
    final whoVerb = positive ? theme.colVerb : "don't ${theme.colVerb}";
    prompt =
        'Of all ${theme.rowSubject} who $whoVerb, '
        'what fraction are ${theme.rowLabels[r].toLowerCase()}?';
  }

  return GeneratedQuestion(
    conceptId: 'two_way_relative_frequency',
    prompt: prompt,
    diagram: TwoWayTableSpec(
      title: theme.title,
      rowLabels: theme.rowLabels,
      colLabels: theme.colLabels,
      counts: counts,
    ),
    correctAnswer: correct,
    distractors: _distinctStrings(correct, candidates),
    explanation: [
      'Cell ${theme.rowLabels[r]} ∩ ${theme.colLabels[c]} = $numerator.',
      'Total of the ${byRow ? "row" : "column"} = $denominator.',
      'Fraction: $numerator/$denominator = $correct.',
    ],
    answerFormat: AnswerFormat.fraction,
  );
}
