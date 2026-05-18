import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// G6 ratio generators using the new TapeDiagram and DoubleNumberLine
/// widgets: ratio_table, double_number_line. CCSS 6.RP.A.3.

const List<(String, String)> _ratioContexts = [
  ('cups of flour', 'cups of sugar'),
  ('apples', 'oranges'),
  ('red marbles', 'blue marbles'),
  ('miles', 'gallons'),
  ('boys', 'girls'),
];

// ─────────────────────────────────────────────────────────────────────────
// ratio_table (G6)
// ─────────────────────────────────────────────────────────────────────────

/// "A recipe uses a {item1} for every b {item2}. If you have a·k
/// {item1}, how many {item2}?" Answer: b·k.
///
/// The tape diagram shows the unit ratio a:b; the scaled value comes
/// from the prompt. Misconception: added the scale instead of
/// multiplying (a + k or b + k) — the integer-distractor pool covers
/// nearby values which catches this.
GeneratedQuestion ratioTable(Random rand) {
  // Small ratio so the kid can verify by counting unit boxes.
  int a;
  int b;
  do {
    a = rand.nextInt(4) + 2; // 2..5
    b = rand.nextInt(4) + 2;
  } while (a == b);
  final k = rand.nextInt(4) + 2; // 2..5
  final ctx = _ratioContexts[rand.nextInt(_ratioContexts.length)];
  final answer = b * k;
  return GeneratedQuestion(
    conceptId: 'ratio_table',
    prompt:
        'A recipe uses $a ${ctx.$1} for every $b ${ctx.$2}. If you '
        'use ${a * k} ${ctx.$1}, how many ${ctx.$2} do you need?',
    diagram: TapeDiagramSpec(
      topUnits: a,
      bottomUnits: b,
      topLabel: ctx.$1,
      bottomLabel: ctx.$2,
    ),
    correctAnswer: '$answer',
    distractors: integerDistractorsWith(
      answer,
      rand,
      // Misconception: kid uses the unscaled ratio value (didn't apply
      // the multiplier k).
      misconception: b,
    ),
    explanation: [
      'The ratio is $a:$b, so each $a ${ctx.$1} pairs with $b ${ctx.$2}.',
      '${a * k} = $a × $k, so ${ctx.$2} = $b × $k = $answer.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// double_number_line (G6)
// ─────────────────────────────────────────────────────────────────────────

/// Same proportional reasoning as `ratio_table`, but presented as a
/// double number line with the kid reading the position of one
/// quantity off the other. CCSS 6.RP.A.3.
GeneratedQuestion doubleNumberLine(Random rand) {
  int a;
  int b;
  do {
    a = rand.nextInt(4) + 2; // 2..5
    b = rand.nextInt(4) + 2;
  } while (a == b);
  // Show 4 tick positions: 0, a, 2a, 3a (top) and 0, b, 2b, 3b (bottom).
  // The kid is asked for the bottom value when top = 4a (off the
  // diagram), so they have to reason proportionally beyond what's
  // labelled.
  final ctx = _ratioContexts[rand.nextInt(_ratioContexts.length)];
  const k = 4;
  final answer = b * k;
  return GeneratedQuestion(
    conceptId: 'double_number_line',
    prompt:
        'The double number line shows the relationship between '
        '${ctx.$1} and ${ctx.$2}. How many ${ctx.$2} go with ${a * k} '
        '${ctx.$1}?',
    diagram: DoubleNumberLineSpec(
      topValues: [0, a, 2 * a, 3 * a],
      bottomValues: [0, b, 2 * b, 3 * b],
      topLabel: ctx.$1,
      bottomLabel: ctx.$2,
    ),
    correctAnswer: '$answer',
    distractors: integerDistractorsWith(
      answer,
      rand,
      // Misconception: read the last labelled value (3·b) instead of
      // extrapolating to 4·b.
      misconception: 3 * b,
    ),
    explanation: [
      'Each step adds $a ${ctx.$1} on top and $b ${ctx.$2} on the bottom.',
      'After 4 steps: ${a * k} ${ctx.$1} and $answer ${ctx.$2}.',
    ],
  );
}
