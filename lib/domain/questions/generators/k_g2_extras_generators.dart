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

/// Two labelled objects in a spatial relation, rendered as a
/// [PositionalSceneSpec] so the K kid sees the scene. MC over
/// above / below / beside / inside. CCSS K.G.A.1.
typedef _Scenario = ({
  String prompt,
  String subject,
  String reference,
  PositionRelation relation,
});

// The prompt must NOT state the relation in words ("The toy is in the
// box…" hands over the answer) — the picture is the only source.
const List<_Scenario> _positionalScenarios = [
  (
    prompt: 'Look at the picture. Where is the book?',
    subject: 'book',
    reference: 'table',
    relation: PositionRelation.above,
  ),
  (
    prompt: 'Look at the picture. Where is the cat?',
    subject: 'cat',
    reference: 'chair',
    relation: PositionRelation.below,
  ),
  (
    prompt: 'Look at the picture. Where is the toy?',
    subject: 'toy',
    reference: 'box',
    relation: PositionRelation.inside,
  ),
  (
    prompt: 'Look at the picture. Where is the lamp?',
    subject: 'lamp',
    reference: 'bed',
    relation: PositionRelation.beside,
  ),
  (
    prompt: 'Look at the picture. Where is the bird?',
    subject: 'bird',
    reference: 'tree',
    relation: PositionRelation.above,
  ),
  (
    prompt: 'Look at the picture. Where is the dog?',
    subject: 'dog',
    reference: 'sofa',
    relation: PositionRelation.below,
  ),
  (
    prompt: 'Look at the picture. Where is the doll?',
    subject: 'doll',
    reference: 'teddy bear',
    relation: PositionRelation.beside,
  ),
  (
    prompt: 'Look at the picture. Where is the pencil?',
    subject: 'pencil',
    reference: 'case',
    relation: PositionRelation.inside,
  ),
];

String _relationWord(PositionRelation r) => switch (r) {
  PositionRelation.above => 'above',
  PositionRelation.below => 'below',
  PositionRelation.beside => 'beside',
  PositionRelation.inside => 'inside',
};

GeneratedQuestion positionalWords(Random rand) {
  final s = _positionalScenarios[rand.nextInt(_positionalScenarios.length)];
  final answer = _relationWord(s.relation);
  return GeneratedQuestion(
    conceptId: 'positional_words',
    prompt: s.prompt,
    diagram: PositionalSceneSpec(
      subjectLabel: s.subject,
      referenceLabel: s.reference,
      relation: s.relation,
    ),
    correctAnswer: answer,
    distractors: stringDistractorsFromPool(
      answer,
      const ['above', 'below', 'beside', 'inside'],
      rand,
    ),
    answerFormat: AnswerFormat.string,
    explanation: ['The ${s.subject} is $answer the ${s.reference}.'],
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
/// lengths in a single unit. Half the scenarios are imperial
/// (inches/feet) and half metric (centimetres/metres), following the
/// measure_with_ruler_inches + measure_with_ruler_cm pattern of teaching
/// both systems side by side. CCSS 2.MD.A.3.
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
  // Metric siblings.
  (
    'a new pencil',
    '18 centimetres',
    ['18 centimetres', '2 centimetres', '2 metres', '18 metres'],
  ),
  (
    'a doorway',
    '2 metres',
    ['2 metres', '2 centimetres', '20 metres', '50 centimetres'],
  ),
  (
    'a paper clip',
    '3 centimetres',
    ['3 centimetres', '3 metres', '30 centimetres', '1 metre'],
  ),
  (
    'a school bus',
    '12 metres',
    ['12 metres', '12 centimetres', '1 metre', '120 metres'],
  ),
  (
    'a sheet of notebook paper',
    '30 centimetres',
    ['30 centimetres', '30 metres', '3 centimetres', '3 metres'],
  ),
  (
    'a marker',
    '13 centimetres',
    ['13 centimetres', '13 metres', '130 centimetres', '1 centimetre'],
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
    // "Typically, a paper clip…", not the old "A typical a paper clip…"
    // (the object strings carry their own article).
    explanation: ['Typically, ${s.$1} is about $answer.'],
  );
}
