import 'dart:math';

import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// K-G1 measurement-vocabulary generators (text-only; no diagram in
/// v1 even though curriculum.md flags `required:shape` for these —
/// the visual is implicit in the story context).

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

/// "A pencil is X cm long. A crayon is Y cm long. Which is longer?"
/// Two-object direct comparison with given measurements. CCSS K.MD.A.2.
const List<(String, String, String)> _pairScenarios = [
  // (subject1, subject2, units suffix used in prompt)
  ('the pencil', 'the crayon', 'cm long'),
  ('the rope', 'the string', 'feet long'),
  ('the cat', 'the dog', 'pounds'),
  ('the apple', 'the orange', 'grams'),
  ('the red ribbon', 'the blue ribbon', 'inches long'),
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
  // Phrase the question consistently with the units (longer for
  // length, heavier for weight, etc.).
  String compWord;
  if (p.$3.contains('long') || p.$3.contains('inches')) {
    compWord = 'longer';
  } else if (p.$3.contains('pound') || p.$3.contains('gram')) {
    compWord = 'heavier';
  } else {
    compWord = 'bigger';
  }
  return GeneratedQuestion(
    conceptId: 'compare_two_objects',
    prompt:
        '${p.$1[0].toUpperCase()}${p.$1.substring(1)} is $a ${p.$3}. '
        '${p.$2[0].toUpperCase()}${p.$2.substring(1)} is $b ${p.$3}. '
        'Which is $compWord?',
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

/// "A is X long, B is Y long, C is Z long. Which is the shortest?"
/// CCSS 1.MD.A.1.
const List<(String, String, String, String)> _tripleScenarios = [
  ('rope A', 'rope B', 'rope C', 'feet long'),
  ('the pencil', 'the marker', 'the crayon', 'cm long'),
  ('Anna', 'Beto', 'Cami', 'inches tall'),
  ('the snake', 'the worm', 'the lizard', 'cm long'),
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
    prompt:
        '${s.$1[0].toUpperCase()}${s.$1.substring(1)} is ${entries[0].$2} '
        '${s.$4}, ${s.$2} is ${entries[1].$2} ${s.$4}, and ${s.$3} is '
        '${entries[2].$2} ${s.$4}. Which is the '
        '${wantShortest ? 'shortest' : 'longest'}?',
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
