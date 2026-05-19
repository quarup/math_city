import 'dart:math';

import 'package:math_city/domain/questions/diagram_spec.dart';
import 'package:math_city/domain/questions/distractors.dart';
import 'package:math_city/domain/questions/generated_question.dart';

/// G5-G8 graph-related concepts that ride on the existing CoordinatePlane
/// widget: two_pattern_relationships, graph_proportional_slope,
/// qualitative_graph_features, interpret_slope_intercept_data.
/// Plus the text-only simulate_compound stats item.

List<String> _distinctStrings(String correct, List<String> candidates) {
  final out = <String>[];
  final seen = <String>{correct};
  for (final c in candidates) {
    if (out.length >= 3) break;
    if (seen.add(c)) out.add(c);
  }
  return out.take(3).toList();
}

String _qualSlopeExplanation() =>
    'Positive slope → increasing; negative slope → decreasing; '
    'zero slope → constant.';

// ─────────────────────────────────────────────────────────────────────────
// two_pattern_relationships (G5)
// ─────────────────────────────────────────────────────────────────────────

/// "Pattern A starts at 0 and adds 2 each time. Pattern B starts at 0
/// and adds 3 each time. Which point is on pattern B at step 4?" → (4, 12).
/// Visualized as two sets of ordered pairs on a Q1 coordinate plane.
GeneratedQuestion twoPatternRelationships(Random rand) {
  final stepA = rand.nextInt(3) + 1; // 1..3
  late int stepB;
  do {
    stepB = rand.nextInt(3) + 1;
  } while (stepB == stepA);
  // Plot 4 points each.
  final pointsA = <CoordinatePlanePoint>[];
  final pointsB = <CoordinatePlanePoint>[];
  for (var x = 1; x <= 4; x++) {
    pointsA.add(CoordinatePlanePoint(x: x, y: x * stepA, label: 'A'));
    pointsB.add(CoordinatePlanePoint(x: x, y: x * stepB, label: 'B'));
  }
  final askStep = rand.nextInt(3) + 2; // 2..4
  final askA = rand.nextBool();
  final pattern = askA ? 'A' : 'B';
  final step = askA ? stepA : stepB;
  final correct = '($askStep, ${askStep * step})';
  return GeneratedQuestion(
    conceptId: 'two_pattern_relationships',
    prompt:
        'Pattern A adds $stepA each step; Pattern B adds $stepB each step. '
        'What is the point on Pattern $pattern at step $askStep?',
    diagram: CoordinatePlaneSpec(
      minX: 0,
      maxX: 5,
      minY: 0,
      maxY: 5 * (stepA > stepB ? stepA : stepB),
      points: [...pointsA, ...pointsB],
    ),
    correctAnswer: correct,
    distractors: _distinctStrings(correct, [
      // The OTHER pattern at the same step.
      '($askStep, ${askStep * (askA ? stepB : stepA)})',
      '(${askStep + 1}, ${(askStep + 1) * step})',
      '(${askStep - 1}, ${(askStep - 1) * step})',
      '(${askStep * step}, $askStep)', // swapped coords
    ]),
    explanation: [
      'At step $askStep: $askStep × $step = ${askStep * step}.',
      'So the point is ($askStep, ${askStep * step}).',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// graph_proportional_slope (G8)
// ─────────────────────────────────────────────────────────────────────────

/// "What is the slope of this proportional relationship?" The line passes
/// through the origin and (1, k). Slope = k. CCSS 8.EE.B.5.
GeneratedQuestion graphProportionalSlope(Random rand) {
  // k ∈ [2, 5] for clarity. Random sign 50/50.
  final magnitude = rand.nextInt(4) + 2; // 2..5
  final isNeg = rand.nextBool();
  final k = isNeg ? -magnitude : magnitude;
  // Two-point line: origin and (1, k) — for negative k extend to (-1, -k)
  // so the line is centered in the plane and clearly through the origin.
  const range = 6;
  // Build a 4-quadrant plane.
  return GeneratedQuestion(
    conceptId: 'graph_proportional_slope',
    prompt:
        'This line shows a proportional relationship y = kx. '
        'What is the slope k?',
    diagram: CoordinatePlaneSpec(
      minX: -range,
      maxX: range,
      minY: -range,
      maxY: range,
      lines: [
        CoordinatePlaneLine(
          x1: -1,
          y1: -k,
          x2: 1,
          y2: k,
        ),
      ],
    ),
    correctAnswer: '$k',
    distractors: _distinctStrings('$k', [
      '${-k}', // sign flip
      '${k + 1}',
      '${k - 1}',
      '$magnitude', // dropped sign
      '0',
    ]),
    explanation: [
      'When x = 1, y = $k. So the slope is $k.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// qualitative_graph_features (G8)
// ─────────────────────────────────────────────────────────────────────────

/// Show a line and ask "Is this function increasing, decreasing, or
/// constant?" — three-way classification by sign of slope. CCSS 8.F.B.5.
GeneratedQuestion qualitativeGraphFeatures(Random rand) {
  final kind = rand.nextInt(3); // 0 = increasing, 1 = decreasing, 2 = constant
  late int slope;
  final intercept = rand.nextInt(5) - 2; // -2..2
  late String correct;
  switch (kind) {
    case 0:
      slope = rand.nextInt(3) + 1; // 1..3
      correct = 'Increasing';
    case 1:
      slope = -(rand.nextInt(3) + 1); // -1..-3
      correct = 'Decreasing';
    default:
      slope = 0;
      correct = 'Constant';
  }
  return GeneratedQuestion(
    conceptId: 'qualitative_graph_features',
    prompt: 'Looking at the graph, is this function:',
    diagram: CoordinatePlaneSpec(
      minX: -5,
      maxX: 5,
      minY: -5,
      maxY: 5,
      lines: [
        CoordinatePlaneLine(
          x1: -3,
          y1: -3 * slope + intercept,
          x2: 3,
          y2: 3 * slope + intercept,
        ),
      ],
    ),
    correctAnswer: correct,
    distractors: [
      if (correct != 'Increasing') 'Increasing',
      if (correct != 'Decreasing') 'Decreasing',
      if (correct != 'Constant') 'Constant',
      'Nonlinear',
    ].take(3).toList(),
    explanation: [
      _qualSlopeExplanation(),
      'Here the slope is $slope, so the function is $correct.',
    ],
    answerFormat: AnswerFormat.string,
  );
}

// ─────────────────────────────────────────────────────────────────────────
// interpret_slope_intercept_data (G8)
// ─────────────────────────────────────────────────────────────────────────

/// "The line of best fit has slope 2 and y-intercept 5. Predict y when
/// x = 10." → 25 = 2·10 + 5. Tests CCSS 8.SP.A.3.
GeneratedQuestion interpretSlopeInterceptData(Random rand) {
  final m = rand.nextInt(4) + 2; // 2..5
  final b = rand.nextInt(10) + 1; // 1..10
  // Generate sample scatter points along y ≈ mx + b with small noise.
  final points = <ScatterPlotPoint>[];
  for (var x = 1; x <= 8; x++) {
    final noise = rand.nextInt(3) - 1; // -1..1
    points.add(
      ScatterPlotPoint(x: x, y: m * x + b + noise),
    );
  }
  // Show the best-fit line as a dashed overlay.
  final askX = rand.nextInt(5) + 10; // 10..14 (extrapolation)
  final correct = m * askX + b;
  return GeneratedQuestion(
    conceptId: 'interpret_slope_intercept_data',
    prompt:
        'The line of best fit for these data is y = ${m}x + $b. '
        'Predict y when x = $askX.',
    diagram: ScatterPlotSpec(
      minX: 0,
      maxX: 10,
      minY: 0,
      maxY: m * 10 + b + 2,
      points: points,
      lineOfFit: ScatterPlotLineOfFit(
        x1: 0,
        y1: b,
        x2: 8,
        y2: m * 8 + b,
      ),
    ),
    correctAnswer: '$correct',
    distractors: integerDistractorsWith(
      correct,
      rand,
      // Misconception: forgot the intercept.
      misconception: m * askX,
    ),
    explanation: [
      'y = ${m}x + $b at x = $askX:',
      '$m × $askX + $b = $correct.',
    ],
  );
}

// ─────────────────────────────────────────────────────────────────────────
// simulate_compound (G7) — text-only
// ─────────────────────────────────────────────────────────────────────────

/// "Sam flips two coins 50 times and gets HH 12 times. What is the
/// experimental P(HH)?" — gives count out of trials and asks for the
/// experimental probability as a fraction. CCSS 7.SP.C.8.
GeneratedQuestion simulateCompound(Random rand) {
  final trials = [50, 100][rand.nextInt(2)];
  final happened = rand.nextInt((trials * 4) ~/ 10 - 5) + 5; // 5..(0.4·trials)
  final correct = '$happened/$trials';
  return GeneratedQuestion(
    conceptId: 'simulate_compound',
    prompt:
        'In a simulation, two coins were flipped $trials times. '
        'Both came up heads $happened times. Based on this simulation, '
        'what is the experimental probability of getting two heads?',
    correctAnswer: correct,
    distractors: _distinctStrings(correct, [
      '$trials/$happened', // flipped
      '$happened/${trials - happened}', // hits-to-misses ratio
      '${happened + 1}/$trials',
      '${happened - 1}/$trials',
      '${trials - happened}/$trials', // P(not both heads)
    ]),
    explanation: [
      'Experimental P = successes / trials = $happened / $trials.',
    ],
    answerFormat: AnswerFormat.fraction,
    answerShape: AnswerShape.exactString,
  );
}
