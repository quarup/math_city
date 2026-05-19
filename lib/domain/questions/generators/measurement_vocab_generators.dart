import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// K-G1 measurement-vocabulary generators. `describe_attribute` is
/// text-only; the two comparison generators below render a proportional
/// [LengthBarsSpec] diagram so the kid sees the relative lengths
/// instead of reading them numerically out of the prompt.

// ─────────────────────────────────────────────────────────────────────────
// describe_attribute (K)
// ─────────────────────────────────────────────────────────────────────────

/// "Which attribute would you use to measure a {thing}?" — MC over
/// length / weight / capacity / temperature. CCSS K.MD.A.1.
const List<(String, String)> _attributeScenarios = [
  // Each row: (item phrase, correct attribute).
  ('how tall a tree is', 'length'),
  ('how long a string is', 'length'),
  ('how heavy a book is', 'weight'),
  ('how heavy a watermelon is', 'weight'),
  ('how much water fits in a bucket', 'capacity'),
  ('how much juice is in a bottle', 'capacity'),
  ('how cold the room is', 'temperature'),
  ('how warm a cup of tea is', 'temperature'),
];

GeneratedQuestion describeAttribute(Random rand) {
  final s = _attributeScenarios[rand.nextInt(_attributeScenarios.length)];
  return GeneratedQuestion(
    conceptId: 'describe_attribute',
    prompt: 'Which attribute do you measure to find out ${s.$1}?',
    correctAnswer: s.$2,
    distractors: stringDistractorsFromPool(
      s.$2,
      const ['length', 'weight', 'capacity', 'temperature'],
      rand,
    ),
    answerFormat: AnswerFormat.string,
    explanation: [
      'To find out ${s.$1}, measure its ${s.$2}.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// compare_two_objects (K)
// ─────────────────────────────────────────────────────────────────────────

/// "Which is longer/heavier/bigger?" — the two objects' lengths are
/// shown as proportional bars on a [LengthBarsSpec] diagram so the
/// kid compares them visually. CCSS K.MD.A.2.
const List<(String, String, String, String)> _pairScenarios = [
  // (subject1, subject2, unit noun, comparison word)
  ('the pencil', 'the crayon', 'cm', 'longer'),
  ('the rope', 'the string', 'feet', 'longer'),
  ('the cat', 'the dog', 'pounds', 'heavier'),
  ('the apple', 'the orange', 'grams', 'heavier'),
  ('the red ribbon', 'the blue ribbon', 'inches', 'longer'),
];

GeneratedQuestion compareTwoObjects(Random rand) {
  final p = _pairScenarios[rand.nextInt(_pairScenarios.length)];
  // Two distinct lengths in 2..20.
  final a = rand.nextInt(19) + 2;
  var b = rand.nextInt(19) + 2;
  while (b == a) {
    b = rand.nextInt(19) + 2;
  }
  final s1Larger = a > b;
  final answer = s1Larger ? p.$1 : p.$2;
  final compWord = p.$4;
  return GeneratedQuestion(
    conceptId: 'compare_two_objects',
    prompt: 'Which is $compWord?',
    diagram: LengthBarsSpec(
      unit: p.$3,
      bars: [
        LengthBar(label: p.$1, length: a),
        LengthBar(label: p.$2, length: b),
      ],
    ),
    correctAnswer: answer,
    distractors: stringDistractorsFromPool(
      answer,
      [p.$1, p.$2, 'they are the same', 'cannot tell'],
      rand,
    ),
    answerFormat: AnswerFormat.string,
    explanation: [
      '${s1Larger ? a : b} > ${s1Larger ? b : a}, so $answer is $compWord.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// order_three_objects_length (G1)
// ─────────────────────────────────────────────────────────────────────────

/// "Which is the shortest/longest?" — the three objects' lengths are
/// shown as proportional bars on a [LengthBarsSpec] diagram. CCSS 1.MD.A.1.
const List<(String, String, String, String)> _tripleScenarios = [
  // (subject1, subject2, subject3, unit noun)
  ('rope A', 'rope B', 'rope C', 'feet'),
  ('the pencil', 'the marker', 'the crayon', 'cm'),
  ('Anna', 'Beto', 'Cami', 'inches'),
  ('the snake', 'the worm', 'the lizard', 'cm'),
];

GeneratedQuestion orderThreeObjectsLength(Random rand) {
  final s = _tripleScenarios[rand.nextInt(_tripleScenarios.length)];
  // Three distinct lengths in 2..30.
  final lengths = <int>{};
  while (lengths.length < 3) {
    lengths.add(rand.nextInt(29) + 2);
  }
  final lengthList = lengths.toList();
  final entries = [
    (s.$1, lengthList[0]),
    (s.$2, lengthList[1]),
    (s.$3, lengthList[2]),
  ];
  // Question flavour: 0 = shortest, 1 = longest.
  final wantShortest = rand.nextInt(2) == 0;
  final ordered = [...entries]..sort((a, b) => a.$2.compareTo(b.$2));
  final answer = wantShortest ? ordered.first.$1 : ordered.last.$1;
  return GeneratedQuestion(
    conceptId: 'order_three_objects_length',
    prompt: 'Which is the ${wantShortest ? 'shortest' : 'longest'}?',
    diagram: LengthBarsSpec(
      unit: s.$4,
      bars: [
        for (final e in entries) LengthBar(label: e.$1, length: e.$2),
      ],
    ),
    correctAnswer: answer,
    distractors: stringDistractorsFromPool(
      answer,
      [s.$1, s.$2, s.$3, 'they are all the same'],
      rand,
    ),
    answerFormat: AnswerFormat.string,
    explanation: [
      'Smallest = ${ordered.first.$2}; biggest = ${ordered.last.$2}.',
    ],
  );
}
