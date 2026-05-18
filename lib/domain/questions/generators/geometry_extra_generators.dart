import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// G1 + G7 geometry generators that ride on existing widgets:
///   compose_shapes (G1, Shape),
///   cross_section_3d (G7, Shape),
///   scale_drawing (G7, text-only / Shape).

// ─────────────────────────────────────────────────────────────────────────
// compose_shapes (G1)
// ─────────────────────────────────────────────────────────────────────────

/// "Two equal ___s can be put together to make a {result}. What
/// shape are the parts?" The diagram renders the *result* shape so
/// the kid sees what they're composing toward. CCSS 1.G.A.2.
///
/// Hardcoded compositions:
///   - Rectangle composed of 2 squares (side-by-side)
///   - Hexagon composed of 2 trapezoids (cut horizontally through the
///     middle pair of vertices)
///   - Rhombus composed of 2 equilateral triangles (base-to-base)
///   - Square composed of 2 right triangles (along the diagonal)
const List<(ShapeKind, String)> _compositions = [
  (ShapeKind.rectangle, 'square'),
  (ShapeKind.hexagon, 'trapezoid'),
  (ShapeKind.rhombus, 'triangle'),
  (ShapeKind.square, 'triangle'),
];

GeneratedQuestion composeShapes(Random rand) {
  final c = _compositions[rand.nextInt(_compositions.length)];
  final resultName = c.$1.displayName;
  final partName = c.$2;
  return GeneratedQuestion(
    conceptId: 'compose_shapes',
    prompt:
        'You can build this $resultName by putting two of the same shape '
        'together. What is that shape?',
    diagram: ShapeSpec(kind: c.$1),
    correctAnswer: partName,
    distractors: stringDistractorsFromPool(
      partName,
      const ['square', 'rectangle', 'triangle', 'trapezoid', 'hexagon'],
      rand,
    ),
    answerFormat: AnswerFormat.string,
    explanation: [
      'Two equal ${partName}s put together can make a $resultName.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// cross_section_3d (G7)
// ─────────────────────────────────────────────────────────────────────────

/// "If you slice {solid} horizontally, what 2D shape do you see at
/// the cut?" CCSS 7.G.A.3.
///
/// Hardcoded for the 4 K-grade 3D solids we draw plus a `cube` cut
/// diagonally (skipped to keep answers clean). Horizontal cuts only.
const List<(ShapeKind, String)> _crossSections = [
  (ShapeKind.cube, 'square'),
  (ShapeKind.cylinder, 'circle'),
  (ShapeKind.cone, 'circle'),
  (ShapeKind.sphere, 'circle'),
];

GeneratedQuestion crossSection3d(Random rand) {
  final c = _crossSections[rand.nextInt(_crossSections.length)];
  final solidName = c.$1.displayName;
  final sliceName = c.$2;
  return GeneratedQuestion(
    conceptId: 'cross_section_3d',
    prompt:
        'You slice this $solidName horizontally. What 2D shape do you see '
        'at the cut?',
    diagram: ShapeSpec(kind: c.$1),
    correctAnswer: sliceName,
    distractors: stringDistractorsFromPool(
      sliceName,
      const ['square', 'circle', 'triangle', 'rectangle'],
      rand,
    ),
    answerFormat: AnswerFormat.string,
    explanation: [
      'A horizontal slice through a $solidName is a $sliceName.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// scale_drawing (G7)
// ─────────────────────────────────────────────────────────────────────────

/// "On a scale drawing, 1 inch represents s feet. The drawing of the
/// wall is d inches. How long is the actual wall?" → d × s feet.
/// CCSS 7.G.A.1.
///
/// Two question flavours drawn 50/50: forward (drawing → real) and
/// inverse (real → drawing).
GeneratedQuestion scaleDrawing(Random rand) {
  // Scale (1 in = s ft) ∈ {5, 10, 20, 25, 50}.
  const scales = [5, 10, 20, 25, 50];
  final s = scales[rand.nextInt(scales.length)];
  // Forward: drawing inches ∈ 2..10 → real feet = d × s.
  // Inverse: real feet that is a multiple of s (so the drawing
  // inches comes out a whole number).
  final forward = rand.nextInt(2) == 0;
  if (forward) {
    final d = rand.nextInt(9) + 2; // 2..10
    final answer = d * s;
    return GeneratedQuestion(
      conceptId: 'scale_drawing',
      prompt:
          'On a scale drawing, 1 inch represents $s feet. The drawing of '
          'a wall is $d inches long. How long is the actual wall, in feet?',
      correctAnswer: '$answer',
      distractors: integerDistractorsWith(
        answer,
        rand,
        // Misconception: divided instead of multiplied.
        misconception: d ~/ (s > d ? d : 1),
      ),
      explanation: [
        '$d inches × $s ft per inch = $answer feet.',
      ],
    );
  } else {
    final dInches = rand.nextInt(9) + 2; // 2..10
    final realFeet = dInches * s;
    return GeneratedQuestion(
      conceptId: 'scale_drawing',
      prompt:
          'A wall is $realFeet feet long. On a scale drawing where 1 inch '
          'represents $s feet, how many inches long is the drawing of '
          'the wall?',
      correctAnswer: '$dInches',
      distractors: integerDistractorsWith(
        dInches,
        rand,
        // Misconception: multiplied instead of divided.
        misconception: realFeet * s,
      ),
      explanation: [
        '$realFeet feet ÷ $s ft per inch = $dInches inches.',
      ],
    );
  }
}
