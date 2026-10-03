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

/// "This {result} is cut into two pieces that are the same. What shape is
/// each piece?" The diagram renders the *result* shape with the cut
/// dashed across it. CCSS 1.G.A.2.
///
/// Hardcoded compositions:
///   - Rectangle composed of 2 squares (side-by-side)
///   - Hexagon composed of 2 trapezoids (cut through the top and bottom
///     corners)
///   - Rhombus composed of 2 triangles (cut between the side corners)
///   - Square composed of 2 right triangles (along the diagonal)
///
/// The cut is drawn, so a Grade 1 child names the pieces they can see
/// rather than imagining the split.
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
        'This $resultName is cut into two pieces that are the same. '
        'What shape is each piece?',
    diagram: ShapeSpec(kind: c.$1, showHalvingCut: true),
    correctAnswer: partName,
    distractors: stringDistractorsFromPool(
      partName,
      [
        'square',
        // A square is a rectangle too, so it can't be a wrong answer.
        if (partName != 'square') 'rectangle',
        'triangle',
        'trapezoid',
        'hexagon',
        'circle',
      ],
      rand,
    ),
    answerFormat: AnswerFormat.string,
    explanation: [
      'Each piece is a $partName.',
      'Two ${partName}s that are the same, put together, make a $resultName.',
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

/// "On a scale drawing, 1 centimetre represents s metres. The drawing of
/// a park is d centimetres long. How long is the actual park?" → d × s
/// metres.
/// CCSS 7.G.A.1.
///
/// Two question flavours drawn 50/50: forward (drawing → real) and
/// inverse (real → drawing).
GeneratedQuestion scaleDrawing(Random rand) {
  // Scale (1 small-unit = s big-units) ∈ {5, 10, 20, 25, 50}.
  const scales = [5, 10, 20, 25, 50];
  final s = scales[rand.nextInt(scales.length)];
  // 50/50 a park drawn in metres or a road on a map in kilometres —
  // real lengths run 10..500, so each object keeps them realistic.
  final inKm = rand.nextBool();
  const small = 'centimetre';
  const smalls = 'centimetres';
  final bigs = inKm ? 'kilometres' : 'metres';
  final thing = inKm ? 'road' : 'park';
  // Forward: drawing length ∈ 2..10 → real = d × s.
  // Inverse: real length that is a multiple of s (so the drawing
  // length comes out a whole number).
  final forward = rand.nextInt(2) == 0;
  if (forward) {
    final d = rand.nextInt(9) + 2; // 2..10
    final answer = d * s;
    // Error-based distractors (off by one drawing unit, added instead of
    // multiplied): ±1 jitter made the correct answer the only round
    // number on screen, so it could be picked without scaling anything.
    final candidates = <String>[
      '${(d + 1) * s}',
      '${(d - 1) * s}',
      '${d + s}',
      '${answer + s}',
    ];
    final distractors = <String>[];
    final seen = <String>{'$answer'};
    for (final c in candidates) {
      if (distractors.length >= 3) break;
      if (seen.add(c)) distractors.add(c);
    }
    return GeneratedQuestion(
      conceptId: 'scale_drawing',
      prompt:
          'On a scale drawing, 1 $small represents $s $bigs. The drawing of '
          'a $thing is $d $smalls long. How long is the actual $thing, '
          'in $bigs?',
      correctAnswer: '$answer',
      distractors: distractors,
      explanation: [
        '$d $smalls × $s $bigs per $small = $answer $bigs.',
      ],
    );
  } else {
    final d = rand.nextInt(9) + 2; // 2..10
    final real = d * s;
    return GeneratedQuestion(
      conceptId: 'scale_drawing',
      prompt:
          'A $thing is $real $bigs long. On a scale drawing where 1 $small '
          'represents $s $bigs, how many $smalls long is the drawing of '
          'the $thing?',
      correctAnswer: '$d',
      distractors: integerDistractorsWith(
        d,
        rand,
        // Misconception: multiplied instead of divided.
        misconception: real * s,
      ),
      explanation: [
        '$real $bigs ÷ $s $bigs per $small = $d $smalls.',
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// volume_unit_cubes (G5)
// ─────────────────────────────────────────────────────────────────────────

/// "A rectangular prism is made of unit cubes. It is l × w × h cubes
/// large. How many unit cubes does it contain?" → l·w·h. CCSS 5.MD.C.3.
///
/// Text-only with a schematic cube diagram (the Shape:cube widget
/// doesn't yet take dimensions — the numbers in the prompt do the
/// visual work, like `pythagorean_apply_3d`).
GeneratedQuestion volumeUnitCubes(Random rand) {
  final l = rand.nextInt(5) + 2; // 2..6
  final w = rand.nextInt(5) + 2;
  final h = rand.nextInt(4) + 2; // 2..5
  final v = l * w * h;
  return GeneratedQuestion(
    conceptId: 'volume_unit_cubes',
    prompt:
        'A rectangular prism is built from unit cubes with these '
        'dimensions. How many unit cubes does it contain?',
    diagram: Box3DSpec(
      length: l,
      width: w,
      height: h,
      showUnitGrid: true,
    ),
    correctAnswer: '$v',
    distractors: integerDistractorsWith(
      v,
      rand,
      // Misconception: added the dimensions instead of multiplying.
      misconception: l + w + h,
    ),
    explanation: [
      'Count the cubes: $l × $w × $h = $v.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// surface_area_from_net (G6)
// ─────────────────────────────────────────────────────────────────────────

/// "A cube has edge length s. What is its total surface area?" → 6·s².
/// CCSS 6.G.A.4 (surface area of right rectangular prism via nets —
/// kept to the cube case in v1 since the Shape widget renders a cube,
/// not an unfolded net).
GeneratedQuestion surfaceAreaFromNet(Random rand) {
  final s = rand.nextInt(8) + 2; // 2..9 → s² ∈ 4..81, sa ∈ 24..486
  final sa = 6 * s * s;
  return GeneratedQuestion(
    conceptId: 'surface_area_from_net',
    prompt:
        'This is the net of a cube whose edge length is $s units. What '
        'is the total surface area of the cube?',
    diagram: Net3DSpec(edgeLength: s),
    correctAnswer: '$sa',
    distractors: integerDistractorsWith(
      sa,
      rand,
      // Misconception: computed volume (s³) instead of surface area.
      misconception: s * s * s,
    ),
    explanation: [
      'A cube has 6 faces, each of area $s × $s = ${s * s}.',
      'Total surface area = 6 × ${s * s} = $sa.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// area_polygon_decompose (G6)
// ─────────────────────────────────────────────────────────────────────────

/// "A polygon can be split into a rectangle of area A and a triangle
/// of area B. What is the total area?" → A + B. CCSS 6.G.A.1.
///
/// Text-only decomposition: the prompt gives each part's DIMENSIONS
/// (not its precomputed area), so the kid computes w·h and b·h/2 and
/// sums — stating both areas reduced the item to one addition. Still
/// no diagram — the generic unlabelled trapezoid it used to show had
/// no split line and didn't match the described rectangle-plus-triangle
/// decomposition, which misleads more than a blank space does.
GeneratedQuestion areaPolygonDecompose(Random rand) {
  final w = rand.nextInt(7) + 3; // 3..9
  final h = rand.nextInt(6) + 2; // 2..7
  final rectArea = w * h;
  // Even base so the triangle area is a whole number.
  final base = (rand.nextInt(4) + 1) * 2; // 2, 4, 6, 8
  final triH = rand.nextInt(5) + 2; // 2..6
  final triArea = base * triH ~/ 2;
  final total = rectArea + triArea;
  return GeneratedQuestion(
    conceptId: 'area_polygon_decompose',
    prompt:
        'A polygon is split into a rectangle $w units by $h units and a '
        'triangle with base $base units and height $triH units. What is '
        'the total area of the polygon, in square units?',
    correctAnswer: '$total',
    distractors: integerDistractorsWith(
      total,
      rand,
      // Misconception: forgot the ÷2 on the triangle.
      misconception: rectArea + base * triH,
    ),
    explanation: [
      'Rectangle: $w × $h = $rectArea square units.',
      'Triangle: $base × $triH ÷ 2 = $triArea square units.',
      'Total: $rectArea + $triArea = $total square units.',
    ],
  );
}
