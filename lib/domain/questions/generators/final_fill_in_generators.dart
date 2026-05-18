import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// Last-mile fill-in generators (Chunk 68): K-G5 concepts that don't
/// yet have their dedicated widget variants (two-array, Box3D, etc.)
/// but can ship text-driven with an existing diagram for context.

// ─────────────────────────────────────────────────────────────────────────
// compare_groups_by_count (K)
// ─────────────────────────────────────────────────────────────────────────

/// "Group A has a {items}. Group B has b {items}. Which group has
/// more?" CCSS K.CC.C.6.
///
/// Text-only in v1 — the AreaGrid widget can render one count, but
/// not two side-by-side groups. Adding a dedicated two-array visual
/// is the obvious next step but out of scope here.
const List<String> _comparePoolItems = [
  'apples',
  'cookies',
  'marbles',
  'crayons',
  'stickers',
  'flowers',
];

GeneratedQuestion compareGroupsByCount(Random rand) {
  final item = _comparePoolItems[rand.nextInt(_comparePoolItems.length)];
  // Two distinct counts in 1..10.
  final a = rand.nextInt(10) + 1;
  var b = rand.nextInt(10) + 1;
  while (b == a) {
    b = rand.nextInt(10) + 1;
  }
  final aWins = a > b;
  final answer = aWins ? 'Group A' : 'Group B';
  return GeneratedQuestion(
    conceptId: 'compare_groups_by_count',
    prompt:
        'Group A has $a $item. Group B has $b $item. Which group has more?',
    correctAnswer: answer,
    distractors: stringDistractorsFromPool(
      answer,
      const ['Group A', 'Group B', 'They are equal', 'Cannot tell'],
      rand,
    ),
    answerFormat: AnswerFormat.string,
    explanation: ['$a vs $b → ${aWins ? a : b} is more.'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// measure_length_units (G1)
// ─────────────────────────────────────────────────────────────────────────

/// "The {object} is measured with same-size unit blocks. How many
/// blocks long is it?" — the Ruler widget renders the object bar
/// above ticks at every whole unit; the kid reads the marked length.
/// CCSS 1.MD.A.2.
const List<String> _objectsToMeasure = [
  'pencil',
  'eraser',
  'marker',
  'crayon',
  'ribbon',
];

GeneratedQuestion measureLengthUnits(Random rand) {
  final obj = _objectsToMeasure[rand.nextInt(_objectsToMeasure.length)];
  final marked = rand.nextInt(7) + 2; // 2..8 unit blocks
  // Pick a ruler total just larger than the marked length so the
  // remaining unmarked space is visible too.
  final total = (marked + 2).clamp(6, 12);
  return GeneratedQuestion(
    conceptId: 'measure_length_units',
    prompt:
        'The $obj is measured with same-size unit blocks. How many blocks '
        'long is the $obj?',
    diagram: RulerSpec(
      totalLength: total,
      markedLength: marked,
      unitLabel: 'blocks',
    ),
    correctAnswer: '$marked',
    // Misconception: kids often count the tick marks instead of the
    // intervals between them (off-by-one too high).
    distractors: integerDistractorsWith(
      marked,
      rand,
      misconception: marked + 1,
    ),
    explanation: [
      'Count the unit blocks under the bar — the $obj spans $marked.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// volume_composite (G5)
// ─────────────────────────────────────────────────────────────────────────

/// "A composite figure is made of two rectangular prisms. Prism 1 is
/// l1·w1·h1 cubic units. Prism 2 is l2·w2·h2. What is the total
/// volume?" → V1 + V2. CCSS 5.MD.C.5.c.
///
/// Text-driven (the Shape widget doesn't render composite prisms in
/// v1; the schematic cube is shown as context).
GeneratedQuestion volumeComposite(Random rand) {
  final l1 = rand.nextInt(4) + 2; // 2..5
  final w1 = rand.nextInt(4) + 2;
  final h1 = rand.nextInt(3) + 2; // 2..4
  final l2 = rand.nextInt(4) + 2;
  final w2 = rand.nextInt(4) + 2;
  final h2 = rand.nextInt(3) + 2;
  final v1 = l1 * w1 * h1;
  final v2 = l2 * w2 * h2;
  final total = v1 + v2;
  return GeneratedQuestion(
    conceptId: 'volume_composite',
    prompt:
        'A composite figure is made of two rectangular prisms. The first '
        'is $l1 × $w1 × $h1 cubic units. The second is $l2 × $w2 × $h2 '
        'cubic units. What is the total volume?',
    diagram: const ShapeSpec(kind: ShapeKind.cube),
    correctAnswer: '$total',
    distractors: integerDistractorsWith(
      total,
      rand,
      // Misconception: kid computed just one of the two prisms.
      misconception: v1,
    ),
    explanation: [
      'Prism 1: $l1 × $w1 × $h1 = $v1.',
      'Prism 2: $l2 × $w2 × $h2 = $v2.',
      'Total: $v1 + $v2 = $total.',
    ],
  );
}
