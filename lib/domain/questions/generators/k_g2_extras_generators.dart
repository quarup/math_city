import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// Small K-G2 generators that ride on existing widgets:
///   positional_words (K, text-only),
///   partition_circle_rect_halves (G1, FractionBar),
///   estimate_length (G2, text-only).

// ─────────────────────────────────────────────────────────────────────────
// positional_words (K)
// ─────────────────────────────────────────────────────────────────────────

/// "The book is on top of the table. Where is the book compared to
/// the table?" — MC over above / below / beside / inside. CCSS K.G.A.1.
const List<(String, String)> _positionalScenarios = [
  ('The book is on top of the table. Where is the book?', 'above'),
  ('The cat is sitting under the chair. Where is the cat?', 'below'),
  ('The toy is in the box. Where is the toy?', 'inside'),
  ('The lamp stands next to the bed. Where is the lamp?', 'beside'),
  ('The bird flies over the tree. Where is the bird?', 'above'),
  ('The dog is hiding under the sofa. Where is the dog?', 'below'),
  ('Anna stands next to her brother. Where is Anna?', 'beside'),
  ('The pencil is inside the case. Where is the pencil?', 'inside'),
];

GeneratedQuestion positionalWords(Random rand) {
  final s = _positionalScenarios[rand.nextInt(_positionalScenarios.length)];
  return GeneratedQuestion(
    conceptId: 'positional_words',
    prompt: s.$1,
    correctAnswer: s.$2,
    distractors: stringDistractorsFromPool(
      s.$2,
      const ['above', 'below', 'beside', 'inside'],
      rand,
    ),
    answerFormat: AnswerFormat.string,
    explanation: ['The position word that fits this scene is ${s.$2}.'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// partition_circle_rect_halves (G1)
// ─────────────────────────────────────────────────────────────────────────

/// "Is this shape divided into halves?" — show a rectangle (via
/// FractionBar) partitioned into 2, 3, 4, or 6 equal parts; answer
/// Yes iff the denominator is 2. CCSS 1.G.A.3.
GeneratedQuestion partitionCircleRectHalves(Random rand) {
  const denoms = <int>[2, 3, 4, 6];
  final denom = denoms[rand.nextInt(denoms.length)];
  // Always shade exactly one part so the visual is unambiguous.
  final isHalves = denom == 2;
  return GeneratedQuestion(
    conceptId: 'partition_circle_rect_halves',
    prompt: 'Is this shape divided into halves?',
    diagram: FractionBarSpec(numerator: 1, denominator: denom),
    correctAnswer: isHalves ? 'Yes' : 'No',
    distractors: stringDistractorsFromPool(
      isHalves ? 'Yes' : 'No',
      const ['Yes', 'No', 'Only sometimes', 'Cannot tell'],
      rand,
    ),
    answerFormat: AnswerFormat.string,
    explanation: [
      if (isHalves)
        'Yes — the shape is divided into 2 equal parts (halves).'
      else
        'No — halves means 2 equal parts, not $denom.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// estimate_length (G2)
// ─────────────────────────────────────────────────────────────────────────

/// "About how long is a typical {object}?" — MC over plausible
/// lengths in a single unit (inches or feet). CCSS 2.MD.A.3.
const List<(String, String, List<String>)> _estimateScenarios = [
  // (object, correct answer, MC pool — must include the correct)
  (
    'a new pencil',
    '7 inches',
    ['7 inches', '1 inch', '2 feet', '20 feet'],
  ),
  (
    'a doorway',
    '7 feet',
    ['7 feet', '7 inches', '20 feet', '1 inch'],
  ),
  (
    'a paper clip',
    '1 inch',
    ['1 inch', '1 foot', '6 inches', '3 feet'],
  ),
  (
    'a school bus',
    '40 feet',
    ['40 feet', '40 inches', '4 feet', '4 inches'],
  ),
  (
    'a sheet of notebook paper',
    '11 inches',
    ['11 inches', '11 feet', '2 inches', '5 feet'],
  ),
  (
    'a marker',
    '5 inches',
    ['5 inches', '5 feet', '15 inches', '1 inch'],
  ),
];

GeneratedQuestion estimateLength(Random rand) {
  final s = _estimateScenarios[rand.nextInt(_estimateScenarios.length)];
  final answer = s.$2;
  return GeneratedQuestion(
    conceptId: 'estimate_length',
    prompt: 'About how long is ${s.$1}?',
    correctAnswer: answer,
    distractors: stringDistractorsFromPool(answer, s.$3, rand),
    answerFormat: AnswerFormat.string,
    explanation: ['A typical ${s.$1} is about $answer.'],
  );
}
