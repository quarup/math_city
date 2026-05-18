import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// G4 protractor generators using the new Protractor widget:
/// measure_angle_protractor, draw_angle_protractor.

// ─────────────────────────────────────────────────────────────────────────
// measure_angle_protractor (G4)
// ─────────────────────────────────────────────────────────────────────────

/// Show an angle drawn over a protractor (with tick labels); kid reads
/// the measure. CCSS 4.MD.C.6.
///
/// Angle drawn to the nearest 5°, in [15, 165] so the kid can't guess
/// "90 or 180" trivially. Misconception distractor: read the wrong scale
/// (180 − a, since protractors carry both directions of tick labels).
GeneratedQuestion measureAngleProtractor(Random rand) {
  int a;
  do {
    a = (rand.nextInt(31) + 3) * 5; // 15..165, step 5
  } while (a == 90); // skip trivial right angle
  return GeneratedQuestion(
    conceptId: 'measure_angle_protractor',
    prompt: 'What is the measure of this angle, in degrees?',
    diagram: ProtractorSpec(angleDeg: a),
    correctAnswer: '$a',
    distractors: integerDistractorsWith(
      a,
      rand,
      // Misconception: read the outer scale (which protractors print
      // for the other direction). 180 − a is the most common kid error.
      misconception: 180 - a,
    ),
    explanation: ['The second ray crosses the $a° tick.'],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// draw_angle_protractor (G4)
// ─────────────────────────────────────────────────────────────────────────

/// "An angle measures $a°. Which protractor figure shows it drawn
/// correctly?" — we don't have a 4-choice picture-MC infrastructure yet,
/// so this is shaped instead as the inverse of the measure task: the
/// diagram is labelled inside the wedge with the target angle, and the
/// kid types the measure value back. This drills the same "match angle
/// measure to figure" skill while staying inside the text-answer UI.
///
/// CCSS 4.MD.C.6.
GeneratedQuestion drawAngleProtractor(Random rand) {
  int a;
  do {
    a = (rand.nextInt(31) + 3) * 5; // 15..165, step 5
  } while (a == 90);
  return GeneratedQuestion(
    conceptId: 'draw_angle_protractor',
    prompt:
        'A student set up the protractor and labelled the angle inside '
        'the wedge. What angle did they draw, in degrees?',
    diagram: ProtractorSpec(angleDeg: a, showAngleLabel: true),
    correctAnswer: '$a',
    distractors: integerDistractorsWith(
      a,
      rand,
      misconception: 180 - a,
    ),
    explanation: [
      'The label $a° inside the wedge shows the angle they drew.',
    ],
  );
}
