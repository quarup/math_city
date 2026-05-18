import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';
// AnswerFormat / AnswerShape live in generated_question.dart.

/// Diagram-using generators that ride on existing widgets (FractionBar,
/// NumberLine, AreaGrid) plus one text-only stats follow-up.

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
// partition_halves_fourths (G1) — FractionBar, denom ∈ {2, 4}
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion partitionHalvesFourths(Random rand) {
  final d = rand.nextBool() ? 2 : 4;
  final n = rand.nextInt(d - 1) + 1; // 1..d-1
  final correct = '$n/$d';
  return GeneratedQuestion(
    conceptId: 'partition_halves_fourths',
    prompt: 'What fraction of the bar is shaded?',
    diagram: FractionBarSpec(numerator: n, denominator: d),
    correctAnswer: correct,
    distractors: _distinctStrings(correct, [
      '$d/$n',
      '${d - n}/$d',
      '${n + 1}/$d',
      '$n/${d + 1}',
    ]),
    explanation: ['$n out of $d equal parts → $n/$d.'],
    answerFormat: AnswerFormat.fraction,
    answerShape: AnswerShape.exactString,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// partition_thirds (G2) — FractionBar, denom = 3
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion partitionThirds(Random rand) {
  const d = 3;
  final n = rand.nextInt(d - 1) + 1; // 1..2
  final correct = '$n/$d';
  return GeneratedQuestion(
    conceptId: 'partition_thirds',
    prompt: 'What fraction of the bar is shaded?',
    diagram: FractionBarSpec(numerator: n, denominator: d),
    correctAnswer: correct,
    distractors: _distinctStrings(correct, [
      '$d/$n',
      '${d - n}/$d',
      '$n/2',
      '$n/${d + 1}',
    ]),
    explanation: ['$n out of $d equal parts → $n/$d.'],
    answerFormat: AnswerFormat.fraction,
    answerShape: AnswerShape.exactString,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// unit_fraction_intro (G3) — FractionBar, numerator = 1
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion unitFractionIntro(Random rand) {
  final d = [2, 3, 4, 5, 6, 8][rand.nextInt(6)];
  const n = 1;
  final correct = '$n/$d';
  return GeneratedQuestion(
    conceptId: 'unit_fraction_intro',
    prompt: 'What unit fraction is shaded?',
    diagram: FractionBarSpec(numerator: n, denominator: d),
    correctAnswer: correct,
    distractors: _distinctStrings(correct, [
      '$d/$n', // "d out of 1"
      '${d - 1}/$d',
      '$n/${d - 1}',
      '$n/${d + 1}',
    ]),
    explanation: ['1 out of $d equal parts → 1/$d.'],
    answerFormat: AnswerFormat.fraction,
    answerShape: AnswerShape.exactString,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// number_line_add_sub (G2) — NumberLine with a hop showing the action
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion numberLineAddSub(Random rand) {
  final isAdd = rand.nextBool();
  late int a;
  late int b;
  late int correct;
  if (isAdd) {
    a = rand.nextInt(40) + 5; // 5..44
    b = rand.nextInt(20) + 5; // 5..24
    correct = a + b;
  } else {
    a = rand.nextInt(40) + 30; // 30..69
    b = rand.nextInt(a - 5) + 3; // 3..(a-3)
    if (b > 20) b = 20;
    correct = a - b;
  }
  final op = isAdd ? '+' : '−';
  // Choose plot range so both `a` and `correct` are visible.
  const lo = 0;
  final hi = ((isAdd ? correct : a) ~/ 10 + 1) * 10;
  return GeneratedQuestion(
    conceptId: 'number_line_add_sub',
    prompt: '$a $op $b = ?',
    diagram: NumberLineSpec(
      min: lo,
      max: hi,
      divisions: hi - lo,
      markedPoints: [a],
      hops: [
        NumberLineHop(from: a, to: correct, label: isAdd ? '+$b' : '−$b'),
      ],
    ),
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      misconception: isAdd ? a - b : a + b,
    ),
    explanation: ['$a $op $b = $correct'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// decimal_on_number_line (G4) — NumberLine 0..1 with a marked decimal
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion decimalOnNumberLine(Random rand) {
  // Pick divisions = 10 (tenths) or 20 (twentieths shows odd-tenths too).
  final divisions = rand.nextBool() ? 10 : 20;
  final tick = rand.nextInt(divisions - 1) + 1; // 1..(div-1)
  final value = tick / divisions;
  final correct = value.toStringAsFixed(divisions == 10 ? 1 : 2);
  // Distractors at neighboring ticks.
  String fmt(double v) => v.toStringAsFixed(divisions == 10 ? 1 : 2);
  return GeneratedQuestion(
    conceptId: 'decimal_on_number_line',
    prompt: 'What decimal is marked on the number line?',
    diagram: NumberLineSpec(
      min: 0,
      max: 1,
      divisions: divisions,
      markedPoints: [value],
    ),
    correctAnswer: correct,
    distractors: _distinctStrings(correct, [
      fmt((tick - 1) / divisions),
      fmt((tick + 1) / divisions),
      fmt((divisions - tick) / divisions), // complementary tick
      fmt((tick - 2).clamp(0, divisions) / divisions),
      fmt((tick + 2).clamp(0, divisions) / divisions),
      fmt(tick / 10), // mistook division as 10 even when 20
      fmt((tick * 10) / divisions / 10), // off-by-tenfold
    ]),
    explanation: ['The marked tick is at $tick/$divisions = $correct.'],
    answerFormat: AnswerFormat.decimal,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// integers_on_number_line (G6) — NumberLine spanning negatives
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion integersOnNumberLine(Random rand) {
  const lo = -10;
  const hi = 10;
  int value;
  do {
    value = rand.nextInt(hi - lo + 1) + lo; // -10..10
  } while (value == 0); // exclude 0 (trivial)
  final correct = value < 0 ? '−${-value}' : '$value';
  String fmt(int v) => v < 0 ? '−${-v}' : '$v';
  return GeneratedQuestion(
    conceptId: 'integers_on_number_line',
    prompt: 'What integer is marked on the number line?',
    diagram: NumberLineSpec(
      min: lo,
      max: hi,
      divisions: hi - lo,
      markedPoints: [value],
    ),
    correctAnswer: correct,
    distractors: _distinctStrings(correct, [
      fmt(-value), // sign-error
      fmt(value + 1),
      fmt(value - 1),
      '0',
    ]),
    explanation: ['The marked point is at $value.'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// area_rectangle_count_squares (G3) — AreaGrid fully shaded, count squares
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion areaRectangleCountSquares(Random rand) {
  final rows = rand.nextInt(5) + 2; // 2..6
  final cols = rand.nextInt(5) + 2; // 2..6
  final correct = rows * cols;
  return GeneratedQuestion(
    conceptId: 'area_rectangle_count_squares',
    prompt: 'How many unit squares are in this rectangle?',
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
      misconception: rows + cols, // added instead of multiplied
    ),
    explanation: [
      '$rows rows × $cols columns = $correct squares.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// partition_into_rows_columns (G2) — AreaGrid; "rows × cols = ?"
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion partitionIntoRowsColumns(Random rand) {
  final rows = rand.nextInt(4) + 2; // 2..5
  final cols = rand.nextInt(4) + 2;
  final correct = rows * cols;
  return GeneratedQuestion(
    conceptId: 'partition_into_rows_columns',
    prompt:
        'A rectangle is partitioned into $rows rows and $cols columns. '
        'How many squares is that in total?',
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
// inference_from_sample (G7) — text-only proportional inference
// ─────────────────────────────────────────────────────────────────────────

GeneratedQuestion inferenceFromSample(Random rand) {
  // Sample size in {50, 100} for clean fractions.
  final sampleSize = rand.nextBool() ? 50 : 100;
  // Proportion expressed as count in [10, sampleSize - 10].
  final inSample = rand.nextInt(sampleSize - 19) + 10;
  // Population is a clean multiple of sampleSize.
  final mult = rand.nextInt(4) + 2; // 2..5
  final population = sampleSize * mult;
  final correct = inSample * mult;
  return GeneratedQuestion(
    conceptId: 'inference_from_sample',
    prompt:
        'In a random sample of $sampleSize students at a school, '
        '$inSample reported they ride the bus. About how many of the '
        '$population students at the school ride the bus?',
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      // Misconception: used the sample count as-is.
      misconception: inSample,
    ),
    explanation: [
      'Proportion in sample: $inSample / $sampleSize.',
      'Scale up: $inSample × $mult = $correct.',
    ],
  );
}
