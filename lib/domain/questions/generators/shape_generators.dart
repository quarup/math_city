import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// K-G2 shape-recognition generators using the new Shape widget:
/// identify_shape_2d, identify_shape_3d, shape_attributes_basic,
/// identify_polygons.

// ─────────────────────────────────────────────────────────────────────────
// identify_shape_2d (K)
// ─────────────────────────────────────────────────────────────────────────

/// The pool of 2D kinds that kindergarten kids should recognize by
/// name. Triangles are collapsed to a single "triangle" answer in the
/// display, but four visual variants appear so the kid learns that
/// "triangle" isn't just one specific picture.
const List<ShapeKind> _shapes2dPool = [
  ShapeKind.circle,
  ShapeKind.triangleEquilateral,
  ShapeKind.triangleIsosceles,
  ShapeKind.triangleScalene,
  ShapeKind.square,
  ShapeKind.rectangle,
  ShapeKind.pentagon,
  ShapeKind.hexagon,
];

const List<String> _displayNames2d = [
  'circle',
  'triangle',
  'square',
  'rectangle',
  'pentagon',
  'hexagon',
];

/// "What is this shape?" — pick a 2D kind, render it, MC over the six
/// kindergarten-grade 2D names. CCSS K.G.A.2.
GeneratedQuestion identifyShape2d(Random rand) {
  final kind = _shapes2dPool[rand.nextInt(_shapes2dPool.length)];
  final answer = kind.displayName;
  return GeneratedQuestion(
    conceptId: 'identify_shape_2d',
    prompt: 'What is the name of this shape?',
    diagram: ShapeSpec(kind: kind),
    correctAnswer: answer,
    distractors: stringDistractorsFromPool(answer, _displayNames2d, rand),
    answerFormat: AnswerFormat.string,
    explanation: ['This shape is a $answer.'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// identify_shape_3d (K)
// ─────────────────────────────────────────────────────────────────────────

const List<ShapeKind> _shapes3dPool = [
  ShapeKind.cube,
  ShapeKind.sphere,
  ShapeKind.cylinder,
  ShapeKind.cone,
];

const List<String> _displayNames3d = ['cube', 'sphere', 'cylinder', 'cone'];

/// "What is this 3D shape?" — show one of cube/sphere/cylinder/cone in
/// schematic 2D outline, MC over the four kindergarten 3D names.
/// CCSS K.G.A.3.
GeneratedQuestion identifyShape3d(Random rand) {
  final kind = _shapes3dPool[rand.nextInt(_shapes3dPool.length)];
  final answer = kind.displayName;
  return GeneratedQuestion(
    conceptId: 'identify_shape_3d',
    prompt: 'What is the name of this 3D shape?',
    diagram: ShapeSpec(kind: kind),
    correctAnswer: answer,
    // _displayNames3d has exactly 4 entries (cube/sphere/cylinder/cone)
    // so removing the correct one always leaves 3 distinct distractors.
    distractors: stringDistractorsFromPool(answer, _displayNames3d, rand),
    answerFormat: AnswerFormat.string,
    explanation: ['This 3D shape is a $answer.'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// shape_attributes_basic (G1)
// ─────────────────────────────────────────────────────────────────────────

/// "How many sides does this shape have?" Drawn from 2D polygons with
/// a stable sideCount (triangle = 3 … octagon = 8). Misconception
/// distractor: ±1 (kids miscount corners). CCSS 1.G.A.1.
GeneratedQuestion shapeAttributesBasic(Random rand) {
  const pool = <ShapeKind>[
    ShapeKind.triangleRight,
    ShapeKind.triangleEquilateral,
    ShapeKind.triangleIsosceles,
    ShapeKind.square,
    ShapeKind.rectangle,
    ShapeKind.trapezoid,
    ShapeKind.pentagon,
    ShapeKind.hexagon,
    ShapeKind.octagon,
  ];
  final kind = pool[rand.nextInt(pool.length)];
  final n = kind.sideCount;
  return GeneratedQuestion(
    conceptId: 'shape_attributes_basic',
    prompt: 'How many sides does this shape have?',
    diagram: ShapeSpec(kind: kind),
    correctAnswer: '$n',
    // Misconception: kids often miscount by ±1, especially on hexagons
    // and octagons. integerDistractors already biases toward ±1.
    distractors: integerDistractors(n, rand),
    explanation: ['Count the sides one by one — there are $n.'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// identify_polygons (G2)
// ─────────────────────────────────────────────────────────────────────────

/// "What kind of polygon is this?" — distinguishes triangle / quad /
/// pentagon / hexagon by name, drawn from a wider pool than
/// `identify_shape_2d` so the kid practises mapping side-count to a
/// formal name. CCSS 2.G.A.1.
GeneratedQuestion identifyPolygons(Random rand) {
  // Each row: (kind, formal polygon name).
  const pool = <(ShapeKind, String)>[
    (ShapeKind.triangleRight, 'triangle'),
    (ShapeKind.triangleEquilateral, 'triangle'),
    (ShapeKind.triangleIsosceles, 'triangle'),
    (ShapeKind.triangleScalene, 'triangle'),
    (ShapeKind.square, 'quadrilateral'),
    (ShapeKind.rectangle, 'quadrilateral'),
    (ShapeKind.parallelogram, 'quadrilateral'),
    (ShapeKind.rhombus, 'quadrilateral'),
    (ShapeKind.trapezoid, 'quadrilateral'),
    (ShapeKind.pentagon, 'pentagon'),
    (ShapeKind.hexagon, 'hexagon'),
  ];
  final row = pool[rand.nextInt(pool.length)];
  final kind = row.$1;
  final answer = row.$2;
  return GeneratedQuestion(
    conceptId: 'identify_polygons',
    prompt: 'What kind of polygon is this?',
    diagram: ShapeSpec(kind: kind),
    correctAnswer: answer,
    distractors: stringDistractorsFromPool(
      answer,
      const ['triangle', 'quadrilateral', 'pentagon', 'hexagon'],
      rand,
    ),
    answerFormat: AnswerFormat.string,
    explanation: [
      'This polygon has ${kind.sideCount} sides, so it is a $answer.',
    ],
  );
}
