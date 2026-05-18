import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// Shape-widget generators:
///   K-G2 recognition — identify_shape_2d, identify_shape_3d,
///                      shape_attributes_basic, identify_polygons.
///   G3-G8 classification / properties — classify_quadrilaterals,
///                      line_of_symmetry, classify_2d_hierarchy,
///                      pythagorean_apply_3d.

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

// ─────────────────────────────────────────────────────────────────────────
// classify_quadrilaterals (G3)
// ─────────────────────────────────────────────────────────────────────────

/// "What kind of quadrilateral is this?" — five specific quad names
/// (square / rectangle / parallelogram / rhombus / trapezoid). Drawn at
/// the canonical orientation for each so kids can rely on a stable
/// visual cue. CCSS 3.G.A.1.
GeneratedQuestion classifyQuadrilaterals(Random rand) {
  const pool = <ShapeKind>[
    ShapeKind.square,
    ShapeKind.rectangle,
    ShapeKind.parallelogram,
    ShapeKind.rhombus,
    ShapeKind.trapezoid,
  ];
  final kind = pool[rand.nextInt(pool.length)];
  final answer = kind.displayName;
  return GeneratedQuestion(
    conceptId: 'classify_quadrilaterals',
    prompt: 'What kind of quadrilateral is this?',
    diagram: ShapeSpec(kind: kind),
    correctAnswer: answer,
    distractors: stringDistractorsFromPool(
      answer,
      const ['square', 'rectangle', 'parallelogram', 'rhombus', 'trapezoid'],
      rand,
    ),
    answerFormat: AnswerFormat.string,
    explanation: ['This quadrilateral is a $answer.'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// line_of_symmetry (G4)
// ─────────────────────────────────────────────────────────────────────────

/// Lines-of-symmetry count for each shape kind we draw, at the
/// canonical orientation the Shape widget renders. Circle is excluded
/// (infinite) so the answer pool stays a clean integer.
const Map<ShapeKind, int> _symmetryCounts = {
  ShapeKind.triangleEquilateral: 3,
  ShapeKind.triangleIsosceles: 1,
  ShapeKind.triangleScalene: 0,
  // The right triangle as we draw it (right angle at the bottom-left,
  // legs equal? no — the canonical shape has unequal legs) is
  // effectively scalene → 0 lines of symmetry.
  ShapeKind.triangleRight: 0,
  ShapeKind.square: 4,
  ShapeKind.rectangle: 2,
  ShapeKind.parallelogram: 0,
  ShapeKind.rhombus: 2,
  // Our trapezoid is an isosceles trapezoid (vertices symmetric about
  // the vertical centreline) → 1 line of symmetry.
  ShapeKind.trapezoid: 1,
  ShapeKind.pentagon: 5,
  ShapeKind.hexagon: 6,
  ShapeKind.octagon: 8,
};

/// "How many lines of symmetry does this shape have?" — integer
/// answer. Pool spans 0..8 across the supported kinds. CCSS 4.G.A.3.
GeneratedQuestion lineOfSymmetry(Random rand) {
  final pool = _symmetryCounts.keys.toList();
  final kind = pool[rand.nextInt(pool.length)];
  final n = _symmetryCounts[kind]!;
  return GeneratedQuestion(
    conceptId: 'line_of_symmetry',
    prompt: 'How many lines of symmetry does this shape have?',
    diagram: ShapeSpec(kind: kind),
    correctAnswer: '$n',
    distractors: integerDistractors(n, rand),
    explanation: [
      'A ${kind.displayName} has $n line${n == 1 ? '' : 's'} of symmetry.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// classify_2d_hierarchy (G5)
// ─────────────────────────────────────────────────────────────────────────

/// "Is every {child} also a {parent}?" — true/false hierarchy items.
/// CCSS 5.G.B.4. The diagram shows an instance of the *child* shape so
/// the kid sees a concrete example. Pool covers the classic quad-
/// hierarchy facts.
GeneratedQuestion classify2dHierarchy(Random rand) {
  // (childKind, childWord, parentWord, isTrue).
  const facts = <(ShapeKind, String, String, bool)>[
    (ShapeKind.square, 'square', 'rectangle', true),
    (ShapeKind.square, 'square', 'parallelogram', true),
    (ShapeKind.square, 'square', 'rhombus', true),
    (ShapeKind.rectangle, 'rectangle', 'parallelogram', true),
    (ShapeKind.rectangle, 'rectangle', 'square', false),
    (ShapeKind.rhombus, 'rhombus', 'parallelogram', true),
    (ShapeKind.rhombus, 'rhombus', 'square', false),
    (ShapeKind.parallelogram, 'parallelogram', 'rectangle', false),
    (ShapeKind.parallelogram, 'parallelogram', 'rhombus', false),
    (ShapeKind.trapezoid, 'trapezoid', 'parallelogram', false),
  ];
  final fact = facts[rand.nextInt(facts.length)];
  final (kind, child, parent, isTrue) = fact;
  final answer = isTrue ? 'True' : 'False';
  return GeneratedQuestion(
    conceptId: 'classify_2d_hierarchy',
    prompt: 'True or False: every $child is a $parent.',
    diagram: ShapeSpec(kind: kind),
    correctAnswer: answer,
    // True/False question — distractor pool is fixed to the opposite
    // plus two confidence-builders so the MC has 4 distinct choices.
    distractors: stringDistractorsFromPool(
      answer,
      const ['True', 'False', 'Only sometimes', 'Cannot tell'],
      rand,
    ),
    answerFormat: AnswerFormat.string,
    explanation: [
      if (isTrue)
        'Every $child meets the defining attributes of a $parent.'
      else
        'Not every $child fits — they fail a defining attribute of a $parent.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// pythagorean_apply_3d (G8)
// ─────────────────────────────────────────────────────────────────────────

/// 3D Pythagorean triples (l, w, h, body diagonal) where
/// l² + w² + h² is a perfect square — the body diagonal is an integer.
/// All four corners ≥ 1. Kept small so the kid can compute by hand.
const List<(int, int, int, int)> _pyth3dTriples = [
  (1, 2, 2, 3),
  (2, 3, 6, 7),
  (1, 4, 8, 9),
  (4, 4, 7, 9),
  (4, 8, 8, 12),
  (2, 6, 9, 11),
  (3, 4, 12, 13),
  (1, 6, 18, 19),
  (6, 6, 7, 11),
];

/// "A box has length l, width w, height h. What is the length of the
/// diagonal from one corner to the opposite corner?" — answer
/// √(l² + w² + h²). CCSS 8.G.B.8.
///
/// The diagram is a schematic cube (the Shape widget doesn't yet take
/// box dimensions); the numbers in the prompt do the visual work.
GeneratedQuestion pythagoreanApply3d(Random rand) {
  final t = _pyth3dTriples[rand.nextInt(_pyth3dTriples.length)];
  final (l, w, h, d) = t;
  return GeneratedQuestion(
    conceptId: 'pythagorean_apply_3d',
    prompt:
        'A rectangular box has the dimensions shown. What is the length '
        'of the diagonal from one corner to the opposite corner?',
    diagram: Box3DSpec(length: l, width: w, height: h),
    correctAnswer: '$d',
    // Misconception: kids often forget the third dimension and compute
    // √(l² + w²) instead. Surface a magnitude-near distractor.
    distractors: integerDistractorsWith(
      d,
      rand,
      misconception: d - 1,
    ),
    explanation: [
      'Use the 3D Pythagorean theorem: diagonal = √($l² + $w² + $h²) = $d.',
    ],
  );
}
