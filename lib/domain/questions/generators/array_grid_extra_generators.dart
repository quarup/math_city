import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// Diagram-using generators that ride on AreaGrid (array_grid),
/// Clock (clock_analog), FractionBar (fraction_bar at tenths/hundredths),
/// and NumberLine (irrational approximation).

List<String> _distinctStrings(String correct, List<String> candidates) {
  final out = <String>[];
  final seen = <String>{correct};
  for (final c in candidates) {
    if (out.length >= 3) break;
    if (seen.add(c)) out.add(c);
  }
  return out.take(3).toList();
}

// ─────────────────────────────────────────────────────────────────────────
// count_objects_to_10 (K) — count shaded cells (≤ 10)
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion countObjectsTo10(Random rand) {
  final n = rand.nextInt(9) + 2; // 2..10
  // Single-row layout if n ≤ 5, else 2 rows.
  late int rows;
  late int cols;
  if (n <= 5) {
    rows = 1;
    cols = n;
  } else {
    rows = 2;
    cols = (n + 1) ~/ 2; // 3 cols for 5..6, 4 cols for 7..8, 5 cols for 9..10
  }
  // shadedRows × shadedCols may over-shade in the 2-row case; clamp.
  final correct = n;
  return GeneratedQuestion(
    conceptId: 'count_objects_to_10',
    prompt: 'How many objects are shown?',
    diagram: AreaGridSpec(
      rows: rows,
      cols: cols,
      shadedRows: rows,
      shadedCols: cols,
    ),
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      misconception: rows * cols, // gave total cells (over-counted)
    ),
    explanation: ['There are $correct objects shaded.'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// count_objects_to_20 (K) — same layout, 11..20
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion countObjectsTo20(Random rand) {
  final n = rand.nextInt(10) + 11; // 11..20
  // 2 rows × cols (cols = ceil(n/2)).
  const rows = 2;
  final cols = (n + 1) ~/ 2;
  final correct = n;
  return GeneratedQuestion(
    conceptId: 'count_objects_to_20',
    prompt: 'How many objects are shown?',
    diagram: AreaGridSpec(
      rows: rows,
      cols: cols,
      shadedRows: rows,
      shadedCols: cols,
    ),
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      misconception: rows * cols,
    ),
    explanation: ['There are $correct objects shaded.'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// equal_groups_intro (G2)
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion equalGroupsIntro(Random rand) {
  final rows = rand.nextInt(4) + 2; // 2..5
  final cols = rand.nextInt(4) + 2;
  final correct = rows * cols;
  return GeneratedQuestion(
    conceptId: 'equal_groups_intro',
    prompt:
        'There are $rows equal groups, with $cols objects in each group. '
        'How many objects in all?',
    diagram: AreaGridSpec(
      rows: rows,
      cols: cols,
      shadedRows: rows,
      shadedCols: cols,
    ),
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      misconception: rows + cols,
    ),
    explanation: ['$rows × $cols = $correct.'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// array_repeated_addition (G2)
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion arrayRepeatedAddition(Random rand) {
  final rows = rand.nextInt(4) + 2; // 2..5
  final cols = rand.nextInt(4) + 2;
  final correct = List.filled(rows, '$cols').join(' + ');
  return GeneratedQuestion(
    conceptId: 'array_repeated_addition',
    prompt:
        'This array has $rows rows and $cols columns. Which repeated '
        'addition shows the total?',
    diagram: AreaGridSpec(
      rows: rows,
      cols: cols,
      shadedRows: rows,
      shadedCols: cols,
    ),
    correctAnswer: correct,
    distractors: _distinctStrings(correct, [
      List.filled(cols, '$rows').join(' + '), // wrong axis (rows ↔ cols)
      List.filled(rows, '${cols + 1}').join(' + '), // each row +1
      if (cols > 1) List.filled(rows, '${cols - 1}').join(' + '),
      List.filled(rows + 1, '$cols').join(' + '), // extra row
      if (rows > 1) List.filled(rows - 1, '$cols').join(' + '),
      '$rows + $cols',
      '${rows * cols}',
    ]),
    explanation: [
      'Each row has $cols. With $rows rows, the total is $correct.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// mult_meaning_groups (G3)
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion multMeaningGroups(Random rand) {
  final rows = rand.nextInt(7) + 3; // 3..9
  final cols = rand.nextInt(7) + 3;
  final correct = '$rows × $cols';
  return GeneratedQuestion(
    conceptId: 'mult_meaning_groups',
    prompt: 'Which multiplication describes this array (rows × columns)?',
    diagram: AreaGridSpec(
      rows: rows,
      cols: cols,
      shadedRows: rows,
      shadedCols: cols,
    ),
    correctAnswer: correct,
    distractors: _distinctStrings(correct, [
      '${rows + 1} × $cols',
      '$rows × ${cols + 1}',
      '${rows + cols} × 1',
      '${rows * cols} × 1', // total × 1
    ]),
    explanation: [
      '$rows rows of $cols each → $rows × $cols.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// div_meaning_share (G3)
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion divMeaningShare(Random rand) {
  final rows = rand.nextInt(5) + 2; // 2..6 (groups)
  final cols = rand.nextInt(5) + 2; // 2..6 (per group)
  final total = rows * cols;
  return GeneratedQuestion(
    conceptId: 'div_meaning_share',
    prompt:
        '$total objects are shared equally into $rows groups. '
        'How many objects per group?',
    diagram: AreaGridSpec(
      rows: rows,
      cols: cols,
      shadedRows: rows,
      shadedCols: cols,
    ),
    correctAnswer: '$cols',
    distractors: integerDistractorsWith(
      cols,
      rand,
      misconception: rows,
    ),
    explanation: ['$total ÷ $rows = $cols.'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// div_meaning_grouping (G3)
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion divMeaningGrouping(Random rand) {
  final rows = rand.nextInt(5) + 2; // 2..6 (groups)
  final cols = rand.nextInt(5) + 2; // 2..6 (per group)
  final total = rows * cols;
  return GeneratedQuestion(
    conceptId: 'div_meaning_grouping',
    prompt:
        '$total objects are put into groups of $cols. '
        'How many groups are there?',
    diagram: AreaGridSpec(
      rows: rows,
      cols: cols,
      shadedRows: rows,
      shadedCols: cols,
    ),
    correctAnswer: '$rows',
    distractors: integerDistractorsWith(
      rows,
      rand,
      misconception: cols,
    ),
    explanation: ['$total ÷ $cols = $rows.'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// distributive_mult_over_add (G3)
// ─────────────────────────────────────────────────────────────────────────

/// "4 × 7 = 4 × (5 + 2). What is 4 × 5 + 4 × 2?" → 28. Visualizes the
/// split of a (rows × cols) array into (rows × splitL) + (rows × splitR).
/// AreaGrid here renders the *full* array; the prompt names the split.
GeneratedQuestion distributiveMultOverAdd(Random rand) {
  final a = rand.nextInt(7) + 3; // 3..9
  final c = rand.nextInt(7) + 3; // 3..9 (whole second factor)
  // Split c into two positives.
  late int x;
  late int y;
  do {
    x = rand.nextInt(c - 1) + 1; // 1..c-1
    y = c - x;
  } while (x == 0 || y == 0);
  final correct = a * c;
  return GeneratedQuestion(
    conceptId: 'distributive_mult_over_add',
    prompt: '$a × $c = $a × ($x + $y) = $a × $x + $a × $y = ?',
    diagram: AreaGridSpec(
      rows: a,
      cols: c,
      shadedRows: a,
      shadedCols: c,
    ),
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      misconception: a * x + y, // only multiplied the first part
    ),
    explanation: [
      '$a × $x = ${a * x}',
      '$a × $y = ${a * y}',
      '${a * x} + ${a * y} = $correct',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// time_to_minute (G3) — Clock, all 60 minutes
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion timeToMinute(Random rand) {
  final hour = rand.nextInt(12) + 1; // 1..12
  final minute = rand.nextInt(60); // 0..59
  final correct = _formatClockTime(hour, minute);
  final altMinutes = <int>{
    (minute + 1) % 60,
    (minute - 1 + 60) % 60,
    (minute + 5) % 60,
    (minute + 30) % 60,
  }..remove(minute);
  final pool = <String>[
    for (final m in altMinutes) _formatClockTime(hour, m),
    _formatClockTime((hour % 12) + 1, minute),
    _formatClockTime(hour == 1 ? 12 : hour - 1, minute),
  ];
  return GeneratedQuestion(
    conceptId: 'time_to_minute',
    prompt: 'What time is it?',
    diagram: ClockSpec(hour: hour, minute: minute),
    correctAnswer: correct,
    distractors: _distinctStrings(correct, pool),
    explanation: ['It is $correct.'],
    answerFormat: AnswerFormat.string,
  );
}

String _formatClockTime(int h, int m) {
  final mm = m.toString().padLeft(2, '0');
  return '$h:$mm';
}

String _elapsedExplanation(
  int startHour,
  int startMin,
  int deltaHr,
  int deltaMin,
  String correct,
) {
  final hourPart = deltaHr == 0 ? '' : '$deltaHr h and ';
  final start = _formatClockTime(startHour, startMin);
  return 'Add $hourPart$deltaMin min to $start → $correct.';
}

// ─────────────────────────────────────────────────────────────────────────
// elapsed_time (G3) — Clock, "what time will it be in N hours/minutes"
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion elapsedTime(Random rand) {
  final startHour = rand.nextInt(11) + 1; // 1..11
  final startMin = rand.nextInt(12) * 5; // 0, 5, ..., 55
  final deltaHr = rand.nextInt(2); // 0..1 hours added
  final deltaMin = (rand.nextInt(5) + 1) * 5; // 5, 10, ..., 25 minutes
  final totalMinutes = (startHour * 60 + startMin) + deltaHr * 60 + deltaMin;
  // Keep the result within a sensible 12-hour clock range.
  final endHour = ((totalMinutes ~/ 60 - 1) % 12) + 1;
  final endMin = totalMinutes % 60;
  final correct = _formatClockTime(endHour, endMin);
  return GeneratedQuestion(
    conceptId: 'elapsed_time',
    prompt:
        'It is ${_formatClockTime(startHour, startMin)}. '
        'What time will it be in '
        '${deltaHr == 0 ? "" : "$deltaHr hour${deltaHr > 1 ? "s" : ""} and "}'
        '$deltaMin minutes?',
    diagram: ClockSpec(hour: startHour, minute: startMin),
    correctAnswer: correct,
    distractors: _distinctStrings(correct, [
      _formatClockTime(endHour, (endMin - 5 + 60) % 60),
      _formatClockTime(endHour, (endMin + 5) % 60),
      _formatClockTime((endHour % 12) + 1, endMin),
      _formatClockTime(endHour == 1 ? 12 : endHour - 1, endMin),
    ]),
    explanation: [
      _elapsedExplanation(
        startHour,
        startMin,
        deltaHr,
        deltaMin,
        correct,
      ),
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// fraction_denom_10_100 (G4) — FractionBar with denom = 10
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion fractionDenom10_100(Random rand) {
  // Denominator restricted to 10 (visually readable; 100 would be too
  // dense to count). Numerator ∈ [1, 9].
  const d = 10;
  final n = rand.nextInt(d - 1) + 1; // 1..9
  final correct = '$n/$d';
  return GeneratedQuestion(
    conceptId: 'fraction_denom_10_100',
    prompt: 'What fraction is shaded? (Denominator = 10)',
    diagram: FractionBarSpec(numerator: n, denominator: d),
    correctAnswer: correct,
    distractors: _distinctStrings(correct, [
      '$d/$n',
      '${d - n}/$d',
      '${n + 1}/$d',
      '$n/${d - 1}',
    ]),
    explanation: ['$n out of $d equal parts → $n/$d.'],
    answerFormat: AnswerFormat.fraction,
    answerShape: AnswerShape.exactString,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// approximate_irrational (G8) — NumberLine with marked irrational
// ─────────────────────────────────────────────────────────────────────────

/// "Between which two integers is √7?" → 2 and 3. We use the
/// NumberLine to *also* mark the irrational's approximate position so
/// the kid sees it. Answer is the pair of integers.
GeneratedQuestion approximateIrrational(Random rand) {
  // Pick a non-perfect-square radicand in [2, 60].
  late int n;
  late int floor;
  do {
    n = rand.nextInt(59) + 2; // 2..60
    floor = sqrt(n).floor();
  } while (floor * floor == n); // skip perfect squares
  final value = sqrt(n);
  final lo = floor;
  final hi = floor + 1;
  final correct = '$lo and $hi';
  return GeneratedQuestion(
    conceptId: 'approximate_irrational',
    prompt: 'Between which two consecutive integers does √$n lie?',
    diagram: NumberLineSpec(
      min: lo - 1,
      max: hi + 1,
      divisions: 3,
      markedPoints: [value],
    ),
    correctAnswer: correct,
    distractors: _distinctStrings(correct, [
      '${lo - 1} and $lo',
      '$hi and ${hi + 1}',
      '$lo and ${hi + 1}',
    ]),
    explanation: [
      '$lo² = ${lo * lo}, $hi² = ${hi * hi}.',
      '${lo * lo} < $n < ${hi * hi}, so $lo < √$n < $hi.',
    ],
    answerFormat: AnswerFormat.string,
  );
}
