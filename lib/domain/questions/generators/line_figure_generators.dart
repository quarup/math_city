import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// G4 lines / rays / segments + parallel/perpendicular generators on
/// the LineFigure widget, plus a classify-quadrilateral-by-lines
/// generator on the Shape widget.

// ─────────────────────────────────────────────────────────────────────────
// identify_lines_rays_segments (G4)
// ─────────────────────────────────────────────────────────────────────────

/// "Is this a line, a ray, or a line segment?" — 3-way MC. CCSS 4.G.A.1.
GeneratedQuestion identifyLinesRaysSegments(Random rand) {
  const pool = <LineFigureKind>[
    LineFigureKind.line,
    LineFigureKind.ray,
    LineFigureKind.segment,
  ];
  final kind = pool[rand.nextInt(pool.length)];
  final answer = kind.displayName;
  return GeneratedQuestion(
    conceptId: 'identify_lines_rays_segments',
    prompt: 'What kind of figure is this?',
    diagram: LineFigureSpec(kind: kind),
    correctAnswer: answer,
    distractors: stringDistractorsFromPool(
      answer,
      const ['line', 'ray', 'line segment', 'point'],
      rand,
    ),
    answerFormat: AnswerFormat.string,
    explanation: [
      switch (kind) {
        LineFigureKind.line =>
          'Arrows on both ends mean the figure extends forever — a line.',
        LineFigureKind.ray =>
          'A dot on one end and an arrow on the other — a ray.',
        LineFigureKind.segment =>
          'Dots on both ends — a line segment with two endpoints.',
        _ => '',
      },
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// parallel_perpendicular_lines (G4)
// ─────────────────────────────────────────────────────────────────────────

/// "Are these two lines parallel, perpendicular, or just intersecting?"
/// 3-way MC. CCSS 4.G.A.1.
GeneratedQuestion parallelPerpendicularLines(Random rand) {
  const pool = <LineFigureKind>[
    LineFigureKind.parallelLines,
    LineFigureKind.perpendicularLines,
    LineFigureKind.intersectingLines,
  ];
  final kind = pool[rand.nextInt(pool.length)];
  final answer = kind.displayName;
  return GeneratedQuestion(
    conceptId: 'parallel_perpendicular_lines',
    prompt: 'How would you describe this pair of lines?',
    diagram: LineFigureSpec(kind: kind),
    correctAnswer: answer,
    distractors: stringDistractorsFromPool(
      answer,
      // Pool of 4 so removing the correct one still leaves 3
      // distinct distractors.
      const ['parallel', 'perpendicular', 'intersecting', 'overlapping'],
      rand,
    ),
    answerFormat: AnswerFormat.string,
    explanation: [
      switch (kind) {
        LineFigureKind.parallelLines =>
          'Parallel lines never meet and stay the same distance apart.',
        LineFigureKind.perpendicularLines =>
          'Perpendicular lines meet at a right angle (90°).',
        LineFigureKind.intersectingLines =>
          'Intersecting lines cross at one point but not at a right angle.',
        _ => '',
      },
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// classify_2d_by_lines_angles (G4)
// ─────────────────────────────────────────────────────────────────────────

/// "Does this quadrilateral have all right angles?" — Yes/No
/// classification of a shape by its line/angle attributes.
/// CCSS 4.G.A.2.
///
/// Two question variants share the same pool (Yes/No + 2 confidence-
/// builder distractors):
///   - "all right angles?" — true for square + rectangle
///   - "all sides equal?"  — true for square + rhombus
GeneratedQuestion classify2dByLinesAngles(Random rand) {
  const quads = <ShapeKind>[
    ShapeKind.square,
    ShapeKind.rectangle,
    ShapeKind.parallelogram,
    ShapeKind.rhombus,
    ShapeKind.trapezoid,
  ];
  final kind = quads[rand.nextInt(quads.length)];
  // Question flavour: 0 = right angles, 1 = equal sides.
  final flavour = rand.nextInt(2);
  late final bool isTrue;
  late final String prompt;
  if (flavour == 0) {
    isTrue = kind == ShapeKind.square || kind == ShapeKind.rectangle;
    prompt = 'Does this quadrilateral have all right angles?';
  } else {
    isTrue = kind == ShapeKind.square || kind == ShapeKind.rhombus;
    prompt = 'Does this quadrilateral have all sides the same length?';
  }
  final answer = isTrue ? 'Yes' : 'No';
  return GeneratedQuestion(
    conceptId: 'classify_2d_by_lines_angles',
    prompt: prompt,
    diagram: ShapeSpec(kind: kind),
    correctAnswer: answer,
    distractors: stringDistractorsFromPool(
      answer,
      const ['Yes', 'No', 'Only sometimes', 'Cannot tell'],
      rand,
    ),
    answerFormat: AnswerFormat.string,
    explanation: [
      if (isTrue)
        'Yes — a ${kind.displayName} fits this description.'
      else
        'No — a ${kind.displayName} fails this description.',
    ],
  );
}
